# PDT / Manufacturing Role & Role Profile Structure

**Status:** Phase 1 (below, §1-7) went live 2026-07-16 as an additive-only pass — `Line1 Operator`/`Line2 Operator`/`Warehouse User` still granted every screen, nobody assigned to the new profiles yet. **Phase 4 (§8 onward) went live 2026-07-21** and is the cutover Phase 1 deferred: the coarse roles are removed from every screen they used to grant and replaced with station-level roles, elevated actions are now role-gated, and `Custom DocPerm` + `User Permission` company-scoping were added for the supervisor roles. See §8 for the full current-state mapping — treat §1-7 as historical background on the roles that predate Phase 4 and are still reused by it (`Reception User`, `Mixer and Calendar Supervisor`, `Line Supervisor`, `Quality Inspector`, `Packing User`, `Tool Store Keeper`, `Lab Technician`).

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

---

## 8. Phase 4 — granular cutover (live 2026-07-21)

### 8.1 Why now

Phase 1 gave every worker family one role (e.g. `Line2 Operator` covered
Building + Curing + Grinding + Cutting + Rib Grinding indiscriminately). That
was fine as a first step off `System Manager`-only, but a Curing worker
being able to touch Calendering, or a Picker being able to reassign bins, was
never the target state. Phase 4 splits each family into station-level roles
and actually removes the broad ones from the screens they used to grant.

Two backend changes made this safe to do for Line 2 specifically:
- `line2.complete_step` used to hard-code `require_pdt("line2_building", ...)`
  for *every* step (Building/Curing/Grinding/Cutting/Rib Grinding all shared
  one gate). It's now step-aware — see `STEP_TO_SCREEN` in
  `universal_mobile_api/api/line2.py` — and a new `PDT Settings.line2_step_roles`
  table further splits Grinding/Cutting/Rib Grinding, which still share the
  single `line2_processing` screen.
- `line2_curing` / `line2_processing` had **zero** `PDT Screen Action` rows
  for `complete_step` before Phase 4 — the action gate lived entirely on
  `line2_building`. Splitting roles onto those screens without adding the
  missing action rows would have 403'd legitimate Curing/Processing workers;
  the cutover script adds them first.

### 8.2 New roles

| Role | desk_access | Screens granted |
|---|---|---|
| `Reception Supervisor` | 1 | grn_putaway, po_reception (+ `override_capacity`) |
| `Material Loading User` | 0 | material_loading, pick_list, tool_requests |
| `Chemical Weighing User` | 0 | weighing_load, tool_requests |
| `Compound Building User` | 0 | mixer_loading, tool_requests |
| `Calendaring User` | 0 | calendering, cutting, tool_requests |
| `Sleeve Building User` | 0 | line2_building, line2_active_jobs, tool_requests |
| `Curing User` | 0 | line2_curing, line2_active_jobs, tool_requests |
| `Sleeve Grinding User` | 0 | line2_processing (GRINDING steps), line2_active_jobs, tool_requests |
| `Sleeve Cutting User` | 0 | line2_processing (CUTTING/TWO_PIECE_CUTTING steps), line2_active_jobs, tool_requests |
| `Rib Grinding User` | 0 | line2_processing (RIB_GRINDING steps), line2_active_jobs, tool_requests |
| `Picker` | 0 | pick_list |
| `Inventory Counter` | 0 | physical_inventory, bag_view |
| `LOT Supervisor` | 1 | lot_browser, manual_transfer (+ `transfer`) |

Reused rather than duplicated (already existed, now wired to the right
screens): `Reception User`, `Mixer and Calendar Supervisor` (= Compound
Production Supervisor — had 0 screens before Phase 4), `Line Supervisor`
(= Production Line 2 Supervisor, already line2-only in practice),
`Quality Inspector`, `Packing User`, `Tool Store Keeper`, `Lab Technician`.

### 8.3 What actually changed on each screen

| Screen | Removed | Added |
|---|---|---|
| grn_putaway | Warehouse User | Reception Supervisor |
| po_reception | — | Reception Supervisor |
| pick_list | Warehouse User | Picker, Material Loading User |
| physical_inventory, bag_view | Warehouse User | Inventory Counter |
| lot_browser, manual_transfer | Warehouse User | LOT Supervisor |
| material_loading | Line1 Operator | Material Loading User, Mixer and Calendar Supervisor |
| weighing_load | Line1 Operator | Chemical Weighing User, Mixer and Calendar Supervisor |
| mixer_loading | Line1 Operator | Compound Building User, Mixer and Calendar Supervisor |
| calendering, cutting | Line1 Operator | Calendaring User, Mixer and Calendar Supervisor |
| manufacturing_mr | Line1 Operator, Warehouse User | Mixer and Calendar Supervisor |
| line2_active_jobs | Line2 Operator | Sleeve Building/Curing/Grinding/Cutting/Rib Grinding User |
| line2_building | Line2 Operator | Sleeve Building User |
| line2_curing | Line2 Operator | Curing User, Line Supervisor |
| line2_processing | Line2 Operator | Sleeve Grinding/Cutting User, Rib Grinding User, Line Supervisor |
| line2_labelling | Line2 Operator | *(Packing User already there)* |
| tool_requests | Line1 Operator, Line2 Operator | every Line1/Line2 granular role + both supervisors |

`System Manager` was **not** removed from any screen in this pass either —
still an explicit escape hatch, same as Phase 1.

### 8.4 Elevated actions (now role-gated, were blank)

| Screen.action | required_role |
|---|---|
| grn_putaway.override_capacity | Reception Supervisor |
| manual_transfer.transfer | LOT Supervisor |
| line2_building.create_rejection | Line Supervisor |
| line2_qc_final.complete_wo | Line Supervisor |

### 8.5 Line 2 step-level permissions (`PDT Settings.line2_step_roles`)

New child table on the `PDT Settings` singleton doctype
(`universal_mobile_api`), checked by `line2.complete_step` in addition to the
screen-level gate — this is what actually tells Grinding/Cutting/Rib
Grinding apart since they share `line2_processing`:

| step_master | allowed roles |
|---|---|
| GRINDING | Sleeve Grinding User, Line Supervisor |
| CUTTING | Sleeve Cutting User, Line Supervisor |
| TWO_PIECE_CUTTING | Sleeve Cutting User, Line Supervisor |
| RIB_GRINDING | Rib Grinding User, Line Supervisor |

A step left unconfigured here has no extra restriction beyond the
screen-level role gate (backward compatible by construction).

### 8.6 Desk access for supervisors

Mobile writes bypass core Frappe permissions (`ignore_permissions=True`
throughout), so this only matters for supervisors who also use the Desk UI.

**Custom DocPerm** (read+write):
| Role | Doctypes |
|---|---|
| Reception Supervisor | Purchase Order, Material Request, Stock Entry, Received Item |
| Mixer and Calendar Supervisor | Job Card, Stock Entry, Material Request, Work Order |
| Line Supervisor | Job Card, Stock Entry |
| LOT Supervisor | Warehouse LOT |

**Company scoping**: Frappe's `User Permission.applicable_for` links to
**DocType**, not Role — there is no native "apply to everyone with role X"
mechanism. Company scoping is therefore per-user: a `User Permission`
(`allow: Company`, `for_value: Universal Rubber Belt Manufacturing LLC`) was
added for every user who currently holds one of the 4 supervisor roles.
**When creating a new supervisor-role user, add this User Permission by hand**
— it is not automatic.

### 8.7 QC shared-login inspector selection

`Quality Inspector` is designed to be held by exactly one shared device
login plus every individual inspector's own (otherwise-unused) User account.
See `manufacturing_universal/line2_qc.list_inspectors()` — it returns every
Employee whose linked User holds `Quality Inspector`, and
`submit_measurement`/`submit_qc_result` accept an `inspector` (Employee)
param that overwrites `Job Card.custom_operator` instead of trusting the
shared session user. The app shows an "Inspector" picker in both QC screens,
required whenever that list is non-empty. **To onboard a real inspector**:
give their existing User account the `Quality Inspector` role — they don't
need PDT app login capability themselves, just the role, to appear in the
picker.

### 8.8 Company-aware schema (Phase 2, same day)

`company` (Link → Company) was added to 7 doctypes the mobile app writes to
that previously had none: `Workstation` (as `custom_company`, fetched from
`warehouse`), `Warehouse LOT` (fetched from `warehouse`), `Worker Session`
(set from the chosen workstation at `select_workspace`), `WMS Pick List` (set
from the Material Request's company), `Batch` (as `custom_company`, via a
`before_insert` hook — `wms_universal.company_utils.set_batch_company` —
covering every batch-creation call site at once instead of editing ~10
files), `Received Item`/`Received Item Line` (set from the Purchase
Receipt's company in `wms_universal.receiving.on_purchase_receipt_submit`).
All existing rows were backfilled; new rows populate automatically. Read
endpoints (`pick.list`, `lot.browse`, `grn.list_pending`) filter by
`session_utils.current_company()` (active Worker Session's company, falling
back to the user's default Company). Today there's only one real production
company (`Universal Rubber Belt Manufacturing LLC`), so this has no visible
effect yet — it's what makes adding a second company later a config change,
not a schema migration.

### 8.9 Script

- `apps/manufacturing_universal/manufacturing_universal/scripts/build_pdt_granular_roles_phase4.py`
  — does everything in §8.2-8.6 plus §8's safety-net role grants for the
  accounts that held the broad roles at cutover time. Idempotent, re-run
  after any DB restore. Verified: a second consecutive run makes zero
  changes. **Self-contained**: also (re-)creates the "reused" roles
  (`Reception User`, `Mixer and Calendar Supervisor`, `Line Supervisor`,
  `Quality Inspector`, `Packing User`, `Tool Store Keeper`, `Lab Technician`,
  `PDT User`) if missing, so it does **not** require Phase 1's scripts to
  have run first — safe to run standalone on a bare server. `Mixer and
  Calendar Supervisor` in particular predates every PDT script on this
  environment (origin unknown) and isn't created by Phase 1 either, so this
  was a real gap before the fix.

### 8.10 User creation guide

For each **worker** role, create a `User` (Full Name + email/username,
"Send Welcome Email" off for shop-floor accounts), set **Role Profile** to
the matching one below, and make sure they have a linked `Employee` record
with `user_id` set (required for `Worker Workstation Assignment` /
`select_workspace` to resolve them). No desk access needed.

| Role Profile | Role(s) | Example username |
|---|---|---|
| PDT - Reception Supervisor | Reception Supervisor, Reception User | reception.supervisor@… |
| PDT - Reception | Reception User | reception1@… |
| PDT - Compound Production Supervisor | Mixer and Calendar Supervisor | compound.supervisor@… |
| PDT - Material Loading User | Material Loading User | matloading1@… |
| PDT - Chemical Weighing User | Chemical Weighing User | weighing1@… |
| PDT - Compound Building User | Compound Building User | mixer1@… |
| PDT - Calendaring User | Calendaring User | calender1@… |
| PDT - Lab | Lab Technician | lab1@… |
| PDT - Line 2 Supervisor | Line Supervisor | line2.supervisor@… |
| PDT - Sleeve Building User | Sleeve Building User | building1@… |
| PDT - Curing User | Curing User | curing1@… |
| PDT - Sleeve Grinding User | Sleeve Grinding User | grinding1@… |
| PDT - Sleeve Cutting User | Sleeve Cutting User | cutting1@… |
| PDT - Rib Grinding User | Rib Grinding User | ribgrinding1@… |
| PDT - QC Desk | Quality Inspector | **one shared device login**, e.g. `qc.station@…` |
| PDT - Picker | Picker | picker1@… |
| PDT - Inventory Counter | Inventory Counter | inventory1@… |
| PDT - LOT Supervisor | LOT Supervisor | lot.supervisor@… |
| PDT - Packing & Shipping | Packing User | packing1@… |
| PDT - Tool Store | Tool Store Keeper | toolstore1@… |

**QC is the one exception to "one user per role"**: create exactly **one**
shared login for the QC device with `PDT - QC Desk`. Then, separately, give
each of the 5 real inspectors' *existing* User accounts the `Quality
Inspector` role (no new login, no Role Profile needed for them) so they show
up in the in-app Inspector picker — see §8.7.

For the 4 supervisor roles (Reception Supervisor, Mixer and Calendar
Supervisor, Line Supervisor, LOT Supervisor), also add a `User Permission`
scoping them to `Universal Rubber Belt Manufacturing LLC` (§8.6) — the
cutover script only did this for users who already held the role before
Phase 4 ran.

Legacy Phase-1 profiles (`PDT - Line 1 Operator`, `PDT - Line 2 Operator`,
`PDT - Warehouse`) are now dead weight — the roles they bundle
(`Line1 Operator`, `Line2 Operator`, `Warehouse User`) no longer grant any
PDT screen. Left in place rather than deleted; don't assign them to anyone
new.
