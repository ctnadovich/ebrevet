import 'package:ebrevet_card/exception.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'activated_event.dart';
import 'my_activated_events.dart';
import 'event.dart';
import 'control_card.dart';
import 'control_state.dart';
import 'report.dart';
import 'time_till.dart';
import 'location.dart';
import 'day_night.dart';
import 'signature.dart';
import 'screen_shot.dart';
import 'mylogger.dart';
import 'outcome.dart';
import 'snackbarglobal.dart';
// import 'region.dart';

// TODO should be able to work with either an ordinary Event
// as a control preview, or with
// an ActivatedEvent showing this rider's check ins.
// Perhaps RiderCheckinDetailsPage could be implemnted
// with this widget, instead of being yet another checkin view?

// This must serve as a LiveView for riders actively riding, as
// a historical record of their ride, and as a preview of the controls

enum ControlsViewStyle { future, live, past }

class ControlsViewPage extends StatefulWidget {
  final Event event;
  final ControlsViewStyle style;
  final ActivatedEvent? activatedEvent;

  ControlsViewPage({
    super.key,
    required this.event,
    required this.style,
  }) : activatedEvent = MyActivatedEvents.lookupMyActivatedEvent(event.eventID);

  static GlobalKey previewContainer = GlobalKey();

  @override
  State<ControlsViewPage> createState() => _ControlsViewPageState();
}

class _ControlsViewPageState extends State<ControlsViewPage> {
  bool _updating = false;

  Future<void> _handleGPSUpdate() async {
    // MyLogger.entry("GPS Update button pressed.");
    setState(() => _updating = true);

    try {
      await RiderLocation.updateLocation();

      if (!mounted) return; // ensure widget still exists
      context.read<ControlState>().positionUpdated();
    } finally {
      if (mounted) {
        setState(() => _updating = false);
        FlushbarGlobal.show("GPS Location Updated");
      }
    }
  }

  Future<void> _handleUpload() async {
    setState(() => _updating = true);

    try {
      if (widget.activatedEvent == null) {
        throw NotActivatedException("Can't updload results.");
      }
      await Report.constructReportAndSend(
        widget.activatedEvent!,
        onUploadDone: () async {
          // optional: handle per-chunk upload completion
        },
      );
      await Future.delayed(const Duration(seconds: 1));
    } finally {
      if (mounted) {
        setState(() => _updating = false);
        FlushbarGlobal.show("Current checkin status uploaded.");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dayNight = context.watch<DayNight>();

    final bool showScreenshotButton = (widget.style == ControlsViewStyle.past);
    final bool isLiveView = (widget.style == ControlsViewStyle.live);

    // final regionName = Region(regionID: event.regionID).clubName;

    // final OverallOutcome overallOutcomeInHistory =
    //     activatedEvent?.outcomes.overallOutcome ??
    //         OverallOutcome.dns; // DNS if never activated
    // final String overallOutcomeDescriptionInHistory =
    //     overallOutcomeInHistory.description;
    // final bool isOutcomeFullyUploaded =
    //     activatedEvent?.isCurrentOutcomeFullyUploaded ?? false;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.event.nameDist),
        actions: [
          if (isLiveView)
            IconButton(
              icon: dayNight.icon,
              onPressed: dayNight.toggleMode,
            ),
        ],
      ),
      floatingActionButton: showScreenshotButton
          ? FloatingActionButton(
              onPressed: () => ScreenShot.take(
                  "Control-Detail-${widget.event.eventID}.png",
                  ControlsViewPage.previewContainer),
              child: const Icon(Icons.share),
            )
          : null,
      body: Stack(
        children: [
          Container(
            color: Theme.of(context).colorScheme.primaryContainer,
            padding: const EdgeInsets.all(16),
            child: RepaintBoundary(
              key: ControlsViewPage.previewContainer,
              child: Column(
                children: [
                  _buildHeader(context, widget.style),
                  Divider(
                    indent: MediaQuery.of(context).size.width * 0.15,
                    endIndent: MediaQuery.of(context).size.width * 0.15,
                  ),
                  Expanded(
                    child: ListView(
                      children: [
                        for (var c in widget.event.controls)
                          ControlCard(c, widget.activatedEvent!)
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_updating)
            Container(
              color: const Color.fromRGBO(128, 128, 128,
                  0.3), // overlay background, // translucent background
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, ControlsViewStyle style) {
    switch (style) {
      case ControlsViewStyle.live:
        return _buildLiveViewHeader(context);
      case ControlsViewStyle.past:
        return _buildHistoryViewHeader(context);
      default:
        return const Text("Unknown header view.");
    }
  }

  Widget _buildLiveViewHeader(BuildContext context) {
    if (widget.activatedEvent == null) {
      return const Text('Event not activated. LiveView unavailable.');
    }

    final ActivatedEvent activatedEvent = widget.activatedEvent!;

    final lastLocationUpdate = RiderLocation.lastLocationUpdate;
    final outcomes = activatedEvent.outcomes;
    final isFinished = activatedEvent.isFinished;
    final isDNQ = outcomes.overallOutcome.isDNQ;

    // RidePage header
    String lastLocationText = "Rider Location Not Known!";
    TextStyle? lastLocationStyle;
    if (lastLocationUpdate != null) {
      final tt = TimeTill(lastLocationUpdate);
      final agoText = '${tt.interval} ${tt.unit}${tt.ago}';
      if (RiderLocation.gpsServiceEnabled) {
        lastLocationText = 'Location found $agoText';
      } else {
        lastLocationText = "GPS OFF! Last update: $agoText";
        lastLocationStyle =
            const TextStyle(fontWeight: FontWeight.bold, fontSize: 15);
      }
    }

    final eventObj = widget.event;
    final gpct =
        ((100.0 * eventObj.gravelDistance) / (1.0 * eventObj.distance)).round();

    return Column(
      children: [
        Text("Riding ${activatedEvent.startStyle.description}",
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium),
        if (isDNQ)
          Text(
            outcomes.overallOutcome.description,
            textAlign: TextAlign.center,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(color: Theme.of(context).colorScheme.error),
          ),
        if (eventObj.isGravel)
          Text(
            "${eventObj.gravelDistance}/${eventObj.distance}K $gpct% Gravel",
            textAlign: TextAlign.center,
          ),
        if (isFinished)
          Text(
            'FINISHED',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          )
        else
          Text(
            lastLocationText,
            textAlign: TextAlign.center,
            style: lastLocationStyle,
          ),
        if (activatedEvent.outcomes.overallOutcome != OverallOutcome.dns)
          Column(
            children: [
              Text(activatedEvent.checkInFractionString),
              Text(
                activatedEvent.isFullyUploadedString,
                style: TextStyle(
                    fontWeight: (activatedEvent.isCurrentOutcomeFullyUploaded)
                        ? FontWeight.normal
                        : FontWeight.bold),
              ),
            ],
          ),
        const SizedBox(height: 8),
        Row(
          children: [
            ElevatedButton(
              onPressed: () {
                // MyLogger.entry("Calling _handleUpdate()");
                _handleGPSUpdate();
              },
              child: const Text("GPS Update"),
            ),
            const Spacer(),
            ElevatedButton(
                onPressed: () {
                  MyLogger.entry("Calling _handleUpload()");
                  _handleUpload();
                },
                child: const Text("Upload results")),
          ],
        ),
      ],
    );
  }

  Widget _buildHistoryViewHeader(BuildContext context) {
    final controlState = context.watch<ControlState>();

    if (widget.activatedEvent == null) {
      return const Text('Event not activated. HistoryView unavailable.');
    }

    final ActivatedEvent activatedEvent = widget.activatedEvent!;

    final outcomes = activatedEvent.outcomes;
    final isFinished = activatedEvent.isFinished;
    final isDNQ = outcomes.overallOutcome.isDNQ;

    // ControlDetailPage header
    final finishedWithCode = isFinished & !isDNQ;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(activatedEvent.startStyle.description,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        Text('Overall result: ${activatedEvent.overallOutcomeDescription}'),
        if (finishedWithCode)
          Text('Finish Code: ${Signature.forCert(activatedEvent).xyText}'),
        Text('Elapsed time: ${activatedEvent.elapsedTimeString}'),
        Text('Last Upload: ${activatedEvent.outcomes.lastUploadString}'),
        const SizedBox(height: 8),
        Row(
          children: [
            ElevatedButton(
                onPressed: () => Report.constructReportAndSend(activatedEvent,
                    onUploadDone: controlState.reportUploaded),
                child: const Text("Upload results")),
            const SizedBox(width: 8),
          ],
        ),
      ],
    );
  }
}
