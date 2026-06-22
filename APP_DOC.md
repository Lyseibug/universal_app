# WMS Universal — Manual Testing Plan & App Documentation

## Table of Contents

1. [System Architecture Overview](#1-system-architecture-overview)
2. [Permission System](#2-permission-system)
3. [ERPNext Setup Prerequisites](#3-erpnext-setup-prerequisites)
4. [Module & Screen Reference](#4-module--screen-reference)
5. [Test Plan: Raw Material Reception Flow (End-to-End)](#5-test-plan-raw-material-reception-flow-end-to-end)
6. [Test Plan: GRN Put-Away (Detailed)](#6-test-plan-grn-put-away-detailed)
7. [Test Plan: Bin/LOT Browser (Detailed)](#7-test-plan-binlot-browser-detailed)
8. [Test Plan: Picking Flow](#8-test-plan-picking-flow)
9. [Test Plan: Manual Transfer](#9-test-plan-manual-transfer)
10. [Test Plan: Physical Inventory](#10-test-plan-physical-inventory)
11. [Test Plan: Offline / Write Queue](#11-test-plan-offline--write-queue)
12. [Test Plan: Edge Cases & Error Handling](#12-test-plan-edge-cases--error-handling)

---

## 1. System Architecture Overview

### Components

| Layer | Technology | Location |
|-------|-----------|----------|
| Mobile App | Flutter (Dart) | `universal_app/` |
| API Gateway | Python (Frappe whitelisted methods) | `apps/universal_mobile_api/` |
| Business Logic | Python (Frappe) | `apps/wms_universal/` |
| ERP Backend | ERPNext v16 (Frappe) | `apps/erpnext/` |
| Database | MariaDB | — |
| Printing | Relay Agent → Physical Printer | `apps/universal/` |

### Data Flow

```
Mobile App (Flutter)
  ↓ HTTP POST (Authorization: token <api_key:api_secret>)
API Gateway (universal_mobile_api)
  → Permission check (PDT Screen + Action roles)
  → Idempotency check (PDT Request Log)
  → Calls business logic (wms_universal)
    → Creates ERPNext documents (Stock Entry, Batch, etc.)
    → Updates WMS documents (Received Item Line, LOT Stock Line, etc.)
    → Writes Warehouse LOG (audit trail)
  ← Returns response envelope {ok: true, data: {...}}
```

### Key Doctypes

| Doctype | Purpose |
|---------|---------|
| **WMS Settings** | Global config: inbound warehouse, finance approver role, idle timeout |
| **PDT Module** | Menu module grouping (e.g., "Warehouse Management") |
| **PDT Screen** | Screen definition with role-based access |
| **PDT Screen Action** | Action within a screen (e.g., "create_batch", "allocate_bin") |
| **Received Item** | Header created on PR submit; tracks put-away status |
| **Received Item Line** | Per-item line with qty tracking and dual-gate approval |
| **Incoming Lab Test** | Lab test linked to each RI line |
| **Warehouse LOT** | Physical bin/location with capacity constraints |
| **LOT Stock Line** | Item+batch+qty within a LOT |
| **Warehouse LOG** | Audit trail for every WMS movement |
| **Worker Session** | Active PDT session (workspace + idle tracking) |
| **PDT Request Log** | Idempotency keys (request_id → cached response) |
| **Universal Printer** | Printer configuration (IP, port, type) |
| **Universal Print Job** | Print queue (Queued → Sent / Failed) |
| **WMS Pick List** | Batch picking request with items |
| **WMS Zone Preference** | Preferred LOTs per item for bin suggestion |

---

## 2. Permission System

### Three-Layer Model

```
Layer 1: SCREEN ACCESS
  User must have ANY role listed in PDT Screen → required_role child table
  → Controls which screens appear in the mobile menu

Layer 2: ACTION ACCESS
  Each PDT Screen Action can have its own required_role
  → Controls which buttons/actions are enabled in the screen UI
  → MenuScreen.can('action_key') returns true/false

Layer 3: DOCTYPE PERMISSION
  Optional permission_check field on action (format: "DOCTYPE:PERMISSION_TYPE")
  → Calls frappe.has_permission() at runtime
  → Example: "Stock Reconciliation:create"
```

### How Permissions Flow

1. **Login** → `session.login()` returns user roles
2. **Menu Fetch** → `session.get_menu()` filters modules/screens/actions by roles
3. **Screen Load** → Flutter only renders screens that exist in `screenRegistry` AND were returned by the menu
4. **Button Enable** → `widget.screen.can('action_key')` checks if action was in the menu response
5. **API Call** → `require_pdt('screen_key', 'action_key')` validates server-side before any operation

### Permission Verification Checklist

| Check | Where | How |
|-------|-------|-----|
| Screen visible in menu | Home Screen | Only screens matching user roles appear |
| Action button enabled | Feature Screen | `screen.can('action_key')` gates onPressed |
| API rejects unauthorized | Server | `require_pdt()` raises PermissionError |
| Cache invalidation | Server | Editing PDT Screen/Action clears config cache |

---

## 3. ERPNext Setup Prerequisites

Before testing the mobile app, the following must be configured in ERPNext:

### 3.1 WMS Settings (Single Document)

| Field | What to Set | Purpose |
|-------|-------------|---------|
| Inbound Warehouse | e.g., "WH-A Inbound/Outbound - URBM" | Where PR stock lands; source for batch creation |
| Finance Approver Role | e.g., "Accounts Manager" | Role required to click Approve Finance on PR |
| Default Output Warehouse | e.g., "Production - URBM" | Destination for picks |
| Idle Alert Minutes | e.g., 30 | Alert supervisor if worker idle |

### 3.2 Warehouses

| Warehouse | Purpose |
|-----------|---------|
| Inbound Warehouse (WH-A) | Receiving area — PR posts stock here |
| LOT Warehouses | One Frappe Warehouse per physical zone/area where LOTs exist |
| Output Warehouse | Destination for picks (production floor, etc.) |

### 3.3 Warehouse LOTs

Create `Warehouse LOT` documents for each physical bin:

| Field | Example |
|-------|---------|
| Name | LOT-A1-01 |
| Warehouse | Cold Store - URBM |
| Zone Name | Zone A |
| Aisle | A1 |
| Level | 01 |
| Max Weight KG | 1000 |
| Max Items | 10 |

### 3.4 Items

Ensure test items have:
- **Has Batch No** = Yes (required for batch-tracked items)
- **UPC Code** (custom field) = populated if you want UPC shown in app
- **Stock UOM** = set (e.g., Kg)
- **Weight Per Unit** = set (for LOT capacity checking)

### 3.5 PDT Configuration (Menu & Permissions)

#### PDT Modules
Create one or more PDT Module docs:
- `warehouse_management` — label: "WAREHOUSE MANAGEMENT"

#### PDT Screens
Create screens with required roles:

| Screen Key | Label | API Module | Required Roles |
|-----------|-------|------------|----------------|
| `grn_putaway` | GRN Put-Away | `grn` | WMS Worker, WMS Supervisor |
| `lot_browser` | Bin Browser | `lot` | WMS Supervisor |
| `manual_transfer` | Manual Transfer | `lot` | WMS Supervisor |
| `pick_list` | Picking | `pick` | WMS Worker, WMS Supervisor |
| `physical_inventory` | Physical Inventory | `physical_inventory` | WMS Supervisor |
| `support` | Support | `notifications` | WMS Worker, WMS Supervisor |

#### PDT Screen Actions (for grn_putaway)

| Action Key | Label | Required Role |
|-----------|-------|---------------|
| `create_batch` | Create Batch | WMS Worker |
| `allocate_bin` | Allocate to Bin | WMS Worker |
| `override_capacity` | Override Bin Capacity | WMS Supervisor |

### 3.6 Users & Roles

| User | Roles | Purpose |
|------|-------|---------|
| Worker user | WMS Worker | Can do put-away, picking |
| Supervisor user | WMS Supervisor, WMS Worker | Full access + overrides |
| Finance user | Accounts Manager (or configured role) | Can approve finance on PR |
| Lab user | (any with ILT access) | Can submit Incoming Lab Tests |

### 3.7 Supplier & Purchase Order

Create a Supplier and at minimum one Purchase Order with batch-tracked items to test the full receipt flow.

---

## 4. Module & Screen Reference

### Mobile App Screens

| Screen | Key | Views/Tabs | Write Operations |
|--------|-----|------------|------------------|
| **GRN Put-Away** | `grn_putaway` | List → Detail → Create Batch → Select Batch → Allocate Bin | create_batch, allocate_to_bin, print_label |
| **Bin Browser** | `lot_browser` | List (filterable, paginated) → Detail bottom sheet | read-only |
| **Manual Transfer** | `manual_transfer` | Single form (from/to/item/batch/qty) | transfer |
| **Picking** | `pick_list` | Tabs: Available / In Progress / Completed | claim, pick (submit) |
| **Physical Inventory** | `physical_inventory` | Start session → Count items → Submit | submit_counts |
| **Support** | `support` | Tabs: Chat / Ticket / Maintenance | sendChat, raiseSupport, raiseMaintenanceRequest |

### API Endpoints Quick Reference

| Endpoint | Method | Idempotent | Permission |
|----------|--------|------------|------------|
| `grn.list_pending` | Read | — | grn_putaway |
| `grn.create_batch` | Write | Yes | grn_putaway + create_batch |
| `grn.allocate_to_bin` | Write | Yes | grn_putaway + allocate_bin |
| `grn.list_created_batches` | Read | — | grn_putaway |
| `grn.suggest_lot` | Read | — | grn_putaway |
| `grn.print_label` | Write | — | grn_putaway |
| `lot.browse` | Read | — | lot_browser |
| `lot.get` | Read | — | lot_browser |
| `lot.transfer` | Write | Yes | manual_transfer + transfer |
| `pick.list` | Read | — | pick_list |
| `pick.claim` | Write | — | pick_list |
| `pick.submit` | Write | Yes | pick_list |
| `physical_inventory.start` | Read | — | physical_inventory |
| `physical_inventory.submit` | Write | Yes | physical_inventory |

---

## 5. Test Plan: Raw Material Reception Flow (End-to-End)

This is the complete flow from Purchase Order to goods sitting in a bin.

### Pre-conditions
- [ ] WMS Settings configured (inbound warehouse, finance approver role)
- [ ] At least 2 Warehouse LOTs created and not reserved
- [ ] Test item (e.g., 30100092) exists with Has Batch No = Yes, UPC Code set
- [ ] Supplier exists
- [ ] PDT screens and roles configured
- [ ] Mobile app logged in with a WMS Worker user

---

### PHASE 1: Purchase Order & Receipt (ERPNext Desktop)

#### TC-1.1: Create Purchase Order
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Go to Purchase Order → New | Form opens |
| 2 | Select Supplier, add item (e.g., 30100092), set qty (e.g., 347.4 Kg) | Item row populated |
| 3 | Submit PO | PO status = "To Receive and Bill" |

#### TC-1.2: Create Purchase Receipt from PO
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | From PO, click Create → Purchase Receipt | PR form opens with items from PO |
| 2 | Set Accepted Warehouse = Inbound Warehouse (WH-A) | Warehouse set |
| 3 | Verify batch is auto-assigned (v16 SBB) | Serial and Batch Bundle created |
| 4 | Submit PR | PR submitted successfully |
| 5 | Check: Received Item created | Navigate to Received Item list → new RI exists with status "In Review" |
| 6 | Check: Received Item Lines created | Each PR item has a corresponding RI line |
| 7 | Check: RI Line fields | `received_qty` matches PR qty, `ready_for_allocation = 0`, `lab_status = Pending` |
| 8 | Check: Incoming Lab Test created | One ILT per RI line, status = "Pending" |
| 9 | Check: Stock in WH-A | Stock Ledger shows item qty in inbound warehouse |
| 10 | Check: Batch captured on RI line | `batch_no` field populated (from PR's SBB) |

#### TC-1.3: Submit Lab Test (Pass)
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Open the Incoming Lab Test linked to the RI line | ILT form opens |
| 2 | Set status = "Pass", fill test parameters | Fields populated |
| 3 | Submit ILT | Status changes to "Pass" |
| 4 | Check RI Line | `lab_status = Passed` |
| 5 | Check RI Line `ready_for_allocation` | Still `0` (finance not yet approved) |

#### TC-1.4: Finance Approval
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Log in as Finance user (with finance_approver_role) | Logged in |
| 2 | Open the Purchase Receipt | PR form opens |
| 3 | Click "Approve Finance" button | Success message: "Finance approved... X line(s) ready for put-away" |
| 4 | Check PR fields | `custom_finance_status = Approved`, `custom_finance_approved_by` and `custom_finance_approved_on` set |
| 5 | Check RI Line | `ready_for_allocation = 1` (both gates passed) |

#### TC-1.5: Verify Landed Cost Voucher Block
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Create a Landed Cost Voucher referencing this PR | LCV form opens |
| 2 | Try to submit LCV | **Error**: "Cannot submit LCV: PR has already been finance-approved. Inventory cost is locked." |

---

### PHASE 2: GRN Put-Away (Mobile App)

#### TC-2.1: View Pending Items
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Open GRN Put-Away screen on mobile | Screen loads |
| 2 | Pull to refresh | List of pending items appears |
| 3 | Verify item card shows | `ItemCode (ItemName)`, GRN reference, warehouse, pending qty |
| 4 | Verify only ready lines shown | Only lines with `ready_for_allocation = 1` appear |

#### TC-2.2: Create First Batch
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Tap an item to open Detail view | Put-Away Details page loads |
| 2 | Verify metrics card | Received Qty, Batches Created (0), Pending Batch Split (full qty), Allocated (0), Pending Allocation (full qty) |
| 3 | Tap "Create Batch" | Create Batch form opens |
| 4 | Verify default qty | Pre-filled with pending batch qty |
| 5 | Enter qty (e.g., 180), select Production Date, optionally Expiry Date | Fields filled |
| 6 | Tap "CREATE & PRINT" | Success toast: "Batch XXXX created and sent to printer!" (or printer warning) |
| 7 | Verify return to Detail view | Metrics updated: Batches Created = 180, Pending Batch Split = remaining |
| 8 | Verify Production Batches list | New batch card appears with batch_no, production date, available qty = 180 |

#### TC-2.3: Create Second Batch (Remaining Qty)
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Tap "Create Batch" again | Form opens with remaining qty pre-filled |
| 2 | Accept the remaining qty, set dates | Fields filled |
| 3 | Tap "CREATE & PRINT" | Success — batch created |
| 4 | Verify metrics | Pending Batch Split = 0 |
| 5 | Verify "Create Batch" button | Disabled (pending batch qty = 0) |

#### TC-2.4: Allocate Batch to Bin
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Tap "Allocate to Bin" | Select Batch screen appears |
| 2 | Verify batch list | Only production batches shown (NOT the staging batch from PR) |
| 3 | Tap a batch (or scan its label) | Allocate Bin form opens |
| 4 | Verify item header | Shows `ItemCode (ItemName)`, batch_no, available qty |
| 5 | Verify lot suggestion card | Shows recommended bin with reason, zone, free capacity |
| 6 | Tap "Use Suggested Bin" (or scan a bin barcode) | LOT field populated |
| 7 | Enter qty (default = batch available qty) | Qty field filled |
| 8 | Tap "ALLOCATE" | Success toast: "X allocated to LOT-XXX successful!" |
| 9 | Verify return | If line still has pending qty → Detail view. If fully allocated → List view |

#### TC-2.5: Verify in ERPNext After Allocation
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Check Stock Entry list | Two Stock Entries: Repack (batch creation) + Material Transfer (allocation) |
| 2 | Check Warehouse LOT | LOT Stock Line added with item, batch, qty, production_date, expiry_date |
| 3 | Check Warehouse LOG | Two entries: "Batch Creation" + "Bin Allocation" |
| 4 | Check Received Item Line | `bin_allocated_quantity` updated, `pending_qty` reduced |
| 5 | If fully allocated: Check Received Item | `status = Completed`, `is_completed = 1` |

---

### PHASE 3: Verification in Bin Browser (Mobile App)

#### TC-3.1: View Allocated Stock
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Open Bin Browser screen | LOT list loads |
| 2 | Verify the target LOT shows as "Occupied" | Status badge = "Occupied" (not "Empty") |
| 3 | Tap the LOT | Detail bottom sheet opens |
| 4 | Verify item card | Shows `ItemCode (ItemName)`, UPC code, Batch, Production Date, Expiry Date, Qty |

---

## 6. Test Plan: GRN Put-Away (Detailed)

### Batch Creation Tests

#### TC-6.1: Partial Batch Creation
| Step | Action | Expected |
|------|--------|----------|
| 1 | Create batch with qty less than received | Success, remaining qty shown |
| 2 | Create another batch with another partial qty | Success, remaining further reduced |
| 3 | Create final batch with exact remaining qty | Success, pending batch = 0, Create Batch button disabled |

#### TC-6.2: Floating-Point Qty Edge Case
| Step | Action | Expected |
|------|--------|----------|
| 1 | Receive 347.4 Kg | RI line created |
| 2 | Create batch 180 Kg | Pending = 167.4 |
| 3 | Create batch 60 Kg | Pending = 107.4 |
| 4 | Create batch 107.4 Kg (the exact remainder) | **Must succeed** — no OVER_PENDING_QTY error |

#### TC-6.3: Over-Qty Validation
| Step | Action | Expected |
|------|--------|----------|
| 1 | Try to create batch with qty > pending | Client-side error: "Please enter a valid quantity between 0 and X" |
| 2 | Bypass client (API call with excess qty) | Server error: OVER_PENDING_QTY |

#### TC-6.4: Production Date Defaults
| Step | Action | Expected |
|------|--------|----------|
| 1 | Open Create Batch form | Production Date pre-filled with receipt_date |
| 2 | Expiry Date field | Empty (optional) |

#### TC-6.5: Multiple PRs for Same Item
| Step | Action | Expected |
|------|--------|----------|
| 1 | Submit two PRs for the same item (e.g., 30100092) | Two RI lines created, each linked to its own PR |
| 2 | Create batch from RI line #1 | Uses staging batch from PR #1 (not PR #2's batch) |
| 3 | Create batch from RI line #2 | Uses staging batch from PR #2 |
| 4 | Check Production Batches list for each line | Only shows batches created for that item (via Repack), not staging batches |

### Bin Allocation Tests

#### TC-6.6: Bin Suggestion
| Step | Action | Expected |
|------|--------|----------|
| 1 | Navigate to Allocate Bin | Suggestion card loads (or shows "no suggestion") |
| 2 | If WMS Zone Preference exists for item | Preferred LOT suggested first |
| 3 | Tap "Use Suggested Bin" | LOT field auto-filled, focus moves to qty |

#### TC-6.7: Bin Capacity Check
| Step | Action | Expected |
|------|--------|----------|
| 1 | Allocate to a LOT that is at max_weight_kg | Error: "BIN_FULL" |
| 2 | If user has `override_capacity` action | Override prompt appears, can force-allocate |
| 3 | If user does NOT have `override_capacity` | Error displayed, cannot proceed |

#### TC-6.8: Allocate to Multiple Bins
| Step | Action | Expected |
|------|--------|----------|
| 1 | Create batch 200 Kg | Available = 200 |
| 2 | Allocate 100 Kg to LOT-A | Success, available = 100 |
| 3 | Allocate 100 Kg to LOT-B | Success, available = 0 |
| 4 | Batch should no longer appear in select list | Batch gone (available_qty = 0) |

#### TC-6.9: Scan Batch Label (Select Batch View)
| Step | Action | Expected |
|------|--------|----------|
| 1 | On Select Batch screen, scan a batch barcode | If batch found → navigates directly to Allocate Bin |
| 2 | Scan an unknown barcode | Error snackbar: "Batch XXX not found in WH-A for this line" |

### Permission Tests

#### TC-6.10: Worker Without create_batch Action
| Step | Action | Expected |
|------|--------|----------|
| 1 | Remove `create_batch` action from worker's PDT Screen config | Config updated |
| 2 | Log in as worker, open GRN Put-Away detail | "Create Batch" button is disabled |

#### TC-6.11: Worker Without allocate_bin Action
| Step | Action | Expected |
|------|--------|----------|
| 1 | Remove `allocate_bin` action | Config updated |
| 2 | Open detail view | "Allocate to Bin" button is disabled, batch list items not tappable |

---

## 7. Test Plan: Bin/LOT Browser (Detailed)

### List View Tests

#### TC-7.1: Default View (Occupied Only)
| Step | Action | Expected |
|------|--------|----------|
| 1 | Open Bin Browser | List loads with LOTs marked "Occupied" |
| 2 | Verify "Show Occupied Lots Only" checkbox | Checked by default |
| 3 | Empty LOTs should NOT appear | Only LOTs with `is_empty = 0` shown |

#### TC-7.2: Show All LOTs
| Step | Action | Expected |
|------|--------|----------|
| 1 | Open filter panel (filter icon) | Filter panel expands |
| 2 | Uncheck "Show Occupied Lots Only" | Checkbox unchecked |
| 3 | Tap "Apply Filters" | List reloads showing both Empty and Occupied LOTs |
| 4 | Verify Empty LOTs show "Empty" status | Status badge = "Empty" |
| 5 | Verify Occupied LOTs show "Occupied" status | Status badge = "Occupied" |

#### TC-7.3: Filter by Warehouse
| Step | Action | Expected |
|------|--------|----------|
| 1 | Enter warehouse name in Warehouse filter | Text entered |
| 2 | Tap "Apply Filters" | Only LOTs in that warehouse shown |

#### TC-7.4: Filter by Zone
| Step | Action | Expected |
|------|--------|----------|
| 1 | Enter zone name in Zone filter | Text entered |
| 2 | Apply | Only LOTs in that zone shown |

#### TC-7.5: Filter by Item Code
| Step | Action | Expected |
|------|--------|----------|
| 1 | Enter item code in Item Code filter | Text entered |
| 2 | Apply | Only LOTs containing that item shown |
| 3 | If no LOTs contain item | "No Bins Found" empty state |

#### TC-7.6: Reset Filters
| Step | Action | Expected |
|------|--------|----------|
| 1 | Set various filters and apply | Filtered results shown |
| 2 | Tap "Reset" | All filters cleared, checkbox back to checked |
| 3 | List reloads with default view | Occupied LOTs shown |

#### TC-7.7: Infinite Scroll / Pagination
| Step | Action | Expected |
|------|--------|----------|
| 1 | Have > 50 LOTs | First page loads (50 items) |
| 2 | Scroll to bottom | Loading spinner appears, next page loads |
| 3 | Continue scrolling | Pages load until all LOTs shown |

#### TC-7.8: Pull to Refresh
| Step | Action | Expected |
|------|--------|----------|
| 1 | Pull down on list | Refresh indicator appears |
| 2 | Release | List reloads from start |

### Detail View Tests

#### TC-7.9: View LOT Contents
| Step | Action | Expected |
|------|--------|----------|
| 1 | Tap an Occupied LOT | Bottom sheet opens |
| 2 | Verify header | "Bin: LOT-XXX", Warehouse, Zone |
| 3 | Verify item cards show | Item Code (Item Name), UPC code, Batch, Production Date, Expiry Date, Qty |

#### TC-7.10: Empty LOT Detail
| Step | Action | Expected |
|------|--------|----------|
| 1 | Tap an Empty LOT | Bottom sheet opens |
| 2 | Verify | "No items in this location" message |

#### TC-7.11: LOT with Multiple Items
| Step | Action | Expected |
|------|--------|----------|
| 1 | Allocate different items/batches to same LOT | Multiple allocations done |
| 2 | Open LOT in Bin Browser | All items listed with individual cards |
| 3 | Each card shows correct batch, dates, qty | Data matches what was allocated |

---

## 8. Test Plan: Picking Flow

#### TC-8.1: View Available Picks
| Step | Action | Expected |
|------|--------|----------|
| 1 | Create WMS Pick List with items in ERPNext | Pick list created |
| 2 | Open Pick List screen, "Available" tab | Items with status "Pending" shown |

#### TC-8.2: Claim a Pick
| Step | Action | Expected |
|------|--------|----------|
| 1 | Tap an available pick item | Item details shown |
| 2 | Tap "Claim" | Item moves to "In Progress" tab, assigned to current user |

#### TC-8.3: Submit Pick
| Step | Action | Expected |
|------|--------|----------|
| 1 | On claimed item, scan/enter actual LOT | LOT field populated |
| 2 | Enter picked qty | Qty field filled |
| 3 | Tap Submit | Success — Stock Entry created (Material Transfer LOT → output WH) |
| 4 | Verify LOT Stock Line | Qty reduced (or line removed if qty = 0) |
| 5 | Verify Warehouse LOG | "Pick Out" entry created |

#### TC-8.4: FIFO Enforcement
| Step | Action | Expected |
|------|--------|----------|
| 1 | LOT has batches with different production dates | Multiple batches in LOT |
| 2 | Pick from this LOT | System selects oldest batch (by production_date) |

---

## 9. Test Plan: Manual Transfer

#### TC-9.1: Transfer Between Bins
| Step | Action | Expected |
|------|--------|----------|
| 1 | Open Manual Transfer screen | Form shown |
| 2 | Scan/enter From LOT, To LOT, Item, Batch, Qty | Fields filled |
| 3 | Submit | Success — Stock Entry created |
| 4 | Verify source LOT | Qty reduced |
| 5 | Verify destination LOT | Qty increased (or new LOT Stock Line) |
| 6 | Verify Warehouse LOG | "Transfer" entry |

#### TC-9.2: Transfer to Full Bin
| Step | Action | Expected |
|------|--------|----------|
| 1 | Try to transfer to a LOT at max capacity | Error: BIN_FULL |

#### TC-9.3: Transfer Same Source and Destination
| Step | Action | Expected |
|------|--------|----------|
| 1 | Enter same LOT for both From and To | Error: "Source and destination bins are the same" |

---

## 10. Test Plan: Physical Inventory

#### TC-10.1: Start Count Session
| Step | Action | Expected |
|------|--------|----------|
| 1 | Open Physical Inventory, scan/select LOT | Session starts, system qty loaded |
| 2 | Verify listed items | Shows all items/batches in LOT with system_qty |

#### TC-10.2: Submit Matching Counts
| Step | Action | Expected |
|------|--------|----------|
| 1 | Enter counted_qty = system_qty for all items | All match |
| 2 | Submit | Success — no Stock Reconciliation created (no difference) |

#### TC-10.3: Submit with Differences
| Step | Action | Expected |
|------|--------|----------|
| 1 | Enter counted_qty different from system_qty | Difference highlighted |
| 2 | Submit | Stock Reconciliation created for adjustments |
| 3 | Verify LOT Stock Line | Quantities updated to match counted values |
| 4 | Verify Warehouse LOG | "Physical Count" entry |

---

## 11. Test Plan: Offline / Write Queue

#### TC-11.1: Create Batch While Offline
| Step | Action | Expected |
|------|--------|----------|
| 1 | Disconnect device from network | No internet |
| 2 | Fill Create Batch form and submit | Entry queued (write queue badge shows 1 pending) |
| 3 | Error message shown | "Network error" or similar |
| 4 | Reconnect to network | Write queue auto-flushes |
| 5 | Verify batch created on server | Batch exists, Stock Entry posted |

#### TC-11.2: Duplicate Request (Idempotency)
| Step | Action | Expected |
|------|--------|----------|
| 1 | Submit an allocation | Success (request_id stored in PDT Request Log) |
| 2 | Force retry same request_id (via write queue manual flush) | Server returns cached response (DUPLICATE_REQUEST treated as success) |
| 3 | Verify no duplicate Stock Entry | Only one Stock Entry created |

#### TC-11.3: Write Queue Badge
| Step | Action | Expected |
|------|--------|----------|
| 1 | Queue multiple operations offline | Badge shows count of pending entries |
| 2 | Tap the badge | Flush triggered |
| 3 | All entries sync | Badge disappears |

---

## 12. Test Plan: Edge Cases & Error Handling

#### TC-12.1: Session Expiry
| Step | Action | Expected |
|------|--------|----------|
| 1 | Let session expire (or invalidate token on server) | — |
| 2 | Try any API call | App redirects to Login screen with session expired message |

#### TC-12.2: Concurrent Users on Same Item
| Step | Action | Expected |
|------|--------|----------|
| 1 | Two workers open the same RI line | Both see it |
| 2 | Worker A creates batch (100 Kg) | Success |
| 3 | Worker B tries to create batch with full qty | Server error: OVER_PENDING_QTY (qty was reduced by Worker A) |
| 4 | Worker B refreshes | Updated pending qty shown |

#### TC-12.3: Item Not in Inbound Warehouse
| Step | Action | Expected |
|------|--------|----------|
| 1 | PR accepted to a different warehouse than WMS Settings inbound | Stock lands elsewhere |
| 2 | Try to create batch | System falls back to PR item's warehouse via `_resolve_source_warehouse` |

#### TC-12.4: Lab Test Fails
| Step | Action | Expected |
|------|--------|----------|
| 1 | Submit ILT with status = "Fail" | ILT submitted |
| 2 | Check RI Line | `lab_status = Rejected/Failed` |
| 3 | Open GRN Put-Away on mobile | This line does NOT appear (ready_for_allocation = 0) |

#### TC-12.5: Finance Not Approved
| Step | Action | Expected |
|------|--------|----------|
| 1 | Lab test passes but finance NOT approved | `lab_status = Passed`, `ready_for_allocation = 0` |
| 2 | Open GRN Put-Away | Line does NOT appear |
| 3 | Approve finance | Line appears in app |

#### TC-12.6: Print Label Without Printer Configured
| Step | Action | Expected |
|------|--------|----------|
| 1 | No Universal Printer configured with is_default = 1 | — |
| 2 | Create batch (triggers print) | Batch created successfully, but toast shows: "Batch created, but printing failed: No printer specified..." |
| 3 | Batch is still usable | Worker can proceed to allocation |

#### TC-12.7: Button Overflow on Small Screens
| Step | Action | Expected |
|------|--------|----------|
| 1 | Open Detail view on a narrow screen device | — |
| 2 | Check "Create Batch" and "Allocate to Bin" buttons | Text truncates with ellipsis, NO right overflow |

---

## Appendix: ERPNext → Mobile App Test Sequence (Quick Reference)

```
ERPNext Desktop:
  1. Create Purchase Order
  2. Create Purchase Receipt (Submit)
     → Auto-creates: Received Item, RI Lines, Incoming Lab Tests
  3. Submit Lab Test (Pass)
  4. Approve Finance on PR

Mobile App:
  5. GRN Put-Away → View pending items
  6. Select item → Create Batch(es)
  7. Select batch → Allocate to Bin
  8. Bin Browser → Verify stock in LOT

Verification (ERPNext):
  9. Check Stock Entries (Repack + Material Transfer)
  10. Check Warehouse LOT contents
  11. Check Warehouse LOG entries
  12. Check Received Item status = Completed (if fully allocated)
```
