import 'package:flutter/material.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:local_notifier/local_notifier.dart';

class Pomodoro extends StatefulWidget {
  final bool darkMode;
  final int currentSeconds;
  final bool isRunning;
  final String currentMode;
  final Map<String, int> timers;
  final VoidCallback onToggleTimer;
  final Function(String) onSwitchMode;
  final Function(Map<String, int>) onUpdateSettings;

  const Pomodoro({
    super.key,
    required this.darkMode,
    required this.currentSeconds,
    required this.isRunning,
    required this.currentMode,
    required this.timers,
    required this.onToggleTimer,
    required this.onSwitchMode,
    required this.onUpdateSettings,
  });

  @override
  State<Pomodoro> createState() => _PomodoroState();
}

class _PomodoroState extends State<Pomodoro>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late PageController _pageController;
  bool _showSettingsPanel = false;
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  bool _hasShownNotification = false;
  int _completedPomodoros = 0; // Track completed pomodoros

  // Add controllers for text input fields
  final TextEditingController _pomodoroController = TextEditingController();
  final TextEditingController _shortBreakController = TextEditingController();
  final TextEditingController _longBreakController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
    _initializeLocalNotifier();
    _tabController = TabController(length: 3, vsync: this);
    _pageController = PageController();
    _tabController.addListener(_handleTabChange);
    _pageController.addListener(() {
      int page = _pageController.page?.round() ?? 0;
      if (_tabController.index != page) {
        _tabController.animateTo(page);
      }
    });

    // Initialize controllers with current values
    _pomodoroController.text = (widget.timers["pomodoro"]! ~/ 60).toString();
    _shortBreakController.text =
        (widget.timers["short break"]! ~/ 60).toString();
    _longBreakController.text = (widget.timers["long break"]! ~/ 60).toString();
  }

  Future<void> _initializeLocalNotifier() async {
    await localNotifier.setup(
      appName: 'Pomodoro Timer',
    );
  }

  Future<void> _initializeNotifications() async {
    tz.initializeTimeZones();

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/launcher_icon');

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) async {
        // Handle notification tap
      },
    );

    // Request notification permissions
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestPermission();
  }

  Future<void> _showTimerEndNotification(String mode) async {
    // Reset notification flag when timer starts
    if (widget.currentSeconds == widget.timers[mode]!) {
      _hasShownNotification = false;
    }

    // Only show notification when timer reaches 0 and hasn't shown notification yet
    if (widget.currentSeconds == 0 && !_hasShownNotification) {
      _hasShownNotification = true;

      // Show desktop notification
      final notification = LocalNotification(
        title: mode == 'pomodoro'
            ? 'Pomodoro Session Complete!'
            : 'Break Time Over!',
        body: mode == 'pomodoro'
            ? 'Time for a break! You\'ve completed a Pomodoro session.'
            : 'Break is over! Ready for the next Pomodoro?',
        actions: [
          LocalNotificationAction(text: 'View'),
          LocalNotificationAction(text: 'Dismiss'),
        ],
      );

      // Show desktop notification
      await notification.show();

      // Show mobile notification
      final androidDetails = AndroidNotificationDetails(
        'pomodoro_timer',
        'Pomodoro Timer',
        channelDescription: 'Notifications for Pomodoro Timer',
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
        fullScreenIntent: true,
        color: const Color(0xFFFF6B6B),
      );

      const iOSDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      await flutterLocalNotificationsPlugin.show(
        0,
        mode == 'pomodoro' ? 'Pomodoro Session Complete!' : 'Break Time Over!',
        mode == 'pomodoro'
            ? 'Time for a break! You\'ve completed a Pomodoro session.'
            : 'Break is over! Ready for the next Pomodoro?',
        NotificationDetails(
          android: androidDetails,
          iOS: iOSDetails,
        ),
      );
    }
  }

  void _handleTabChange() {
    if (!_tabController.indexIsChanging) {
      return;
    }
    switch (_tabController.index) {
      case 0:
        widget.onSwitchMode("pomodoro");
        break;
      case 1:
        widget.onSwitchMode("short break");
        break;
      case 2:
        widget.onSwitchMode("long break");
        break;
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _pageController.dispose();
    _pomodoroController.dispose();
    _shortBreakController.dispose();
    _longBreakController.dispose();
    super.dispose();
  }

  String _formatTime() {
    int minutes = widget.currentSeconds ~/ 60;
    int seconds = widget.currentSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final pomodoroMinutes = int.tryParse(_pomodoroController.text) ?? 25;
    final shortBreakMinutes = int.tryParse(_shortBreakController.text) ?? 5;
    final longBreakMinutes = int.tryParse(_longBreakController.text) ?? 15;

    await prefs.setInt('pomodoro_minutes', pomodoroMinutes);
    await prefs.setInt('short_break_minutes', shortBreakMinutes);
    await prefs.setInt('long_break_minutes', longBreakMinutes);

    widget.onUpdateSettings({
      "pomodoro": pomodoroMinutes * 60,
      "short break": shortBreakMinutes * 60,
      "long break": longBreakMinutes * 60,
    });
  }

  @override
  Widget build(BuildContext context) {
    // Handle automatic mode switching when timer ends
    if (widget.currentSeconds == 0 && widget.isRunning) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showTimerEndNotification(widget.currentMode);

        // Automatically switch modes when timer ends
        if (widget.currentMode == 'pomodoro') {
          _completedPomodoros++;
          // After 4 pomodoros, take a long break, otherwise take a short break
          if (_completedPomodoros % 4 == 0) {
            _hasShownNotification = false;
            widget.onSwitchMode('long break');
            _tabController.animateTo(2); // Switch to long break tab
            _pageController.animateToPage(2,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut);
          } else {
            _hasShownNotification = false;
            widget.onSwitchMode('short break');
            _tabController.animateTo(1); // Switch to short break tab
            _pageController.animateToPage(1,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut);
          }
        } else if (widget.currentMode == 'short break' ||
            widget.currentMode == 'long break') {
          _hasShownNotification = false;
          widget.onSwitchMode('pomodoro');
          _tabController.animateTo(0); // Switch to pomodoro tab
          _pageController.animateToPage(0,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut);
        }
      });
    }

    double circleSize = MediaQuery.of(context).size.width * 0.1;
    double progress =
        widget.currentSeconds / widget.timers[widget.currentMode]!;

    return Scaffold(
      backgroundColor: widget.darkMode ? const Color(0xFF1E1E3F) : Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                const SizedBox(height: 10),
                Text(
                  "POMODORO TIMER",
                  style: TextStyle(
                    color: widget.darkMode ? Colors.white : Colors.black,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 20),
                ClipRRect(
                  borderRadius: BorderRadius.circular(50),
                  child: Container(
                    width: 350,
                    height: 50,
                    decoration: BoxDecoration(
                      color:
                          widget.darkMode ? Colors.grey[850] : Colors.grey[200],
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: TabBar(
                        controller: _tabController,
                        tabs: const [
                          Tab(text: "pomodoro"),
                          Tab(text: "short break"),
                          Tab(text: "long break"),
                        ],
                        indicator: ShapeDecoration(
                          color: const Color(0xFFFF6B6B),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        indicatorColor: Colors.transparent,
                        labelColor: Colors.white,
                        unselectedLabelColor: Colors.grey.shade400,
                        labelStyle:
                            const TextStyle(fontWeight: FontWeight.bold),
                        indicatorSize: TabBarIndicatorSize.tab,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    onPageChanged: (index) {
                      _tabController.animateTo(index);
                    },
                    children: [
                      _buildTimerContent(circleSize, progress),
                      _buildTimerContent(circleSize, progress),
                      _buildTimerContent(circleSize, progress),
                    ],
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    color:
                        widget.darkMode ? Colors.grey[850] : Colors.grey[200],
                    borderRadius: BorderRadius.circular(30),
                  ),
                  padding: const EdgeInsets.all(12),
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _showSettingsPanel = !_showSettingsPanel;
                      });
                    },
                    child: Icon(
                      Icons.settings,
                      color:
                          widget.darkMode ? Colors.white70 : Colors.grey[700],
                      size: 32,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
              ],
            ),
            Positioned(
              right: 0,
              top: 0,
              bottom: 0,
              child: ClipRect(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOutCubic,
                  width: _showSettingsPanel ? 300 : 0,
                  decoration: BoxDecoration(
                    color: widget.darkMode
                        ? const Color(0xFF1E1E3F).withOpacity(0.95)
                        : Colors.white.withOpacity(0.95),
                    border: Border(
                      left: BorderSide(
                        color: widget.darkMode
                            ? Colors.white.withOpacity(0.1)
                            : Colors.black.withOpacity(0.1),
                      ),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(-2, 0),
                      ),
                    ],
                  ),
                  child: AnimatedSlide(
                    duration: const Duration(milliseconds: 300),
                    offset: Offset(_showSettingsPanel ? 0 : 1, 0),
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 300),
                      opacity: _showSettingsPanel ? 1.0 : 0.0,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.settings,
                                      color: const Color(0xFFFF6B6B),
                                    ),
                                    const SizedBox(width: 8),
                                    const Text(
                                      'Settings',
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFFFF6B6B),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Expanded(
                            child: SingleChildScrollView(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16.0),
                              child: Column(
                                children: [
                                  _buildTimeInputField(
                                    'Pomodoro (minutes)',
                                    _pomodoroController,
                                    Icons.timer,
                                  ),
                                  const SizedBox(height: 16),
                                  _buildTimeInputField(
                                    'Short Break (minutes)',
                                    _shortBreakController,
                                    Icons.coffee,
                                  ),
                                  const SizedBox(height: 16),
                                  _buildTimeInputField(
                                    'Long Break (minutes)',
                                    _longBreakController,
                                    Icons.bedtime,
                                  ),
                                  const SizedBox(height: 24),
                                  Container(
                                    width: double.infinity,
                                    height: 45,
                                    child: ElevatedButton(
                                      onPressed: () {
                                        _saveSettings();
                                        setState(() {
                                          _showSettingsPanel = false;
                                        });
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            const Color(0xFFFF6B6B),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        elevation: 2,
                                        shadowColor: const Color(0xFFFF6B6B)
                                            .withOpacity(0.3),
                                      ),
                                      child: const Text(
                                        'SAVE SETTINGS',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimerContent(double circleSize, double progress) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          children: [
            const SizedBox(height: 30),
            Stack(
              alignment: Alignment.center,
              children: [
                // Outermost Circle
                Container(
                  padding: const EdgeInsets.all(50),
                  width: (circleSize * 2) + 60, // Largest circle
                  height: (circleSize * 2) + 60,
                  decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: widget.darkMode
                              ? Color.fromARGB(255, 76, 63, 100)
                                  .withOpacity(0.4)
                              : Colors.grey[300]!,
                          blurRadius: 20,
                          offset: Offset(-25, -15),
                        ),
                        BoxShadow(
                          color: widget.darkMode
                              ? Color.fromARGB(255, 0, 0, 0).withOpacity(0.4)
                              : Colors.grey[400]!,
                          blurRadius: 20,
                          offset: Offset(10, 20),
                        ),
                      ],
                      gradient: widget.darkMode
                          ? LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Color.fromARGB(255, 23, 23, 59),
                                Color.fromARGB(255, 23, 23, 59),
                                Color.fromARGB(255, 23, 23, 66),
                                Color.fromARGB(255, 33, 33, 109)
                              ],
                            )
                          : LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Colors.white,
                                Colors.grey[100]!,
                                Colors.grey[200]!,
                                Colors.grey[300]!,
                              ],
                            )),
                ),
                // Middle Circle
                Container(
                  width: (circleSize * 2) + 25,
                  height: (circleSize * 2) + 25,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: widget.darkMode
                        ? Color.fromARGB(255, 23, 23, 58)
                        : Colors.grey[200],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(50),
                  child: GestureDetector(
                    onTap: widget.onToggleTimer,
                    child: Container(
                      width: circleSize * 2,
                      height: circleSize * 2,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: widget.darkMode
                            ? Color.fromARGB(255, 23, 23, 58)
                            : Colors.grey[200],
                      ),
                      child: CircularPercentIndicator(
                        radius: circleSize,
                        lineWidth: 12,
                        percent: progress,
                        progressColor: const Color(0xFFFF6B6B),
                        backgroundColor: widget.darkMode
                            ? Color.fromARGB(255, 23, 23, 58)
                            : Colors.grey[200]!,
                        circularStrokeCap: CircularStrokeCap.round,
                        center: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _formatTime(),
                              style: TextStyle(
                                color: widget.darkMode
                                    ? Colors.white
                                    : Colors.black,
                                fontSize: 42,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              widget.isRunning ? "PAUSE" : "START",
                              style: TextStyle(
                                color: widget.darkMode
                                    ? Colors.grey
                                    : Colors.black,
                                fontSize: 18,
                                letterSpacing: 3,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeInputField(
    String label,
    TextEditingController controller,
    IconData icon,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: widget.darkMode
            ? Colors.black.withOpacity(0.2)
            : Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color(0xFFFF6B6B).withOpacity(0.2),
          width: 1,
        ),
      ),
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        style: TextStyle(
          color: widget.darkMode ? Colors.white : Colors.black87,
          fontSize: 16,
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: widget.darkMode ? Colors.white70 : Colors.black54,
            fontSize: 14,
          ),
          prefixIcon: Icon(
            icon,
            color: const Color(0xFFFF6B6B),
            size: 24,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.transparent,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }
}
