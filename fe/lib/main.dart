import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

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
import 'features/library/data/services/schedule_api_service.dart';
import 'features/library/presentation/providers/schedule_provider.dart';
import 'features/gate/data/gate_api_service.dart';
import 'features/gate/presentation/gate_provider.dart';
import 'features/dashboard/services/dashboard_api_service.dart';
import 'features/dashboard/providers/dashboard_provider.dart';
import 'routes/app_routes.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');

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
  late final ScheduleProvider _scheduleProvider;
  late final GateProvider _gateProvider;
  late final DashboardProvider _dashboardProvider;

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
    _scheduleProvider = ScheduleProvider(
      service: ScheduleApiService(_apiClient),
    );
    _gateProvider = GateProvider(GateApiService(_apiClient));
    _dashboardProvider = DashboardProvider(
      apiService: DashboardApiService(_apiClient),
    );

    _authProvider.checkAuth();
  }

  @override
  void dispose() {
    _apiClient.close();
    _authProvider.dispose();
    _userProvider.dispose();
    _deviceProvider.dispose();
    _scheduleProvider.dispose();
    _gateProvider.dispose();
    _dashboardProvider.dispose();

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
        ChangeNotifierProvider<ScheduleProvider>.value(
          value: _scheduleProvider,
        ),
        ChangeNotifierProvider<GateProvider>.value(value: _gateProvider),
        ChangeNotifierProvider<DashboardProvider>.value(
          value: _dashboardProvider,
        ),
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
