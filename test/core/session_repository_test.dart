import 'package:flutter_test/flutter_test.dart';
import 'package:universal_app/core/api/api_client.dart';
import 'package:universal_app/core/auth/session_models.dart';
import 'package:universal_app/core/auth/session_repository.dart';
import 'package:universal_app/core/auth/token_store.dart';

class FakeApiClient implements ApiClient {
  final List<Map<String, dynamic>> calls = [];
  dynamic responseData;
  Object? errorToThrow;

  @override
  void Function()? get onUnauthenticated => null;

  @override
  void updateBaseUrl(String newUrl) {}

  @override
  Future<dynamic> call(String method, {Map<String, dynamic>? body}) async {
    calls.add({'method': method, 'body': body});
    if (errorToThrow != null) {
      throw errorToThrow!;
    }
    return responseData;
  }
}

class FakeTokenStore implements TokenStore {
  String? token;

  @override
  Future<String?> read() async => token;

  @override
  Future<void> write(String t) async => token = t;

  @override
  Future<void> clear() async => token = null;
}

void main() {
  group('SessionRepository Tests', () {
    late FakeApiClient fakeApi;
    late FakeTokenStore fakeTokens;
    late SessionRepository repo;

    setUp(() {
      fakeApi = FakeApiClient();
      fakeTokens = FakeTokenStore();
      repo = SessionRepository(fakeApi, fakeTokens);
    });

    test('listWorkspaces handles response when data is a List directly', () async {
      fakeApi.responseData = [
        {
          'assignment': 'assign-1',
          'label': 'Workstation 1',
          'warehouse': 'WH-A',
          'supervisor': 'supervisor-1',
          'supervisor_name': 'Supervisor One'
        },
        {
          'assignment': 'assign-2',
          'label': 'Workstation 2',
          'warehouse': 'WH-B',
          'supervisor': 'supervisor-2',
          'supervisor_name': 'Supervisor Two'
        }
      ];

      final result = await repo.listWorkspaces();

      expect(result, hasLength(2));
      expect(result[0].assignment, equals('assign-1'));
      expect(result[0].label, equals('Workstation 1'));
      expect(result[1].assignment, equals('assign-2'));
      expect(result[1].label, equals('Workstation 2'));
    });

    test('listWorkspaces handles response when data is a Map containing workspaces key', () async {
      fakeApi.responseData = {
        'workspaces': [
          {
            'assignment': 'assign-1',
            'label': 'Workstation 1',
            'warehouse': 'WH-A',
            'supervisor': 'supervisor-1',
            'supervisor_name': 'Supervisor One'
          }
        ]
      };

      final result = await repo.listWorkspaces();

      expect(result, hasLength(1));
      expect(result[0].assignment, equals('assign-1'));
    });

    test('listWorkspaces handles response when assignment and label keys are named name, id, workspace_label, or workspace', () async {
      fakeApi.responseData = [
        {
          'name': 'assign-name',
          'workspace_label': 'Workstation Label Name',
          'warehouse': 'WH-A',
        },
        {
          'id': 'assign-id',
          'workspace': 'Workstation Workspace Name',
          'warehouse': 'WH-B',
        }
      ];

      final result = await repo.listWorkspaces();

      expect(result, hasLength(2));
      expect(result[0].assignment, equals('assign-name'));
      expect(result[0].label, equals('Workstation Label Name'));
      expect(result[1].assignment, equals('assign-id'));
      expect(result[1].label, equals('Workstation Workspace Name'));
    });
  });
}
