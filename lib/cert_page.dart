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

import 'package:ebrevet_card/signature.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'activated_event.dart';
import 'day_night.dart';
import 'activated_event_view_page.dart';
import 'control_state.dart';
import 'app_settings.dart';
import 'screen_shot.dart';
import 'utility.dart';

class CertificatePage extends StatefulWidget {
  final ActivatedEvent pastEvent;
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
    var titleLarge = Theme.of(context)
        .textTheme
        .titleLarge
        ?.copyWith(color: Theme.of(context).colorScheme.onSurface);
    var titleMedium = Theme.of(context)
        .textTheme
        .titleMedium
        ?.copyWith(color: Theme.of(context).colorScheme.onSurface);
    var titleSmall = Theme.of(context)
        .textTheme
        .titleSmall
        ?.copyWith(color: Theme.of(context).colorScheme.onSurface);

    // Theme.of(context).textTheme.titleLarge!;

    const emStyle = TextStyle(fontStyle: FontStyle.italic);

    var inversePrimary = Theme.of(context).colorScheme.inversePrimary;

    var gradientStart = Theme.of(context).colorScheme.surfaceBright;
    var gradientMid = Theme.of(context).colorScheme.surface;
    var gradientEnd = Theme.of(context).colorScheme.surfaceDim;
    gradientStart = Utility.increaseColorHue(gradientStart, 0);
    gradientStart = Utility.increaseColorLightness(gradientStart, -.1);
    gradientEnd = Utility.increaseColorHue(gradientEnd, 180);
    gradientEnd = Utility.increaseColorSaturation(gradientEnd, 0.5);
    gradientEnd = Utility.increaseColorLightness(gradientEnd, -.25);

    var border = Theme.of(context).colorScheme.onSurfaceVariant;

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
        onPressed: () => ScreenShot.take(fileName, previewContainer),
        child: const Icon(Icons.share),
      ),
      body: Container(
        color: inversePrimary,
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
                        gradient: LinearGradient(
                            // colors: [
                            //   Colors.red[100]!,
                            //   Colors.white,
                            //   Colors.blue[100]!
                            // ],
                            colors: [gradientStart, gradientMid, gradientEnd],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight),
                        border: Border.all(
                          // color: Colors.yellowAccent,
                          color: border,
                          width: 2,
                        ),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.blueAccent,
                            offset: Offset(5, 5),
                            blurRadius: 10,
                          ),
                        ],
                        borderRadius:
                            const BorderRadius.all(Radius.circular(20))),
                    child: Theme(
                      data: Theme.of(context).copyWith(
                        textTheme: const TextTheme(
                          bodyLarge:
                              TextStyle(fontSize: 20, color: Colors.blue),
                          bodyMedium:
                              TextStyle(fontSize: 16, color: Colors.red),
                        ),
                      ),
                      child: Column(
                        children: [
                          Image.asset(
                            'assets/images/eBrevet-128.png',
                            width: 64,
                          ),
                          Text('Finish Certificate', style: titleLarge),
                          // Text('Proof of Passage', style: titleLarge),
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
                          Text('RUSA ID ${pastEvent.riderID}',
                              style: titleSmall),
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
                          // const Text('This', style: emStyle),
                          Text(
                            pastEvent.startStyle.description,
                            style: emStyle,
                          ),
                          const Text('completed in', style: emStyle),
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
                ),
                TextButton(
                    onPressed: () {
                      Navigator.of(context).push(MaterialPageRoute(
                        builder: (context) => ActivatedEventViewPage(
                          event: pastEvent,
                          isLiveView: false,
                          showScreenshotButton: true,
                        ), // ControlDetailPage(pastEvent),
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
}
