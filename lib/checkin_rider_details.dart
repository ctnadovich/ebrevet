import 'package:ebrevet_card/utility.dart';
import 'package:flutter/material.dart';
import 'checkin_progress.dart';
import 'control.dart'; // For Control and ControlStyle
import 'event.dart';
import 'checkin.dart';

class RiderCheckinDetailsPage extends StatelessWidget {
  final RiderResults rider;
  final Event event; // Pass this from Event object

  const RiderCheckinDetailsPage({
    super.key,
    required this.rider,
    required this.event,
  });

  @override
  Widget build(BuildContext context) {
    final List<Checkin> checklist = rider.checklist;

    final bool isPreride =
        rider.isReallyPreride ?? false; // assume not preride if no checkins

    final DateTime? prerideStartDateTime =
        (isPreride) ? checklist[0].checkinDatetime : null;

    //final result = rider.result ?? '';
    final elapsedTime = rider.formatElapsedHHMM();
    final List<Control> controls = event.controls;
    final numControls = controls.length;
    final String eventName = event.nameDist;

    return Scaffold(
      appBar: AppBar(
        title: Text(rider.riderName),
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
                if (rider.result.isNotEmpty) ...[
                  Row(
                    children: [
                      Icon(
                        rider.result.toUpperCase() == "FINISH"
                            ? Icons.flag
                            : rider.result.toUpperCase() == "ACTIVE"
                                ? Icons.directions_bike
                                : Icons.info_outline,
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
                        const Icon(Icons.timer,
                            size: 16, color: Colors.blueGrey),
                        const SizedBox(width: 6),
                        Text("Elapsed Time: $elapsedTime"),
                      ],
                    ),
                  ],
                  const SizedBox(height: 12),
                ],
                if (checklist.isNotEmpty)
                  CheckinProgress(
                    checklist: checklist,
                    numControls: numControls,
                  ),
              ],
            ),
          ),

          const Divider(height: 1),

          // ===== SCROLLABLE CHECKIN LIST =====
          Expanded(
            child: checklist.isEmpty
                ? const Center(child: Text("No checkins available"))
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: checklist.length,
                    itemBuilder: (context, index) {
                      final checkin = checklist[index];

                      // Extract comment, skipping "Automatic Check In"
                      String? comment;
                      final rawComment = (checkin.comment ?? "").trim();
                      if (rawComment.isNotEmpty &&
                          !rawComment.contains("Automatic Check In")) {
                        comment = rawComment;
                      }

                      // Lookup the corresponding control
                      Control? control;
                      if (checkin.index > 0 &&
                          checkin.index <= controls.length) {
                        control = controls[checkin.index - 1];
                      }

                      if (control == null) throw Exception('Null control');

                      final checkinText =
                          checkin.formatCheckinWithControlTimes(control);

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
