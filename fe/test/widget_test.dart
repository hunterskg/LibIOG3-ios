import 'package:fe/core/storage/token_storage.dart';
import 'package:fe/features/auth/domain/models/user_res.dart';
import 'package:fe/main.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeTokenStorage implements TokenStorage {
  String? accessToken;
  String? refreshToken;
  UserRes? user;

  @override
  Future<void> clear() async {
    accessToken = null;
    refreshToken = null;
    user = null;
  }

  @override
  Future<String?> getAccessToken() async => accessToken;

  @override
  Future<String?> getRefreshToken() async => refreshToken;

  @override
  Future<UserRes?> getUser() async => user;

  @override
  Future<void> saveTokens({required String accessToken, required String refreshToken}) async {
    this.accessToken = accessToken;
    this.refreshToken = refreshToken;
  }

  @override
  Future<void> saveUser(UserRes user) async {
    this.user = user;
  }
}

void main() {
  testWidgets('App renders RoleSelectScreen initially', (WidgetTester tester) async {
    final fakeStorage = FakeTokenStorage();
    await tester.pumpWidget(MyApp(tokenStorage: fakeStorage));
    await tester.pumpAndSettle();

    expect(find.text('LibIO — Quản lý Thư viện'), findsOneWidget);
    expect(find.text('Độc giả'), findsOneWidget);
    expect(find.text('Nhân viên'), findsOneWidget);
  });
}
