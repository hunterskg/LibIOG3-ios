import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/constants/api_constants.dart';
import 'core/constants/route_constants.dart';
import 'core/network/api_client.dart';
import 'core/storage/token_storage.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/data/services/auth_service.dart';
import 'features/auth/domain/models/role.dart';
import 'features/auth/presentation/providers/auth_provider.dart';
import 'features/biometric/data/services/face_biometric_service.dart';
import 'features/user/data/services/user_api_service.dart';
import 'features/user/presentation/providers/user_provider.dart';
import 'features/device/data/services/device_api_service.dart';
import 'features/device/presentation/providers/device_provider.dart';
import 'routes/app_routes.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final tokenStorage = await SharedPreferencesTokenStorage.create();

  runApp(MyApp(tokenStorage: tokenStorage));
}

class MyApp extends StatefulWidget {
  final TokenStorage tokenStorage;

  const MyApp({super.key, required this.tokenStorage});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final ApiClient _apiClient;
  late final AuthService _authService;
  late final AuthProvider _authProvider;
  late final FaceBiometricService _faceBiometricService;
  late final UserApiService _userApiService;
  late final UserProvider _userProvider;
  late final DeviceProvider _deviceProvider;

  @override
  void initState() {
    super.initState();

    _apiClient = ApiClient(
      baseUrl: ApiConstants.baseUrl,
      getAccessToken: () async => _authProvider.accessToken,
    );

    _authService = AuthService(_apiClient);

    _authProvider = AuthProvider(
      authService: _authService,
      tokenStorage: widget.tokenStorage,
    );
    _faceBiometricService = FaceBiometricService(_apiClient);
    _userApiService = UserApiService(_apiClient);
    _userProvider = UserProvider(
      apiService: _userApiService,
      faceBiometricService: _faceBiometricService,
    );
    _deviceProvider = DeviceProvider(service: DeviceApiService(_apiClient));

    _authProvider.checkAuth();
  }

  @override
  void dispose() {
    _apiClient.close();
    _authProvider.dispose();
    _userProvider.dispose();
    _deviceProvider.dispose();

    super.dispose();
  }

  String _getInitialRoute(AuthProvider auth) {
    if (!auth.isAuthenticated) {
      return AppRoutes.roleSelect;
    }

    switch (auth.currentUser?.role) {
      case UserRole.reader:
        return AppRoutes.readerHome;
      case UserRole.staff:
        return AppRoutes.staffHome;
      case UserRole.admin:
        return AppRoutes.adminHome;
      case UserRole.device:
        return AppRoutes.deviceHome;
      default:
        return AppRoutes.roleSelect;
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<ApiClient>.value(value: _apiClient),
        ChangeNotifierProvider<AuthProvider>.value(value: _authProvider),
        ChangeNotifierProvider<UserProvider>.value(value: _userProvider),
        ChangeNotifierProvider<DeviceProvider>.value(value: _deviceProvider),
      ],
      child: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: appLightTheme,
            darkTheme: appDarkTheme,
            themeMode: ThemeMode.light,
            initialRoute: _getInitialRoute(auth),
            routes: appRoutes,
          );
        },
      ),
    );
  }
}
