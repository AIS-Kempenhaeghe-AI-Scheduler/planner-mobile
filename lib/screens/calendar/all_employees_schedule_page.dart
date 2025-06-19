import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../theme/theme_provider.dart';
import '../../services/schedule_service.dart';

enum AllEmployeesViewType { day, week, month }

class AllEmployeesSchedulePage extends StatefulWidget {
  const AllEmployeesSchedulePage({super.key});

  @override
  State<AllEmployeesSchedulePage> createState() =>
      _AllEmployeesSchedulePageState();
}

class _AllEmployeesSchedulePageState extends State<AllEmployeesSchedulePage> {
  AllEmployeesViewType _currentView = AllEmployeesViewType.week;
  DateTime _focusedDay = DateTime.now();
  Map<String, dynamic>? _allEmployeesSchedule;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAllEmployeesSchedule();
  }

  Future<void> _loadAllEmployeesSchedule() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final scheduleService =
          Provider.of<ScheduleService>(context, listen: false);

      switch (_currentView) {
        case AllEmployeesViewType.day:
          final dateStr = scheduleService.formatDate(_focusedDay);
          _allEmployeesSchedule =
              await scheduleService.getAllEmployeesDailySchedule(dateStr);
          break;
        case AllEmployeesViewType.week:
          final weekStart = scheduleService.getWeekStart(_focusedDay);
          final startDateStr = scheduleService.formatDate(weekStart);
          _allEmployeesSchedule =
              await scheduleService.getAllEmployeesWeeklySchedule(startDateStr);
          break;
        case AllEmployeesViewType.month:
          _allEmployeesSchedule =
              await scheduleService.getAllEmployeesMonthlySchedule(
                  _focusedDay.year, _focusedDay.month);
          break;
      }
    } catch (e) {
      print('Error loading all employees schedule: $e');
      setState(() {
        _error = 'Failed to load schedule: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'All Employees Schedule',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        backgroundColor: isDarkMode ? ThemeProvider.notionBlack : Colors.white,
        foregroundColor: isDarkMode ? Colors.white : ThemeProvider.notionBlack,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_outlined, size: 20),
            onPressed: _loadAllEmployeesSchedule,
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
              child: _buildScheduleView(),
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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  DateFormat('MMMM yyyy').format(_focusedDay),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color:
                        isDarkMode ? Colors.white : ThemeProvider.notionBlack,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  _getViewDescription(),
                  style: TextStyle(
                    fontSize: 13,
                    color: isDarkMode
                        ? const Color(0xFF9CA3AF)
                        : const Color(0xFF6B7280),
                    fontWeight: FontWeight.w400,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
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
                _buildViewButton(
                    'Day', AllEmployeesViewType.day, Icons.view_day_outlined),
                _buildViewButton('Week', AllEmployeesViewType.week,
                    Icons.view_week_outlined),
                _buildViewButton('Month', AllEmployeesViewType.month,
                    Icons.calendar_month_outlined),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getViewDescription() {
    switch (_currentView) {
      case AllEmployeesViewType.day:
        return DateFormat('EEEE, MMMM d').format(_focusedDay);
      case AllEmployeesViewType.week:
        final weekStart = _getWeekStart(_focusedDay);
        final weekEnd = weekStart.add(const Duration(days: 6));
        return '${DateFormat('MMM d').format(weekStart)} - ${DateFormat('MMM d').format(weekEnd)}';
      case AllEmployeesViewType.month:
        return 'All employees for the month';
    }
  }

  DateTime _getWeekStart(DateTime date) {
    final weekday = date.weekday;
    return date.subtract(Duration(days: weekday - 1));
  }

  Widget _buildViewButton(
      String label, AllEmployeesViewType viewType, IconData icon) {
    final isSelected = _currentView == viewType;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () {
        setState(() {
          _currentView = viewType;
        });
        _loadAllEmployeesSchedule();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? ThemeProvider.notionBlue : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 15,
              color: isSelected
                  ? Colors.white
                  : (isDarkMode
                      ? const Color(0xFF9CA3AF)
                      : const Color(0xFF6B7280)),
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
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

  Widget _buildScheduleView() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: ThemeProvider.notionBlue,
            ),
            SizedBox(height: 16),
            Text(
              'Loading employees schedule...',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF6B7280),
              ),
            ),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              color: Color(0xFFEF4444),
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              'Error loading schedule',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: ThemeProvider.notionBlack,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF6B7280),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadAllEmployeesSchedule,
              style: ElevatedButton.styleFrom(
                backgroundColor: ThemeProvider.notionBlue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_allEmployeesSchedule == null) {
      return const Center(
        child: Text(
          'No schedule data available',
          style: TextStyle(
            fontSize: 14,
            color: Color(0xFF6B7280),
          ),
        ),
      );
    }

    return _buildScheduleContent();
  }

  Widget _buildScheduleContent() {
    switch (_currentView) {
      case AllEmployeesViewType.day:
        return _buildDayView();
      case AllEmployeesViewType.week:
        return _buildWeekView();
      case AllEmployeesViewType.month:
        return _buildMonthView();
    }
  }

  Widget _buildDayView() {
    final daySchedule = _allEmployeesSchedule?['daySchedule'];

    // Handle case where daySchedule might be a String (error message) instead of Map
    if (daySchedule == null ||
        daySchedule is! Map<String, dynamic> ||
        daySchedule.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.schedule_outlined,
              size: 48,
              color: Color(0xFF9CA3AF),
            ),
            SizedBox(height: 16),
            Text(
              'No employees scheduled for this day',
              style: TextStyle(
                fontSize: 16,
                color: Color(0xFF6B7280),
              ),
            ),
          ],
        ),
      );
    } // Get the first day's data (for daily view, there should be only one day)
    final dayData = daySchedule.values.first as Map<String, dynamic>;
    final activities = dayData['activities'] as Map<String, dynamic>? ?? {};
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      child: Column(
        children: [
          // Summary header
          Container(
            margin: const EdgeInsets.all(20),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  ThemeProvider.notionBlue.withOpacity(0.1),
                  ThemeProvider.notionBlue.withOpacity(0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: ThemeProvider.notionBlue.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: ThemeProvider.notionBlue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.today_outlined,
                        color: ThemeProvider.notionBlue,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Today\'s Schedule Overview',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: isDarkMode
                                  ? Colors.white
                                  : ThemeProvider.notionBlack,
                            ),
                          ),
                          Text(
                            DateFormat('EEEE, MMMM d, yyyy')
                                .format(_focusedDay),
                            style: TextStyle(
                              fontSize: 14,
                              color: isDarkMode
                                  ? const Color(0xFF9CA3AF)
                                  : const Color(0xFF6B7280),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildSummaryItem(
                        'Activities',
                        activities.length.toString(),
                        Icons.event_note_outlined,
                        ThemeProvider.notionBlue,
                        isDarkMode,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildSummaryItem(
                        'Total Staff',
                        activities.values
                            .fold<int>(
                                0, (sum, list) => sum + (list as List).length)
                            .toString(),
                        Icons.people_outline,
                        const Color(0xFF10B981),
                        isDarkMode,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildSummaryItem(
                        'Departments',
                        activities.length.toString(),
                        Icons.business_outlined,
                        const Color(0xFFF59E0B),
                        isDarkMode,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Activities list
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: activities.entries.map<Widget>((activityEntry) {
                final activityType = activityEntry.key;
                final employees =
                    List<String>.from(activityEntry.value as List);

                return _buildEnhancedActivityCard(
                    activityType, employees, isDarkMode);
              }).toList(),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildWeekView() {
    final weekSchedule = _allEmployeesSchedule?['weekSchedule'];
    if (weekSchedule == null ||
        weekSchedule is! Map<String, dynamic> ||
        weekSchedule.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.schedule_outlined,
              size: 48,
              color: Color(0xFF9CA3AF),
            ),
            SizedBox(height: 16),
            Text(
              'No schedule data available for this week',
              style: TextStyle(
                fontSize: 16,
                color: Color(0xFF6B7280),
              ),
            ),
          ],
        ),
      );
    }

    // Create a timeline view for the week
    return _buildWeekTimelineView(weekSchedule);
  }

  Widget _buildMonthView() {
    final monthSchedule = _allEmployeesSchedule?['monthSchedule'];
    if (monthSchedule == null ||
        monthSchedule is! Map<String, dynamic> ||
        monthSchedule.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.schedule_outlined,
              size: 48,
              color: Color(0xFF9CA3AF),
            ),
            SizedBox(height: 16),
            Text(
              'No schedule data available for this month',
              style: TextStyle(
                fontSize: 16,
                color: Color(0xFF6B7280),
              ),
            ),
          ],
        ),
      );
    }

    return _buildMonthGridView(monthSchedule);
  }

  Widget _buildMonthGridView(Map<String, dynamic> monthSchedule) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: monthSchedule.entries.map((entry) {
          final dateStr = entry.key;
          final dayData = entry.value;

          // Check if dayData is actually a Map
          if (dayData is! Map<String, dynamic>) {
            return const SizedBox.shrink();
          }

          final date = DateTime.parse(dateStr);
          return _buildMonthDayView(date, dayData);
        }).toList(),
      ),
    );
  }

  Widget _buildMonthDayView(DateTime date, Map<String, dynamic> dayData) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final activities = dayData['activities'] as Map<String, dynamic>? ?? {};

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color:
                isDarkMode ? const Color(0xFF3D3D3D) : const Color(0xFFE5E5E5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDarkMode ? 0.2 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: ThemeProvider.notionBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  DateFormat('EEEE, MMM d').format(date),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: ThemeProvider.notionBlue,
                  ),
                ),
              ),
              const Spacer(),
              if (activities.isNotEmpty)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isDarkMode
                        ? const Color(0xFF2D2D2D)
                        : const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${activities.length} ${activities.length == 1 ? 'activity' : 'activities'}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: isDarkMode
                          ? const Color(0xFF9CA3AF)
                          : const Color(0xFF6B7280),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          if (activities.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDarkMode
                    ? const Color(0xFF2D2D2D)
                    : const Color(0xFFF8F9FA),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.event_busy_outlined,
                    size: 16,
                    color: isDarkMode
                        ? const Color(0xFF6B7280)
                        : const Color(0xFF9CA3AF),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'No activities scheduled',
                    style: TextStyle(
                      fontSize: 13,
                      color: isDarkMode
                          ? const Color(0xFF6B7280)
                          : const Color(0xFF9CA3AF),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            )
          else
            ...activities.entries.map((activityEntry) {
              final activityType = activityEntry.key;
              final employees = List<String>.from(activityEntry.value as List);
              return _buildEnhancedActivityCard(
                  activityType, employees, isDarkMode);
            }).toList(),
        ],
      ),
    );
  }

  Widget _buildWeekTimelineView(Map<String, dynamic> weekSchedule) {
    // Create a timeline view showing each day with activities and assigned employees
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: weekSchedule.length,
      itemBuilder: (context, index) {
        final entry = weekSchedule.entries.elementAt(index);
        final dateStr = entry.key;
        final dayData = entry.value;

        // Check if dayData is actually a Map
        if (dayData is! Map<String, dynamic>) {
          return const SizedBox.shrink();
        }

        final date = DateTime.parse(dateStr);
        return _buildWeekDaySection(date, dayData);
      },
    );
  }

  Widget _buildWeekDaySection(DateTime date, Map<String, dynamic> dayData) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final activities = dayData['activities'] as Map<String, dynamic>? ?? {};

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: ThemeProvider.notionBlue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  DateFormat('EEEE').format(date),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: ThemeProvider.notionBlue,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  DateFormat('MMM d').format(date),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: ThemeProvider.notionBlue,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          if (activities.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: isDarkMode
                        ? const Color(0xFF3D3D3D)
                        : const Color(0xFFE5E5E5)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.event_busy_outlined,
                    size: 16,
                    color: isDarkMode
                        ? const Color(0xFF9CA3AF)
                        : const Color(0xFF9CA3AF),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'No activities scheduled',
                    style: TextStyle(
                      fontSize: 13,
                      color: isDarkMode
                          ? const Color(0xFF9CA3AF)
                          : const Color(0xFF6B7280),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            )
          else
            ...activities.entries.map((activityEntry) {
              final activityType = activityEntry.key;
              final employees = List<String>.from(activityEntry.value as List);

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: isDarkMode
                          ? const Color(0xFF3D3D3D)
                          : const Color(0xFFE5E5E5)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 4,
                          height: 20,
                          decoration: BoxDecoration(
                            color: _getActivityColor(activityType),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            activityType,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: isDarkMode
                                  ? Colors.white
                                  : ThemeProvider.notionBlack,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: _getActivityColor(activityType)
                                .withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${employees.length}',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: _getActivityColor(activityType),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: employees.map((employeeName) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: isDarkMode
                                ? const Color(0xFF2D2D2D)
                                : const Color(0xFFF8F9FA),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            employeeName,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w400,
                              color: isDarkMode
                                  ? const Color(0xFF9CA3AF)
                                  : const Color(0xFF6B7280),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              );
            }).toList(),
        ],
      ),
    );
  }

  Color _getActivityColor(String activityName) {
    switch (activityName.toLowerCase()) {
      case 'activities & therapy':
        return const Color(0xFF3B82F6); // Blue
      case 'meal services':
        return const Color(0xFF10B981); // Green
      case 'medical support':
        return const Color(0xFFEF4444); // Red
      case 'night care':
        return const Color(0xFF8B5CF6); // Purple
      case 'personal care':
        return const Color(0xFFF59E0B); // Orange
      default:
        return const Color(0xFF6B7280); // Gray
    }
  }

  Widget _buildSummaryItem(
    String title,
    String value,
    IconData icon,
    Color color,
    bool isDarkMode,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1F2937) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDarkMode ? const Color(0xFF374151) : const Color(0xFFE5E7EB),
        ),
        boxShadow: [
          BoxShadow(
            color: (isDarkMode ? Colors.black : Colors.grey).withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  size: 16,
                  color: color,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: isDarkMode
                        ? const Color(0xFF9CA3AF)
                        : const Color(0xFF6B7280),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : ThemeProvider.notionBlack,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedActivityCard(
      String activityType, List<String> employees, bool isDarkMode) {
    final activityColor = _getActivityColor(activityType);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1F2937) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDarkMode ? const Color(0xFF374151) : const Color(0xFFE5E7EB),
        ),
        boxShadow: [
          BoxShadow(
            color: (isDarkMode ? Colors.black : Colors.grey).withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: activityColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.work_outline,
                  size: 20,
                  color: activityColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      activityType,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isDarkMode
                            ? Colors.white
                            : ThemeProvider.notionBlack,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${employees.length} employee${employees.length != 1 ? 's' : ''}',
                      style: TextStyle(
                        fontSize: 13,
                        color: isDarkMode
                            ? const Color(0xFF9CA3AF)
                            : const Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: activityColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  employees.length.toString(),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: activityColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Assigned Staff:',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: isDarkMode
                  ? const Color(0xFF9CA3AF)
                  : const Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: employees.map((employee) {
              return Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isDarkMode
                      ? const Color(0xFF374151)
                      : const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isDarkMode
                        ? const Color(0xFF4B5563)
                        : const Color(0xFFE5E7EB),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircleAvatar(
                      radius: 8,
                      backgroundColor: activityColor.withOpacity(0.2),
                      child: Text(
                        employee.isNotEmpty ? employee[0].toUpperCase() : 'U',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: activityColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      employee,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: isDarkMode
                            ? Colors.white
                            : ThemeProvider.notionBlack,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
