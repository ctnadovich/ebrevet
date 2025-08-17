import 'package:flutter/material.dart';
import 'event.dart';
import 'checkin_rider_details.dart'; // adjust import to your path
import 'checkin_helpers.dart';
import 'checkin_progress.dart';

class RiderCheckinStatus extends StatelessWidget {
  final List<dynamic> riders;
  final Event event;

  const RiderCheckinStatus(
      {super.key, required this.event, required this.riders});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
      children: [
// Event details header

        // Rider cards
        ...riders.map((riderData) {
          final rider = riderData as Map<String, dynamic>;

          return RiderCheckinCard(rider: rider, event: event);
        }).toList(),
      ],
    );
  }
}

class RiderCheckinCard extends StatelessWidget {
  final Map<String, dynamic> rider;
  final Event event;

  const RiderCheckinCard({
    super.key,
    required this.rider,
    required this.event,
  });

  @override
  Widget build(BuildContext context) {
    final riderName = rider['rider_name'] ?? '';
    final riderId = rider['rider_id'] ?? '';
    final result = (rider['result'] ?? '').toString().trim();
    final elapsedTime = rider['elapsed_time'] ?? '';
    final checklist = rider['checklist'] as List<dynamic>? ?? [];
    final comments = extractComments(checklist);
    // .where((e) => !(e['comment'] as String).contains('Automatic Check In'))
    // .map((e) => "(${e['index'] + 1}) ${e['comment']}")
    // .join(', ');

    String lastCheckInText = "None";
    final lastCheckIn = getLastCheckin(checklist);
    if (lastCheckIn != null) {
      final i = lastCheckIn['index'];
      final t = convertToLocalTime(lastCheckIn['checkin_datetime']);
      lastCheckInText = "Control $i, $t";
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 8.0),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// Rider name + details icon
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    "$riderName ($riderId)",
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.arrow_forward_ios, size: 18),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            RiderCheckinDetailsPage(rider: rider, event: event),
                      ),
                    );
                  },
                ),
              ],
            ),

            const SizedBox(height: 4),

            /// Status + elapsed time
            if (result.isNotEmpty) ...[
              Row(
                children: [
                  Icon(
                    () {
                      switch (result.toUpperCase()) {
                        case "FINISH":
                          return Icons.flag;
                        case "ACTIVE":
                          return Icons.directions_bike;
                        default:
                          return Icons.info_outline;
                      }
                    }(),
                    size: 16,
                    color: Colors.blueGrey,
                  ),
                  const SizedBox(width: 6),
                  Text("Status: $result"),
                ],
              ),
              if (result.toUpperCase() == "FINISH") ...[
                const SizedBox(height: 2),
                Row(
                  children: [
                    const Icon(Icons.timer, size: 16, color: Colors.blueGrey),
                    const SizedBox(width: 6),
                    Text("Elapsed Time: $elapsedTime"),
                  ],
                ),
              ],
            ],

            const SizedBox(height: 6),

            /// Last check-in + progress
            if (result.toUpperCase() != "FINISH") ...[
              Text(
                "Last check-in: $lastCheckInText",
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 4),
              if (lastCheckInText != 'None')
                CheckinProgress(checklist: checklist),
            ],

            /// Last comment
            if (comments.isNotEmpty) ...[
              Row(
                children: [
                  const Icon(Icons.comment, size: 16, color: Colors.blueGrey),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      "@ Control ${comments.last['index']}: ${comments.last['comment']}",
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
