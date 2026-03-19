import 'package:bagtrip/core/app_error.dart';
import 'package:bagtrip/core/result.dart';
import 'package:bagtrip/service/agent_service.dart';
import 'package:bagtrip/service/api_client.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockApiClient extends Mock implements ApiClient {}

void main() {
  group('AgentService error mapping', () {
    late MockApiClient mockApiClient;
    late AgentService agentService;

    setUp(() {
      mockApiClient = MockApiClient();
      agentService = AgentService(apiClient: mockApiClient);
    });

    final actionParams = {
      'tripId': 'trip-1',
      'conversationId': 'conv-1',
      'action': <String, dynamic>{'type': 'SELECT', 'itemId': 'item-1'},
    };

    test('chat throws UnimplementedError', () {
      expect(
        () => agentService.chat(
          tripId: 'trip-1',
          conversationId: 'conv-1',
          message: 'Hello',
        ),
        throwsUnimplementedError,
      );
    });

    test('action success returns Result.success with data', () async {
      when(
        () => mockApiClient.post('/agent/actions', data: any(named: 'data')),
      ).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/agent/actions'),
          statusCode: 200,
          data: <String, dynamic>{'status': 'ok', 'result': 'selected'},
        ),
      );

      final result = await agentService.action(
        tripId: actionParams['tripId']! as String,
        conversationId: actionParams['conversationId']! as String,
        action: actionParams['action']! as Map<String, dynamic>,
      );

      expect(result, isA<Success<Map<String, dynamic>>>());
      final data = (result as Success<Map<String, dynamic>>).data;
      expect(data['status'], 'ok');
    });

    test(
      'action with non-200 status returns Result.failure with ServerError',
      () async {
        when(
          () => mockApiClient.post('/agent/actions', data: any(named: 'data')),
        ).thenAnswer(
          (_) async => Response(
            requestOptions: RequestOptions(path: '/agent/actions'),
            statusCode: 500,
            data: {'error': 'Internal server error'},
          ),
        );

        final result = await agentService.action(
          tripId: 'trip-1',
          conversationId: 'conv-1',
          action: <String, dynamic>{'type': 'BOOK'},
        );

        expect(result, isA<Failure<Map<String, dynamic>>>());
        final failure = result as Failure<Map<String, dynamic>>;
        expect(failure.error, isA<ServerError>());
      },
    );

    test(
      'action with unexpected response format returns Result.failure with ServerError',
      () async {
        when(
          () => mockApiClient.post('/agent/actions', data: any(named: 'data')),
        ).thenAnswer(
          (_) async => Response(
            requestOptions: RequestOptions(path: '/agent/actions'),
            statusCode: 200,
            data: 'not a map',
          ),
        );

        final result = await agentService.action(
          tripId: 'trip-1',
          conversationId: 'conv-1',
          action: <String, dynamic>{'type': 'SELECT'},
        );

        expect(result, isA<Failure<Map<String, dynamic>>>());
        final failure = result as Failure<Map<String, dynamic>>;
        expect(failure.error, isA<ServerError>());
      },
    );

    test('DioException maps to Result.failure with NetworkError', () async {
      when(
        () => mockApiClient.post('/agent/actions', data: any(named: 'data')),
      ).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/agent/actions'),
          error: 'Connection timeout',
          type: DioExceptionType.connectionTimeout,
        ),
      );

      final result = await agentService.action(
        tripId: 'trip-1',
        conversationId: 'conv-1',
        action: <String, dynamic>{'type': 'SELECT'},
      );

      expect(result, isA<Failure<Map<String, dynamic>>>());
      final failure = result as Failure<Map<String, dynamic>>;
      expect(failure.error, isA<NetworkError>());
    });

    test(
      'generic exception maps to Result.failure with UnknownError',
      () async {
        when(
          () => mockApiClient.post('/agent/actions', data: any(named: 'data')),
        ).thenThrow(Exception('Something unexpected happened'));

        final result = await agentService.action(
          tripId: 'trip-1',
          conversationId: 'conv-1',
          action: <String, dynamic>{'type': 'BOOK'},
        );

        expect(result, isA<Failure<Map<String, dynamic>>>());
        final failure = result as Failure<Map<String, dynamic>>;
        expect(failure.error, isA<UnknownError>());
      },
    );
  });
}
