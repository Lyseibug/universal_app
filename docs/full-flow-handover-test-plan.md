# Full-Flow Handover Test Plan — WMS + Compound + Calendering (PDT, Prints, End-to-End)

**Purpose:** verify the complete flow — PO reception → put-away → material request → pick → silo/oil/weighing load → mixer loading → machine production → compound lab test → calendering → label printing — actually works on real hardware (PDT app + physical printer) before handing this system to the client.

**Written:** 2026-07-06, against the live state of this bench (`universal` site) as audited in `GOLIVE-DOC.md` §0. Every API call, screen key, action key, and field name below is taken directly from the current code (`universal_mobile_api`, `manufacturing_universal`, `wms_universal`, `universal` apps) — not from the missing companion docs referenced in `GOLIVE-DOC.md` (`testdocs/calendering-sheet-movement-golive-testing.md` and `universal_app/APP_DOC.md` do **not exist** on this bench; this document replaces them).

**Companion doc:** `GOLIVE-DOC.md` — read §0 first. This test plan assumes you are working through the gaps it lists, not that they're already fixed.

---

## 0. How to use this document

**Start with §4 (End-to-end user journey)** — it walks one real thread of data through every role and screen in the order it actually happens, PO to finished sheet. Come back to §5 onward (the per-screen technical suites) to dig into edge cases at any one step.

Each technical suite (§5+) has:
- **Blocked by** — config that must exist first (cross-referenced to `GOLIVE-DOC.md`). If it's not done, skip to fixing it — don't try to test around it.
- **Test cases** — ID, precondition, steps, expected result, pass/fail box.
- Steps are written as **PDT app actions** (what the floor worker taps/scans) with the exact underlying API call in a code block underneath, so the same test case can be run two ways:
  1. Through the actual Flutter app, once built and pointed at this site.
  2. Directly via REST, for testing the backend logic *before* the app is ready — `POST /api/method/<module>.<function>` with header `Authorization: token <api_key>:<api_secret>` (obtained from the `login` call in TS-0).

Do not mark a checkbox done from a `bench console` call alone if the real path is the PDT app + physical device — note it as "backend verified, device verification pending" instead. The point of this pass is to catch what only shows up on real hardware (barcode scan reliability, print rendering, network drop handling), not just re-prove the Python logic.

---

## 1. Readiness gate — must be true before you can even start

Pulled directly from `GOLIVE-DOC.md` §0. If a row is ❌, the corresponding test suite later in this doc **cannot** be executed at all (the screen doesn't exist, or the config it needs is empty) — fix it first.

| Needed for | Config | Status as of 2026-07-06 | Blocks |
|---|---|---|---|
| Every PDT test | PDT Screens for the flow you're testing (**registration only** — this row is about whether the PDT Screen record exists at all, not whether the underlying logic works) | Only 6/14 exist: `grn_putaway`, `pick_list`, `physical_inventory`, `lot_browser`, `manual_transfer`, `support`. **Missing entirely**: `po_reception`, `manufacturing_mr`, `material_loading`, `mixer_loading`, `weighing_load`, `bag_view`, `compound_lab_test`, `calendering` | Blocks driving these through the **actual PDT app** — backend logic can still be tested directly against the API for all of them (see per-suite notes; TS-5's Silo/Oil logic in particular is already done, just not screen-registered) |
| Every PDT test | Screens granted to real operational roles, not just `System Manager` | All 6 existing screens are `System Manager`-only | All PDT suites, if testing as a non-admin operator — **not a concern right now per your instruction to test as System Manager** |
| TS-2 (put-away) | `grn_putaway` action rows | Stale: configured as `put_away`/`override_suggested_lot`/`override_capacity`, code expects `create_batch`/`allocate_bin`/`override_capacity` | TS-2 — pending your go-ahead to fix |
| TS-5 (silo/oil load) | Tank Lot Assignment (12/12 rows) → stream resolution | ✅ **Logic done** — fixed and tested 2026-07-06, `_resolve_stream()` now reads Tank Lot Assignment directly, verified against all 12 real items | Only the `material_loading` **screen record** is still missing (see row above) — the code path itself is not blocked |
| TS-5 (weighing load) | `stream_item_group_map` row for the Chemical Bags item group (or whichever group your weighing items sit in) | ❌ 0 rows — weighing items still cannot resolve a stream | This is the one real logic gap left in TS-5, and it's Weighing-only — Silo/Oil are unaffected |
| TS-6 (mixer loading) | `mixer_wip_warehouse` set | ✅ Set (`Mixer WIP - URBM`) | — |
| TS-7 (machine production) | Machine bridge connected | ✅ **Corrected 2026-07-06**: the bridge *is* connected — it runs standalone (own `config.json`, not the site's `machtech_base_url`/`chem_base_url` fields, which turned out to be unused by it) and has already synced real data: 258 Formula-BOM Mappings, 205 BOMs, all created 2026-07-02/03 by a dedicated `machineapi@` user. **Real open gap instead**: `Machine Material Map` is still 0 rows — machine codes are being resolved by creating Items with `custom_formula_bom_code` set (works, confirmed live), but 17 `Unmatched Machine Record` entries from before that fix still sit in `status="Pending"` and do not auto-clear (see TS-7 below) | TS-7 (retest scope changed, not blocked) |
| TS-8 (lab test) | `Quality Manager` role assigned to a test user | Role exists; confirm a test user has it | TS-8 |
| TS-9 (calendering) | Liner/Cylinder roll Items + Store/In Use warehouses + opening qty | ✅ Done (2026-07-04/06 rework — pooled stock, not Tool Master) | — |
| TS-9 (calendering) | Named Workstation `Calender` (+ `Mixer`, `Chemical Weighing`) with `hour_rate`, linked in Manufacturing Settings URBM | ⚠️ **Updated 2026-07-06**: all three Workstations now exist and are correctly linked in Manufacturing Settings URBM. **But `hour_rate = 0` on all three** — `_compute_overhead_cost` silently no-ops on a zero rate, so overhead is still not actually being costed | Overhead costing only — doesn't block the flow itself |
| TS-10 (printing) | `Compound Batch Label` print format | ✅ Ships and renders | — |
| TS-10 (printing) | `Universal Printer` record + running print-relay agent | ❌ 0 Printer records; relay agent not verified | TS-10 |
| TS-11 (alerts) | Scheduler enabled | ✅ Enabled | — |
| TS-11 (alerts) | `idle_alert_minutes` intentionally set | Currently `10` — **check this is what you want**; `GOLIVE-DOC.md` §15 recorded a decision to defer idle alerts (`= 0`) for Phase 1 that was never actually applied | TS-11 |
| TS-11 (alerts) | Tank `min_qty_kg` set on at least one Tank Lot Assignment | ❌ All 12 are `0` — low-tank alert can't be tested until at least one has a real threshold | TS-11 (low-tank half) |

**If you're running this test pass specifically to find out "what's left before handover," don't try to force your way past a ❌ row with a console shortcut — that's exactly the gap the client needs to know about.** Log it, move to the next testable suite, come back once it's fixed.

---

## 2. Environment & tooling

**Test users needed** (create if missing, one per role, each linked to a real Employee via `user_id` — only 10/171 Employees currently have this):

| Role | Used for |
|---|---|
| System Manager | Fallback while other screens are still admin-only |
| `WMS Picker` (create — doesn't exist yet) | TS-4 (pick) |
| `WMS Supervisor` (create — doesn't exist yet, or use System Manager) | TS-3 (lot browser / manual transfer) |
| `Quality Manager` | TS-8 (compound lab test) |
| `Finance Approver` | TS-1 (finance approval) |
| Lab user (Desk) with Incoming Lab Test write+submit | TS-1 (incoming lab pass) |

**Getting an API session** (needed for every REST-style test step below):

```
POST /api/method/universal_mobile_api.api.session.login
{"usr": "<employee_code_or_username>", "pwd": "<password>"}
→ {"token": "<api_key>:<api_secret>", "employee": "...", "roles": [...]}
```
Use `Authorization: token <api_key>:<api_secret>` on every subsequent call.

**Workspace selection** — the intended flow is `list_workspaces` → `select_workspace`, but `assert_active_workspace()` is currently commented out in `permissions.py` (a known gap, `GOLIVE-DOC.md` §15 #11), so calls will succeed even without selecting a workspace. Test both ways:
- TS-0.1: select a workspace properly, confirm `Worker Session` created and `list_workspaces`/`select_workspace` behave correctly.
- TS-0.2 (regression check for the known gap): skip workspace selection entirely, confirm a write call (e.g. `material_loading.load`) still succeeds — if the client wants workspace enforcement, this is where you'd catch that it's currently *not* enforced.

**Idempotency** — every write action takes a `request_id`. It's a **global key across all actions**, not per-action (`GOLIVE-DOC.md` §15 #11) — verify this explicitly:
- TS-0.3: call `material_loading.load` with `request_id="TEST-UUID-1"`, note the result. Call `pick.submit` with the **same** `request_id="TEST-UUID-1"`. Expected (per current code): the second call returns the **first call's cached response** instead of doing pick work — this is a real bug to confirm/reconfirm, not a false alarm. If fixed, this test should instead show the second call executing normally.

---

## 3. Test data to seed before running the suites

Use real existing master data where possible (this bench has 5,724 Items, 1,303 Purchase Receipts, etc.) — don't invent parallel test items unless a suite specifically needs a disposable one (calendering sheet batches, see TS-9).

- One **Supplier** and one draft→submitted **Purchase Order** with 2–3 line items (mix of a lab-tested raw material and a non-lab item, if your item master distinguishes them) — needed for TS-1.
- Confirm at least one item in each of: a Silo-mapped item group, an Oil-mapped item group (both covered by the 12 existing Tank Lot Assignments — e.g. item `30100044` → `SILO 1`), and a Weighing/Chemical Bags item (will fail until `stream_item_group_map` gets a row — see Readiness Gate).
- One eligible FMB batch for calendering (`Compound Lab Test` result = Pass or Conditional Pass, sitting in FMB Zone with qty > 0) — you likely need to run TS-6/TS-7/TS-8 first to produce one, or seed one directly for calendering-only testing.

---

## 4. End-to-end user journey — PO to finished sheet, in the order a real user does it

Everything in §5 onward is organized as **technical suites** (one screen/module at a time) so you can re-test any piece in isolation later. This section is the opposite view: **one continuous run**, following a single thread of real data through every role and every screen, in the order it actually happens on the floor. Run this first — it's what "does the system actually work end to end" really means. Use the technical suites afterward to dig into edge cases at each step.

**Running example** (swap in your own real values, but keep the same item/batch flowing through every step so you can trace it): Supplier `Acme Rubber Supplies`, raw material item `30100044` (Filler, already mapped to `SILO 1` in Tank Lot Assignment) at 5,000 Kg, feeding into an FMB formula that gets calendered into a sheet item.

A second item in a Weighing/Chemical Bags group is included at step 1 to show where the flow **currently breaks** (stream_item_group_map is empty) — either skip it for a today's-date full run, or fix that one config row first and include it.

| # | Role | Where | What they do | What happens | Detail in |
|---|---|---|---|---|---|
| 1 | Procurement | Desk | Create Supplier `Acme Rubber Supplies` (if new) → create Purchase Order → 2 lines: `30100044` (Filler, Silo) qty 5,000 Kg, and one Chemical-Bags item qty 500 Kg → submit | PO submitted, status "To Receive" | TS-1 |
| 2 | Warehouse receiving clerk | PDT `po_reception` (**not yet built** — call `po_reception.submit_reception` directly for now) | Scan/select the PO → confirm both lines → submit reception | Purchase Receipt created + submitted into the WMS Settings inbound warehouse; PR's `on_submit` auto-creates a Received Item + Incoming Lab Test per line | TS-1 |
| 3 | Lab technician | Desk (Incoming Lab Test) | Open the auto-created Incoming Lab Test for the Filler line → enter results → Pass | `custom_lab_status` progresses toward "cleared" | TS-1 |
| 4 | Finance approver | Desk (Purchase Receipt) | Open the PR → **Approve Finance** | `custom_finance_status`/`approved_by`/`approved_on` set — line now `ready_for_allocation=1` once both lab + finance clear | TS-1 |
| 5 | Warehouse worker | PDT `grn_putaway` (**exists, but action rows are stale — fix first, see TS-2**) | Scan the cleared line → `create_batch` (enter qty, production date) → system suggests a bin → scan the bin (or a different one, needs override) → `allocate_bin` | Production batch created; stock moves inbound WH → the bin (Warehouse LOT); `Compound Batch Label`/`Batch Label` print job queued | TS-2 |
| 6 | Production planner | PDT `manufacturing_mr` (**not yet built** — call `manufacturing_mr.create` directly) | Create a Manufacturing Material Request: `30100044`, qty 5,000 Kg, `target_stream="Silo"` (the Chemical-Bags line would use `target_stream="Weighing"` — **this is where it currently dead-ends**, §1) → submit → `create_pick_list` | MR submitted; WMS Pick List + Pick List Items generated | TS-4 |
| 7 | Warehouse picker | PDT `pick_list` (exists, correctly configured) | `claim` the pick item → scan the suggested bin → `pick.submit` with the picked qty | Stock Entry moves the item from the bin toward the Outside Silo warehouse; pick item → Completed | TS-4 |
| 8a | Silo/Oil operator | PDT `material_loading` (**not yet built** — call `line1_loading.resolve` / `load` directly) | Scan `30100044` → system resolves `stream="Silo"` (via Tank Lot Assignment, fixed 2026-07-06) → confirm qty → `load` | FIFO transfer Outside Silo WH → Inside Silo WH (`SILO 1`'s LOT); tank capacity checked; `LOT Stock Line` + fill % updated | TS-5 |
| 8b | Weighing operator | Same screen, Chemical-Bags item | Scan the weighing item → `resolve` | **Currently throws** `"No stream mapping configured..."` — add a `stream_item_group_map` row for that Item Group to unblock this leg | TS-5 |
| 9 | Mixer operator | PDT `mixer_loading` (**not yet built** — call `line1_mixer.load` directly) | For any non-stream inputs the formula needs (chilled polymer, direct-add chemicals staged in Mixer Staging) — scan and `load` into Mixer WIP. (Silo/Oil items from step 8a don't need this step — the machine draws them directly from Inside Silo/Oil when it reports production, step 10.) | Material Transfer staging → Mixer WIP | TS-6 |
| 10 | *(machine, not a person)* | Real mixer machine, or console-simulated | Machine runs the formula, consumes `30100044` from Inside Silo WH + whatever was loaded in step 9, reports production | FMB batch created in FMB Zone; `custom_lab_status="Pending"`; draft Compound Lab Test auto-created; tank's `LOT Stock Line` decremented (`deduct_lot_stock`); Compound Batch Label auto-printed | TS-7 |
| 11 | Quality Manager | PDT `compound_lab_test` (**not yet built** — call `line1_lab.submit_lab_test` directly) | Open the FMB batch from step 10 → enter parameter results → submit | Compound Lab Test submitted; `custom_lab_status` → Pass/Fail/Conditional; **Fail blocks steps 12+** for this batch | TS-8 |
| 12 | Calendering operator | PDT `calendering` (**not yet built** — call `line1_calendering.start_run` directly) | Scan the Pass'd FMB batch → enter input qty → `start_run` | Material Transfer FMB Zone → Calendering WH; Calendering Run "In Progress" | TS-9 |
| 13 | Calendering operator | Same screen | For each sheet produced: enter item/qty/thickness + pick one Liner item + one Cylinder item (scanned or selected from `list_roll_stock`'s available pool) → enter liner/calendar returns + excruder sludge → `complete_run` | Sheet batch(es) created in Finished Sheet WH; roll items moved Store→In Use (1 Nos each); mass balance checked; Compound Batch Label printed | TS-9 |
| 14 | *(system, automatic)* | — | Once the sheet batch's stock is later fully consumed downstream (cut, packed, sold, whatever your next stage is) | `release_exhausted_rolls` fires automatically, returns the roll items In Use → Store | TS-9 |
| 15 | Anyone | Desk or PDT | Check `list_roll_stock`, `list_tank_status`, Finished Sheet WH stock | Confirms the whole thread is now visible end to end: less raw material in the tank, a finished sheet batch in stock, roll tools back at baseline | — |

**What this run actually proves, right now (2026-07-06), if you execute it via direct API calls today:**
- Steps 3–5, 7 (lab, finance, put-away, pick) work through the one **existing** relevant screen (`grn_putaway`, once TS-2's stale actions are fixed) or Desk.
- Steps 2, 6, 8, 9, 11, 12–13 all work at the **backend/API level** today (verified this session for 8a and 13's roll logic specifically) but have **no PDT Screen record yet** — so a real device can't drive them until those 8 screens are created. That's the one gap that determines whether this whole journey can run on an actual handheld tomorrow, not any remaining logic bug.
- Step 8b (Weighing) is the one **logic** gap left in the chain — fix the stream map row and it closes.

---

## 5. TS-1 — PO Reception → dual approval → Purchase Receipt

**Blocked by:** `po_reception` PDT screen doesn't exist — test the Desk half now, PDT half once the screen is created.

| ID | Precondition | Steps | Expected | Pass |
|---|---|---|---|---|
| TS-1.1 | Submitted PO exists | **PDT** (once screen exists): open `po_reception` → `list_pending()` → `get(purchase_order)` → select lines → `submit_reception(purchase_order, items, request_id)`. **Backend now:** call `universal_mobile_api.api.po_reception.submit_reception` directly with the same payload | Purchase Receipt created, submitted, warehouse = WMS Settings `inbound_warehouse`; PR's `on_submit` hook fires (creates Received Item + Incoming Lab Tests) | ☐ |
| TS-1.2 | PR from TS-1.1 | Over-receive: call `submit_reception` with `qty` > pending for a line | `PdtError OVER_PENDING_QTY` | ☐ |
| TS-1.3 | PR from TS-1.1 | Desk: lab user completes Incoming Lab Test → Pass | `custom_lab_status` progresses; Received Item Line `ready_for_allocation` flips only once **both** lab and finance clear (check `wms_universal.put_away` logic) | ☐ |
| TS-1.4 | PR from TS-1.1 | Desk: Finance Approver clicks **Approve Finance** on the PR | `custom_finance_status`/`custom_finance_approved_by`/`custom_finance_approved_on` set | ☐ |
| TS-1.5 | Finance not yet approved | Desk: non-Finance-Approver user opens the PR | **Approve Finance** button not visible / action blocked | ☐ |
| TS-1.6 | — | Attempt PO reception/approval flow with `enable_item_wise_inventory_account` in play, using an item with no inventory account default | Confirm it throws `"Please set default inventory account for item …"` (same error hit live during this session's own testing) — or confirm the item DOES have a default and posts clean | ☐ |

---

## 6. TS-2 — Bin put-away (`grn_putaway`)

**Blocked by:** action rows are stale right now — fix before running write test cases (TS-2.3+).

| ID | Precondition | Steps | Expected | Pass |
|---|---|---|---|---|
| TS-2.1 | Fix stale action rows first | Desk: PDT Screen `grn_putaway` → Actions child table → replace `put_away`/`override_suggested_lot` with `create_batch`, keep/add `allocate_bin`, `override_capacity` | Saved config matches code's `require_pdt("grn_putaway", "create_batch")` / `("grn_putaway", "allocate_bin")` / `("grn_putaway", "override_capacity")` | ☐ |
| TS-2.2 | Lines with `ready_for_allocation=1` exist (from TS-1) | `list_pending()` | Returns the cleared lines with item/UOM/batch info | ☐ |
| TS-2.3 | Line from TS-2.2 | `create_batch(received_item_line, qty, production_date, expiry_date, request_id)` | New production batch created via Repack in the inbound warehouse; batch_no returned for label printing (feeds TS-10) | ☐ |
| TS-2.4 | Batch from TS-2.3 | `suggest_lot(received_item_line, qty)` | Returns a suggested Warehouse LOT with available capacity | ☐ |
| TS-2.5 | — | `allocate_to_bin(received_item_line, lot, qty, batch_no, force_capacity=0, suggested_lot, request_id)` scanning the **suggested** lot | Stock moves inbound WH → LOT; `LOT Stock Line` updated; Warehouse LOG written | ☐ |
| TS-2.6 | — | Same, but scan a **different** lot than suggested, without `override_suggested_lot` role/action | Blocked (`PermissionError`) unless the user has the override action | ☐ |
| TS-2.7 | LOT at/near capacity | `allocate_to_bin(..., force_capacity=0)` for a qty that exceeds bin capacity | Throws capacity error; retry with `force_capacity=1` (needs `override_capacity`) succeeds and should be visibly flagged as an override | ☐ |
| TS-2.8 | — | `list_created_batches(received_item_line)` | Shows the batch from TS-2.3 with remaining un-allocated qty | ☐ |

---

## 7. TS-3 — Lot browser / manual transfer

**Blocked by:** none (both screens already exist) — good suite to prove out the PDT app end-to-end even before the bigger screens are built.

| ID | Steps | Expected | Pass |
|---|---|---|---|
| TS-3.1 | `browse(warehouse=None, only_occupied=1)` | Lists occupied bins only | ☐ |
| TS-3.2 | `browse(item=<item_code>)` | Restricts to bins containing that item, via `LOT Stock Line` | ☐ |
| TS-3.3 | `get(lot)` on a bin with contents | Full contents incl. batch, qty, expiry | ☐ |
| TS-3.4 | `transfer(from_lot, to_lot, item, batch_no, qty, request_id)` | Bin-to-bin Stock Entry + Warehouse LOG posted; source decremented, dest incremented | ☐ |
| TS-3.5 | `transfer` into a full/reserved bin (e.g. a Tank Lot Assignment bin, `is_reserved=1`) | Should reject — tank bins are capacity/reservation-locked (§8.1) | ☐ |
| TS-3.6 | `transfer(from_lot=X, to_lot=X, ...)` | `PdtError VALIDATION` "Source and destination bins are the same" | ☐ |

---

## 8. TS-4 — Material Request → FIFO Pick

**Blocked by:** `manufacturing_mr` PDT screen doesn't exist; `pick_list` does and is correctly configured.

| ID | Steps | Expected | Pass |
|---|---|---|---|
| TS-4.1 | (once screen exists) `create(items=[{item_code, required_qty, target_stream}], remarks)` — `target_stream` must be `Silo`/`Oil`/`Weighing` | Manufacturing Material Request created in draft | ☐ |
| TS-4.2 | `create` with an invalid `target_stream` (e.g. `"Mixer"`) | `PdtError VALIDATION "Invalid stream"` — confirms §15 gap #12 (no direct-to-Mixer-Staging stream) is still open | ☐ |
| TS-4.3 | MR from TS-4.1 | `submit_mr(name, request_id)` | MR submitted | ☐ |
| TS-4.4 | Submitted MR | `create_pick_list(name, request_id)` | WMS Pick List + Pick List Items created | ☐ |
| TS-4.5 | Pick items exist | `pick.list(material_request=name)` | Items ordered Unassigned → In Progress → Completed | ☐ |
| TS-4.6 | Pick item | `pick.claim(pick_item)` as Worker A, then `claim` again as Worker B | Worker B gets `PdtError FORBIDDEN` — item already claimed | ☐ |
| TS-4.7 | Claimed item | `pick.get_by_scan(pick_item_id)` using the **printed barcode**, not the doc name | Resolves correctly — proves the barcode-driven scan path, not just name lookup | ☐ |
| TS-4.8 | Claimed item | `pick.submit(pick_item, actual_lot=<suggested_lot>, picked_qty, request_id)` | Stock Entry + LOG posted, item status → Completed (or partial → still In Progress) | ☐ |
| TS-4.9 | Claimed item | `pick.submit` with `actual_lot` ≠ suggested, without the override action | Blocked — needs `override_suggested_lot` | ☐ |
| TS-4.10 | — | Full MR → pick list → pick cycle, then check MR status | Confirm/reconfirm §15 gap #3: MR status stalls at "Picked", `loaded_qty` never written (cosmetic only, but note it) | ☐ |

---

## 9. TS-5 — Silo / Oil / Weighing load (`material_loading`)

**Blocked by:** screen doesn't exist yet. Weighing half also blocked by empty `stream_item_group_map`. Silo/Oil half is code-ready as of 2026-07-06 (Tank Lot Assignment drives stream resolution directly).

| ID | Precondition | Steps | Expected | Pass |
|---|---|---|---|---|
| TS-5.1 | Item with a Tank Lot Assignment (e.g. `30100044` → `SILO 1`), stock present in Outside Silo WH | `resolve(item_code)` → `manufacturing_universal.silo_loading.resolve_item` | Returns `stream="Silo"`, correct Outside warehouse, available qty | ☐ |
| TS-5.2 | Same item, no stock in Outside Silo WH | `resolve(item_code)` | Returns `qty=0` — UI should block loading, not throw | ☐ |
| TS-5.3 | Item from TS-5.1 | `load(item_code, qty, request_id)` | FIFO transfer Outside→Inside Silo; capacity validated against Tank Lot Assignment `max_capacity_kg`; `LOT Stock Line` updated for the tank's LOT; Warehouse LOG `"Silo Load"` written | ☐ |
| TS-5.4 | qty requested > tank `max_capacity_kg` remaining | `load(item_code, qty, request_id)` | Throws capacity-exceeded error — **except**: all 6 Oil tanks currently have `max_capacity_kg=0` (unlimited) — repeat this case for both a Silo item (should enforce) and an Oil item (won't enforce until capacity is set) | ☐ |
| TS-5.5 | Weighing/Chemical-Bags item, no Tank Lot Assignment | `resolve(item_code)` | Throws `"No stream mapping configured..."` — expected until `stream_item_group_map` gets a row; **do not** treat this as a regression, it's the known remaining gap | ☐ |
| TS-5.6 | — | `list_outside_stock()` / `list_inside_stock()` | Aggregated totals across all three streams, tagged with `stream` | ☐ |
| TS-5.7 | — | `list_tank_status()` | Fill % per tank; confirm the 12 real tanks show correct `current_qty`/`fill_pct` | ☐ |
| TS-5.8 | Legacy screens | Confirm `silo_loading`/`oil_loading` PDT screens are **not** activated | Per `GOLIVE-DOC.md` §10 — these bypass tank capacity + bin bookkeeping (Finding #17); should stay off | ☐ |

---

## 10. TS-6 — Mixer loading (`mixer_loading`)

**Blocked by:** screen doesn't exist yet.

| ID | Steps | Expected | Pass |
|---|---|---|---|
| TS-6.1 | `list_stageable()` | Batches in Mixer Staging / WIP Bags / CMB Zone | ☐ |
| TS-6.2 | `resolve(code)` scanning a staged batch barcode | Resolves to the right stageable stock line | ☐ |
| TS-6.3 | `resolve(code)` scanning a CMB batch with `custom_lab_status="Fail"` | Should be blocked/excluded — CMB lab-gate at mixer loading (`GOLIVE-DOC.md` §14a) | ☐ |
| TS-6.4 | Stageable batch | `load(item_code, qty, batch_no, source_warehouse, request_id)` | Material Transfer staging→`Mixer WIP`; Warehouse LOG `"Mixer Load"` written | ☐ |
| TS-6.5 | — | `list_wip()` | Shows what's currently loaded, awaiting machine consumption | ☐ |

---

## 11. TS-7 — Machine production (CMB/FMB) — bridge confirmed live

**Corrected 2026-07-06** — this suite was originally written assuming the bridge wasn't connected and needed console simulation. It **is** connected: it runs as a standalone process (own `config.json`, independent of the site's `machtech_base_url`/`chem_base_url` fields) and has already synced real formula/production data — 258 Formula-BOM Mappings and 205 BOMs, created 2026-07-02/03 by the dedicated `machineapi@universal-rbm.com` API user. Test against the **real bridge traffic** where you can; fall back to console simulation (`manufacturing_universal.machine_api_endpoints`) only for cases you can't easily trigger from the physical machines (e.g. TS-7.3/TS-7.4 edge cases).

| ID | Steps | Expected | Pass |
|---|---|---|---|
| TS-7.1 | Trigger a real FMB production run on the mixer (or console-simulate `receive_mixer_production`) | FMB batch created in FMB Zone; `custom_lab_status="Pending"`; draft Compound Lab Test auto-created | ☐ |
| TS-7.2 | Same for a CMB formula | CMB batch created in CMB Zone; **also** gets `custom_lab_status="Pending"` + draft Compound Lab Test (§14a: CMB now lab-tested exactly like FMB) | ☐ |
| TS-7.3 | Formula code containing "FMB" as a substring of an otherwise-CMB code | Confirm/reconfirm Finding #25 — `compound_type` classification is a substring test, still a landmine for future formula codes | ☐ |
| TS-7.4 | Dose value > 100 on a BOM line | Confirm/reconfirm Finding #27 — divided by 1000 by the unit-guessing heuristic; verify it's correct for your real formulas, not just silently wrong | ☐ |
| TS-7.5 | Simulate/observe `receive_alarm`, `receive_heartbeat` | `Equipment Alarm Log` / heartbeat timestamp updated | ☐ |
| TS-7.6 | A real (or simulated) batch that consumes a Silo/Oil item from Mixer WIP | `deduct_lot_stock()` decrements the tank's `LOT Stock Line` correctly | ☐ |
| TS-7.7 | **New 2026-07-06**: check `Unmatched Machine Record` (currently 17 rows, all `status="Pending"`) | For each, confirm whether the underlying machine code now resolves to an Item (checked live: `PAT103P-CMB`, `PAB101P-CMB-T2`, `PMB102P-CMB-T3` now resolve via `custom_formula_bom_code`; **`PM-CJ204P-IRAN IMPORTED` still does not resolve to any Item** — needs an Item created/mapped for it) | ☐ |
| TS-7.8 | **New 2026-07-06**: after fixing an unmatched code by creating/mapping the Item | Confirm the **old** Unmatched Machine Record row does *not* auto-clear — the code comment is explicit that these "never auto-resolve." Decide the SOP: manually set `status`/`resolved_by`/`resolved_on` on the old row, or just let the next real production event for that code succeed and treat the old row as historical noise | ☐ |
| TS-7.9 | **New 2026-07-06**: `Machine Material Map` remains 0 rows — confirm this is an intentional choice (resolving via `custom_formula_bom_code` on Item instead) rather than an oversight | Both mechanisms work (`_find_item_by_name_or_code` checks `custom_formula_bom_code` first, then Machine Material Map) — pick one convention and stick to it so future machine codes don't silently rely on whichever happens to be populated | ☐ |

---

## 12. TS-8 — Compound Lab Test (`compound_lab_test`)

**Blocked by:** screen doesn't exist. Note the screen's docstring says role `Quality Inspector` — that role doesn't exist; use `Quality Manager` per `GOLIVE-DOC.md` §3.

| ID | Steps | Expected | Pass |
|---|---|---|---|
| TS-8.1 | FMB/CMB batch from TS-7, `custom_lab_status="Pending"` | `list_fmb(status="Pending")` | Shows both CMB and FMB batches, tagged `compound_type` | ☐ |
| TS-8.2 | Batch from TS-8.1 | `get_fmb(batch_no)` | Full detail incl. formula, any existing lab test | ☐ |
| TS-8.3 | — | `submit_lab_test(fmb_batch, parameters=[...], remarks, request_id)` with values inside spec | Compound Lab Test submitted, `result="Pass"` (or whatever your pass logic derives), `custom_lab_status` updated on the Batch | ☐ |
| TS-8.4 | — | Same with a value outside spec | `result` reflects Fail/Conditional per your parameter thresholds; confirm §15 gap #5 — a Fail creates **no** rejection/rework record, compound just sits blocked in its zone | ☐ |
| TS-8.5 | Failed batch | Attempt to load it into the mixer (TS-6) or calender (TS-9) | Must be blocked — lab gate enforced at consumption | ☐ |
| TS-8.6 | — | Note: doc string says required role is `Quality Inspector` (doesn't exist) | Confirm the PDT Screen's actual role row is `Quality Manager` when you create it — don't copy the docstring literally | ☐ |

---

## 13. TS-9 — Calendering (`calendering`)

**Blocked by:** screen doesn't exist. Backend logic fully reworked 2026-07-04/06 (pooled roll stock, not Tool Master) — this is the most-changed area this session, test it thoroughly.

| ID | Precondition | Steps | Expected | Pass |
|---|---|---|---|---|
| TS-9.1 | FMB batch, lab Pass/Conditional Pass, stock in FMB Zone | `list_fmb_for_calendering()` / `list_eligible_fmb()` | Lists it; excludes batches already in an active run | ☐ |
| TS-9.2 | Eligible batch | `start_run(fmb_batch, input_qty, request_id)` | Material Transfer FMB Zone→Calendering WH; Calendering Run created, status "In Progress" | ☐ |
| TS-9.3 | Run in progress | `complete_run(name, sheets=[{item_code, qty, liner_item_code, cylinder_item_code, ...}], liner_return_qty, calendar_return_qty, excruder_sludge_qty, request_id)` | See TS-9.4–9.10 for the specific things to verify inside this one call | ☐ |
| TS-9.4 | Sheet missing `liner_item_code` or `cylinder_item_code` | `complete_run` with one omitted | Throws `"... item is required"` — mandatory-per-sheet still enforced, now at spec level | ☐ |
| TS-9.5 | `liner_item_code` pointing at a Cylinder-group item (or vice versa) | `complete_run` | Throws Item Group mismatch error | ☐ |
| TS-9.6 | Roll item with insufficient Store stock (e.g. push qty above the 1 Nos available for `40100004`) | `complete_run` | Throws insufficient-stock error **before** any batch/stock entry is created | ☐ |
| TS-9.7 | Valid sheets | `complete_run` succeeds | Sheet batches created; Manufacture SE (FMB out, sheets in); Repack SE if returns > 0; **one Material Transfer** moves 1 Nos of each roll item Store→In Use (`roll_stock_entry`); Compound Batch Label auto-printed per §9 | ☐ |
| TS-9.8 | Mass balance | `complete_run` with `sheet_total + liner_return + calendar_return + excruder_sludge` off by > 0.5 Kg from `fmb_input_qty` | Throws quantity-mismatch error | ☐ |
| TS-9.9 | Sheet batch from TS-9.7 fully consumed elsewhere (e.g. issue it out completely via a Stock Entry) | Trigger `release_exhausted_rolls` (Stock Entry `on_submit` hook) | The same roll items move back In Use→Store automatically; `Calendering Output.tools_released` flips to 1; `list_roll_stock()` shows qty back at baseline | ☐ |
| TS-9.10 | — | `list_roll_stock()` | Available (Store) vs in-use qty per roll spec — this is the "how many used, how many left" view | ☐ |
| TS-9.11 | Cancel a Calendering Run after completion | Cancel the Run / its Stock Entries | Confirm behavior is sane (no orphaned "in use" roll stock stuck unreleased) — this is a new path introduced by the pooled-stock rework, not covered by the old Tool Master design, so don't assume it's fine — verify it | ☐ |
| TS-9.12 | Return batches | Verify liner/calendar return batches get a fresh `manufacturing_date=today` with no parent-batch link | Confirms §15 gap #7 is still open (FIFO will rank returned compound as new) | ☐ |
| TS-9.13 | — | **Mobile app note**: this whole suite requires `calendering_screen.dart` to send `liner_item_code`/`cylinder_item_code` instead of the old `liner_tool`/`cylinder_tool` — confirm the app build actually matches before device-testing this suite | Flutter payload matches new API shape | ☐ |
| TS-9.14 | **New 2026-07-06**: `Calender` Workstation exists and is linked, but `hour_rate=0` | Run `complete_run` and check the output Manufacture Stock Entry's `additional_costs` | Confirm overhead is still **not** being added (expected while `hour_rate=0`) — set a real rate on `Calender`/`Mixer`/`Chemical Weighing` Workstations, then rerun and confirm an overhead line does appear | ☐ |

---

## 14. TS-10 — Label printing

**Blocked by:** 0 `Universal Printer` records; print-relay agent not verified.

| ID | Steps | Expected | Pass |
|---|---|---|---|
| TS-10.1 | Create a `Universal Printer` record: `printer_name`, `printer_type` (ZPL/TSPL/PDF), `printer_ip`, `printer_port=9100`, `is_active=1`, `is_default=1` | Saved | ☐ |
| TS-10.2 | Batch created anywhere in the flow (mixer/CMB/FMB per §9: auto-printed on every mixer batch + CMB + FMB) | Check `Universal Print Job` list | A job in status `Queued`, `print_content` populated with rendered HTML including barcode | ☐ |
| TS-10.3 | — | `universal.printing.request_print(reference_doctype="Batch", reference_name=<batch>, print_format="Compound Batch Label")` called directly | Same — proves the manual/GRN path independent of auto-print hooks | ☐ |
| TS-10.4 | Job queued | Start/verify the print-relay agent polling `get_pending_jobs` | Job picked up, physically printed, then `mark_job(job_name, "Sent")` called | ☐ |
| TS-10.5 | Printed label | **Physically scan the barcode** with a real scanner | Resolves to the correct batch — the one thing that can't be verified by API testing alone | ☐ |
| TS-10.6 | — | Confirm relay's HTML→printer path: `print_content` is stored as **HTML**; if your physical printer is raw ZPL/TSPL, the relay must render HTML→image→ZPL/TSPL, or the format needs reworking as raw-commands | Verify with the actual relay + printer combination, not assumed | ☐ |
| TS-10.7 | GRN put-away batch (TS-2.3) | Attempt to print via the `Batch Label` format referenced by the put-away screen | **Currently fails — `Batch Label` print format has not been authored yet** (only `Compound Batch Label` exists) | ☐ |
| TS-10.8 | Bad printer config (wrong IP, printer offline) | Relay attempts send | `mark_job(job_name, "Failed", error_message=...)` — confirm failure is visible/actionable in the Desk, not silent | ☐ |

---

## 15. TS-11 — Alerts

**Blocked by:** scheduler is on, but `idle_alert_minutes=10` (contradicts the documented Phase-1 deferral) and all tank `min_qty_kg=0` (low-tank alert can't fire).

| ID | Steps | Expected | Pass |
|---|---|---|---|
| TS-11.1 | Decide: is `idle_alert_minutes=10` intentional now, or should it be `0` per the original Phase-1 decision? | Set accordingly | Documented decision either way — don't leave it as an accidental default | ☐ |
| TS-11.2 | If keeping idle alerts on | Leave a logged-in PDT session idle past `idle_alert_minutes` | Worker prompt appears; supervisor gets a push (per Worker Workstation Assignment's `supervisor` field — confirm this is set for your test worker, only 2 sample rows exist today) | ☐ |
| TS-11.3 | Set `min_qty_kg` on at least one Tank Lot Assignment to a real threshold above current stock | Wait for the hourly `flag_low_tanks()` scheduler run (or trigger manually via console) | `Manufacturing Manager` users get a Notification Log; deduped so it fires at most once/hour per tank | ☐ |
| TS-11.4 | — | Confirm OneSignal/FCM credentials, or accept in-app-only notifications for Phase 1 (`GOLIVE-DOC.md` §11) | Explicit decision, not silence | ☐ |

---

## 16. Sign-off

Do not sign off a row unless it was verified **on the real PDT device** (not just backend/console), where "PDT app" applies.

| Suite | Backend verified | Device verified | Signed off by | Date |
|---|---|---|---|---|
| TS-0 Session/idempotency | ☐ | n/a | | |
| TS-1 PO reception & approval | ☐ | ☐ | | |
| TS-2 Put-away | ☐ | ☐ | | |
| TS-3 Lot browser / manual transfer | ☐ | ☐ | | |
| TS-4 MR & pick | ☐ | ☐ | | |
| TS-5 Silo/Oil/Weighing load | ☐ | ☐ | | |
| TS-6 Mixer loading | ☐ | ☐ | | |
| TS-7 Machine production (bridge live) | ☐ | ☐ (bridge already connected — verify on real machine traffic, not just console) | | |
| TS-8 Compound lab test | ☐ | ☐ | | |
| TS-9 Calendering | ☐ | ☐ | | |
| TS-10 Label printing | ☐ | ☐ | | |
| TS-11 Alerts | ☐ | n/a | | |

**Do not hand over until:** every suite above is either signed off, or its gap is explicitly listed as an accepted go-live decision in `GOLIVE-DOC.md` §15/§16 — not silently skipped.
