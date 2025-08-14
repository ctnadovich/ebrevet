import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'checkin_detail.dart';

class RiderStatusDialog extends StatelessWidget {
  final String url;

  const RiderStatusDialog({super.key, required this.url});

  Future<List<dynamic>> _fetchRiderData() async {
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      return json.decode(response.body) as List<dynamic>;
    } else {
      throw Exception('Failed to load rider status');
    }
  }

  String? convertToLocalTime(String? isoString) {
    if (isoString == null) return null;
    try {
      final dt = DateTime.parse(isoString).toLocal();
      final hours = dt.hour.toString().padLeft(2, '0');
      final minutes = dt.minute.toString().padLeft(2, '0');
      return "$hours:$minutes";
    } catch (e) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Rider Status"),
      content: SizedBox(
        width: double.maxFinite,
        child: FutureBuilder<List<dynamic>>(
          future: _fetchRiderData(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Text('Error: ${snapshot.error}');
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Text('No data available');
            }

            final riders = snapshot.data!;
            return ListView.builder(
              shrinkWrap: true,
              itemCount: riders.length,
              itemBuilder: (context, index) {
                final rider = riders[index] as Map<String, dynamic>;

                final riderName = rider['rider_name'] ?? '';
                final riderId = rider['rider_id'] ?? '';
                final result = (rider['result'] ?? '').toString().trim();
                final elapsedTime = rider['elapsed_time'] ?? '';

                final checklist = rider['checklist'] as List<dynamic>? ?? [];
                final times = checklist
                    .asMap()
                    .entries
                    .where((entry) =>
                        entry.value != null &&
                        entry.value['checkin_datetime'] != null)
                    .map((entry) {
                      final controlNum = entry.key + 1;
                      final time = convertToLocalTime(
                          entry.value['checkin_datetime'] as String?);
                      return time != null ? "($controlNum) $time" : null;
                    })
                    .where((time) => time != null)
                    .cast<String>()
                    .toList();

                final checklistSummary =
                    times.isNotEmpty ? times.join(", ") : null;

                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 6.0),
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "$riderName ($riderId)",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        if (result.isNotEmpty) ...[
                          Text("Result: $result"),
                          if (result.toUpperCase() == "FINISH") ...[
                            const SizedBox(height: 2),
                            Text("Elapsed Time: $elapsedTime"),
                          ],
                        ],
                        if (checklistSummary != null) ...[
                          const SizedBox(height: 6),
                          Text("Checkpoints: $checklistSummary"),
                        ],
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerRight,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      RiderCheckinDetailsPage(rider: rider),
                                ),
                              );
                            },
                            child: const Text('Details'),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text("Close"),
        ),
      ],
    );
  }
}
