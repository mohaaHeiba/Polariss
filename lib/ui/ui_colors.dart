import 'package:flutter/material.dart';

class UIColors {
  static const Color backgroundColor = Color(0xFF1A1A1A);
  static const Color primaryColor = Color.fromARGB(255, 81, 81, 173);
  static const Color secondaryColor = Color(0xFF202020);
  static const Color textColor = Colors.white;
  static const Color dividerColor = Colors.grey;
}





// import 'package:flutter/material.dart';
// import 'package:table_calendar/table_calendar.dart';
// import 'package:hive_flutter/hive_flutter.dart';
// import 'package:flutter/services.dart';

// @HiveType(typeId: 0)
// class TodoItem extends HiveObject {
//   @HiveField(0)
//   String title;

//   @HiveField(1)
//   DateTime date;

//   @HiveField(2)
//   bool isDone;

//   TodoItem({
//     required this.title,
//     required this.date,
//     this.isDone = false,
//   });
// }

// class TodoItemAdapter extends TypeAdapter<TodoItem> {
//   @override
//   final typeId = 0;

//   @override
//   TodoItem read(BinaryReader reader) {
//     return TodoItem(
//       title: reader.read(),
//       date: DateTime.parse(reader.read()),
//       isDone: reader.read(),
//     );
//   }

//   @override
//   void write(BinaryWriter writer, TodoItem obj) {
//     writer.write(obj.title);
//     writer.write(obj.date.toIso8601String());
//     writer.write(obj.isDone);
//   }
// }

// class Dotolist extends StatefulWidget {
//   final bool darkMode;
//   const Dotolist({super.key, this.darkMode = true});

//   @override
//   State<Dotolist> createState() => _DotolistState();
// }

// class _DotolistState extends State<Dotolist> with TickerProviderStateMixin {
//   late Box<TodoItem> _todoBox;
//   List<TodoItem> _todos = [];
//   DateTime _selectedDate = DateTime.now();
//   CalendarFormat _calendarFormat = CalendarFormat.week;
//   final _textController = TextEditingController();
//   final _searchController = TextEditingController();
//   String _searchQuery = '';
//   bool _isAddingTask = false;

//   Color get primaryColor =>
//       widget.darkMode ? const Color(0xFF2B2D42) : Colors.white;
//   Color get accentColor => const Color(0xFF6C63FF);
//   Color get surfaceColor =>
//       widget.darkMode ? const Color(0xFF373B69) : Colors.grey[200]!;
//   Color get backgroundColor =>
//       widget.darkMode ? const Color(0xFF1B1B2F) : Colors.white;
//   LinearGradient get cardGradient => LinearGradient(
//         colors: widget.darkMode
//             ? [const Color(0xFF373B69), const Color(0xFF2B2D42)]
//             : [Colors.white, Colors.grey[100]!],
//         begin: Alignment.topLeft,
//         end: Alignment.bottomRight,
//       );
//   Color get shadowColor => const Color(0xFF6C63FF);
//   Color get dividerColor =>
//       widget.darkMode ? const Color(0xFF373B69) : Colors.grey[300]!;
//   Color get textColor => widget.darkMode ? Colors.white : Colors.black87;
//   Color get textColorSecondary =>
//       widget.darkMode ? Colors.white60 : Colors.black54;

//   late AnimationController _listAnimationController;

//   @override
//   void initState() {
//     super.initState();
//     _initHive();
//     _searchController.addListener(() {
//       setState(() {
//         _searchQuery = _searchController.text;
//       });
//     });

//     _listAnimationController = AnimationController(
//       vsync: this,
//       duration: const Duration(milliseconds: 300),
//     );
//     _listAnimationController.forward();
//   }

//   @override
//   void dispose() {
//     _listAnimationController.dispose();
//     _searchController.dispose();
//     _textController.dispose();
//     super.dispose();
//   }

//   Future<void> _initHive() async {
//     await Hive.initFlutter();

//     // Check if adapter is already registered
//     if (!Hive.isAdapterRegistered(0)) {
//       Hive.registerAdapter(TodoItemAdapter());
//     }

//     _todoBox = await Hive.openBox<TodoItem>('todos');
//     _loadTodos();
//   }

//   void _loadTodos() {
//     setState(() {
//       _todos = _todoBox.values.toList();
//     });
//   }

//   Future<void> _saveTodo(TodoItem todo) async {
//     await _todoBox.add(todo);
//     _loadTodos();
//   }

//   List<TodoItem> _getFilteredTodos() {
//     if (_searchQuery.isEmpty) {
//       return _todos
//           .where((todo) => isSameDay(todo.date, _selectedDate))
//           .toList();
//     }
//     return _todos.where((todo) {
//       return todo.title.toLowerCase().contains(_searchQuery.toLowerCase());
//     }).toList();
//   }

//   List<DateTime> _getEventDays() {
//     return _todos
//         .map((todo) => DateTime(
//               todo.date.year,
//               todo.date.month,
//               todo.date.day,
//             ))
//         .toSet()
//         .toList();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return AnnotatedRegion<SystemUiOverlayStyle>(
//       value: widget.darkMode
//           ? SystemUiOverlayStyle.light
//           : SystemUiOverlayStyle.dark,
//       child: Scaffold(
//         body: SafeArea(
//           child: Row(
//             children: [
//               // Left side - Calendar and Search
//               Expanded(
//                 flex: 1, // Changed from 2 to 1
//                 child: Container(
//                   padding: const EdgeInsets.all(24),
//                   decoration: BoxDecoration(
//                     color: surfaceColor.withOpacity(0.3),
//                     border: Border(
//                       right: BorderSide(color: dividerColor, width: 1),
//                     ),
//                   ),
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       // Search Bar
//                       Container(
//                         margin: const EdgeInsets.only(bottom: 24),
//                         decoration: BoxDecoration(
//                           color: surfaceColor,
//                           borderRadius: BorderRadius.circular(12),
//                           border:
//                               Border.all(color: accentColor.withOpacity(0.3)),
//                           boxShadow: [
//                             BoxShadow(
//                               color: shadowColor.withOpacity(0.1),
//                               blurRadius: 10,
//                               offset: const Offset(0, 4),
//                             ),
//                           ],
//                         ),
//                         padding: const EdgeInsets.symmetric(
//                             horizontal: 16, vertical: 12),
//                         child: TextField(
//                           controller: _searchController,
//                           style: TextStyle(color: textColor, fontSize: 14),
//                           decoration: InputDecoration(
//                             hintText: 'Search tasks...',
//                             hintStyle: TextStyle(color: textColorSecondary),
//                             border: InputBorder.none,
//                             icon: Icon(Icons.search, color: textColorSecondary),
//                             isDense: true,
//                             contentPadding: EdgeInsets.zero,
//                           ),
//                         ),
//                       ),
//                       _buildCalendar(),
//                       if (_searchQuery.isNotEmpty)
//                         Padding(
//                           padding: const EdgeInsets.only(top: 16),
//                           child: _buildSearchInfo(),
//                         ),
//                     ],
//                   ),
//                 ),
//               ),
//               // Right side - Todo List
//               Expanded(
//                 flex: 2, // Changed from 3 to 2
//                 child: Padding(
//                   padding: const EdgeInsets.all(24),
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Padding(
//                         padding: const EdgeInsets.only(bottom: 24),
//                         child: Row(
//                           children: [
//                             Container(
//                               padding: const EdgeInsets.symmetric(
//                                 horizontal: 16,
//                                 vertical: 8,
//                               ),
//                               decoration: BoxDecoration(
//                                 gradient: const LinearGradient(
//                                   colors: [
//                                     Color(0xFF6C63FF),
//                                     Color(0xFF584DFF)
//                                   ],
//                                   begin: Alignment.topLeft,
//                                   end: Alignment.bottomRight,
//                                 ),
//                                 boxShadow: [
//                                   BoxShadow(
//                                     color: accentColor.withOpacity(0.3),
//                                     blurRadius: 8,
//                                     offset: const Offset(0, 2),
//                                   ),
//                                 ],
//                               ),
//                               child: InkWell(
//                                 onTap: () {
//                                   setState(() {
//                                     _isAddingTask = !_isAddingTask;
//                                     if (!_isAddingTask) {
//                                       _textController.clear();
//                                     }
//                                   });
//                                 },
//                                 child: Row(
//                                   mainAxisSize: MainAxisSize.min,
//                                   children: [
//                                     Icon(
//                                         _isAddingTask ? Icons.close : Icons.add,
//                                         color: Colors.white,
//                                         size: 20),
//                                     const SizedBox(width: 8),
//                                     Text(
//                                       _isAddingTask ? 'Cancel' : 'Add Task',
//                                       style: const TextStyle(
//                                         color: Colors.white,
//                                         fontSize: 14,
//                                         fontWeight: FontWeight.w500,
//                                       ),
//                                     ),
//                                   ],
//                                 ),
//                               ),
//                             ),
//                             const SizedBox(width: 16),
//                             Container(
//                               padding: const EdgeInsets.symmetric(
//                                 horizontal: 16,
//                                 vertical: 8,
//                               ),
//                               decoration: BoxDecoration(
//                                 color: accentColor.withOpacity(0.1),
//                                 borderRadius: BorderRadius.circular(20),
//                               ),
//                               child: Text(
//                                 '${_getFilteredTodos().length} tasks',
//                                 style: TextStyle(
//                                   color: accentColor,
//                                   fontSize: 14,
//                                   fontWeight: FontWeight.w500,
//                                 ),
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//                       if (_isAddingTask)
//                         Container(
//                           margin: const EdgeInsets.only(bottom: 24),
//                           padding: const EdgeInsets.symmetric(
//                             horizontal: 16,
//                             vertical: 8,
//                           ),
//                           decoration: BoxDecoration(
//                             gradient: cardGradient,
//                             borderRadius: BorderRadius.circular(16),
//                             boxShadow: [
//                               BoxShadow(
//                                 color: shadowColor.withOpacity(0.15),
//                                 blurRadius: 10,
//                                 offset: const Offset(0, 4),
//                               ),
//                             ],
//                           ),
//                           child: Row(
//                             children: [
//                               Expanded(
//                                 child: TextField(
//                                   controller: _textController,
//                                   style: TextStyle(color: textColor),
//                                   decoration: InputDecoration(
//                                     hintText: 'Enter task...',
//                                     hintStyle:
//                                         TextStyle(color: textColorSecondary),
//                                     border: InputBorder.none,
//                                     isDense: true,
//                                   ),
//                                   onSubmitted: (value) {
//                                     if (value.isNotEmpty) {
//                                       final newTodo = TodoItem(
//                                         title: value,
//                                         date: _selectedDate,
//                                       );
//                                       _saveTodo(newTodo);
//                                       _textController.clear();
//                                       setState(() {
//                                         _isAddingTask = false;
//                                       });
//                                     }
//                                   },
//                                 ),
//                               ),
//                               IconButton(
//                                 icon: Icon(Icons.send, color: accentColor),
//                                 onPressed: () {
//                                   if (_textController.text.isNotEmpty) {
//                                     final newTodo = TodoItem(
//                                       title: _textController.text,
//                                       date: _selectedDate,
//                                     );
//                                     _saveTodo(newTodo);
//                                     _textController.clear();
//                                     setState(() {
//                                       _isAddingTask = false;
//                                     });
//                                   }
//                                 },
//                               ),
//                             ],
//                           ),
//                         ),
//                       Expanded(
//                         child: ClipRRect(
//                           borderRadius: BorderRadius.circular(24),
//                           child: _buildTodoList(),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ),
//         backgroundColor: backgroundColor,
//       ),
//     );
//   }

//   Widget _buildCalendar() {
//     return Container(
//       margin: const EdgeInsets.symmetric(horizontal: 0),
//       decoration: BoxDecoration(
//         gradient: cardGradient,
//         boxShadow: [
//           BoxShadow(
//             color: shadowColor.withOpacity(0.15),
//             blurRadius: 20,
//             offset: const Offset(0, 10),
//           ),
//         ],
//       ),
//       padding: const EdgeInsets.all(16),
//       child: TableCalendar(
//         firstDay: DateTime.utc(2023, 1, 1),
//         lastDay: DateTime.utc(2030, 12, 31),
//         focusedDay: _selectedDate,
//         calendarFormat: _calendarFormat,
//         selectedDayPredicate: (day) => isSameDay(_selectedDate, day),
//         onDaySelected: (selectedDay, focusedDay) {
//           setState(() {
//             _selectedDate = selectedDay;
//           });
//         },
//         onFormatChanged: (format) {
//           setState(() {
//             _calendarFormat = format;
//           });
//         },
//         eventLoader: (day) {
//           return _getEventDays()
//               .where((eventDay) => isSameDay(eventDay, day))
//               .toList();
//         },
//         calendarStyle: CalendarStyle(
//           defaultTextStyle: TextStyle(
//               color: textColor, fontSize: 15, fontWeight: FontWeight.w500),
//           weekendTextStyle: TextStyle(
//               color: textColorSecondary,
//               fontSize: 15,
//               fontWeight: FontWeight.w500),
//           outsideTextStyle: TextStyle(color: textColorSecondary, fontSize: 15),
//           todayDecoration: BoxDecoration(
//             color: accentColor,
//             shape: BoxShape.circle,
//             boxShadow: [
//               BoxShadow(
//                 color: accentColor,
//                 blurRadius: 12,
//                 spreadRadius: -3,
//               ),
//             ],
//           ),
//           selectedDecoration: BoxDecoration(
//             gradient: LinearGradient(
//               colors: [Color(0xFF8B85FF), Color(0xFF6C63FF)],
//               begin: Alignment.topLeft,
//               end: Alignment.bottomRight,
//             ),
//             shape: BoxShape.circle,
//             boxShadow: [
//               BoxShadow(
//                 color: Color(0xFF6C63FF),
//                 blurRadius: 8,
//                 spreadRadius: -2,
//               ),
//             ],
//           ),
//           markerDecoration: BoxDecoration(
//             color: textColorSecondary,
//             shape: BoxShape.circle,
//           ),
//           markerSize: 6,
//           cellMargin: EdgeInsets.all(6),
//         ),
//         headerStyle: HeaderStyle(
//           formatButtonVisible: false,
//           titleTextStyle: TextStyle(color: textColor, fontSize: 14),
//           leftChevronIcon: Icon(Icons.chevron_left, color: textColor, size: 20),
//           rightChevronIcon:
//               Icon(Icons.chevron_right, color: textColor, size: 20),
//           headerMargin: EdgeInsets.only(bottom: 8),
//           titleCentered: true,
//         ),
//       ),
//     );
//   }

//   Widget _buildSearchInfo() {
//     return Padding(
//       padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
//       child: Row(
//         children: [
//           Icon(Icons.info_outline, color: textColorSecondary, size: 16),
//           const SizedBox(width: 4),
//           Text(
//             'Showing all matching todos',
//             style: TextStyle(color: textColorSecondary, fontSize: 12),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildTodoList() {
//     return Container(
//       margin: const EdgeInsets.all(0),
//       decoration: BoxDecoration(
//         color: surfaceColor,
//         boxShadow: [
//           BoxShadow(
//             color: shadowColor.withOpacity(0.1),
//             blurRadius: 20,
//             offset: const Offset(0, 10),
//           ),
//         ],
//       ),
//       child: ClipRRect(
//         borderRadius: BorderRadius.circular(20),
//         child: ListView.builder(
//           itemCount: _getFilteredTodos().length,
//           padding: const EdgeInsets.symmetric(vertical: 8),
//           itemBuilder: (context, index) {
//             final todo = _getFilteredTodos()[index];
//             return _buildTodoCard(todo);
//           },
//         ),
//       ),
//     );
//   }

//   Widget _buildTodoCard(TodoItem todo) {
//     return Container(
//       margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
//       decoration: BoxDecoration(
//         gradient: cardGradient,
//         borderRadius: BorderRadius.circular(16),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.1),
//             blurRadius: 10,
//             offset: const Offset(0, 4),
//           ),
//         ],
//       ),
//       child: ListTile(
//         contentPadding:
//             const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
//         title: Text(
//           todo.title,
//           style: TextStyle(
//             color: textColor,
//             fontSize: 16,
//             fontWeight: FontWeight.w500,
//             decoration: todo.isDone ? TextDecoration.lineThrough : null,
//             decorationColor: textColorSecondary,
//           ),
//         ),
//         subtitle: Container(
//           margin: const EdgeInsets.only(top: 6),
//           child: Text(
//             '${todo.date.day}/${todo.date.month}/${todo.date.year}',
//             style: TextStyle(
//               color: textColorSecondary,
//               fontSize: 13,
//             ),
//           ),
//         ),
//         trailing: Container(
//           height: 28,
//           width: 28,
//           decoration: BoxDecoration(
//             color:
//                 todo.isDone ? accentColor.withOpacity(0.1) : Colors.transparent,
//             borderRadius: BorderRadius.circular(8),
//           ),
//           child: Checkbox(
//             value: todo.isDone,
//             onChanged: (value) {
//               setState(() {
//                 todo.isDone = value!;
//                 todo.save();
//               });
//             },
//             checkColor: Colors.white,
//             fillColor: MaterialStateProperty.resolveWith((states) {
//               if (states.contains(MaterialState.selected)) {
//                 return accentColor;
//               }
//               return Colors.white24;
//             }),
//             shape: RoundedRectangleBorder(
//               borderRadius: BorderRadius.circular(8),
//             ),
//             materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
//           ),
//         ),
//       ),
//     );
//   }
// }