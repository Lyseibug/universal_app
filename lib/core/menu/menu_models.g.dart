// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'menu_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$MenuPayloadImpl _$$MenuPayloadImplFromJson(Map<String, dynamic> json) =>
    _$MenuPayloadImpl(
      menu: (json['menu'] as List<dynamic>)
          .map((e) => MenuModule.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$$MenuPayloadImplToJson(_$MenuPayloadImpl instance) =>
    <String, dynamic>{
      'menu': instance.menu,
    };

_$MenuModuleImpl _$$MenuModuleImplFromJson(Map<String, dynamic> json) =>
    _$MenuModuleImpl(
      moduleKey: json['module_key'] as String,
      label: json['label'] as String,
      icon: json['icon'] as String? ?? 'widgets',
      screens: (json['screens'] as List<dynamic>)
          .map((e) => MenuScreen.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$$MenuModuleImplToJson(_$MenuModuleImpl instance) =>
    <String, dynamic>{
      'module_key': instance.moduleKey,
      'label': instance.label,
      'icon': instance.icon,
      'screens': instance.screens,
    };

_$MenuScreenImpl _$$MenuScreenImplFromJson(Map<String, dynamic> json) =>
    _$MenuScreenImpl(
      screenKey: json['screen_key'] as String,
      label: json['label'] as String,
      route: json['route'] as String,
      apiModule: json['api_module'] as String,
      actions: (json['actions'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      icon: json['icon'] as String?,
    );

Map<String, dynamic> _$$MenuScreenImplToJson(_$MenuScreenImpl instance) =>
    <String, dynamic>{
      'screen_key': instance.screenKey,
      'label': instance.label,
      'route': instance.route,
      'api_module': instance.apiModule,
      'actions': instance.actions,
      'icon': instance.icon,
    };
