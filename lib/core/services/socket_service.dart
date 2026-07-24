import 'package:socket_io_client/socket_io_client.dart' as io;
import '../utils/logger.dart';

class SocketService {
  io.Socket? _socket;
  final String _baseUrl;
  final String _token;
  final String _employeeId;
  final String _userEmail;
  final String? _siteName;
  final void Function(Map<String, dynamic> data) onNotificationReceived;
  final void Function(Map<String, dynamic> data)? onGroupMessageReceived;
  final void Function(Map<String, dynamic> data)? onDirectMessageReceived;

  SocketService({
    required String baseUrl,
    required String token,
    required String employeeId,
    required String userEmail,
    required this.onNotificationReceived,
    String? siteName,
    this.onGroupMessageReceived,
    this.onDirectMessageReceived,
  })  : _baseUrl = baseUrl,
        _token = token,
        _employeeId = employeeId,
        _userEmail = userEmail,
        _siteName = siteName;

  /// Establish socket connection
  void connect() {
    disconnect();

    // Frappe's realtime server namespaces every connection by site
    // (apps/frappe/realtime/index.js: `io.of(/^\/.*$/)` + the authenticate
    // middleware's site-name check) and publish_realtime always emits on
    // `/<site>` (apps/frappe/frappe/realtime.py). Without the `/<site>`
    // suffix here the socket lands on the default namespace instead and
    // silently never receives anything it's published -- confirmed live:
    // connections succeed either way, but only the namespaced one actually
    // gets events. Falls back to the bare host if site_name isn't known yet
    // (e.g. a cached pre-login session) -- same as before this fix, so it
    // degrades to the previous (broken-for-realtime) behavior rather than
    // failing to connect at all.
    final socketUrl = (_siteName != null && _siteName.isNotEmpty) ? '$_baseUrl/$_siteName' : _baseUrl;
    AppLogger.info('Initializing Socket.io client to: $socketUrl', tag: 'SocketService');

    try {
      _socket = io.io(
        socketUrl,
        io.OptionBuilder()
            .setTransports(['websocket', 'polling']) // Fallback to polling if websocket fails
            .setExtraHeaders({
              'Authorization': 'token $_token',
              // The site-namespaced connection is only accepted if Origin's
              // hostname matches Host's hostname (see authenticate.js).
              'Origin': _baseUrl,
            })
            .enableAutoConnect()
            .enableReconnection()
            .setReconnectionAttempts(10)
            .setReconnectionDelay(2000)
            .build(),
      );

      _socket?.onConnect((_) {
        AppLogger.info('Socket.io connected successfully. Subscribing to user:$_userEmail and employee:$_employeeId', tag: 'SocketService');
        // Subscribe to the Frappe user room (publish_realtime with user= targets this)
        _socket?.emit('subscribe', 'user:$_userEmail');
        // Subscribe to employee notification room
        _socket?.emit('subscribe', 'employee:$_employeeId');
        // Subscribe to all notifications room
        _socket?.emit('subscribe', 'all');
        // Also subscribe using Frappe's task_subscribe for user doctype events
        _socket?.emit('task_subscribe', 'employee:$_employeeId');
      });

      _socket?.onDisconnect((reason) {
        AppLogger.info('Socket.io disconnected: $reason', tag: 'SocketService');
      });

      _socket?.onConnectError((error) {
        AppLogger.error('Socket.io connection error: $error', tag: 'SocketService');
      });

      _socket?.onError((error) {
        AppLogger.error('Socket.io error occurred: $error', tag: 'SocketService');
      });

      // Listen for custom realtime notification events from Frappe
      _socket?.on('new_notification', (data) {
        AppLogger.info('Socket received event [new_notification]', tag: 'SocketService');
        if (data != null && data is Map) {
          final payload = Map<String, dynamic>.from(data);
          onNotificationReceived(payload);
        }
      });

      // Also listen for Frappe's generic publish_realtime events
      _socket?.on('notification', (data) {
        AppLogger.info('Socket received event [notification]', tag: 'SocketService');
        if (data != null && data is Map) {
          final payload = Map<String, dynamic>.from(data);
          onNotificationReceived(payload);
        }
      });

      // Group chat: a new message in one of the caller's groups (publish_realtime
      // targets the recipient's own user:<email> room -- same delivery mechanism
      // as new_notification above, just a separate event name/payload shape).
      _socket?.on('new_group_message', (data) {
        AppLogger.info('Socket received event [new_group_message]', tag: 'SocketService');
        if (data != null && data is Map) {
          onGroupMessageReceived?.call(Map<String, dynamic>.from(data));
        }
      });

      // 1:1 direct chat: same delivery mechanism as new_group_message above,
      // just a distinct event name/payload shape (sender/recipient, not group).
      _socket?.on('new_direct_message', (data) {
        AppLogger.info('Socket received event [new_direct_message]', tag: 'SocketService');
        if (data != null && data is Map) {
          onDirectMessageReceived?.call(Map<String, dynamic>.from(data));
        }
      });

      // Listen for Frappe's event emitter pattern (used by publish_realtime with event name)
      _socket?.on('event', (data) {
        if (data != null && data is Map) {
          final event = data['event']?.toString() ?? '';
          if (event == 'new_notification' || event == 'notification') {
            AppLogger.info('Socket received Frappe event [$event]', tag: 'SocketService');
            final payload = data['message'];
            if (payload != null && payload is Map) {
              onNotificationReceived(Map<String, dynamic>.from(payload));
            }
          }
        }
      });
    } catch (e) {
      AppLogger.error('Failed to initialize Socket.io client: $e', tag: 'SocketService');
    }
  }

  /// Disconnect and dispose client
  void disconnect() {
    if (_socket != null) {
      AppLogger.info('Disconnecting Socket.io client', tag: 'SocketService');
      _socket?.disconnect();
      _socket?.dispose();
      _socket = null;
    }
  }
}
