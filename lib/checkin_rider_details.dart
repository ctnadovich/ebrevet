import 'package:ebrevet_card/utility.dart';
import 'package:flutter/material.dart';
import 'checkin_helpers.dart'; // convertToLocalTime
import 'checkin_progress.dart';
import 'control.dart'; // For Control and ControlStyle
import 'event.dart';

class RiderCheckinDetailsPage extends StatelessWidget {
  final Map<String, dynamic> rider;
  final Event event; // Pass this from Event object

  const RiderCheckinDetailsPage({
    super.key,
    required this.rider,
    required this.event,
  });

  @override
  Widget build(BuildContext context) {
    final List<dynamic>? checklist = rider['checklist'];

    // Filter out nulls
    final validCheckins =
        checklist?.asMap().entries.where((e) => e.value != null).toList();

    final bool isPreride =
        (checklist != null && checklist.isNotEmpty && checklist[0] != null)
            ? (checklist[0]['is_prerideq'] == true)
            : false;

    final DateTime? prerideStartDateTime = (isPreride)
        ? DateTime.parse(checklist[0]['checkin_datetime']).toLocal()
        : null;

    final result = rider['result']?.toString() ?? '';
    final elapsedTime = rider['elapsed_time']?.toString() ?? '';
    final List<Control> controls = event.controls;
    final String eventName = event.nameDist;

    return Scaffold(
      appBar: AppBar(
        title: Text(rider['rider_name'] ?? 'Rider Details'),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ===== HEADER SECTION =====
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(eventName,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        )),
                if (isPreride) ...[
                  Row(
                    children: [
                      const Icon(Icons.directions_bike_outlined),
                      const SizedBox(width: 6),
                      Text(
                          "PRE RIDE starting ${Utility.toBriefDateTimeString(prerideStartDateTime)} "),
                    ],
                  ),
                ],
                if (result.isNotEmpty) ...[
                  Row(
                    children: [
                      Icon(
                        result.toUpperCase() == "FINISH"
                            ? Icons.flag
                            : result.toUpperCase() == "ACTIVE"
                                ? Icons.directions_bike
                                : Icons.info_outline,
                        size: 16,
                        color: Colors.blueGrey,
                      ),
                      const SizedBox(width: 6),
                      Text("Status: $result"),
                    ],
                  ),
                  if (result.toUpperCase() == "FINISH" &&
                      elapsedTime.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(Icons.timer,
                            size: 16, color: Colors.blueGrey),
                        const SizedBox(width: 6),
                        Text("Elapsed Time: $elapsedTime"),
                      ],
                    ),
                  ],
                  const SizedBox(height: 12),
                ],
                if (checklist != null && checklist.isNotEmpty)
                  CheckinProgress(checklist: checklist),
              ],
            ),
          ),

          const Divider(height: 1),

          // ===== SCROLLABLE CHECKIN LIST =====
          Expanded(
            child: validCheckins == null || validCheckins.isEmpty
                ? const Center(child: Text("No checkins available"))
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: validCheckins.length,
                    itemBuilder: (context, index) {
                      final entryIndex = validCheckins[index].key;
                      final checkin = validCheckins[index].value;

                      // Extract comment, skipping "Automatic Check In"
                      String? comment;
                      final rawComment = checkin?['comment']?.toString().trim();
                      if (rawComment != null &&
                          rawComment.isNotEmpty &&
                          !rawComment.contains("Automatic Check In")) {
                        comment = rawComment;
                      }

                      // Lookup the corresponding control
                      Control? control;
                      if (entryIndex < controls.length) {
                        control = controls[entryIndex];
                      }

                      if (control == null) throw Exception('Null control');

                      final checkinText =
                          formatCheckinWithControlTimes(checkin, control);

                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 6.0),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.check_circle_outline_outlined,
                                    color: Colors.green,
                                    size: 30,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      checkinText,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "${control.name} (${control.style.name}, ${control.distMi.toStringAsFixed(1)} mi)",
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                              if (control.address.isNotEmpty)
                                Text(
                                  control.address,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(color: Colors.grey[700]),
                                ),
                              Text(
                                "OPEN: ${control.openTimeString}",
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(color: Colors.grey[700]),
                              ),
                              Text(
                                "CLOSE: ${control.closeTimeString}",
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(color: Colors.grey[700]),
                              ),
                              if (comment != null) ...[
                                const SizedBox(height: 4),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Icon(Icons.comment,
                                        size: 16, color: Colors.blueGrey),
                                    const SizedBox(width: 6),
                                    Expanded(child: Text(comment)),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
