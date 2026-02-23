import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await _configureLocalTimeZone();

  if (Platform.isAndroid) {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@drawable/app_icon');

    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse:
          (NotificationResponse notificationResponse) {
            debugPrint("Notification Clicked: ${notificationResponse.payload}");
          },
    );
  }

  runApp(const MyApp());
}

Future<void> _configureLocalTimeZone() async {
  tz.initializeTimeZones();
  try {
    var timeZoneResult = await FlutterTimezone.getLocalTimezone();
    String timeZoneName = timeZoneResult.toString();
    tz.setLocalLocation(tz.getLocation(timeZoneName));
    debugPrint("Timezone explicitly set to: $timeZoneName");
  } catch (e) {
    debugPrint("Could not detect timezone, falling back to UTC. Error: $e");
    tz.setLocalLocation(tz.getLocation('UTC'));
  }
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String? savedName;
  bool isNameRead = false;

  @override
  void initState() {
    super.initState();
    checkName();
  }

  Future<void> checkName() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString('user_name');

    setState(() {
      savedName = name;
      isNameRead = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isNameRead == false) {
      return const MaterialApp(
        home: Scaffold(body: Center(child: CircularProgressIndicator())),
      );
    }
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Swift Task',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: savedName == null
          ? const LoginScreen()
          : HomeScreen(name: savedName!),
    );
  }
}
