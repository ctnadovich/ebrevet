import 'dart:async';
import 'package:ebrevet_card/snackbarglobal.dart';
import 'package:flutter/material.dart';

import 'control.dart';
import 'time_till.dart';
import 'location.dart';
import 'current.dart';


// TODO Someplace the organizer and emergency number needs to appear

class RidePage extends StatefulWidget {
  @override
  State<RidePage> createState() => _RidePageState();
}

class _RidePageState extends State<RidePage> {
  Timer? timer;
  final int tickPeriod = 10;
  int tTick = 0;

  @override
  void initState() {
    super.initState();

    RiderLocation.updateLocation();

// Maybe move this timer to its own class and use it to schedule events?
// Or maybe we want location updates to be rider initiated and don't need this timer?

    // var tickDuration = Duration(seconds: tickPeriod);

    // double setPeriodSeconds = Settings.getValue<double>(
    //     'key-location_poll-period',
    //     defaultValue: 30)!;
    // int periodTicks = setPeriodSeconds.floor() ~/ tickPeriod;

    // timer = Timer.periodic(tickDuration, (Timer t) {
    //   if (0 == tTick % periodTicks) {
    //     RiderLocation.updateLocation();
    //   }
    //   tTick++;
    // });
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
                        Text(
                            'Rider: ${Current.rider?.firstLastRUSA ?? 'Unknown'}'),
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
    if (c.isOpen) {
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
    } else if (c.isAvailable) {
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

  // TODO Enter comment,  "take photo", or answer the control question

  // TODO What about distance to control and time relative to open/close? 

  Future openCheckInDialog() => showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Check In to Control'),  // TODO Name of control? 
          content: Text(widget.control.name),
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
