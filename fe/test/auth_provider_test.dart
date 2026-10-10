// import 'package:fe/core/network/api_client.dart';
// import 'package:fe/core/network/api_exception.dart';
// import 'package:fe/core/storage/token_storage.dart';
// import 'package:fe/features/auth/data/services/auth_service.dart';
// import 'package:fe/features/auth/domain/dtos/login_req.dart';
// import 'package:fe/features/auth/domain/models/auth_res.dart';
// import 'package:fe/features/auth/domain/models/role.dart';
// import 'package:fe/features/auth/domain/models/user_res.dart';
// import 'package:fe/features/auth/presentation/providers/auth_provider.dart';
// import 'package:flutter_test/flutter_test.dart';
//
// class MockTokenStorage implements TokenStorage {
//   String? _at;
//   String? _rt;
//   UserRes? _user;
//
//   @override
//   Future<void> clear() async {
//     _at = null;
//     _rt = null;
//     _user = null;
//   }
//
//   @override
//   Future<String?> getAccessToken() async => _at;
//
//   @override
//   Future<String?> getRefreshToken() async => _rt;
//
//   @override
//   Future<UserRes?> getUser() async => _user;
//
//   @override
//   Future<void> saveTokens({required String accessToken, required String refreshToken}) async {
//     _at = accessToken;
//     _rt = refreshToken;
//   }
//
//   @override
//   Future<void> saveUser(UserRes user) async {
//     _user = user;
//   }
// }
//
// class FakeAuthService extends AuthService {
//   UserRes? mockUser;
//   bool shouldThrow = false;
//   String? lastResentEmail;
//   bool resendShouldThrow = false;
//
//   FakeAuthService() : super(ApiClient());
//
//   @override
//   Future<String> resendCode(String email) async {
//     if (resendShouldThrow) {
//       throw const ApiException('Verification session expired', statusCode: 404);
//     }
//     lastResentEmail = email;
//     return 'Mã xác thực mới đã được gửi đến email.';
//   }
//
//   @override
//   Future<AuthRes> login(LoginReq req) async {
//     if (shouldThrow) {
//       throw const ApiException('Invalid credentials', statusCode: 401);
//     }
//     return AuthRes(
//       accessToken: 'fake_jwt_token',
//       refreshToken: 'fake_refresh_token',
//       user: mockUser ??
//           const UserRes(
//             userId: '1',
//             email: 'user@example.com',
//             role: UserRole.reader,
//           ),
//     );
//   }
// }
//
// void main() {
//   group('AuthProvider Role Isolation & Login', () {
//     late MockTokenStorage tokenStorage;
//     late FakeAuthService authService;
//     late AuthProvider authProvider;
//
//     setUp(() {
//       tokenStorage = MockTokenStorage();
//       authService = FakeAuthService();
//       authProvider = AuthProvider(
//         authService: authService,
//         tokenStorage: tokenStorage,
//       );
//     });
//
//     test('reader login succeeds with reader role', () async {
//       authService.mockUser = const UserRes(
//         userId: '1',
//         email: 'reader@test.com',
//         role: UserRole.reader,
//       );
//
//       final ok = await authProvider.login(
//         username: 'reader@test.com',
//         password: 'password123',
//         expectedRole: UserRole.reader,
//       );
//
//       expect(ok, isTrue);
//       expect(authProvider.isAuthenticated, isTrue);
//       expect(authProvider.currentUser?.role, UserRole.reader);
//       expect(authProvider.accessToken, 'fake_jwt_token');
//     });
//
//     test('reader account trying staff login gets blocked', () async {
//       authService.mockUser = const UserRes(
//         userId: '1',
//         email: 'reader@test.com',
//         role: UserRole.reader,
//       );
//
//       final ok = await authProvider.login(
//         username: 'reader@test.com',
//         password: 'password123',
//         expectedRole: UserRole.staff,
//       );
//
//       expect(ok, isFalse);
//       expect(authProvider.isAuthenticated, isFalse);
//       expect(
//         authProvider.errorMessage,
//         'Tài khoản không có quyền truy cập cổng Nhân viên.',
//       );
//     });
//
//     test('staff account login succeeds on staff portal', () async {
//       authService.mockUser = const UserRes(
//         userId: '2',
//         email: 'staff@thuvien.vn',
//         role: UserRole.staff,
//       );
//
//       final ok = await authProvider.login(
//         username: 'staff@thuvien.vn',
//         password: 'password123',
//         expectedRole: UserRole.staff,
//       );
//
//       expect(ok, isTrue);
//       expect(authProvider.isAuthenticated, isTrue);
//       expect(authProvider.currentUser?.role, UserRole.staff);
//     });
//
//     test('logout clears tokens and user state', () async {
//       authService.mockUser = const UserRes(
//         userId: '2',
//         email: 'staff@thuvien.vn',
//         role: UserRole.staff,
//       );
//       await authProvider.login(
//         username: 'staff@thuvien.vn',
//         password: 'password123',
//         expectedRole: UserRole.staff,
//       );
//
//       await authProvider.logout();
//       expect(authProvider.isAuthenticated, isFalse);
//       expect(authProvider.currentUser, isNull);
//       expect(await tokenStorage.getAccessToken(), isNull);
//     });
//
//     test('resendCode succeeds and clears errorMessage', () async {
//       final ok = await authProvider.resendCode(email: 'reader@test.com');
//       expect(ok, isTrue);
//       expect(authService.lastResentEmail, 'reader@test.com');
//       expect(authProvider.errorMessage, isNull);
//       expect(authProvider.isLoading, isFalse);
//     });
//
//     test('resendCode failure sets errorMessage', () async {
//       authService.resendShouldThrow = true;
//       final ok = await authProvider.resendCode(email: 'expired@test.com');
//       expect(ok, isFalse);
//       expect(authProvider.errorMessage, 'Verification session expired');
//       expect(authProvider.isLoading, isFalse);
//     });
//   });
// }
