// Copyright (C) 2023 Chris Nadovich
// This file is part of eBrevet <https://github.com/ctnadovich/ebrevet>.
//
// eBrevet is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// eBrevet is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with eBrevet.  If not, see <http://www.gnu.org/licenses/>.

// import 'package:ebrevet_card/event.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'control_card.dart';
import 'time_till.dart';
import 'location.dart';
import 'app_settings.dart';
import 'day_night.dart';
import 'ticker.dart';
import 'outcome.dart';
import 'report.dart';
import 'past_event.dart';
import 'control_state.dart';

class RidePage extends StatefulWidget {
  final PastEvent activeEvent;
  const RidePage(this.activeEvent, {super.key});

  @override
  State<RidePage> createState() => _RidePageState();
}

class _RidePageState extends State<RidePage> {
  Ticker ticker = Ticker();

  @override
  void initState() {
    super.initState();

    ticker.init(
      period: AppSettings.gpsRefreshPeriod,
      onTick: () async {
        await RiderLocation.updateLocation();
        if (mounted) setState(() {});
      },
    );
  }

  @override
  void dispose() {
    super.dispose();
    ticker.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var activeEvent = widget.activeEvent;
    var event = activeEvent.event;

    var startStyle = activeEvent.startStyle;
    var outcomes = activeEvent.outcomes;
    var isFinished = activeEvent.isFinished;
    var isDNQ = activeEvent.outcomes.overallOutcome == OverallOutcome.dnq;
    var controlList = event.controls;
    var eventText = event.nameDist;
    var dayNight = context.watch<DayNight>();
    var lastLocationUpdate = RiderLocation.lastLocationUpdate;

    var gpct =
        ((100.0 * event.gravelDistance) / (1.0 * event.distance)).round();

    var controlState = context.watch<ControlState>();

    String lastLocationUpdateText = "Rider Location Not Known!";
    TextStyle? lastLocationUpdateTextStyle;
    if (lastLocationUpdate != null) {
      var ttLastLocationUpdate = TimeTill(lastLocationUpdate);
      var agoText =
          '${ttLastLocationUpdate.interval} ${ttLastLocationUpdate.unit}${ttLastLocationUpdate.ago}';
      if (RiderLocation.gpsServiceEnabled) {
        lastLocationUpdateText = 'Location found $agoText';
      } else {
        lastLocationUpdateText = "GPS OFF! Last update: $agoText";
        lastLocationUpdateTextStyle =
            const TextStyle(fontWeight: FontWeight.bold, fontSize: 15);
      }
    } else {
      lastLocationUpdateText = "Rider Location Not Known!";
      lastLocationUpdateTextStyle = Theme.of(context).textTheme.bodyLarge;
    }

    return Scaffold(
      appBar: AppBar(
        title: Column(
          children: [
            Text('$eventText'),
          ],
        ),
        actions: [
          IconButton(
              icon: dayNight.icon,
              onPressed: () {
                dayNight.toggleMode();
              })
        ],
      ),
      body: Container(
        color: Theme.of(context).colorScheme.primaryContainer,
        padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
        child: Center(
          child: ListView(
            children: <Widget>[
                  Text(
                    startStyle.description,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  if (isDNQ)
                    Text(
                      'DISQUALIFIED',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Theme.of(context).colorScheme.error),
                      textAlign: TextAlign.center,
                    ),
                  if (event.isGravel)
                    Text(
                      "${event.gravelDistance}/${event.distance}K $gpct% Gravel",
                      textAlign: TextAlign.center,
                    ),
                  if (isFinished)
                    Text(
                      'FINISHED',
                      style: Theme.of(context).textTheme.titleMedium,
                      textAlign: TextAlign.center,
                    )
                  else
                    Text(
                      lastLocationUpdateText,
                      textAlign: TextAlign.center,
                      style: lastLocationUpdateTextStyle,
                    ),
                  (outcomes.overallOutcome == OverallOutcome.dns)
                      ? const SizedBox.shrink()
                      : Column(
                          children: [
                            Text(activeEvent.checkInFractionString),
                            Text(
                              activeEvent.isFullyUploadedString,
                              style: TextStyle(
                                  fontWeight: (activeEvent
                                          .isCurrentOutcomeFullyUploaded)
                                      ? FontWeight.normal
                                      : FontWeight.bold),
                            ),
                          ],
                        ),
                  Row(
                    children: [
                      // RiderLocation.gpsServiceEnabled
                      //     ?
                      ElevatedButton(
                          onPressed: () => RiderLocation.updateLocation()
                              .then((_) => controlState.positionUpdated()),
                          child: const Text("GPS Update")),
                      //    const ElevatedButton(
                      //       onPressed: null, child: Text("GPS Off")),
                      const Spacer(),
                      ElevatedButton(
                          onPressed: () => Report.constructReportAndSend(
                                activeEvent,
                                onUploadDone: () {
                                  controlState.reportUploaded;
                                },
                              ),
                          child: const Text("Upload results")),
                    ],
                  ),
                ] +
                [for (var c in controlList) ControlCard(c, activeEvent)],
          ),
        ),
      ),
    );
  }
}
