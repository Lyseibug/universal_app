import 'package:freezed_annotation/freezed_annotation.dart';

part 'menu_models.freezed.dart';
part 'menu_models.g.dart';

/// The full menu payload returned by `session.get_menu`.
@freezed
class MenuPayload with _$MenuPayload {
  const factory MenuPayload({
    required List<MenuModule> menu,
  }) = _MenuPayload;

  factory MenuPayload.fromJson(Map<String, dynamic> json) =>
      _$MenuPayloadFromJson(json);
}

/// A top-level module section in the dynamic menu.
@freezed
class MenuModule with _$MenuModule {
  const factory MenuModule({
    // ignore: invalid_annotation_target
    @JsonKey(name: 'module_key') required String moduleKey,
    required String label,
    @Default('widgets') String icon,
    required List<MenuScreen> screens,
  }) = _MenuModule;

  factory MenuModule.fromJson(Map<String, dynamic> json) =>
      _$MenuModuleFromJson(json);
}

/// A navigable screen entry inside a [MenuModule].
///
/// The [actions] list controls which buttons are visible on the screen.
/// Action gating is UX-only — the server re-checks via `require_pdt`.
@freezed
class MenuScreen with _$MenuScreen {
  const MenuScreen._();

  const factory MenuScreen({
    // ignore: invalid_annotation_target
    @JsonKey(name: 'screen_key') required String screenKey,
    required String label,
    required String route,
    // ignore: invalid_annotation_target
    @JsonKey(name: 'api_module') required String apiModule,
    @Default([]) List<String> actions,
    String? icon,
  }) = _MenuScreen;

  factory MenuScreen.fromJson(Map<String, dynamic> json) =>
      _$MenuScreenFromJson(json);

  /// Returns `true` if [actionKey] is permitted for the current user.
  bool can(String actionKey) => actions.contains(actionKey);
}
