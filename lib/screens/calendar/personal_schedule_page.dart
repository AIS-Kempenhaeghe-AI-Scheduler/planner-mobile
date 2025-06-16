import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/auth_service.dart';
import '../../services/schedule_service.dart';
import '../../theme/theme_provider.dart';
import 'views/personal_day_view.dart';
import 'views/personal_week_view.dart';
import 'views/personal_month_view.dart';

enum PersonalViewType { day, week, month }

class PersonalSchedulePage extends StatefulWidget {
  const PersonalSchedulePage({super.key});

  @override
  State<PersonalSchedulePage> createState() => _PersonalSchedulePageState();
}

class _PersonalSchedulePageState extends State<PersonalSchedulePage> {
  PersonalViewType _currentView = PersonalViewType.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  final ScheduleService _scheduleService = ScheduleService();

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;

    // Initialize the schedule service with auth token
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authService = Provider.of<AuthService>(context, listen: false);
      _scheduleService.setAuthToken(authService.authToken);
    });
  }

  void _onDateChanged(DateTime focusedDay, DateTime? selectedDay) {
    setState(() {
      _focusedDay = focusedDay;
      _selectedDay = selectedDay;
    });
  }

  void _switchToDay() {
    setState(() {
      _currentView = PersonalViewType.day;
    });
  }

  Widget _buildCurrentView() {
    switch (_currentView) {
      case PersonalViewType.day:
        return PersonalDayView(
          focusedDay: _focusedDay,
          selectedDay: _selectedDay,
          onDateChanged: _onDateChanged,
        );
      case PersonalViewType.week:
        return PersonalWeekView(
          focusedDay: _focusedDay,
          selectedDay: _selectedDay,
          onDateChanged: _onDateChanged,
        );
      case PersonalViewType.month:
        return PersonalMonthView(
          focusedDay: _focusedDay,
          selectedDay: _selectedDay,
          onDateChanged: _onDateChanged,
          onViewChanged: _switchToDay,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);

    if (!authService.isAuthenticated) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('My Schedule'),
          backgroundColor: Colors.white,
          foregroundColor: ThemeProvider.notionBlack,
          elevation: 0,
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.lock_outline,
                size: 64,
                color: Colors.grey,
              ),
              SizedBox(height: 16),
              Text(
                'Please log in to view your schedule',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Text(
              'My Schedule',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: ThemeProvider.notionBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                authService.currentUser?.name ?? 'User',
                style: const TextStyle(
                  fontSize: 12,
                  color: ThemeProvider.notionBlue,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        foregroundColor: ThemeProvider.notionBlack,
        elevation: 0,
        actions: [
          // View type selector
          Container(
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildViewButton('Day', PersonalViewType.day, Icons.view_day),
                _buildViewButton(
                    'Week', PersonalViewType.week, Icons.view_week),
                _buildViewButton(
                    'Month', PersonalViewType.month, Icons.calendar_month),
              ],
            ),
          ),
        ],
      ),
      body: Container(
        color: Colors.white,
        child: _buildCurrentView(),
      ),
    );
  }

  Widget _buildViewButton(
      String label, PersonalViewType viewType, IconData icon) {
    final isSelected = _currentView == viewType;

    return GestureDetector(
      onTap: () {
        setState(() {
          _currentView = viewType;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? ThemeProvider.notionBlue : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? Colors.white : Colors.grey[600],
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: isSelected ? Colors.white : Colors.grey[600],
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
