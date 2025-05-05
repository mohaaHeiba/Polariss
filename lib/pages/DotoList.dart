import 'package:flutter/material.dart';
import 'dart:async';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:table_calendar/table_calendar.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:audioplayers/audioplayers.dart';
import 'package:local_notifier/local_notifier.dart';

class Dotolist extends StatefulWidget {
  final bool darkMode;
  const Dotolist({super.key, required this.darkMode});

  @override
  State<Dotolist> createState() => _DotolistState();
}

class _DotolistState extends State<Dotolist> {
  final List<Map<String, dynamic>> _tasks = [];
  final TextEditingController _taskController = TextEditingController();
  OverlayEntry? _overlayEntry;
  DateTime _selectedDate = DateTime.now();
  late SharedPreferences _prefs;

  // Add new enum for repeat options at the top of the class
  final List<Map<String, String>> _repeatOptions = [
    {'value': 'none', 'label': 'No repeat'},
    {'value': 'daily', 'label': 'Every day'},
    {'value': 'weekly', 'label': 'Every week'},
    {'value': 'monthly', 'label': 'Every month'},
    {'value': 'yearly', 'label': 'Every year'},
  ];

  // Add this new field for time options
  final List<Map<String, String>> _timeOptions = [
    {'value': 'none', 'label': 'No time'},
    {'value': '09:00', 'label': '9:00 AM'},
    {'value': '12:00', 'label': '12:00 PM'},
    {'value': '15:00', 'label': '3:00 PM'},
    {'value': '18:00', 'label': '6:00 PM'},
    {'value': 'custom', 'label': 'Custom time...'},
  ];

  String _newTaskRepeatOption = 'none'; // Add this field
  String _newTaskTimeOption = 'none'; // Add this field
  CalendarFormat _calendarFormat = CalendarFormat.month;

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  TimeOfDay? _selectedTime;

  // Add these fields at the start of the class
  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
    _loadTasks();
    _initializeLocalNotifier();
  }

  Future<void> _initializeNotifications() async {
    tz.initializeTimeZones();

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  Future<void> _initializeLocalNotifier() async {
    await localNotifier.setup(
      appName: 'Todo List',
    );
  }

  Future<void> _playNotificationSound() async {
    // You can replace this URL with any other online MP3 sound
    const String soundUrl =
        'https://dl.dropboxusercontent.com/scl/fi/sbq2179my8k682qn40yd8/Art-Deco-YouTube.mp3?rlkey=3yqxxgsnewrz1mlcuio32a3w5&st=nytzm6hi';

    await _audioPlayer.play(UrlSource(soundUrl));
  }

  Future<void> _scheduleNotification(String task, DateTime dateTime) async {
    // Show desktop notification
    final notification = LocalNotification(
      title: 'Task Due Now!',
      body: task,
      actions: [
        LocalNotificationAction(text: 'View'),
        LocalNotificationAction(text: 'Dismiss'),
      ],
    );

    // Schedule both mobile and desktop notifications
    if (dateTime.isAfter(DateTime.now())) {
      // Mobile notification
      final androidDetails = AndroidNotificationDetails(
        'todo_channel',
        'Todo Notifications',
        channelDescription: 'Notifications for todo items',
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
        fullScreenIntent: true,
      );

      await flutterLocalNotificationsPlugin.zonedSchedule(
        _tasks.length,
        'Task Due Now!',
        task,
        tz.TZDateTime.from(dateTime, tz.local),
        NotificationDetails(android: androidDetails),
        androidAllowWhileIdle: true,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );

      // Schedule desktop notification and sound
      Future.delayed(
        Duration(
          milliseconds: dateTime.difference(DateTime.now()).inMilliseconds,
        ),
        () async {
          await notification.show();
          await _playNotificationSound();
        },
      );
    }
  }

  void _showTimeOptions() {
    showMenu(
      color: widget.darkMode ? Colors.black : Colors.white,
      context: context,
      position: RelativeRect.fromLTRB(MediaQuery.of(context).size.width - 470,
          MediaQuery.of(context).size.height - 430, 50, 0),
      items: _timeOptions.map((option) {
        return PopupMenuItem<String>(
          value: option['value'],
          child: Text(
            option['label']!,
            style: TextStyle(
              color: widget.darkMode ? Colors.white : Colors.black,
            ),
          ),
        );
      }).toList(),
    ).then((value) async {
      if (value == 'custom') {
        final TimeOfDay? time = await showTimePicker(
          context: context,
          initialTime: TimeOfDay.now(),
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: ColorScheme.dark(
                  primary: Colors.blue,
                  onPrimary: Colors.white,
                  surface: widget.darkMode ? Colors.black : Colors.white,
                  onSurface: widget.darkMode ? Colors.white : Colors.black,
                ),
              ),
              child: child!,
            );
          },
        );
        if (time != null) {
          setState(() {
            _selectedTime = time;
            _newTaskTimeOption = '${time.hour}:${time.minute}';
          });
        }
      } else if (value != null && value != 'none') {
        final parts = value.split(':');
        setState(() {
          _selectedTime = TimeOfDay(
            hour: int.parse(parts[0]),
            minute: int.parse(parts[1]),
          );
          _newTaskTimeOption = value;
        });
      } else if (value == 'none') {
        setState(() {
          _selectedTime = null;
          _newTaskTimeOption = 'none';
        });
      }
    });
  }

  Future<void> _loadTasks() async {
    _prefs = await SharedPreferences.getInstance();
    String? tasksString = _prefs.getString('tasks');
    if (tasksString != null) {
      setState(() {
        final List<dynamic> decodedTasks = jsonDecode(tasksString);
        _tasks.addAll(decodedTasks.map((x) {
          final Map<String, dynamic> task = Map<String, dynamic>.from(x);
          // Ensure repeat field exists
          task['repeat'] ??= 'none';
          return task;
        }));
      });
    }
  }

  Future<void> _saveTasks() async {
    await _prefs.setString('tasks', jsonEncode(_tasks));
  }

  bool _shouldShowTask(Map<String, dynamic> task) {
    final taskDate =
        DateTime.parse(task['dueDate'] ?? DateTime.now().toIso8601String());
    final repeatType = task['repeat'] as String? ?? 'none';

    if (DateUtils.isSameDay(taskDate, _selectedDate)) return true;

    if (taskDate.isAfter(_selectedDate)) return false;

    switch (repeatType) {
      case 'daily':
        return true;
      case 'weekly':
        return taskDate.weekday == _selectedDate.weekday;
      case 'monthly':
        return taskDate.day == _selectedDate.day;
      case 'yearly':
        return taskDate.month == _selectedDate.month &&
            taskDate.day == _selectedDate.day;
      default:
        return DateUtils.isSameDay(taskDate, _selectedDate);
    }
  }

  void _addTask(String task) {
    if (task.trim().isNotEmpty) {
      final now = DateTime.now();
      DateTime taskDateTime = _selectedDate;
      if (_selectedTime != null) {
        taskDateTime = DateTime(
          _selectedDate.year,
          _selectedDate.month,
          _selectedDate.day,
          _selectedTime!.hour,
          _selectedTime!.minute,
        );

        if (taskDateTime.isAfter(now)) {
          _scheduleNotification(task, taskDateTime);
        }
      }

      setState(() {
        _tasks.add({
          'task': task,
          'completed': false,
          'dueDate': taskDateTime.toIso8601String(),
          'repeat': _newTaskRepeatOption,
          'time': _selectedTime?.format(context),
        });
        _taskController.clear();
        _newTaskRepeatOption = 'none';
        _newTaskTimeOption = 'none';
        _selectedTime = null;
        _saveTasks();
      });
    }
  }

  void _updateTaskRepeat(int taskIndex, String repeatValue) {
    setState(() {
      _tasks[taskIndex]['repeat'] = repeatValue;
      _saveTasks();
    });
  }

  void _showCalendarOverlay(BuildContext context, Offset offset) {
    _overlayEntry = OverlayEntry(
      builder: (context) => Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: () {
                _overlayEntry?.remove();
                _overlayEntry = null;
              },
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).size.height - 470,
            left: MediaQuery.of(context).size.width - 350,
            child: GestureDetector(
              onTap: () {},
              child: Material(
                color: Colors.transparent,
                child: Container(
                  width: 300,
                  decoration: BoxDecoration(
                    color: widget.darkMode ? Colors.black : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: TableCalendar(
                    firstDay: DateTime(2020),
                    lastDay: DateTime(2030),
                    focusedDay: _selectedDate,
                    currentDay: DateTime.now(),
                    calendarFormat: _calendarFormat,
                    onFormatChanged: (format) {
                      setState(() {
                        _calendarFormat = format;
                      });
                    },
                    selectedDayPredicate: (day) =>
                        isSameDay(_selectedDate, day),
                    calendarStyle: CalendarStyle(
                      selectedDecoration: BoxDecoration(
                        color: Colors.blue,
                        shape: BoxShape.circle,
                      ),
                      todayDecoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.5),
                        shape: BoxShape.circle,
                      ),
                      defaultTextStyle: TextStyle(
                        color: widget.darkMode ? Colors.white : Colors.black,
                      ),
                      weekendTextStyle: TextStyle(
                        color: widget.darkMode ? Colors.white70 : Colors.grey,
                      ),
                      outsideTextStyle: TextStyle(
                        color:
                            widget.darkMode ? Colors.white38 : Colors.grey[400],
                      ),
                    ),
                    headerStyle: HeaderStyle(
                      formatButtonVisible: false,
                      titleTextStyle: TextStyle(
                        color: widget.darkMode ? Colors.white : Colors.black,
                      ),
                      leftChevronIcon: Icon(
                        Icons.chevron_left,
                        color: widget.darkMode ? Colors.white : Colors.black,
                      ),
                      rightChevronIcon: Icon(
                        Icons.chevron_right,
                        color: widget.darkMode ? Colors.white : Colors.black,
                      ),
                    ),
                    daysOfWeekStyle: DaysOfWeekStyle(
                      weekdayStyle: TextStyle(
                        color:
                            widget.darkMode ? Colors.white70 : Colors.black87,
                      ),
                      weekendStyle: TextStyle(
                        color:
                            widget.darkMode ? Colors.white70 : Colors.black87,
                      ),
                    ),
                    onDaySelected: (selectedDay, focusedDay) {
                      setState(() {
                        _selectedDate = selectedDay;
                      });
                      _overlayEntry?.remove();
                      _overlayEntry = null;
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _overlayEntry?.remove();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: widget.darkMode ? const Color(0xFF1E1E3F) : Colors.white,
      body: Stack(
        children: [
          // Header section
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 44, vertical: 24),
            child: Container(
              height: 60,
              color: widget.darkMode ? const Color(0xFF1E1E3F) : Colors.white,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'My Day',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: widget.darkMode ? Colors.white : Colors.black,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => _showCalendarOverlay(context, Offset.zero),
                        child: Text(
                          DateFormat('EEEE, d\'th\' MMMM')
                              .format(_selectedDate),
                          style: TextStyle(
                            fontSize: 14,
                            color: widget.darkMode
                                ? Colors.white70
                                : Colors.black54,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Tasks list
          Padding(
            padding: const EdgeInsets.only(top: 100, bottom: 130),
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 44),
              itemCount: _tasks.length,
              itemBuilder: (context, index) {
                final task = _tasks[index];
                if (_shouldShowTask(task)) {
                  return Container(
                    margin: const EdgeInsets.symmetric(vertical: 1),
                    decoration: BoxDecoration(
                        color: widget.darkMode
                            ? const Color(0xFF2B2D42)
                            : Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: widget.darkMode
                                ? Colors.black.withOpacity(0.1)
                                : Colors.grey.withOpacity(0.1),
                            blurRadius: 4,
                            spreadRadius: 1,
                            offset: const Offset(0, 2),
                          ),
                        ]),
                    child: ListTile(
                      leading: Checkbox(
                        value: _tasks[index]['completed'],
                        onChanged: (bool? value) {
                          setState(() {
                            _tasks[index]['completed'] = value;
                            _saveTasks();
                          });
                        },
                        activeColor: Colors.green,
                      ),
                      title: Text(
                        _tasks[index]['task'],
                        style: TextStyle(
                          decoration: _tasks[index]['completed']
                              ? TextDecoration.lineThrough
                              : null,
                          color: widget.darkMode ? Colors.white : Colors.black,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (_tasks[index]['time'] != null)
                            Text(
                              'Time: ${_tasks[index]['time']}',
                              style: TextStyle(
                                color: widget.darkMode
                                    ? Colors.white70
                                    : Colors.black54,
                                fontSize: 12,
                              ),
                            ),
                          if (_tasks[index]['repeat'] != 'none')
                            Text(
                              'Repeats ${_tasks[index]['repeat']}',
                              style: TextStyle(
                                color: widget.darkMode
                                    ? Colors.white70
                                    : Colors.black54,
                                fontSize: 12,
                              ),
                            ),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(
                              Icons.repeat,
                              color:
                                  (_tasks[index]['repeat'] ?? 'none') != 'none'
                                      ? Colors.green
                                      : (widget.darkMode
                                          ? Colors.white54
                                          : Colors.black54),
                            ),
                            onPressed: () {
                              showMenu(
                                context: context,
                                position: RelativeRect.fromLTRB(100, 100, 0, 0),
                                items: _repeatOptions.map((option) {
                                  return PopupMenuItem<String>(
                                    value: option['value'],
                                    child: Text(
                                      option['label']!,
                                      style: TextStyle(color: Colors.white),
                                    ),
                                  );
                                }).toList(),
                              ).then((value) {
                                if (value != null) {
                                  setState(() {
                                    _tasks[index]['repeat'] = value;
                                    _saveTasks();
                                  });
                                }
                              });
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () {
                              setState(() {
                                _tasks.removeAt(index);
                                _saveTasks();
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                }
                return Container();
              },
            ),
          ),

          // Add task input field
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 44, vertical: 70),
            alignment: Alignment.bottomCenter,
            width: MediaQuery.of(context).size.width,
            child: TextField(
              controller: _taskController,
              style: TextStyle(
                color: widget.darkMode ? Colors.white : Colors.black,
              ),
              onSubmitted: _addTask,
              decoration: InputDecoration(
                hintText: 'Create a new task...',
                hintStyle: TextStyle(
                  color: widget.darkMode ? Colors.white60 : Colors.black54,
                ),
                prefixIcon: Icon(
                  Icons.add,
                  color: widget.darkMode ? Colors.white60 : Colors.black54,
                ),
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.repeat,
                        color: _newTaskRepeatOption != 'none'
                            ? Colors.green
                            : (widget.darkMode ? Colors.white : Colors.black),
                      ),
                      onPressed: () {
                        final RenderBox button =
                            context.findRenderObject() as RenderBox;
                        final Offset offset = button.localToGlobal(Offset.zero);

                        showMenu(
                          color: widget.darkMode ? Colors.black : Colors.white,
                          context: context,
                          position: RelativeRect.fromLTRB(
                              MediaQuery.of(context).size.width - 470,
                              MediaQuery.of(context).size.height - 380,
                              50,
                              0),
                          items: _repeatOptions.map((option) {
                            return PopupMenuItem<String>(
                              value: option['value'],
                              child: Text(
                                option['label']!,
                                style: TextStyle(
                                  color: widget.darkMode
                                      ? Colors.white
                                      : const Color.fromARGB(255, 0, 0, 0),
                                ),
                              ),
                            );
                          }).toList(),
                        ).then((value) {
                          if (value != null) {
                            setState(() {
                              _newTaskRepeatOption = value;
                            });
                          }
                        });
                      },
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.calendar_today,
                        color: widget.darkMode ? Colors.white : Colors.black,
                      ),
                      onPressed: () {
                        _showCalendarOverlay(context, Offset.zero);
                      },
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.timer,
                        color: _newTaskTimeOption != 'none'
                            ? Colors.blue
                            : (widget.darkMode ? Colors.white : Colors.black),
                      ),
                      onPressed: _showTimeOptions,
                    )
                  ],
                ),
                border: OutlineInputBorder(
                  borderSide: BorderSide.none,
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: widget.darkMode
                    ? const Color(0xFF2B2D42)
                    : Colors.grey[200],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
