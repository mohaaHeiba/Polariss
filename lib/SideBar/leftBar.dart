import 'package:chat1/pages/DotoList.dart';
import 'package:chat1/pages/HomePage.dart';
import 'package:chat1/pages/Promdoro.dart';
import 'package:chat1/pages/SettingsPage.dart';
import 'package:chat1/widget/chat_desgin.dart';
import 'package:flutter/material.dart';
import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import '../ui/ui_colors.dart';
import 'dart:async';

class Leftbar extends StatefulWidget {
  const Leftbar({super.key});

  @override
  State<Leftbar> createState() => _LeftbarState();
}

class _LeftbarState extends State<Leftbar> {
  int _selectedTab = 0;
  String? _profileImagePath;
  bool _darkMode = true;
  // Add refresh counter to force rebuild
  int _refreshCounter = 0;

  // Add timer state variables
  Timer? _timer;
  int _currentSeconds = 25 * 60;
  bool _isRunning = false;
  String _currentMode = "pomodoro";
  Map<String, int> _timers = {
    "pomodoro": 25 * 60,
    "short break": 5 * 60,
    "long break": 15 * 60,
  };

  @override
  void initState() {
    super.initState();
    _loadProfileImage();
    _loadSettings();
    _loadTimerSettings();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadProfileImage() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _profileImagePath = prefs.getString('profile_image');
    });
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _darkMode = prefs.getBool('dark_mode') ?? true;
    });
  }

  Future<void> _loadTimerSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _timers = {
        "pomodoro": (prefs.getInt('pomodoro_minutes') ?? 25) * 60,
        "short break": (prefs.getInt('short_break_minutes') ?? 5) * 60,
        "long break": (prefs.getInt('long_break_minutes') ?? 15) * 60,
      };
      _currentSeconds = _timers[_currentMode]!;
    });
  }

  void _updateDarkMode(bool value) {
    setState(() {
      _darkMode = value;
    });
  }

  // Add timer control methods
  void toggleTimer() {
    if (_isRunning) {
      _pauseTimer();
    } else {
      _startTimer();
    }
  }

  void _startTimer() {
    _timer?.cancel();
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

  void switchTimerMode(String mode) {
    _timer?.cancel();
    setState(() {
      _currentMode = mode;
      _currentSeconds = _timers[mode]!;
      _isRunning = false;
    });
  }

  void updateTimerSettings(Map<String, int> newTimers) {
    setState(() {
      _timers = newTimers;
      _currentSeconds = _timers[_currentMode]!;
      _isRunning = false;
      _timer?.cancel();
    });
  }

  void _refreshAllPages() {
    setState(() {
      // Increment counter to force rebuild of all pages
      _refreshCounter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          _buildNavigationRail(),
          Expanded(
            child: Column(
              children: [
                _buildWindowButtons(),
                Expanded(child: _buildPageView()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWindowButtons() {
    return WindowTitleBarBox(
      child: Container(
        color: _darkMode
            ? const Color(0xFF1E1E3F)
            : const Color.fromARGB(255, 255, 255, 255),
        child: Row(
          children: [
            Expanded(child: MoveWindow()),
            MinimizeWindowButton(
              colors: WindowButtonColors(
                iconNormal: _darkMode
                    ? UIColors.primaryColor
                    : const Color.fromARGB(255, 0, 0, 0),
                iconMouseOver: Colors.grey,
                mouseDown: Colors.red,
              ),
            ),
            MaximizeWindowButton(
              colors: WindowButtonColors(
                iconNormal: _darkMode
                    ? UIColors.primaryColor
                    : const Color.fromARGB(255, 0, 0, 0),
                iconMouseOver: Colors.grey,
                mouseDown: Colors.red,
              ),
            ),
            CloseWindowButton(
              colors: WindowButtonColors(
                iconNormal: _darkMode
                    ? UIColors.primaryColor
                    : const Color.fromARGB(255, 0, 0, 0),
                iconMouseOver: Colors.red,
                mouseDown: Colors.redAccent,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavigationRail() {
    return Container(
      width: 100,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _darkMode
                ? const Color.fromARGB(255, 0, 0, 0)
                : const Color.fromARGB(255, 56, 56, 105),
            _darkMode ? Colors.black87 : Colors.black
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: const BorderRadius.only(topRight: Radius.circular(0)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 8)
        ],
      ),
      child: NavigationRail(
        selectedIndex: _selectedTab,
        onDestinationSelected: (index) => setState(() => _selectedTab = index),
        labelType: NavigationRailLabelType.all,
        useIndicator: false,
        minWidth: 80,
        minExtendedWidth: 220,
        backgroundColor: Colors.transparent,
        leading: Column(
          children: [
            const SizedBox(height: 16),
            GestureDetector(
              onTap: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (context) => Container(
                    height: MediaQuery.of(context).size.height * 0.955,
                    decoration: BoxDecoration(
                      color:
                          _darkMode ? UIColors.backgroundColor : Colors.white,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                      ),
                    ),
                    child: Padding(
                      padding: EdgeInsets.only(
                          top: MediaQuery.of(context).padding.top),
                      child: SettingsPage(
                        onDarkModeChanged: _updateDarkMode,
                        onRefresh: _refreshAllPages,
                      ),
                    ),
                  ),
                );
              },
              child: Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: UIColors.primaryColor, width: 2),
                  image: _profileImagePath != null
                      ? DecorationImage(
                          image: FileImage(File(_profileImagePath!)),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: _profileImagePath == null
                    ? Icon(Icons.person, size: 30, color: UIColors.primaryColor)
                    : null,
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Divider(color: UIColors.dividerColor, thickness: 1),
            ),
          ],
        ),
        destinations: [
          _buildAnimatedDestination(Icons.home_outlined, Icons.home, 'Home', 0),
          _buildAnimatedDestination(Icons.chat_outlined, Icons.chat, 'Chat', 1),
          _buildAnimatedDestination(
              Icons.timer_outlined, Icons.timer, 'Pomodoro', 2),
          _buildAnimatedDestination(Icons.note_outlined, Icons.note, 'Todo', 3),
        ],
      ),
    );
  }

  NavigationRailDestination _buildAnimatedDestination(
      IconData unselectedIcon, IconData selectedIcon, String label, int index) {
    return NavigationRailDestination(
      padding: const EdgeInsets.symmetric(vertical: 10),
      icon: Tooltip(
        message: label,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          transitionBuilder: (child, animation) {
            return ScaleTransition(scale: animation, child: child);
          },
          child: Icon(
            _selectedTab == index ? selectedIcon : unselectedIcon,
            key: ValueKey<bool>(_selectedTab == index),
            color:
                _selectedTab == index ? UIColors.primaryColor : Colors.white70,
            size: _selectedTab == index ? 30 : 24,
          ),
        ),
      ),
      label: Text(
        label,
        style: TextStyle(
          color: _selectedTab == index ? UIColors.primaryColor : Colors.white70,
          fontWeight: _selectedTab == index ? FontWeight.bold : FontWeight.w400,
        ),
      ),
    );
  }

  Widget _buildPageView() {
    // Add refresh counter to force rebuild of page view
    return AnimatedSwitcher(
      key: ValueKey<int>(_refreshCounter),
      duration: const Duration(milliseconds: 350),
      transitionBuilder: (child, animation) {
        return FadeTransition(opacity: animation, child: child);
      },
      child: _getPage(_selectedTab),
    );
  }

  Widget _getPage(int index) {
    // Use refresh counter in key to force rebuild
    final pageKey = ValueKey<int>(_refreshCounter);

    switch (index) {
      case 0:
        return Homepage(
          key: pageKey,
          darkMode: _darkMode,
        );
      case 1:
        return ChatDesign(
          key: pageKey,
          darkMode: _darkMode,
        );
      case 2:
        return Pomodoro(
          key: pageKey,
          darkMode: _darkMode,
          currentSeconds: _currentSeconds,
          isRunning: _isRunning,
          currentMode: _currentMode,
          timers: _timers,
          onToggleTimer: toggleTimer,
          onSwitchMode: switchTimerMode,
          onUpdateSettings: updateTimerSettings,
        );
      case 3:
        return Dotolist(
          key: pageKey,
          darkMode: _darkMode,
        );
      default:
        return Homepage(
          key: pageKey,
          darkMode: _darkMode,
        );
    }
  }
}
