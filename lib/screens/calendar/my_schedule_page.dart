import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../theme/theme_provider.dart';
import '../../services/schedule_service.dart';
import '../../services/auth_service.dart';
import '../../screens/event_form_screen.dart';
import '../../screens/profile_screen.dart';
import '../../screens/preference_screen.dart';
import '../../screens/admin_screen.dart';
import 'views/day_view.dart';
import 'views/week_view.dart';
import 'views/month_view.dart';
import 'all_employees_schedule_page.dart';

enum ViewType { day, week, month }

class MySchedulePage extends StatefulWidget {
  const MySchedulePage({super.key});

  @override
  State<MySchedulePage> createState() => _MySchedulePageState();
}

class _MySchedulePageState extends State<MySchedulePage> {
  ViewType _currentView = ViewType.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  final Map<String, Widget Function(BuildContext, DateTime, DateTime?)>
      _viewBuilders = {};

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay; // Initialize view builders
    _viewBuilders['Day'] = (context, focusedDay, selectedDay) => DayView(
        focusedDay: focusedDay,
        selectedDay: selectedDay,
        onDateChanged: _onDateChanged);
    _viewBuilders['Week'] = (context, focusedDay, selectedDay) => WeekView(
        focusedDay: focusedDay,
        selectedDay: selectedDay,
        onDateChanged: _onDateChanged,
        onViewChanged: _switchToDay);
    _viewBuilders['Month'] = (context, focusedDay, selectedDay) => MonthView(
        focusedDay: focusedDay,
        selectedDay: selectedDay,
        onDateChanged: _onDateChanged,
        onViewChanged: _switchToDay); // Load events when the page loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadEventsForCurrentView();
    });
  }

  void _onDateChanged(DateTime focusedDay, DateTime? selectedDay) {
    setState(() {
      _focusedDay = focusedDay;
      _selectedDay = selectedDay;
    });

    // Load appropriate events based on current view
    _loadEventsForCurrentView();
  }

  void _loadEventsForCurrentView() {
    final scheduleService =
        Provider.of<ScheduleService>(context, listen: false);

    switch (_currentView) {
      case ViewType.week:
        final weekStart = scheduleService.getWeekStart(_focusedDay);
        scheduleService.loadEventsForWeek(weekStart);
        break;
      case ViewType.month:
        scheduleService.loadEventsForMonth(_focusedDay.year, _focusedDay.month);
        break;
      case ViewType.day:
        // Day view uses the events already loaded for the month/week
        break;
    }
  }

  void _switchToDay() {
    setState(() {
      _currentView = ViewType.day;
    });
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final userName = authService.currentUser?.name ?? 'User';
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      drawer: _buildDrawer(context),
      appBar: AppBar(
        title: Row(
          children: [
            const Text(
              'My Schedule',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: ThemeProvider.notionBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: ThemeProvider.notionBlue.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircleAvatar(
                      backgroundColor: ThemeProvider.notionBlue,
                      radius: 6,
                      child: Text(
                        userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        userName,
                        style: const TextStyle(
                          fontSize: 11,
                          color: ThemeProvider.notionBlue,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        elevation: 0,
        backgroundColor: isDarkMode ? ThemeProvider.notionBlack : Colors.white,
        foregroundColor: isDarkMode ? Colors.white : ThemeProvider.notionBlack,
        actions: [
          IconButton(
            icon: const Icon(Icons.search_outlined, size: 20),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Search functionality coming soon'),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.add_outlined, size: 20),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const EventFormScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: Icon(
              Provider.of<ThemeProvider>(context).themeMode == ThemeMode.light
                  ? Icons.dark_mode_outlined
                  : Icons.light_mode_outlined,
              size: 20,
            ),
            onPressed: () {
              Provider.of<ThemeProvider>(context, listen: false).toggleTheme();
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      backgroundColor:
          isDarkMode ? ThemeProvider.notionBlack : const Color(0xFFFAFAFA),
      body: Column(
        children: [
          _buildViewSelector(),
          Divider(
              height: 1,
              color: isDarkMode
                  ? const Color(0xFF2D2D2D)
                  : const Color(0xFFE5E5E5)),
          Expanded(
            child: Container(
              color: isDarkMode ? ThemeProvider.notionBlack : Colors.white,
              child: _viewBuilders[_currentView == ViewType.month
                  ? 'Month'
                  : _currentView == ViewType.week
                      ? 'Week'
                      : 'Day']!(context, _focusedDay, _selectedDay),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildViewSelector() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      color: isDarkMode ? ThemeProvider.notionBlack : Colors.white,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      child: Row(
        children: [
          Text(
            DateFormat('MMMM yyyy').format(_focusedDay),
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: isDarkMode ? Colors.white : ThemeProvider.notionBlack,
            ),
          ),
          const Spacer(),
          Container(
            decoration: BoxDecoration(
              color: isDarkMode
                  ? const Color(0xFF2D2D2D)
                  : const Color(0xFFF8F8F8),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                  color: isDarkMode
                      ? const Color(0xFF3D3D3D)
                      : const Color(0xFFE5E5E5)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildViewButton('Day', ViewType.day, Icons.view_day_outlined),
                _buildViewButton(
                    'Week', ViewType.week, Icons.view_week_outlined),
                _buildViewButton(
                    'Month', ViewType.month, Icons.calendar_month_outlined),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildViewButton(String label, ViewType viewType, IconData icon) {
    final isSelected = _currentView == viewType;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () {
        setState(() {
          _currentView = viewType;
        });
        _loadEventsForCurrentView();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
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
              color: isSelected
                  ? Colors.white
                  : (isDarkMode
                      ? const Color(0xFF9CA3AF)
                      : const Color(0xFF6B7280)),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected
                    ? Colors.white
                    : (isDarkMode
                        ? const Color(0xFF9CA3AF)
                        : const Color(0xFF6B7280)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Drawer(
      backgroundColor: isDarkMode ? ThemeProvider.notionBlack : Colors.white,
      elevation: 0,
      child: Column(
        children: [
          // Header with logo
          Container(
            padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
            width: double.infinity,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Image.asset(
                  'assets/logo/Kempenhaeghe_logo.png',
                  height: 40,
                  fit: BoxFit.contain,
                  alignment: Alignment.centerLeft,
                ),
                const SizedBox(height: 20),
                const Divider(height: 1, color: Color(0xFFE5E5E5)),
              ],
            ),
          ),

          // Menu items
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildNotionMenuItem(
                  context,
                  icon: Icons.person_pin_circle_outlined,
                  title: 'My Schedule',
                  isSelected: true,
                  onTap: () {
                    Navigator.pop(context);
                  },
                ),
                _buildNotionMenuItem(
                  context,
                  icon: Icons.groups_outlined,
                  title: 'All Employees',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AllEmployeesSchedulePage(),
                      ),
                    );
                  },
                ),
                _buildNotionMenuItem(
                  context,
                  icon: Icons.event_note_outlined,
                  title: 'Schedule Preferences',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const PreferenceScreen(),
                      ),
                    );
                  },
                ),
                _buildNotionMenuItem(
                  context,
                  icon: Icons.admin_panel_settings_outlined,
                  title: 'Admin Panel',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AdminScreen(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    'PERSONAL',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isDarkMode
                          ? ThemeProvider.notionGray
                          : const Color(0xFF9B9A97),
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                _buildNotionMenuItem(
                  context,
                  icon: Icons.person_outline,
                  title: 'Profile',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ProfileScreen(),
                      ),
                    );
                  },
                ),
                _buildNotionMenuItem(
                  context,
                  icon: Icons.settings_outlined,
                  title: 'Settings',
                  onTap: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Settings coming soon')),
                    );
                  },
                ),
                _buildNotionMenuItem(
                  context,
                  icon: Icons.help_outline,
                  title: 'Help & Support',
                  onTap: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Help coming soon')),
                    );
                  },
                ),
              ],
            ),
          ),

          // Bottom user section
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: isDarkMode
                      ? const Color(0xFF2D2D2D)
                      : const Color(0xFFE5E5E5),
                  width: 1,
                ),
              ),
            ),
            child: InkWell(
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const ProfileScreen()),
                );
              },
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor:
                          ThemeProvider.notionBlue.withOpacity(0.1),
                      radius: 16,
                      child: const Icon(
                        Icons.person_outline,
                        size: 18,
                        color: ThemeProvider.notionBlue,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        Provider.of<AuthService>(context).currentUser?.name ??
                            'User',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: isDarkMode
                              ? Colors.white
                              : ThemeProvider.notionBlack,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Provider.of<ThemeProvider>(context).themeMode ==
                                ThemeMode.light
                            ? Icons.dark_mode_outlined
                            : Icons.light_mode_outlined,
                        size: 18,
                        color: isDarkMode
                            ? ThemeProvider.notionGray
                            : const Color(0xFF6B7280),
                      ),
                      onPressed: () {
                        Provider.of<ThemeProvider>(context, listen: false)
                            .toggleTheme();
                      },
                      style: IconButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(32, 32),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotionMenuItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    bool isSelected = false,
    required VoidCallback onTap,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 1),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDarkMode ? const Color(0xFF2D2D2D) : const Color(0xFFF1F1F0))
              : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected
                  ? (isDarkMode ? Colors.white : ThemeProvider.notionBlack)
                  : (isDarkMode
                      ? ThemeProvider.notionGray
                      : const Color(0xFF6B7280)),
            ),
            const SizedBox(width: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
                color: isSelected
                    ? (isDarkMode ? Colors.white : ThemeProvider.notionBlack)
                    : (isDarkMode
                        ? ThemeProvider.notionGray
                        : const Color(0xFF374151)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
