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

import 'package:ebrevet_card/snackbarglobal.dart';
import 'package:share_plus/share_plus.dart';
import 'package:ebrevet_card/signature.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

import 'past_event.dart';
import 'day_night.dart';
import 'view_page.dart';
import 'mylogger.dart';
import 'control_state.dart';
import 'app_settings.dart';

class CertificatePage extends StatefulWidget {
  final PastEvent pastEvent;
  const CertificatePage(this.pastEvent, {super.key});
  @override
  State<CertificatePage> createState() => _CertificatePageState();
}

class _CertificatePageState extends State<CertificatePage> {
  // ScreenshotController screenshotController = ScreenshotController();
  static GlobalKey previewContainer = GlobalKey();

  @override
  Widget build(BuildContext context) {
    var dayNight = context.watch<DayNight>();
    var titleLarge = Theme.of(context).textTheme.titleLarge!;
    var titleMedium = Theme.of(context).textTheme.titleMedium!;
    var titleSmall = Theme.of(context).textTheme.titleSmall!;
    const emStyle = TextStyle(fontStyle: FontStyle.italic);

    context.read<ControlState>();

    var pastEvent = widget.pastEvent;
    // var wasOfficialFinish = pastEvent.wasOfficialFinish;
    var event = pastEvent.event;
    // var outcomes = widget.pastEvent.outcomes;

    final bool isOutcomeFullyUploaded = pastEvent.isCurrentOutcomeFullyUploaded;

    var certString = Signature.forCert(pastEvent).xyText;

    var fileName = "Cert-${AppSettings.rusaID}-${event.eventID}.png";

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Event Finish',
        ),
        actions: [
          IconButton(
              icon: dayNight.icon,
              onPressed: () {
                dayNight.toggleMode();
              })
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => takeScreenShot(fileName),
        child: const Icon(Icons.share),
      ),
      body: Container(
        color: Theme.of(context).colorScheme.inversePrimary,
        padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              children: [
                RepaintBoundary(
                  key: previewContainer,
                  child: Container(
                    padding: const EdgeInsetsDirectional.all(12),
                    decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        borderRadius:
                            const BorderRadius.all(Radius.circular(20))),
                    child: Column(
                      children: [
                        Image.asset(
                          'assets/images/eBrevet-128.png',
                          width: 64,
                        ),
                        Text('Electronic', style: titleLarge),
                        Text('Proof of Passage', style: titleLarge),
                        const SizedBox(
                          height: 4,
                        ),
                        const Text(
                          'The Randonneur',
                          style: emStyle,
                        ),
                        Text(
                          AppSettings.fullName,
                          style: titleMedium,
                        ),
                        Text('RUSA ID ${pastEvent.riderID}', style: titleSmall),
                        const SizedBox(
                          height: 4,
                        ),
                        const Text('Completed the', style: emStyle),
                        Text(event.region.regionName, style: titleMedium),
                        Text('${event.nameDist}', style: titleLarge),
                        Text(
                            '${event.eventSanction} ${event.eventType[0].toUpperCase()}${event.eventType.substring(1).toLowerCase()}',
                            style: titleMedium),
                        const SizedBox(
                          height: 4,
                        ),
                        const Text('Organized by', style: emStyle),
                        Text(event.region.clubName, style: titleMedium),
                        Text('On ${event.startDate}', style: titleSmall),
                        const SizedBox(
                          height: 4,
                        ),
                        const Text('This', style: emStyle),
                        Text(
                          (pastEvent.isPreride)
                              ? 'Volunteer Preride'
                              : 'Scheduled Brevet',
                          style: emStyle,
                        ),
                        const Text('was completed in', style: emStyle),
                        Text(pastEvent.elapsedTimeStringVerbose,
                            style: titleMedium),
                        const SizedBox(
                          height: 4,
                        ),
                        Column(
                          children: [
                            Text(pastEvent.checkInFractionString),
                            Text(
                              pastEvent.isFullyUploadedString,
                              style: TextStyle(
                                  fontWeight: isOutcomeFullyUploaded
                                      ? FontWeight.normal
                                      : FontWeight.bold),
                            ),
                          ],
                        ),
                        Text('Finish Code: $certString', style: emStyle),
                      ],
                    ),
                  ),
                ),
                TextButton(
                    onPressed: () {
                      Navigator.of(context).push(MaterialPageRoute(
                        builder: (context) => ControlDetailPage(
                            pastEvent), // ControlDetailPage(pastEvent),
                      ));
                    },
                    child: const Text('Control Detail')),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void takeScreenShot(String filename) async {
    try {
      if (previewContainer.currentContext == null) {
        throw Exception("No context for preview Container");
      }
      RenderRepaintBoundary boundary = previewContainer.currentContext!
          .findRenderObject() as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage();
      final directory = (await getApplicationDocumentsDirectory()).path;
      var byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) {
        throw const FormatException("Failed converting image to byte data.");
      }
      Uint8List pngBytes = byteData.buffer.asUint8List();
      // print(pngBytes);
      File imgFile = File('$directory/$filename');
      imgFile.writeAsBytes(pngBytes);

      MyLogger.entry("Wrote image of ${pngBytes.length} bytes to $imgFile");

      /// Share Plugin
      await Share.shareXFiles([XFile(imgFile.path)]);
    } catch (e) {
      var message = "Failed to save screenshot: $e";
      SnackbarGlobal.show(message);
      MyLogger.entry(message, severity: Severity.error);
    }
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
}
