import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../theme/theme_provider.dart';
import '../../services/schedule_service.dart';
import '../../screens/event_form_screen.dart';
import '../../screens/profile_screen.dart';
import '../../screens/preference_screen.dart';
import '../../screens/admin_screen.dart';
import 'views/day_view.dart';
import 'views/week_view.dart';
import 'views/month_view.dart';
import 'personal_schedule_page.dart';

enum ViewType { day, week, month }

class ScheduleHomePage extends StatefulWidget {
  const ScheduleHomePage({super.key});

  @override
  State<ScheduleHomePage> createState() => _ScheduleHomePageState();
}

class _ScheduleHomePageState extends State<ScheduleHomePage> {
  ViewType _currentView = ViewType.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  final Map<String, Widget Function(BuildContext, DateTime, DateTime?)>
      _viewBuilders = {};

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;

    // Initialize view builders
    _viewBuilders['Day'] = (context, focusedDay, selectedDay) => DayView(
        focusedDay: focusedDay,
        selectedDay: selectedDay,
        onDateChanged: _onDateChanged);
    _viewBuilders['Week'] = (context, focusedDay, selectedDay) => WeekView(
        focusedDay: focusedDay,
        selectedDay: selectedDay,
        onDateChanged: _onDateChanged);
    _viewBuilders['Month'] = (context, focusedDay, selectedDay) => MonthView(
        focusedDay: focusedDay,
        selectedDay: selectedDay,
        onDateChanged: _onDateChanged,
        onViewChanged:
            _switchToDay); // Load events from backend when app starts
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
    return Scaffold(
      drawer: _buildDrawer(context),
      appBar: AppBar(
        title: const Text(
          'Kempenhaege',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Search functionality coming soon'),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.add),
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
                  ? Icons.dark_mode
                  : Icons.light_mode,
            ),
            onPressed: () {
              Provider.of<ThemeProvider>(context, listen: false).toggleTheme();
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          _buildViewSelector(),
          const Divider(height: 1),
          Expanded(
            child: _viewBuilders[_currentView == ViewType.month
                ? 'Month'
                : _currentView == ViewType.week
                    ? 'Week'
                    : 'Day']!(context, _focusedDay, _selectedDay),
          ),
        ],
      ),
    );
  }

  Widget _buildViewSelector() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
      child: Row(
        children: [
          Text(
            DateFormat('MMMM yyyy').format(_focusedDay),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const Spacer(),
          SizedBox(
            width: 240, // Fixed width for the segmented button
            child: SegmentedButton<ViewType>(
              segments: const [
                ButtonSegment<ViewType>(
                  value: ViewType.day,
                  label: Text('Day'),
                ),
                ButtonSegment<ViewType>(
                  value: ViewType.week,
                  label: Text('Week'),
                ),
                ButtonSegment<ViewType>(
                  value: ViewType.month,
                  label: Text('Month'),
                ),
              ],
              selected: {_currentView},
              onSelectionChanged: (Set<ViewType> selection) {
                setState(() {
                  _currentView = selection.first;
                });
                // Load events for the new view
                _loadEventsForCurrentView();
              },
              style: ButtonStyle(
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: const VisualDensity(horizontal: 0, vertical: 0),
                padding: const MaterialStatePropertyAll<EdgeInsets>(
                    EdgeInsets.symmetric(horizontal: 4)),
                // Set a fixed width for each segment
                fixedSize: MaterialStatePropertyAll<Size>(Size(70, 36)),
                // Add specific styles for the checkmark icon
                iconSize: const MaterialStatePropertyAll<double>(16.0),
                iconColor:
                    MaterialStatePropertyAll<Color>(ThemeProvider.notionBlue),
              ),
            ),
          ),
        ],
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
            padding: const EdgeInsets.fromLTRB(16, 48, 16, 16),
            width: double.infinity,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Image.asset(
                  'assets/logo/Kempenhaeghe_logo.png',
                  height: 50,
                  fit: BoxFit.contain,
                  alignment: Alignment.centerLeft,
                ),
                const SizedBox(height: 16),
                const Divider(height: 1),
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
                  icon: Icons.schedule,
                  title: 'Schedule',
                  isSelected: true,
                  onTap: () {
                    Navigator.pop(context);
                  },
                ),
                _buildNotionMenuItem(
                  context,
                  icon: Icons.person_pin_circle_outlined,
                  title: 'My Schedule',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const PersonalSchedulePage(),
                      ),
                    );
                  },
                ),
                _buildNotionMenuItem(
                  context,
                  icon: Icons.calendar_today,
                  title: 'Calendar',
                  onTap: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Calendar view coming soon'),
                      ),
                    );
                  },
                ),
                _buildNotionMenuItem(
                  context,
                  icon: Icons.people_outline,
                  title: 'Meetings',
                  onTap: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Meetings feature coming soon'),
                      ),
                    );
                  },
                ),
                _buildNotionMenuItem(
                  context,
                  icon: Icons.event_note,
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
                  icon: Icons.task_alt,
                  title: 'Tasks',
                  onTap: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Tasks feature coming soon'),
                      ),
                    );
                  },
                ),
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
                  icon: Icons.admin_panel_settings,
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
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Text(
                    'PERSONAL',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: isDarkMode
                          ? ThemeProvider.notionGray
                          : const Color(0xFF9B9A97),
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                _buildNotionMenuItem(
                  context,
                  icon: Icons.bookmark_border,
                  title: 'Favorites',
                  onTap: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Favorites feature coming soon'),
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
                  title: 'Help',
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

          // Bottom section
          InkWell(
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfileScreen()),
              );
            },
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: ThemeProvider.notionBlue.withOpacity(0.2),
                    radius: 14,
                    child: const Icon(
                      Icons.person_outline,
                      size: 18,
                      color: ThemeProvider.notionBlue,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'User',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color:
                          isDarkMode ? Colors.white : ThemeProvider.notionBlack,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: Icon(
                      Provider.of<ThemeProvider>(context).themeMode ==
                              ThemeMode.light
                          ? Icons.dark_mode_outlined
                          : Icons.light_mode_outlined,
                      size: 20,
                    ),
                    onPressed: () {
                      Provider.of<ThemeProvider>(
                        context,
                        listen: false,
                      ).toggleTheme();
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
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDarkMode ? const Color(0xFF2D2D2D) : const Color(0xFFF1F1F0))
              : Colors.transparent,
          borderRadius: BorderRadius.circular(3),
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
                      : const Color(0xFF9B9A97)),
            ),
            const SizedBox(width: 10),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
                color: isSelected
                    ? (isDarkMode ? Colors.white : ThemeProvider.notionBlack)
                    : (isDarkMode
                        ? ThemeProvider.notionGray
                        : const Color(0xFF37352F)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
