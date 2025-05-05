import 'package:flutter/material.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'dart:async';

class Pomodoro extends StatefulWidget {
  final bool darkMode;
  const Pomodoro({super.key, required this.darkMode});

  @override
  State<Pomodoro> createState() => _PomodoroState();
}

class _PomodoroState extends State<Pomodoro>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late PageController _pageController;
  Timer? _timer;
  int _currentSeconds = 25 * 60; // 25 minutes
  bool _isRunning = false;
  String _currentMode = "pomodoro";
  final Map<String, int> _timers = {
    "pomodoro": 25 * 60,
    "short break": 5 * 60,
    "long break": 15 * 60,
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _pageController = PageController();
    _tabController.addListener(_handleTabChange);
    _pageController.addListener(() {
      int page = _pageController.page?.round() ?? 0;
      if (_tabController.index != page) {
        _tabController.animateTo(page);
      }
    });
  }

  void _handleTabChange() {
    if (!_tabController.indexIsChanging) {
      return;
    }
    switch (_tabController.index) {
      case 0:
        _switchMode("pomodoro");
        break;
      case 1:
        _switchMode("short break");
        break;
      case 2:
        _switchMode("long break");
        break;
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _pageController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _toggleTimer() {
    if (_isRunning) {
      _pauseTimer();
    } else {
      _startTimer();
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_currentSeconds > 0) {
          _currentSeconds--;
        } else {
          _timer?.cancel();
          _isRunning = false;
        }
      });
    });
    setState(() => _isRunning = true);
  }

  void _pauseTimer() {
    _timer?.cancel();
    setState(() => _isRunning = false);
  }

  void _switchMode(String mode) {
    _timer?.cancel();
    setState(() {
      _currentMode = mode;
      _currentSeconds = _timers[mode]!;
      _isRunning = false;
      switch (mode) {
        case "pomodoro":
      }
    });
  }

  String _formatTime() {
    int minutes = _currentSeconds ~/ 60;
    int seconds = _currentSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    double circleSize = MediaQuery.of(context).size.width * 0.1;
    double progress = _currentSeconds / _timers[_currentMode]!;

    return Scaffold(
      backgroundColor: widget.darkMode ? const Color(0xFF1E1E3F) : Colors.white,
      body: SafeArea(
        child: Column(
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
              borderRadius: BorderRadius.circular(50), // Prevents overflow
              child: Container(
                width: 350,
                height: 50,
                decoration: BoxDecoration(
                  color: widget.darkMode ? Colors.grey[850] : Colors.grey[200],
                  borderRadius: BorderRadius.circular(50),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(
                      4.0), // Padding for better highlight spacing
                  child: TabBar(
                    controller: _tabController,
                    tabs: const [
                      Tab(text: "pomodoro"),
                      Tab(text: "short break"),
                      Tab(text: "long break"),
                    ],
                    indicator: ShapeDecoration(
                      color: const Color(0xFFFF6B6B), // Red highlight color
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    indicatorColor:
                        Colors.transparent, // ✅ Removes the default underline
                    labelColor: Colors.white,
                    unselectedLabelColor: Colors.grey.shade400,
                    labelStyle: const TextStyle(fontWeight: FontWeight.bold),
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
                    onTap: _toggleTimer,
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
                              _isRunning ? "PAUSE" : "START",
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
            Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(30),
              ),
              padding: const EdgeInsets.all(12),
              child:
                  Icon(Icons.settings, color: Colors.grey.shade400, size: 32),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}
