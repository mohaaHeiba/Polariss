import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'ProfileImagePage.dart';
import 'package:flutter/services.dart';
import '../ui/ui_colors.dart';
import 'ContactUsPage.dart';

class SettingsPage extends StatefulWidget {
  final Function(bool) onDarkModeChanged;
  final VoidCallback onRefresh;

  SettingsPage({
    required this.onDarkModeChanged,
    required this.onRefresh,
  });

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final TextEditingController _nameController = TextEditingController();
  bool _darkMode = false;
  bool _notificationsEnabled = true;
  String _appVersion = "1.0.0"; // You can fetch dynamically later

  @override
  void initState() {
    super.initState();
    _loadSettings();
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _nameController.text = prefs.getString('user_name') ?? '';
      _darkMode = prefs.getBool('dark_mode') ?? false;
      _notificationsEnabled = prefs.getBool('notifications') ?? true;
    });
  }

  Future<void> _saveName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_name', name);
  }

  Future<void> _toggleDarkMode(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('dark_mode', value);
    setState(() {
      _darkMode = value;
      widget.onDarkModeChanged(value);

      Theme.of(context).copyWith(
        scaffoldBackgroundColor:
            _darkMode ? UIColors.backgroundColor : Colors.white,
      );
    });
  }

  Future<void> _toggleNotifications(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications', value);
    setState(() {
      _notificationsEnabled = value;
    });
  }

  Future<void> _clearAllData() async {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) => Builder(
        builder: (BuildContext builderContext) {
          final isDarkMode =
              Theme.of(builderContext).brightness == Brightness.dark;
          return AlertDialog(
            backgroundColor:
                isDarkMode ? UIColors.backgroundColor : Colors.white,
            title: Text(
              "Clear All Data",
              style: TextStyle(
                color: isDarkMode ? UIColors.textColor : Colors.black,
              ),
            ),
            content: Text(
              "Are you sure you want to clear all todo lists and chats? This action cannot be undone.",
              style: TextStyle(
                color: isDarkMode ? UIColors.textColor : Colors.black,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: Text(
                  "Cancel",
                  style: TextStyle(
                    color: isDarkMode ? UIColors.textColor : Colors.black,
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () async {
                  final prefs = await SharedPreferences.getInstance();

                  // Clear todo lists
                  await prefs.remove('tasks');

                  // Clear all chat data
                  final historiesCount =
                      prefs.getInt('chat_histories_count') ?? 0;
                  for (int i = 0; i < historiesCount; i++) {
                    await prefs.remove('chat_history_$i');
                  }
                  await prefs.remove('chat_histories_count');
                  await prefs.remove('current_chat_index');

                  // Clear user name
                  await prefs.remove('user_name');

                  // Keep dark mode and notification settings

                  setState(() {
                    _nameController.text = '';
                  });

                  // Close dialog and settings page
                  Navigator.of(context).pop(); // Close dialog
                  Navigator.of(context).pop(); // Close settings page

                  // Show success message
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('All data has been cleared successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );

                  // Trigger refresh of all pages immediately
                  widget.onRefresh();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                ),
                child: Text("Clear All", style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _darkMode ? UIColors.backgroundColor : Colors.white,
      child: Column(
        children: [
          Expanded(
            child: ListView(
              padding: EdgeInsets.symmetric(horizontal: 32, vertical: 20),
              children: [
                Container(
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: _darkMode ? Colors.grey[800] : Colors.grey[300],
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black54,
                        blurRadius: 15,
                        offset: Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      ProfileImagePage(),
                      SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Profile Name',
                              style: TextStyle(
                                color: _darkMode
                                    ? UIColors.textColor
                                    : Colors.black,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 8),
                            TextField(
                              controller: _nameController,
                              style: TextStyle(
                                  color: _darkMode
                                      ? UIColors.textColor
                                      : Colors.black,
                                  fontSize: 16),
                              decoration: InputDecoration(
                                hintText: 'Enter your name',
                                hintStyle: TextStyle(
                                    color: _darkMode
                                        ? Colors.white54
                                        : Colors.black54),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(
                                      color: UIColors.primaryColor
                                          .withOpacity(0.7)),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(
                                      color: Colors.tealAccent, width: 2),
                                ),
                                filled: true,
                                fillColor:
                                    _darkMode ? Colors.black54 : Colors.white,
                              ),
                              onChanged: (value) => _saveName(value),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 20),
                Text(
                  'General Settings',
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: _darkMode ? UIColors.textColor : Colors.black),
                ),
                SizedBox(height: 10),
                ListTile(
                  leading:
                      Icon(Icons.brightness_6, color: UIColors.primaryColor),
                  title: Text('Dark Mode',
                      style: TextStyle(
                          color:
                              _darkMode ? UIColors.textColor : Colors.black)),
                  trailing: Switch(
                    value: _darkMode,
                    onChanged: _toggleDarkMode,
                    activeColor: UIColors.primaryColor,
                  ),
                ),
                ListTile(
                  leading:
                      Icon(Icons.notifications, color: UIColors.primaryColor),
                  title: Text('Notifications',
                      style: TextStyle(
                          color:
                              _darkMode ? UIColors.textColor : Colors.black)),
                  trailing: Switch(
                    value: _notificationsEnabled,
                    onChanged: _toggleNotifications,
                    activeColor: const Color.fromARGB(255, 56, 56, 105),
                  ),
                ),
                ListTile(
                  leading: Icon(Icons.info, color: UIColors.primaryColor),
                  title: Text('App Version',
                      style: TextStyle(
                          color:
                              _darkMode ? UIColors.textColor : Colors.black)),
                  subtitle: Text(_appVersion,
                      style: TextStyle(
                          color: _darkMode ? Colors.white54 : Colors.black54)),
                  onTap: () {},
                ),
                ListTile(
                  leading:
                      Icon(Icons.message_sharp, color: UIColors.primaryColor),
                  title: Text('Contact Us',
                      style: TextStyle(
                          color:
                              _darkMode ? UIColors.textColor : Colors.black)),
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return Dialog(
                          child: Container(
                            height: MediaQuery.of(context).size.height * 0.89,
                            width: MediaQuery.of(context).size.width * 0.85,
                            child: ContactUsPage(darkMode: _darkMode),
                          ),
                        );
                      },
                    );
                  },
                ),
                SizedBox(height: 20),
                Text(
                  'Account',
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: _darkMode ? UIColors.textColor : Colors.black),
                ),
                SizedBox(height: 10),
                ListTile(
                  leading: Icon(Icons.delete_forever, color: Colors.redAccent),
                  title: Text('Clear All Data',
                      style: TextStyle(color: Colors.redAccent)),
                  onTap: _clearAllData,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }
}
