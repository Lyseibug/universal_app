# Mobile App Screen Fix Plan — universal_app vs GOLIVE-DOC.md

**Audited:** 2026-07-06, against `GOLIVE-DOC.md` §10/§14b/§15 and the live backend
(`universal_mobile_api` + `manufacturing_universal`) on `site1.local`.
**Verdict: the mobile-app gaps are NOT fixed.** The two go-live-doc Flutter items (§14b
calendering payload, §15 #13 rebuild) are still open, and this audit found two additional
breaking defects (a compile error and a registry key mismatch) plus the unchanged
server-side PDT screen configuration gap.

---

## 1. Audit result

### 1.1 Flutter code (universal_app) — screen-by-screen

| Screen (dart) | Backend module | Contract status |
|---|---|---|
| `po_reception_screen.dart` | `po_reception` | ✅ OK (`list_pending`/`search`/`get`/`submit_reception` all match) |
| `grn_putaway_screen.dart` | `grn` | ✅ App-side OK (`create_batch`/`allocate_to_bin`/`suggest_lot`/`print_label`) — broken only by stale **server** action rows (§2.2) |
| `pick_list_screen.dart` | `pick` | ✅ OK (server config also already correct) |
| `physical_inventory`, `lot_browser`, `manual_transfer`, `support` | — | ✅ OK |
| `manufacturing_mr_screen.dart` | `manufacturing_mr` | ⚠️ Works, but **no `create_pick_list` support** — repo/screen never call it, yet §10 requires that action row and the backend exposes it |
| `material_loading_screen.dart` | `line1_loading` | ✅ OK (`resolve`/`list_outside_stock`/`list_inside_stock`/`load`); optional `list_tank_status` dashboard unused |
| `mixer_loading_screen.dart` | `line1_mixer` | ✅ OK (`list_stageable`/`list_wip`/`resolve`/`load` with `batch_no`+`source_warehouse`) |
| `weighing_screen.dart` | `line1_weighing` | ❌ **COMPILE BREAK** — calls `repo.listBoxes()` (line 53) and `repo.weighingLoad(...)` (line 125); **neither method exists** in `Line1Repository`. The app cannot build at all today |
| `bag_viewer_screen.dart` | `line1_weighing` | ✅ OK (`list_bags`/`get_bag`) |
| `compound_lab_test_screen.dart` | `line1_lab` | ⚠️ Submit contract OK (`submit_lab_test`, param shape matches). But `FmbBatch`/`FmbDetail` models lack the new `compound_type` field, so the CMB-vs-FMB tag (§14a deliverable) can't be shown |
| `calendering_screen.dart` | `line1_calendering` | ❌ **BREAKING (§14b)** — sheet payload still sends `liner_tool`/`cylinder_tool` (lines 315–316); backend `complete_run` reads `liner_item_code`/`cylinder_item_code` and throws "*Liner item is required*" for **every** completion. UI is still the dead barcode-scan design (free-text tool fields); no `list_roll_stock` usage |
| `oil_loading_screen.dart`, `silo_loading_screen.dart` | `line1_silo` | ⚠️ Legacy — must never be activated server-side (Finding #17); registry entries are harmless because the menu is server-driven |

### 1.2 Screen registry (`lib/screens/home/screen_registry.dart`)

❌ Registers key **`weighing`**, but the backend permission gate and menu use screen_key
**`weighing_load`** (`require_pdt("weighing_load", ...)`). The registry silently skips
unknown keys → even after server config is created, the Weighing screen would never
appear on any device.

### 1.3 Server-side PDT configuration (blocks all mobile screens regardless of app fixes)

Verified live in the DB (2026-07-06) — unchanged from GOLIVE-DOC §0/§10:

- Only **6 of 14** PDT Screen records exist (`grn_putaway`, `pick_list`,
  `physical_inventory`, `lot_browser`, `manual_transfer`, `support`).
- Missing entirely: `po_reception`, `manufacturing_mr`, `material_loading`,
  `mixer_loading`, `weighing_load`, `bag_view`, `compound_lab_test`, `calendering`.
- All 6 existing screens granted **only to System Manager**.
- `grn_putaway` action rows still stale: has `put_away`, `override_suggested_lot`,
  `override_capacity`; code needs `create_batch`, `allocate_bin`, `override_capacity`
  → mobile GRN put-away throws PermissionError for everyone.
- PDT Modules: only `inventory`, `picking`, `receiving`, `supervisor_tools`, `support` —
  no `line1`/production module grouping for the 8 new screens.
- `WMS Picker` / `WMS Supervisor` roles still not created (§3).

### 1.4 Build/tooling

- No Flutter SDK on this bench (§15 #13 unchanged) — all fixes below must be
  `flutter analyze`'d and built on the dev machine.
- Models under `core/models/*.dart` use freezed → changing `FmbBatch` requires
  `dart run build_runner build --delete-conflicting-outputs` on the dev machine.

---

## 2. Fix plan

> **Implementation status (2026-07-06): Part A is DONE (A1–A5), implemented in this
> working tree.** Details of what shipped:
> - **A1** — `listWeighingOutsideStock()`, `listBoxes()`, `weighingLoad()` added to
>   `line1_repository.dart`; `weighing_screen.dart` now calls
>   `listWeighingOutsideStock()`. Because the generic outside-stock read is
>   permission-gated to the `material_loading` screen, a weighing-scoped
>   `list_outside_stock` endpoint was added to
>   `universal_mobile_api/api/line1_weighing.py` (gated on `weighing_load`,
>   same `_get_item_totals_in_warehouse` idiom as `list_bags`). Verified live:
>   endpoint registered after gunicorn reload; settings resolve; query runs.
> - **A2** — `calendering_screen.dart` redesigned: `_SheetEntry` now holds
>   `linerItemCode`/`cylinderItemCode`; per-sheet Liner/Cylinder dropdowns fed by
>   `listRollStock()` (new repo method + plain-Dart `RollStock` model), options show
>   availability and disable at 0; client-side roll tally before submit; payload sends
>   `liner_item_code`/`cylinder_item_code`; collapsible Roll Stock card with refresh in
>   the run detail. `list_roll_stock` verified live: 11 specs with real quantities.
> - **A3** — registry key changed to `weighing_load`.
> - **A4** — `compoundType` (`compound_type`, default `'FMB'`) added to `FmbBatch`;
>   generated `.freezed.dart`/`.g.dart` hand-patched mirroring the `labStatus`
>   pattern (19+2 lines, verified balanced) — **still run build_runner on the dev
>   machine to confirm**. Lab screen shows a CMB/FMB chip in list + detail (detail
>   carries the type from the tapped row since `get_fmb` doesn't return it);
>   FMB-only wording generalized.
> - **A5** — `createPickList()` repo method + a "Create Pick List" recovery button on
>   submitted MRs missing a pick list, gated by `can('create_pick_list')`
>   (`submit_mr` normally auto-creates it).
>
> **Not done here:** Part B (server PDT config) and Part C (build/verify on a machine
> with the Flutter SDK — none on this bench). A6 (tank dashboard) intentionally skipped.

### Part A — Flutter fixes (universal_app), in priority order

#### A1. Fix the compile break: add the two missing weighing repo methods — **P0**
File: `lib/features/line1/line1_repository.dart` (add under the "Bags" section):

```dart
// ── Weighing (Outside → Inside Weighing Machine WH) ──────────────────────

Future<List<StockItem>> listBoxes() async {
  final data = await _api.call('line1_weighing.list_boxes');
  return _parseStockList(data);   // same item-totals shape as list_inside_stock
}

Future<LoadResult> weighingLoad({
  required String boxBarcode,
  required String itemCode,
  required double qty,
}) async {
  final result = await _writeQueue.run('line1_weighing.weighing_load', {
    'box_barcode': boxBarcode,
    'item_code': itemCode,
    'qty': qty,
  });
  return LoadResult.fromJson(Map<String, dynamic>.from(result));
}
```

Backend contract (verified): `weighing_load(box_barcode, item_code, qty, request_id)`
returns the standard load-result dict plus `box_barcode`; `list_boxes()` returns
aggregated item totals in Inside Weighing WH (same shape `_parseStockList` handles).
`request_id` is injected by `WriteQueue` — do not add it manually.
Sanity-check `weighing_screen.dart` compiles against these signatures (it reads
`result.qty`; `LoadResult` already parses `qty`).

#### A2. Calendering screen — §14b payload + pooled-roll UI — **P0**
Files: `lib/features/line1/calendering_screen.dart`,
`lib/features/line1/line1_repository.dart`, `lib/core/models/line1_models.dart`.

1. **Repo**: add
   ```dart
   Future<List<RollStock>> listRollStock() async {
     final data = await _api.call('line1_calendering.list_roll_stock');
     ...
   }
   ```
   Backend returns per roll-spec Item: `item_code`, `item_name`, `item_group`,
   `roll_type` (`Liner`|`Cylinder`), `available_qty` (Store WH), `in_use_qty`
   (In Use WH). Add a plain-Dart `RollStock` model next to `CalenderingFmb`
   (no codegen needed for plain classes).
2. **Sheet entry redesign** (`_SheetEntry`, lines ~886+): replace
   `linerToolCtrl`/`cylinderToolCtrl` (free-text barcode fields) with
   `String? linerItemCode` / `String? cylinderItemCode` selected from two
   dropdowns populated by `listRollStock()` — one filtered to `roll_type == 'Liner'`,
   one to `'Cylinder'`. Show `item_name (available_qty avail)` per option;
   disable options with `available_qty <= 0`.
3. **Client-side stock tally** (mirrors backend up-front check): across all sheet
   entries, count 1 Nos per selection per sheet and warn when a spec's total
   exceeds its `available_qty` before submitting.
4. **Payload** (lines ~308–317): send
   `'liner_item_code': e.linerItemCode` / `'cylinder_item_code': e.cylinderItemCode`;
   drop `liner_tool`/`cylinder_tool`. Keep `item_code`, `qty`, `thickness_mm`,
   `width_in_mm`, `length_in_mm` (all verified still read by the backend).
5. **Validation messages** (lines ~282–295): "Liner roll spec is required" /
   "Cylinder roll spec is required" per sheet (still mandatory — matches backend).
6. **Optional but cheap**: a "Roll stock" info sheet/tab on the calendering screen
   listing available vs in-use per spec (straight render of `listRollStock()`),
   satisfying §8.5's "how many used, how many left" on the floor.
7. Refresh roll stock after a successful `complete_run` (the Store→In Use transfer
   changes availability immediately).

#### A3. Registry key fix: `weighing` → `weighing_load` — **P0** (one line)
File: `lib/screens/home/screen_registry.dart` line 54:

```dart
'weighing_load':      (s) => WeighingScreen(screen: s),
```

`weighing_screen.dart` already gates its button on `screen.can('load')`, which matches
the backend action key — no other change needed.

#### A4. Lab models: add `compound_type` — **P1** (cosmetic but a §14a deliverable)
Files: `lib/core/models/line1_models.dart` (`FmbBatch`, `FmbDetail`),
`lib/features/line1/compound_lab_test_screen.dart`.

- Add `@JsonKey(name: 'compound_type') @Default('FMB') String compoundType,` to both
  freezed models → **requires build_runner codegen on the dev machine**.
- Show a CMB/FMB chip in the batch list + detail header (screen already lists both
  zones because the backend merged them — only the tag is missing).
- Title/labels: the screen is no longer FMB-only; rename visible "FMB" strings to
  "Compound" where they'd be wrong for CMB batches.

#### A5. Manufacturing MR: add pick-list dispatch — **P1**
Files: `lib/features/manufacturing_mr/manufacturing_mr_repository.dart` + screen.

- Repo: `createPickList(String name)` → `_writeQueue.run('manufacturing_mr.create_pick_list', {'name': name})`.
- Screen: on a submitted MR's detail view, show a **Create Pick List** button gated by
  `widget.screen.can('create_pick_list')`.
- Without this, §10's `create_pick_list` action row exists but nothing in the app can
  trigger it (today a Desk user must create the pick list).

#### A6. Optional (defer if time-boxed): tank dashboard — **P2**
`line1_loading.list_tank_status` (fill % per silo/oil tank, reads Tank Lot Assignment)
has no UI. Add a read-only tank status card/tab to `material_loading_screen.dart`.
Pure read, no action row needed.

#### A7. Legacy screens — leave as-is
Keep `oil_loading`/`silo_loading` registry entries (server never serves those keys, so
they can't render) or delete the two dart files for hygiene. **Never** create their PDT
Screen records server-side (Finding #17 — they bypass tank-capacity validation).

### Part B — Server-side PDT configuration (required for any screen to appear)

The menu is 100% server-driven (`session.get_menu` reads PDT Screen/Module records and
filters by role + action rows). Do this on the reference bench, then export as
fixtures/data for the fresh target server.

1. **Fix `grn_putaway` action rows** (unblocks mobile put-away immediately):
   delete `put_away` + `override_suggested_lot` rows; add `create_batch` and
   `allocate_bin`; keep `override_capacity`.
2. **Create roles** (§3): `WMS Picker`, `WMS Supervisor`.
3. **Create PDT Module** `line1` (label e.g. "Production — Line 1") for menu grouping;
   assign the 8 new screens to it.
4. **Create the 8 missing PDT Screen records** with exact keys (from code, verified):

| screen_key | Action rows (exact) | Roles (suggested) |
|---|---|---|
| `po_reception` | `submit_reception` | reception/warehouse staff role |
| `manufacturing_mr` | `create`, `create_pick_list` | production requester role |
| `material_loading` | `load` | tank/machine operators |
| `mixer_loading` | `load` | mixer operators |
| `weighing_load` | `load` | weighing operators |
| `bag_view` | — (read-only) | weighing operators |
| `compound_lab_test` | `submit_test` | Quality Manager |
| `calendering` | `start_run`, `complete_run` | calendering operators |

5. **Re-grant the 6 existing screens** to real floor roles (`WMS Picker` on
   `pick_list`, warehouse staff on `grn_putaway`/`physical_inventory`,
   `WMS Supervisor` on `lot_browser`/`manual_transfer`, all floor roles on `support`)
   instead of System-Manager-only.
6. Every PDT user needs `Employee.user_id` linked (only 10/171 today) and a
   Worker Workstation Assignment with supervisor set (§3) — otherwise login/workspace
   selection and alert routing fail.

### Part C — Build & verification (on the dev machine — no Flutter SDK here)

1. `dart run build_runner build --delete-conflicting-outputs` (for A4's freezed change).
2. `flutter analyze` — must be clean (A1 fixes today's guaranteed compile errors;
   analyze catches any leftovers, per §15 #13).
3. `flutter build apk --release`; distribute via the PDT App Version self-update record (§11).
4. Functional passes against this reference bench:
   - **Weighing**: scan box → load → verify Outside→Inside Weighing transfer + `Weighing Load` log.
   - **Calendering**: start run → complete with 2 sheets selecting liner+cylinder specs →
     verify Store→In Use Material Transfer (`roll_stock_entry`), sheet batches created,
     roll stock counts drop; retest a completion with `available_qty = 0` → clean client-side block.
   - **Lab**: CMB batch shows with CMB tag; submit test; verify mixer-load gate on Fail.
   - **GRN put-away** on mobile after B1 (create batch → suggest lot → allocate → over-capacity override).
   - **MR**: create → submit → create pick list from the device.
   - Full plans: `universal_app/APP_DOC.md` §5–6 and `testdocs/calendering-sheet-movement-golive-testing.md` §6 (TC-CAL set).

### Sequencing

1. **B1 + B4 + A1 + A2 + A3** are the go-live-critical set (compile, §14b contract,
   weighing visibility, server screens). A1/A3 are minutes; A2 is the only substantial
   Flutter work (~1 screen redesign); B1/B4 are pure config.
2. Then A4 + A5 + B2/B3/B5 (roles/grants + lab tag + MR pick list).
3. A6 (tank dashboard) is optional polish; do only if the floor asks for it.
4. Part C last, then update GOLIVE-DOC §0/§16 checkboxes.
