# Stage-by-Stage Manual Stock Entry Guide

**Companion to** `APPSHEET-DATA-MIGRATION-GUIDE.md`. That guide covers the overall migration strategy (extraction, item/batch mapping, staged rollout). This one drills into exactly what document to create, with which fields, at **each of the 11 production stages you named**: Chemical Weighing, Mixer, Calender, Building, Curing, Sleeve Grind, Cutting, Rib Grind, QC, Warehouse Packing, Packed.

**Audited live against site1.local, 2026-07-10** — every warehouse name, field name, and code path below was read directly from the running app's source and confirmed against live `Manufacturing Settings URBM` values (all warehouse links are currently configured; that wasn't always true on prior dates, so re-check if you're reading this later).

---

## 0. How stock actually moves through every stage (updated — real station-to-station transfers now built and live-verified)

An earlier pass through this guide found that Building through Rib Grind had **no** stock movement in the live code — only Chemical Weighing, Mixer, Calender, and QC moved real stock, and the sleeve/belt build in between was tracked purely by the flowchart traveler (Job Card history), not the stock ledger.

**That's no longer true — real per-station stock movement is now built, tested end-to-end, and live on this system.** Every station (Building, Curing, Sleeve Grind, Cutting, Rib Grind, Inspect) now has its own real Warehouse pair, and a unit's batch physically transfers between them exactly as you described: on arrival at a station the batch moves from that station's Warehouse into its WIP; on completion it moves from that WIP into the next station's Warehouse.

| Stage | Real Stock Entry? | Mechanism |
|---|---|---|
| Chemical Weighing | **Yes** | `Machine Production Record` → Manufacture Stock Entry |
| Mixer | **Yes** | `Machine Production Record` → Manufacture Stock Entry |
| Calender | **Yes** | `Calendering Run` → Manufacture + Repack + Material Transfer Stock Entries |
| Building | **Yes** | Consumes the Work Order's BOM (rubber sheet + fabric + cord) from `building_material_warehouse`, creates the unit's own Batch, produces it into Building's own WIP — see §4.1 |
| Curing | **Yes** | Arrival: Curing WH → Curing WIP. Departure: Curing WIP → Grinding WH — see §4.2 |
| Sleeve Grind | **Yes** | Arrival: Grinding WH → Grinding WIP. Departure: Grinding WIP → Cutting WH |
| Cutting *(Line 2 belt-cutting step)* | **Yes** | Arrival: Belt Cutting WH → Belt Cutting WIP. Departure: Belt Cutting WIP → Rib Grind WH |
| Rib Grind | **Yes** | Arrival: Rib Grind WH → Rib Grind WIP. Departure: Rib Grind WIP → Inspect WH |
| QC (Inspect) | **Yes** | Arrival: Inspect WH → Inspect WIP. `complete_wo()` then moves the same batch straight from Inspect WIP into `Finished Belt WH` — no re-consumption of raw material, since it was already consumed once, at Building — see §9 |
| Warehouse Packing | **No** | `Box`/`Pallet` records just group existing FG batches by Sales Order — no stock entry |
| Packed | **No** | Status flip (`Open`→`Sealed`) only |
| *(Shipped, one step beyond "Packed")* | **Yes** | `ship_box`/`ship_pallet` creates a real Delivery Note against the Sales Order's warehouse |

**The mechanism, in one paragraph:** `Flowchart Step Master` now carries `step_warehouse` (arrival/staging) and `step_wip_warehouse` (actively being worked) for every real station. `Work Order.custom_unit_batch` tracks the physical unit's Batch from Building onward. On Job Card **creation** for a station, its batch moves `step_warehouse → step_wip_warehouse` (Building is the exception — its "arrival" is the BOM consumption that creates the batch directly into its own WIP). On Job Card **completion**, the batch moves `step_wip_warehouse → next station's step_warehouse`. The transfer always sources from wherever the batch **actually** currently sits (queried live, not assumed) — so this also correctly handles rework Job Cards that send a unit back to an earlier station out of sequence. All of this lives in the new `manufacturing_universal/line2_station_flow.py` module, wired into `_find_or_create_job_card()` (arrival) and `complete_step()` (departure) in `line2_building.py`, plus a rewritten `complete_wo()` in `line2_qc.py` that no longer re-consumes the BOM at the end.

**One real naming resolution:** the warehouse tree only had one "Cutting WH/WIP" pair, already claimed by Line 1's unrelated sheet-repack operation. Line 2's belt-cutting step now has its own **`Belt Cutting WH - URBM`** / **`Belt Cutting WIP - URBM`**, created for this purpose.

---

## 1. Chemical Weighing

**Real mechanism:** `Machine Production Record` (Desk doctype, built for exactly this — manual OR machine entry) → click **Process Production Record** → runs `manual_production.py::process_manual_production_record`.

**Warehouses (live-confirmed):**
- Source (raw material consumed): whatever you set per row, or defaults to `Inside Weighing Machine WH - URBM`
- Target (bag produced into): `WIP Bags - URBM`

**Cost mechanics:** the consumed raw material's cost comes from **its existing valuation rate in the source warehouse** (standard Frappe FIFO/moving-average — you don't type a cost in). An optional overhead line can be added: `Workstation "Chemical Weighing".hour_rate × machine_time_seconds ÷ 3600`, posted to the company's `default_operating_cost_account`. For historical backfill you won't have a real machine time — leave `machine_time_seconds` at 0 (no overhead applied) unless you want to estimate a typical weighing duration.

### Manual entry procedure

1. **Desk → New → Machine Production Record**
2. Fill header fields:
   - `machine_batch_id` — **your AppSheet batch number, exactly as-is**. This becomes the new `Batch.batch_id`, so it must not already exist as a Batch anywhere on the site (Batch names are global — see the main migration guide §2).
   - `machine_type` = `Weighing`
   - `formula_code` — must match an **active** `Formula-BOM Mapping` row with `machine = "Chemical Weighing"`. If the formula doesn't have one yet, create it first (`Formula-BOM Mapping` list) — this is what tells the system which Item the produced bag actually is.
   - `production_datetime` — backdate to the real historical date/time.
   - `status` = `Pending` (leave as default; don't set `Processed` by hand)
3. In the **Items** child table, one row per raw material consumed:
   - `item_code`, `qty`
   - `warehouse` — leave blank to default to Inside Weighing Machine WH, or set explicitly if the material came from somewhere else
   - `batch_no` — if the raw material itself is batch-tracked and you know which lot was consumed, set it here (must already exist as a Batch)
4. Save.
5. Click **Process Production Record**. This creates the Batch (using your `machine_batch_id`), a submitted Manufacture Stock Entry, computes variance against the formula's BOM, and marks the record `Processed`.
6. If it fails, the record flips to `Error` with `error_message` populated — fix the Items table and click Process again (idempotent, safe to retry).

---

## 2. Mixer

Same doctype and button as Chemical Weighing — `machine_type = Mixer` instead.

**Warehouses (live-confirmed):**
- Source: per-row, or resolved automatically via `_resolve_source_warehouse` (tank/stream mapping for silo/oil items, or the item's default warehouse otherwise)
- Target: depends on the formula's `compound_type` on the matched Formula-BOM Mapping —
  - `compound_type = CMB` or `PM` → `CMB Zone - URBM`
  - `compound_type = FMB` → `FMB Zone - URBM`

**Cost mechanics:** same pattern as Weighing — consumed materials cost via their own valuation rate; optional overhead via `Workstation "Mixer".hour_rate`.

**QC gate — important for continuity:** for `compound_type` in `CMB`/`FMB`/`PM`, processing automatically sets the new Batch's `custom_lab_status = "Pending"` and creates a **draft `Compound Lab Test`**. If your AppSheet data already recorded this batch as lab-passed historically, you'll want to update `custom_lab_status` to `"Pass"` (or the appropriate value) and complete/submit the corresponding Compound Lab Test after processing — otherwise downstream stages that gate on lab status (mixer loading for CMB/PM, calendering for FMB) will treat it as still pending.

### Manual entry procedure

Identical to §1, with `machine_type = Mixer`. After clicking **Process Production Record**, additionally:
- Open the auto-created `Compound Lab Test` draft for this batch and fill in the historical result, or
- If you don't have per-parameter lab data from AppSheet, at minimum set `Batch.custom_lab_status` to match what AppSheet recorded, so gated downstream stages behave correctly.

---

## 3. Calender

**Real mechanism:** `Calendering Run` doctype, but — unlike Machine Production Record — **its Desk form does not create Stock Entries on its own**. The `CalenderingRun.validate()` controller only checks that output quantities balance against input; the actual Manufacture/Repack/Material Transfer Stock Entries are side effects of the whitelisted `calendering.py::complete_run()` function, which the PDT wizard calls. Filling in and submitting a plain Calendering Run form in Desk will **not** move any stock.

**Warehouses (live-confirmed):**
- FMB compound consumed from: `Calendering WH - URBM` (compound must already be staged there — normally via a fulfilled Material Request, not relevant for backfill)
- Sheets produced into: `Finished Sheet WH - URBM`
- Liner/calendar returns (if any) go back to: `FMB Zone - URBM`, as a **new** batch derived from the source
- Roll tooling transferred: `WIP Calendering - URBM` → `Calender Tools In Use - URBM`

**Cost mechanics:** FMB compound consumed at its own valuation rate; optional overhead via `Workstation "Calender".hour_rate × run duration`.

### Manual entry procedure

1. Create the sheet's `Batch` record(s) directly (Desk → New → Batch), one per sheet output, `batch_id` = your AppSheet number, `item` = the sheet item code.
2. Create a **Stock Entry**, `Stock Entry Type = Manufacture`:
   - Row 1 (consumed): `item_code` = the FMB compound, `qty`, `s_warehouse = Calendering WH - URBM`, `batch_no` = the FMB batch (must already exist — see §2)
   - Row 2 (produced): `item_code` = the sheet item, `qty`, `t_warehouse = Finished Sheet WH - URBM`, `batch_no` = the sheet batch from step 1, check `Is Finished Item`
   - Set `valuation_rate` on the produced row only if you need to override the default cost roll-up (normally leave it to compute from consumption).
3. If there were liner/calendar returns, add a second Stock Entry, `Stock Entry Type = Repack`, consuming the same FMB batch from `Calendering WH - URBM` and producing a **new** batch into `FMB Zone - URBM` (a plain Material Transfer would fail here — the new batch was never in Calendering WH, so it needs a Repack to legally "convert" between batches).
4. Also create the `Calendering Run` record itself (status `Completed`, filled `sheets` table, linking the Stock Entry names into `output_stock_entry`/`return_stock_entry`) for traceability.

---

## 4–8. Building, Curing, Sleeve Grind, Cutting *(Line 2)*, Rib Grind

Per §0, these five stations now move real stock, station to station, via a new `manufacturing_universal/line2_station_flow.py` module — live-verified end to end on this system. This section is the bulk setup: BOM/operations prerequisite, the two one-time setup scripts, and how to bulk-backfill your existing AppSheet flowchart/batch IDs against the real mechanism.

### 4.0 Prerequisite — confirm before backfilling any unit

`Work Order.bom_no` is a **mandatory** field in this ERPNext version (`reqd: 1`) — there is no "skip BOM" mode for Work Order creation itself. As of this audit, **only 304 of 3,233 stock items (~9%) have any submitted BOM.** For any item without one, you cannot create a Work Order — full stop — until a BOM exists (even a minimal single-line placeholder BOM will satisfy the mandatory-field check if you're not ready to do full BOM data entry yet). Check before starting:
```
bench --site site1.local mariadb -e "SELECT COUNT(*) FROM tabBOM WHERE docstatus=1 AND item='<your item code>';"
```

### The station warehouses, already configured

`Flowchart Step Master` now carries `step_warehouse` (arrival/staging) and `step_wip_warehouse` (actively being worked) for every real station — set once via the `line2_station_warehouses` patch, live-confirmed:

| Step | Station Warehouse | Station WIP Warehouse |
|---|---|---|
| BUILDING | Sleeve Building WH  - URBM | Sleeve Building WIP - URBM |
| CURING | Curing WH - URBM | Curing WIP - URBM |
| GRINDING | Sleeve Grinding WH - URBM | Sleeve Grinding WIP - URBM |
| CUTTING | Belt Cutting WH - URBM *(new — see §0)* | Belt Cutting WIP - URBM *(new)* |
| RIB_GRINDING | Rib Grind WH - URBM | Rib Grind WIP - URBM |
| INSPECT | Inspect WH - URBM | Inspect WIP - URBM |

You don't need to set these again — they're already populated. If you ever need to point a station at a different physical warehouse, edit the relevant `Flowchart Step Master` record directly (Desk → Flowchart Step Master → the step → Station Warehouse / Station WIP Warehouse fields).

### 4.1 One-time setup — enable real per-job costing on each BOM

I checked the native ERPNext Job Card → Work Order cost rollup (`job_card.py::update_work_order()`) directly. It requires `Job Card.operation_id` — a link to a specific row in the Work Order's own `operations` child table — which only exists if the Work Order's BOM has `with_operations = 1` (a routing) and that BOM's `BOM Operation` rows get copied into `wo.operations` automatically at Work Order creation (native `set_work_order_operations()`, confirmed in `work_order.py`). **Confirmed live: 0 of the 304 submitted BOMs on this system have `with_operations = 1`.** This one-time setup fixes that, so every Work Order created against a prepared BOM gets real per-operation costing automatically from then on — no per-Work-Order manual step, no report to maintain.

Run this once per BOM (idempotent — skips BOMs already set up), driven by a CSV of `bom_no, production_type`:

```python
# apps/manufacturing_universal/manufacturing_universal/scripts/enable_flowchart_operations.py
import csv
import frappe
from frappe.utils import flt


def _ensure_operation(step_master):
    if not frappe.db.exists("Operation", step_master):
        frappe.get_doc({"doctype": "Operation", "name": step_master}).insert(ignore_permissions=True)
    return step_master


def _ensure_workstation(name):
    if not frappe.db.exists("Workstation", name):
        frappe.get_doc({"doctype": "Workstation", "workstation_name": name}).insert(ignore_permissions=True)
    return name


def enable_flowchart_operations(bom_no, production_type):
    """Cancels and amends `bom_no`, turning on with_operations and populating
    its Operations table to mirror `production_type`'s Flowchart Step Config
    sequence. The amended BOM becomes the new default. This is the setup
    step that makes Work Order.actual_operating_cost populate itself
    natively for every future Work Order against this item."""
    old = frappe.get_doc("BOM", bom_no)
    if old.with_operations and old.operations:
        return old.name  # already set up

    steps = frappe.get_all(
        "Flowchart Step Config",
        filters={"parent": production_type, "parenttype": "Production Type Master"},
        fields=["step_sequence", "step_master", "allowed_workstations", "target_time_minutes"],
        order_by="step_sequence asc",
    )
    if not steps:
        frappe.throw(f"No Flowchart Step Config for production type {production_type}")

    old.cancel()
    new = frappe.copy_doc(old)
    new.with_operations = 1
    new.set("operations", [])
    for s in steps:
        _ensure_operation(s.step_master)
        ws = (s.allowed_workstations or "").split(",")[0].strip() or _ensure_workstation(f"Line2-{s.step_master}")
        hour_rate = flt(frappe.db.get_value("Workstation", ws, "hour_rate"))
        new.append("operations", {
            "operation": s.step_master,
            "workstation": ws,
            "time_in_mins": s.target_time_minutes or 30,
            "hour_rate": hour_rate,
            "base_hour_rate": hour_rate,
        })
    new.insert(ignore_permissions=True)
    new.submit()
    frappe.db.set_value("BOM", new.name, "is_default", 1)
    frappe.db.set_value("BOM", old.name, "is_default", 0)
    return new.name


def run(bom_production_type_csv="bom_production_types.csv"):
    """CSV columns: bom_no, production_type"""
    for row in csv.DictReader(open(bom_production_type_csv)):
        try:
            new_bom = enable_flowchart_operations(row["bom_no"], row["production_type"])
            frappe.db.commit()
            print(f"{row['bom_no']} -> {new_bom}")
        except Exception as e:
            frappe.db.rollback()
            print(f"FAILED {row['bom_no']}: {e}")
```

This cancels and amends each submitted BOM — a real, visible change (the BOM gets a new document name, the old one is cancelled). Run it against a small batch first and check the result in Desk before running it across all 304.

### 4.2 Bulk-create Work Orders and replay each unit's real station history

One script, two input CSVs — this is the actual bulk backfill, run once §4.1 has been done for the BOMs you need. Unlike the version of this script from before the station-flow mechanism existed, this one **reuses the exact same functions the live PDT app calls** (`_find_or_create_job_card` for arrival, `depart_station` for departure) rather than hand-building Stock Entries — so a backfilled unit's history is indistinguishable from one that was actually scanned station-to-station on the floor, batch and all.

**`flowchart_headers.csv`** — one row per physical unit/traveler: `flowchart_number, item_code, production_type, qty, current_step, building_line`

**`flowchart_steps.csv`** — one row per already-completed step, **in order**: `flowchart_number, step_code, from_time, to_time, workstation`. Don't include `current_step` itself here — only steps that are fully done.

```python
# apps/manufacturing_universal/manufacturing_universal/scripts/bulk_flowchart_backfill.py
import csv
from collections import defaultdict

import frappe
from frappe.utils import flt, get_datetime


def _load_steps(path):
    by_flow = defaultdict(list)
    for row in csv.DictReader(open(path)):
        by_flow[row["flowchart_number"]].append(row)
    for flow in by_flow:
        by_flow[flow].sort(key=lambda r: get_datetime(r["from_time"]))
    return by_flow


def create_flowchart_wo(header, steps):
    from manufacturing_universal.line2_building import _get_flowchart_steps, _step_config, _find_or_create_job_card
    from manufacturing_universal.line2_station_flow import depart_station

    barcode = header["flowchart_number"]
    if frappe.db.exists("Work Order", {"custom_flowchart_barcode": barcode}):
        return {"skipped": barcode, "reason": "already migrated"}

    bom_no = frappe.db.get_value("BOM", {"item": header["item_code"], "docstatus": 1, "is_default": 1})
    if not bom_no:
        return {"skipped": barcode, "reason": "no submitted default BOM"}

    wo = frappe.get_doc({
        "doctype": "Work Order",
        "production_item": header["item_code"],
        "bom_no": bom_no,
        "qty": flt(header["qty"]),
        "company": frappe.db.get_default("company"),
        "wip_warehouse": "Sleeve Building WIP - URBM",
        "fg_warehouse": "Finished Belt WH - URBM",
        "custom_production_type": header["production_type"],
        "custom_building_line": header.get("building_line") or None,
    })
    wo.insert(ignore_permissions=True)
    wo.submit()  # on_submit fires: auto-generates a barcode + sets current_step to the first step
    wo.db_set("custom_flowchart_barcode", barcode, update_modified=False)  # force the real number back

    flow_steps = _get_flowchart_steps(header["production_type"])

    for i, s in enumerate(steps):
        step_code = s["step_code"]
        sc = _step_config(flow_steps, step_code)
        # Fires start_building() for BUILDING (BOM consumption -> unit batch
        # in Building's WIP) or arrive_at_station() for every other step
        # (that step's WH -> WIP) — identical to a real PDT scan.
        jc = _find_or_create_job_card(wo, step_code, sc)

        from_time, to_time = get_datetime(s["from_time"]), get_datetime(s["to_time"])
        workstation = s.get("workstation") or jc.workstation
        jc.workstation = workstation
        jc.hour_rate = flt(frappe.db.get_value("Workstation", workstation, "hour_rate"))
        jc.append("time_logs", {
            "from_time": from_time, "to_time": to_time,
            "time_in_mins": (to_time - from_time).total_seconds() / 60,
            "completed_qty": wo.qty,
        })
        jc.save(ignore_permissions=True)
        jc.submit()

        next_step = steps[i + 1]["step_code"] if i + 1 < len(steps) else header["current_step"]
        depart_station(wo, step_code, next_step)  # that step's WIP -> next step's WH

    wo.reload()
    wo.db_set("custom_current_step", header["current_step"], update_modified=False)

    return {"created": barcode, "work_order": wo.name, "unit_batch": wo.custom_unit_batch}


def run(headers_csv="flowchart_headers.csv", steps_csv="flowchart_steps.csv"):
    headers = list(csv.DictReader(open(headers_csv)))
    steps_by_flow = _load_steps(steps_csv)

    for h in headers:
        try:
            result = create_flowchart_wo(h, steps_by_flow.get(h["flowchart_number"], []))
            frappe.db.commit()
        except Exception as e:
            frappe.db.rollback()
            result = {"error": h["flowchart_number"], "message": str(e)}
        print(result)
```

Run: `bench --site site1.local execute manufacturing_universal.scripts.bulk_flowchart_backfill.run`. Idempotent — a re-run skips any `flowchart_number` already migrated, so a failed batch partway through is safe to re-run after fixing the offending row. If `flowchart_steps.csv` has zero rows for a unit still at `BUILDING`, that's fine — the loop won't run, and `custom_current_step` still gets set to `BUILDING` at the end, matching a unit that's just arrived and hasn't been scanned yet.

**On per-job costing:** if the BOMs referenced weren't set up per §4.1 (`with_operations=1`), the Job Cards above will still submit and the real stock transfers still happen correctly — you just won't get the native `actual_operating_cost` rollup (§4.3 still works as a fallback query in that case). Run §4.1 first if you want costing wired up from the start.

If a step involved rework (per your AppSheet history), set `custom_is_rework = 1` and `custom_rework_count` on that Job Card row before `jc.save()`, and increment `Work Order.custom_rework_count` to match — mirrors `line2_rejection.py::create_rejection()`'s Rework path. Add these as extra optional columns in `flowchart_steps.csv` if you need them.

### 4.3 Additional operating costs

Native `Work Order.calculate_operating_cost()` (confirmed in `work_order.py`) computes:

```
total_operating_cost = additional_operating_cost + (actual_operating_cost or planned_operating_cost) + corrective_operation_cost
```

`actual_operating_cost` is the sum of `hour_rate × actual_operation_time` across `wo.operations` — this now populates itself once §4.1 and §4.2 are done, no further action needed. The other two fields are for costs the per-step time doesn't capture:

- **`additional_operating_cost`** — a flat, non-time-based top-up on the Work Order itself. Use this for anything AppSheet tracked as a per-unit cost that isn't proportional to logged time (a consumables allowance, a fixed admin/QC surcharge, etc.). Set it directly and recalculate:
  ```python
  wo = frappe.get_doc("Work Order", wo_name)
  wo.additional_operating_cost = 12.50
  wo.calculate_operating_cost()
  wo.save(ignore_permissions=True)
  ```
- **`corrective_operation_cost`** — native ERPNext's own field for rework, but it only accumulates from Job Cards with `is_corrective_job_card = 1` (a different flag from this codebase's `custom_is_rework`). If you want historical rework cost to roll into this native field too, set both flags on the same Job Card row.

### 4.4 Backtracking — "which stage is this flowchart number done through"

Given a flowchart number, three pieces of data answer this, cross-referenced:

1. **Current state** — `Work Order` looked up by `custom_flowchart_barcode`: gives `custom_current_step` (where it is now) and `custom_production_type` (which sequence applies).
2. **Completed history** — every **submitted** `Job Card` for that Work Order, ordered by creation: each row's `custom_flowchart_step` is one completed step, with its time log and any rework flag.
3. **The full expected sequence** — `Flowchart Step Config` for that production type, ordered by `step_sequence` — lets you compute "% complete" and "which steps remain."

A ready-made lookup function (put this in a script, or call ad hoc via `bench console` — it's read-only, safe to run anytime):

```python
import frappe
from frappe.utils import flt

def get_flowchart_history(barcode):
    wo = frappe.db.get_value(
        "Work Order",
        {"custom_flowchart_barcode": barcode, "docstatus": 1},
        ["name", "custom_current_step", "custom_production_type", "custom_rework_count",
         "production_item", "qty", "actual_operating_cost", "total_operating_cost"],
        as_dict=True,
    )
    if not wo:
        frappe.throw(f"No submitted Work Order found for flowchart barcode '{barcode}'")

    all_steps = frappe.get_all(
        "Flowchart Step Config",
        filters={"parent": wo.custom_production_type, "parenttype": "Production Type Master"},
        fields=["step_sequence", "step_master"],
        order_by="step_sequence asc",
        pluck="step_master",
    )

    completed = frappe.get_all(
        "Job Card",
        filters={"work_order": wo.name, "docstatus": 1},
        fields=["custom_flowchart_step", "creation", "modified",
                 "custom_is_rework", "hour_rate", "total_time_in_mins"],
        order_by="creation asc",
    )

    completed_steps = [c.custom_flowchart_step for c in completed if not c.custom_is_rework]
    remaining = [s for s in all_steps if s not in completed_steps and s != wo.custom_current_step]

    return {
        "flowchart_barcode": barcode,
        "work_order": wo.name,
        "production_item": wo.production_item,
        "current_step": wo.custom_current_step,
        "rework_count": wo.custom_rework_count or 0,
        "completed_steps": completed_steps,
        "remaining_steps": remaining,
        "percent_complete": round(len(completed_steps) / len(all_steps) * 100, 1) if all_steps else 0,
        "step_history": completed,
        "actual_operating_cost": flt(wo.actual_operating_cost),
        "total_operating_cost": flt(wo.total_operating_cost),
    }
```

`actual_operating_cost`/`total_operating_cost` now come straight off the Work Order itself — populated natively as each Job Card submits with its `operation_id` set (§4.1/§4.2), no separate cost query needed.

For a durable, click-to-use version rather than a console call: save this as a **Frappe Script Report** (Desk → Report → New Report, type "Script Report") with `barcode` as a report filter — a searchable "scan or type a flowchart number, see its full history" screen for floor/office staff, no bench access needed.

---

## 9. QC (Inspect arrival + final handoff to Finished Belt WH)

Raw material is now consumed **once, at Building** (§4.1's `start_building()`) — QC no longer re-consumes the BOM. `complete_wo()` is now just the unit batch's last hop.

**Real mechanism:** `line2_qc.py` — `start_qc()` (loads measurement params) → `submit_measurement()` (pass/fail per param on the QC Job Card) → `submit_qc_result()` (records rejections via `Rejection Log`: `Rework` creates a new Job Card back at a return-to step and moves the batch there via `arrive_at_station`; `Full Scrap` moves the batch from wherever it actually currently sits to `Scrap - URBM`, looked up dynamically — not a hardcoded warehouse) → `complete_wo()`.

**`complete_wo()`, live-verified:**
- If `Work Order.custom_unit_batch` is set (every Work Order created via §4's mechanism has this): a single **Material Transfer**, `custom_unit_batch`'s current location (should be `Inspect WIP - URBM`, arrived there when the Inspect Job Card was created) → `wo.fg_warehouse` if set, else `Finished Belt WH - URBM`. No new batch is created — the same batch that was created at Building carries its accumulated cost straight through.
- If `custom_unit_batch` is **not** set (a Work Order created before this mechanism existed, or one you deliberately backfilled without it): falls back to the old behavior — consumes the entire BOM from `Sleeve Building WH  - URBM` and creates a brand-new finished batch. This fallback exists for backward compatibility; every new backfill via §4.2 sets `custom_unit_batch`, so you shouldn't need it.
- For Sleeve-UOM items, also computes `belt_qty` via the item's Belt UOM conversion factor — purely informational, doesn't change what's posted.

**Cost mechanics:** the transferred batch already carries whatever cost it accumulated at Building (raw material valuation + any additional/operating cost you set per §4.3) — nothing new is costed at this step.

### Manual entry procedure

If you're backfilling via §4.2, this step needs **no separate manual entry** — `_find_or_create_job_card(wo, "INSPECT", ...)` (fired automatically as part of the §4.2 replay) already moves the batch into `Inspect WIP - URBM`; calling `complete_wo(wo.name)` finishes the job:

```python
from manufacturing_universal.line2_qc import complete_wo
complete_wo(wo_name)
```

For a unit that was **rejected outright** (never finished) rather than passing QC: instead of calling `complete_wo()`, call `create_rejection(wo_name, job_card_name, reason_code, qty, "Full Scrap")` from `line2_rejection.py` — it finds the batch's real current location and moves it to `Scrap - URBM` itself.

---

## 10. Warehouse Packing

**Real mechanism:** `Box`/`Pallet` doctypes. **No stock movement** — these only group existing FG batches (already sitting in `Finished Belt WH - URBM` from §9) against a Sales Order, for traceability and later shipment. The stock ledger doesn't change when something is packed.

### Manual entry procedure

Only relevant if AppSheet tracked "which finished units are already boxed/palletized but not yet shipped," and you want that grouping preserved:

1. Confirm a `Sales Order` exists for the relevant customer/order (Box/Pallet both require one — `sales_order` is a mandatory Link).
2. Desk → New → Box: `box_barcode` (use your AppSheet box number if tracked, otherwise the doctype will auto-generate one via the app's own `create_box` if you go through the API instead of a raw Desk insert), `sales_order`, `status = Open`.
3. Add each FG batch/qty to the Box's `items` child table — `item_code`, `batch_no` (must exist from §9), `qty`.
4. If AppSheet also tracked pallet groupings: Desk → New → Pallet similarly, then add the Box(es) to the Pallet's `boxes` table (`pallet_type = "Belt"`) or add items directly to `direct_contents` (`pallet_type = "Sleeve"`).

---

## 11. Packed *(and Shipped, one step beyond)*

**Real mechanism:** a status flip, `Box.status`/`Pallet.status` from `Open` → `Sealed`. Still no stock movement.

### Manual entry procedure

1. Set `status = "Sealed"` on the Box/Pallet record from §10 (only valid once it has at least one item row).
2. **Only if the unit was genuinely already shipped out** (not just packed) in AppSheet's history: this is where real stock finally leaves the warehouse. Rather than calling `ship_box`/`ship_pallet` (which expects a live Sales Order fulfillment flow), for a historical backfill it's cleaner to create the `Delivery Note` directly (Desk → New → Delivery Note, against the Sales Order, `set_warehouse = Finished Belt WH - URBM`, item/batch/qty rows matching the Box/Pallet contents), submit it, then set `Box.status`/`Pallet.status = "Shipped"` and `delivery_note` to the DN name by hand to keep the records linked. Don't call `ship_box`/`ship_pallet` for backdated records — they're designed to create the DN with today's date from currently-sealed live state, not a historical one.

---

## Cost / valuation cheat-sheet across every stage

None of these stages ask you to type in a cost directly (except optional overhead). Cost always flows from **the valuation rate already sitting on the consumed item/batch/warehouse combination**, per standard Frappe stock costing. This means the single highest-leverage thing to get right before touching any of the above is:

1. **Every raw material batch you create during opening-stock posting (main migration guide §5c) needs a correct `valuation_rate`.** Everything downstream — bag cost, compound cost, sheet cost, finished belt cost — is a mechanical roll-up from there. Garbage in at the raw-material layer means every finished-goods valuation from Weighing through QC is wrong.
2. **Labor/operating cost** at Weighing, Mixer, and Calender uses `Workstation.hour_rate × machine time` as an `additional_costs` line on that stage's own Stock Entry. Building through Inspect use a different, native mechanism instead — `Work Order.actual_operating_cost`, populated automatically once §4.1/§4.2 are done (see §4.3 for the full breakdown, including `additional_operating_cost` for flat non-time-based top-ups). These don't feed the same GL account by default — reconcile with your accountant if you want them to.
3. Frappe's own valuation method (FIFO by default on this site) determines which specific batch's rate gets consumed when multiple batches of the same item sit in one warehouse — so if AppSheet's per-batch costs varied, get the batches in with correct individual `valuation_rate`s and correct `manufacturing_date` ordering, and let FIFO do the rest; don't try to average them into one blended rate.

---

## Quick reference — warehouse map used by this guide (live-confirmed 2026-07-10)

| Setting field | Warehouse |
|---|---|
| `inside_weighing_warehouse` | Inside Weighing Machine WH - URBM |
| `wip_bags_warehouse` | WIP Bags - URBM |
| `cmb_zone_warehouse` | CMB Zone - URBM |
| `fmb_zone_warehouse` | FMB Zone - URBM |
| `calendering_warehouse` | Calendering WH - URBM |
| `finished_sheet_warehouse` | Finished Sheet WH - URBM |
| `wip_calendering_warehouse` | WIP Calendering - URBM |
| `calender_tools_store_warehouse` / `calender_tools_in_use_warehouse` | Calender Tools Store - URBM / Calender Tools In Use - URBM |
| `cutting_warehouse` | Cutting WH - URBM *(Line 1 sheet-repack, not the Line 2 flowchart CUTTING step)* |
| `building_material_warehouse` | Sleeve Building WH  - URBM *(double space, real name — consumed once, at Building)* |
| `building_wip_warehouse` / `sleeve_wip_warehouse` | Sleeve Building WIP - URBM |
| `finished_belt_warehouse` | Finished Belt WH - URBM |
| `line2_scrap_warehouse` | Scrap - URBM |
| `mixer_workstation` / `weighing_workstation` / `calender_workstation` | Mixer / Chemical Weighing / Calender |

Re-run `bench --site site1.local execute manufacturing_universal.silo_loading._get_settings` before a real migration run — these have flipped after DB restores before.

**Per-station WH/WIP pairs (on `Flowchart Step Master`, not Manufacturing Settings URBM — see §4):**

| Step | Station Warehouse | Station WIP Warehouse |
|---|---|---|
| BUILDING | Sleeve Building WH  - URBM | Sleeve Building WIP - URBM |
| CURING | Curing WH - URBM | Curing WIP - URBM |
| GRINDING | Sleeve Grinding WH - URBM | Sleeve Grinding WIP - URBM |
| CUTTING *(Line 2 step)* | Belt Cutting WH - URBM | Belt Cutting WIP - URBM |
| RIB_GRINDING | Rib Grind WH - URBM | Rib Grind WIP - URBM |
| INSPECT | Inspect WH - URBM | Inspect WIP - URBM |

---

## Note on "Cutting"

This system has two distinct things called cutting: the Line 2 flowchart `CUTTING` step (part of the sleeve/belt build sequence, §4–8 — confirmed this is what your AppSheet "Cutting" stage means) and an unrelated Line 1 "Cutting & Splicing" sheet-repack operation (`line1_cutting.py`, real Repack Stock Entry, `Finished Sheet WH - URBM` → `Cutting WH - URBM`, changes item identity) that isn't part of this guide.
