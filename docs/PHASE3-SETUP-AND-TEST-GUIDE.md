# Phase 3 — Setup & Test Guide (Line 2 Building, Tool Usage Log, Sleeve Calculator, Cutting & Splicing)

Generated: 2026-07-08
Audience: whoever is testing with **swalih.v@universal-rbm.com** ("Muhammed Swalih Vallikkadan", Employee `E0106`)
Companion docs: `PDT-SETUP-REFERENCE.md` (general PDT setup), `full-flow-handover-test-plan.md` (Line 1 receiving→calendering test plan)

This pass did two things: (1) verified every blocker previously flagged for the 4 Phase 2 features was actually fixed, and found/fixed a few more that were blocking a *real* test session; (2) configured the system so swalih can log in today and exercise every new feature. Section 2 below is the one thing that's still genuinely blocked and needs your call.

---

## 0. TL;DR

| Area | Status |
|---|---|
| Scheduler | ✅ Enabled (`enable_scheduler=1`) — **known to flip off after a DB restore**, re-check before every session |
| Tool Usage Log, Sleeves Calculator, Workstation capacity matching, Cutting & Splicing (Phase 2 code) | ✅ All 4 confirmed still working live |
| PDT Screens for Line 2 (10) + Sleeve Calculator + Cutting | ✅ Created just now — were 100% missing before this pass |
| Line 2 + Cutting warehouses on Manufacturing Settings URBM | ✅ Wired just now (mostly reusing warehouses that already existed but were never linked) |
| Tool Master (physical molds/airbags/pots) | ✅ 3 seed records created (was 0) |
| Finance Approver role | ✅ Granted to swalih (was 0 users system-wide) |
| swalih's PDT access | ✅ Confirmed — has System Manager, which is the only role every PDT Screen currently requires |
| **Real belt/sleeve BOMs** | ❌ **Still 0 of 1,196+ real belt items have a submitted BOM — see §2, this blocks real Work Order testing** |
| Universal Printer / Batch Label print format | ❌ Still 0 records / doesn't exist — label printing steps will not physically print |
| Operating cost account, granular roles, tank min/max, machine bridge, LOT population | Untouched — you said you'd handle these yourself |

---

## 1. What changed in this pass

### 1.1 Fixed / confirmed working
- **Scheduler**: found enabled at audit time. Memory from earlier sessions shows this flips off after DB restores — it is *not* a one-time fix. Check `System Settings → Enable Scheduler` (or `bench --site site1.local doctor`) at the start of every test session before assuming background jobs run.
- **Tool Usage Log, Sleeves Calculator, Workstation capacity matching, Cutting & Splicing**: re-verified all 4 live. No regressions. One code-quality fix made along the way: `test_tool_usage_log.py` was written against the deprecated `FrappeTestCase` base class, which is known on this bench to explode against site-specific fixture data. Converted to the `IntegrationTestCase` + `IGNORE_TEST_RECORD_DEPENDENCIES` pattern the rest of this codebase already uses. This did **not** fix `bench run-tests` itself (see §7) — that's a separate, deeper, pre-existing bench issue — but the test file is now written the correct way for whenever that gets sorted out.

### 1.2 Newly configured (all idempotent — safe to re-run)
Everything below was applied by `apps/manufacturing_universal/manufacturing_universal/scripts/phase3_pdt_and_warehouse_setup.py`. Keep this script — if a DB restore wipes this config again (state on this bench has flipped after restores before), re-run it:
```
cd sites && ../env/bin/python ../apps/manufacturing_universal/manufacturing_universal/scripts/phase3_pdt_and_warehouse_setup.py
```

1. **PDT Module `line2`** ("Belt/Sleeve Building") — didn't exist. Without it, Line 2 screens have no menu group to live in.
2. **12 PDT Screens created** (server had 14 screens total before this, covering only Line 1/receiving/picking/inventory/support — **zero** Line 2 coverage):
   - `line2_active_jobs`, `line2_building`, `line2_curing`, `line2_processing`, `line2_labelling`, `line2_qc_measure`, `line2_qc_final`, `line2_sleeve`, `line2_packing`, `line2_tools` (all module `line2`)
   - `sleeve_calculator` (module `supervisor_tools` — it's a planning tool for a supervisor deciding how many sleeves to build, not a shop-floor step)
   - `cutting` (module `line1`)
   - Actions on each screen were derived directly from the exact `require_pdt(screen_key, action_key)` calls already present in the deployed API code — these screens don't grant any capability the code didn't already implement, they just make the existing capability reachable and configurable instead of dark.
   - All 12 require role **System Manager**, matching every one of the other 14 existing screens exactly. Nothing on this bench today uses finer-grained PDT roles — see §3 for what that means for you.
   - `line2_curing` / `line2_processing` are worth knowing about: their Flutter screens call the *same* backend functions as `line2_building` (`scan_flowchart` / `complete_step`), so their PDT Screen record only controls whether the tile appears in the menu — the actual write permission is enforced under `line2_building`'s gate at runtime either way.
3. **Warehouses wired into Manufacturing Settings URBM** — the good news: 4 of 5 Line 2 warehouses, plus the Cutting warehouse, **already existed** on this bench (created ahead of the settings that reference them, apparently) — they were just never linked:

   | Settings field | Warehouse linked | Was it new? |
   |---|---|---|
   | `building_material_warehouse` | `Sleeve Building WH  - URBM` *(real name has a double space)* | already existed |
   | `building_wip_warehouse` | `Sleeve Building WIP - URBM` | already existed |
   | `sleeve_wip_warehouse` | `Sleeve Building WIP - URBM` (shared with above — no more specific candidate existed; code uses these for different purposes so sharing is safe) | already existed |
   | `finished_belt_warehouse` | `Finished Belt WH - URBM` | **created new** — the only genuinely new warehouse, filling an obvious gap in an otherwise-complete series (Curing/Grinding/Rib Grind/Measure/Inspect/Cutting all already had WH+WIP pairs) |
   | `line2_scrap_warehouse` | `Scrap - URBM` | already existed |
   | `cutting_warehouse` | `Cutting WH - URBM` | already existed (created during Phase 2 build/verification, then intentionally left linked now that you want live testing) |

   **Review the `finished_belt_warehouse` naming** — I picked "Finished Belt WH - URBM" to match the existing convention exactly; rename it if you'd prefer something else (Frappe warehouse renames don't lose data).

   Note: a fair amount of the existing warehouse tree (`Curing WH/WIP`, `Sleeve Grinding WH/WIP`, `Rib Grind WH/WIP`, `Measure WH/WIP`, `Inspect WH/WIP`) is **not referenced by any Line 2 code today** — the building/curing/processing/grinding steps all move stock through the native `Work Order.wip_warehouse` field instead, not warehouse-to-warehouse per step. Those warehouses look like they were built for a more granular per-step model that was never wired up. Not a blocker, just flagging it so it doesn't look like a bug when you notice stock never moves through them.

4. **3 Tool Master records seeded** (was 0 on the whole bench):
   - `MOLD-3PK-0855` (Mold), `AIRBAG-3PK-0855` (Airbag, `current_weight_kg=2.5`), `CURING-POT-01` (Curing Pot, `pot_capacity=2` — lets you test the multi-occupancy behavior too)
   - All clearly test-coded (`MOLD-`/`AIRBAG-`/`CURING-POT-` prefixes) so they're easy to find and delete later once you seed real tooling data.
5. **`Finance Approver` role granted to swalih** — this role had **zero users** system-wide. `approve_finance()` (the Purchase Receipt finance-approval step) hard-checks `frappe.get_roles()` for this exact role name with no Administrator-style bypass — without it, that action would throw a PermissionError for swalih specifically, even with System Manager.
6. **Workstation capacity fields set on 2 stations**, to make Feature 2 (capacity matching) demonstrable rather than a silent no-op:
   - `L2B1`: generous limits (50 / 2000 / 2000 mm) — will pass for the test item
   - `A1B1`: deliberately tiny limits (5 / 100 / 100 mm) — will be filtered out for the test item, so you can see the exclusion actually happen
   - All other 131 Workstations remain at 0/blank (unconstrained — unaffected, matches prior behavior).

### 1.3 Confirmed already fine, no action taken
- swalih already has an **active Worker Session** (`WS-0012`, workstation `Reception`, since 2026-07-07) — the mobile app should route straight to the home screen, not a workspace picker.
- swalih's **Worker Workstation Assignment** (`Reception, Mixer, Chemical Weighing, Calender, Putaway`) does *not* include any Line 2 or Cutting station. This is safe to leave as-is: `get_worker_stations()` is a read-only convenience endpoint (populates a "your stations" list in the UI) and is never cross-checked against the actual write actions — `require_pdt()`'s role check is the only real gate, confirmed by direct test (§4). If you want the UI's convenience list to include Line 2/Cutting stations, edit Worker Workstation Assignment `v7u5pnffpl` and add e.g. `L2B1, A1B1, Cutting` — optional, not required for testing.

---

## 2. THE remaining blocker: real belt items have no BOM

This is bigger than anything else on this list and isn't something I fixed, because it's a data-entry/business decision, not a code gap.

**0 of 1,196 items** in the three real belt/sleeve item groups (`PK-EPDM-RS`, `PK-CR-RS`, `PK-CR-CF`) have a submitted BOM — active or inactive. The `ITB-CR-*` family (484 more items) almost certainly matches the same pattern. This is tracked more broadly in the BOM Completion Plan work, but it's worth restating precisely here because of what it means for *this* test pass specifically:

**You cannot create a real Work Order for a real belt item today.** Native ERPNext requires a submitted BOM to create a Work Order at all. Which means the full "supervisor creates WO → system builds the flowchart of Job Cards → operator scans through Building→Curing→...→QC→Packing" journey **cannot be walked end-to-end with real production data** until at least one real item has a BOM.

What *can* be tested without a BOM (and is proven working, see §4): the Sleeves Calculator, the capacity-matching logic directly, Tool Usage Log checkout/checkin against a manually-created Job Card, and Cutting & Splicing (which doesn't use Work Orders at all).

Two ways to unblock the full journey, your call:
- **Real path**: complete BOM data entry for at least one real item (e.g. `20101603`, "3PK 0855 EPDM RS" — already has Sleeve Build Specification dims and a Belt UOM conversion factor of 88, see §5) — this is real business data (raw material lines, quantities) that needs your domain input, not something to fabricate.
- **Fast path for connectivity testing only**: create one minimal single-line test BOM (Desk UI → BOM → New → Item = `20101603` → add any one raw material row with qty 1 → Submit). This unblocks Work Order creation for walkthrough purposes but the quantities won't mean anything — don't mistake it for real production data.

**Update (same day, later)**: one worked-example BOM now exists — `107 YU CR 22-BOM-0469` on template `20100747`, created to prove the brand-variant BOM mechanism end-to-end (see §8). Its component quantities are placeholders (0.5 Kg sheet + 1 label per belt) — replace them with real lines, but keep the label-template row pattern exactly as it is.

---

## 3. Explicitly out of scope for this pass (your own calls, untouched)

Everything below was either something you said you'd do yourself, or was confirmed to have no effect on anything today:

- `default_operating_cost_account` on Company — still unset ("I will setup the operating cost account... later")
- Roles/users for anyone beyond swalih/Administrator — still just those two working accounts ("after all are working... I will create roles and users later")
- Tank `min_qty_kg` / Oil `max_capacity_kg` — still 0 ("I will set later, it currently doesn't affect anywhere")
- Machine bridge URLs (`machtech_base_url`, `chem_base_url`) — untouched ("machine API is running in local machine, no need to configure the details here for now")
- PO/PR/bin mappings, LOT population — untouched, you're creating your own test POs/PRs and will populate real LOTs for production yourself
- **`WMS Picker` / `WMS Supervisor` roles** — confirmed these still don't exist as Role records. Not currently a blocker: every PDT Screen (all 26, old and new) uses `System Manager` uniformly, and the code comments referencing these two role names in `lot.py`/`pick.py` are aspirational/stale, not what's actually configured. Worth creating for real before a production go-live with limited-privilege users, but not needed for this test pass since swalih has System Manager.
- **Universal Printer (0 records) / `Batch Label` print format (doesn't exist)** — still open. The `line2_labelling.print_label` action and packing/shipping label steps will run their backend logic fine, but nothing will physically print. Flagged, not fixed — this needs a real printer/print-format decision from you.
- `stream_item_group_map` (0 rows, weighing leg) — still open, unrelated to this pass.

---

## 4. Test script for swalih

Log in to the mobile app as `swalih.v@universal-rbm.com`. All 26 PDT Screens are now visible (confirmed live via `compiled_pdt_config()` — see verification note at the end of each section below).

### 4.1 Sleeve Calculator (NEW — supervisor tool, no BOM needed)
1. Open **Supervisor Tools → Sleeve Calculator**.
2. Enter item `20101603` and a desired belt quantity, e.g. `440`.
3. Expect: `sleeves_needed = 5`, `conversion_factor = 88`, `actual_belt_yield = 440`.
4. Try a quantity that doesn't divide evenly, e.g. `450` → expect `sleeves_needed = 6` (rounds up), `actual_belt_yield = 528` (real yield from rounding up).
5. Try an item with no Belt UOM conversion row → expect a graceful 1:1 fallback, not an error.

*Verified in this pass*: called the real mobile endpoint as swalih, got back exactly `{sleeves_needed: 5, conversion_factor: 88.0, actual_belt_yield: 440.0}` for `20101603` / `440`.

### 4.2 Cutting & Splicing (NEW — Line 1)
1. Open **Compound Production → Cutting & Splicing**.
2. Scan/enter a source sheet batch. **Today this list will be empty** — 0 Calendering Runs have ever been executed on this bench, so there's no calendered sheet stock sitting in Finished Sheet WH yet. Either run a real calendering batch first (see `full-flow-handover-test-plan.md` §4 for the concrete chain), or seed a test batch via console if you just want to prove the screen mechanically.
3. Once a source batch is available: enter a target item, input qty (≤ available), output qty. Confirm and submit.
4. Expect: a new Batch of the target item created in `Cutting WH - URBM`, a `Cutting Log` row, and a `Warehouse LOG` row with `movement_type = "Cut & Splice"`.

*Verified in this pass*: `cutting_warehouse` is now linked; the full Repack mechanics were already proven end-to-end in the Phase 2 build (100kg seeded → 60kg consumed → 40kg remaining + 55kg new target batch). Only the warehouse link was missing before; it's set now.

### 4.3 Tool Usage Log (NEW — real audit trail, via Line 2 Building)
1. Open **Belt/Sleeve Building → Sleeve/Belt Building** (or Tool Status).
2. Scan/select tool `MOLD-3PK-0855` against any open Job Card and check it out.
3. Expect: a new `Tool Usage Log` row, `status = Open`, `checked_out_at` populated.
4. Complete the step / release the tool.
5. Expect: the same log row now `status = Closed`, `checked_in_at` populated, `duration_minutes ≥ 0`.
6. Optional — test pot multi-occupancy: check `CURING-POT-01` (`pot_capacity = 2`) out against two different Job Cards; releasing the first must leave its log `Open` (pot still occupied by the second); only releasing the second closes both.

*Verified in this pass*: ran exactly this sequence against the real seeded `MOLD-3PK-0855` and a real Job Card — checkout opened the log, checkin closed it with a real duration.

### 4.4 Workstation capacity matching (Feature 2 — indirect, needs a Job Card)
This one is genuinely hard to click through in the UI today because it only shows up during Job Card creation for a Work Order, which is blocked by §2's BOM gap. To see it in action without a WO:
- Console proof (already done, repeatable): filtering `"L2B1,A1B1"` for item `20101603` (dims 10.68×855×950mm) returns only `["L2B1"]` — `A1B1`'s deliberately tiny limits (5×100×100mm) correctly exclude it.
- Once §2 is resolved for at least one item, creating a Work Order + Job Card against a step whose `allowed_workstations` includes both `L2B1` and `A1B1` will show the same filtering live in the Job Card's assigned workstation.

### 4.5 Finance Approval (existing feature, previously untestable by swalih)
1. Find any submitted Purchase Receipt with a pending finance status.
2. As swalih, call/click **Approve Finance**.
3. Expect: success now (previously would have thrown `PermissionError` — swalih didn't have the `Finance Approver` role until this pass).

### 4.6 Everything already working (regression sanity, not new)
Receiving (1,305 real Purchase Receipts exist), GRN/putaway, and the rest of the 14 pre-existing PDT screens are unaffected by anything in this pass — no changes were made to their config or code.

---

## 5. Test data reference

| What | Value |
|---|---|
| Test item | `20101603` — "3PK 0855 EPDM RS", item group `PK-EPDM-RS`, `stock_uom = Sleeve` |
| Sleeve Build Specification dims | width 10.68mm, length 855mm, height 950mm |
| Belt UOM conversion factor | 88 (1 Sleeve = 88 Belts) |
| Production Type | `PK` (category Belt, qc_mode "Belt UOM", 6-step route incl. rib grind) |
| Seed Tool Master | `MOLD-3PK-0855`, `AIRBAG-3PK-0855`, `CURING-POT-01` |
| Capacity-configured Workstations | `L2B1` (generous, passes), `A1B1` (tiny, excluded) |
| Only item anywhere with Belt UOM + a submitted BOM | `E2E-BELT-PK-6PK1200` — a synthetic test fixture from an earlier `test_line2_e2e.py`-style test, `stock_uom = Nos`, no Sleeve Build Specification. Usable for pure WO/JobCard pipeline mechanics, not representative of real production data. |

---

## 6. Full config snapshot at end of this pass

<details>
<summary>PDT Screens (26 total, click to expand)</summary>

All 26 screens require role `System Manager` only. 14 pre-existing (receiving/picking/inventory/line1/support), 12 created this pass (10 `line2_*` + `sleeve_calculator` + `cutting`).
</details>

- PDT Modules: 7 (`receiving`, `picking`, `inventory`, `supervisor_tools`, `line1`, `line2` *(new)*, `support`)
- Manufacturing Settings URBM: all Line 1 + Line 2 + Cutting warehouses now linked (full list in §1.2); `compound_warehouse`, `default_silo_mr_warehouse`, `default_weighing_mr_warehouse`, `default_oil_mr_warehouse`, generic `scrap_warehouse`, `cutting_wip_warehouse` remain unset — confirmed unreferenced by any current code path, left alone
- Tool Master: 3 records (was 0)
- Finance Approver role: 1 user (swalih) (was 0)

---

## 7. Troubleshooting / bench quirks

- **Scheduler and warehouse-link state have both been observed to reset after a DB restore in earlier sessions.** Don't assume this pass's config is permanent — re-check §0's table (or re-run the setup script, which is idempotent) at the start of a session if anything seems to have reverted.
- After adding a new module to an app's `modules.txt`, always `bench --site site1.local clear-cache` **before** `bench migrate` — otherwise doctype sync silently skips it and post-sync patches get marked executed without doing anything.
- `bench console` mangles piped stdin on this bench — for scripted checks use `cd sites && ../env/bin/python script.py` with `frappe.init("site1.local"); frappe.connect()`.
- `Manufacturing Settings URBM` is **not actually a Single** doctype (`issingle=0`) despite behaving like one (exactly one auto-hash-named record) — always fetch it via `manufacturing_universal.silo_loading._get_settings()`, never `frappe.get_single(...)` (throws `DoesNotExistError`).
- `WMS Settings` **is** a real Single — use `frappe.db.get_single_value("WMS Settings", "fieldname")`, not `frappe.db.get_value(..., {}, "name")` (that pattern gives a false null for Singles).
- `bench run-tests` is unreliable on this bench for reasons unrelated to any of the 4 Phase 2 features: even with `--skip-before-tests`, Frappe's own test-record bootstrapping throws on this data-filled site (`"Please set default inventory account for item Loyal Item"` — reproduces on brand-new `IntegrationTestCase`-based files too, confirmed this pass). Console-based verification (as used throughout this pass) is the reliable path until that gets root-caused separately.

---

## 8. Brand-variant BOMs (one BOM per belt model, label resolves per brand)

Verified live 2026-07-08. The mechanism was already built (`manufacturing_universal/brand_variant_bom.py`, wired into Work Order `validate` in hooks.py) but had never been exercised — no template BOM existed to trigger it. It now has a worked example and a full end-to-end proof behind it.

### How it works (no manual steps at production time)

1. **You create ONE BOM per belt model**, against the **template** item (e.g. `20100747` "107 YU CR 22"). Common components (sheets, cord, …) are normal rows. The label row is the **label template** (e.g. `60100001` "107 YU CR 22_Label") — the `has_variants` flag on the row auto-fetches from the item, no manual flag needed.
2. **The supervisor creates the Work Order for the brand's FG variant** (e.g. `20100747-Raykalton`). Desk auto-picks the template's default BOM (native ERPNext fallback for variants).
3. **On save, the hook takes over** (`apply_brand_variant_bom`): first time a brand is produced, it auto-creates and submits a brand-specific BOM (e.g. `107 YU CR 22-Raykalton-BOM-XXXX`) with the label row resolved to that brand's label variant (`60100001-Raykalton`), sets it as the WO's BOM, and repopulates required items. Every later WO for the same brand reuses that generated BOM — exactly one per brand per model, created on demand.
4. **`complete_wo` (final QC step on the PDT) consumes the brand's label** — proven live: Manufacture Stock Entry consumed `60100001-Raykalton` (not the template) + sheet from `Sleeve Building WH  - URBM`, produced batched `20100747-Raykalton` into `Finished Belt WH - URBM`.

The brand link is the `custom_brand` field on Item, which `universal`'s `sync_brand` hook enforces from the Brand variant attribute on every Item save — so variants you create later (Mito, Hanchang, …) via Desk's "Create Variant" button sync automatically.

### What you need to do per belt model

1. Make sure the FG template + label template exist, plus a variant of **each** for every brand you'll produce (Desk → template item → Create Variant → pick Brand). All 12 trial models already have Raykalton variants of both.
2. Create the template BOM with real component lines + the label-template row (qty = labels per BOM unit — e.g. 88 labels per 1 Sleeve for a factor-88 item, or 1 per Belt for Belt-UOM items).
3. Nothing else — Work Orders per brand handle themselves.

### Worked example kept on the system

`107 YU CR 22-BOM-0469` on template `20100747`: 0.5 Kg of sheet `20100722` + 1 Nos of label template `60100001` per belt. **Component quantities are placeholders** — swap in real lines; the label row is the pattern to copy.

### Caveats found during verification

- **If a brand's label variant doesn't exist, WO creation fails with a clear error** ("No '60100001' variant found for brand 'X'. Create the brand-specific item variant…"). That's intended — create the label variant, retry. Disabled variants are ignored on purpose.
- **Generated brand BOMs are cached, not synced**: if you later change a template BOM (add/replace component lines), existing generated brand BOMs do NOT update. Cancel/delete the generated brand BOMs (they're named `<model>-<Brand>-BOM-…`) and they regenerate from the updated template on the next WO. This matters for the worked example above — after you put real lines into `…-BOM-0469`, there's nothing stale to delete (the proof's generated BOM was already removed), but remember this whenever you revise a template BOM later.
- **"No Brand" production**: there's a `No Brand` attribute value but no label variants for it yet. If unbranded belts should consume a blank label, create `<label>-No Brand` variants; if they should consume nothing, that needs a small code change (skip rule) — flag it when you get there.
- **Brand Label inventory accounts were missing** (the reason the first proof run failed): all 24 Brand Label items now have `110404 - Inventory - Raw Material - URBM` as their default inventory account. **Review this account choice** — change it on the items if labels should post elsewhere.
- Labels are batch-tracked (`has_batch_no=1`, auto-batch) like everything else, and must be stocked in `Sleeve Building WH  - URBM` (the building material warehouse) to be consumable at WO completion — receive them there via your PO/PR flow or a Material Receipt.

### Test script for swalih (add to §4)

1. Desk → Work Order → New → Production Item `20100747-Raykalton`, qty 2 → Save. Expect: BOM field flips from `107 YU CR 22-BOM-0469` to a new `107 YU CR 22-Raykalton-BOM-…`, and Required Items shows `60100001-Raykalton`.
2. Save again / create a second WO for the same variant. Expect: same generated BOM reused (no duplicate).
3. Stock the label variant + sheet in `Sleeve Building WH  - URBM`, submit the WO, run the QC-final complete step from the PDT (or `complete_wo` from console). Expect: Manufacture Stock Entry consumes the **Raykalton** label; finished batch of `20100747-Raykalton` lands in `Finished Belt WH - URBM`.
4. Negative test: create a `Mito` variant of the FG **without** creating the Mito label variant, then try a WO for it. Expect: clear "No '60100001' variant found for brand 'Mito'" error at save.
