import 'package:flutter/material.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class Homepage extends StatefulWidget {
  final bool darkMode;
  const Homepage({super.key, required this.darkMode});

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  List<Map<String, dynamic>> _dailyTasks = [];
  int _totalTasks = 0;
  int _completedTasks = 0;
  List<String> _lastChatMessages = [];

  @override
  void initState() {
    super.initState();
    _loadTasks();
    _loadLastChat();
  }

  Future<void> _loadTasks() async {
    final prefs = await SharedPreferences.getInstance();
    String? tasksString = prefs.getString('tasks');
    if (tasksString != null) {
      final List<dynamic> allTasks = jsonDecode(tasksString);
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      setState(() {
        _totalTasks = allTasks.length;
        _completedTasks = allTasks.where((task) {
          // For non-repeating tasks, check the completed status directly
          if (task['repeat'] == 'none') {
            return task['completed'] == true;
          }

          // For repeating tasks, check the completedDates map
          final completedDates =
              task['completedDates'] as Map<String, dynamic>? ?? {};
          final dateKey = today.toIso8601String().split('T')[0];
          return completedDates[dateKey] == true;
        }).length;

        // Filter tasks for today
        _dailyTasks = allTasks.where((task) {
          final taskDate = DateTime.parse(
              task['dueDate'] ?? DateTime.now().toIso8601String());
          final taskDay = DateTime(taskDate.year, taskDate.month, taskDate.day);

          // Check if task is for today or is a repeating task that should show today
          if (DateUtils.isSameDay(taskDay, today)) return true;

          // Handle repeating tasks
          final repeatType = task['repeat'] as String? ?? 'none';
          switch (repeatType) {
            case 'daily':
              return true;
            case 'weekly':
              return taskDate.weekday == today.weekday;
            case 'monthly':
              return taskDate.day == today.day;
            case 'yearly':
              return taskDate.month == today.month && taskDate.day == today.day;
            default:
              return false;
          }
        }).map((task) {
          // Create a copy of the task with the correct completion status for today
          final Map<String, dynamic> taskCopy = Map<String, dynamic>.from(task);

          // For repeating tasks, check the completedDates map
          if (task['repeat'] != 'none') {
            final completedDates =
                task['completedDates'] as Map<String, dynamic>? ?? {};
            final dateKey = today.toIso8601String().split('T')[0];
            taskCopy['completed'] = completedDates[dateKey] ?? false;
          }

          return taskCopy;
        }).toList();
      });
    }
  }

  Future<void> _loadLastChat() async {
    final prefs = await SharedPreferences.getInstance();
    final totalChats = prefs.getInt('chat_histories_count') ?? 0;

    // Get the last 5 chat indices
    final startIndex = (totalChats > 5) ? totalChats - 5 : 0;
    final List<int> lastFiveChats = List.generate(
            totalChats < 5 ? totalChats : 5, (index) => startIndex + index + 1)
        .reversed
        .toList();

    setState(() {
      _lastChatMessages = lastFiveChats.map((index) => 'Chat $index').toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: widget.darkMode ? const Color(0xFF1E1E3F) : Colors.white,
      body: Row(
        children: [
          // Main Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(24.0), // Reduced padding
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Welcome Text Animation with smaller size
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 16),
                    child: DefaultTextStyle(
                      style: TextStyle(
                        color: widget.darkMode ? Colors.white : Colors.black,
                        fontSize: 32, // Reduced from 42
                        fontWeight: FontWeight.w800,
                        fontFamily: 'Polaris',
                        letterSpacing: -0.5,
                      ),
                      child: AnimatedTextKit(
                        animatedTexts: [
                          TypewriterAnimatedText(
                            'Welcome To Polaris!',
                            speed: const Duration(milliseconds: 100),
                            cursor: '|',
                          ),
                        ],
                        isRepeatingAnimation: false,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24), // Reduced from 48

                  // Stats Cards with adjusted layout
                  GridView.count(
                    crossAxisCount: 3,
                    crossAxisSpacing: 20,
                    mainAxisSpacing: 20,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    childAspectRatio: 1.8,
                    children: [
                      _buildStatCard(
                        'Total Tasks',
                        _totalTasks.toString(),
                        Icons.task_alt,
                        Colors.blue,
                      ),
                      _buildStatCard(
                        'Completed',
                        _completedTasks.toString(),
                        Icons.check_circle,
                        Colors.green,
                      ),
                      _buildStatCard(
                        'Success Rate',
                        '${(_completedTasks / (_totalTasks == 0 ? 1 : _totalTasks) * 100).toStringAsFixed(0)}%',
                        Icons.analytics,
                        Colors.orange,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24), // Reduced from 48

                  // Make the remaining content take available space
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Recent Tasks Section
                        Expanded(
                          flex: 3,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Today\'s Tasks',
                                style: TextStyle(
                                  color: widget.darkMode
                                      ? Colors.white
                                      : Colors.black,
                                  fontSize: 20, // Reduced from 24
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 16), // Reduced from 24
                              Expanded(
                                child: ListView(
                                  children: _dailyTasks
                                      .map((task) => _buildTaskItem(task))
                                      .toList(),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 24), // Reduced from 48
                        // Recent Chat Section
                        Expanded(
                          flex: 2,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Recent Chat',
                                style: TextStyle(
                                  color: widget.darkMode
                                      ? Colors.white
                                      : Colors.black,
                                  fontSize: 20, // Reduced from 24
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 16), // Reduced from 24
                              Expanded(child: _buildChatSection()),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatSection() {
    return Container(
      padding: const EdgeInsets.only(right: 10, left: 10, top: 10, bottom: 10),
      decoration: BoxDecoration(
        color: widget.darkMode ? const Color(0xFF2B2D42) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: _lastChatMessages.isEmpty
                ? Center(
                    child: Text(
                      'No chats yet',
                      style: TextStyle(
                        color:
                            widget.darkMode ? Colors.white70 : Colors.black54,
                        fontSize: 16,
                      ),
                    ),
                  )
                : ListView.builder(
                    itemCount: _lastChatMessages.length,
                    itemBuilder: (context, index) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: widget.darkMode
                              ? Colors.blue.withOpacity(0.1)
                              : Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: widget.darkMode
                                ? Colors.white.withOpacity(0.1)
                                : Colors.grey.shade200,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.chat_outlined,
                              color: widget.darkMode
                                  ? Colors.blue
                                  : Colors.blue[700],
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              _lastChatMessages[index],
                              style: TextStyle(
                                color: widget.darkMode
                                    ? Colors.white
                                    : Colors.black87,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: 120,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: widget.darkMode
              ? [color.withOpacity(0.2), color.withOpacity(0.1)]
              : [Colors.white, Colors.grey.shade50],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 12,
            spreadRadius: 0,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -10,
            top: -10,
            child: Icon(
              icon,
              size: 70,
              color: color.withOpacity(0.1),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: TextStyle(
                      color: widget.darkMode ? Colors.white : Colors.black,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    title,
                    style: TextStyle(
                      color: widget.darkMode ? Colors.white70 : Colors.black54,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTaskItem(Map<String, dynamic> task) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: widget.darkMode ? const Color(0xFF2B2D42) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: widget.darkMode
              ? Colors.white.withOpacity(0.1)
              : Colors.grey.shade200,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: task['completed']
                  ? Colors.green.withOpacity(0.1)
                  : Colors.grey.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              task['completed'] ? Icons.check_circle : Icons.circle_outlined,
              color: task['completed'] ? Colors.green : Colors.grey,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task['task'],
                  style: TextStyle(
                    color: widget.darkMode ? Colors.white : Colors.black87,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    decoration:
                        task['completed'] ? TextDecoration.lineThrough : null,
                    decorationColor: Colors.grey,
                  ),
                ),
                if (task['repeat'] != 'none' && task['repeat'] != null)
                  Text(
                    'Repeats ${task['repeat']}',
                    style: TextStyle(
                      color: widget.darkMode ? Colors.white70 : Colors.black54,
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
