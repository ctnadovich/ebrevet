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

import 'package:ebrevet_card/signature.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'event_history.dart';
import 'day_night.dart';
import 'view_page.dart';
import 'mylogger.dart';

class CertificatePage extends StatefulWidget {
  final PastEvent pastEvent;
  const CertificatePage(this.pastEvent, {super.key});
  @override
  State<CertificatePage> createState() => _CertificatePageState();
}

class _CertificatePageState extends State<CertificatePage> {
  @override
  Widget build(BuildContext context) {
    var dayNight = context.watch<DayNight>();
    var titleLarge = Theme.of(context).textTheme.titleLarge!;
    var titleMedium = Theme.of(context).textTheme.titleMedium!;
    var emStyle = const TextStyle(fontStyle: FontStyle.italic);
    

    var pastEvent = widget.pastEvent;
    // var wasOfficialFinish = pastEvent.wasOfficialFinish;
    var event = pastEvent.event;
    // var outcomes = widget.pastEvent.outcomes;

    var certSignature = Signature(
      event: event, 
      riderID: pastEvent.riderID, 
      data: widget.pastEvent.elapsedTimeStringhhmm,
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
      body: Container(
        color: Theme.of(context).colorScheme.primaryContainer,
        padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
        child: Center(
          child: SingleChildScrollView(
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
                 Text('The Randonneur', style: emStyle,),
                Text('RUSA ID ${pastEvent.riderID}', style: titleMedium),
                const SizedBox(
                  height: 4,
                ),
                 Text('Completed the', style: emStyle),
                Text(event.region.regionName, style: titleMedium),
                Text('${event.nameDist}', style: titleLarge),
                Text('${event.eventSanction} ${event.eventType}', style: titleMedium),
                const SizedBox(
                  height: 4,
                ),
                 Text('Organized by', style: emStyle),
                Text(event.region.clubName, style: titleLarge),
                Text('On ${event.startDate}', style: titleMedium),
                const SizedBox(
                  height: 4,
                ),
                 Text('This ride was completed in', style: emStyle),
                Text(widget.pastEvent.elapsedTimeStringVerbose,
                    style: titleLarge),

                const SizedBox(
                  height: 4,
                ),
                   Text('Finish Code: $certString', style: emStyle),
              
                TextButton(
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                  ),
                  onPressed: () async {
                    if (context.mounted) {
                      Navigator.of(context).push(MaterialPageRoute(
                        builder: (context) => ViewPage(pastEvent),
                      ));
                    } else {
                      MyLogger.logInfo("Not mounted!?");
                    }
                  },
                  child: const Text("Control Detail"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
