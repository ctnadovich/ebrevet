import 'package:flutter/material.dart';
import 'event.dart';
import 'utility.dart';
import 'checkin.dart';

class ChronologicalCheckinStatus extends StatelessWidget {
  final List<RiderResults> riders;
  final Event event;

  const ChronologicalCheckinStatus(
      {super.key, required this.event, required this.riders});

  @override
  Widget build(BuildContext context) {
    final allCheckins = riders.toTimeline();

    if (allCheckins.isEmpty) {
      return const Center(child: Text("No check-ins recorded"));
    }

    return ListView.builder(
      itemCount: allCheckins.length,
      itemBuilder: (context, index) {
        final checkin = allCheckins[index];

        final control = checkin.controlIndex;
        final distance = event.controls[control - 1].distMi;
        final controlName = event.controls[control - 1].name;

        return ListTile(
          leading: Container(
            padding: const EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.secondaryContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              Utility.toBriefTimeString(checkin.dateTime),
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
                checkin.riderName,
                style: Theme.of(context).textTheme.titleSmall,
              ),
              if (checkin.text.trim().isNotEmpty &&
                  !checkin.text.contains("Automatic Check In"))
                Flexible(
                  child: Transform.translate(
                    offset: const Offset(4, -6), // lift bubble upward a bit
                    child: Padding(
                      padding: const EdgeInsets.only(left: 8.0),
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
                              checkin.text,
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
                            left: -6,
                            top: 10,
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

    // return ListView.builder(
    //   itemCount: allCheckins.length,
    //   itemBuilder: (context, index) {
    //     final entry = allCheckins[index];
    //     final time =
    //         Utility.toBriefTimeString(DateTime.parse(entry['checkinTime']));
    //     final riderName = entry['riderName'];
    //     final control = entry['controlIndex'];
    //     final distance = event.controls[control - 1].distMi;
    //     final controlName = event.controls[control - 1].name;
    //     final comment = entry['comment'];

    //     return ListTile(
    //       leading: Container(
    //         padding: const EdgeInsets.all(8.0),
    //         decoration: BoxDecoration(
    //           color: Theme.of(context).colorScheme.secondaryContainer,
    //           borderRadius: BorderRadius.circular(8),
    //         ),
    //         child: Text(
    //           time,
    //           style: Theme.of(context).textTheme.titleSmall?.copyWith(
    //                 color: Theme.of(context).colorScheme.onSecondaryContainer,
    //                 fontWeight: FontWeight.bold,
    //               ),
    //         ),
    //       ),
    //       title: Row(
    //         crossAxisAlignment: CrossAxisAlignment.start,
    //         children: [
    //           Text(
    //             riderName,
    //             style: Theme.of(context).textTheme.titleSmall,
    //           ),
    //           if (comment != null &&
    //               comment.trim().isNotEmpty &&
    //               !comment.contains("Automatic Check In"))
    //             // Let long comments wrap without overflowing the tile
    //             Flexible(
    //               child: Transform.translate(
    //                 offset: const Offset(4, -6), // lift bubble upward a bit
    //                 child: Padding(
    //                   padding: const EdgeInsets.only(
    //                       left: 8.0), // gap after the name
    //                   child: Stack(
    //                     clipBehavior: Clip.none,
    //                     children: [
    //                       // Bubble
    //                       Container(
    //                         padding: const EdgeInsets.symmetric(
    //                             horizontal: 10.0, vertical: 6.0),
    //                         decoration: BoxDecoration(
    //                           color: Theme.of(context)
    //                               .colorScheme
    //                               .secondaryContainer,
    //                           borderRadius: BorderRadius.circular(12),
    //                         ),
    //                         child: Text(
    //                           comment,
    //                           style: Theme.of(context)
    //                               .textTheme
    //                               .bodySmall
    //                               ?.copyWith(
    //                                 color: Theme.of(context)
    //                                     .colorScheme
    //                                     .onSurfaceVariant,
    //                               ),
    //                         ),
    //                       ),
    //                       // Stem
    //                       const Positioned(
    //                         left: -6, // sticks out to the left of the bubble
    //                         top: 10, // tweak to taste
    //                         child: _BubbleStem(),
    //                       ),
    //                     ],
    //                   ),
    //                 ),
    //               ),
    //             ),
    //         ],
    //       ),
    //       subtitle: Text("($control) $controlName ($distance mi)"),
    //     );
    //   },
    // );
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
