import 'package:flutter/material.dart';
import 'checkin_status_rider.dart';
import 'checkin_status_timed.dart';
import 'event.dart';
import 'event_header_card.dart';
// import 'activated_event.dart';
// import 'my_activated_events.dart';
import 'checkin.dart';

class CheckinStatusPage extends StatefulWidget {
  final Event event;
//   final ActivatedEvent? activatedEvent;

  const CheckinStatusPage({super.key, required this.event});
  // : activatedEvent =
  //       MyActivatedEvents.lookupMyActivatedEvent(event.eventID);

  @override
  State<CheckinStatusPage> createState() => _CheckinStatusPageState();
}

class _CheckinStatusPageState extends State<CheckinStatusPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late Future<List<RiderResults>> _riderResults;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _riderResults = RiderResults.fetchAllFromServer(
        widget.event.checkinStatusUrl); // fallback if not activated
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Event event = widget.event;
    return Scaffold(
        appBar: AppBar(
          title: const Text("Check-ins"),
        ),
        body: Column(
          children: [
            EventHeaderCard(event: event),
            Material(
              color: Theme.of(context).colorScheme.surface,
              child: TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(icon: Icon(Icons.people), text: "By Rider"),
                  Tab(icon: Icon(Icons.history), text: "By Time"),
                ],
              ),
            ),
            Expanded(
              child: FutureBuilder<List<RiderResults>>(
                future: _riderResults,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(
                      child: Card(
                        margin: const EdgeInsets.all(16),
                        color: Colors.red.shade50,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.error_outline,
                                  color: Colors.red, size: 48),
                              const SizedBox(height: 12),
                              Text(
                                "Something went wrong",
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                      color: Colors.red.shade700,
                                    ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                snapshot.error.toString(),
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                              const SizedBox(height: 12),
                              ElevatedButton.icon(
                                onPressed: () {
                                  setState(() {
                                    _riderResults =
                                        RiderResults.fetchAllFromServer(event
                                            .checkinStatusUrl); // whatever your reload is
                                  });
                                },
                                icon: const Icon(Icons.refresh),
                                label: const Text("Retry"),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(child: Text("No check-ins available"));
                  }

                  final riders = snapshot.data!;

                  return TabBarView(
                    controller: _tabController,
                    children: [
                      RiderCheckinStatus(event: event, riders: riders),
                      ChronologicalCheckinStatus(event: event, riders: riders),
                    ],
                  );
                },
              ),
            ),
          ],
        ));
//    }
  }
}
