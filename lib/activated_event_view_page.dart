import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'activated_event.dart';
import 'control_card.dart';
import 'control_state.dart';
import 'report.dart';
import 'time_till.dart';
import 'location.dart';
import 'day_night.dart';
import 'signature.dart';
import 'screen_shot.dart';
import 'utility.dart';
import 'outcome.dart';

class ActivatedEventViewPage extends StatelessWidget {
  final ActivatedEvent event;
  final bool isLiveView; // true = RidePage, false = ControlDetailPage
  final bool showScreenshotButton;

  const ActivatedEventViewPage({
    super.key,
    required this.event,
    this.isLiveView = true,
    this.showScreenshotButton = false,
  });

  static GlobalKey previewContainer = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final dayNight = context.watch<DayNight>();
    final controlState = context.watch<ControlState>();
    final lastLocationUpdate = RiderLocation.lastLocationUpdate;

    return Scaffold(
      appBar: AppBar(
        title: Text(event.event.nameDist),
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
                  "Control-Detail-${event.event.eventID}.png",
                  previewContainer),
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
              _buildHeader(context, controlState, lastLocationUpdate),
              Divider(
                indent: MediaQuery.of(context).size.width * 0.15,
                endIndent: MediaQuery.of(context).size.width * 0.15,
              ),
              Expanded(child: _buildControlList(context)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, ControlState controlState,
      DateTime? lastLocationUpdate) {
    final outcomes = event.outcomes;
    final isFinished = event.isFinished;
    final isDNQ = outcomes.overallOutcome.isDNQ;

    if (isLiveView) {
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

      final eventObj = event.event;
      final gpct =
          ((100.0 * eventObj.gravelDistance) / (1.0 * eventObj.distance))
              .round();

      return Column(
        children: [
          Text("Riding ${event.startStyle.description}",
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
          if (outcomes.overallOutcome != OverallOutcome.dns)
            Column(
              children: [
                Text(event.checkInFractionString),
                Text(
                  event.isFullyUploadedString,
                  style: TextStyle(
                      fontWeight: (event.isCurrentOutcomeFullyUploaded)
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
                  onPressed: () => Report.constructReportAndSend(event,
                      onUploadDone: () async {}),
                  child: const Text("Upload results")),
            ],
          ),
        ],
      );
    } else {
      // ControlDetailPage header
      final finishedWithCode = isFinished & !outcomes.overallOutcome.isDNQ;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(event.startStyle.description,
              style: const TextStyle(fontWeight: FontWeight.bold)),
          Text('Overall result: ${event.overallOutcomeDescription}'),
          if (finishedWithCode)
            Text('Finish Code: ${Signature.forCert(event).xyText}'),
          Text('Elapsed time: ${event.elapsedTimeString}'),
          Text('Last Upload: ${event.outcomes.lastUploadString}'),
          const SizedBox(height: 8),
          Row(
            children: [
              ElevatedButton(
                  onPressed: () => Report.constructReportAndSend(event,
                      onUploadDone: controlState.reportUploaded),
                  child: const Text("Upload results")),
              const SizedBox(width: 8),
            ],
          ),
        ],
      );
    }
  }

  Widget _buildControlList(BuildContext context) {
    if (isLiveView) {
      // RidePage controls
      return ListView(
        children: [for (var c in event.event.controls) ControlCard(c, event)],
      );
    } else {
      // ControlDetailPage check-ins
      return ListView(
        children: [
          for (var checkIn in event.outcomes.checkInTimeList)
            _checkInCard(event, checkIn)
        ],
      );
    }
  }

  Widget _checkInCard(ActivatedEvent activatedEvent, List<String> checkIn) {
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
}
