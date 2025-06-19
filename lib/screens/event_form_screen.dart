import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:provider/provider.dart';
import '../models/event.dart';
import '../theme/theme_provider.dart';
import '../services/schedule_service.dart';

class EventFormScreen extends StatefulWidget {
  final Event? event;
  final DateTime? initialDate;

  const EventFormScreen({super.key, this.event, this.initialDate});

  @override
  State<EventFormScreen> createState() => _EventFormScreenState();
}

class _EventFormScreenState extends State<EventFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _attendeesController = TextEditingController();

  late DateTime _startDate;
  late TimeOfDay _startTime;
  late DateTime _endDate;
  late TimeOfDay _endTime;
  Color _selectedColor = Colors.blue;
  bool _isAllDay = false;
  String? _recurrenceRule;
  bool _isSaving = false;
  String? _errorMessage;

  final List<Color> _colorOptions = [
    Colors.blue,
    Colors.red,
    Colors.green,
    Colors.orange,
    Colors.purple,
    Colors.teal,
    Colors.indigo,
    Colors.pink,
  ];

  final List<String> _recurrenceOptions = [
    'None',
    'Daily',
    'Weekly',
    'Monthly',
    'Yearly',
  ];

  @override
  void initState() {
    super.initState();

    // Initialize with existing event or default values
    if (widget.event != null) {
      _titleController.text = widget.event!.title;
      _descriptionController.text = widget.event!.description;
      _locationController.text = widget.event!.location;
      _attendeesController.text = widget.event!.attendees.join(', ');
      _startDate = widget.event!.startTime;
      _startTime = TimeOfDay.fromDateTime(widget.event!.startTime);
      _endDate = widget.event!.endTime;
      _endTime = TimeOfDay.fromDateTime(widget.event!.endTime);
      _selectedColor = widget.event!.color;
      _isAllDay = widget.event!.isAllDay;
      _recurrenceRule = widget.event!.recurrenceRule;
    } else {
      // Use provided initial date or current date
      final initialDate = widget.initialDate ?? DateTime.now();

      // Default to current hour rounded up to nearest hour
      final currentTime = TimeOfDay.now();
      final hour = currentTime.hour + (currentTime.minute > 0 ? 1 : 0);

      _startDate = initialDate;
      _startTime = TimeOfDay(hour: hour % 24, minute: 0);

      // End time is 1 hour after start time
      _endDate = initialDate;
      _endTime = TimeOfDay(hour: (hour + 1) % 24, minute: 0);

      _recurrenceRule = 'None';
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _attendeesController.dispose();
    super.dispose();
  }

  DateTime _combineDateAndTime(DateTime date, TimeOfDay time) {
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  Future<void> _selectDate(BuildContext context, bool isStart) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStart ? _startDate : _endDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: ThemeProvider.notionBlue,
              onPrimary: Colors.white,
              surface: Theme.of(context).cardColor,
              onSurface: Theme.of(context).textTheme.bodyLarge!.color!,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
          // If end date is before start date, update it
          if (_endDate.isBefore(_startDate)) {
            _endDate = _startDate;
          }
        } else {
          _endDate = picked;
        }
      });
    }
  }

  Future<void> _selectTime(BuildContext context, bool isStart) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: isStart ? _startTime : _endTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: ThemeProvider.notionBlue,
              onPrimary: Colors.white,
              surface: Theme.of(context).cardColor,
              onSurface: Theme.of(context).textTheme.bodyLarge!.color!,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isStart) {
          _startTime = picked;

          // If start and end dates are the same and end time is before start time
          if (_startDate.year == _endDate.year &&
              _startDate.month == _endDate.month &&
              _startDate.day == _endDate.day &&
              (_endTime.hour < _startTime.hour ||
                  (_endTime.hour == _startTime.hour &&
                      _endTime.minute < _startTime.minute))) {
            // Set end time to be 1 hour after start time
            _endTime = TimeOfDay(
              hour: (_startTime.hour + 1) % 24,
              minute: _startTime.minute,
            );
          }
        } else {
          _endTime = picked;
        }
      });
    }
  }

  Future<void> _saveEvent() async {
    if (_formKey.currentState!.validate()) {
      // Set loading state
      setState(() {
        _isSaving = true;
        _errorMessage = null;
      });

      try {
        // Create start and end DateTime objects
        final startDateTime = _isAllDay
            ? DateTime(_startDate.year, _startDate.month, _startDate.day)
            : _combineDateAndTime(_startDate, _startTime);

        final endDateTime = _isAllDay
            ? DateTime(
                _endDate.year,
                _endDate.month,
                _endDate.day,
                23,
                59,
                59,
              )
            : _combineDateAndTime(_endDate, _endTime);

        // Parse attendees from comma-separated string
        final attendees = _attendeesController.text.isEmpty
            ? <String>[]
            : _attendeesController.text
                .split(',')
                .map((e) => e.trim())
                .toList();

        // Create new event or update existing one
        final event = widget.event?.copyWith(
              title: _titleController.text,
              description: _descriptionController.text,
              startTime: startDateTime,
              endTime: endDateTime,
              color: _selectedColor,
              isAllDay: _isAllDay,
              attendees: attendees,
              location: _locationController.text,
              recurrenceRule:
                  _recurrenceRule == 'None' ? null : _recurrenceRule,
            ) ??
            Event(
              id: const Uuid().v4(),
              title: _titleController.text,
              description: _descriptionController.text,
              startTime: startDateTime,
              endTime: endDateTime,
              color: _selectedColor,
              isAllDay: _isAllDay,
              attendees: attendees,
              location: _locationController.text,
              recurrenceRule:
                  _recurrenceRule == 'None' ? null : _recurrenceRule,
            );

        // Save event to backend via ScheduleService
        final scheduleService =
            Provider.of<ScheduleService>(context, listen: false);
        final success = widget.event == null
            ? await scheduleService.addEvent(event)
            : await scheduleService.updateEvent(event);

        // Handle result
        if (success) {
          // Return the saved event to the calling screen
          Navigator.of(context).pop(event);
        } else {
          // Show error message
          setState(() {
            _errorMessage = scheduleService.error ?? 'Failed to save event';
            _isSaving = false;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_errorMessage!),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        // Handle any exceptions
        setState(() {
          _errorMessage = 'An error occurred: $e';
          _isSaving = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_errorMessage!), backgroundColor: Colors.red),
        );
      }
    }
  }

  Widget _buildNotionTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    bool autofocus = false,
    String? Function(String?)? validator,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: isDarkMode ? ThemeProvider.notionGray : Colors.grey[700],
              ),
            ),
          ),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          autofocus: autofocus,
          keyboardType: keyboardType,
          validator: validator,
          style: TextStyle(
            fontSize: maxLines > 1 ? 14 : 15,
            color: isDarkMode ? Colors.white : ThemeProvider.notionBlack,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: isDarkMode ? Colors.grey[600] : Colors.grey[400],
            ),
            filled: true,
            fillColor:
                isDarkMode ? ThemeProvider.notionDarkGray : Colors.grey[100],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 14,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final dateFormat = DateFormat('EEE, MMM d, yyyy');

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          widget.event == null ? 'Create Event' : 'Edit Event',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        actions: [
          _isSaving
              ? Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: ThemeProvider.notionBlue,
                    ),
                  ),
                )
              : TextButton(
                  onPressed: _saveEvent,
                  child: Text(
                    'Save',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: ThemeProvider.notionBlue,
                    ),
                  ),
                ),
        ],
        elevation: 0,
        centerTitle: false,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            // Title
            _buildNotionTextField(
              controller: _titleController,
              label: 'TITLE',
              hint: 'Event title',
              autofocus: widget.event == null,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a title';
                }
                return null;
              },
            ),

            const SizedBox(height: 24.0),

            // Date & Time Selection
            Text(
              'DATE & TIME',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: isDarkMode ? ThemeProvider.notionGray : Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8.0),

            // All Day Toggle
            Container(
              decoration: BoxDecoration(
                color: isDarkMode
                    ? ThemeProvider.notionDarkGray
                    : Colors.grey[100],
                borderRadius: BorderRadius.circular(4),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: Row(
                children: [
                  Text(
                    'All day',
                    style: TextStyle(
                      fontSize: 15,
                      color:
                          isDarkMode ? Colors.white : ThemeProvider.notionBlack,
                    ),
                  ),
                  const Spacer(),
                  Switch(
                    value: _isAllDay,
                    onChanged: (value) {
                      setState(() {
                        _isAllDay = value;
                      });
                    },
                    activeColor: ThemeProvider.notionBlue,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8.0),

            // Start Date & Time
            InkWell(
              onTap: () => _selectDate(context, true),
              child: Container(
                decoration: BoxDecoration(
                  color: isDarkMode
                      ? ThemeProvider.notionDarkGray
                      : Colors.grey[100],
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(4),
                    topRight: Radius.circular(4),
                  ),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 14,
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 18,
                      color: ThemeProvider.notionBlue,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Start: ${dateFormat.format(_startDate)}',
                      style: TextStyle(
                        fontSize: 15,
                        color: isDarkMode
                            ? Colors.white
                            : ThemeProvider.notionBlack,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const Divider(height: 1),

            if (!_isAllDay)
              InkWell(
                onTap: () => _selectTime(context, true),
                child: Container(
                  decoration: BoxDecoration(
                    color: isDarkMode
                        ? ThemeProvider.notionDarkGray
                        : Colors.grey[100],
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 14,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 18,
                        color: ThemeProvider.notionBlue,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Time: ${_startTime.format(context)}',
                        style: TextStyle(
                          fontSize: 15,
                          color: isDarkMode
                              ? Colors.white
                              : ThemeProvider.notionBlack,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            const Divider(height: 1),

            // End Date & Time
            InkWell(
              onTap: () => _selectDate(context, false),
              child: Container(
                decoration: BoxDecoration(
                  color: isDarkMode
                      ? ThemeProvider.notionDarkGray
                      : Colors.grey[100],
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 14,
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 18,
                      color: ThemeProvider.notionBlue,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'End: ${dateFormat.format(_endDate)}',
                      style: TextStyle(
                        fontSize: 15,
                        color: isDarkMode
                            ? Colors.white
                            : ThemeProvider.notionBlack,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            if (!_isAllDay)
              Column(
                children: [
                  const Divider(height: 1),
                  InkWell(
                    onTap: () => _selectTime(context, false),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isDarkMode
                            ? ThemeProvider.notionDarkGray
                            : Colors.grey[100],
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(4),
                          bottomRight: Radius.circular(4),
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 14,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 18,
                            color: ThemeProvider.notionBlue,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Time: ${_endTime.format(context)}',
                            style: TextStyle(
                              fontSize: 15,
                              color: isDarkMode
                                  ? Colors.white
                                  : ThemeProvider.notionBlack,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

            const SizedBox(height: 24.0),

            // Location
            _buildNotionTextField(
              controller: _locationController,
              label: 'LOCATION',
              hint: 'Add location',
            ),

            const SizedBox(height: 24.0),

            // Description
            _buildNotionTextField(
              controller: _descriptionController,
              label: 'DESCRIPTION',
              hint: 'Add a description...',
              maxLines: 5,
              keyboardType: TextInputType.multiline,
            ),

            const SizedBox(height: 24.0),

            // Color picker
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'COLOR',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: isDarkMode
                        ? ThemeProvider.notionGray
                        : Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 8.0),
                SizedBox(
                  height: 40,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _colorOptions.length,
                    itemBuilder: (context, index) {
                      final color = _colorOptions[index];
                      final isSelected = color == _selectedColor;

                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedColor = color;
                          });
                        },
                        child: Container(
                          margin: const EdgeInsets.only(right: 12),
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected
                                  ? Colors.white
                                  : Colors.transparent,
                              width: 2,
                            ),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: color.withOpacity(0.4),
                                      blurRadius: 4,
                                      spreadRadius: 1,
                                    ),
                                  ]
                                : null,
                          ),
                          child: isSelected
                              ? const Icon(
                                  Icons.check,
                                  color: Colors.white,
                                  size: 18,
                                )
                              : null,
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24.0),

            // Recurrence
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'REPEAT',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: isDarkMode
                        ? ThemeProvider.notionGray
                        : Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 8.0),
                Container(
                  decoration: BoxDecoration(
                    color: isDarkMode
                        ? ThemeProvider.notionDarkGray
                        : Colors.grey[100],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _recurrenceRule ?? 'None',
                      isExpanded: true,
                      icon: const Icon(Icons.arrow_drop_down),
                      style: TextStyle(
                        fontSize: 15,
                        color: isDarkMode
                            ? Colors.white
                            : ThemeProvider.notionBlack,
                      ),
                      dropdownColor: isDarkMode
                          ? ThemeProvider.notionDarkGray
                          : Colors.grey[100],
                      items: _recurrenceOptions.map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          _recurrenceRule = newValue;
                        });
                      },
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24.0),

            // Attendees
            _buildNotionTextField(
              controller: _attendeesController,
              label: 'ATTENDEES',
              hint: 'Add attendees (comma separated)',
            ),

            const SizedBox(height: 24.0),
          ],
        ),
      ),
    );
  }
}
