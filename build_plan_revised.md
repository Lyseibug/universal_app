# PDT Mobile Application — Flutter Development Guide
## UNIVERSAL Production Management System

**Date:** June 2026  
**Backend:** ERPNext v16 + universal_mobile_api (Frappe whitelisted REST)  
**Platform:** Android only (physical PDT handhelds + worker smartphones)  
**Authentication:** Frappe API Key:Secret token (Basic Auth header)

---

## Table of Contents

1. [Project Setup & Architecture](#1-project-setup--architecture)
2. [Backend API Contract](#2-backend-api-contract)
3. [Authentication & Session Flow](#3-authentication--session-flow)
4. [Navigation & Menu Architecture](#4-navigation--menu-architecture)
5. [Module: Warehouse — GRN Put-Away](#5-module-warehouse--grn-put-away)
6. [Module: Warehouse — FIFO Pick List](#6-module-warehouse--fifo-pick-list)
7. [Module: Warehouse — Physical Inventory](#7-module-warehouse--physical-inventory)
8. [Module: Warehouse — LOT Browser & Manual Transfer](#8-module-warehouse--lot-browser--manual-transfer)
9. [Module: Line 1 — Funnel/Bag Transfer & Calendering](#9-module-line-1--funnelbag-transfer--calendering)
10. [Module: Line 2 — Building Flowchart](#10-module-line-2--building-flowchart)
11. [Module: QC](#11-module-qc)
12. [Module: Packing & Palletisation](#12-module-packing--palletisation)
13. [Notifications (FCM/OneSignal)](#13-notifications-fcmonesignal)
14. [Barcode Scanning](#14-barcode-scanning)
15. [Offline & Idempotency](#15-offline--idempotency)
16. [State Management (Riverpod)](#16-state-management-riverpod)
17. [Shared UI Components](#17-shared-ui-components)
18. [Error Handling](#18-error-handling)
19. [Testing Strategy](#19-testing-strategy)
20. [Build & Release](#20-build--release)

---

## 1. Project Setup & Architecture

### 1.1 Flutter SDK & Dependencies

```yaml
# pubspec.yaml
name: universal_pdt
description: Universal Production Management PDT App

environment:
  sdk: '>=3.3.0 <4.0.0'
  flutter: '>=3.22.0'

dependencies:
  flutter:
    sdk: flutter

  # State management
  flutter_riverpod: ^2.5.0
  riverpod_annotation: ^2.3.0

  # Networking
  dio: ^5.4.0
  pretty_dio_logger: ^1.3.1

  # Local storage
  flutter_secure_storage: ^9.0.0     # API token
  shared_preferences: ^2.2.3         # settings, last workspace
  hive_flutter: ^1.1.0               # offline queue

  # Barcode scanning
  mobile_scanner: ^5.1.0             # camera-based scan
  flutter_bluetooth_serial: ^0.4.0   # Zebra/Honeywell BT scanner

  # Notifications
  onesignal_flutter: ^5.1.6

  # UI
  go_router: ^13.2.0
  google_fonts: ^6.2.0
  flutter_hooks: ^0.20.5

  # Utilities
  uuid: ^4.3.3
  intl: ^0.19.0
  freezed_annotation: ^2.4.1
  json_annotation: ^4.9.0
  image_picker: ^1.1.0               # flowchart photo upload (QC)

dev_dependencies:
  build_runner: ^2.4.9
  freezed: ^2.4.7
  json_serializable: ^6.8.0
  riverpod_generator: ^2.4.0
  flutter_lints: ^4.0.0
  mocktail: ^1.0.3
  integration_test:
    sdk: flutter
```

### 1.2 Folder Structure

```
lib/
├── main.dart
├── app.dart                        # MaterialApp + GoRouter + ProviderScope
│
├── core/
│   ├── api/
│   │   ├── api_client.dart         # Dio singleton, auth header, error mapping
│   │   ├── api_response.dart       # { ok, data } / { error, code, message } envelope
│   │   └── endpoints.dart          # all URL constants
│   ├── auth/
│   │   ├── auth_repository.dart    # login, logout, token storage
│   │   └── auth_state.dart         # Riverpod auth provider
│   ├── session/
│   │   ├── session_repository.dart # workspace select, menu fetch
│   │   └── session_state.dart
│   ├── scanner/
│   │   ├── scanner_service.dart    # unified camera + BT scanner
│   │   └── scan_result.dart
│   ├── notifications/
│   │   ├── notification_service.dart   # OneSignal init, player ID reg
│   │   └── notification_state.dart
│   ├── offline/
│   │   ├── idempotency.dart        # UUID v4 request_id generation + local cache
│   │   └── offline_queue.dart      # Hive-backed retry queue
│   └── theme/
│       └── app_theme.dart
│
├── features/
│   ├── grn/                        # GRN Put-Away
│   ├── pick/                       # FIFO Pick List
│   ├── physical_inventory/         # Physical Inventory
│   ├── lot/                        # LOT Browser + Manual Transfer
│   ├── line1/                      # Funnel, Calendering, Cutting
│   ├── line2/                      # Sleeve Building, Curing, Grinding, Labelling
│   ├── qc/                         # QC Measurement + QC Final
│   ├── packing/                    # Box + Pallet
│   └── support/                    # Chat, Raise Issue, Maintenance
│
└── shared/
    ├── widgets/
    │   ├── pdt_scaffold.dart       # App bar + scanner FAB + support drawer
    │   ├── scan_input_field.dart   # text field + scan icon
    │   ├── lot_card.dart
    │   ├── status_chip.dart
    │   ├── qty_stepper.dart
    │   ├── confirm_bottom_sheet.dart
    │   └── error_snack.dart
    └── models/                     # shared freezed DTOs
```

### 1.3 Architecture Principles

- **Repository pattern**: each feature has its own Repository class that calls the API. Riverpod providers depend on repositories, never on Dio directly.
- **Offline-first for writes**: every write call that has a `request_id` parameter goes through `idempotency.dart`, which generates a UUID, stores it locally, and retries on failure.
- **Read-only calls are always online**: no offline caching of LOT contents — the data changes too fast.
- **One screen = one `AsyncNotifier`**: each screen has a dedicated Riverpod notifier that owns its loading/error state.

---

## 2. Backend API Contract

### 2.1 Base URL & Auth

```
Base:  https://<erp-host>/api/method/universal_mobile_api.api
Auth:  Authorization: token <api_key>:<api_secret>
       Content-Type: application/json
```

All responses are wrapped:
```json
// Success
{ "ok": true, "data": <payload> }

// Failure (4xx)
{ "error": true, "code": "BIN_FULL", "message": "LOT B-AA-1 is full" }
```

### 2.2 Complete Endpoint List

| Module | Method | Endpoint | Notes |
|---|---|---|---|
| **Session** | POST | `session.login` | `usr`, `pwd` → `token`, `employee`, `roles` |
| | GET | `session.list_workspaces` | Active assignments for logged-in worker |
| | POST | `session.select_workspace` | `assignment` → creates Worker Session |
| | GET | `session.get_menu` | Role-filtered module/screen/action tree |
| | POST | `session.logout` | Closes Worker Session |
| **GRN** | GET | `grn.list_pending` | Received Item Lines with `ready_for_allocation=1` |
| | GET | `grn.get` | `received_item` → full doc |
| | GET | `grn.suggest_lot` | `received_item_line`, `qty` → `{ lot, reason, warehouse, zone, aisle, level }` |
| | POST | `grn.put_away` | `received_item_line`, `lot`, `qty`, `production_date`, `expiry_date`, `force_capacity`, `request_id` |
| **Pick** | GET | `pick.list` | `material_request?`, `status?` |
| | POST | `pick.claim` | `pick_item` |
| | POST | `pick.submit` | `pick_item`, `actual_lot`, `picked_qty`, `request_id` |
| **Physical Inventory** | GET | `physical_inventory.start` | `lot` → lines with system_qty |
| | POST | `physical_inventory.submit` | `lot`, `counts` (JSON), `request_id` |
| **LOT** | GET | `lot.browse` | `warehouse?`, `zone?`, `item?`, `only_occupied?`, `limit`, `start` |
| | GET | `lot.get` | `lot` → full bin doc with contents |
| | POST | `lot.transfer` | `from_lot`, `to_lot`, `item`, `batch_no`, `qty`, `request_id` |
| **Notifications** | POST | `notifications.register_device` | `player_id` |
| | POST | `notifications.chat` | `message`, `recipient?` |
| | POST | `notifications.raise_support` | `support_type`, `payload?` |
| | POST | `notifications.maintenance_request` | `equipment`, `issue_type`, `description`, `urgency` |
| | GET | `notifications.get_notifications` | `limit`, `start` |
| | POST | `notifications.mark_read` | `notification_id` or `mark_all=true` |
| **App Update** | GET | `app_update.check` | Returns `{ latest_version, download_url, force_update }` |

---

## 3. Authentication & Session Flow

### 3.1 Login Screen

```dart
// features/auth/login_screen.dart
// Fields: Employee ID (or username), Password
// On submit → api/session.login
// Store token in FlutterSecureStorage
// Store employee_id and roles in memory (session state)
```

**Flow:**
1. Worker enters Employee code (e.g. `EMP-0042`) — API maps this to the User internally.
2. On success: store `api_key:api_secret` token in secure storage.
3. After login: call `notifications.register_device(player_id)` with the OneSignal player ID.
4. Navigate to Workspace Setup screen.

### 3.2 Workspace Setup Screen

```dart
// features/session/workspace_setup_screen.dart
// Shows list of Worker Workstation Assignments
// Worker selects their workspace for this shift
// Calls session.select_workspace(assignment)
// Then calls session.get_menu() → drives bottom nav / drawer
```

**UI:** Cards per assignment showing `workstation` + `workspace` code. If only one assignment, auto-select.

### 3.3 Token Refresh

Frappe API key/secret tokens do not expire by default. The login endpoint regenerates the `api_secret` on each login. Store once and reuse until explicit logout.

If a `401 UNAUTHENTICATED` response is received, clear stored token and redirect to login.

---

## 4. Navigation & Menu Architecture

### 4.1 Dynamic Menu from API

`session.get_menu()` returns a structure driven by PDT Module + PDT Screen doctypes:

```json
{
  "menu": [
    {
      "module_key": "warehouse",
      "label": "Warehouse",
      "icon": "warehouse",
      "screens": [
        { "screen_key": "grn_putaway", "label": "GRN Put-Away", "route": "/grn", "actions": ["put_away", "override_capacity"] },
        { "screen_key": "pick_list",   "label": "Pick List",     "route": "/pick" },
        ...
      ]
    },
    { "module_key": "line1", ... },
    { "module_key": "line2", ... }
  ]
}
```

### 4.2 Router Setup (GoRouter)

```dart
// core/router.dart
final router = GoRouter(
  routes: [
    GoRoute(path: '/login',     builder: (_, __) => const LoginScreen()),
    GoRoute(path: '/workspace', builder: (_, __) => const WorkspaceSetupScreen()),
    GoRoute(path: '/home',      builder: (_, __) => const HomeScreen()),
    GoRoute(path: '/grn',       builder: (_, __) => const GrnScreen()),
    GoRoute(path: '/pick',      builder: (_, __) => const PickListScreen()),
    GoRoute(path: '/physical-inventory', builder: (_, __) => const PhysicalInventoryScreen()),
    GoRoute(path: '/lot-browser',  builder: (_, __) => const LotBrowserScreen()),
    GoRoute(path: '/lot-transfer', builder: (_, __) => const ManualTransferScreen()),
    GoRoute(path: '/line1/funnel', builder: (_, __) => const FunnelScreen()),
    GoRoute(path: '/line1/calendering', builder: (_, __) => const CalenderingScreen()),
    GoRoute(path: '/line1/cutting', builder: (_, __) => const CuttingScreen()),
    GoRoute(path: '/line2/building', builder: (_, __) => const BuildingScreen()),
    GoRoute(path: '/line2/curing',   builder: (_, __) => const CuringScreen()),
    GoRoute(path: '/line2/grinding', builder: (_, __) => const GrindingScreen()),
    GoRoute(path: '/line2/labelling', builder: (_, __) => const LabellingScreen()),
    GoRoute(path: '/qc',         builder: (_, __) => const QcScreen()),
    GoRoute(path: '/packing',    builder: (_, __) => const PackingScreen()),
    GoRoute(path: '/support',    builder: (_, __) => const SupportScreen()),
  ],
  redirect: (context, state) {
    final isLoggedIn = ref.read(authProvider).isAuthenticated;
    if (!isLoggedIn && state.matchedLocation != '/login') return '/login';
    return null;
  },
);
```

### 4.3 Home Screen

Renders the dynamic menu as a grid of module tiles. Tapping a module shows its screens. Only shows screens the worker's role has access to (the server already filters `get_menu()`).

---

## 5. Module: Warehouse — GRN Put-Away

**PDT Screen key:** `grn_putaway`  
**Roles:** WMS Receiver

### 5.1 How Items Become Allocatable

Items arrive in **WH-A (Inbound/Outbound - URBM)** via the native Purchase Receipt stock posting. WH-I Quarantine is for production holds only — not part of receiving.

```
Purchase Receipt submitted in ERPNext → stock lands in WH-A (native)
  └─► hook fires in a single transaction:
       Received Item created (status = "In Review")
       One Incoming Lab Test created per item line (linked to that line)
       No extra Stock Entry needed.

[Parallel — lab and finance run independently]

LAB (per item line):
  Lab tech opens their auto-created ILT, enters Pass / Fail, submits
  └─► hook: Received Item Line.lab_status = Passed/Rejected
       If PR.finance_status = Approved → ready_for_allocation = 1

FINANCE (one action covers the whole GRN):
  Finance Approver opens the Purchase Receipt in ERPNext
  Clicks [Approve Finance] button
  └─► PR.finance_status = Approved (cost is now locked — LCV blocked)
       All lines where lab_status = Passed → ready_for_allocation = 1

When BOTH gates pass for a line → ready_for_allocation = 1
PDT list_pending() returns that line → worker allocates to a bin
put_away Stock Entry: WH-A → home LOT's warehouse
```

### 5.2 Screen Flow

```
Pending List → Tap Item Line → Suggestion Card → Put-Away Dialog → Confirm
```

**Step 1 — Pending List (`grn.list_pending`)**
- Calls `grn.list_pending()` on screen load
- Shows lines where `ready_for_allocation = 1` and `is_line_completed = 0`
- Each row: Item code, GRN reference, pending qty
- Pull-to-refresh

**Step 2 — Tap a line → Suggestion + Put-Away Dialog**

On tap, immediately call `grn.suggest_lot(line.name, line.pendingQty)` in parallel with opening the dialog.

The dialog shows:

```
┌─────────────────────────────────────────┐
│ rubber-001                              │
│ Pending: 150 KG                         │
│                                         │
│ Suggested Bin                           │
│ ┌─────────────────────────────────┐     │
│ │  B-CD-1  · Cord & Fabrics       │     │
│ │  "Already holds rubber-001      │     │
│ │   (80 KG present, 70 KG free)"  │     │
│ └─────────────────────────────────┘     │
│ [Use Suggested Bin]  [Scan Different]   │
│                                         │
│ Qty: [ 70.000 ] KG    ▲ ▼              │
│ Production Date: [ 2026-01-15 ]  📅     │
│ Expiry Date:     [ optional   ]  📅     │
│                                         │
│ [Confirm Put-Away]                      │
└─────────────────────────────────────────┘
```

- If suggestion returns `lot: null` → no suggestion card shown; scan field is empty
- "Use Suggested Bin" auto-fills the scan field with the suggestion
- "Scan Different" opens the scanner overlay
- Qty defaults to `min(pending_qty, suggested_available_kg)` — worker adjusts if partial
- Production Date: optional; defaults to receipt date on the backend if omitted
- Expiry Date: optional
- Supervisor "Force Capacity" toggle only visible if worker has `override_capacity` action

**Step 3 — Confirm → `grn.put_away`**
- Generate `request_id = uuid_v4()` locally before submitting
- Show loading → success snackbar with Stock Entry number
- On success: decrement pending qty shown inline (no full reload needed)
- If `BIN_FULL` error returned and worker is supervisor → show "Force Capacity" toggle

### 5.3 Key Widgets

```dart
// Suggestion card — shown while dialog loads, updated when suggest_lot returns
SuggestionCard(
  isLoading: state.isSuggesting,
  suggestion: state.suggestion,
  onUse: () => controller.useSuggestion(),
  onScanDifferent: () => scannerService.openOverlay(),
)

// ScanInputField — text field + camera icon button
ScanInputField(
  label: 'Bin (LOT)',
  controller: controller.lotController,
  onScanned: (value) => controller.setLot(value),
)

// QtyInput — numeric, min 0.001, max = pendingQty
QtyInput(max: line.pendingQty, onChanged: controller.setQty)

DatePickerField(label: 'Production Date (optional)')
```

### 5.4 Riverpod Notifier

```dart
@freezed
class GrnPutAwayState with _$GrnPutAwayState {
  const factory GrnPutAwayState({
    @Default([]) List<ReceivedItemLine> pendingLines,
    @Default(false) bool isLoading,
    LotSuggestion? suggestion,
    @Default(false) bool isSuggesting,
    String? selectedLot,
    double? qty,
    String? productionDate,
    String? expiryDate,
  }) = _GrnPutAwayState;
}

@riverpod
class GrnNotifier extends _$GrnNotifier {
  @override
  Future<GrnPutAwayState> build() async {
    final lines = await ref.read(grnRepositoryProvider).listPending();
    return GrnPutAwayState(pendingLines: lines);
  }

  Future<void> fetchSuggestion(ReceivedItemLine line) async {
    state = AsyncData(state.value!.copyWith(isSuggesting: true, suggestion: null));
    try {
      final s = await ref.read(grnRepositoryProvider)
          .suggestLot(line.name, line.pendingQty);
      state = AsyncData(state.value!.copyWith(isSuggesting: false, suggestion: s));
    } catch (_) {
      state = AsyncData(state.value!.copyWith(isSuggesting: false));
    }
  }

  void useSuggestion() {
    final lot = state.value?.suggestion?.lot;
    if (lot != null) setLot(lot);
  }

  void setLot(String lot) =>
      state = AsyncData(state.value!.copyWith(selectedLot: lot));

  Future<void> putAway(ReceivedItemLine line) async {
    final s = state.value!;
    final requestId = const Uuid().v4();
    await ref.read(grnRepositoryProvider).putAway(
      lineId: line.name,
      lot: s.selectedLot!,
      qty: s.qty ?? line.pendingQty,
      productionDate: s.productionDate,
      expiryDate: s.expiryDate,
      requestId: requestId,
    );
    ref.invalidateSelf();
  }
}
```

### 5.5 LotSuggestion Model

```dart
@freezed
class LotSuggestion with _$LotSuggestion {
  const factory LotSuggestion({
    String? lot,              // null = no suggestion available
    required String reason,
    String? warehouse,
    String? zone,
    String? aisle,
    String? level,
  }) = _LotSuggestion;
  factory LotSuggestion.fromJson(Map<String, dynamic> json) =>
      _$LotSuggestionFromJson(json);
}
```

---

## 6. Module: Warehouse — FIFO Pick List

**PDT Screen key:** `pick_list`  
**Roles:** WMS Picker

### 6.1 Screen Flow

```
Pick List (grouped) → Tap item → Pick Dialog → Confirm
```

**Grouped display:**
- **Unassigned** (status=Pending, not claimed by this worker)
- **My Items** (status=In Progress, assigned_to = me)
- **Completed** (status=Completed, greyed out at bottom)

**Filter bar:** Material Request dropdown to narrow by MR.

**Tap an unassigned item → claim it** (calls `pick.claim`). Item moves to "My Items".

**Tap a claimed item → Pick Dialog:**
- Item code + description
- Required qty / Picked so far / Remaining
- Suggested LOT chip (tap to auto-fill scan field)
- Scan field for actual LOT (default pre-filled with suggested)
- Qty stepper (max = remaining)
- If scanned lot differs from suggested → confirm "Override suggested bin?"

**On confirm → `pick.submit`**
- Generate `request_id` before submit
- Partial picks allowed (remaining stays in "In Progress")

### 6.2 Pick Item Card

```dart
PickItemCard(
  item: pickItem,
  onClaim: () => controller.claim(pickItem.name),
  onPick: () => showPickDialog(context, pickItem),
  isMyItem: pickItem.assignedTo == currentUser,
)
```

---

## 7. Module: Warehouse — Physical Inventory

**PDT Screen key:** `physical_inventory`  
**Roles:** WMS Counter

### 7.1 Screen Flow

```
Scan Bin → Bin Contents Table (count each line) → Submit
```

**Step 1 — Scan Bin**
- Large scan field in center of screen
- On scan: calls `physical_inventory.start(lot)` → shows bin contents

**Step 2 — Count Table**
- Each row: Item | Batch | Production Date | System Qty (grey, read-only) | **Counted Qty** (editable)
- Default counted qty = system qty (worker changes only what differs)
- "Add new line" button for items found in the bin that aren't in the system

**Step 3 — Submit → `physical_inventory.submit`**
- Show diff summary: "3 lines, 2 adjustments" before confirming
- Post with idempotency `request_id`
- Show Stock Reconciliation number on success

---

## 8. Module: Warehouse — LOT Browser & Manual Transfer

**PDT Screen key:** `lot_browser` (read), `manual_transfer` (write)  
**Roles:** WMS Supervisor

### 8.1 LOT Browser

- Search/filter bar: Warehouse, Zone, Item code, "Occupied only" toggle
- Paginated list of bins (50 per page)
- Each bin card: Bin ID | Warehouse | Zone | Aisle | Level | Status chips (Full/Empty/Reserved)
- Tap → bin detail with full contents table (item, batch, qty, production date)

### 8.2 Manual Transfer

- From Bin scan field
- To Bin scan field
- Item + Batch scan fields
- Qty stepper
- Confirm → `lot.transfer` with `request_id`

---

## 9. Module: Line 1 — Funnel/Bag Transfer & Calendering

**Roles:** Line 1 Operator

### 9.1 Funnel/Bag Transfer Screen

**Flow:** Scan pick_item_id → Show item + batch + available qty → Edit load qty (partial allowed) → Approve

On approve → `line1.funnel_transfer` (to be implemented):
- Stock Entry: Funnel-Out → Funnel-In for load qty
- WMS LOG: Funnel Transfer

### 9.2 Calendering Screen

**Flow:** Scan FMB batch barcode → Show FMB details (lab-approved flag) → Enter sheet outputs + C/R return qtys

Form fields:
- FMB batch (scanned)
- FMB qty loaded
- Sheet outputs table: each row = sheet item + thickness + length + qty (up to 5 specs)
- C-return qty (goes back to original batch)
- R-return qty (goes back to original batch)
- Calculated display: Net Consumed, Yield %

On submit → `line1.calendering_submit` (to be implemented):
- Stock Entry for sheets created in Calendering WH
- C/R returns Stock Entry back to FMB Zone with original batch number

### 9.3 Cutting & Splicing Screen

**Flow:** Scan source sheet batch → Select target item → Enter input qty + output qty → Put-away target to a LOT

On submit → `line1.cutting_submit` (to be implemented):
- Repack Stock Entry: source sheet → target item

---

## 10. Module: Line 2 — Building Flowchart

**Roles:** Builder, Curing Operator, Grinder, Finisher

### 10.1 Flowchart Scan Entry Point

Every Line 2 action starts with scanning the flowchart barcode printed on the work order traveller.

```dart
// On scan: call line2.scan_flowchart(barcode)
// Returns: { work_order, item, step, expected_measurements[], tools_assigned }
// App navigates to the correct step screen automatically
```

### 10.2 Active Jobs Dashboard

- Live job cards with elapsed timer (client-side counter started from Job Card `actual_start_time`)
- New Scan button (opens scanner full-screen)
- Switch Workspace button

### 10.3 Sleeve Building Screen

1. Flowchart scan → WO loaded
2. Mold scan (if first use today and plan hasn't pre-assigned) → `line2.assign_mold`
3. Layering checklist: each layer row shows item, count, description, optional photo
4. Critical layers require explicit ✓ tap to proceed
5. Finish button → `line2.complete_building_step`

### 10.4 Curing Screen

1. Flowchart scan → WO loaded (should already be at curing step)
2. Airbag scan (recommended airbag shown, alternatives below)
3. Finish → `line2.complete_curing` (mold + airbag released)
4. Note: Cure data recorded on paper flowchart and photographed at QC — no data entry here

### 10.5 Grinding / Chamfer / Rib Grinding / Cutting (per step)

Same pattern for all measurement steps:
1. Flowchart scan
2. Pre-filled measurement fields (type-specific, expected values shown)
3. Worker verifies/enters actuals
4. Qty field + Rejection qty field (if any rejection → opens rejection modal)
5. Rejection modal: reason code picker (filtered to Production Type of this item), qty, "Send to Rework" or "Full Scrap"
6. Finish → `line2.complete_step`

### 10.6 Labelling Screen

1. Flowchart scan (at Finishing step)
2. System shows item details
3. "Generate & Print Label" button → `line2.print_label(work_order)`
4. Worker confirms physical label attached → Finish

---

## 11. Module: QC

**Roles:** QC Measurer, QC Inspector

### 11.1 Mode Detection

QC mode is determined by the item's Sales Order UOM:
- **Belt UOM** → 2-person mode: Measurer enters measurements first, then QC Inspector reviews and enters accept/reject.
- **Sleeve UOM** → 1-person mode: single session for measurements + accept/reject.

The screen shows a "Who is doing QC?" dropdown (list of QC Users) because QC PDTs are shared.

### 11.2 QC Measurement Screen (Belt mode — Measurer)

1. Scan lot / batch
2. Product details + elapsed timer
3. Type-specific measurement fields (pre-filled with expected values from Production Type)
4. Submit → `qc.submit_measurements`

### 11.3 QC Final Screen (Belt mode — Inspector / Sleeve mode — single)

1. Scan lot
2. Review measurements (if Belt mode, read-only display of measurer's data)
3. Inspected qty | Accepted qty | Rejected qty (auto-computed: inspected - accepted)
4. "Add Rejected Item" button → modal:
   - Rejection reason (filtered by Production Type)
   - Qty (may be in belt UOM even if production is sleeve UOM)
   - Action: Rework (→ step picker) or Full Scrap
5. Rework assignment: default step from reason code, QC can override to any step from Grinding onward
6. "Attach Flowchart Photo" — mandatory for completion:
   - `image_picker` → camera intent
   - Upload file to ERPNext File record, link to Work Order
7. Finish → `qc.complete` which:
   - Creates Rejection Log entries
   - Completes native ERPNext Work Order
   - Creates Manufacture Stock Entry (materials consumed → finished belts in belt UOM)
   - Option to put finished goods to a WH-L LOT (with palletisation prompt)

---

## 12. Module: Packing & Palletisation

**Roles:** Packer

### 12.1 Create Box (Belt orders)

1. Scan or select Sales Order
2. Add items to box (item + batch + qty)
3. Print box label → `packing.print_box_label`
4. Box created and linked to Sales Order

### 12.2 Create Pallet

1. Select Sales Order
2. Belt pallets: scan boxes to add to pallet
3. Sleeve pallets: add items directly
4. Assign to Finished Products LOT (WH-L) → `packing.put_away_pallet`
5. Print pallet label → `packing.print_pallet_label`

---

## 13. Notifications (FCM/OneSignal)

### 13.1 Setup

```dart
// core/notifications/notification_service.dart
import 'package:onesignal_flutter/onesignal_flutter.dart';

class NotificationService {
  Future<void> init() async {
    OneSignal.initialize('<ONESIGNAL_APP_ID>');
    OneSignal.Notifications.requestPermission(true);

    OneSignal.User.pushSubscription.addObserver((state) async {
      final playerId = state.current.id;
      if (playerId != null) {
        await ref.read(notificationsRepositoryProvider).registerDevice(playerId);
      }
    });

    OneSignal.Notifications.addForegroundWillDisplayListener((event) {
      // Show in-app banner for foreground notifications
      event.notification.display();
    });

    OneSignal.Notifications.addClickListener((event) {
      _handleNotificationTap(event.notification.additionalData);
    });
  }

  void _handleNotificationTap(Map<String, dynamic>? data) {
    if (data == null) return;
    final trigger = data['trigger'] as String?;
    switch (trigger) {
      case 'chat_message':   router.push('/support?tab=chat'); break;
      case 'on_site_support': /* supervisor screen */ break;
      case 'idle_alert':     /* worker sees their own idle pop-up */ break;
    }
  }
}
```

### 13.2 Idle Alert Pop-up

The server pushes an `idle_alert` notification to the worker's device when no flowchart scan is recorded within `wms_settings.idle_alert_minutes`.

```dart
// The app handles this as an in-foreground overlay:
OneSignal.Notifications.addForegroundWillDisplayListener((event) {
  if (event.notification.additionalData?['trigger'] == 'idle_alert') {
    event.preventDefault();   // don't show system notification
    _showIdleOverlay();        // show modal dialog on the PDT screen
  }
});
```

---

## 14. Barcode Scanning

### 14.1 Unified Scanner Service

```dart
// core/scanner/scanner_service.dart
// Supports two input methods:
// 1. Camera scan via mobile_scanner package
// 2. Bluetooth HID keyboard events from physical Zebra/Honeywell scanners

class ScannerService {
  final _controller = StreamController<String>.broadcast();
  Stream<String> get onScan => _controller.stream;

  // Bluetooth scanners appear as keyboard input — capture via RawKeyboardListener
  // or hardware_keyboard package
  void onHardwareInput(String input) {
    // Zebra scanners emit the barcode + Enter key
    final cleaned = input.trim();
    if (cleaned.isNotEmpty) _controller.add(cleaned);
  }

  // Camera scan result from MobileScanner
  void onCameraScan(BarcodeCapture capture) {
    final barcode = capture.barcodes.firstOrNull?.rawValue;
    if (barcode != null) _controller.add(barcode);
  }
}
```

### 14.2 ScanInputField Widget

```dart
// shared/widgets/scan_input_field.dart
class ScanInputField extends ConsumerStatefulWidget {
  final String label;
  final ValueChanged<String> onScanned;
  final bool autofocus;

  // Shows a text field + camera icon button
  // On camera icon tap → opens MobileScanner overlay
  // On hardware scan (BT scanner) → auto-populates and calls onScanned
}
```

### 14.3 Barcode Types Used

| Barcode | Format | Example |
|---|---|---|
| Bin / LOT | Code 128 or QR | `B-AA-1` |
| Pick Item | Code 128 | `PL-2026-00001-001` |
| Work Order Flowchart | QR | `WO-2026-00123` |
| Mold / Tool | Code 128 | `MOLD-0042` |
| FMB Batch | QR | `FMB-20260601-001` |
| Box | Code 128 | `BOX-2026-0001` |
| Pallet | Code 128 | `PAL-2026-0001` |

---

## 15. Offline & Idempotency

### 15.1 Request ID Generation

Every write call that the server accepts a `request_id` parameter must generate a UUID v4 client-side before sending. This ensures that if the network drops after the server processes the request but before the response arrives, the client can retry safely.

```dart
// core/offline/idempotency.dart
import 'package:uuid/uuid.dart';

class IdempotencyService {
  static const _uuid = Uuid();

  // Generate a fresh request_id for a new write operation
  String newId() => _uuid.v4();
}
```

### 15.2 Offline Queue (Hive)

For write operations that fail due to network unavailability, queue them and retry:

```dart
// core/offline/offline_queue.dart
@HiveType(typeId: 0)
class QueuedRequest {
  @HiveField(0) final String endpoint;
  @HiveField(1) final Map<String, dynamic> params;
  @HiveField(2) final String requestId;
  @HiveField(3) final DateTime createdAt;
}

// Process queue on connectivity restore using connectivity_plus
```

### 15.3 What to Queue

- `grn.put_away` ✅ (has request_id)
- `pick.submit` ✅
- `lot.transfer` ✅
- `physical_inventory.submit` ✅
- `pick.claim` ✗ (not idempotent, don't queue — just retry online)

---

## 16. State Management (Riverpod)

### 16.1 Global Providers

```dart
// core/auth/auth_provider.dart
@riverpod
class Auth extends _$Auth {
  @override
  AuthState build() => _loadFromStorage();

  Future<void> login(String usr, String pwd) async { ... }
  Future<void> logout() async { ... }
  bool get isAuthenticated => state.token != null;
}

// core/session/session_provider.dart
@riverpod
class Session extends _$Session {
  @override
  SessionState build() => SessionState.empty();

  Future<void> selectWorkspace(String assignment) async { ... }
  MenuData get menu => state.menu;
}
```

### 16.2 Per-Screen Notifiers

Each screen uses an `AsyncNotifier`:

```dart
// features/grn/grn_notifier.dart
@riverpod
class GrnNotifier extends _$GrnNotifier {
  @override
  Future<List<ReceivedItemLine>> build() =>
      ref.read(grnRepositoryProvider).listPending();

  Future<void> putAway({ ... }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(grnRepositoryProvider).putAway(...);
      return ref.read(grnRepositoryProvider).listPending();
    });
  }
}
```

---

## 17. Shared UI Components

### 17.1 PdtScaffold

Wraps every screen with:
- App bar: screen title + back button + active workspace chip
- FAB: scan button (opens scanner overlay)
- End drawer: Support panel (Chat Supervisor, Raise Issue, Maintenance Request)
- Connectivity banner (red bar when offline)

```dart
PdtScaffold(
  title: 'GRN Put-Away',
  onScan: (value) => context.read(grnNotifierProvider.notifier).setScannedLot(value),
  child: GrnPutAwayBody(),
)
```

### 17.2 Status Chip

```dart
StatusChip(status: pickItem.status)
// Pending → grey, In Progress → orange, Completed → green
```

### 17.3 Confirm Bottom Sheet

All destructive actions (submit put-away, submit count, complete step) use a standardised confirmation sheet:

```dart
showConfirmSheet(
  context,
  title: 'Confirm Put-Away',
  details: 'Item: rubber-001\nLot: B-AA-1\nQty: 50 KG',
  onConfirm: () => controller.executePutAway(),
);
```

### 17.4 Live Timer Widget

Used on Active Jobs Dashboard and QC screens:

```dart
LiveTimer(startTime: jobCard.actualStartTime)
// Counts up in HH:MM:SS
// Turns orange after target_time_minutes
// Turns red after target_time_minutes + buffer_time_minutes
```

---

## 18. Error Handling

### 18.1 API Error Codes → User Messages

```dart
// core/api/error_mapper.dart
extension ApiErrorMapper on String {
  String toUserMessage() => switch (this) {
    'BIN_FULL'            => 'This bin is full. Ask your supervisor to override.',
    'NOT_READY_FOR_ALLOC' => 'This item is still in lab/finance review.',
    'OVER_PENDING_QTY'    => 'Quantity exceeds what is still pending.',
    'NO_STOCK'            => 'No stock of this item in the selected bin.',
    'INSUFFICIENT_QTY'    => 'Not enough stock in this bin.',
    'FORBIDDEN'           => 'You do not have permission for this action.',
    'UNAUTHENTICATED'     => 'Session expired. Please log in again.',
    'VALIDATION'          => 'Check your input and try again.',
    _                     => 'Unexpected error. Please contact support.',
  };
}
```

### 18.2 Error Snackbar

```dart
// Always shown at bottom of screen, never modal (avoids blocking workflow)
ErrorSnack.show(context, code: e.code, message: e.message);
```

### 18.3 Network Error Handling

```dart
// Dio interceptor: on DioException → check if request is idempotent
// If yes → add to offline queue
// If no → show "No connection" snackbar with retry button
```

---

## 19. Testing Strategy

### 19.1 Unit Tests — Repository Layer

```dart
// test/features/grn/grn_repository_test.dart
// Mock Dio with MockAdapter
// Test: 200 success → returns List<ReceivedItemLine>
// Test: BIN_FULL error → throws PdtApiException with code BIN_FULL
// Test: network timeout → adds to offline queue (if idempotent)
```

### 19.2 Widget Tests — Screen Level

```dart
// test/features/grn/grn_screen_test.dart
// Pump screen with mock provider
// Verify: pending lines render correctly
// Simulate scan → verify lot field populated
// Simulate confirm → verify loading state → verify success snackbar
```

### 19.3 Integration Tests — End-to-End

Run against a staging ERPNext instance:

```dart
// integration_test/grn_flow_test.dart
// 1. Login with test worker credentials
// 2. Select workspace
// 3. Navigate to GRN
// 4. Scan a real pending received item line
// 5. Enter lot, qty, production date
// 6. Submit
// 7. Assert Stock Entry was created in ERPNext
```

### 19.4 Offline Tests

```dart
// Disable network → submit pick
// Assert: request stored in Hive queue
// Re-enable network → assert: request retried + Stock Entry created
```

---

## 20. Build & Release

### 20.1 Environment Config

```dart
// lib/core/config/app_config.dart
class AppConfig {
  static const baseUrl = String.fromEnvironment('BASE_URL',
      defaultValue: 'https://erp.universal.internal');
  static const oneSignalAppId = String.fromEnvironment('ONESIGNAL_APP_ID');
  static const environment = String.fromEnvironment('ENV', defaultValue: 'prod');
}
```

Build with:
```bash
flutter build apk --release \
  --dart-define=BASE_URL=https://erp.universal.internal \
  --dart-define=ONESIGNAL_APP_ID=<id> \
  --dart-define=ENV=prod
```

### 20.2 App Update Check

On launch, call `app_update.check`. If `force_update = true` and installed version < `latest_version`, block with a mandatory update dialog pointing to the internal APK URL.

### 20.3 Release APK Distribution

Distribute via an internal APK download link (no Play Store needed for enterprise). The `PDT App Version` doctype in ERPNext tracks versions and their download URLs. Workers get a push notification when an update is available.

### 20.4 Target Android Version

- `minSdkVersion 26` (Android 8.0 — covers all Zebra TC-series PDTs from 2018+)
- `targetSdkVersion 34`
- Enable `android:largeHeap="true"` for photo uploads at QC

---

## Appendix A: Complete Screen List with API Calls

| Screen | API Calls | Write? |
|---|---|---|
| Login | `session.login` | yes |
| Workspace Setup | `session.list_workspaces`, `session.select_workspace`, `session.get_menu` | yes |
| Home (Menu) | (uses cached menu) | no |
| GRN Put-Away | `grn.list_pending`, `grn.get`, `grn.suggest_lot`, `grn.put_away` | put_away yes; suggest_lot no |
| Pick List | `pick.list`, `pick.claim`, `pick.submit` | yes |
| Physical Inventory | `physical_inventory.start`, `physical_inventory.submit` | yes |
| LOT Browser | `lot.browse`, `lot.get` | no |
| Manual LOT Transfer | `lot.transfer` | yes |
| Funnel Transfer | `line1.funnel_transfer` | yes |
| Bag Creation | `line1.bag_create` | yes |
| Calendering | `line1.calendering_submit` | yes |
| Cutting & Splicing | `line1.cutting_submit` | yes |
| Active Jobs Dashboard | `line2.my_jobs` | no |
| Flowchart Scan | `line2.scan_flowchart` | yes (starts Job Card) |
| Sleeve Building | `line2.complete_building_step` | yes |
| Curing | `line2.complete_curing` | yes |
| Grinding/Chamfer/Rib/Cut | `line2.complete_step` | yes |
| Labelling | `line2.print_label` | yes |
| QC Measurement | `qc.submit_measurements` | yes |
| QC Final | `qc.complete` | yes |
| Packing — Box | `packing.create_box`, `packing.print_box_label` | yes |
| Packing — Pallet | `packing.create_pallet`, `packing.put_away_pallet`, `packing.print_pallet_label` | yes |
| Sleeve Creation | `line2.sleeve_creation_submit` | yes |
| Tool Status View | `tools.list`, `tools.update_weight` | yes |
| Equipment Alarm View | `machtech.alarms` | no |
| Chat / Support | `notifications.chat`, `notifications.raise_support`, `notifications.maintenance_request` | yes |
| Notifications Inbox | `notifications.get_notifications`, `notifications.mark_read` | yes |

---

## Appendix B: Data Models (Freezed)

```dart
// shared/models/received_item_line.dart
@freezed
class ReceivedItemLine with _$ReceivedItemLine {
  const factory ReceivedItemLine({
    required String name,
    required String parent,
    required String itemCode,
    required double receivedQty,
    required double binAllocatedQuantity,
    required double pendingQty,
    required bool isLineCompleted,
    required bool readyForAllocation,
  }) = _ReceivedItemLine;
  factory ReceivedItemLine.fromJson(Map<String, dynamic> json) =>
      _$ReceivedItemLineFromJson(json);
}

// shared/models/warehouse_lot.dart
@freezed
class WarehouseLot with _$WarehouseLot {
  const factory WarehouseLot({
    required String name,
    required String warehouse,
    required String zoneName,
    required String aisle,
    required String level,
    required bool isFull,
    required bool isEmpty,
    required bool isReserved,
    @Default([]) List<LotStockLine> contents,
  }) = _WarehouseLot;
  factory WarehouseLot.fromJson(Map<String, dynamic> json) =>
      _$WarehouseLotFromJson(json);
}

// shared/models/lot_stock_line.dart
@freezed
class LotStockLine with _$LotStockLine {
  const factory LotStockLine({
    required String itemCode,
    required double qty,
    String? batchNo,
    String? productionDate,
    String? expiryDate,
    String? grnReference,
  }) = _LotStockLine;
  factory LotStockLine.fromJson(Map<String, dynamic> json) =>
      _$LotStockLineFromJson(json);
}

// shared/models/pick_item.dart
@freezed
class PickItem with _$PickItem {
  const factory PickItem({
    required String name,
    required String parent,
    required String itemCode,
    required double requiredQty,
    required double pickedQty,
    String? suggestedLot,
    String? actualLot,
    required String pickMode,
    required String status,
    String? assignedTo,
  }) = _PickItem;
  factory PickItem.fromJson(Map<String, dynamic> json) =>
      _$PickItemFromJson(json);
}
```

---

## Appendix C: Backend Endpoints Still to Be Built

These API endpoints are referenced in this guide but do not yet exist in `universal_mobile_api`. They must be built alongside or before the corresponding screens:

| Endpoint module | Screens it serves | Build phase |
|---|---|---|
| `api/line1.py` | Funnel, Calendering, Cutting | Phase 5–6 |
| `api/line2.py` | All Line 2 building steps | Phase 7 |
| `api/qc.py` | QC Measurement + QC Final | Phase 8 |
| `api/packing.py` | Box + Pallet | Phase 8 |
| `api/tools.py` | Tool Status View | Phase 7 |
| `api/machtech.py` | Equipment Alarm View | Phase 13 |
