# Full-Flow Handover Test Plan — WMS + Compound + Calendering (PDT, Prints, End-to-End)

**Purpose:** verify the complete flow — PO reception → put-away → material request → pick → silo/oil/weighing load → mixer loading → machine production → compound lab test → calendering → label printing — actually works on real hardware (PDT app + physical printer) before handing this system to the client.

**Written:** 2026-07-06, against the live state of this bench (`universal` site) as audited in `GOLIVE-DOC.md` §0. **Updated 2026-07-06 (afternoon):** §1 refreshed after a live re-audit (all 14 PDT screens now exist; two new gaps found), and §4 rewritten around a concrete real item chain — sheet `20100722` / FMB `20100024`. Every API call, screen key, action key, and field name below is taken directly from the current code (`universal_mobile_api`, `manufacturing_universal`, `wms_universal`, `universal` apps) — not from the missing companion docs referenced in `GOLIVE-DOC.md` (`testdocs/calendering-sheet-movement-golive-testing.md` and `universal_app/APP_DOC.md` do **not exist** on this bench; this document replaces them). **Updated 2026-07-06 (evening), re-audited live against the DB:** the `calendering` screen's missing `complete_run` action row is **fixed and verified** (§1, TS-9). Compound BOM costing was reworked — all 95 Rubber Sheet items now have a BOM, and all 47 compound BOMs that had bag chemicals missing now include them at the correct weight, with a corrected batch quantity (Σ of all components) and recalculated cost/explosion (§3, §4, new note under TS-9). Ten FMB BOMs that had a ×1000 unit-scaling bug are also fixed. TS-7.7–7.9 numbers refreshed (13 of 15 previously-unresolved machine codes now resolve to an Item; only 2 genuinely don't). The PM-routing gap (TS-7.10) is **reconfirmed still open** — code unchanged. A DB restore was performed this session; it left the schema one `bench migrate` behind the doctype JSON (harmless — `required_role` is a Table MultiSelect, not a column, so no data was actually missing — but **run `bench migrate` after any restore on this bench**, it's now a known step, see §1).

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
| Every PDT test | PDT Screens for the flow you're testing (**registration only** — this row is about whether the PDT Screen record exists at all, not whether the underlying logic works) | ✅ **Updated 2026-07-06 (afternoon audit): all 14/14 exist** — the 8 missing screens were created 2026-07-06 10:41–10:45, all active, all `System Manager`-only. Action rows verified against the code's `require_pdt` calls for every screen **except `calendering`** (see new row below) | — |
| Every PDT test | Screens granted to real operational roles, not just `System Manager` | All 6 existing screens are `System Manager`-only | All PDT suites, if testing as a non-admin operator — **not a concern right now per your instruction to test as System Manager** |
| TS-2 (put-away) | `grn_putaway` action rows | ✅ **Fixed & verified 2026-07-06** — rows are now exactly `create_batch`/`allocate_bin`/`override_capacity`, matching the code | — |
| TS-9 / §4 step 13 | `calendering` screen's `complete_run` action row | ✅ **Fixed 2026-07-06 (evening)** — the row was added; `require_pdt("calendering", "complete_run")` now passes (verified live). **Real remaining blocker for actually running the step**: zero FMB batches currently sit in `FMB Zone - URBM` with lab status Pass/Conditional Pass (0 rows, re-verified 2026-07-06 evening) — `list_eligible_fmb()` returns empty, so there's nothing to `start_run` yet. Run the §4 upstream chain (or seed one batch + a Pass Compound Lab Test) before device-testing this screen | TS-9.1 needs a seeded batch; TS-9.3+ itself is unblocked |
| TS-7 / §4 step 10a | `receive_mixer_production` routing for `compound_type="PM"` | ❌ **Reconfirmed 2026-07-06 (evening)** — code at `machine_api_endpoints.py:244–249` is unchanged: mapping `Mixer-PM-PAB201-P` is typed `PM` (a legal doctype option), but the endpoint only routes `CMB`/`FMB` and throws `Invalid compound_type: PM` | §4 step 10a / TS-7.10 — decide: extend the code (PM → CMB Zone, most likely) or retype the mapping to `CMB` |
| §3, §4 BOM figures | Sheet BOMs (95 Rubber Sheet items) | ✅ **Fixed 2026-07-06 (evening)** — all 95 now have a submitted, active, default BOM: 1 Kg sheet ← 1.0203 Kg of its FMB compound (the 98% calendering yield). RS items' Default Material Request Type also corrected Purchase → Manufacture | — |
| §3, §4 BOM figures | Bag chemicals (curatives/accelerators) missing from 47 CMB/FMB BOMs | ✅ **Fixed 2026-07-06 (evening)** — bag lines now carry the bag's real weight (were incorrectly qty=1.0 Kg each), 10 FMB BOMs' ×1000 unit-scaling bug corrected, one BOM's wrong item (bag instead of compound) swapped, BOM `quantity` set to Σ of all components (per-instruction), and cost/exploded-items recalculated bottom-up. See `bom-completion-plan` memory for the full list. **This changes the §4 chain's example weights** — `PAB201P-FMB-BOM-0370` is now 125.543 Kg (was 115.5) and `PAB201P-PM-BOM-0356` is now 111.32 Kg (was 107.93); §4's table/steps below are updated to match | — |
| — | Cylinder/liner as BOM components | **Decision confirmed 2026-07-06**: they stay **out** of BOM lines. They're reusable tools (Calender Tools Store/In Use pooled stock), already handled correctly by `complete_run`/`release_exhausted_rolls` — putting them on the BOM would double-count cost and break the auto-return logic | — |
| TS-1 (finance approval) | A user holding the `Finance Approver` role | ❌ **Found 2026-07-06 audit**: the role exists but has **zero users** (enabled or disabled). Administrator masks this — it implicitly passes every role check | TS-1.4/1.5 and §4 step 4, for any realistic (non-Administrator) test |
| TS-5 (silo/oil load) | Tank Lot Assignment (12/12 rows) → stream resolution | ✅ **Logic done** — fixed and tested 2026-07-06, `_resolve_stream()` now reads Tank Lot Assignment directly, verified against all 12 real items | Only the `material_loading` **screen record** is still missing (see row above) — the code path itself is not blocked |
| TS-5 (weighing load) | `stream_item_group_map` row for the Chemical Bags item group (or whichever group your weighing items sit in) | ❌ 0 rows — weighing items still cannot resolve a stream | This is the one real logic gap left in TS-5, and it's Weighing-only — Silo/Oil are unaffected |
| TS-6 (mixer loading) | `mixer_wip_warehouse` set | ✅ Set (`Mixer WIP - URBM`) | — |
| TS-7 (machine production) | Machine bridge connected | ✅ **Corrected 2026-07-06**: the bridge *is* connected — it runs standalone (own `config.json`, not the site's `machtech_base_url`/`chem_base_url` fields, which turned out to be unused by it) and has already synced real data: 258 Formula-BOM Mappings, 205 BOMs, all created 2026-07-02/03 by a dedicated `machineapi@` user. **Real open gap instead**: `Machine Material Map` is still 0 rows — machine codes are being resolved by creating Items with `custom_formula_bom_code` set (works, confirmed live), but 17 `Unmatched Machine Record` entries from before that fix still sit in `status="Pending"` and do not auto-clear (see TS-7 below) | TS-7 (retest scope changed, not blocked) |
| TS-8 (lab test) | `Quality Manager` role assigned to a test user | ✅ **Confirmed 2026-07-06 audit** — 9 enabled users hold it | — |
| TS-9 (calendering) | Liner/Cylinder roll Items + Store/In Use warehouses + opening qty | ✅ Done (2026-07-04/06 rework — pooled stock, not Tool Master) | — |
| TS-9 (calendering) | Named Workstation `Calender` (+ `Mixer`, `Chemical Weighing`) with `hour_rate`, linked in Manufacturing Settings URBM | ⚠️ **Updated 2026-07-06**: all three Workstations now exist and are correctly linked in Manufacturing Settings URBM. **But `hour_rate = 0` on all three** — `_compute_overhead_cost` silently no-ops on a zero rate, so overhead is still not actually being costed | Overhead costing only — doesn't block the flow itself |
| TS-10 (printing) | `Compound Batch Label` print format | ✅ Ships and renders | — |
| TS-10 (printing) | `Universal Printer` record + running print-relay agent | ❌ 0 Printer records; relay agent not verified | TS-10 |
| TS-11 (alerts) | Scheduler enabled | ❌ **Corrected 2026-07-06 audit: actually disabled** — System Settings `enable_scheduler` is unset, so `is_scheduler_inactive()` is True; the bench `schedule` process is running but skips this site. Enable via `bench --site site1.local enable-scheduler` (or System Settings) | TS-11 — and every other scheduled job on the site |
| TS-11 (alerts) | `idle_alert_minutes` intentionally set | ✅ **Updated 2026-07-06 audit** — now `0`; the Phase-1 deferral from `GOLIVE-DOC.md` §15 was applied. TS-11.2 is n/a while it stays 0 | — |
| TS-11 (alerts) | Tank `min_qty_kg` set on at least one Tank Lot Assignment | ❌ All 12 are `0` (reconfirmed 2026-07-06 evening) — low-tank alert can't be tested until at least one has a real threshold | TS-11 (low-tank half) |
| Environment | Bench schema in sync with doctype JSON after a DB restore | ⚠️ **Learned 2026-07-06 (evening)**: a stuck DB restore (zombie DB connections holding metadata locks — killed, or the TCP layer reaped them) needed `bench --site site1.local clear-cache` **then** `bench migrate` afterward before the site was fully consistent again. Nothing was actually broken in this case (`PDT Screen.required_role` "missing column" was a false alarm — it's a Table MultiSelect, no column expected), but treat post-restore migrate as mandatory going forward, not optional | Any test session that starts right after a restore |

**If you're running this test pass specifically to find out "what's left before handover," don't try to force your way past a ❌ row with a console shortcut — that's exactly the gap the client needs to know about.** Log it, move to the next testable suite, come back once it's fixed.

---

## 2. Environment & tooling

**Test users needed** (create if missing, one per role, each linked to a real Employee via `user_id` — only 10/171 Employees currently have this):

| Role | Used for |
|---|---|
| System Manager | Fallback while other screens are still admin-only |
| `WMS Picker` (create — doesn't exist yet) | TS-4 (pick) |
| `WMS Supervisor` (create — doesn't exist yet, or use System Manager) | TS-3 (lot browser / manual transfer) |
| `Quality Manager` | TS-8 (compound lab test) — 9 enabled users already hold it (verified 2026-07-06) |
| `Finance Approver` | TS-1 (finance approval) — ⚠️ role exists but has **zero users** (2026-07-06); assign one first, and don't test as Administrator (it passes every role check and would mask this) |
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

- One **Supplier** and one draft→submitted **Purchase Order** — for the §4 concrete run this is the 6-line PO in step 1 (B104/B107/O102/P303/P304/L401). All six are `is_purchase_item=1` and already in the item master.
- Silo and Oil streams are covered by the §4 chain itself (B104 → `SILO 3`, B107 → `SILO 4`, O102 → `OIL 3`). A Weighing/Chemical-Bags item is **not** part of the chain — add one deliberately if you want to exercise that (it will fail until `stream_item_group_map` gets a row — see Readiness Gate).
- One eligible FMB batch for calendering (`Compound Lab Test` result = Pass or Conditional Pass, sitting in FMB Zone with qty > 0) — **still none as of 2026-07-06 evening** (item `20100024` has zero batches; reconfirmed — `list_eligible_fmb()` is empty), so either run the §4 journey through step 11b first, or seed one directly for calendering-only testing. Note `20100722` already has one historical batch (`5844398`, batch_qty now 0) from earlier testing — this run must create a *new* one.
- **BOM data is now complete for costing** (fixed 2026-07-06 evening): all 95 Rubber Sheet items have a BOM, all 47 compound BOMs that were missing bag chemicals now have them at the correct weight. If you're testing costing/variance display anywhere in this flow (e.g. `_calculate_variance` in TS-7), expect BOM `quantity` and `total_cost` to be noticeably higher than before this fix — that's expected, not a regression.

---

## 4. End-to-end user journey — PO to finished sheet, in the order a real user does it

Everything in §5 onward is organized as **technical suites** (one screen/module at a time) so you can re-test any piece in isolation later. This section is the opposite view: **one continuous run**, following a single thread of real data through every role and every screen, in the order it actually happens on the floor. Run this first — it's what "does the system actually work end to end" really means. Use the technical suites afterward to dig into edge cases at each step.

**Running example — a real chain that already exists in the item master (verified live 2026-07-06).** The target is sheet item `20100722`, produced by calendering FMB compound `20100024`. Everything below is read from the actual BOMs/mappings on this site — no invented items:

| Stage | Item | Name | Group | Chain detail |
|---|---|---|---|---|
| Finished sheet | `20100722` | RS-PAB201P-1.0-1200 | Rubber Sheets | Calendering output (1.0 mm × 1200 mm). Batch-tracked; has **one historical batch `5844398`** (2026-06-25) — this run must create a *new* one, don't confuse them |
| FMB compound | `20100024` | PAB201P-FMB | Compounds | Formula `PAB201-P-FMB` (mapping `Mixer-PAB201-P-FMB`, active) → BOM `PAB201P-FMB-BOM-0370`, **updated 2026-07-06 evening: 125.543 Kg total** = 84.7 PM + 16.4 B104 + 11.8 B107 + 2.6 O102 + **10.043 Kg bag `PAB201P-FMB-1` (curatives, was missing from the BOM until this session's fix)**. Zero batches/stock today |
| PM masterbatch | `20100023` | PAB201P-PM | Compounds | Formula `PM-PAB201-P` (mapping `Mixer-PM-PAB201-P`, `compound_type="PM"`) → BOM `PAB201P-PM-BOM-0356`, **updated 2026-07-06 evening: 111.32 Kg total** = 43.4 P303 + 43.4 P304 + 16.9 L401 + 4.23 B104 + **3.39 Kg bag `PAB201P-PM-1` (co-agent, was missing from the BOM until this session's fix)**. Zero batches/stock today — must be produced before the FMB run |
| Raw — Silo | `30100027` | B104 | Carbon | Tank `SILO 3` (used by *both* the PM and FMB runs) |
| Raw — Silo | `30100030` | B107 | Carbon | Tank `SILO 4` |
| Raw — Oil | `30100033` | O102 | Process oil | Tank `OIL 3` |
| Raw — non-stream | `30100003`, `30100004` | P303, P304 | Polymer | No tank, no stream mapping — reach the mixer via manual transfer → Mixer Staging → `mixer_loading` (step 7b/9a) |
| Raw — non-stream | `30100039` | L401 | Filler | Same path as the polymers |
| Liner | `40100003` | Plastic Liner-1200-100 | Calender Liners | 70 Nos in Calender Tools Store (matches the 1200 mm sheet) |
| Cylinder | `40100009` | Cylinder-1200-120 | Calender Cylinders | 93 Nos in Calender Tools Store |

**What this chain does and doesn't exercise:**
- **No Weighing/Chemical-Bags item appears anywhere in it** — so it does *not* hit the empty `stream_item_group_map` gap and can run end-to-end without that fix. If you also want to probe the weighing gap in the same pass, add one Chemical-Bags line to the PO in step 1 and expect it to dead-end at step 8 (`"No stream mapping configured..."`).
- **New note (2026-07-06 evening)**: the BOMs now include bag chemicals (`PAB201P-PM-1`, `PAB201P-FMB-1`) that this chain's physical steps deliberately don't source (no weighing/bag logistics in this journey — see point above). `produced_qty` in `receive_mixer_production` comes from whatever the machine/simulation reports, **not** from the BOM, so you can still run steps 10a/10b with the original raw-only weights (107.93 Kg PM / 115.5 Kg FMB) exactly as written below — the BOM change doesn't block that. What it *does* change: `_calculate_variance` (TS-7) will now show a "missing" line for the bag component with `bom_qty > 0` and `actual = 0`, since this chain's `consume_list` never reports consuming it. That's expected — it's not a regression, it's the corrected BOM surfacing a gap in this simplified worked example, not in production data.
- **It does hit a gap the generic example didn't (found 2026-07-06 wiring this chain):** the PM leg. `Mixer-PM-PAB201-P` is typed `compound_type="PM"` — a legal option on the Formula-BOM Mapping doctype — but `receive_mixer_production` only routes `CMB`/`FMB` and **throws `Invalid compound_type: PM`** (`machine_api_endpoints.py:244–249`). Decision needed before step 10a: extend the code to route PM (most likely like CMB → CMB Zone), or retype the mapping to `CMB` as a config workaround. See TS-7.10.
- B104/B107/O102 already have bulk stock (43 t / 37 t / 20 t) sitting un-put-away in `WH-A Inbound/Outbound - URBM`. Receive fresh PO quantities anyway — the point is to exercise reception → lab → finance → put-away on *this* thread, not to borrow old stock.

All 8 previously-missing PDT screens were created 2026-07-06 (all `System Manager`-only, all active), so every step below is now drivable through the PDT app — the per-step API call remains listed for backend-first testing. The two ❌ markers are the only things that stop this exact run today.

| # | Role | Where | What they do | What happens | Detail in |
|---|---|---|---|---|---|
| 1 | Procurement | Desk | Pick/create a Supplier → Purchase Order with 6 lines: `30100027` B104 50 Kg, `30100030` B107 25 Kg, `30100033` O102 10 Kg, `30100003` P303 100 Kg, `30100004` P304 100 Kg, `30100039` L401 25 Kg (≈2 PM + 2 FMB batches of headroom) → submit | PO submitted, status "To Receive" | TS-1 |
| 2 | Warehouse receiving clerk | PDT `po_reception` | Scan/select the PO → confirm all 6 lines → `submit_reception` | Purchase Receipt created + submitted into `WH-A Inbound/Outbound - URBM`; PR's `on_submit` auto-creates a Received Item + Incoming Lab Test per line | TS-1 |
| 3 | Lab technician | Desk (Incoming Lab Test) | Complete the 6 auto-created Incoming Lab Tests → Pass | `custom_lab_status` progresses toward "cleared" per line | TS-1 |
| 4 | Finance approver | Desk (Purchase Receipt) | Open the PR → **Approve Finance**. ⚠️ The `Finance Approver` role has **zero users** (2026-07-06 audit) — assign it to a test user first; testing as Administrator would mask this since Administrator passes every role check | `custom_finance_status`/`approved_by`/`approved_on` set — each line flips `ready_for_allocation=1` once both lab + finance clear | TS-1 |
| 5 | Warehouse worker | PDT `grn_putaway` (action rows **fixed & verified 2026-07-06**) | For each of the 6 lines: `create_batch` (qty, production date) → system suggests a bin → scan it → `allocate_bin` | 6 production batches created; stock moves inbound WH → bins (Warehouse LOTs); label print jobs queued | TS-2 |
| 6 | Production planner | PDT `manufacturing_mr` | Create one Manufacturing Material Request, 3 lines: B104 50 Kg + B107 25 Kg with `target_stream="Silo"`, O102 10 Kg with `target_stream="Oil"` → `submit_mr` → `create_pick_list`. (P303/P304/L401 can't go on an MR — there is no Mixer/staging stream, §15 gap #12; they take step 7b instead) | MR submitted; WMS Pick List + Pick List Items generated for the 3 tank lines | TS-4 |
| 7a | Warehouse picker | PDT `pick_list` | `claim` each pick item → scan the suggested bin → `pick.submit` with the picked qty | Stock Entries move B104/B107 toward Outside Silo WH and O102 toward Outside Oil WH; pick items → Completed | TS-4 |
| 7b | Warehouse worker | PDT `manual_transfer` | Transfer P303 (43.4+ Kg), P304 (43.4+ Kg), L401 (16.9+ Kg) from their put-away bins → a Mixer Staging LOT | Bin-to-bin Stock Entry + Warehouse LOG — the workaround for the missing direct-to-staging stream | TS-3 |
| 8 | Silo/Oil operator | PDT `material_loading` | Scan B104 → resolves `stream="Silo"` → `load` → lands in `SILO 3`; same for B107 → `SILO 4`; scan O102 → resolves `stream="Oil"` → `load` → `OIL 3` | FIFO transfers Outside → Inside WHs; capacity checked against `max_capacity_kg` (10,627 Kg silos; oil tanks are 0 = unenforced); `LOT Stock Line` + fill % updated per tank | TS-5 |
| 9a | Mixer operator | PDT `mixer_loading` | Scan the P303, P304, L401 batches staged in step 7b → `load` each into Mixer WIP for the PM run | Material Transfer Mixer Staging → Mixer WIP | TS-6 |
| 10a | *(machine, not a person)* | Real mixer, or console-simulated | Machine runs formula `PM-PAB201-P`: consumes P303 43.4 + P304 43.4 + L401 16.9 from Mixer WIP and B104 4.23 from Inside Silo (`SILO 3`) → reports production of 107.93 Kg | ❌ **Currently throws `Invalid compound_type: PM`** — see the chain notes above and TS-7.10; fix/retype first. Once routed: PM batch of `20100023` created (expect CMB Zone), lab status Pending. Also watch: if the bridge tags the polymers `materialCategory="1"`, `_resolve_source_warehouse` sends them to Inside Silo WH instead of Mixer WIP — verify against real payloads | TS-7 |
| 11a | Quality Manager | PDT `compound_lab_test` | Test the PM batch → Pass | `custom_lab_status="Pass"` — required before it can be mixer-loaded (CMB-style lab gate, TS-6.3) | TS-8 |
| 9b | Mixer operator | PDT `mixer_loading` | Scan the Pass'd PM batch (CMB Zone) → `load` 84.7 Kg into Mixer WIP | Material Transfer CMB Zone → Mixer WIP; a Fail'd batch must be rejected here | TS-6 |
| 10b | *(machine)* | Real mixer, or console-simulated | Machine runs formula `PAB201-P-FMB`: consumes PM 84.7 (Mixer WIP) + B104 16.4 (`SILO 3`) + B107 11.8 (`SILO 4`) + O102 2.6 (`OIL 3`) → reports 115.5 Kg | FMB batch of `20100024` created in FMB Zone; `custom_lab_status="Pending"`; draft Compound Lab Test auto-created; tank `LOT Stock Line`s decremented (`deduct_lot_stock`); Compound Batch Label auto-printed | TS-7 |
| 11b | Quality Manager | PDT `compound_lab_test` | Enter parameter results for the FMB batch → submit | Compound Lab Test submitted; `custom_lab_status` → Pass/Fail/Conditional; **Fail blocks steps 12+** | TS-8 |
| 12 | Calendering operator | PDT `calendering` | Scan the Pass'd FMB batch → input qty 115.5 → `start_run` | Material Transfer FMB Zone → Calendering WH; Calendering Run "In Progress" | TS-9 |
| 13 | Calendering operator | Same screen | `complete_run` with e.g. two sheets of `20100722` (60 Kg + 54 Kg), each specifying liner `40100003` + cylinder `40100009`, plus `liner_return_qty=0.5`, `calendar_return_qty=0.5`, `excruder_sludge_qty=0.5` (sums to 115.5 — inside the 0.5 Kg balance) | ❌ **The `calendering` screen is missing its `complete_run` action row** (created 2026-07-06 with only `start_run`) — `require_pdt` PermissionErrors *every* caller, even System Manager, until the row is added. Once fixed: new sheet batch(es) of `20100722` in Finished Sheet WH; rolls move Store → In Use (verify whether it's 1 Nos per sheet or per distinct roll item when two sheets share a roll — TS-9.7); label printed | TS-9 |
| 14 | *(system, automatic)* | — | Once the new sheet batch is later fully consumed downstream | `release_exhausted_rolls` fires, returns `40100003`/`40100009` In Use → Store | TS-9 |
| 15 | Anyone | Desk or PDT | Check `list_tank_status`, `list_roll_stock`, Finished Sheet WH | `SILO 3`/`SILO 4`/`OIL 3` fill % down by the consumed amounts; a **new** batch of `20100722` in stock (distinct from historical `5844398`); liner back at 70 / cylinder back at 93 Nos | — |

**What this run actually proves, right now (2026-07-06, updated evening):**
- Every screen in the table exists as a PDT Screen record (the 8 missing ones were created 2026-07-06, ~10:41–10:45), so the whole journey is drivable from a real handheld — the plan's original headline gap is closed.
- **One thing now stops this exact chain, down from two:** step 10a still throws `Invalid compound_type: PM` in `receive_mixer_production` (TS-7.10, reconfirmed unchanged). Step 13's blocker — the missing `complete_run` action row on the `calendering` screen — **is fixed** (added 2026-07-06 evening, verified live). The real thing stopping step 13 from being *run* today isn't permissions anymore, it's data: zero eligible FMB batches exist in FMB Zone (see §1), so this chain has to be walked from step 1 (or seeded) before step 12/13 have anything to work with.
- This chain contains no Weighing item, so the empty `stream_item_group_map` does **not** block it — that gap only bites if you add a Chemical-Bags line to probe it deliberately.
- Also fix before step 4: assign the `Finance Approver` role to a test user (it currently has none — reconfirmed 2026-07-06 evening).
- BOM figures for the FMB/PM legs (step 10a/10b) are now higher than originally written — see the chain table above and the note beneath it about the resulting (expected) variance gap.

---

## 5. TS-1 — PO Reception → dual approval → Purchase Receipt

**Blocked by:** nothing screen-side since 2026-07-06 — `po_reception` now exists. Assign a user the `Finance Approver` role first (it has zero users) or TS-1.4/1.5 can't run realistically.

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

**Blocked by:** nothing since 2026-07-06 — `manufacturing_mr` now exists; `pick_list` was already correct.

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

**Blocked by:** screens exist since 2026-07-06 (`material_loading`, `weighing_load`). The Weighing half is still blocked by the empty `stream_item_group_map` (0 rows); the Silo/Oil half is fully runnable — the §4 chain exercises it with B104/B107/O102.

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

**Blocked by:** nothing since 2026-07-06 — the screen now exists. The §4 chain uses this suite twice: polymers/filler for the PM run (step 9a) and the PM batch itself for the FMB run (step 9b).

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
| TS-7.7 | **Refreshed 2026-07-06 (evening)**: re-checked all 17 `Unmatched Machine Record` rows (still all `status="Pending"`, still 17 — none auto-cleared) against `_find_item_by_name_or_code` live | **13 of 15 unique underlying codes now resolve** to an Item (e.g. `PAT103P-CMB` → `20101807` once whitespace-stripped, `PAB101P-CMB-T2` → `20101853`, `PMB102P-CMB-T3` → `20101861`, `PK-PREMIUM-PZ-2` → `20101860`, plus 9 more). **Only `PM-CJ204P-IRAN IMPORTED` genuinely still fails to resolve** (affects 2 rows: `CJ204P-T2-FMB`, `CJ204P-FMB`) — needs an Item created/mapped for it, no close match exists. The `PAT103P-CMB` row's code has a literal trailing tab in the stored raw data — resolves fine once stripped (confirming the code comment's whitespace-defense works), so that row is purely stale, not a live gap | ☐ |
| TS-7.8 | **Reconfirmed 2026-07-06 (evening)**: after fixing an unmatched code by creating/mapping the Item (13 of 15 already resolve as of this audit) | Confirmed the **old** Unmatched Machine Record rows do *not* auto-clear — the code comment is explicit that these "never auto-resolve," and this session's audit found the same 17 rows sitting `Pending` despite most codes now resolving. Decide the SOP: manually set `status`/`resolved_by`/`resolved_on` on the old rows, or just let the next real production event for that code succeed and treat the old rows as historical noise | ☐ |
| TS-7.9 | **New 2026-07-06**: `Machine Material Map` remains 0 rows — confirm this is an intentional choice (resolving via `custom_formula_bom_code` on Item instead) rather than an oversight | Both mechanisms work (`_find_item_by_name_or_code` checks `custom_formula_bom_code` first, then Machine Material Map) — pick one convention and stick to it so future machine codes don't silently rely on whichever happens to be populated | ☐ |
| TS-7.10 | **New 2026-07-06 (found wiring §4's concrete chain)**: trigger/simulate `receive_mixer_production` for a PM-type formula — e.g. `PM-PAB201-P` → item `20100023`, mapping `Mixer-PM-PAB201-P`, `compound_type="PM"` | Currently throws `Invalid compound_type: PM` (`machine_api_endpoints.py:244–249` routes only CMB/FMB, but `PM` is a legal option on the mapping doctype). Decide the fix — extend the code to route PM (probably like CMB → CMB Zone, so the batch is lab-gated before mixer loading) or retype the mapping to `CMB` — then retest and confirm the PM batch lands in the right zone with `custom_lab_status="Pending"` | ☐ |

---

## 12. TS-8 — Compound Lab Test (`compound_lab_test`)

**Blocked by:** nothing since 2026-07-06 — the `compound_lab_test` screen now exists, created `System Manager`-only. Before handover, switch/add `Quality Manager` (9 enabled users hold it) — not the docstring's `Quality Inspector`, which still doesn't exist.

| ID | Steps | Expected | Pass |
|---|---|---|---|
| TS-8.1 | FMB/CMB batch from TS-7, `custom_lab_status="Pending"` | `list_fmb(status="Pending")` | Shows both CMB and FMB batches, tagged `compound_type` | ☐ |
| TS-8.2 | Batch from TS-8.1 | `get_fmb(batch_no)` | Full detail incl. formula, any existing lab test | ☐ |
| TS-8.3 | — | `submit_lab_test(fmb_batch, parameters=[...], remarks, request_id)` with values inside spec | Compound Lab Test submitted, `result="Pass"` (or whatever your pass logic derives), `custom_lab_status` updated on the Batch | ☐ |
| TS-8.4 | — | Same with a value outside spec | `result` reflects Fail/Conditional per your parameter thresholds; confirm §15 gap #5 — a Fail creates **no** rejection/rework record, compound just sits blocked in its zone | ☐ |
| TS-8.5 | Failed batch | Attempt to load it into the mixer (TS-6) or calender (TS-9) | Must be blocked — lab gate enforced at consumption | ☐ |
| TS-8.6 | — | Note: doc string says required role is `Quality Inspector` (doesn't exist) | Screen was created 2026-07-06 with `System Manager` only — fine for this pass, but add/switch to `Quality Manager` before handover; don't copy the docstring's `Quality Inspector` | ☐ |

---

## 13. TS-9 — Calendering (`calendering`)

**Blocked by:** ~~the `calendering` screen is missing its `complete_run` action row~~ — **fixed 2026-07-06 (evening)**, the row was added and `require_pdt("calendering", "complete_run")` now passes (verified live, including as System Manager). The real blocker to actually running this suite today is **data, not permissions**: zero FMB batches sit in FMB Zone with lab status Pass/Conditional Pass, so `list_eligible_fmb()` is empty and TS-9.2 (`start_run`) has nothing to select — walk the §4 chain first, or seed one batch directly. Backend logic fully reworked 2026-07-04/06 (pooled roll stock, not Tool Master) — this is the most-changed area this session, test it thoroughly. For the §4 chain use liner `40100003` + cylinder `40100009` (both stocked in Calender Tools Store, confirmed live: 70 / 93 Nos respectively). Compound BOM costing behind this suite (FMB/PM/sheet BOMs) was also fixed this session — see the new row under §1 and the §4 chain notes; it does not change anything about how `complete_run` itself behaves, only the cost figures downstream of it.

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

**Blocked by:** the scheduler is actually **off** for this site (System Settings `enable_scheduler` unset — corrected 2026-07-06, §1) so nothing here fires at all until it's enabled. `idle_alert_minutes` is now `0` (deferral applied — TS-11.1 resolved, TS-11.2 n/a) and all tank `min_qty_kg=0` (low-tank alert still can't fire).

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
