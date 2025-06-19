import 'package:flutter/material.dart';
import 'my_schedule_page.dart';

class ScheduleHomePage extends StatelessWidget {
  const ScheduleHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    // Immediately redirect to MySchedulePage
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const MySchedulePage(),
        ),
      );
    });

    // Show a loading screen while redirecting
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
