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
// along with dogtag.  If not, see <http://www.gnu.org/licenses/>.

import 'dart:async';
import 'package:ebrevet_card/snackbarglobal.dart';
// import 'package:flutter_settings_screens/flutter_settings_screens.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'control.dart';
import 'time_till.dart';
import 'location.dart';
import 'current.dart';
import 'app_settings.dart';
import 'day_night.dart';
import 'ticker.dart';

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
      period: AppSettings.timeRefreshPeriod,
      onTick: RiderLocation.updateLocation,
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
          child: ValueListenableBuilder(
              valueListenable: RiderLocation.lastLocationUpdate,
              builder: (context, value, child) {
                return ListView(
                  children: <Widget>[
                        Text(
                          (isPreride)
                              ? 'Volunteer Preride'
                              : 'Scheduled Brevet',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        // (Current.outcomes?.overallOutcome == OverallOutcome.dns)
                        //     ? SizedBox.shrink()
                        //     : Text(
                        //         "${Current.activatedEvent?.checkInFractionString ?? ''} "
                        //         "(${Current.activatedEvent?.isFullyUploadedString ?? ''})",
                        //         style: TextStyle(
                        //             fontWeight: Current.activatedEvent
                        //                         ?.isCurrentOutcomeFullyUploaded ??
                        //                     false
                        //                 ? FontWeight.normal
                        //                 : FontWeight.bold),
                        //       ),
                        Text(
                          'At ${RiderLocation.lastLocationUpdateString} ${RiderLocation.lastLocationUpdateTimeZoneName} '
                          'location was ${RiderLocation.latLongString}',
                          textAlign: TextAlign.center,
                        ),
                        Row(
                          children: [
                            ElevatedButton(
                                onPressed: () => RiderLocation.updateLocation(),
                                child: const Text("GPS Refresh")),
                            const Spacer(),
                            ElevatedButton(
                                onPressed: () =>
                                    Current.constructReportAndSend(),
                                child: const Text("Upload results")),
                          ],
                        ),
                      ] +
                      [for (var c in controlList) ControlCard(c)],
                );
              }),
        ),
      ),
    );
  }
}

class ControlCard extends StatefulWidget {
  final Control control;
  const ControlCard(this.control, {super.key});
  @override
  State<ControlCard> createState() => _ControlCardState();
}

class _ControlCardState extends State<ControlCard> {
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
        valueListenable: Current.lastSuccessfulServerUpload,
        builder: (context, lastUpload, child) {
          return Card(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                ListTile(
                  leading: Icon((widget.control.sif == SIF.intermediate)
                      ? Icons.checklist
                      : ((widget.control.sif == SIF.start)
                          ? Icons.play_arrow
                          : Icons.stop)),
                  title: showControlName(widget.control),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      showDistance(widget.control.cLoc),
                      showControlStatus(widget.control),
                    ],
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: <Widget>[
                    checkInButton(widget.control, lastUpload),
                    const SizedBox(width: 8),
                  ],
                ),
                const SizedBox(
                  height: 5,
                )
              ],
            ),
          );
        });
  }

  Text showControlStatus(Control c) {
    // if (Current.activatedEvent!.isOpenControl(c.index)) {
    //   return Text.rich(TextSpan(
    //     children: [
    //       TextSpan(
    //         text: 'OPEN NOW! ',
    //         style: TextStyle(fontWeight: FontWeight.bold),
    //       ),
    //       TextSpan(
    //         text: controlStatus(c),
    //       ),
    //     ],
    //   ));
    // } else {
    return Text(controlStatus(c));
    //   }
  }

  // TODO the phrasing here needs work, esp the Undefined open/close that occurs before
  // the first preride control check in

  String controlStatus(Control c) {
    DateTime now = DateTime.now();
    int controlKey = c.index;
    var open = Current.activatedEvent!.openActual(controlKey);
    var close = Current.activatedEvent!.closeActual(controlKey);
    if ((open ?? close) == null) return ""; // Pre ride undefined open/close
    if (open!.isAfter(now)) {
      // Open in future
      var tt = TimeTill(open);
      var ot = open.toLocal().toString().substring(11, 16);
      return "Opens $ot (in ${tt.interval} ${tt.unit})";
    } else if (close!.isBefore(now)) {
      // Closed in past
      var tt = TimeTill(close);
      var ct = close.toLocal().toString().substring(11, 16);
      return "Closed $ct (${tt.interval} ${tt.unit} ago)";
    } else {
      var tt = TimeTill(close);
      //var ct = c.close.toLocal().toString().substring(11, 16);
      return "Closes in ${tt.interval} ${tt.unit}";
    }
  }

  Text showDistance(ControlLocation cLoc) {
    // if (cLoc.isNearControl) {
    //   return Text(
    //     'AT THIS CONTROL',
    //     style: TextStyle(
    //       fontWeight: FontWeight.bold,
    //     ),
    //   );
    // } else {
    return Text(
        'Direction: ${cLoc.crowCompassHeadingString} ${cLoc.crowDistMiString} mi away');
    //  }
  }

  Text showExactDistance(ControlLocation cLoc) {
    return Text(
        'Direction: ${cLoc.crowCompassHeadingString} ${cLoc.crowDistMetersString} meters away');
  }

  Widget showControlName(Control control) {
    return GestureDetector(
      onTap: () {
        openControlNameDialog(control);
      },
      child: Text(
        control.name,
        style: TextStyle(
            fontSize:
                Theme.of(context).primaryTextTheme.bodyLarge?.fontSize ?? 16,
            color: Theme.of(context).colorScheme.primary),
      ),
    );
  }

  Future openControlNameDialog(Control control) => showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(widget.control.name),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                  "Control: ${1 + widget.control.index} of ${Current.event?.controls.length ?? '?'}"),
              Text("Address: ${widget.control.address}"),
              Text("Style: ${widget.control.style}"),
              Text('Course distance: ${widget.control.distMi.toString()} mi'),
              showDistance(widget.control.cLoc),
              Text(
                  "Location: ${widget.control.lat} N;  ${widget.control.long}E"),
              showControlStatus(widget.control),
              Text(
                  'Open Time: ${Current.activatedEvent!.openActualString(widget.control.index)}'),
              Text(
                  'Close Time: ${Current.activatedEvent!.closeActualString(widget.control.index)}'),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('OK'))
          ],
        ),
      );

  Widget checkInButton(Control c, DateTime? lastUpload) {
    var checkInTime = Current.controlCheckInTime(c);
    // var lastUpload = Current.activatedEvent?.outcomes.lastUpload;

    if (checkInTime != null) {
      var checkInIcon = (lastUpload != null && lastUpload.isAfter(checkInTime))
          ? const Icon(Icons.check_circle, color: Colors.green)
          : const Icon(Icons.pending_sharp, color: Colors.red);
      return Column(
        children: [
          checkInIcon,
          Text(checkInTime.toLocal().toString().substring(11, 19)),
        ],
      );
    } else if (false == Current.activatedEvent!.isAvailable(c.index)) {
      var open = Current.activatedEvent!.isOpenControl(c.index);
      var near = Current.activatedEvent!.isNear(c.index);
      var openTimeOverride = AppSettings.openTimeOverride;
      var proximityRadiusInfinite = AppSettings.proximityRadius ==
          AppSettings.infiniteDistance.toDouble();

      return Text.rich(
          TextSpan(style: const TextStyle(fontSize: 12), children: [
        if (open || openTimeOverride)
          TextSpan(
            text: 'Open now${openTimeOverride ? "*" : ""}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        if (!open && !openTimeOverride)
          const TextSpan(
            text: 'Not open',
          ),
        const TextSpan(text: ' - '),
        if (near)
          TextSpan(
            text: 'At control${proximityRadiusInfinite ? "*" : ""}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        if (!near)
          const TextSpan(
            text: 'Not near',
          ),
      ]));
    } else {
      return ElevatedButton(
        onPressed: () {
          openCheckInDialog();
        },
        child: const Text('CHECK IN'),
      );
    }
    // else {
    //   return const SizedBox.shrink();
    // }
  }

  // TODO Posting result and elapsed time to roster

  // TODO Enter comment,  "take photo", or answer the control question

  // TODO Convert some logger statements to exceptions -- in app notifications

  Future openCheckInDialog() => showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Check In to Control'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.control.name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              showControlStatus(widget.control),
              showExactDistance(widget.control.cLoc),
              if (widget.control.cLoc.isNearControl)
                const Text(
                  'AT THIS CONTROL',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () {
                  submitCheckInDialog();
                },
                child: const Text('CHECK IN NOW'))
          ],
        ),
      );

  void submitCheckInDialog() {
    setState(() {
      if (Current.event != null) {
        Current.controlCheckIn(control: widget.control, comment: 'No Comment');
      } else {
        SnackbarGlobal.show('No current event to check into.');
      }
    });
    Navigator.of(context).pop();
  }
}
