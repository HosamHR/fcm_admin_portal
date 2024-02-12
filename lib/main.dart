import 'dart:async';
import 'dart:convert';

// #docregion Import
import 'package:fcm_admin_portal/schedule_medication_reminder.dart';
import 'package:fcm_admin_portal/send_reminder_page.dart';
// #enddocregion Import
import 'package:flutter/material.dart' hide Notification;
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_strategy/url_strategy.dart';

enum Routes {
  sendMedication,
  scheduleMedication,
}

final _router = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const Home(),
    ),
    GoRoute(
      name: Routes.scheduleMedication.name,
      path: '/schedule_mediation_reminder',
      builder: (context, state) => const ScheduleMedicationReminderPage(),
    ),
    GoRoute(
      name: Routes.sendMedication.name,
      path: '/send_mediation_reminder',
      builder: (context, state) => const SendReminderPage(),
    )
  ],
);

late final SharedPreferences sharedPreferences;
void main() async {
  setPathUrlStrategy();
  sharedPreferences = await SharedPreferences.getInstance();
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      routerConfig: _router,
    );
  }
}

class Home extends StatefulWidget {
  const Home({
    super.key,
  });

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ElevatedButton(
                onPressed: () {
                  context.goNamed(Routes.sendMedication.name);
                },
                child: const Text('Send Medication Reminder Page'),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: () {
                  context.goNamed(Routes.scheduleMedication.name);
                },
                child: const Text('Schedule Medication Reminder Page'),
              )
            ],
          ),
        ),
      ),
    );
  }
}

Future<Map<String, dynamic>> refreshToken(
  String token,
  String provider,
  String apiKey,
) async {
  final url = Uri.parse('https://identitytoolkit.googleapis.com/v1/accounts:signInWithIdp?key=$apiKey');

  final response = await http.post(url,
      headers: {'Content-type': 'application/json'},
      body: jsonEncode({
        'postBody': 'id_token=$token&providerId=$provider',
        'requestUri': 'http://localhost',
        'returnIdpCredential': true,
        'returnSecureToken': true
      }));
  if (response.statusCode != 200) {
    throw 'Refresh token request failed: ${response.statusCode}';
  }

  final data = Map<String, dynamic>.of(jsonDecode(response.body));
  if (data.containsKey('refreshToken')) {
    return data;
  } else {
    throw 'No refresh token in response';
  }
}
