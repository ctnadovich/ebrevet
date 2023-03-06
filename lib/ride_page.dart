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

import 'control.dart';
import 'time_till.dart';
import 'location.dart';
import 'current.dart';
import 'app_settings.dart';

// TODO IT's unclear _which_ event (future or history) apprears in future or ride pages

// TODO First control auto check in?

class RidePage extends StatefulWidget {
  @override
  State<RidePage> createState() => _RidePageState();
}

class _RidePageState extends State<RidePage> {
  Timer? timer;
  final int tickPeriod = 10;
  int tTick = 0;

  final isPreride = Current.activatedEvent?.isPreride ?? false;

  @override
  void initState() {
    super.initState();

    RiderLocation.updateLocation();

// Maybe move this timer to its own class and use it to schedule events?
// Or maybe we want location updates to be rider initiated and don't need this timer?

    var tickDuration = Duration(seconds: tickPeriod);

    double setPeriodSeconds = AppSettings.locationPollPeriod;
    int periodTicks = setPeriodSeconds.floor() ~/ tickPeriod;

    timer = Timer.periodic(tickDuration, (Timer t) {
      if (0 == tTick % periodTicks) {
        RiderLocation.updateLocation();
      }
      tTick++;
    });
  }

  @override
  void dispose() {
    super.dispose();
    timer?.cancel();
  }

  @override
  Widget build(BuildContext context) {
    var controlList = (Current.isActivated) ? Current.event!.controls : [];
    var eventText =
        (Current.isActivated) ? Current.event!.nameDist : 'No event';

    return Scaffold(
      appBar: AppBar(
        title: Column(
          children: [
            Text('$eventText'),
          ],
        ),
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
                        Text((isPreride)?'Preride':'Brevet'),
                        Text(
                            'Rider RUSA#: ${Current.activatedEvent?.riderID ?? 'Unknown'}'),
                        Text(
                            'At ${RiderLocation.lastLocationUpdateString} ${RiderLocation.lastLocationUpdateTimeZoneName} '
                            'location was ${RiderLocation.latLongString}'),
                        ElevatedButton(
                            onPressed: () => RiderLocation.updateLocation(),
                            child: Text("GPS Refresh Current Location")),
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
  const ControlCard(this.control);
  @override
  State<ControlCard> createState() => _ControlCardState();
}

class _ControlCardState extends State<ControlCard> {
  @override
  Widget build(BuildContext context) {
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
              checkInButton(widget.control),
              const SizedBox(width: 8),
            ],
          ),
          SizedBox(
            height: 5,
          )
        ],
      ),
    );
  }

  Text showControlStatus(Control c) {
    if (Current.activatedEvent!.isOpenControl(c.index)) {
      return Text.rich(TextSpan(
        children: [
          TextSpan(
            text: 'OPEN NOW! ',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          TextSpan(
            text: controlStatus(c),
          ),
        ],
      ));
    } else {
      return Text(controlStatus(c));
    }
  }

  String controlStatus(Control c) {
    DateTime now = DateTime.now();
    if (c.open.isAfter(now)) {
      // Open in future
      var tt = TimeTill(c.open);
      var ot = c.open.toLocal().toString().substring(11, 16);
      return "Opens $ot (in ${tt.interval} ${tt.unit})";
    } else if (c.close.isBefore(now)) {
      // Closed in past
      var tt = TimeTill(c.close);
      var ct = c.close.toLocal().toString().substring(11, 16);
      return "Closed $ct (${tt.interval} ${tt.unit} ago)";
    } else {
      var tt = TimeTill(c.close);
      //var ct = c.close.toLocal().toString().substring(11, 16);
      return "Closes in ${tt.interval} ${tt.unit}";
    }
  }

  Text showDistance(ControlLocation cLoc) {
    if (cLoc.isNearControl) {
      return Text(
        'AT THIS CONTROL',
        style: TextStyle(
          fontWeight: FontWeight.bold,
        ),
      );
    } else {
      return Text(
          'Direction: ${cLoc.crowCompassHeadingString} ${cLoc.crowDistMiString} mi away');
    }
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
              Text('Open Time: ${widget.control.openTimeString}'),
              Text('Close Time: ${widget.control.closeTimeString}'),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text('OK'))
          ],
        ),
      );

  Widget checkInButton(Control c) {
    var checkInTime = Current.controlCheckInTime(c);

    if (checkInTime != null) {
      return Column(
        children: [
          Icon(Icons.check),
          Text(checkInTime.toLocal().toString().substring(11, 19)),
        ],
      );
    } else if (c.index==0 || Current.activatedEvent!.isAvailable(c.index)) {
      return ElevatedButton(
        onPressed: () {
          openCheckInDialog();
        },
        child: Text('CHECK IN'),
      );
    } else {
      return const SizedBox.shrink();
    }
  }

  // TODO Preride time calculation relative to start time

  // TODO Automatic pre ride mode -- should be impossible to pre-ride day of

  // TODO distance override should not be part of pre ride mode

  // TODO Upload now button

  // TODO Confirmation of upload for each control

  // TODO note region in past/future events (multi region)

  // TODO developer options separate and restricted. 

  // TODO Posting result and elapsed time to roster

  // TODO Enter comment,  "take photo", or answer the control question

  // TODO What about un-checkin and erase history

  Future openCheckInDialog() => showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Check In to Control'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.control.name,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              showControlStatus(widget.control),
              showExactDistance(widget.control.cLoc),
              if (widget.control.cLoc.isNearControl)
                Text(
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
        Current.controlCheckIn(widget.control);
      } else {
        SnackbarGlobal.show('No current event to check into.');
      }
    });
    Navigator.of(context).pop();
  }
}
