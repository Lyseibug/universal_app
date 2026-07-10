# AppSheet → Frappe Data Migration Guide

**Purpose:** move current stock, batch numbers, and in-flight flowchart travelers out of Google AppSheet and into this Frappe system as the new system of record.

**Audited live against site1.local on 2026-07-10.** All doctype names, field names, and counts below were pulled fresh from the running system, not from a prior write-up — re-run the audit queries in §9 if you use this guide more than a few days after this date, since warehouse links and scheduler state have flipped after restores before on this bench.

---

## 1. The two things AppSheet tracks, and how each maps to Frappe

You confirmed two categories of AppSheet data need to move:

| AppSheet concept | What it actually is | Frappe equivalent |
|---|---|---|
| **Batch number** | An identifier on a lot of material/compound/product | `Batch.batch_id` (also the document name) |
| **Flowchart number** | A number generated when a work order is created from a plan; printed on a physical flowchart sheet that travels with the sleeve/belt on the floor; used to look up which station it's at and which steps are already done | `Work Order.custom_flowchart_barcode`, with live station = `Work Order.custom_current_step` and step history = one `Job Card` per completed step |

These are **independent** in Frappe. A Batch is a stock-ledger concept (which lot, how much, in which warehouse). A flowchart number is a Work-Order-tracking concept (which unit, at which station, with which steps done). A single physical sleeve/belt on your floor will usually need **both**: a Batch record for its stock quantity, and a Work Order for its flowchart traveler — linked to each other by warehouse (the WIP warehouse the Work Order is currently transferring into/out of holds the stock for that Batch).

### 1a. How the flowchart mechanism actually works today (verified in code)

This was clearly purpose-built to formalize exactly what you're describing — it isn't a stretch fit:

- `Production Type Master` (7 records: `AX`, `CR`, `PK`, `SPA`, `SPB`, `SPZ` = category **Belt**; `TB` = category **Sleeve**) defines a named production route.
- `Flowchart Step Config` (37 rows total, a child table on Production Type Master) defines the **ordered sequence of steps** for each type — e.g. `PK` has 6 configured steps, `CR` has 5, `TB` has 2.
- `Flowchart Step Master` (6 global step definitions: `BUILDING`, `CURING`, `CUTTING`, `GRINDING`, `INSPECT`, `RIB_GRINDING`) are the steps those sequences are built from.
- On **Work Order submit**, `manufacturing_universal/line2_wo_hooks.py::on_submit` runs:
  1. Resolves `custom_production_type` (from the field on the WO itself, or falls back to `Item.custom_production_type` — **but that Item field is 0/5,748 populated on this system today**, so in practice you must set `custom_production_type` explicitly on every Work Order).
  2. **Unconditionally regenerates `custom_flowchart_barcode`** via `flowchart_naming.generate_flowchart_code()` — an "AR08-style" code: `[Year-letter][Month-letter][Day] [ProductLetter][Seq]`, e.g. `BR08 P001` decodes to 2026-07-08, product letter `P`, sequence 001. This uses `Production Type Master.flow_code_letter` — **currently NULL on all 7 records**, so right now every WO submission falls through to a legacy fallback code (`FC-{WO name}-{random hex}`) instead of the real scheme.
  3. Sets `custom_current_step` to the **first** step in that type's sequence.
- The PDT app's `scan_flowchart(barcode)` endpoint (`manufacturing_universal/line2_building.py`) is what the floor actually uses: scan the barcode → look up the submitted Work Order by `custom_flowchart_barcode` → read `custom_current_step` → find-or-create a `Job Card` for that step → capture measurements/rework/tool/photo → on completion, advance `custom_current_step` to the next step in the sequence and move stock between the step's WH/WIP warehouse pair.

**Critical implication for migration:** because step 2 above is unconditional, you cannot pre-set `custom_flowchart_barcode` on a new Work Order and expect `submit()` to leave it alone — it will overwrite it with a freshly generated code. To preserve an AppSheet-origin flowchart number, submit the Work Order normally (so all the real side effects fire), then immediately force the field back with `frappe.db.set_value(...)`, which bypasses the hook. This is shown in §7.

---

## 2. Live system state right now (why order matters)

Zero of the following have ever existed on this bench: Work Orders, Job Cards, Stock Reconciliations, Sleeve Creation Logs, Rejection Logs, Cutting Logs, Tool Usage Logs. This is a genuine from-scratch go-live, not a top-up of an already-running system — so there's no risk of double-counting existing Frappe stock, but also no existing pattern to copy from; every choice below (warehouse mapping, valuation source, ID collision rules) is a first-time decision you're locking in.

What **does** already exist and must not collide with anything you migrate:

- **1,110 Batch records**, all created this week from live compound production, with internal naming conventions already in use: `PM-<formula>-<seq>` (Premix), `FMB-<formula>-<seq>` (Final Mixed Batch), `BAG-<formula>-<n>-<seq>` (weighed bags), plus bare numeric IDs like `4810304` for supplier lots. **`Batch.batch_id` is the document's actual primary key and must be globally unique across the entire site — not just per item.** If AppSheet numbers batches per-item (e.g. every product has its own "001", "002"...), those will collide with each other on import unless you namespace them (see §5).
- **517 Warehouse LOT records** — a separate location/slot master (floor/aisle/rack, max dimensions, current occupant), not a transactional ledger. Don't confuse this with Batch; it's closer to "which physical bin/tank" than "which lot of material."
- **304 of 3,233 stock items (~9%) have any submitted BOM.** This blocks creating a real Work Order for the other 91% today unless you either add a BOM first or the Work Order doesn't require backflush consumption for your purposes.
- **~2,650 of 5,751 items have a default expense/inventory account set on Item Default; roughly 3,100 don't.** Any Stock Entry or Stock Reconciliation against an item missing this will throw at GL posting time. Check before a bulk run, not during one (query in §9).
- `Stock Settings.auto_create_serial_and_batch_bundle_for_outward = 1` is **on** — required for FIFO batch consumption to work correctly against whatever you import; don't turn it off.

---

## 3. Get the data out of AppSheet

You weren't sure yet how your AppSheet app is backed. Check this first, in order of likelihood:

1. **Open the app in the AppSheet editor → Data → Tables.** Each table shows its source. The overwhelming majority of AppSheet apps sit directly on top of a Google Sheet (sometimes Excel on OneDrive/SharePoint). If you see a Google Sheets icon next to each table, you have direct access.
2. If backed by Sheets: open each underlying spreadsheet directly (Data → Tables → click the table → "Open source spreadsheet" or similar) and use **File → Download → Comma Separated Values (.csv)** per tab, or **File → Download → Microsoft Excel** for the whole workbook in one file. Do this for every relevant tab, not just the ones the app's UI surfaces — AppSheet apps commonly have hidden or reference-only tables that still hold real data (lookup tables, historical logs).
3. If there's no visible backing spreadsheet (data lives only inside AppSheet's own storage), you have two fallback paths:
   - The **AppSheet API** (Enterprise plans) can pull table data programmatically — check your AppSheet plan tier first, this isn't available on all tiers.
   - Manual export via the app's own UI (view a table as a deck/table view, select all, copy) — workable for hundreds of rows, painful past a few thousand. Given you estimated 5,000+ rows, push hard on finding the backing spreadsheet before resorting to this.
4. Either way, **export everything relevant as of one single cutover moment** (e.g. "as of 2026-07-13 08:00", before the floor starts that shift) — don't stagger the export across days, or you'll double-count movements that happen in between on paper but not yet in AppSheet.

Tables to pull, based on what you told me needs to move:

- **Item/product master** (if AppSheet has its own product codes/names — needed to map to the 5,748 Items already in Frappe).
- **Batch/lot register** — whatever table assigns batch numbers to quantities of material/compound/product.
- **Current stock by location** — a snapshot of qty per item per station/warehouse/bin, right now, including WIP and staging.
- **Flowchart/traveler tracker** — whatever table or view records, per flowchart number: which item/product it is, which station it's currently at, and which steps are already completed (even if that's just a set of checkbox columns per step, e.g. `Building_Done`, `Curing_Done`, `QC_Done`).

---

## 4. Map AppSheet stations to real Frappe warehouses

Your Frappe warehouse tree already models individual stations physically — this is a real asset, not something to rebuild. Every "station" your AppSheet flowchart references should map to one of these (all under `Production - URBM`, confirmed live):

| Station concept | WH (finished-for-step) | WIP (in-process) |
|---|---|---|
| Sleeve Building | `Sleeve Building WH  - URBM` (note: double space in the real name) | `Sleeve Building WIP - URBM` |
| Curing | `Curing WH - URBM` | `Curing WIP - URBM` |
| Sleeve Grinding | `Sleeve Grinding WH - URBM` | `Sleeve Grinding WIP - URBM` |
| Rib Grinding | `Rib Grind WH - URBM` | `Rib Grind WIP - URBM` |
| Measure | `Measure WH - URBM` | `Measure WIP - URBM` |
| Inspect | `Inspect WH - URBM` | `Inspect WIP - URBM` |
| Cutting | `Cutting WH - URBM` | `Cutting WIP - URBM` |
| Calendering | `Calendering WH - URBM` | `WIP Calendering - URBM` |
| Compound premix | `CMB Zone - URBM` | — |
| Final mixed batch | `FMB Zone - URBM` | — |
| Mixer | `Mixer Staging WH - URBM` | `Mixer WIP - URBM` |
| Weighing | `Outside Weighing Machine WH - URBM` / `Inside Weighing Machine WH - URBM` | `WIP Bags - URBM` |
| Finished belt | `Finished Belt WH - URBM` | — |
| Finished sheet | `Finished Sheet WH - URBM` | — |
| Scrap/reject | `Scrap - URBM` | — |
| Raw material stores | `WH-A Inbound/Outbound`, `WH-B Cord & Fabrics`, `WH-C Chilled Polymer`, `WH-D Normal Polymer`, `WH-E Fiber`, `WH-F Chemical`, `WH-G Oil`, `WH-H Carbon Black`, `WH-I Quarantine`, `WH-L Finished Products` (all `- URBM`, spread across First/Second/Third/Ground floor) | — |

**Note:** `Manufacturing Settings URBM`'s five Line 2 warehouse fields (`building_material_warehouse`, `building_wip_warehouse`, `sleeve_wip_warehouse`, `finished_belt_warehouse`, `line2_scrap_warehouse`) drive which of the above the PDT app code actually writes to for rejection/tool/QC flows. Confirm these are linked (not blank) before you rely on post-migration floor scans working — this has been found unset after DB restores before.

Build one small lookup CSV mapping every distinct AppSheet station label to the correct warehouse name above before writing any import script — don't hardcode the mapping inline, since you'll want to review/correct it before it touches data.

---

## 5. Field-by-field mapping

### 5a. Items

Match every AppSheet product row to an existing Frappe `Item` by whatever stable code both systems share (barcode, model code, etc.) — **do not** create new Items automatically for unmatched rows. Print an "unmatched" report and resolve those by hand; auto-creating placeholder items has, elsewhere in this project, silently produced items with no default inventory account and no BOM, both of which then block every downstream stock/production posting. With 5,748 Items already loaded, most matches should be direct.

### 5b. Batch numbers

Target: `Batch` doctype.

| AppSheet field | Frappe field | Notes |
|---|---|---|
| Batch/lot number | `batch_id` (= document name, via `autoname: field:batch_id`) | **Must be globally unique site-wide.** Confirmed: your AppSheet batch numbers are already globally unique, so import them as-is — no prefixing. The only check needed is against the 1,110 existing `PM-`/`FMB-`/`BAG-`/numeric batches already on this system (§9 pre-flight query dumps the existing list to diff against). |
| Item | `item` (Link → Item, required) | Must resolve via §5a first. |
| Quantity | `batch_qty` | |
| Production/manufacture date | `manufacturing_date` | |
| Expiry date, if tracked | `expiry_date` | |
| — | `custom_lab_status` | Set explicitly (`Pending`/`Pass`/`Fail`/`Conditional Pass`) — don't leave blank if your QC process expects it populated; downstream lab-gate logic checks this field. |

### 5c. Current stock (opening balances)

Target: **`Stock Reconciliation`**, not `Stock Entry`. Stock Reconciliation is ERPNext's purpose-built tool for "set the qty and value of X in warehouse Y as of date Z" without needing a source/target movement — exactly your "opening balance" case, and it's never been used on this bench (0 records), so there's no prior convention to break.

| AppSheet field | Frappe field (Stock Reconciliation Item) | Notes |
|---|---|---|
| Item | `item_code` | |
| Station (mapped via §4) | `warehouse` | |
| Batch number | `batch_no` | Must already exist as a `Batch` from §5b. |
| Quantity on hand | `qty` | |
| Value | `valuation_rate` | Read directly from your own `valuation_rate` column in the import CSV — see §5d. |

Group reconciliation lines into batches by warehouse or by cutover pass — a single `Stock Reconciliation` document can carry many item/warehouse/batch rows; you don't need one document per row.

### 5d. Valuation rate

Confirmed: you're supplying `valuation_rate` as a column in the import CSV yourself (your own cost sheet), one value per row — the script reads it directly, no lookup against `Item Price`/Purchase Receipt needed. One rule regardless of source: do **not** set `allow_zero_valuation_rate=1` together with a `basic_rate`/`valuation_rate` on the same line — this codebase has already hit a bug elsewhere where that combination silently zeroes the rate, which then breaks FG valuation downstream with a "Valuation Rate Missing" throw. Set `valuation_rate` only.

### 5e. Flowchart numbers (in-flight WIP travelers only)

This section applies **only** to units currently mid-process on the floor with a physical flowchart sheet attached — not to items merely sitting as stock. Target: **`Work Order`** (backfilled as submitted, docstatus=1) + one **`Job Card`** per already-completed step.

| AppSheet field | Frappe field | Notes |
|---|---|---|
| Flowchart number | `custom_flowchart_barcode` | **Must be forced back after submit** — see §7, the on_submit hook overwrites it otherwise. Must also be globally unique (the field has `unique=1`). |
| Product/model | `production_item` | Resolve via §5a. |
| Quantity | `qty` | |
| Belt/Sleeve type (AX/CR/PK/SPA/SPB/SPZ/TB) | `custom_production_type` | Must be set explicitly — `Item.custom_production_type` is unpopulated everywhere on this system, so there is no fallback. |
| Station currently at | `custom_current_step` | Set **after** submit, to the true current step — submit's hook will otherwise default it to the sequence's first step. |
| Building line/workstation, if tracked | `custom_building_line` | Link to Workstation. |
| Steps already completed | One submitted `Job Card` per step, `custom_flowchart_step` = that step's code | Backdate `creation`/completion where you have a real date from AppSheet history; where you don't, at minimum preserve the *order* so step history reads correctly. |

---

## 6. Recommended staged order

Given the scale (5,000+ rows, multiple sheets) and that all four data categories (stock, WIP, historical records, item specs) need to move, don't run this as one script. Stage it with a checkpoint after each phase:

1. **Item master reconciliation** — resolve every AppSheet product code against Frappe's existing 5,748 Items; fix the unmatched list by hand. Nothing downstream should run until this list is clean.
2. **Batch master** — create all `Batch` records (§5b) for material, compound, and product lots. No stock movement yet, just the batch identities.
3. **Opening stock** — post `Stock Reconciliation` (§5c) for raw material and staged/finished stock that is **not** mid-flowchart (i.e. sitting still, no traveler attached).
4. **WIP flowchart travelers** — for units actively on the floor with a flowchart number, create the backfilled Work Order + Job Card history (§5e) **and** its current stock position (its WIP warehouse qty) in the same pass, since both represent the same physical unit — don't split these across separate stages or they'll temporarily disagree.
5. **Historical/closed records** (already-shipped or already-consumed batches) — lowest priority, doesn't block floor operations; migrate last, purely for traceability/reporting.

Reconcile total quantities (sum of qty by item, AppSheet vs. Frappe) after every stage before moving to the next.

---

## 7. Script skeleton

This repo already has a convention for one-off admin/import scripts: `apps/manufacturing_universal/manufacturing_universal/scripts/*.py`, each with a `run()` entrypoint invoked via `bench --site site1.local execute manufacturing_universal.scripts.<module>.run`. Follow that pattern rather than the generic Data Import Tool — the orchestration below (Batch → Stock Reconciliation → Work Order → Job Card, with cross-references) is beyond what a flat CSV-to-doctype import can express in one pass.

```python
# apps/manufacturing_universal/manufacturing_universal/scripts/appsheet_migration.py
import frappe
from frappe.utils import now_datetime

def create_batches(rows):
    """rows: list of dicts with keys: batch_id, item, batch_qty, manufacturing_date"""
    created, skipped = [], []
    for r in rows:
        if frappe.db.exists("Batch", r["batch_id"]):
            skipped.append(r["batch_id"])  # review collisions before re-running
            continue
        if not frappe.db.exists("Item", r["item"]):
            skipped.append(r["batch_id"])  # unresolved item, fix mapping first
            continue
        frappe.get_doc({
            "doctype": "Batch",
            "batch_id": r["batch_id"],
            "item": r["item"],
            "batch_qty": r["batch_qty"],
            "manufacturing_date": r.get("manufacturing_date"),
        }).insert(ignore_permissions=True)
        created.append(r["batch_id"])
    return created, skipped


def post_opening_stock(warehouse, lines, posting_datetime=None):
    """lines: list of dicts with keys: item_code, batch_no, qty, valuation_rate"""
    sr = frappe.get_doc({
        "doctype": "Stock Reconciliation",
        "purpose": "Opening Stock",
        "posting_date": (posting_datetime or now_datetime()).date(),
        "posting_time": (posting_datetime or now_datetime()).time(),
        "company": frappe.db.get_default("company"),
        "items": [
            {
                "item_code": l["item_code"],
                "warehouse": warehouse,
                "batch_no": l["batch_no"],
                "qty": l["qty"],
                "valuation_rate": l["valuation_rate"],
            }
            for l in lines
        ],
    })
    sr.insert(ignore_permissions=True)
    sr.submit()
    return sr.name


def run():
    # Load your exported CSVs here (frappe.utils.csvutils or pandas) and call
    # create_batches / post_opening_stock in the order from §6. Keep this
    # run() a thin driver — log every created/skipped ID so a partial run
    # can be resumed idempotently (both functions already check for
    # pre-existing records).
    pass
```

Flowchart traveler backfill (Work Order + Job Card, with real per-job costing and backtracking) is a bulk CSV-driven script of its own, not a single function — see the companion `STAGE-BY-STAGE-MANUAL-ENTRY-GUIDE.md` §4, which is the authoritative version.

Delete/adjust this script after the migration is done — the convention in this repo is that scripts here are one-off and disposable, not long-lived automation.

---

## 8. Validation checklist before calling it done

- [ ] Row counts: AppSheet source rows vs. Frappe records created, per table, with a logged list of skipped/unmatched rows (not just a total).
- [ ] Quantity reconciliation: sum of qty by item between AppSheet's snapshot and Frappe's post-migration stock (`Bin.actual_qty` by item/warehouse).
- [ ] Every migrated flowchart number resolves via the same `scan_flowchart` PDT endpoint the floor will actually use — test at least one real barcode end-to-end on a device, not just via Desk.
- [ ] No duplicate `Batch.batch_id` or `Work Order.custom_flowchart_barcode` (both are unique fields; a bulk insert will throw immediately on collision, but check before printing any physical labels from the migrated data).
- [ ] Spot-check GL impact of the opening Stock Reconciliation with your accountant — this is the first real valuation entry this system has ever posted at this scale.

---

## 9. Pre-flight queries (run these fresh, don't trust the numbers above past a few days)

```bash
# Item-wise inventory account gap (blocks GL posting)
bench --site site1.local mariadb -e "
SELECT COUNT(DISTINCT parent) FROM \`tabItem Default\`
WHERE expense_account IS NOT NULL AND expense_account != '';"

# BOM coverage (affects whether Work Orders need a BOM created first)
bench --site site1.local mariadb -e "SELECT COUNT(DISTINCT item) FROM tabBOM WHERE docstatus=1;"

# Confirm Line 2 warehouse links are still set (flips after DB restores)
bench --site site1.local execute manufacturing_universal.silo_loading._get_settings

# Existing Batch IDs, to check for collisions before import
bench --site site1.local mariadb -e "SELECT batch_id FROM tabBatch;" > existing_batches.txt
```

---

## Still needed before this is actionable

Decisions are locked (batch numbers import as-is, valuation rate comes from your CSV). What's left is fact-finding, not choices:

1. **Confirm the AppSheet export path** (Google Sheets vs. API vs. manual) — §3. Check the AppSheet editor's Data → Tables view first.
2. **Supply the actual AppSheet column names/table structure** once exported, so §5's mapping table can be made concrete instead of conceptual.
3. **Optionally configure `flow_code_letter`** on the 7 Production Type Master records, so Work Orders created *after* the migration generate real AR08-style codes instead of the current `FC-` fallback — unrelated to the migration itself but worth fixing before go-live regardless.
