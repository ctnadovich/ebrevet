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
// import 'utility.dart';
import 'outcome.dart';
// import 'region.dart';

// TODO should be able to work with either an ordinary Event
// as a control preview, or with
// an ActivatedEvent showing this rider's check ins.
// Perhaps RiderCheckinDetailsPage could be implemnted
// with this widget, instead of being yet another checkin view?

// This must serve as a LiveView for riders actively riding, as
// a historical record of their ride, and as a preview of the controls

enum ControlsViewStyle { future, live, past }

class ControlsViewPage extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final dayNight = context.watch<DayNight>();

    final bool showScreenshotButton = (style == ControlsViewStyle.past);
    final bool isLiveView = (style == ControlsViewStyle.live);

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
        title: Text(event.nameDist),
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
                  "Control-Detail-${event.eventID}.png", previewContainer),
              child: const Icon(Icons.share),
            )
          : null,
      body: Container(
        color: Theme.of(context).colorScheme.primaryContainer,
        padding: const EdgeInsets.all(16),
        child: RepaintBoundary(
          key: previewContainer,
          child: Column(
            children: [
              _buildHeader(context, style),
              Divider(
                indent: MediaQuery.of(context).size.width * 0.15,
                endIndent: MediaQuery.of(context).size.width * 0.15,
              ),
              Expanded(
                child: ListView(
                  children: [
                    for (var c in event.controls)
                      ControlCard(c, activatedEvent!)
                  ],
                ),
              ),
            ],
          ),
        ),
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
    if (this.activatedEvent == null) {
      return const Text('Event not activated. LiveView unavailable.');
    }

    final ActivatedEvent activatedEvent = this.activatedEvent!;

    final controlState = context.watch<ControlState>();
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

    final eventObj = event;
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
                onPressed: () => RiderLocation.updateLocation()
                    .then((_) => controlState.positionUpdated()),
                child: const Text("GPS Update")),
            const Spacer(),
            ElevatedButton(
                onPressed: () => Report.constructReportAndSend(activatedEvent,
                    onUploadDone: () async {}),
                child: const Text("Upload results")),
          ],
        ),
      ],
    );
  }

  Widget _buildHistoryViewHeader(BuildContext context) {
    final controlState = context.watch<ControlState>();

    if (this.activatedEvent == null) {
      return const Text('Event not activated. HistoryView unavailable.');
    }

    final ActivatedEvent activatedEvent = this.activatedEvent!;

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

  // Widget _buildControlList(BuildContext context) {
  //   if (isLiveView) {
  //     // RidePage controls
  //     return ListView(
  //       children: [for (var c in event.controls) ControlCard(c, activatedEvent!)],
  //     );
  //   } else {
  //     // ControlDetailPage check-ins
  //     return ListView(
  //       children: [
  //         for (var checkIn in activatedEvent.outcomes.checkInTimeList)
  //           _checkInCard(event, checkIn)
  //       ],
  //     );
  //   }
  // }

/*   Widget _checkInCard(ActivatedEvent activatedEvent, List<String> checkIn) {
    final controlIndex = int.parse(checkIn[0]);
    final ciDateTime = DateTime.parse(checkIn[1]).toLocal();
    final ciDateTimeString = Utility.toBriefDateTimeString(ciDateTime);

    final eventObj = activatedEvent.event;
    final control = eventObj.controls[controlIndex];
    final courseMile = control.distMi;
    final controlName = control.name;

    final checkInSignature = activatedEvent.makeCheckInSignature(control);

    Icon checkInIcon;
    final lastUpload = activatedEvent.outcomes.lastUpload;
    final checkInTime =
        activatedEvent.outcomes.getControlCheckInTime(control.index);

    if (checkInTime != null) {
      checkInIcon = (lastUpload != null && lastUpload.isAfter(checkInTime))
          ? const Icon(Icons.check_circle, color: Colors.green)
          : const Icon(Icons.pending_sharp, color: Colors.orangeAccent);
    } else {
      checkInIcon = const Icon(Icons.broken_image, color: Colors.red);
    }

    return Card(
      child: ListTile(
        leading: Icon(controlIndex == eventObj.startControlKey
            ? Icons.play_arrow
            : (controlIndex == eventObj.finishControlKey
                ? Icons.stop
                : Icons.pedal_bike)),
        title: Text(controlName),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(control.address),
            Text(
                'Control ${controlIndex + 1} ($courseMile mi): $ciDateTimeString'),
            Text("Check-in Code: $checkInSignature"),
            Row(children: [const Text('Upload: '), checkInIcon]),
          ],
        ),
      ),
    );
  }
 */
}
