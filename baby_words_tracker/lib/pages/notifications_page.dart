import 'package:flutter/material.dart';

class NotificationsPage extends StatelessWidget {
  static const routeName = '/notifications';

  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final sampleNotifications = [
      "Don't forget to log today's words!",
      "New word added: 'nana'",
      "Check your weekly progress report.",
      "Reminder: Upload your next video.",
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
      ),
      body: ListView.builder(
        itemCount: sampleNotifications.length,
        itemBuilder: (context, index) {
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListTile(
              leading: const Icon(Icons.notifications),
              title: Text(sampleNotifications[index]),
            ),
          );
        },
      ),
    );
  }
}
