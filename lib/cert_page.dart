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
import 'package:screenshot/screenshot.dart';
import 'package:ebrevet_card/signature.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'event_history.dart';
import 'day_night.dart';
import 'view_page.dart';
import 'mylogger.dart';
import 'control_state.dart';

class CertificatePage extends StatefulWidget {
  final PastEvent pastEvent;
  const CertificatePage(this.pastEvent, {super.key});
  @override
  State<CertificatePage> createState() => _CertificatePageState();
}

class _CertificatePageState extends State<CertificatePage> {
  ScreenshotController screenshotController = ScreenshotController();

  @override
  Widget build(BuildContext context) {
    var dayNight = context.watch<DayNight>();
    var titleLarge = Theme.of(context).textTheme.titleLarge!;
    var titleMedium = Theme.of(context).textTheme.titleMedium!;
    const emStyle = TextStyle(fontStyle: FontStyle.italic);

    context.read<ControlState>();

    var pastEvent = widget.pastEvent;
    // var wasOfficialFinish = pastEvent.wasOfficialFinish;
    var event = pastEvent.event;
    // var outcomes = widget.pastEvent.outcomes;

    final bool isOutcomeFullyUploaded = pastEvent.isCurrentOutcomeFullyUploaded;

    var certSignature = Signature(
        event: event,
        riderID: pastEvent.riderID,
        data:
            "${pastEvent.outcomes.overallOutcome.description}:${widget.pastEvent.elapsedTimeStringhhmm}",
        codeLength: 4);
    var certString = Signature.substituteZeroOneXY(certSignature.text);

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
        onPressed: () => _takeScreenshot(),
        child: const Icon(Icons.share),
      ),
      body: Container(
        color: Theme.of(context).colorScheme.primaryContainer,
        padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              children: [
                Screenshot(
                  controller: screenshotController,
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
                      Text('RUSA ID ${pastEvent.riderID}', style: titleMedium),
                      const SizedBox(
                        height: 4,
                      ),
                      const Text('Completed the', style: emStyle),
                      Text(event.region.regionName, style: titleMedium),
                      Text('${event.nameDist}', style: titleLarge),
                      Text('${event.eventSanction} ${event.eventType}',
                          style: titleMedium),
                      const SizedBox(
                        height: 4,
                      ),
                      const Text('Organized by', style: emStyle),
                      Text(event.region.clubName, style: titleLarge),
                      Text('On ${event.startDate}', style: titleMedium),
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
                          style: titleLarge),
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

  void _takeScreenshot() async {
    final imageData = await screenshotController.capture();
    if (imageData != null) {
      Share.shareXFiles([XFile.fromData(imageData)]);
    } else {
      MyLogger.entry('Could not take screenshot.', severity: Severity.warning);
    }
  }
}
