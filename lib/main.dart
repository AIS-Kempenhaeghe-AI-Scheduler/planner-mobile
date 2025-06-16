import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'screens/calendar/schedule_home_page.dart';
import 'screens/login_screen.dart';
import 'screens/email_entry_screen.dart';
import 'theme/theme_provider.dart';
import 'services/event_manager.dart';
import 'services/user_preference_manager.dart';
import 'services/auth_service.dart';

void main() async {  // Ensure Flutter is initialized before doing any async work
  WidgetsFlutterBinding.ensureInitialized();

  // Check for saved email
  final prefs = await SharedPreferences.getInstance();
  final savedEmail = prefs.getString('savedEmail');

  runApp(
    MultiProvider(
      providers: [        ChangeNotifierProvider(create: (context) => ThemeProvider()),
        ChangeNotifierProvider(create: (context) => EventManager()),
        ChangeNotifierProvider(create: (context) => UserPreferenceManager()),
        // Add the authentication service
        ChangeNotifierProvider(create: (context) => AuthService()),
      ],
      child: KempenhaegeScheduleApp(savedEmail: savedEmail),
    ),
  );
}

class KempenhaegeScheduleApp extends StatelessWidget {
  final String? savedEmail;
  const KempenhaegeScheduleApp({super.key, this.savedEmail});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final authService = Provider.of<AuthService>(context);

    Widget home;
    if (authService.isAuthenticated) {
      home = const ScheduleHomePage();
    } else if (savedEmail != null && savedEmail!.isNotEmpty) {
      home = LoginScreen(prefilledEmail: savedEmail!);
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
