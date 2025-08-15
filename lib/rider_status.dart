import 'package:flutter/material.dart';
import 'dart:convert';
import 'checkin_detail.dart';
import 'event.dart';
import 'future_events.dart';
import 'exception.dart';
import 'utility.dart';

class CheckinStatusPage extends StatelessWidget {
  final Event event;

  const CheckinStatusPage({super.key, required this.event});

  Future<List<dynamic>> _fetchRiderData() async {
    String url = "${event.checkinStatusUrl}/json";

    String responseBody = await FutureEvents.fetchResponseFromServer(url);
    List<dynamic> decodedResponse = jsonDecode(responseBody);

    if (decodedResponse.isEmpty) {
      throw ServerException('Empty reponse from $url');
    }

    return decodedResponse;
  }

  String? convertToLocalTime(String? isoString) {
    if (isoString == null) return null;
    try {
      final dt = DateTime.parse(isoString).toLocal();
      return Utility.toBriefDateTimeString(dt);
    } catch (e) {
      return null;
    }
  }

  String? buildChecklistSummary(List<dynamic>? checklist) {
    if (checklist == null) return null;

    final times = checklist
        .asMap()
        .entries
        .where((entry) =>
            entry.value != null && entry.value['checkin_datetime'] != null)
        .map((entry) {
          final controlNum = entry.key + 1;
          final time =
              convertToLocalTime(entry.value['checkin_datetime'] as String?);
          return time != null ? "($controlNum) $time" : null;
        })
        .whereType<String>()
        .toList();

    return times.isNotEmpty ? times.join(", ") : null;
  }

  Widget buildChecklistProgress(List<dynamic>? checklist) {
    if (checklist == null || checklist.isEmpty) {
      return const Text("No checkpoints");
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final count = checklist.length;
        final maxWidth = constraints.maxWidth;
        final circleDiameter = (maxWidth / count) - 6; // spacing adjustment
        // final radius = (circleDiameter / 2).clamp(8, 20); // min/max size
        final radius = ((circleDiameter / 2).clamp(8.0, 20.0)).toDouble();

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: checklist.asMap().entries.map((entry) {
            final index = entry.key;
            final controlNum = index + 1;
            final hasCheckin = entry.value?['checkin_datetime'] != null;

            return CircleAvatar(
              radius: radius,
              backgroundColor: hasCheckin ? Colors.green : Colors.grey.shade400,
              child: Text(
                "$controlNum",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: radius * 0.9,
                  fontWeight: FontWeight.bold,
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Map<String, dynamic>? getLastCheckin(List<dynamic>? checklist) {
    if (checklist == null || checklist.isEmpty) return null;

    for (int i = checklist.length - 1; i >= 0; i--) {
      final item = checklist[i] as Map<String, dynamic>?;
      if (item != null) {
        item['index'] = i + 1;
        return item;
      }
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Control Check-Ins")),
      body: FutureBuilder<List<dynamic>>(
        future: _fetchRiderData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No data available'));
          }

          final riders = snapshot.data!;

          return ListView.builder(
            itemCount: riders.length,
            itemBuilder: (context, index) {
              final rider = riders[index] as Map<String, dynamic>;

              final riderName = rider['rider_name'] ?? '';
              final riderId = rider['rider_id'] ?? '';
              final result = (rider['result'] ?? '').toString().trim();
              final elapsedTime = rider['elapsed_time'] ?? '';
              final checklist = rider['checklist'] ?? [];

              if (checklist == null || checklist.isEmpty) {
                return const Text("No checkpoints");
              }
              final lastCheckIn = getLastCheckin(checklist);
              String lastCheckInText = "None";
              if (lastCheckIn != null) {
                final i = lastCheckIn['index'];
                final t = convertToLocalTime(lastCheckIn['checkin_datetime']);
                lastCheckInText = "Control $i @ $t";
              }

              return Card(
                margin:
                    const EdgeInsets.symmetric(vertical: 6.0, horizontal: 8.0),
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
                        Text("Status: $result"),
                        if (result.toUpperCase() == "FINISH") ...[
                          const SizedBox(height: 2),
                          Text("Elapsed Time: $elapsedTime"),
                        ],
                      ],
                      const SizedBox(height: 6),
                      if (result.toUpperCase() != "FINISH")
                        Text(
                          "Last check-in: $lastCheckInText",
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      const SizedBox(height: 4),
                      if (result.toUpperCase() != "FINISH")
                        buildChecklistProgress(
                            rider['checklist'] as List<dynamic>?),
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
    );
  }
}
