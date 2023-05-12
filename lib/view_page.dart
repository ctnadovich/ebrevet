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

import 'package:share_plus/share_plus.dart';
// import 'package:screenshot/screenshot.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'past_event.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'control.dart';
import 'report.dart';
import 'control_state.dart';
import 'utility.dart';
import 'mylogger.dart';
import 'app_settings.dart';
import 'snackbarglobal.dart';

// TODO This really should be the same widget (or a child) as Ride Page

class ControlDetailPage extends StatelessWidget {
  final PastEvent pastEvent;
  // final ScreenshotController screenshotController = ScreenshotController();

  ControlDetailPage(this.pastEvent, {super.key});

  @override
  Widget build(BuildContext context) {
    var controlState = context.watch<ControlState>();
    var fileName =
        "Control-Detail-${AppSettings.rusaID}-${pastEvent.event.eventID}.png";

    return Scaffold(
        appBar: AppBar(
          title: Text(
            pastEvent.event.nameDist,
            //style: TextStyle(fontSize: 14),
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => {}, // takeScreenshot(fileName),
          child: const Icon(Icons.share),
        ),
        body: Container(
          color: Theme.of(context).colorScheme.primaryContainer,
          padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
          child:
              // Screenshot(
              //   controller: screenshotController,
              //   child:

              ListView(
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
                        Report.constructReportAndSend(pastEvent,
                            onUploadDone: controlState.reportUploaded);
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
          // ),
        ));
  }

  // void takeScreenshot(String fileName) async {
  //   try {
  //     await screenshotController
  //         .capture(delay: const Duration(milliseconds: 10))
  //         .then((image) async {
  //       if (image != null) {
  //         final directory = await getApplicationDocumentsDirectory();

  //         final imagePath = await File('${directory.path}/$fileName').create();
  //         await imagePath.writeAsBytes(image);

  //         /// Share Plugin
  //         await Share.shareXFiles([XFile(imagePath.path)]);
  //       }
  //     });
  //   } catch (e) {
  //     var message = "Failed to save screenshot: $e";
  //     SnackbarGlobal.show(message);
  //     MyLogger.entry(message, severity: Severity.error);
  //   }
  // }

  // TODO Consider Refactor/consolodating this with ControlCard
  // used by RidePage. Silly to maintain two similar views of the same thing.
  // On the other hand, there are some differences between the preferred
  // view during the ride, vs after the ride. Perhaps these could be
  // child classes of a common control card view class.

  Widget checkInCard(List<String> checkIn) {
    var controlIndex = int.parse(checkIn[0]);
    var ciDateTime = DateTime.parse(checkIn[1]).toLocal();
    var ciDateTimeString = Utility.toBriefDateTimeString(ciDateTime);

    // var ciDate = citString.substring(5, 10);
    // var ciTime = citString.substring(11, 16);
    var event = pastEvent.event;
    var control = event.controls[controlIndex];
    var courseMile = control.distMi;
    var controlName = control.name;

    var checkInSignatureString = pastEvent.makeCheckInSignature(control);

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
                'Control ${controlIndex + 1} ($courseMile mi): $ciDateTimeString'),
            Text("Check-in Code: $checkInSignatureString"),
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
