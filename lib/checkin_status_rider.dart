import 'package:ebrevet_card/checkin.dart';
import 'package:flutter/material.dart';
import 'event.dart';
import 'checkin_rider_details.dart'; // adjust import to your path
import 'checkin_progress.dart';
import 'utility.dart';

class RiderCheckinStatus extends StatelessWidget {
  final List<RiderResults> riders;
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
          final rider = riderData;

          return RiderCheckinCard(rider: rider, event: event);
        }).toList(),
      ],
    );
  }
}

class RiderCheckinCard extends StatelessWidget {
  final RiderResults rider;
  final Event event;

  const RiderCheckinCard({
    super.key,
    required this.rider,
    required this.event,
  });

  @override
  Widget build(BuildContext context) {
    final comments = rider.extractComments();
    final numControls = event.controls.length;

    String lastCheckInText = "None";
    if (rider.isReallyPreride == false && rider.checklist.isNotEmpty) {
      final i = rider.checklist.length;
      final t =
          Utility.toBriefDateTimeString(rider.checklist.last.checkinDatetime);
      lastCheckInText = "Control $i/$numControls, $t";
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
                    "${rider.riderName} (${rider.riderId})",
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
            if (rider.result.isNotEmpty) ...[
              Row(
                children: [
                  Icon(
                    () {
                      switch (rider.result.toUpperCase()) {
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
                  Text("Status: ${rider.result}"),
                ],
              ),
              if (rider.result.toUpperCase() == "FINISH") ...[
                const SizedBox(height: 2),
                Row(
                  children: [
                    const Icon(Icons.timer, size: 16, color: Colors.blueGrey),
                    const SizedBox(width: 6),
                    Text("Elapsed Time: ${rider.formatElapsedHHMM()}"),
                  ],
                ),
              ],
            ],

            const SizedBox(height: 6),

            /// Last check-in + progress
            if (rider.result.toUpperCase() != "FINISH") ...[
              Text(
                "Last check-in: $lastCheckInText",
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 4),
              if (lastCheckInText != 'None')
                CheckinProgress(
                    checklist: rider.checklist, numControls: numControls),
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
