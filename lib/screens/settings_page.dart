import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../main.dart';
import 'login_screen.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  Future<void> resetData(BuildContext context) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      if (Platform.isAndroid) {
        await flutterLocalNotificationsPlugin.cancelAll();
      }
      debugPrint("Data cleared successfully!");
    } catch (e) {
      debugPrint("ERROR: $e");
    } finally {
      if (context.mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Settings"),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const SizedBox(height: 20),
          const Text(
            "Account Actions",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text("Log Out & Clear Data"),
            subtitle: const Text("Remove user info and go back to login"),
            onTap: () => resetData(context),
          ),
        ],
      ),
    );
  }
}
