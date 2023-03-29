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

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'control_card.dart';
import 'time_till.dart';
import 'location.dart';
import 'current.dart';
import 'app_settings.dart';
import 'day_night.dart';
import 'ticker.dart';
import 'outcome.dart';
import 'report.dart';

class RidePage extends StatefulWidget {
  const RidePage({super.key});
  @override
  State<RidePage> createState() => _RidePageState();
}

class _RidePageState extends State<RidePage> {
  final isPreride = Current.activatedEvent?.isPreride ?? false;
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
    var controlList = (Current.isActivated) ? Current.event!.controls : [];
    var eventText =
        (Current.isActivated) ? Current.event!.nameDist : 'No event';
    var dayNight = context.watch<DayNight>();
    var lastLocationUpdate = RiderLocation.lastLocationUpdate;

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
                    (isPreride) ? 'Volunteer Preride' : 'Scheduled Brevet',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Text(
                    lastLocationUpdateText,
                    textAlign: TextAlign.center,
                    style: lastLocationUpdateTextStyle,
                  ),

// TODO immediate updating of these texts after checkin or upload

                  (Current.outcomes?.overallOutcome == OverallOutcome.dns)
                      ? const SizedBox.shrink()
                      : Column(
                          children: [
                            Text(
                                Current.activatedEvent?.checkInFractionString ??
                                    ''),
                            Text(
                              Current.activatedEvent?.isFullyUploadedString ??
                                  '',
                              style: TextStyle(
                                  fontWeight: (Current.activatedEvent
                                              ?.isCurrentOutcomeFullyUploaded ??
                                          false)
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
                          onPressed: () => RiderLocation.updateLocation(),
                          child: const Text("GPS Update")),
                      //    const ElevatedButton(
                      //       onPressed: null, child: Text("GPS Off")),
                      const Spacer(),
                      ElevatedButton(
                          onPressed: () {
                            var report = Report(Current.activatedEvent);
                            report.constructReportAndSend();
                          },
                          child: const Text("Upload results")),
                    ],
                  ),
                ] +
                [
                  for (var c in controlList)
                    ControlCard(c, Current.activatedEvent!)
                ],
          ),
        ),
      ),
    );
  }
}
