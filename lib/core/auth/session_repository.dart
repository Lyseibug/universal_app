import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';

import '../api/api_client.dart';
import '../menu/menu_models.dart';
import '../utils/logger.dart';
import 'session_models.dart';
import 'token_store.dart';

const _tag = 'SessionRepository';
const _sessionBoxName = 'session';
const _menuBoxName = 'menus';
const _sessionCacheKey = 'cached_session';
const _menuCacheKey = 'cached_menu';

/// Repository managing authorization, active worker sessions, and dynamic menus.
class SessionRepository {
  final ApiClient _api;
  final TokenStore _tokens;

  SessionRepository(this._api, this._tokens);

  Box<dynamic> get _sessionBox => Hive.box<dynamic>(_sessionBoxName);
  Box<dynamic> get _menuBox => Hive.box<dynamic>(_menuBoxName);

  /// Authenticate with the PDT backend and store the session token.
  ///
  /// Returns a list of assigned user roles.
  Future<List<String>> login(String usr, String pwd) async {
    final data = await _api.call('session.login', body: {'usr': usr, 'pwd': pwd});
    final token = data['token'] as String?;
    if (token == null || token.isEmpty) {
      throw Exception('Login did not return a valid API token');
    }
    await _tokens.write(token);
    AppLogger.info('Login successful. Token saved.', tag: _tag);
    return List<String>.from(data['roles'] ?? const []);
  }

  /// List available workstation assignments for the authenticated worker.
  Future<List<WorkspaceModel>> listWorkspaces() async {
    final data = await _api.call('session.list_workspaces');
    final List<dynamic> list;
    if (data is List) {
      list = data;
    } else if (data is Map) {
      list = data['workspaces'] as List<dynamic>? ?? [];
    } else {
      list = [];
    }
    AppLogger.info('listWorkspaces raw response list: $list', tag: _tag);
    final parsed = list
        .map((e) => WorkspaceModel.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
    AppLogger.info('listWorkspaces parsed successfully: $parsed', tag: _tag);
    return parsed;
  }

  /// Select an active workstation assignment.
  ///
  /// Returns and caches the updated [SessionInfo].
  Future<SessionInfo> selectWorkspace(String assignment) async {
    final data = await _api.call('session.select_workspace', body: {'assignment': assignment});
    final session = SessionInfo.fromJson(Map<String, dynamic>.from(data));
    
    // Cache the active session locally for offline startup
    await _sessionBox.put(_sessionCacheKey, jsonEncode(data));
    AppLogger.info('Workspace selected and cached: ${session.workspaceLabel}', tag: _tag);
    return session;
  }

  /// Fetch the dynamic WMS menu for the current worker and workspace.
  ///
  /// Falls back to the Hive-cached menu on network or API failures.
  Future<MenuPayload?> getMenu() async {
    try {
      final data = await _api.call('session.get_menu');
      AppLogger.info('Menu raw API response: $data', tag: _tag);
      final payload = MenuPayload.fromJson(Map<String, dynamic>.from(data));
      
      // Cache the successfully loaded menu
      await _menuBox.put(_menuCacheKey, jsonEncode(data));
      AppLogger.info('Menu fetched and cached (${payload.menu.length} modules)', tag: _tag);
      return payload;
    } catch (e) {
      AppLogger.warning('Menu fetch failed: $e — trying local cache', tag: _tag);
      return _getCachedMenu();
    }
  }

  /// Fetch active session details from the server.
  ///
  /// Falls back to the Hive-cached session info on failure.
  Future<SessionInfo?> getSessionInfo() async {
    try {
      final data = await _api.call('session.get_info');
      final session = SessionInfo.fromJson(Map<String, dynamic>.from(data));
      await _sessionBox.put(_sessionCacheKey, jsonEncode(data));
      return session;
    } catch (e) {
      AppLogger.warning('Session info fetch failed: $e — trying local cache', tag: _tag);
      return _getCachedSession();
    }
  }

  /// Perform logout and clear all local credentials and caches.
  Future<void> logout() async {
    try {
      await _api.call('session.logout');
    } catch (e) {
      AppLogger.warning('Remote logout call failed (non-blocking): $e', tag: _tag);
    } finally {
      await _tokens.clear();
      await _sessionBox.delete(_sessionCacheKey);
      await _menuBox.delete(_menuCacheKey);
      AppLogger.info('Session and menu cache cleared.', tag: _tag);
    }
  }

  /// Retrieve the last active session from the local Hive cache.
  SessionInfo? _getCachedSession() {
    final cached = _sessionBox.get(_sessionCacheKey) as String?;
    if (cached == null) return null;
    try {
      final json = jsonDecode(cached) as Map<String, dynamic>;
      return SessionInfo.fromJson(json);
    } catch (e) {
      AppLogger.warning('Failed to parse cached session: $e', tag: _tag);
      return null;
    }
  }

  /// Retrieve the last loaded menu from the local Hive cache.
  MenuPayload? _getCachedMenu() {
    final cached = _menuBox.get(_menuCacheKey) as String?;
    if (cached == null) return null;
    try {
      final json = jsonDecode(cached) as Map<String, dynamic>;
      return MenuPayload.fromJson(json);
    } catch (e) {
      AppLogger.warning('Failed to parse cached menu: $e', tag: _tag);
      return null;
    }
  }
}
