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

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:ebrevet_card/snackbarglobal.dart';

import 'day_night.dart';
import 'mylogger.dart';

class LogPage extends StatefulWidget {
  const LogPage({
    super.key,
  });
  @override
  LogPageState createState() {
    return LogPageState();
  }
}

class LogPageState extends State<LogPage> {
  // static GlobalKey previewContainer = GlobalKey();

  final spacerBox = const SizedBox(
    height: 16,
  );

  @override
  Widget build(BuildContext context) {
    var dayNight = context.watch<DayNight>();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Log',
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
        onPressed: () =>
            shareTextLog(), // ScreenShot.take(fileName, previewContainer),
        child: const Icon(Icons.share),
      ),
      body: Container(
        color: Theme.of(context).colorScheme.primaryContainer,
        padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
        child:
            // RepaintBoundary(
            //  key: previewContainer,
            //   child:
            ListView(
          children: [
            ...MyLogger.records.reversed.map((s) => (Text(s))),
          ],
        ),
        //),
      ),
    );
  }

  static void shareTextLog({String filename = 'eBrevetLog.txt'}) async {
    MyLogger.entry("Sharing activity log");
    var logList = MyLogger.records.reversed.toList();
    var logText = logList.join('\n');
    try {
      ShareResult shareResult =
          await Share.shareWithResult(logText, subject: "eBrevet Activity Log");
      MyLogger.entry(shareResult.status.toString());
    } catch (e) {
      var message = "Failed to share activity log";
      SnackbarGlobal.show(message);
    }
  }
}
