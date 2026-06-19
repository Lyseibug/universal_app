# Flutter PDT App — Development Guide (wired to `universal_mobile_api`)

A code-level guide to building the app against the endpoints you've written. It follows the actual contract those endpoints expose, so the Dart here drops straight onto your API. This supersedes the response-handling sketch in the earlier build plan (the real envelope is wrapped under `message` — see §1).

---

## 1. The exact contract this app codes to

- **Base path:** every call is `POST /api/method/universal_mobile_api.api.<module>.<method>`.
- **Auth header:** `Authorization: token <api_key>:<api_secret>` — the single string returned by `login` as `token`.
- **Response envelope (Frappe wraps your return under `message`):**
  - success → HTTP 2xx, body `{"message": {"ok": true, "data": <payload>}}`
  - failure → HTTP 400/401/403, body `{"message": {"error": true, "code": "...", "message": "..."}}`
- **Writes are idempotent:** stock-moving calls take a `request_id` (uuid). Re-sending the same id replays the first result (`DUPLICATE_REQUEST` never double-posts).
- **Login params are `usr` / `pwd`** (matching `session.login(usr, pwd)`).
- **Menu shape** from `session.get_menu` (`data`):
  ```json
  { "menu": [ { "module_key": "receiving", "label": "Receiving", "icon": "inbox",
      "screens": [ { "screen_key": "grn_putaway", "label": "GRN Put-Away",
        "route": "/grn-putaway", "api_module": "grn",
        "actions": ["put_away","override_suggested_lot"] } ] } ] }
  ```
- **Screen / action keys** (from the seed): `grn_putaway`(put_away, override_suggested_lot, override_capacity) · `pick_list`(claim, pick, override_suggested_lot) · `physical_inventory`(submit_count) · `lot_browser`(—) · `manual_transfer`(transfer) · `support`(chat, raise_issue, maintenance_request).
- **Error codes** to handle: `FORBIDDEN`, `UNAUTHENTICATED`, `NO_ACTIVE_WORKSPACE`, `NOT_READY_FOR_ALLOCATION`, `OVER_PENDING_QTY`, `BIN_FULL`, `DUPLICATE_REQUEST`, `VALIDATION`.

---

## 2. Dependencies (`pubspec.yaml`)

```yaml
dependencies:
  flutter_riverpod: ^2.5.0
  dio: ^5.4.0
  flutter_secure_storage: ^9.0.0
  go_router: ^14.0.0
  uuid: ^4.3.0
  hive: ^2.2.3
  hive_flutter: ^1.1.0
  mobile_scanner: ^5.0.0
  connectivity_plus: ^6.0.0
  # firebase_messaging: ^14.0.0   # phase 9 push
dev_dependencies:
  build_runner: ^2.4.0
  hive_generator: ^2.0.0
```

Use current stable versions from pub.dev at build time.

---

## 3. Project structure

```
lib/
  core/
    api/ api_client.dart  api_exception.dart
    auth/ token_store.dart  session_repository.dart
    menu/ menu_models.dart  menu_providers.dart
    scanner/ scan_service.dart
    sync/ write_queue.dart  request_id.dart
    errors/ error_messages.dart
  features/
    login/ login_screen.dart
    workspace/ workspace_screen.dart
    home/ home_screen.dart  screen_registry.dart
    grn/ grn_repository.dart  grn_putaway_screen.dart
    pick/ pick_repository.dart  pick_list_screen.dart
    physical_inventory/ ...
    lot/ ...
    support/ ...
  app.dart  main.dart
```

---

## 4. Core — API client

`validateStatus` lets 4xx reach `onResponse`, so success and error are unwrapped in one place.

```dart
// core/api/api_exception.dart
class ApiException implements Exception {
  final String code;
  final String message;
  const ApiException(this.code, this.message);
  bool get isAuth => code == 'UNAUTHENTICATED';
}

// core/api/api_client.dart
import 'package:dio/dio.dart';
import '../auth/token_store.dart';
import 'api_exception.dart';

class ApiClient {
  final Dio _dio;
  final TokenStore _tokens;

  ApiClient(this._tokens, {required String baseUrl})
      : _dio = Dio(BaseOptions(
          baseUrl: baseUrl,
          contentType: 'application/json',
          validateStatus: (s) => s != null && s < 500,
        )) {
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final t = await _tokens.read();
        if (t != null) options.headers['Authorization'] = 'token $t';
        handler.next(options);
      },
    ));
  }

  /// Returns the inner `data` payload, or throws ApiException.
  Future<dynamic> call(String method, {Map<String, dynamic>? body}) async {
    final res = await _dio.post(
      '/api/method/universal_mobile_api.api.$method',
      data: body ?? const {},
    );
    final root = res.data;
    final msg = (root is Map && root['message'] is Map)
        ? root['message'] as Map
        : null;
    if (msg == null) {
      throw const ApiException('PROTOCOL', 'Unexpected server response');
    }
    if (msg['error'] == true) {
      throw ApiException(
        (msg['code'] ?? 'UNKNOWN').toString(),
        (msg['message'] ?? 'Error').toString(),
      );
    }
    return msg['data'];
  }
}
```

```dart
// core/auth/token_store.dart
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
class TokenStore {
  final _s = const FlutterSecureStorage();
  Future<String?> read() => _s.read(key: 'pdt_token');
  Future<void> write(String t) => _s.write(key: 'pdt_token', value: t);
  Future<void> clear() => _s.delete(key: 'pdt_token');
}
```

---

## 5. Menu models

```dart
// core/menu/menu_models.dart
class MenuScreen {
  final String screenKey, label, route, apiModule;
  final List<String> actions;
  MenuScreen(this.screenKey, this.label, this.route, this.apiModule, this.actions);
  factory MenuScreen.fromJson(Map j) => MenuScreen(
    j['screen_key'], j['label'], j['route'] ?? '', j['api_module'] ?? '',
    List<String>.from(j['actions'] ?? const []));
  bool can(String action) => actions.contains(action);
}

class MenuModule {
  final String moduleKey, label, icon;
  final List<MenuScreen> screens;
  MenuModule(this.moduleKey, this.label, this.icon, this.screens);
  factory MenuModule.fromJson(Map j) => MenuModule(
    j['module_key'], j['label'], j['icon'] ?? '',
    (j['screens'] as List).map((s) => MenuScreen.fromJson(s)).toList());
}
```

---

## 6. Session repository

```dart
// core/auth/session_repository.dart
import '../api/api_client.dart';
import 'token_store.dart';
import '../menu/menu_models.dart';

class SessionRepository {
  final ApiClient _api;
  final TokenStore _tokens;
  SessionRepository(this._api, this._tokens);

  Future<List<String>> login(String usr, String pwd) async {
    // login does not need a token; ApiClient simply won't attach one yet.
    final data = await _api.call('session.login', body: {'usr': usr, 'pwd': pwd});
    await _tokens.write(data['token']);            // "api_key:api_secret"
    return List<String>.from(data['roles'] ?? const []);
  }

  Future<List<Map>> listWorkspaces() async =>
      List<Map>.from(await _api.call('session.list_workspaces'));

  Future<void> selectWorkspace(String assignment) =>
      _api.call('session.select_workspace', body: {'assignment': assignment});

  Future<List<MenuModule>> getMenu() async {
    final data = await _api.call('session.get_menu');
    return (data['menu'] as List).map((m) => MenuModule.fromJson(m)).toList();
  }

  Future<void> logout() async {
    try { await _api.call('session.logout'); } finally { await _tokens.clear(); }
  }
}
```

---

## 7. State (Riverpod)

```dart
// providers wiring (simplified)
final baseUrlProvider = Provider<String>((_) =>
    const String.fromEnvironment('BASE_URL', defaultValue: 'https://erp.example.com'));
final tokenStoreProvider = Provider((_) => TokenStore());
final apiClientProvider = Provider((ref) =>
    ApiClient(ref.read(tokenStoreProvider), baseUrl: ref.read(baseUrlProvider)));
final sessionRepoProvider = Provider((ref) =>
    SessionRepository(ref.read(apiClientProvider), ref.read(tokenStoreProvider)));

/// Menu loaded once after workspace selection; the whole UI reads from this.
final menuProvider = FutureProvider<List<MenuModule>>((ref) =>
    ref.read(sessionRepoProvider).getMenu());

/// Auth state drives routing.
final authProvider = StateProvider<bool>((_) => false);
```

A top-level error handler should catch `ApiException.isAuth` anywhere and flip `authProvider` to false (→ login).

---

## 8. Routing & bootstrap

```dart
// app.dart — go_router with an auth redirect
final router = GoRouter(
  redirect: (ctx, state) {
    final loggedIn = ref.read(authProvider);
    final atLogin = state.matchedLocation == '/login';
    if (!loggedIn) return atLogin ? null : '/login';
    return null;
  },
  routes: [
    GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
    GoRoute(path: '/workspace', builder: (_, __) => const WorkspaceScreen()),
    GoRoute(path: '/home', builder: (_, __) => const HomeScreen()),
    // feature routes are resolved dynamically from the menu (see §10)
  ],
);
```

Boot sequence: `main` opens Hive (write queue), checks for a stored token; if present, try `get_menu` (valid token) → `/home`, else `/login`.

---

## 9. Login & workspace screens

```dart
// login: on submit
final roles = await ref.read(sessionRepoProvider).login(usr, pwd);
ref.read(authProvider.notifier).state = true;
final ws = await ref.read(sessionRepoProvider).listWorkspaces();
context.go(ws.length == 1 ? '/home' : '/workspace');
if (ws.length == 1) {
  await ref.read(sessionRepoProvider).selectWorkspace(ws.first['name']);
}

// workspace picker: on tap
await ref.read(sessionRepoProvider).selectWorkspace(assignment);
ref.invalidate(menuProvider);     // refetch menu for the chosen workspace
context.go('/home');
```

---

## 10. The dynamic menu + screen registry (central)

The app ships one widget per known `screen_key`. The menu decides which appear and which actions are enabled. Unknown keys are skipped so the server can add screens before every device updates.

```dart
// features/home/screen_registry.dart
typedef ScreenBuilder = Widget Function(MenuScreen screen);

final screenRegistry = <String, ScreenBuilder>{
  'grn_putaway':        (s) => GrnPutAwayScreen(screen: s),
  'pick_list':          (s) => PickListScreen(screen: s),
  'physical_inventory': (s) => PhysicalInventoryScreen(screen: s),
  'lot_browser':        (s) => LotBrowserScreen(screen: s),
  'manual_transfer':    (s) => ManualTransferScreen(screen: s),
  'support':            (s) => SupportScreen(screen: s),
};

// features/home/home_screen.dart (build)
final menu = ref.watch(menuProvider);
return menu.when(
  loading: () => const Center(child: CircularProgressIndicator()),
  error: (e, _) => ErrorView(e),
  data: (modules) => ListView(children: [
    for (final m in modules)
      ExpansionTile(
        title: Text(m.label),
        children: [
          for (final s in m.screens)
            if (screenRegistry.containsKey(s.screenKey))   // forward-compat
              ListTile(
                title: Text(s.label),
                onTap: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => screenRegistry[s.screenKey]!(s))),
              ),
        ],
      ),
  ]),
);
```

Each screen receives its `MenuScreen` and gates buttons with `screen.can('action_key')`. **This is UX only** — the server re-checks via `require_pdt`, so a hidden or tampered action still fails server-side.

---

## 11. Scanner service

```dart
// core/scanner/scan_service.dart
abstract class ScanService {
  Stream<String> get scans;          // emits each decoded barcode
  void dispose();
}
```

- **Camera devices** → implement with `mobile_scanner`.
- **Zebra/Honeywell handhelds** → laser scans usually arrive via DataWedge **intent** or as **keyboard-wedge** input; implement a variant that listens for the broadcast/keystrokes and pushes onto the same `scans` stream.
- Select the implementation at startup from a device profile. Every screen consumes `scans`, indifferent to how scanning happened.

---

## 12. Idempotent write queue

```dart
// core/sync/request_id.dart
import 'package:uuid/uuid.dart';
String newRequestId() => const Uuid().v4();

// core/sync/write_queue.dart  (Hive-backed; survives app restarts)
class PendingWrite {
  final String requestId, method;
  final Map<String, dynamic> body;
  String state;                       // pending | synced | failed
  PendingWrite(this.requestId, this.method, this.body, this.state);
}

class WriteQueue {
  final ApiClient _api;
  final Box _box;                     // Hive box of PendingWrite
  WriteQueue(this._api, this._box);

  /// Enqueue and try immediately; safe to retry with the SAME requestId.
  Future<dynamic> run(String method, Map<String, dynamic> body) async {
    final id = body['request_id'] ?? newRequestId();
    body['request_id'] = id;
    await _box.put(id, {'method': method, 'body': body, 'state': 'pending'});
    try {
      final data = await _api.call(method, body: body);
      await _box.put(id, {'method': method, 'body': body, 'state': 'synced'});
      return data;
    } on ApiException {
      rethrow;                        // surface to UI; row stays for retry/flush
    }
  }

  Future<void> flush() async {        // call on connectivity restore
    for (final k in _box.keys) {
      final row = Map<String, dynamic>.from(_box.get(k));
      if (row['state'] == 'synced') continue;
      try {
        await _api.call(row['method'], body: Map<String, dynamic>.from(row['body']));
        row['state'] = 'synced'; await _box.put(k, row);
      } catch (_) { /* keep for next flush */ }
    }
  }
}
```

`connectivity_plus` triggers `flush()` when the network returns. Because every write carries a stable `request_id`, a retry after a dropped response never posts a second Stock Entry — the server returns the original result.

---

## 13. Feature screens

All follow: **list → render (scanner-driven) → action (writes via WriteQueue) → handle ApiException.**

### 13.1 GRN Put-Away (full example)

```dart
// features/grn/grn_repository.dart
class GrnRepository {
  final ApiClient _api; final WriteQueue _q;
  GrnRepository(this._api, this._q);

  Future<List> listPending() async => await _api.call('grn.list_pending');

  Future<dynamic> get(String receivedItem) =>
      _api.call('grn.get', body: {'received_item': receivedItem});

  Future<dynamic> putAway({
    required String line, required String lot, required double qty,
    String? productionDate, String? expiryDate, bool forceCapacity = false,
  }) => _q.run('grn.put_away', {
        'received_item_line': line, 'lot': lot, 'qty': qty,
        'production_date': productionDate, 'expiry_date': expiryDate,
        'force_capacity': forceCapacity ? 1 : 0,
      });
}

// features/grn/grn_putaway_screen.dart (essentials)
class GrnPutAwayScreen extends ConsumerStatefulWidget {
  final MenuScreen screen;
  const GrnPutAwayScreen({required this.screen, super.key});
  // ...
}

// in build:
// 1) FutureBuilder over repo.listPending() -> list of lines (ready_for_allocation=1)
// 2) tapping a line opens an allocation form; scanner fills the bin (lot)
// 3) qty + production date entered; submit:
Future<void> _submit() async {
  try {
    await ref.read(grnRepoProvider).putAway(
      line: lineName, lot: scannedLot, qty: qty,
      productionDate: prodDate, forceCapacity: overrideFull);
    _toast('Put away');
  } on ApiException catch (e) {
    if (e.code == 'BIN_FULL' && widget.screen.can('override_capacity')) {
      _offerOverride();                 // only supervisors see/can use this
    } else {
      _toast(messageFor(e));            // §14
    }
  }
}

// button visibility:
if (widget.screen.can('override_capacity')) OverrideFullBinSwitch(...),
```

### 13.2 Pick List
- `pick.list(material_request?, status?)` → grouped Unassigned/In Progress/Completed.
- `pick.claim(pick_item)` (button gated `claim`).
- `pick.submit(pick_item, actual_lot, picked_qty, request_id)` via `WriteQueue` (button gated `pick`). If the scanned bin ≠ `suggested_lot`, only allow when `screen.can('override_suggested_lot')`.

### 13.3 Physical Inventory
- `physical_inventory.start(lot)` → lines with `system_qty`.
- `physical_inventory.submit(lot, counts, request_id)` via `WriteQueue` (button gated `submit_count`). `counts` = `[{item_code, batch_no, counted_qty}]` sent as a JSON list.

### 13.4 LOT Browser (read-only)
- `lot.browse(warehouse?, zone?, item?, only_occupied?, limit, start)` with pagination; `lot.get(lot)` for detail. No actions.

### 13.5 Manual LOT Transfer
- `lot.transfer(from_lot, to_lot, item, batch_no, qty, request_id)` via `WriteQueue` (button gated `transfer`). Scanner fills from-bin then to-bin.

### 13.6 Support
- `notifications.chat(message, recipient?)` (gated `chat`; recipient defaults to supervisor server-side).
- `notifications.raise_support(support_type, payload?)` (gated `raise_issue`).
- `notifications.maintenance_request(equipment, issue_type, description, urgency)` (gated `maintenance_request`).
- `notifications.register_device(player_id)` is called once after login (no gate) when push is wired.

---

## 14. Error → message mapping

```dart
// core/errors/error_messages.dart
String messageFor(ApiException e) {
  switch (e.code) {
    case 'NOT_READY_FOR_ALLOCATION': return 'Lab/finance not cleared yet.';
    case 'OVER_PENDING_QTY':         return 'Quantity exceeds what is pending.';
    case 'BIN_FULL':                 return 'That bin is full.';
    case 'NO_ACTIVE_WORKSPACE':      return 'Select a workspace first.';
    case 'FORBIDDEN':                return 'You are not permitted to do that.';
    case 'DUPLICATE_REQUEST':        return 'Already submitted.';
    default:                          return e.message;
  }
}
```

`UNAUTHENTICATED` is handled globally (→ login), not shown as a toast.

---

## 15. Push notifications (phase 9)
Register FCM/OneSignal, call `notifications.register_device(playerId)` after login, and render incoming pushes (idle, target overrun, chat, support, machine alarm). Wire only when the server's phase-9 dispatch is live.

---

## 16. Testing
1. **ApiClient envelope** — mock `{message:{ok:true,data:..}}` and `{message:{error:true,code:'FORBIDDEN'}}`; assert `call` returns data / throws ApiException.
2. **Menu rendering** — feed each seeded user's `get_menu` payload; assert exactly the right tiles/buttons and that unknown `screen_key`s are skipped (receiver must NOT show `override_capacity`; supervisor must).
3. **Action gating** — a `MenuScreen` with `actions:['put_away']` shows Put Away, hides Override Full Bin.
4. **Idempotency** — `WriteQueue.run` on a failed-then-restored network keeps the same `request_id`; assert one server success.
5. **Integration** — login → workspace → menu → put-away against a staging site seeded with the PDT records.

---

## 17. Build / release & milestones
- Flavors `dev`/`staging`/`prod` carry `BASE_URL` via `--dart-define`.
- Android: target the PDT OS; document the DataWedge profile if used.
- Milestones: **F0** core (ApiClient, TokenStore, envelope) → **F1** login + workspace + dynamic menu → **F2** scanner + write queue → **F3** GRN → **F4** Pick → **F5** Physical Inventory → **F6** LOT Browser + Transfer → **F7** Support + push → **F8** offline/permission tests + release. Build F0–F2 before any feature screen.