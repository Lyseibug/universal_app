import 'package:flutter_test/flutter_test.dart';
import 'package:universal_app/core/menu/menu_models.dart';

void main() {
  group('MenuScreen Gating Tests', () {
    test('MenuScreen parses JSON and gates actions correctly', () {
      final json = {
        'screen_key': 'grn_putaway',
        'label': 'GRN Put-Away',
        'route': '/grn-putaway',
        'api_module': 'grn',
        'actions': ['put_away', 'override_capacity'],
        'icon': 'archive'
      };

      final screen = MenuScreen.fromJson(json);

      expect(screen.screenKey, equals('grn_putaway'));
      expect(screen.label, equals('GRN Put-Away'));
      expect(screen.route, equals('/grn-putaway'));
      expect(screen.apiModule, equals('grn'));
      expect(screen.icon, equals('archive'));
      
      // Gating checks
      expect(screen.can('put_away'), isTrue);
      expect(screen.can('override_capacity'), isTrue);
      expect(screen.can('override_suggested_lot'), isFalse);
    });

    test('MenuModule parses screens list successfully', () {
      final json = {
        'module_key': 'receiving',
        'label': 'Receiving',
        'icon': 'inbox',
        'screens': [
          {
            'screen_key': 'grn_putaway',
            'label': 'GRN Put-Away',
            'route': '/grn-putaway',
            'api_module': 'grn',
            'actions': ['put_away']
          }
        ]
      };

      final module = MenuModule.fromJson(json);

      expect(module.moduleKey, equals('receiving'));
      expect(module.label, equals('Receiving'));
      expect(module.icon, equals('inbox'));
      expect(module.screens, hasLength(1));
      expect(module.screens.first.screenKey, equals('grn_putaway'));
      expect(module.screens.first.can('put_away'), isTrue);
    });
  });
}
