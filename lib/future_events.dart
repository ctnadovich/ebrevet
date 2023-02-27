import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'snackbarglobal.dart';
import 'event.dart';
import 'region.dart';
import 'rider.dart';
import 'dart:async';
import 'dart:convert';
import 'files.dart';
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
    try {
      print("** Refreshing events from DISK for ${rgn.name}");

      var eventMapFromFile = await storedEvents.readJSON();
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
        throw Exception("Future events file read was empty.");
        // TODO Maybe need custom exception classes?
      }
    } catch (error) {
      events.clear();
      // TODO Do somethnig better than just printing this, if possible.
      print("Couldn't refresh events from FILE: $error");
      return 0;
    }
  }

  static Future<bool> refreshEventsFromServer(Rider rdr, Region rgn) async {
    // The first event in the "future events" list needs to be available sufficiently after start time
    // or the event ends.  We don't want it to "disappear" before we are done with it should
    // a user refresh events from the server. Certainly riders need
    // to be able to see events after they are done. And restarting the app should not lose
    // the last events download.

    // TODO Need belt and suspenders here -- the SQL should only send future events,
    // But this code still should prune past events that accidentally
    // appear in the future_events download

    try {
      print("Refreshing events from SERVER for ${rdr.firstLastRUSA}");

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

  static void rebuildEventList(Map eventMap, Region g) {
    List el = eventMap['event_list'];
    print("rebuildEventList() from ${el.length} events in Map");
    events.clear();
    for (var e in el) {
      var eventToAdd = Event.fromMap(e);
      if (eventToAdd.valid == false) {
        throw Exception('Invalid event data found.');
      }
      events.add(eventToAdd);
    }
    events.sort((a, b) => a.startDateTime.isBefore(b.startDateTime)
        ? -1
        : (a.startDateTime.isAfter(b.startDateTime) ? 1 : 0));
    // rider = r;
    region = g;
    var n = events.length;
    print("Event List rebuilt with $n events in ${region!.name}.");
  }

  static Future<Map<String, dynamic>?> fetchFutureEventsFromServer(
      Region rgn) async {
    var futureEventsURL = rgn.eventURL;

    String url = '$futureEventsURL/future_events';
    print('Fetching future event data from $url');

    Map<String, dynamic> decodedResponse;
    http.Response? response;

    try {
      response = await http.get(Uri.parse(url)).timeout(Duration(seconds: 15));
    } catch (e) {
      throw Exception('Failed to fetch data for events. No Internet? $e');
    }  // TODO perhaps handle the timeout exception differently than no internet

    if (response.statusCode == 200) {
      decodedResponse = jsonDecode(response.body);

      if (decodedResponse is List && decodedResponse.isEmpty) {
        throw Exception('No Data for region ${rgn.name}.');
      }

      if (false == decodedResponse.containsKey('event_list')) {
        throw Exception(
            'Failed to load future events from $futureEventsURL (Missing field in response).');
      }

      if (true == decodedResponse.containsKey('event_errors') &&
          decodedResponse['event_errors'].isNotEmpty) {
        throw Exception('Errors found in response from $futureEventsURL');
      }

      return decodedResponse;
    } else {
      // If the server did not return a 200 OK response,
      // then throw an exception.
      throw Exception(
          'Failed to load future events for Region ${rgn.name} from $url (Status Code: ${response.statusCode})');
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
