import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import '../models/task.dart';
import '../main.dart';
import 'todo_page.dart';
import 'settings_page.dart';

class HomeScreen extends StatefulWidget {
  final String name;
  const HomeScreen({super.key, required this.name});

  @override
  State<HomeScreen> createState() => _HomeScreen();
}

class _HomeScreen extends State<HomeScreen> {
  int _selectedIndex = 0;
  List<Task> _tasks = [];

  @override
  void initState() {
    super.initState();
    _loadTasksFromMemory();
    _requestPermissions();
  }

  Future<void> _requestPermissions() async {
    if (Platform.isAndroid) {
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          flutterLocalNotificationsPlugin
              .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin
              >();

      if (androidImplementation != null) {
        await androidImplementation.requestNotificationsPermission();
      }
    }
  }

  Future<bool> _checkExactAlarmPermission() async {
    if (Platform.isAndroid) {
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          flutterLocalNotificationsPlugin
              .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin
              >();

      if (androidImplementation != null) {
        final bool? granted = await androidImplementation
            .requestExactAlarmsPermission();
        return granted ?? false;
      }
    }
    return true;
  }

  Future<void> _loadTasksFromMemory() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String>? taskStrings = prefs.getStringList('saved_tasks_json');

    if (taskStrings != null) {
      setState(() {
        _tasks = taskStrings
            .map((str) => Task.fromMap(jsonDecode(str)))
            .toList();
      });
    }
  }

  Future<void> _saveTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> taskStrings = _tasks
        .map((task) => jsonEncode(task.toMap()))
        .toList();

    await prefs.setStringList('saved_tasks_json', taskStrings);
  }

  Future<void> _showImmediateNotification(Task task) async {
    if (!Platform.isAndroid) return;
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'task_channel_id',
          'Task Reminders',
          channelDescription: 'Notifications for tasks',
          importance: Importance.max,
          priority: Priority.high,
          icon: '@drawable/app_icon',
        );
    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
    );

    await flutterLocalNotificationsPlugin.show(
      task.id,
      'Task Created!',
      task.title,
      details,
    );
  }

  Future<void> _scheduleNotification(Task task) async {
    if (task.date == null) return;
    if (!Platform.isAndroid) return;
    final now = DateTime.now();

    if (task.date!.isBefore(now)) {
      debugPrint("Scheduled time is in the past. Notification skipped.");
      return;
    }

    await _checkExactAlarmPermission();

    final scheduledTime = tz.TZDateTime.from(task.date!, tz.local);

    try {
      await flutterLocalNotificationsPlugin.zonedSchedule(
        task.id,
        'It is time! ⏰',
        task.title,
        scheduledTime,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'task_channel_id',
            'Task Reminders',
            importance: Importance.max,
            priority: Priority.high,
            icon: '@drawable/app_icon',
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
      debugPrint("Notification Scheduled for: $scheduledTime");
    } catch (e) {
      debugPrint("Error scheduling notification: $e");
    }
  }

  Future<void> _cancelNotification(int id) async {
    if (!Platform.isAndroid) return;
    await flutterLocalNotificationsPlugin.cancel(id);
  }

  void _addNewTask(String title, DateTime? selectedDate) async {
    final newTask = Task(title: title, date: selectedDate);

    setState(() {
      _tasks.add(newTask);
    });

    await _saveTasks();
    if (!mounted) return;
    Navigator.pop(context);

    if (selectedDate != null) {
      await _scheduleNotification(newTask);
    } else {
      await _showImmediateNotification(newTask);
    }
  }

  void _deleteTask(int index) async {
    await _cancelNotification(_tasks[index].id);

    setState(() {
      _tasks.removeAt(index);
    });
    _saveTasks();
  }

  void _toggleTask(int index) async {
    setState(() {
      _tasks[index].isCompleted = !_tasks[index].isCompleted;
    });
    _saveTasks();

    if (_tasks[index].isCompleted) {
      await _cancelNotification(_tasks[index].id);
    }
  }

  Future<DateTime?> _pickDateTime(BuildContext context) async {
    final DateTime? date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (date == null) return null;
    if (!context.mounted) return null;

    final TimeOfDay? time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (time == null) return null;

    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  void _showAddTaskSheet() {
    TextEditingController taskController = TextEditingController();
    DateTime? tempDate;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                left: 20,
                right: 20,
                top: 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    "New Task",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 15),
                  TextField(
                    controller: taskController,
                    autofocus: true,
                    decoration: const InputDecoration(
                      hintText: "What to do?",
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.task_alt),
                    ),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: () async {
                      final DateTime? picked = await _pickDateTime(context);
                      if (picked != null) {
                        setSheetState(() {
                          tempDate = picked;
                        });
                      }
                    },
                    icon: const Icon(Icons.calendar_month),
                    label: Text(
                      tempDate == null
                          ? "Select Date & Time"
                          : "${tempDate!.day}/${tempDate!.month}/${tempDate!.year} ${tempDate!.hour}:${tempDate!.minute.toString().padLeft(2, '0')}",
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: tempDate == null
                          ? Colors.grey
                          : Colors.blue,
                    ),
                  ),
                  const SizedBox(height: 15),
                  ElevatedButton(
                    onPressed: () {
                      if (taskController.text.isNotEmpty) {
                        _addNewTask(taskController.text, tempDate);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                    ),
                    child: const Text("ADD TASK"),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      TodoPage(
        name: widget.name,
        tasks: _tasks,
        onDelete: _deleteTask,
        onToggle: _toggleTask,
      ),
      const SettingsPage(),
    ];
    return Scaffold(
      body: pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blue,
        onTap: _onItemTapped,
      ),
      floatingActionButton: _selectedIndex == 0
          ? FloatingActionButton(
              onPressed: _showAddTaskSheet,
              backgroundColor: Colors.blue,
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}
