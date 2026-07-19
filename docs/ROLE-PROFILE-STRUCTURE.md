# PDT / Manufacturing Role & Role Profile Structure

**Status:** Roles, Role Profiles, Module Profile, and PDT Screen role grants below are **live on site1.local** as of 2026-07-16. `System Manager` was left in place on every screen (additive-only change) — no existing access was removed. Nobody has been assigned to the new Role Profiles yet.

## 1. Why

Every PDT (mobile) screen was gated to `System Manager` only, so every shop-floor
user (reception, warehouse, QC, lab, line operators) needed full admin-level access
just to use the app. This was flagged as a go-live blocker in the 2026-07-13 audit.
This document records the fine-grained Role/Role Profile structure built to replace
that, and the current (additive) rollout state.

The gate mechanism (`universal_mobile_api/permissions.py: require_pdt()`) is unchanged:
- **Screen-level** `required_role` (Table MultiSelect on `PDT Screen`) — OR match: any one listed role grants access.
- **Action-level** `required_role` (single Link on `PDT Screen Action`) — AND on top of screen access, only if set.
- Optional `permission_check` (`doctype:perm_type`) — additional core-Frappe doctype permission check.

## 2. Roles created

| Role | desk_access | Purpose |
|---|---|---|
| `PDT User` | 0 | Base marker for any mobile-app account; gates the generic `support` screen. |
| `Line1 Operator` | 0 | Compound production: material loading, mixing, weighing, calendering, cutting, fabric stitching. |
| `Lab Technician` | 0 | Compound lab testing. |
| `Reception User` | 0 | Goods receiving / PO reception / putaway. |
| `Warehouse User` | 0 | Stock viewing, lot browsing, manual transfers, physical inventory, picking, pick-list fulfillment. |
| `Tool Store Keeper` | 0 | Tool request fulfillment, tool/airbag/grinding-wheel status. |
| `Line2 Operator` | 0 | Belt/sleeve building line: building, curing, processing, sleeve creation. |
| `Packing User` | 0 | Labelling, boxing, palletizing, shipping. |
| `Quality Inspector` | 0 | QC measurement and final QC sign-off. |
| `Line Supervisor` | 1 | Elevated actions within a line (tool release, rejections, WO completion) + occasional Desk oversight. |

All mobile-only roles have `desk_access=0` by design — if one of these users ever
logs into Desk, they get no default backend UI beyond what the `PDT Mobile Worker`
Module Profile (§4) leaves visible.

## 3. Role Profiles created

| Role Profile | Roles bundled |
|---|---|
| `PDT - Line 1 Operator` | PDT User, Line1 Operator |
| `PDT - Line 1 Supervisor` | PDT User, Line1 Operator, Line Supervisor |
| `PDT - Lab` | PDT User, Lab Technician |
| `PDT - Reception` | PDT User, Reception User |
| `PDT - Warehouse` | PDT User, Warehouse User |
| `PDT - Tool Store` | PDT User, Tool Store Keeper |
| `PDT - Line 2 Operator` | PDT User, Line2 Operator |
| `PDT - Line 2 Supervisor` | PDT User, Line2 Operator, Line Supervisor |
| `PDT - Packing & Shipping` | PDT User, Packing User |
| `PDT - QC Desk` | PDT User, Quality Inspector |

Back-office/desk manufacturing staff already have a Role Profile on this bench —
**`Manufacturing`** (`Stock User`, `Manufacturing User`, `Manufacturing Manager`) —
so a duplicate wasn't created. Assign that one to planners/back-office users who
don't touch the mobile app.

## 4. Module Profile created

**`PDT Mobile Worker`** — blocks every Desk module except:
`Manufacturing`, `Manufacturing Universal`, `Quality Management`, `Stock`, `Universal Mobile Api`, `Wms Universal`.

Follows the same block-list convention already used on this bench (`Accounts Desk`, `New Desktop` Module Profiles).

## 5. Live PDT Screen → Role mapping (as applied)

The live server has **27 PDT Screens**, not the 26 in `pdt_rebuild_all_screens.py`'s
canonical list — 6 screens exist live that aren't in that script (`grn_putaway`,
`lot_browser`, `manual_transfer`, `physical_inventory`, `pick_list`, `support`),
and 3 screens in that script don't exist live (`silo_loading`, `oil_loading`,
`sleeve_calculator`). This table reflects **actual live state**, confirmed by
querying `PDT Screen` directly.

| Module | Screen | Active | required_role (live now) |
|---|---|---|---|
| line1 | material_loading | ✓ | System Manager, Line1 Operator |
| line1 | mixer_loading | ✓ | System Manager, Line1 Operator |
| line1 | weighing_load | ✓ | System Manager, Line1 Operator |
| line1 | compound_lab_test | ✓ | System Manager, Lab Technician |
| line1 | calendering | ✓ | System Manager, Line1 Operator |
| line1 | cutting | ✓ | System Manager, Line1 Operator |
| fabric_stitching | fabric_stitching | ✓ | System Manager, Line1 Operator |
| line1 | manufacturing_mr | ✓ | System Manager, Line1 Operator, Warehouse User |
| receiving | po_reception | ✓ | System Manager, Reception User |
| receiving | grn_putaway | ✓ | System Manager, Reception User, Warehouse User |
| inventory | bag_view | ✓ | System Manager, Warehouse User |
| inventory | lot_browser | ✓ | System Manager, Warehouse User |
| inventory | manual_transfer | ✓ | System Manager, Warehouse User |
| inventory | physical_inventory | ✓ | System Manager, Warehouse User |
| picking | pick_list | ✓ | System Manager, Warehouse User |
| line2 | tool_requests | ✓ | System Manager, Line1 Operator, Line2 Operator, Tool Store Keeper |
| line2 | line2_active_jobs | ✓ | System Manager, Line2 Operator, Line Supervisor |
| line2 | line2_building | ✓ | System Manager, Line2 Operator, Line Supervisor |
| line2 | line2_curing | ✓ | System Manager, Line2 Operator |
| line2 | line2_processing | ✓ | System Manager, Line2 Operator |
| line2 | line2_labelling | ✓ | System Manager, Line2 Operator, Packing User |
| line2 | line2_qc_measure | ✓ | System Manager, Quality Inspector |
| line2 | line2_qc_final | ✓ | System Manager, Quality Inspector, Line Supervisor |
| line2 | line2_sleeve | inactive | System Manager, Line2 Operator |
| line2 | line2_packing | ✓ | System Manager, Packing User |
| line2 | line2_tools | ✓ | System Manager, Tool Store Keeper |
| support | support | ✓ | System Manager, PDT User |

Not present on this bench (no action needed): `silo_loading`, `oil_loading` (legacy, superseded by `material_loading`), `sleeve_calculator` (referenced in the design/rebuild script but never created live).

## 6. What was intentionally NOT done in this pass

1. **Action-level `required_role`** (e.g. restricting `release_tool`/`create_rejection` on `line2_building`, `complete_wo` on `line2_qc_final`, `fulfill` on `tool_requests` to supervisors/keepers only) — left blank. Setting these now would immediately restrict current `System Manager` users unless they also hold the matching supervisor/keeper role, unlike the screen-level change which is purely additive. This is a deliberate follow-up cutover step.
2. **No user has been assigned** to any new Role Profile or the Module Profile yet.
3. **`System Manager` was not removed** from any screen. Once real users are piloted per Role Profile and verified end-to-end in the app, `System Manager` can be dropped from each screen's `required_role` module-by-module — `require_pdt()` has no Administrator bypass, so this must happen only after every real user of that screen already holds the correct new role.

## 7. Scripts (idempotent, safe to re-run after a DB restore)

- `apps/manufacturing_universal/manufacturing_universal/scripts/build_pdt_roles_and_role_profiles.py` — creates the 10 Roles, 10 Role Profiles, 1 Module Profile.
- `apps/manufacturing_universal/manufacturing_universal/scripts/add_pdt_screen_roles.py` — adds the screen-level roles above, alongside `System Manager`, to all 27 live PDT Screens.

Run via (bench console mangles piped stdin on this bench):
```
cd sites && ../env/bin/python ../apps/manufacturing_universal/manufacturing_universal/scripts/build_pdt_roles_and_role_profiles.py
cd sites && ../env/bin/python ../apps/manufacturing_universal/manufacturing_universal/scripts/add_pdt_screen_roles.py
```
