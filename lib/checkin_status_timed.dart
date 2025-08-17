import 'package:flutter/material.dart';
import 'event.dart';
import 'utility.dart';

class ChronologicalCheckinStatus extends StatelessWidget {
  final List<dynamic> riders;
  final Event event;

  const ChronologicalCheckinStatus(
      {super.key, required this.event, required this.riders});

  @override
  Widget build(BuildContext context) {
    // Build a flat list of all check-ins with rider reference
    final List<Map<String, dynamic>> allCheckins = [];

    for (final rider in riders) {
      final riderMap = rider as Map<String, dynamic>;
      final riderName = riderMap['rider_name'] ?? '';
      final checklist = riderMap['checklist'] as List<dynamic>? ?? [];

      for (int i = 0; i < checklist.length; i++) {
        final checkin = checklist[i];
        if (checkin == null) continue;
        if (checkin['is_prerideq'] ?? false) continue;

        allCheckins.add({
          'riderName': riderName,
          'controlIndex': i + 1,
          'checkinTime': checkin['checkin_datetime'],
          'comment': checkin['comment'] ?? '',
        });
      }
    }

    // Sort chronologically by checkinTime
    allCheckins.sort((a, b) {
      final aTime = DateTime.parse(a['checkinTime']);
      final bTime = DateTime.parse(b['checkinTime']);
      return bTime.compareTo(aTime);
    });

    if (allCheckins.isEmpty) {
      return const Center(child: Text("No check-ins recorded"));
    }

    return ListView.builder(
      itemCount: allCheckins.length,
      itemBuilder: (context, index) {
        final entry = allCheckins[index];
        final time =
            Utility.toBriefTimeString(DateTime.parse(entry['checkinTime']));
        final riderName = entry['riderName'];
        final control = entry['controlIndex'];
        final distance = event.controls[control - 1].distMi;
        final controlName = event.controls[control - 1].name;
        final comment = entry['comment'];

        return ListTile(
          leading: Container(
            padding: const EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.secondaryContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              time,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSecondaryContainer,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
          title: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                riderName,
                style: Theme.of(context).textTheme.titleSmall,
              ),
              if (comment != null &&
                  comment.trim().isNotEmpty &&
                  !comment.contains("Automatic Check In"))
                // Let long comments wrap without overflowing the tile
                Flexible(
                  child: Transform.translate(
                    offset: const Offset(4, -6), // lift bubble upward a bit
                    child: Padding(
                      padding: const EdgeInsets.only(
                          left: 8.0), // gap after the name
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          // Bubble
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10.0, vertical: 6.0),
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .colorScheme
                                  .secondaryContainer,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              comment,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                            ),
                          ),
                          // Stem
                          const Positioned(
                            left: -6, // sticks out to the left of the bubble
                            top: 10, // tweak to taste
                            child: _BubbleStem(),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
          subtitle: Text("($control) $controlName ($distance mi)"),
        );
      },
    );
  }
}

class _BubbleStem extends StatelessWidget {
  const _BubbleStem();

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: 0.785398, // 45 degrees in radians
      child: Container(
        width: 10,
        height: 10,
        color: Theme.of(context).colorScheme.secondaryContainer,
      ),
    );
  }
}
