import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'screens/calendar/my_schedule_page.dart';
import 'screens/login_screen_new.dart';
import 'screens/email_entry_screen.dart';
import 'theme/theme_provider.dart';
import 'services/schedule_service.dart';
import 'services/user_preference_manager.dart';
import 'services/auth_service.dart';

void main() async {
  // Ensure Flutter is initialized before doing any async work
  WidgetsFlutterBinding.ensureInitialized();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => ThemeProvider()),
        ChangeNotifierProvider(create: (context) => AuthService()),
        ChangeNotifierProxyProvider<AuthService, ScheduleService>(
          create: (context) => ScheduleService()
            ..setAuthToken(
                Provider.of<AuthService>(context, listen: false).authToken),
          update: (context, authService, previous) {
            final service = previous ?? ScheduleService();
            service.setAuthToken(authService.authToken);
            return service;
          },
        ),
        ChangeNotifierProvider(create: (context) => UserPreferenceManager()),
      ],
      child: const KempenhaegeScheduleApp(),
    ),
  );
}

class KempenhaegeScheduleApp extends StatefulWidget {
  const KempenhaegeScheduleApp({super.key});

  @override
  State<KempenhaegeScheduleApp> createState() => _KempenhaegeScheduleAppState();
}

class _KempenhaegeScheduleAppState extends State<KempenhaegeScheduleApp> {
  String? _savedEmail;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSavedEmail();
  }

  Future<void> _loadSavedEmail() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _savedEmail = prefs.getString('savedEmail');
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return MaterialApp(
        home: Scaffold(
          body: Center(
            child: const CircularProgressIndicator(),
          ),
        ),
      );
    }

    final themeProvider = Provider.of<ThemeProvider>(context);
    final authService = Provider.of<AuthService>(context);
    Widget home;
    if (authService.isAuthenticated) {
      home = const MySchedulePage();
    } else if (_savedEmail != null && _savedEmail!.isNotEmpty) {
      home = NewLoginScreen(prefilledEmail: _savedEmail!);
    } else {
      home = const EmailEntryScreen();
    }

    return MaterialApp(
      title: 'Kempenhaege Schedule',
      debugShowCheckedModeBanner: false,
      theme: themeProvider.lightTheme,
      darkTheme: themeProvider.darkTheme,
      themeMode: themeProvider.themeMode,
      home: home,
    );
  }
}
