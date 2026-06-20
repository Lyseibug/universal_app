# Mobile App Changes — Two-Step Batch & Put-Away Flow

## PDT Screen Configuration

Both steps live inside the **existing `grn_putaway` screen** — no new PDT Screen record needed.
The route stays `/grn-putaway`; the two steps are sub-views within it.

### Screen-Level Changes

| Field | Old Value | New Value |
|-------|-----------|-----------|
| `screen_label` | Bin Allocation | **GRN Put-Away** |

### Action Changes

| Action Key | Action Label | Change | Required Role |
|-----------|-------------|--------|---------------|
| `put_away` | Put Away | **Remove** (replaced by two below) | — |
| `create_batch` | Create Batch | **Add** | *(same as screen role)* |
| `allocate_bin` | Allocate to Bin | **Add** | *(same as screen role)* |
| `override_suggested_lot` | Scan Different Bin | Keep as-is | — |
| `override_capacity` | Override Full Bin | Keep as-is | *(supervisor role)* |

### How `require_pdt` Maps to Actions

| API Endpoint | `require_pdt` Call | Action Checked |
|-------------|-------------------|----------------|
| `grn.list_pending` | `require_pdt("grn_putaway")` | Screen access only |
| `grn.get` | `require_pdt("grn_putaway")` | Screen access only |
| `grn.list_created_batches` | `require_pdt("grn_putaway")` | Screen access only |
| `grn.suggest_lot` | `require_pdt("grn_putaway")` | Screen access only |
| `grn.create_batch` | `require_pdt("grn_putaway", "create_batch")` | `create_batch` action |
| `grn.allocate_to_bin` | `require_pdt("grn_putaway", "allocate_bin")` | `allocate_bin` action |
| `grn.allocate_to_bin` (force) | `require_pdt("grn_putaway", "override_capacity")` | `override_capacity` action |

### Setup Instructions (ERPNext Desk)

1. Open **PDT Screen → grn_putaway**
2. Change `screen_label` from "Bin Allocation" to "GRN Put-Away"
3. In the **Actions** table:
   - Delete the row with `action_key = put_away`
   - Add row: `action_key = create_batch`, `action_label = Create Batch`
   - Add row: `action_key = allocate_bin`, `action_label = Allocate to Bin`
4. Save

---

## Overview

The GRN put-away is now **two separate steps** on the PDT instead of one:

| Step | What the Worker Does | What the System Does |
|------|---------------------|---------------------|
| **1. Create Batch** | Enters qty, production date, expiry date | Repacks staging batch → new production batch in WH-A. Returns `batch_no` for label printing |
| **2. Bin Allocation** | Scans printed batch label, scans target LOT | Transfers stock from WH-A → LOT warehouse. Updates LOT contents |

The worker **must label the goods** between step 1 and step 2 — that's the whole point of the split.

---

## Screen Flow

All views below live within the existing **`grn_putaway`** PDT Screen (route: `/grn-putaway`).
No new PDT Screen record is needed — the two steps are sub-views navigated in-app.

```
PDT Screen: grn_putaway  (route: /grn-putaway)
═══════════════════════════════════════════════

┌─────────────────────────┐
│   GRN Put-Away (List)   │
│                         │
│  Shows pending RI lines │
│  (ready_for_allocation  │
│   & not completed)      │
│                         │
│  Tap a line ──────────► │
└─────────┬───────────────┘
          │
          ▼
┌─────────────────────────┐
│  RI Line Detail         │
│  (sub-view, same screen)│
│                         │
│  Item: P-POLYMER-001    │
│  Received: 100 KG       │
│  Batches Created: 40 KG │
│  Pending Batch: 60 KG   │
│  Allocated: 0 KG        │
│  Pending Alloc: 100 KG  │
│                         │
│  ┌───────────────────┐  │
│  │  Create Batch     │──┼──► Step 1 (action: create_batch)
│  └───────────────────┘  │
│  ┌───────────────────┐  │
│  │  Allocate to Bin  │──┼──► Step 2 (action: allocate_bin)
│  └───────────────────┘  │
│                         │
│  --- Created Batches --- │
│  BATCH-00457  40KG       │
│    Prod: 2026-01-15      │
│    Exp:  2027-01-15      │
│    In WH-A: 40 KG  ✓    │
│  BATCH-00458  35KG       │
│    Prod: 2026-03-01      │
│    ...                   │
└─────────────────────────┘
```

---

## Step 1 Screen — Create Batch

### Layout

```
┌──────────────────────────────┐
│  ← Create Batch              │
│                              │
│  Item: P-POLYMER-001         │
│  Staging Batch: BATCH-00456  │
│  Remaining: 60 KG            │
│                              │
│  ┌────────────────────────┐  │
│  │ Quantity          [60] │  │
│  └────────────────────────┘  │
│  ┌────────────────────────┐  │
│  │ Production Date  [📅]  │  │
│  └────────────────────────┘  │
│  ┌────────────────────────┐  │
│  │ Expiry Date      [📅]  │  │
│  └────────────────────────┘  │
│                              │
│  ┌────────────────────────┐  │
│  │    CREATE & PRINT      │  │
│  └────────────────────────┘  │
└──────────────────────────────┘
```

### API Call

```
POST /api/method/universal_mobile_api.api.grn.create_batch
```

**Request:**
```json
{
  "received_item_line": "RIL-P-POLYMER-001-0001",
  "qty": 40,
  "production_date": "2026-01-15",
  "expiry_date": "2027-01-15",
  "request_id": "uuid-unique-per-tap"
}
```

**Response:**
```json
{
  "ok": true,
  "data": {
    "batch_no": "BATCH-00457",
    "stock_entry": "STE-00123"
  }
}
```

### After Successful Response

1. **Show success dialog** with the `batch_no` prominently displayed
2. **Call `grn.print_label`** to send the label to the relay printer:
   ```json
   {
     "reference_doctype": "Batch",
     "reference_name": "<batch_no from response>",
     "print_format": "Batch Label"
   }
   ```
3. Show **"Label sent to printer"** toast
4. Worker collects the printed label and sticks it on the physical goods
5. **Navigate back** to the RI Line Detail screen (quantities refresh)
6. Worker can repeat step 1 for more qty of the same line (different dates)

### Validation Rules (Client-Side)

- `qty` must be > 0 and ≤ `pending_batch_qty` (from `list_pending` response)
- `production_date` is required (if not provided, default to today / GRN receipt date)
- `expiry_date` is optional
- `request_id` must be a UUID generated fresh per tap (idempotency)

---

## Step 2 Screen — Allocate to Bin

### Entry Point

Worker taps "Allocate to Bin" on the RI Line Detail screen, then:
1. Sees a list of created batches with available qty in WH-A (from `list_created_batches`)
2. Taps a batch OR scans the batch label barcode
3. Goes to the allocation form

### Layout

```
┌──────────────────────────────┐
│  ← Allocate to Bin           │
│                              │
│  Item: P-POLYMER-001         │
│  Batch: BATCH-00457          │
│  Prod: 2026-01-15            │
│  Available in WH-A: 40 KG    │
│                              │
│  ┌────────────────────────┐  │
│  │ Quantity          [40] │  │
│  └────────────────────────┘  │
│                              │
│  Suggested LOT:              │
│  ┌────────────────────────┐  │
│  │ F-CA-1                 │  │
│  │ Chemical WH, Aisle CA  │  │
│  │ Already holds item     │  │
│  │ (20 KG present,        │  │
│  │  80 KG free)           │  │
│  │           [USE THIS]   │  │
│  └────────────────────────┘  │
│                              │
│  ── OR scan a different bin ─│
│  ┌────────────────────────┐  │
│  │ 📷 Scan LOT Barcode    │  │
│  └────────────────────────┘  │
│                              │
│  ┌────────────────────────┐  │
│  │    ALLOCATE            │  │
│  └────────────────────────┘  │
│                              │
│  □ Force capacity override   │
│    (supervisor only)         │
└──────────────────────────────┘
```

### API Calls

**1. Get created batches for this line:**
```
POST /api/method/universal_mobile_api.api.grn.list_created_batches
```

**Request:**
```json
{
  "received_item_line": "RIL-P-POLYMER-001-0001"
}
```

**Response:**
```json
{
  "ok": true,
  "data": [
    {
      "batch_no": "BATCH-00457",
      "production_date": "2026-01-15",
      "expiry_date": "2027-01-15",
      "available_qty": 40.0
    },
    {
      "batch_no": "BATCH-00458",
      "production_date": "2026-03-01",
      "expiry_date": "2027-03-01",
      "available_qty": 35.0
    }
  ]
}
```

**2. Get LOT suggestion:**
```
POST /api/method/universal_mobile_api.api.grn.suggest_lot
```
(unchanged from before)

**3. Allocate:**
```
POST /api/method/universal_mobile_api.api.grn.allocate_to_bin
```

**Request:**
```json
{
  "received_item_line": "RIL-P-POLYMER-001-0001",
  "lot": "F-CA-1",
  "qty": 40,
  "batch_no": "BATCH-00457",
  "force_capacity": 0,
  "request_id": "uuid-unique-per-tap"
}
```

**Response:**
```json
{
  "ok": true,
  "data": {
    "stock_entry": "STE-00124",
    "lot": "F-CA-1",
    "qty": 40.0,
    "batch": "BATCH-00457"
  }
}
```

### After Successful Response

1. **Show success toast** — "40 KG allocated to F-CA-1"
2. Navigate back to RI Line Detail (quantities refresh)
3. If `pending_qty` = 0, the line shows as completed

### Validation Rules (Client-Side)

- `qty` must be > 0 and ≤ `available_qty` for the selected batch
- `qty` must be ≤ `pending_qty` on the RI line
- `batch_no` must be from the `list_created_batches` result (or scanned)
- `lot` must be a valid LOT (from suggestion or scanned barcode)

---

## Updated `list_pending` Response

The `list_pending` endpoint now returns extra fields for the two-step tracking:

```json
{
  "ok": true,
  "data": [
    {
      "name": "RIL-P-POLYMER-001-0001",
      "parent": "RI-MAT-REC-00001",
      "item_code": "P-POLYMER-001",
      "batch_no": "BATCH-00456",
      "received_qty": 100.0,
      "batch_qty_created": 40.0,
      "pending_batch_qty": 60.0,
      "bin_allocated_quantity": 0.0,
      "pending_qty": 100.0
    }
  ]
}
```

**New fields:**
| Field | Meaning |
|-------|---------|
| `batch_no` | Staging batch from the PR (used internally) |
| `batch_qty_created` | How much qty has been split into production batches (step 1 done) |
| `pending_batch_qty` | `received_qty - batch_qty_created` — how much still needs batch creation |

**Existing fields (unchanged):**
| Field | Meaning |
|-------|---------|
| `bin_allocated_quantity` | How much has been moved to LOTs (step 2 done) |
| `pending_qty` | `received_qty - bin_allocated_quantity` — how much still needs bin allocation |

---

## Label Printing — Server-Side Relay Architecture

The PDT **never talks to a printer directly** — no Bluetooth, no printer SDK, no local rendering.
All printing goes through ERPNext → relay agent → physical printer.

### How It Works

```
PDT (mobile)              ERPNext Server              Local Relay PC            Printer
────────────          ──────────────────          ─────────────────         ────────────
                                                  (warehouse LAN)
grn.create_batch()
  → returns batch_no
        │
grn.print_label() ────►  1. Renders label HTML
                            using Print Format
                            Designer template
                         2. Creates Universal
                            Print Job (Queued) ──►  print_agent.py polls
                                                    every 3 seconds
                         3. Returns {print_job}          │
                                                         ├─ Fetches job + content
                                                         ├─ Converts HTML → PDF
                                                         ├─ Sends to printer
                                                         │  (TCP:9100 or CUPS)
                                                         └─ Marks job → Sent
```

### Components

| Component | Where | What |
|-----------|-------|------|
| **Universal Printer** | ERPNext doctype (`universal` app) | Registers each printer: name, IP, port, type (ZPL/TSPL/PDF), location |
| **Universal Print Job** | ERPNext doctype (`universal` app) | Queue record: printer, print format, rendered content, status (Queued/Sent/Failed) |
| **Print Format** | ERPNext Print Format Designer | Label templates — designed in the desk UI, no code needed for new label types |
| **print_agent.py** | Python script on the local relay PC | Polls for Queued jobs, converts HTML→PDF, sends to printer, marks Sent/Failed |

### Label Templates (Print Format Designer)

Create label templates in ERPNext desk at **Print Format → New**:

| Template Name | DocType | Used For |
|--------------|---------|----------|
| `Batch Label` | Batch | GRN batch labels (step 1) |
| `LOT Label` | Warehouse LOT | Bin identification labels |
| `Pick Slip` | WMS Pick List | Pick list printout |

Each template is designed visually in the Print Format Designer — fields, barcodes,
layout — no code changes needed to add or modify label formats.

**Suggested Batch Label content:**
```
┌─────────────────────────┐
│  |||||||||||||||||||||||  │  ← Barcode (batch name)
│  BATCH-00457             │
│                          │
│  P-POLYMER-001           │
│  Polymer Grade A         │
│  Qty: 40 KG              │
│                          │
│  Prod: 2026-01-15        │
│  Exp:  2027-01-15        │
└─────────────────────────┘
```

### PDT Print API Call

After `create_batch` succeeds, the PDT calls `print_label` in a second request:

```
POST /api/method/universal_mobile_api.api.grn.print_label
```

**Request:**
```json
{
  "reference_doctype": "Batch",
  "reference_name": "BATCH-00457",
  "print_format": "Batch Label",
  "printer": "Label Printer - WH-A"
}
```

`printer` is optional — omit to use the default printer.

**Response:**
```json
{
  "ok": true,
  "data": {
    "print_job": "PJ-00012",
    "printer": "Label Printer - WH-A",
    "status": "Queued"
  }
}
```

The PDT shows **"Label sent to printer"** immediately (the relay agent delivers within seconds).

### Relay Agent Setup (One-Time, on the Local PC)

```bash
# Install on the warehouse PC (Windows/Linux/Mac — any OS with Python)
pip install requests weasyprint

# Create an API key in ERPNext for the agent user
# Then run:
python3 print_agent.py \
    --url https://your-erpnext.com \
    --api-key YOUR_KEY \
    --api-secret YOUR_SECRET \
    --poll-interval 3
```

The agent runs as a background service (systemd on Linux, Task Scheduler on Windows).
It picks up ALL print jobs system-wide — WMS labels, production labels, QC labels, etc.

### ERPNext Printer Registration

In ERPNext desk, go to **Universal Printer → New** for each physical printer:

| Field | Example |
|-------|---------|
| Printer Name | Label Printer - WH-A |
| Printer IP | 192.168.1.50 |
| Port | 9100 |
| Printer Type | ZPL |
| Location | Inbound Area |
| Default | ✓ |

### Key Points for the Mobile Team

1. **No printer code in the PDT app** — the app only calls `grn.print_label()`
2. **No Bluetooth pairing, no printer SDKs, no local rendering**
3. **The `printer` parameter is optional** — most workers use the default; supervisor can override
4. **Print job status is fire-and-forget** — the PDT doesn't poll for completion; label prints within 2-3 seconds via the relay
5. **New label types** require only a new Print Format in ERPNext desk — no app or API changes

---

## Error Codes

| Code | When | User Message |
|------|------|-------------|
| `NOT_READY_FOR_ALLOCATION` | Lab or finance not cleared | "This item hasn't been cleared yet. Lab/finance approval pending." |
| `OVER_PENDING_QTY` | Qty exceeds what's available | "Quantity exceeds the remaining amount." |
| `BIN_FULL` | Target LOT is at capacity | "This bin is full. Ask a supervisor to override." |
| `FORBIDDEN` | Missing role for the action | "You don't have permission for this action." |
| `VALIDATION` | Missing request_id | "Request ID is required." |

---

## Summary of API Endpoints (GRN Module)

| Endpoint | Purpose | Step |
|----------|---------|------|
| `grn.list_pending` | List RI lines ready for put-away | — |
| `grn.get` | Get full Received Item doc | — |
| `grn.create_batch` | **NEW** — Repack staging → production batch | 1 |
| `grn.print_label` | **NEW** — Send label to relay printer | 1 (after) |
| `grn.list_created_batches` | **NEW** — Batches in WH-A for a line | 2 (pre) |
| `grn.suggest_lot` | Suggest best LOT for put-away | 2 (pre) |
| `grn.allocate_to_bin` | **NEW** (replaces `put_away`) — Transfer to LOT | 2 |

The old `grn.put_away` endpoint is **removed** — replaced by the two-step flow.
The `grn.print_label` endpoint is generic — it works for any doctype/print format
and can be reused for other label types (LOT labels, pick slips, etc.).

---

## Typical Worker Workflow

1. Open GRN Put-Away screen → see pending lines
2. Tap a line (e.g., P-POLYMER-001, 100 KG)
3. Tap **Create Batch**
   - Enter: 40 KG, Prod 2026-01-15, Exp 2027-01-15
   - Tap CREATE & PRINT
   - App calls `grn.create_batch` → gets BATCH-00457
   - App calls `grn.print_label` → label prints on the nearby printer
   - Worker collects label, sticks it on the 40 KG pallet
4. Tap **Create Batch** again
   - Enter: 35 KG, Prod 2026-03-01, Exp 2027-03-01
   - CREATE & PRINT → BATCH-00458 label prints → stick on 35 KG pallet
5. Tap **Create Batch** again
   - Enter: 25 KG, Prod 2026-05-10, Exp 2027-05-10
   - CREATE & PRINT → BATCH-00459 label prints → stick on 25 KG pallet
6. Now all 100 KG has batches. Tap **Allocate to Bin**
   - See 3 batches listed. Tap BATCH-00457 (40 KG)
   - System suggests LOT F-CA-1 → tap USE THIS
   - Tap ALLOCATE → done, 40 KG moved
7. Tap **Allocate to Bin** again
   - Tap BATCH-00458 (35 KG) → scan LOT F-CA-2
   - ALLOCATE → done
8. Repeat for BATCH-00459 → line shows completed
