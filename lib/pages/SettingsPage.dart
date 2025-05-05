import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'ProfileImagePage.dart';
import 'package:flutter/services.dart';
import '../ui/ui_colors.dart';
import 'ContactUsPage.dart';

class SettingsPage extends StatefulWidget {
  final Function(bool) onDarkModeChanged;

  SettingsPage({required this.onDarkModeChanged});

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

  void _logout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Logout",
            style: TextStyle(
                color: _darkMode ? UIColors.textColor : Colors.black)),
        content: Text("Are you sure you want to logout?",
            style: TextStyle(
                color: _darkMode ? UIColors.textColor : Colors.black)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel",
                style: TextStyle(
                    color: _darkMode ? UIColors.textColor : Colors.black)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: Text("Logout",
                style: TextStyle(
                    color: _darkMode ? UIColors.textColor : Colors.black)),
          ),
        ],
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
                  leading: Icon(Icons.exit_to_app, color: Colors.redAccent),
                  title:
                      Text('Logout', style: TextStyle(color: Colors.redAccent)),
                  onTap: _logout,
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
