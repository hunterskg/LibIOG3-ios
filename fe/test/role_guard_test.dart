import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:fe/features/auth/domain/models/role.dart';
import 'package:fe/features/auth/domain/models/user_res.dart';
import 'package:fe/features/auth/presentation/providers/auth_provider.dart';
import 'package:fe/shared/widgets/role_guard.dart';

class _FakeAuthProvider extends ChangeNotifier implements AuthProvider {
  UserRes? _user;

  void setUser(UserRes? user) {
    _user = user;
    notifyListeners();
  }

  @override
  UserRes? get currentUser => _user;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('RoleGuard Widget', () {
    late _FakeAuthProvider fakeAuth;

    setUp(() {
      fakeAuth = _FakeAuthProvider();
    });

    Widget createTestWidget({
      required List<UserRole> allowedRoles,
      required Widget child,
    }) {
      return ChangeNotifierProvider<AuthProvider>.value(
        value: fakeAuth,
        child: MaterialApp(
          home: RoleGuard(
            allowedRoles: allowedRoles,
            child: child,
          ),
        ),
      );
    }

    testWidgets('hiển thị child khi role của user nằm trong allowedRoles', (tester) async {
      fakeAuth.setUser(
        const UserRes(userId: 'u1', email: 'admin@lib.vn', role: UserRole.admin),
      );

      await tester.pumpWidget(
        createTestWidget(
          allowedRoles: [UserRole.admin],
          child: const Text('Admin Dashboard Protected Content'),
        ),
      );

      expect(find.text('Admin Dashboard Protected Content'), findsOneWidget);
      expect(find.text('Từ chối truy cập'), findsNothing);
    });

    testWidgets('hiển thị Từ chối truy cập khi user có role khác allowedRoles', (tester) async {
      fakeAuth.setUser(
        const UserRes(userId: 'u2', email: 'staff@lib.vn', role: UserRole.staff),
      );

      await tester.pumpWidget(
        createTestWidget(
          allowedRoles: [UserRole.admin],
          child: const Text('Admin Dashboard Protected Content'),
        ),
      );

      expect(find.text('Admin Dashboard Protected Content'), findsNothing);
      expect(find.text('Từ chối truy cập'), findsOneWidget);
      expect(find.text('Về trang chủ của tôi'), findsOneWidget);
    });

    testWidgets('hiển thị Từ chối truy cập khi user chưa đăng nhập', (tester) async {
      fakeAuth.setUser(null);

      await tester.pumpWidget(
        createTestWidget(
          allowedRoles: [UserRole.reader],
          child: const Text('Reader Protected Content'),
        ),
      );

      expect(find.text('Reader Protected Content'), findsNothing);
      expect(find.text('Từ chối truy cập'), findsOneWidget);
    });
  });
}
