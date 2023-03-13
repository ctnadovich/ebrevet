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
import 'package:http/http.dart' as http;

import 'snackbarglobal.dart';
import 'event.dart';
import 'region.dart';
import 'dart:async';
import 'dart:convert';
import 'files.dart';
import 'exception.dart';
import 'app_settings.dart';

// import 'current.dart';

class FutureEvents {
  static var events = <Event>[];
  // static Rider? rider; // Rider associated with the event download
  static Region? region; // Region associated with the event download
  static DateTime? lastRefreshed;
  static ValueNotifier<int> refreshCount = ValueNotifier(0);
  static const futureEventsFileName = 'future_events.json';
  static var storedEvents = FileStorage(futureEventsFileName);

  static void clear() {
    events.clear();
    lastRefreshed = null;
    refreshCount.value = 0;
    //   rider = null;
    region = null;
    storedEvents.clear();
  }

  static Future<int> refreshEventsFromDisk(Region rgn) async {
    Map<String, dynamic> eventMapFromFile;
    try {
      print("** Refreshing events from DISK for ${rgn.clubName}");

      try {
        eventMapFromFile = await storedEvents.readJSON();
      } catch (e) {
        throw NoPreviousDataException(
            'Cound not read ${storedEvents.fileName} file.');
      }

      var lrs = '';
      if (eventMapFromFile.isNotEmpty) {
        rebuildEventList(eventMapFromFile, rgn);
        if (eventMapFromFile.containsKey('lastRefreshed')) {
          var timestamp = eventMapFromFile['lastRefreshed'];
          lrs = "lastRefreshed = $timestamp";
          lastRefreshed = DateTime.tryParse(timestamp)?.toLocal();
        } else {
          lastRefreshed = null;
          lrs = "Unkown";
        }
        refreshCount.value++;
        print(
            "Successfully restored ${events.length} events from disk. Last Refreshed = $lrs");
        return refreshCount.value;
      } else {
        throw NoPreviousDataException("Future events file read was empty.");
      }
    } catch (error) {
      events.clear();
      // TODO Do somethnig better than just printing this, if possible.
      print("Couldn't refresh future events from FILE: $error");
      return 0;
    }
  }

  static Future<bool> refreshEventsFromServer(Region rgn) async {
    try {
      print("Refreshing events from SERVER for ${rgn.clubName}");

      // Then try to fetch from the server in background with callback to process
      var eventMapFromServer = await fetchFutureEventsFromServer(rgn);
      if (null == eventMapFromServer) return false;
      rebuildEventList(eventMapFromServer, rgn);
      var now = DateTime.now();
      eventMapFromServer['lastRefreshed'] = now.toUtc().toIso8601String();
      var writeStatus = await storedEvents.writeJSON(
          eventMapFromServer); // Save what we just downloaded to disk
      lastRefreshed = now;
      refreshCount.value++;
      print("Refresh complete. Write status: $writeStatus");
    } catch (error) {
      // events.clear();
      SnackbarGlobal.show(error.toString());
      // TODO format this and adjust the text (maybe need custom exception class?)
      print("Error refreshing events: $error");
      return false;
    }
    return true;
  }

  // The first event in the "future events" list needs to be available sufficiently after start time
  // or the event ends.  We don't want it to "disappear" before we are done with it should
  // a user refresh events from the server. Certainly riders need
  // to be able to see events after they are done. And restarting the app should not lose
  // the last events download.

  // Need belt and suspenders here -- the SQL should only send future events,
  // But this code still should prune past events that accidentally
  // appear in the future_events download

  static const futureEventGraceTime = 12; // hours

  static void rebuildEventList(Map eventMap, Region g) {
    List el = eventMap['event_list'];
    print("rebuildEventList() from ${el.length} events in Map");
    events.clear();
    for (var e in el) {
      var eventToAdd = Event.fromMap(e);
      if (eventToAdd.valid == false) {
        throw FormatException('Invalid event data found.');
      }

      var now = DateTime.now();
      var eventReallyEnds =
          eventToAdd.endDateTime.add(Duration(hours: futureEventGraceTime));
      if (eventReallyEnds.isAfter(now)) events.add(eventToAdd);
    }
    events.sort((a, b) => a.startDateTime.isBefore(b.startDateTime)
        ? -1
        : (a.startDateTime.isAfter(b.startDateTime) ? 1 : 0));
    // rider = r;
    region = g;
    var n = events.length;
    print("Event List rebuilt with $n events in ${region!.clubName}.");
  }

  static Future<Map<String, dynamic>?> fetchFutureEventsFromServer(
      Region rgn) async {
    var futureEventsURL = rgn.eventURL;

    String url = '$futureEventsURL/future_events';
    print('Fetching future event data from $url');

    Map<String, dynamic> decodedResponse;
    http.Response? response;


    try {
      response = await http
          .get(Uri.parse(url))
          .timeout(Duration(seconds: AppSettings.httpGetTimeoutSeconds));
    } on TimeoutException {
      throw ServerException(
          'No response from server (${AppSettings.httpGetTimeoutSeconds} sec timeout).');
    } catch (e) {
      throw NoInternetException('Network error: $e');
    }

    if (response.statusCode != 200) {
      throw ServerException(
          'Error response from $url (Status Code: ${response.statusCode})');
    } else {
      decodedResponse = jsonDecode(response.body);

      if (decodedResponse is List && decodedResponse.isEmpty) {
        throw ServerException('Empty reponse from $url');
      }

      if (false == decodedResponse.containsKey('event_list')) {
        throw ServerException('No event_list key in response from $url');
      }

      if (true == decodedResponse.containsKey('event_errors') &&
          decodedResponse['event_errors'].isNotEmpty) {
        throw ServerException('Server side errors found in response from $url');
      }

      return decodedResponse;
    }
  }

  static String get lastRefreshedStr {
    if (lastRefreshed == null) {
      return 'Never';
    } else {
      return lastRefreshed.toString().substring(0, 16);
    }
  }

  static String get lastRefreshedSince {
    if (lastRefreshed == null) {
      return 'Never';
    } else {
      var since = DateTime.now().difference(lastRefreshed!);
      return since.toString();
    }
  }
}
