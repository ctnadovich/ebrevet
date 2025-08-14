import 'package:flutter/material.dart';

class RiderCheckinDetailsPage extends StatelessWidget {
  final Map<String, dynamic> rider;

  const RiderCheckinDetailsPage({super.key, required this.rider});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(rider['rider_name'] ?? 'Rider Details'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // TODO: Add widgets to display rider details here
          // Example:
          // Text('Rider ID: ${rider['rider_id']}'),
          // Text('Result: ${rider['result']}'),
        ],
      ),
    );
  }
}
