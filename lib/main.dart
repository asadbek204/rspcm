import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'core/app_snackbar.dart';
import 'providers/theme_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/language_provider.dart';
import 'l10n/app_localizations.dart';
import 'screens/dashboard/dashboard_screen.dart';
import 'screens/dashboard/notifications_screen.dart';
import 'screens/calendar/calendar_screen.dart';
import 'screens/profile/profile_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/exams/exams_list_screen.dart';
import 'screens/teacher/teacher_main_screen.dart';
import 'services/api_service.dart';
import 'widgets/app_drawer.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('ru_RU');
  Intl.defaultLocale = 'ru_RU';

  // Firebase — gracefully skip if google-services.json is not present (dev without Firebase)
  try {
    await Firebase.initializeApp();
  } catch (_) {
    // Firebase not configured — push notifications will be unavailable
  }

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => LanguageProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: 'RSPCM',
          debugShowCheckedModeBanner: false,
          scaffoldMessengerKey: AppSnackbar.messengerKey,
          locale: const Locale('ru', 'RU'),
          supportedLocales: const [Locale('ru', 'RU'), Locale('uz')],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
          ],
          theme: themeProvider.themeData,
          home: const _AuthGate(),
        );
      },
    );
  }
}

class _AuthGate extends StatelessWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        if (authProvider.isLoading) {
          return const _StartupLoadingScreen();
        }
        if (!authProvider.isAuthenticated) return const LoginScreen();
        return authProvider.isTeacher
            ? const TeacherMainScreen()
            : const MainScreen();
      },
    );
  }
}

class _StartupLoadingScreen extends StatelessWidget {
  const _StartupLoadingScreen();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Center(
        child: CircularProgressIndicator(color: theme.primaryColor),
      ),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  int _unreadCount = 0;
  final ApiService _api = ApiService();

  List<String> _titles(BuildContext context) {
    final l = AppLocalizations.of(context);
    return [
      l.appTitle,
      l.navCalendar,
      l.navExams,
      l.navProfile,
    ];
  }

  @override
  void initState() {
    super.initState();
    _loadUnreadCount();
  }

  Future<void> _loadUnreadCount() async {
    try {
      final count = await _api.getUnreadNotificationCount();
      if (mounted) setState(() => _unreadCount = count);
    } catch (_) {}
  }

  void _openNotifications() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const NotificationsScreen()),
    ).then((_) => _loadUnreadCount());
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final List<Widget> screens = [
      DashboardScreen(onTabSelected: (i) => _onItemTapped(i)),
      const CalendarScreen(),
      const ExamsListScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(_titles(context)[_selectedIndex]),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                IconButton(
                  icon: const Icon(Icons.notifications_none_outlined),
                  onPressed: _openNotifications,
                ),
                if (_unreadCount > 0)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: IgnorePointer(
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: Colors.red.shade600,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: theme.scaffoldBackgroundColor,
                            width: 1.5,
                          ),
                        ),
                        constraints:
                            const BoxConstraints(minWidth: 17, minHeight: 17),
                        child: Text(
                          _unreadCount > 99 ? '99+' : '$_unreadCount',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            height: 1,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
      drawer: AppDrawer(onTabSelected: _onItemTapped),
      body: screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 11),
        unselectedLabelStyle: const TextStyle(fontSize: 11),
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.dashboard_outlined),
            activeIcon: const Icon(Icons.dashboard),
            label: AppLocalizations.of(context).navHome,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.calendar_today_outlined),
            activeIcon: const Icon(Icons.calendar_today),
            label: AppLocalizations.of(context).navCalendar,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.fact_check_outlined),
            activeIcon: const Icon(Icons.fact_check),
            label: AppLocalizations.of(context).navExams,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.person_outline),
            activeIcon: const Icon(Icons.person),
            label: AppLocalizations.of(context).navProfile,
          ),
        ],
      ),
    );
  }
}
