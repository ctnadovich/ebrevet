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

import 'package:ebrevet_card/event_history.dart';
import 'package:flutter/material.dart';
import 'control.dart';
import 'report.dart';

class ControlDetailPage extends StatelessWidget {
  final PastEvent pastEvent;

  const ControlDetailPage(this.pastEvent, {super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(
            pastEvent.event.nameDist,
            //style: TextStyle(fontSize: 14),
          ),
        ),
        body: Container(
          color: Theme.of(context).colorScheme.primaryContainer,
          padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
          child: ListView(
            children: [
              Row(
                children: [
                  const SizedBox(
                    width: 8,
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        (pastEvent.isPreride)
                            ? 'Volunteer Preride'
                            : 'Scheduled Brevet',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                          'Overall result: ${pastEvent.overallOutcomeDescription}'),
                      Text('Elapsed time: ${pastEvent.elapsedTimeString}'),
                      Text(
                          'Last Upload: ${pastEvent.outcomes.lastUploadString}'),
                      const SizedBox(
                        height: 8,
                      ),
                    ],
                  ),
                  const Spacer(flex: 1),
                  ElevatedButton(
                      onPressed: () {
                        var report = Report(pastEvent);
                        report.constructReportAndSend();
                      }, // Current.constructReportAndSend(),
                      child: const Text("Upload results")),
                  const SizedBox(
                    width: 8,
                  ),
                ],
              ),
              for (var checkIn in pastEvent.outcomes.checkInTimeList)
                checkInCard(checkIn),
            ],
          ),
        ));
  }

  // TODO Pretty this up and add more analytics
  // or maybe refactor/consolodate this with ControlCard
  // used by RidePage

  Widget checkInCard(List<String> checkIn) {
    var controlIndex = int.parse(checkIn[0]);
    var citString = DateTime.parse(checkIn[1]).toLocal().toIso8601String();
    var ciDate = citString.substring(5, 10);
    var ciTime = citString.substring(11, 16);
    var event = pastEvent.event;
    var control = event.controls[controlIndex];
    var courseMile = control.distMi;
    var controlName = control.name;
    return Card(
      child: ListTile(
        leading: Icon(controlIndex == event.startControlKey
            ? Icons.play_arrow
            : (controlIndex == event.finishControlKey
                ? Icons.stop
                : Icons.pedal_bike)),
        title: Text(controlName),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(control.address),
            Text(
                'Control ${controlIndex + 1} ($courseMile mi): $ciDate @ $ciTime'),
            checkInIcon(control, pastEvent.outcomes.lastUpload),
          ],
        ),
      ),
    );
  }

  Widget checkInIcon(Control c, DateTime? lastUpload) {
    var checkInTime = pastEvent.outcomes.getControlCheckInTime(c.index);
    Icon checkInIcon;
    if (checkInTime != null) {
      checkInIcon = (lastUpload != null && lastUpload.isAfter(checkInTime))
          ? const Icon(Icons.check_circle, color: Colors.green)
          : const Icon(Icons.pending_sharp, color: Colors.orangeAccent);
    } else {
      checkInIcon = const Icon(
        Icons.broken_image,
        color: Colors.red,
      );
    }
    return Row(
      children: [const Text('Upload: '), checkInIcon],
    );
  }
}
