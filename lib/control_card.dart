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

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'control.dart';
import 'time_till.dart';
import 'location.dart';
import 'app_settings.dart';
import 'past_event.dart';
import 'control_state.dart';

class ControlCard extends StatefulWidget {
  final Control control;
  final PastEvent pastEvent;

  const ControlCard(this.control, this.pastEvent, {super.key});

  @override
  State<ControlCard> createState() => _ControlCardState();
}

class _ControlCardState extends State<ControlCard> {
  late TextEditingController controller;

  @override
  void initState() {
    super.initState();
    controller = TextEditingController();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    context.watch<ControlState>();
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
                Text(exactDistanceString(widget.control.cLoc)),
                Text(controlStatusString(widget.control)),
              ],
            ),
            trailing: checkInButton(
              widget.control,
              widget.pastEvent.outcomes.lastUpload,
            ),
          ),
          const SizedBox(
            height: 5,
          )
        ],
      ),
    );
  }

  String controlStatusString(Control c) {
    DateTime now = DateTime.now();
    int controlKey = c.index;
    var activeEvent = widget.pastEvent;
    var open = activeEvent.openActual(controlKey);
    var close = activeEvent.closeActual(controlKey);
    if ((open ?? close) == null) return ""; // Pre ride undefined open/close
    if (open!.isAfter(now)) {
      // Open in future
      var tt = TimeTill(open);
      return "Opens ${tt.terseDateTime} (in ${tt.interval} ${tt.unit})";
    } else if (close!.isBefore(now)) {
      // Closed in past
      var tt = TimeTill(close);
      return "Closed ${tt.terseDateTime} (${tt.interval} ${tt.unit} ago)";
    } else {
      var tt = TimeTill(close);
      //var ct = c.close.toLocal().toString().substring(11, 16);
      return "Closes in ${tt.interval} ${tt.unit}";
    }
  }

  String exactDistanceString(ControlLocation cLoc) {
    return ('Dir: ${cLoc.crowDistString} ${cLoc.crowCompassHeadingString}');
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
                  "Control: ${1 + widget.control.index} of ${widget.pastEvent.event.controls.length}"),
              Text("Address: ${widget.control.address}"),
              Text("Style: ${widget.control.style}"),
              Text('Course distance: ${widget.control.distMi.toString()} mi'),
              Text(exactDistanceString(widget.control.cLoc)),
              Text(
                  "Location: ${widget.control.lat} N;  ${widget.control.long}E"),
              Text(controlStatusString(widget.control)),
              Text(
                  'Open Time: ${widget.pastEvent.openActualString(widget.control.index)}'),
              Text(
                  'Close Time: ${widget.pastEvent.closeActualString(widget.control.index)}'),
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
    var activeEvent = widget.pastEvent;
    var checkInTime = activeEvent.controlCheckInTime(c);
    // var lastUpload = Current.activatedEvent?.outcomes.lastUpload;

    if (checkInTime != null) {
      var checkInIcon = (lastUpload != null && lastUpload.isAfter(checkInTime))
          ? const Icon(Icons.check_circle, color: Colors.green)
          : const Icon(Icons.pending_sharp, color: Colors.orangeAccent);
      return Column(
        children: [
          checkInIcon,
          Text(checkInTime.toLocal().toString().substring(11, 19)),
        ],
      );
    } else if (false == activeEvent.isAvailable(c.index)) {
      var open = activeEvent.isOpenControl(c.index);
      var near = activeEvent.isNear(c.index);
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
        if (!near && RiderLocation.riderLocation != null)
          const TextSpan(
            text: 'Not near',
          ),
        if (RiderLocation.riderLocation == null)
          const TextSpan(
            text: 'Dist ??',
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
  }

  Future openCheckInDialog() => showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Check In to Control'),
          content: checkInDIalogContent(widget.control),
          actions: [
            TextButton(
                onPressed: () {
                  submitCheckInDialog();
                },
                child: const Text('CHECK IN NOW'))
          ],
        ),
      );

  Column checkInDIalogContent(Control control) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          control.name,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(controlStatusString(control)),
        Text(exactDistanceString(control.cLoc)),
        if (control.cLoc.isNearControl)
          const Text(
            'AT THIS CONTROL',
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
        TextField(
          decoration: const InputDecoration(hintText: 'Comment (optional)'),
          controller: controller,
          onSubmitted: (_) => submitCheckInDialog(),
        ),
      ],
    );
  }

  void submitCheckInDialog() {
    var controlState = context.read<ControlState>();
    widget.pastEvent.controlCheckIn(
      control: widget.control,
      comment: controller.text,
      // onUploadDone: controlState.reportUploaded,
      controlState: controlState,
    );
    controller.clear();
    Navigator.of(context).pop();
  }
}
