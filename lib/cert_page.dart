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

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'event_history.dart';
import 'day_night.dart';

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

    var pastEvent = widget.pastEvent;
    // var wasOfficialFinish = pastEvent.wasOfficialFinish;
    var event = pastEvent.event;
    // var outcomes = widget.pastEvent.outcomes;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Certificate of eCompletion',
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
          child: ListView(
            children: [
              Text('${event.nameDist}'),
              Text('${event.eventSanction} ${event.eventType}'),
              Text('Completed in ${widget.pastEvent.elapsedTimeString}')
            ],
          ),
        ),
      ),
    );
  }
}
