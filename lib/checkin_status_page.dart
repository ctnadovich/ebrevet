import 'dart:convert';
import 'package:flutter/material.dart';
import 'checkin_status_rider.dart';
import 'checkin_status_timed.dart';
import 'event.dart';
import 'scheduled_events.dart';
import 'exception.dart';
import 'event_header_card.dart';

class CheckinStatusPage extends StatefulWidget {
  final Event event;

  const CheckinStatusPage({super.key, required this.event});

  @override
  State<CheckinStatusPage> createState() => _CheckinStatusPageState();
}

class _CheckinStatusPageState extends State<CheckinStatusPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late Future<List<dynamic>> _ridersFuture;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _ridersFuture = _fetchCheckinData(widget.event);
  }

  Future<List<dynamic>> _fetchCheckinData(Event event) async {
    String url = "${event.checkinStatusUrl}/json";

    String responseBody = await ScheduledEvents.fetchResponseFromServer(url);
    List<dynamic> decodedResponse = jsonDecode(responseBody);

    if (decodedResponse.isEmpty) {
      throw ServerException('Empty reponse from $url');
    }

    return decodedResponse;
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text("Check-ins"),
        ),
        body: Column(
          children: [
            EventHeaderCard(event: widget.event),
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
              child: FutureBuilder<List<dynamic>>(
                future: _ridersFuture,
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
                                    _ridersFuture = _fetchCheckinData(widget
                                        .event); // whatever your reload is
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
                      RiderCheckinStatus(event: widget.event, riders: riders),
                      ChronologicalCheckinStatus(
                          event: widget.event, riders: riders),
                    ],
                  );
                },
              ),
            ),
          ],
        ));
  }
}
