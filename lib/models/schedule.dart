class ScheduleActivity {
  final String activity;
  final String date;
  final String? dayOfWeek;
  final String? time;

  ScheduleActivity({
    required this.activity,
    required this.date,
    this.dayOfWeek,
    this.time,
  });

  factory ScheduleActivity.fromJson(Map<String, dynamic> json) {
    return ScheduleActivity(
      activity: json['activity'] ?? '',
      date: json['date'] ?? '',
      dayOfWeek: json['dayOfWeek'],
      time: json['time'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'activity': activity,
      'date': date,
      if (dayOfWeek != null) 'dayOfWeek': dayOfWeek,
      if (time != null) 'time': time,
    };
  }
}

class TimeSlot {
  final String time;
  final int hour;
  final List<ScheduleActivity> activities;

  TimeSlot({
    required this.time,
    required this.hour,
    required this.activities,
  });

  factory TimeSlot.fromJson(Map<String, dynamic> json) {
    return TimeSlot(
      time: json['time'] ?? '',
      hour: json['hour'] ?? 0,
      activities: (json['activities'] as List<dynamic>?)
              ?.map((item) => ScheduleActivity.fromJson(item))
              .toList() ??
          [],
    );
  }

  bool get hasActivities => activities.isNotEmpty;
}

class DaySchedule {
  final String date;
  final String employee;
  final List<TimeSlot> workingHours;
  final int totalActivities;

  DaySchedule({
    required this.date,
    required this.employee,
    required this.workingHours,
    required this.totalActivities,
  });

  factory DaySchedule.fromJson(Map<String, dynamic> json) {
    return DaySchedule(
      date: json['date'] ?? '',
      employee: json['employee'] ?? '',
      workingHours: (json['workingHours'] as List<dynamic>?)
              ?.map((item) => TimeSlot.fromJson(item))
              .toList() ??
          [],
      totalActivities: json['totalActivities'] ?? 0,
    );
  }
}

class WeeklySchedule {
  final String startDate;
  final String employee;
  final Map<String, DayActivities> weekSchedule;
  final int totalDays;

  WeeklySchedule({
    required this.startDate,
    required this.employee,
    required this.weekSchedule,
    required this.totalDays,
  });

  factory WeeklySchedule.fromJson(Map<String, dynamic> json) {
    final weekScheduleData =
        json['weekSchedule'] as Map<String, dynamic>? ?? {};
    final weekSchedule = <String, DayActivities>{};

    weekScheduleData.forEach((date, dayData) {
      weekSchedule[date] = DayActivities.fromJson(dayData);
    });

    return WeeklySchedule(
      startDate: json['startDate'] ?? '',
      employee: json['employee'] ?? '',
      weekSchedule: weekSchedule,
      totalDays: json['totalDays'] ?? 0,
    );
  }
}

class MonthlySchedule {
  final int year;
  final int month;
  final String employee;
  final Map<String, DayActivities> monthSchedule;
  final int totalDays;

  MonthlySchedule({
    required this.year,
    required this.month,
    required this.employee,
    required this.monthSchedule,
    required this.totalDays,
  });

  factory MonthlySchedule.fromJson(Map<String, dynamic> json) {
    final monthScheduleData =
        json['monthSchedule'] as Map<String, dynamic>? ?? {};
    final monthSchedule = <String, DayActivities>{};

    monthScheduleData.forEach((date, dayData) {
      monthSchedule[date] = DayActivities.fromJson(dayData);
    });

    return MonthlySchedule(
      year: json['year'] ?? 0,
      month: json['month'] ?? 0,
      employee: json['employee'] ?? '',
      monthSchedule: monthSchedule,
      totalDays: json['totalDays'] ?? 0,
    );
  }
}

class DayActivities {
  final String dayOfWeek;
  final List<ScheduleActivity> activities;

  DayActivities({
    required this.dayOfWeek,
    required this.activities,
  });

  factory DayActivities.fromJson(Map<String, dynamic> json) {
    return DayActivities(
      dayOfWeek: json['dayOfWeek'] ?? '',
      activities: (json['activities'] as List<dynamic>?)
              ?.map((item) => ScheduleActivity.fromJson(item))
              .toList() ??
          [],
    );
  }

  bool get hasActivities => activities.isNotEmpty;
}
