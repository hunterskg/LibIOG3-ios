import 'dart:convert';
import 'package:fe/core/network/api_client.dart';
import 'package:fe/features/biometric/data/services/face_biometric_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('RegisterFaceRes status getters', () {
    const successRes = RegisterFaceRes(
      message: 'RegistrationSuccess',
      resultId: 'req-1',
    );
    expect(successRes.isSuccess, isTrue);
    expect(successRes.isInProgress, isFalse);

    const inProgressRes = RegisterFaceRes(
      message: 'RegistrationInProgress',
      resultId: 'req-2',
    );
    expect(inProgressRes.isSuccess, isFalse);
    expect(inProgressRes.isInProgress, isTrue);

    const otherRes = RegisterFaceRes(
      message: 'UnknownStatus',
      resultId: 'req-3',
    );
    expect(otherRes.isSuccess, isFalse);
    expect(otherRes.isInProgress, isFalse);
  });

  test(
    'FaceBiometricService.registerFace sends multipart request and parses response',
    () async {
      final mockClient = MockClient((request) async {
        expect(request.method, 'POST');
        expect(request.url.path, '/biometric/face/register');
        return http.Response(
          jsonEncode({'message': 'RegistrationSuccess', 'resultId': 'res-123'}),
          201,
        );
      });

      final apiClient = ApiClient(
        client: mockClient,
        getAccessToken: () async => 'test-token',
      );
      final service = FaceBiometricService(apiClient);

      final res = await service.registerFace(
        imageBytes: [1, 2, 3],
        requestId: 'req-001',
      );

      expect(res.message, 'RegistrationSuccess');
      expect(res.resultId, 'res-123');
      expect(res.isSuccess, isTrue);
      expect(res.isInProgress, isFalse);
    },
  );

  group('FaceBiometricService.getRegistrationStatus', () {
    test('returns status successfully without readerId', () async {
      final mockClient = MockClient((request) async {
        expect(request.method, 'GET');
        expect(request.url.path, '/biometric/face/status');
        expect(request.url.queryParameters, isEmpty);
        return http.Response(
          jsonEncode({
            'isRegistered': true,
            'status': 'ACTIVE',
            'registeredAt': '2026-10-10T10:00:00.000Z',
            'updatedAt': '2026-10-10T12:00:00.000Z',
          }),
          200,
        );
      });

      final apiClient = ApiClient(
        client: mockClient,
        getAccessToken: () async => 'test-token',
      );
      final service = FaceBiometricService(apiClient);

      final res = await service.getRegistrationStatus();

      expect(res.isRegistered, isTrue);
      expect(res.status, 'ACTIVE');
      expect(res.registeredAt, isNotNull);
      expect(res.updatedAt, isNotNull);
    });

    test('returns status with readerId query param', () async {
      final mockClient = MockClient((request) async {
        expect(request.method, 'GET');
        expect(request.url.path, '/biometric/face/status');
        expect(request.url.queryParameters['readerId'], 'target-uuid');
        return http.Response(
          jsonEncode({
            'isRegistered': false,
          }),
          200,
        );
      });

      final apiClient = ApiClient(
        client: mockClient,
        getAccessToken: () async => 'test-token',
      );
      final service = FaceBiometricService(apiClient);

      final res = await service.getRegistrationStatus(readerId: 'target-uuid');

      expect(res.isRegistered, isFalse);
      expect(res.status, isNull);
    });
  });
}
