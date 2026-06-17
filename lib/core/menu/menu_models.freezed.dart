// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'menu_models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

MenuPayload _$MenuPayloadFromJson(Map<String, dynamic> json) {
  return _MenuPayload.fromJson(json);
}

/// @nodoc
mixin _$MenuPayload {
  List<MenuModule> get menu => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $MenuPayloadCopyWith<MenuPayload> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $MenuPayloadCopyWith<$Res> {
  factory $MenuPayloadCopyWith(
          MenuPayload value, $Res Function(MenuPayload) then) =
      _$MenuPayloadCopyWithImpl<$Res, MenuPayload>;
  @useResult
  $Res call({List<MenuModule> menu});
}

/// @nodoc
class _$MenuPayloadCopyWithImpl<$Res, $Val extends MenuPayload>
    implements $MenuPayloadCopyWith<$Res> {
  _$MenuPayloadCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? menu = null,
  }) {
    return _then(_value.copyWith(
      menu: null == menu
          ? _value.menu
          : menu // ignore: cast_nullable_to_non_nullable
              as List<MenuModule>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$MenuPayloadImplCopyWith<$Res>
    implements $MenuPayloadCopyWith<$Res> {
  factory _$$MenuPayloadImplCopyWith(
          _$MenuPayloadImpl value, $Res Function(_$MenuPayloadImpl) then) =
      __$$MenuPayloadImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({List<MenuModule> menu});
}

/// @nodoc
class __$$MenuPayloadImplCopyWithImpl<$Res>
    extends _$MenuPayloadCopyWithImpl<$Res, _$MenuPayloadImpl>
    implements _$$MenuPayloadImplCopyWith<$Res> {
  __$$MenuPayloadImplCopyWithImpl(
      _$MenuPayloadImpl _value, $Res Function(_$MenuPayloadImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? menu = null,
  }) {
    return _then(_$MenuPayloadImpl(
      menu: null == menu
          ? _value._menu
          : menu // ignore: cast_nullable_to_non_nullable
              as List<MenuModule>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$MenuPayloadImpl implements _MenuPayload {
  const _$MenuPayloadImpl({required final List<MenuModule> menu})
      : _menu = menu;

  factory _$MenuPayloadImpl.fromJson(Map<String, dynamic> json) =>
      _$$MenuPayloadImplFromJson(json);

  final List<MenuModule> _menu;
  @override
  List<MenuModule> get menu {
    if (_menu is EqualUnmodifiableListView) return _menu;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_menu);
  }

  @override
  String toString() {
    return 'MenuPayload(menu: $menu)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MenuPayloadImpl &&
            const DeepCollectionEquality().equals(other._menu, _menu));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode =>
      Object.hash(runtimeType, const DeepCollectionEquality().hash(_menu));

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$MenuPayloadImplCopyWith<_$MenuPayloadImpl> get copyWith =>
      __$$MenuPayloadImplCopyWithImpl<_$MenuPayloadImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$MenuPayloadImplToJson(
      this,
    );
  }
}

abstract class _MenuPayload implements MenuPayload {
  const factory _MenuPayload({required final List<MenuModule> menu}) =
      _$MenuPayloadImpl;

  factory _MenuPayload.fromJson(Map<String, dynamic> json) =
      _$MenuPayloadImpl.fromJson;

  @override
  List<MenuModule> get menu;
  @override
  @JsonKey(ignore: true)
  _$$MenuPayloadImplCopyWith<_$MenuPayloadImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

MenuModule _$MenuModuleFromJson(Map<String, dynamic> json) {
  return _MenuModule.fromJson(json);
}

/// @nodoc
mixin _$MenuModule {
// ignore: invalid_annotation_target
  @JsonKey(name: 'module_key')
  String get moduleKey => throw _privateConstructorUsedError;
  String get label => throw _privateConstructorUsedError;
  String get icon => throw _privateConstructorUsedError;
  List<MenuScreen> get screens => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $MenuModuleCopyWith<MenuModule> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $MenuModuleCopyWith<$Res> {
  factory $MenuModuleCopyWith(
          MenuModule value, $Res Function(MenuModule) then) =
      _$MenuModuleCopyWithImpl<$Res, MenuModule>;
  @useResult
  $Res call(
      {@JsonKey(name: 'module_key') String moduleKey,
      String label,
      String icon,
      List<MenuScreen> screens});
}

/// @nodoc
class _$MenuModuleCopyWithImpl<$Res, $Val extends MenuModule>
    implements $MenuModuleCopyWith<$Res> {
  _$MenuModuleCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? moduleKey = null,
    Object? label = null,
    Object? icon = null,
    Object? screens = null,
  }) {
    return _then(_value.copyWith(
      moduleKey: null == moduleKey
          ? _value.moduleKey
          : moduleKey // ignore: cast_nullable_to_non_nullable
              as String,
      label: null == label
          ? _value.label
          : label // ignore: cast_nullable_to_non_nullable
              as String,
      icon: null == icon
          ? _value.icon
          : icon // ignore: cast_nullable_to_non_nullable
              as String,
      screens: null == screens
          ? _value.screens
          : screens // ignore: cast_nullable_to_non_nullable
              as List<MenuScreen>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$MenuModuleImplCopyWith<$Res>
    implements $MenuModuleCopyWith<$Res> {
  factory _$$MenuModuleImplCopyWith(
          _$MenuModuleImpl value, $Res Function(_$MenuModuleImpl) then) =
      __$$MenuModuleImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {@JsonKey(name: 'module_key') String moduleKey,
      String label,
      String icon,
      List<MenuScreen> screens});
}

/// @nodoc
class __$$MenuModuleImplCopyWithImpl<$Res>
    extends _$MenuModuleCopyWithImpl<$Res, _$MenuModuleImpl>
    implements _$$MenuModuleImplCopyWith<$Res> {
  __$$MenuModuleImplCopyWithImpl(
      _$MenuModuleImpl _value, $Res Function(_$MenuModuleImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? moduleKey = null,
    Object? label = null,
    Object? icon = null,
    Object? screens = null,
  }) {
    return _then(_$MenuModuleImpl(
      moduleKey: null == moduleKey
          ? _value.moduleKey
          : moduleKey // ignore: cast_nullable_to_non_nullable
              as String,
      label: null == label
          ? _value.label
          : label // ignore: cast_nullable_to_non_nullable
              as String,
      icon: null == icon
          ? _value.icon
          : icon // ignore: cast_nullable_to_non_nullable
              as String,
      screens: null == screens
          ? _value._screens
          : screens // ignore: cast_nullable_to_non_nullable
              as List<MenuScreen>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$MenuModuleImpl implements _MenuModule {
  const _$MenuModuleImpl(
      {@JsonKey(name: 'module_key') required this.moduleKey,
      required this.label,
      this.icon = 'widgets',
      required final List<MenuScreen> screens})
      : _screens = screens;

  factory _$MenuModuleImpl.fromJson(Map<String, dynamic> json) =>
      _$$MenuModuleImplFromJson(json);

// ignore: invalid_annotation_target
  @override
  @JsonKey(name: 'module_key')
  final String moduleKey;
  @override
  final String label;
  @override
  @JsonKey()
  final String icon;
  final List<MenuScreen> _screens;
  @override
  List<MenuScreen> get screens {
    if (_screens is EqualUnmodifiableListView) return _screens;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_screens);
  }

  @override
  String toString() {
    return 'MenuModule(moduleKey: $moduleKey, label: $label, icon: $icon, screens: $screens)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MenuModuleImpl &&
            (identical(other.moduleKey, moduleKey) ||
                other.moduleKey == moduleKey) &&
            (identical(other.label, label) || other.label == label) &&
            (identical(other.icon, icon) || other.icon == icon) &&
            const DeepCollectionEquality().equals(other._screens, _screens));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, moduleKey, label, icon,
      const DeepCollectionEquality().hash(_screens));

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$MenuModuleImplCopyWith<_$MenuModuleImpl> get copyWith =>
      __$$MenuModuleImplCopyWithImpl<_$MenuModuleImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$MenuModuleImplToJson(
      this,
    );
  }
}

abstract class _MenuModule implements MenuModule {
  const factory _MenuModule(
      {@JsonKey(name: 'module_key') required final String moduleKey,
      required final String label,
      final String icon,
      required final List<MenuScreen> screens}) = _$MenuModuleImpl;

  factory _MenuModule.fromJson(Map<String, dynamic> json) =
      _$MenuModuleImpl.fromJson;

  @override // ignore: invalid_annotation_target
  @JsonKey(name: 'module_key')
  String get moduleKey;
  @override
  String get label;
  @override
  String get icon;
  @override
  List<MenuScreen> get screens;
  @override
  @JsonKey(ignore: true)
  _$$MenuModuleImplCopyWith<_$MenuModuleImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

MenuScreen _$MenuScreenFromJson(Map<String, dynamic> json) {
  return _MenuScreen.fromJson(json);
}

/// @nodoc
mixin _$MenuScreen {
// ignore: invalid_annotation_target
  @JsonKey(name: 'screen_key')
  String get screenKey => throw _privateConstructorUsedError;
  String get label => throw _privateConstructorUsedError;
  String get route =>
      throw _privateConstructorUsedError; // ignore: invalid_annotation_target
  @JsonKey(name: 'api_module')
  String get apiModule => throw _privateConstructorUsedError;
  List<String> get actions => throw _privateConstructorUsedError;
  String? get icon => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $MenuScreenCopyWith<MenuScreen> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $MenuScreenCopyWith<$Res> {
  factory $MenuScreenCopyWith(
          MenuScreen value, $Res Function(MenuScreen) then) =
      _$MenuScreenCopyWithImpl<$Res, MenuScreen>;
  @useResult
  $Res call(
      {@JsonKey(name: 'screen_key') String screenKey,
      String label,
      String route,
      @JsonKey(name: 'api_module') String apiModule,
      List<String> actions,
      String? icon});
}

/// @nodoc
class _$MenuScreenCopyWithImpl<$Res, $Val extends MenuScreen>
    implements $MenuScreenCopyWith<$Res> {
  _$MenuScreenCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? screenKey = null,
    Object? label = null,
    Object? route = null,
    Object? apiModule = null,
    Object? actions = null,
    Object? icon = freezed,
  }) {
    return _then(_value.copyWith(
      screenKey: null == screenKey
          ? _value.screenKey
          : screenKey // ignore: cast_nullable_to_non_nullable
              as String,
      label: null == label
          ? _value.label
          : label // ignore: cast_nullable_to_non_nullable
              as String,
      route: null == route
          ? _value.route
          : route // ignore: cast_nullable_to_non_nullable
              as String,
      apiModule: null == apiModule
          ? _value.apiModule
          : apiModule // ignore: cast_nullable_to_non_nullable
              as String,
      actions: null == actions
          ? _value.actions
          : actions // ignore: cast_nullable_to_non_nullable
              as List<String>,
      icon: freezed == icon
          ? _value.icon
          : icon // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$MenuScreenImplCopyWith<$Res>
    implements $MenuScreenCopyWith<$Res> {
  factory _$$MenuScreenImplCopyWith(
          _$MenuScreenImpl value, $Res Function(_$MenuScreenImpl) then) =
      __$$MenuScreenImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {@JsonKey(name: 'screen_key') String screenKey,
      String label,
      String route,
      @JsonKey(name: 'api_module') String apiModule,
      List<String> actions,
      String? icon});
}

/// @nodoc
class __$$MenuScreenImplCopyWithImpl<$Res>
    extends _$MenuScreenCopyWithImpl<$Res, _$MenuScreenImpl>
    implements _$$MenuScreenImplCopyWith<$Res> {
  __$$MenuScreenImplCopyWithImpl(
      _$MenuScreenImpl _value, $Res Function(_$MenuScreenImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? screenKey = null,
    Object? label = null,
    Object? route = null,
    Object? apiModule = null,
    Object? actions = null,
    Object? icon = freezed,
  }) {
    return _then(_$MenuScreenImpl(
      screenKey: null == screenKey
          ? _value.screenKey
          : screenKey // ignore: cast_nullable_to_non_nullable
              as String,
      label: null == label
          ? _value.label
          : label // ignore: cast_nullable_to_non_nullable
              as String,
      route: null == route
          ? _value.route
          : route // ignore: cast_nullable_to_non_nullable
              as String,
      apiModule: null == apiModule
          ? _value.apiModule
          : apiModule // ignore: cast_nullable_to_non_nullable
              as String,
      actions: null == actions
          ? _value._actions
          : actions // ignore: cast_nullable_to_non_nullable
              as List<String>,
      icon: freezed == icon
          ? _value.icon
          : icon // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$MenuScreenImpl extends _MenuScreen {
  const _$MenuScreenImpl(
      {@JsonKey(name: 'screen_key') required this.screenKey,
      required this.label,
      required this.route,
      @JsonKey(name: 'api_module') required this.apiModule,
      final List<String> actions = const [],
      this.icon})
      : _actions = actions,
        super._();

  factory _$MenuScreenImpl.fromJson(Map<String, dynamic> json) =>
      _$$MenuScreenImplFromJson(json);

// ignore: invalid_annotation_target
  @override
  @JsonKey(name: 'screen_key')
  final String screenKey;
  @override
  final String label;
  @override
  final String route;
// ignore: invalid_annotation_target
  @override
  @JsonKey(name: 'api_module')
  final String apiModule;
  final List<String> _actions;
  @override
  @JsonKey()
  List<String> get actions {
    if (_actions is EqualUnmodifiableListView) return _actions;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_actions);
  }

  @override
  final String? icon;

  @override
  String toString() {
    return 'MenuScreen(screenKey: $screenKey, label: $label, route: $route, apiModule: $apiModule, actions: $actions, icon: $icon)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MenuScreenImpl &&
            (identical(other.screenKey, screenKey) ||
                other.screenKey == screenKey) &&
            (identical(other.label, label) || other.label == label) &&
            (identical(other.route, route) || other.route == route) &&
            (identical(other.apiModule, apiModule) ||
                other.apiModule == apiModule) &&
            const DeepCollectionEquality().equals(other._actions, _actions) &&
            (identical(other.icon, icon) || other.icon == icon));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, screenKey, label, route,
      apiModule, const DeepCollectionEquality().hash(_actions), icon);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$MenuScreenImplCopyWith<_$MenuScreenImpl> get copyWith =>
      __$$MenuScreenImplCopyWithImpl<_$MenuScreenImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$MenuScreenImplToJson(
      this,
    );
  }
}

abstract class _MenuScreen extends MenuScreen {
  const factory _MenuScreen(
      {@JsonKey(name: 'screen_key') required final String screenKey,
      required final String label,
      required final String route,
      @JsonKey(name: 'api_module') required final String apiModule,
      final List<String> actions,
      final String? icon}) = _$MenuScreenImpl;
  const _MenuScreen._() : super._();

  factory _MenuScreen.fromJson(Map<String, dynamic> json) =
      _$MenuScreenImpl.fromJson;

  @override // ignore: invalid_annotation_target
  @JsonKey(name: 'screen_key')
  String get screenKey;
  @override
  String get label;
  @override
  String get route;
  @override // ignore: invalid_annotation_target
  @JsonKey(name: 'api_module')
  String get apiModule;
  @override
  List<String> get actions;
  @override
  String? get icon;
  @override
  @JsonKey(ignore: true)
  _$$MenuScreenImplCopyWith<_$MenuScreenImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
