# Full System Setup & Production Test Guide

Generated: 2026-07-08 · Test user: **swalih.v@universal-rbm.com** (Employee `E0106`, has System Manager + Finance Approver)
Scope: everything from Purchase Order and Sales Order through compound production, calendering, belt/sleeve building, QC and packing to Delivery Note — Desk flows and PDT (mobile) flows, with every doctype and where its setup lives.
Companions: `PHASE3-SETUP-AND-TEST-GUIDE.md` (Line-2/brand-BOM detail), `full-flow-handover-test-plan.md` (older Line-1 test suites), `PDT-SETUP-REFERENCE.md` (PDT user administration).

---

## 0. System map — what runs where

**Four custom Frappe apps** (dependency order, no app imports upward):
| App | Owns | Key modules |
|---|---|---|
| `universal` | Company-wide customisations, brand/variant sync, payroll | `custom_scripts/item_sync.py`, Building Production Plan |
| `wms_universal` | Receiving, LOT/bin warehouse management, picking | `receiving.py`, `put_away.py`, `pick.py`, `lot.py` |
| `manufacturing_universal` | Lines 1 & 2 production, machine ingestion, tools | `machine_api_endpoints.py`, `manual_production.py`, `silo_loading.py`, `mixer_loading.py`, `calendering.py`, `line1_cutting.py`, `line2_*.py`, `brand_variant_bom.py` |
| `universal_mobile_api` | Every PDT endpoint + screen/role gating | `api/*.py`, `permissions.py` (PDT Screen/Action/Role) |

**Two user interfaces**:
- **Desk** (browser, `http://site1.local`): all master-data setup, PO/SO/PR, BOMs, Work Orders, manual production records, lab tests (also possible via PDT), monitoring.
- **PDT** (Android handheld, Flutter app): shop-floor execution — receiving/putaway, picking, loading, calendering, cutting, Line-2 building/QC/packing. 26 screens across 7 modules, all currently gated on the **System Manager** role only.

**Machine vs manual production records — how it works** (answering the architecture question):
The machine bridge pushes JSON to `receive_mixer_production` / `receive_chem_product`. Those endpoints do everything **in one synchronous shot**: resolve the formula via **Formula-BOM Mapping** → resolve each consumed material via **Machine Material Map** → create the **Batch** → create + submit the **Manufacture Stock Entry** (actual machine quantities, not BOM quantities) → *then* store a **Machine Production Record (MPR)**. The MPR is not a processing queue — it is the **permanent audit record**: raw machine JSON, links to the Batch/Stock Entry it produced, per-material actual-vs-BOM variance (feeds the *Machine Production Variance* report), machine timing, and the idempotency key (`machine_batch_id` — a batch pushed twice is skipped). If any resolution fails, **no stock moves** — the raw payload lands in **Unmatched Machine Record** instead, for repair and reprocessing.
**The manual path (built 2026-07-08) inverts the order, same pipeline**: you create the MPR yourself in Desk with `status = Pending`, then click **Process Production Record** — it runs the identical pipeline (Batch → Stock Entry → variance → lab-test draft → LOT deduction → label print) and flips the record to `Processed`. Downstream, manual and machine records are indistinguishable. When the machine integrates later, nothing changes — both paths converge on the same doctype.

---

## 1. One-time setup checklist (verify before every test session)

State on this bench has reverted after DB restores before — re-verify this table at session start. Items marked ✅ were verified/configured 2026-07-08.

| # | Setting | Where in Desk | Current state |
|---|---|---|---|
| 1 | Scheduler enabled | System Settings → Enable Scheduler | ✅ on (flips after restores!) |
| 2 | Manufacturing Settings URBM — all warehouses | Search "Manufacturing Settings URBM" (it's a single record, not a Single doctype) | ✅ all Line-1 + Line-2 + Cutting warehouses linked (see §1.1) |
| 3 | WMS Settings → Finance Approver Role | WMS Settings (Single) | ✅ "Finance Approver"; swalih has the role |
| 4 | Stock Settings → auto-pick batches FIFO | Stock Settings → Serial & Batch section | ✅ `auto_create_serial_and_batch_bundle_for_outward=1`, FIFO — **required** for machine/manual production records |
| 5 | PDT Modules (7) + Screens (26) | PDT Module / PDT Screen list | ✅ incl. all 10 `line2_*`, `cutting`, `sleeve_calculator` |
| 6 | swalih Worker Workstation Assignment + active Worker Session | Worker Workstation Assignment `v7u5pnffpl`; Worker Session | ✅ WS-0012 active |
| 7 | Tank Lot Assignment (12: 6 silos + oils) | Tank Lot Assignment list | ✅ items+capacities set; `min_qty_kg` all 0 (you deferred) |
| 8 | Formula-BOM Mapping (258, 207 active w/ BOM) | Formula-BOM Mapping list | ✅ Mixer CMB/FMB/PM + Chemical Weighing |
| 9 | Machine Material Map | Machine Material Map list | ⚠️ 55 rows, **all Mixer — 0 Chemical Weighing rows** (only matters for machine-pushed chem records; manual entry doesn't need it) |
| 10 | `stream_item_group_map` (weighing-stream mapping) | Manufacturing Settings URBM → Stream Mapping table | ❌ 0 rows — blocks PDT *Material Loading* for weighing-stream items (silo/oil unaffected, they resolve via tanks). Add rows: Item Group → "Weighing" |
| 11 | Workstation `hour_rate` (Mixer / Chemical Weighing / Calender) | Workstation list | ⚠️ all 0 → overhead cost silently 0 on production entries (works, just costs nothing) |
| 12 | Company `default_operating_cost_account` | Company | ❌ unset (you deferred) — overhead also needs #11 |
| 13 | Inventory accounts on items | Item → Item Defaults row | ✅ fixed 2026-07-08: 149 Chemical Bags + 24 Brand Label + 7 Calender Liners + 4 Cylinders + 5 Products → **review the account choices** (Raw Material / Spare parts / Belts) |
| 14 | Universal Printer + label formats | Universal Printer list | ❌ 0 printers. `Compound Batch Label` print format exists; `Batch Label` doesn't. Label steps run but nothing prints physically |
| 15 | Belt/sleeve BOMs | BOM list | ❌ 0/1,196 real belt items have BOMs. Worked example exists: `107 YU CR 22-BOM-0469` (template `20100747`, placeholder qtys). Brand-variant mechanism proven — see §6.3 |
| 16 | Sleeve Build Layer rows (per-item layering) | Sleeve Build Specification → Layers table | ❌ empty on all 4,115 records — layering checklist on PDT building screen will be empty until populated |
| 17 | Production Type `label_stage` | Production Type Master (7 records) | ⚠️ unset on all — labelling step won't be spliced into routes until set (Before Curing / After Grinding) |
| 18 | Tool Master (molds/airbags/pots) | Tool Master list | ✅ 3 test tools seeded (`MOLD-3PK-0855`, `AIRBAG-3PK-0855`, `CURING-POT-01`); real tooling data is yours to load |

### 1.1 Warehouse wiring (Manufacturing Settings URBM)
Silo/Oil/Weighing inside+outside pairs, `wip_bags`, `fmb_zone`, `cmb_zone`, `mixer_staging`, `mixer_wip`, `wip_calendering`, `finished_sheet`, `calendering`, `calender_tools_store/in_use` — all set previously. Set 2026-07-08: `building_material` → `Sleeve Building WH  - URBM` (double space is real), `building_wip`/`sleeve_wip` → `Sleeve Building WIP - URBM`, `finished_belt` → `Finished Belt WH - URBM` (new), `line2_scrap` → `Scrap - URBM`, `cutting` → `Cutting WH - URBM`. Unset & unreferenced by code (leave alone): `compound_warehouse`, `cutting_wip`, generic `scrap`, `default_*_mr` warehouses.

**Note (2026-07-09):** `calendering_warehouse` ("Calendering WH") and `wip_calendering_warehouse` ("WIP Calendering") are **two different things**, previously conflated in this doc's prose. `calendering_warehouse` is where scanned-in FMB batches sit while being calendered — the destination of a fulfilled **Calendering FMB** Material Request (Store: `fmb_zone_warehouse`). `wip_calendering_warehouse` was dead code until now and is repurposed as the **roll staging bin** — the destination of a fulfilled **Calendering Tools** Material Request (Store: `calender_tools_store_warehouse`), holding Liner/Cylinder rolls ready for Complete Run to auto-match and consume. See §4.

---

## 2. Flow A — Procure to stock (PO → PR → lab → finance → putaway → LOT)

**Desk doctypes**: Purchase Order, Purchase Receipt, Received Item, Incoming Lab Test, LOT Stock Line. **PDT screens**: `po_reception`, `grn_putaway`.

1. **Purchase Order** (Desk → Buying → Purchase Order → New): supplier, items (raw materials — 30-series polymers/chemicals, 40-series liners), qty, warehouse can stay default. Submit. *(98 receivable POs already exist for testing.)*
2. **PO Reception** (PDT → Receiving → PO Reception): scan/select the PO, enter received quantities → creates the **Purchase Receipt** (submitted). Desk alternative: PO → Create → Purchase Receipt → Submit.
3. **On PR submit (automatic)**: `wms_universal.receiving.on_purchase_receipt_submit` creates one **Received Item** (status In Review, one line per PR item) + one **Incoming Lab Test** per line (status Pending). Stock is already in the receiving warehouse from the PR itself.
4. **Incoming lab** (Desk → Incoming Lab Test): set result Pass/Fail per line. Pass marks the Received Item Line lab-passed.
5. **Finance approval** (Desk → the Purchase Receipt → **Approve Finance** button): only users with the WMS-Settings-configured role (Finance Approver — swalih has it) can click; sets `custom_finance_status = Approved` and cascades `ready_for_allocation` to lab-passed lines. After this, LCV submission for the PR is blocked (by design — see LCV memory/doc).
6. **Bin allocation / putaway** (PDT → Receiving → Bin Allocation `grn_putaway`): scan item/batch → system suggests bins via **WMS Zone Preference** (item-group keyed, 123 records) → allocate → creates **LOT Stock Line** rows (the WMS quantum of stock: item+batch+bin). Actions: `create_batch`, `allocate_bin`, `override_capacity`.
7. **Verify**: Received Item status; LOT Stock Line rows exist; Bin qty. Desk → LOT Browser equivalents on PDT: `lot_browser`, `manual_transfer` (Supervisor Tools).

---

## 3. Flow B — Compound production (Line 1: materials → bags/PM/CMB/FMB → lab)

### 3.1 Stage materials to the lines
1. **Manufacturing MR** (PDT → Compound Production → Manufacturing MR): pick items+qty+stream → creates **Material Request** (type Material Transfer). Six streams: **Silo / Oil / Weighing / Mixer** are lot-based — submit creates a **WMS Pick List** (`create_pick_list`) resolved via `wms_universal.lot_suggestion` against **Warehouse LOT** bins. **Calendering Tools / Calendering FMB** (added 2026-07-09, see §4) have no Warehouse LOT infrastructure — submit leaves them at status `MR Raised` and a **Mark Fulfilled** button (`fulfill_mmr_direct`) does one direct Material Transfer instead (FIFO batch selection for the batch-tracked Calendering FMB stream).
2. **Pick** (PDT → Picking → Pick List): claim → scan LOT/bin → pick → stock moves to the *Outside* warehouses (Outside Silo WH / Outside Oil WH / Outside Weighing Machine WH). Suggested LOTs come from `wms_universal.lot_suggestion`; `override_suggested_lot` action exists.
3. **Material Loading** (PDT → Compound Production → Material Loading): scan item → stream resolves via **Tank Lot Assignment** (Silo/Oil tanks are authoritative) or the **stream_item_group_map** (weighing items — ❌ currently empty, add rows first) → moves Outside→Inside warehouse for that stream, respecting tank capacity. Tank state: PDT tank-status list or Desk → Tank Lot Assignment.
4. **Weighing Load** (PDT → `weighing_load`): box-scan based load into Inside Weighing Machine WH (needs stream map rows for its items).

### 3.2 Chemical bags — manual Machine Production Record (Weighing)
Until the chem machine is integrated, enter each produced bag as a manual MPR:

**Desk → Machine Production Record → New**
| Field | Value |
|---|---|
| Machine Batch ID | the bag barcode (becomes the Batch ID), e.g. `BAG-XCJ105P-0001` |
| Machine Type | **Weighing** |
| Formula Code | exactly as in Formula-BOM Mapping, e.g. `X-CJ105P5-CMB (3)` |
| Qty | produced bag weight (Kg), e.g. `4.237` |
| Production Datetime | defaults to now |
| Status | Pending (default) |
| Items table | one row per consumed chemical: **Item + Qty**. Warehouse can be left blank → defaults to Inside Weighing Machine WH. Batch No optional → FIFO auto-pick |

Save → **Process Production Record** button → confirms → creates the Batch (into **WIP Bags - URBM**), the Manufacture Stock Entry, computes variance vs the mapping's BOM, sets status Processed. No lab test for bags. Errors (bad formula code, missing stock) mark the record `Error` with the message stored — fix and click Process again.

### 3.3 Mixer compounds (PM → CMB → FMB) — manual MPR (Mixer)
Same doctype, `Machine Type = Mixer`. Routing by the mapping's `compound_type`:
- **PM** (masterbatch, e.g. `PM-PAB201-P`) → lands in **CMB Zone** *(fixed 2026-07-08 — previously threw "Invalid compound_type: PM")*, gets a lab gate.
- **CMB** → **CMB Zone**, lab gate.
- **FMB** (final mix, e.g. `PAB201-P-FMB`) → **FMB Zone**, lab gate.

Consumed rows: leave Warehouse blank → auto-resolves (silo items → Inside Silo WH via their tank; oil → Inside Oil WH; bags/compounds → Mixer WIP). Set Warehouse explicitly to override (e.g. a PM consumed from CMB Zone). To consume a **specific** batch (e.g. the exact PM batch), set Batch No on the row; otherwise FIFO picks.
On Process: Batch → zone warehouse, Stock Entry, variance vs BOM, **Batch.custom_lab_status = Pending** + a draft **Compound Lab Test**, LOT deduction, label print request (`Compound Batch Label`), Warehouse LOG.
Real floor sequence before the mixer record: **Mixer Loading** (PDT → `mixer_loading`) scans bags/CMB/PM batches from staging into **Mixer WIP** — it enforces the **lab gate** (a lab-tracked batch must be Pass/Conditional Pass to load).

### 3.4 Compound Lab Test
PDT → Compound Production → Compound Lab Test (or Desk → Compound Lab Test): open the draft created by the production record → enter parameter results → submit with result **Pass / Conditional Pass / Fail** → sets `Batch.custom_lab_status`. Gates: mixer loading (CMB/PM), calendering FMB selection (FMB must be lab-passed).

---

## 4. Flow C — Calendering & cutting (FMB → sheets → cut sheets)

**Redesigned 2026-07-09**: FMB and roll tooling are no longer silently auto-transferred by the calendering screen itself — both now go through a real **Material Request → fulfill** trail (Manufacturing MR screen, §3.1), and Complete Run is a 3-step wizard instead of one long form.

1. **Stage the FMB** (PDT → Manufacturing MR → New, stream **Calendering FMB**): request the FMB item + qty needed → Submit → **Mark Fulfilled** (picker action, FIFO-selects lab-passed batches from **FMB Zone**, one Material Transfer into **Calendering WH**). No Warehouse LOT infra for this stream — direct fulfillment, no pick list.
2. **Stage the rolls** (PDT → Manufacturing MR → New, stream **Calendering Tools**): request the Liner/Cylinder item + qty needed (40-series items, e.g. liner `40100003`, cylinder `40100009`) → Submit → **Mark Fulfilled** (one Material Transfer from **Calender Tools Store** into **WIP Calendering**, the new roll-staging bin — see §1.1 note).
3. **Start Run — scan to build** (PDT → Compound Production → Calendering, "New Run" tab): scan the FMB batch now sitting in Calendering WH (list of what's available shown as a fallback) → confirm quantity → `start_run_from_batches` creates the **Calendering Run** (no stock movement — the batch is already there). Scan again to claim a second batch of the same item into the same run if one batch isn't enough, then **Proceed to Sheets**.
4. **Complete Run — 3-step wizard**:
   - **Step 1, Sheets**: "Add Sheet" opens a picker scoped to finished sheet Items (`Item Group = Rubber Sheets`) sharing the FMB item's `compound` field — no more typing an item code. Only Qty/Thickness/Width/Length are manual inputs (thickness/width pre-fill from the picked Item, still editable).
   - **Step 2, Liner & Cylinder**: auto-matched per sheet from **WIP Calendering** stock — narrowest roll whose `width ≥ sheet width` and `length(m)×1000 ≥ sheet length(mm)`. Green = matched+available; amber = matched but short on staged stock (**Raise MR** button pre-fills a Calendering Tools request for the shortfall, right from this screen); red = no roll spec wide/long enough at all (a data problem, not a stock one).
   - **Step 3, Returns**: unchanged — liner/calendar return qty, excruder sludge, balance check, **Complete Run**. Sheets land in **Finished Sheet WH** as new Batches; returns go back to FMB Zone via Repack; roll consumption moves WIP Calendering → Calender Tools In Use (auto-released back to Store once the sheet batch it's wound with is fully consumed — unchanged). Desk: Calendering Run list shows the full trace, including the `fmb_sources` child table for multi-batch runs.
5. **Cutting & Splicing** (PDT → Compound Production → Cutting & Splicing, built Phase 2): scan a sheet batch in Finished Sheet WH → enter target item, input/output qty → Repack into **Cutting WH** + **Cutting Log** row.

---

## 5. Flow D — Sales Order → Production Plan → Work Orders

1. **Customer** (Desk → Selling → Customer; 225 exist) and **Sales Order** (Desk → Selling → Sales Order → New): items = **finished belt variants** (e.g. `20100747-Raykalton` — the brand variant, not the template), qty, delivery date. Submit. *(SO00083 exists submitted for testing.)*
2. **Building Production Plan** (Desk → Building Production Plan → New): `plan_date`, **`sales_order`** (link added 2026-07-08), `building_line` (Workstation), then one **entry row per Work Order** you create in step 3 (sequence, work order, item, qty, tool assignment, estimated start/end). This doctype is manual planning/tracking — it does not auto-create WOs. Submit when the day's plan is set; update entry statuses as production progresses.
3. **Work Order** (Desk → Manufacturing → Work Order → New) per SO line: Production Item = the **brand variant**; qty in the item's stock UOM (Sleeve for sleeve-built items — use PDT → Supervisor Tools → **Sleeve Calculator** to convert desired belts → sleeves via the item's UOM conversion); `custom_production_type` (TB/SPB/SPA/SPZ/AX/PK/CR) if not set on the Item. On save the **brand-variant BOM hook** fires: first WO per brand auto-creates the brand BOM with the label line resolved (template BOM must exist — §6.3). On submit, `line2_wo_hooks` stamps the flowchart barcode and the Job-Card route per the Production Type's flowchart steps.

---

## 6. Flow E — Belt/sleeve building (Line 2), QC, packing, delivery

### 6.1 Building (PDT, module Belt/Sleeve Building)
- **Sleeve Creation** (`line2_sleeve`): consume fabric from Sleeve Building WH → produce sleeve batches into Sleeve Building WIP (+ **Sleeve Creation Log**). Layering checklist comes from **Sleeve Build Specification → Layers** (❌ empty today — screen works, checklist just empty).
- **Active Jobs** (`line2_active_jobs`) / **Sleeve/Belt Building** (`line2_building`): scan the WO's flowchart barcode → current step, allowed workstations (filtered by the **physical capacity fields** on Workstation vs the item's spec dims), step inputs → `complete_step`. Tools: `assign_tool`/`release_tool` (Tool Master status + **Tool Usage Log** checkout/checkin audit; curing pots support multi-occupancy via `pot_capacity`).
- **Curing / Processing** (`line2_curing`, `line2_processing`): same scan→complete backend as building; separate menu tiles per station.
- **Rejection** (`create_rejection` on the building screen): Rework (routes a new Job Card back to the chosen step, max `max_rework_attempts`=2 then auto-escalates) or Full Scrap (stock → Scrap via **Rejection Log**).
- **Labelling** (`line2_labelling`): `print_label` — position in the route comes from Production Type `label_stage` (⚠️ unset today).

### 6.2 QC & completion
- **QC Measurement** (`line2_qc_measure`): parameter measurements per Production Type (**Type Measurement Param** child table) → **Job Card Measurement** rows.
- **QC Final** (`line2_qc_final`): accept/reject quantities (`submit_qc_result`), then **`complete_wo`**: submits open Job Cards, consumes BOM materials FIFO from Sleeve Building WH, produces the finished-belt Batch into **Finished Belt WH**, converts Sleeve→Belt qty via the item's UOM conversion when qc_mode = Sleeve UOM.

### 6.3 Brand-variant BOMs (prerequisite for any Line-2 WO)
One BOM per belt model, on the **template** item, with the **label template** as the label row. First WO per brand auto-generates `<model>-<Brand>-BOM-…` with the label resolved to that brand's label variant (e.g. `60100001-Raykalton`). Full detail + caveats: `PHASE3-SETUP-AND-TEST-GUIDE.md` §8. Worked example kept: `107 YU CR 22-BOM-0469` (replace its placeholder qtys with real lines). Missing label variant for a brand → clear error at WO save. **Note**: generated brand BOMs are cached — after editing a template BOM, delete its generated brand copies so they regenerate.

### 6.4 Packing & shipping (PDT `line2_packing`, SO-keyed)
- **Create Box / Pallet** against the **Sales Order** → scan finished belt batches in (`add_to_box`, `add_item_to_pallet`, `add_box_to_pallet`) → **Seal** → **Ship** (`ship_pallet`/`ship_box`) → creates the **Delivery Note** (submitted) against the SO.
- **Verify in Desk**: Delivery Note list; SO status → To Bill; Box/Pallet doctypes carry the containment trace. (Invoicing is standard ERPNext from the DN — out of scope per your instruction.)

---

## 7. Worked end-to-end example (concrete items, proven quantities)

The compound chain below was executed live on 2026-07-08 via manual MPRs and verified to the kilogram; the belt chain was proven the same day via the brand-BOM proof.

| Step | Screen/Doctype | Input | Expected result |
|---|---|---|---|
| 1 | PO/PR/putaway (Flow A) | 30100003, 30100004, 30100027, 30100030, 30100033, 30100039 polymers/chemicals; bag chemicals | LOT stock in bins |
| 2 | Pick + Material Loading | silo items → SILO tanks (30100027 = SILO 3, 30100030 = SILO 4) | stock in Inside Silo WH |
| 3 | Manual MPR (Weighing) | formula `X-CJ105P5-CMB (3)`, qty 4.237 | bag batch in WIP Bags |
| 4 | Manual MPR (Mixer, PM) | formula `PM-PAB201-P`, qty **111.32** (BOM: 43.4 + 16.9 + 43.4 + 4.23 + 3.39) | PM batch in **CMB Zone**, lab Pending, variance 0 |
| 5 | Compound Lab Test | pass the PM batch | `custom_lab_status = Pass` |
| 6 | Mixer Loading (PDT) | scan PM batch + bags into Mixer WIP | lab gate passes |
| 7 | Manual MPR (Mixer, FMB) | formula `PAB201-P-FMB`, qty **125.543**; consume row: item 20100023 @ 84.7 from CMB Zone, batch = the PM batch | FMB batch `20100024` in **FMB Zone** |
| 8 | Lab test → pass | FMB batch | `custom_lab_status = Pass` |
| 8a | Manufacturing MR (Calendering FMB) → Mark Fulfilled | FMB item, qty | FMB batch moved FMB Zone → Calendering WH |
| 8b | Manufacturing MR (Calendering Tools) → Mark Fulfilled | liner 40100003, cylinder 40100009 | rolls moved Calender Tools Store → WIP Calendering |
| 8c | Calendering: scan FMB batch → Start Run → 3-step Complete Run | FMB batch scanned; sheet picked from compound-matched list; liner/cylinder auto-matched in Step 2 | sheet `20100722` batch in Finished Sheet WH |
| 9 | SO + Building Production Plan | SO for `20100747-Raykalton`; plan linked to SO | plan submitted |
| 10 | Work Order | `20100747-Raykalton`, template BOM `107 YU CR 22-BOM-0469` | brand BOM auto-generated, label → `60100001-Raykalton` |
| 11 | Build → QC → complete | PDT Line-2 screens | belt batch in Finished Belt WH |
| 12 | Pack & ship | box/pallet on the SO → ship | **Delivery Note** submitted |

---

## 8. Known gaps & workarounds (single list)

| Gap | Impact | Workaround / fix |
|---|---|---|
| 0/1,196 real belt BOMs | No real Line-2 WOs | Enter real BOMs per template (§6.3 pattern); worked example on `20100747` |
| `stream_item_group_map` empty | PDT Material Loading fails for weighing-stream items | Add Item-Group→Weighing rows in Manufacturing Settings URBM |
| Machine Material Map: 0 Chemical Weighing rows | Machine-pushed chem records will unmatch | Irrelevant for manual entry; add rows before machine integration |
| Sleeve Build Layer rows empty | Building layering checklist empty | Populate from PK- Base Specs workbook (needs the junk-record scoping pass first) |
| Production Type `label_stage` unset | Labelling step not in routes | Set Before Curing / After Grinding per type |
| Universal Printer 0 records; `Batch Label` format missing | No physical label printing | Configure printer + relay; formats: `Compound Batch Label` exists |
| Workstation hour_rate 0 + no operating cost account | Overhead cost = 0 on production entries | Set rates + Company default_operating_cost_account (deferred by you) |
| `bench run-tests` broken bench-wide | Automated tests can't run | Pre-existing fixture bugs; console verification is the working path |
| Inventory-account choices made 2026-07-08 | Chemical Bags/labels→Raw Material, liners/cylinders→Spare parts, Products→Belts | Review and re-point if your accountant disagrees |

## 9. Re-runnable setup scripts & quirks

- `apps/manufacturing_universal/manufacturing_universal/scripts/phase3_pdt_and_warehouse_setup.py` — PDT screens/modules, warehouse wiring, seed tools, Finance Approver, capacity demo. Idempotent; re-run after any restore: `cd sites && ../env/bin/python <path>`.
- Quirks: Manufacturing Settings URBM is **not** a Single (use its one record, or `silo_loading._get_settings()` in code); `bench console` mangles piped stdin (use script files); clear-cache **before** migrate when a new module is added to `modules.txt`; scheduler + warehouse links can revert after DB restores.
