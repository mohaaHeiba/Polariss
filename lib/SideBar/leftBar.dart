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

class Leftbar extends StatefulWidget {
  const Leftbar({super.key});

  @override
  State<Leftbar> createState() => _LeftbarState();
}

class _LeftbarState extends State<Leftbar> {
  int _selectedTab = 0;
  String? _profileImagePath;
  bool _darkMode = true;

  @override
  void initState() {
    super.initState();
    _loadProfileImage();
    _loadSettings();
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

  void _updateDarkMode(bool value) {
    setState(() {
      _darkMode = value;
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
                      child: SettingsPage(onDarkModeChanged: _updateDarkMode),
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
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 350),
      transitionBuilder: (child, animation) {
        return FadeTransition(opacity: animation, child: child);
      },
      child: _getPage(_selectedTab),
    );
  }

  Widget _getPage(int index) {
    switch (index) {
      case 0:
        return Homepage(
          darkMode: _darkMode,
        );
      case 1:
        return ChatDesign(
          darkMode: _darkMode,
        );
      case 2:
        return Pomodoro(darkMode: _darkMode);
      case 3:
        return Dotolist(darkMode: _darkMode);
      default:
        return Homepage(
          darkMode: _darkMode,
        );
    }
  }
}
