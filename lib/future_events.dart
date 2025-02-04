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

// import 'package:flutter/material.dart';
// import 'package:ebrevet_card/report.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';

import 'snackbarglobal.dart';
import 'event.dart';
import 'dart:async';
import 'dart:convert';
import 'files.dart';
import 'exception.dart';
import 'app_settings.dart';
import 'mylogger.dart';
import 'region.dart';
// import 'permanent.dart';

// import 'current.dart';
//
enum FutureEventsSourceID {
  fromRegion('US RUSA Region'),
  fromInternationalRegion('International Region'),
  // fromPerm('RUSA Permanent Search'),
  fromURL('Custom Event Data URL');

  final String description;
  const FutureEventsSourceID(this.description);

  String toJson() => name;
  static FutureEventsSourceID fromJson(String json) => values.byName(json);
  static const FutureEventsSourceID defaultID = FutureEventsSourceID.fromRegion;
}

class FutureEventsSource {
  final FutureEventsSourceID id;
  final String url;

  String get description => id.description;

  String get fullDescription {
    return "${id.description}: $subDescription";
  }

  String get subDescription {
    String d;
    switch (id) {
      case FutureEventsSourceID.fromRegion:
      case FutureEventsSourceID.fromInternationalRegion:
        var rgn = Region.fromSettings();
        d = rgn.regionName;
        break;
      case FutureEventsSourceID.fromURL:
        d = "($url)";
        break;
      // case FutureEventsSourceID.fromPerm:
      //   d = "($url)";
      //   break;
    }
    return d;
  }

  factory FutureEventsSource.fromSettingsSourceID() {
    var sourceID = AppSettings.futureEventsSourceID.value;
    String eventsURL;
    switch (sourceID) {
      case FutureEventsSourceID.fromRegion:
        var rgn = Region.fromSettings();
        eventsURL = rgn.futureEventsURL;
        break;
      case FutureEventsSourceID.fromInternationalRegion:
        var rgn = Region.fromSettings();
        eventsURL = rgn.futureEventsURL;
        break;
      // case FutureEventsSourceID.fromPerm:
      //   var perm = Permanent.fromSettings();
      //   eventsURL = perm.futureEventsURL;
      //   break;
      case FutureEventsSourceID.fromURL:
        eventsURL = AppSettings.eventInfoURL.value;
        break;
    }
    return FutureEventsSource(sourceID, eventsURL);
  }

  // factory FutureEventsSource.fromSelectedRegion() {
  //   var rgn = Region.fromSettings();
  //   var eventsURL = rgn.futureEventsURL;
  //   return FutureEventsSource(FutureEventsSourceID.fromRegion, eventsURL);
  // }

  // factory FutureEventsSource.fromCustomURL() {
  //   var eventsURL = AppSettings.eventInfoURL;
  //   return FutureEventsSource(FutureEventsSourceID.fromURL, eventsURL);
  // }

  FutureEventsSource(this.id, this.url);

  FutureEventsSource.fromJson(Map<String, dynamic> json)
      : id = FutureEventsSourceID.fromJson(json['id']),
        url = json['url'];

  Map<String, dynamic> toJson() => {
        'id': id.toJson(),
        'url': url,
      };
}

// This class stores the currently selected event info source
// and provides change notification to anything that cares

class SourceSelection extends ChangeNotifier {
  FutureEventsSource eventInfoSource;

  SourceSelection()
      : eventInfoSource = FutureEventsSource.fromSettingsSourceID();

  updateFromSettings() {
    eventInfoSource = FutureEventsSource.fromSettingsSourceID();
    notifyListeners();
  }
}

class FutureEvents {
  static var events = <Event>[]; // List of events

  static FutureEventsSource?
      eventInfoSource; // where did the above list of events come from
  static const eventInfoSourceFieldName = 'event_info_source';

  static DateTime? lastRefreshed; // Time when last refreshed from server
  static const lastRefreshedFieldName = 'last_refreshed';

  static var storedEvents = FileStorage(AppSettings.futureEventsFilename);

  static void clear() {
    events.clear();
    lastRefreshed = null;
    // refreshCount.value = 0;
    //   rider = null;
    eventInfoSource = null;
    storedEvents.clear();
  }

  static Future<String> refreshEventsFromDisk() async {
    Map<String, dynamic> eventMapFromFile;
    try {
      MyLogger.entry("** Refreshing events from ${storedEvents.fileName}");

      try {
        eventMapFromFile = await storedEvents.readJSON();
      } catch (e) {
        throw NoPreviousDataException(
            'Cound not read ${storedEvents.fileName} file.');
      }

      var lrs = '';
      if (eventMapFromFile.isNotEmpty) {
        rebuildEventList(eventMapFromFile);

        if (eventMapFromFile.containsKey(lastRefreshedFieldName)) {
          var timestamp = eventMapFromFile[lastRefreshedFieldName];
          lrs = "lastRefreshed = $timestamp";
          lastRefreshed = DateTime.tryParse(timestamp)?.toLocal();
        } else {
          lastRefreshed = null;
          lrs = "Unkown";
        }

        if (eventMapFromFile.containsKey(eventInfoSourceFieldName)) {
          eventInfoSource = FutureEventsSource.fromJson(
              eventMapFromFile[eventInfoSourceFieldName]);
        } else {
          eventInfoSource = FutureEventsSource(FutureEventsSourceID.fromRegion,
              Region.fromSettings().futureEventsURL);
        }

        // refreshCount.value++;
        MyLogger.entry(
            "Successfully restored ${events.length} events from disk. Last Refreshed = $lrs");
        return lrs;
        //refreshCount.value;
      } else {
        throw NoPreviousDataException("Future events file read was empty.");
      }
    } catch (error) {
      events.clear();
      MyLogger.entry("Couldn't refresh future events from FILE: $error");
      return 'unknown'; // 0;
    }
  }

  static Future<bool> refreshEventsFromServer(
      FutureEventsSource futureEventsSource, BuildContext context) async {
    try {
      MyLogger.entry(
          "Refreshing events from SERVER for ${futureEventsSource.description} with"
          " URL ${futureEventsSource.url}");

      // Then try to fetch from the server in background with callback to process
      var eventMapFromServer =
          await fetchFutureEventsFromServer(futureEventsSource.url);
      if (null == eventMapFromServer) return false;
      rebuildEventList(eventMapFromServer);
      var now = DateTime.now();
      eventMapFromServer[lastRefreshedFieldName] =
          now.toUtc().toIso8601String();
      eventMapFromServer[eventInfoSourceFieldName] = futureEventsSource;
      var writeStatus = await storedEvents.writeJSON(
          eventMapFromServer); // Save what we just downloaded to disk
      lastRefreshed = now;
      eventInfoSource = futureEventsSource;

      // refreshCount.value++;
      MyLogger.entry("Refresh complete. Write status: $writeStatus");
    } on CueWizardException catch (error) {
      if (context.mounted) {
        cueWizardErrorDialog(error, futureEventsSource, context);
      }
    } catch (error) {
      if (error is IncompatibleVersionException) {
        if (context.mounted) {
          versionErrorDialog(error, futureEventsSource, context);
        }
        events.clear();
      } else {
        SnackbarGlobal.show(error.toString());
      }
      MyLogger.entry("Error refreshing events: $error");

      return false;
    }
    return true;
  }

  static Future<bool?> versionErrorDialog(IncompatibleVersionException error,
          FutureEventsSource futureEventsSource, BuildContext context) =>
      showDialog<bool>(
          context: context,
          builder: (BuildContext ctx) {
            return AlertDialog(
              icon: const Icon(Icons.error, size: 62.0),
              title: const Text('Incompatible App Version'),
              content: Text(
                  "You have version ${error.actual} of this app installed, "
                  "but the ${futureEventsSource.fullDescription} event data server requires "
                  "version ${error.required} or newer. Please update this app to the latest version."),
              actions: [
                // The "Yes" button
                TextButton(
                    onPressed: () {
                      Navigator.of(context).pop(true);
                    },
                    child: const Text('Continue'))
              ],
            );
          });

  static Future<bool?> cueWizardErrorDialog(CueWizardException e,
          FutureEventsSource futureEventsSource, BuildContext context) =>
      showDialog<bool>(
          context: context,
          builder: (BuildContext ctx) {
            return AlertDialog(
              icon: const Icon(Icons.error, size: 62.0),
              title: const Text('Route Data Errors'),
              content: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text("Errors/Warnings found in event data retrieved from "
                        "the ${futureEventsSource.fullDescription}. "),
                    Text(
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium!
                            .copyWith(fontStyle: FontStyle.italic),
                        "The event organizer should use the Route Manager to explore/fix these problems before publishing events."),
                    for (var errorMessage in e.errorList)
                      Container(
                          color: Theme.of(context).colorScheme.errorContainer,
                          margin: const EdgeInsets.all(4),
                          padding: const EdgeInsets.all(8),
                          child: Text(errorMessage)),
                  ],
                ),
              ),
              actions: [
                // The "Yes" button
                TextButton(
                    onPressed: () {
                      Navigator.of(context).pop(true);
                    },
                    child: const Text('Continue'))
              ],
            );
          });

  // The first event in the "future events" list needs to be available sufficiently after start time
  // or the event ends.  We don't want it to "disappear" before we are done with it should
  // a user refresh events from the server. Certainly riders need
  // to be able to see events after they are done. And restarting the app should not lose
  // the last events download.

  // Need belt and suspenders here -- the SQL should only send future events,
  // But this code still should prune past events that accidentally
  // appear in the future_events download

  static const keepInFutureEventListAfterFinishHours = 12; // hours

  static void rebuildEventList(Map eventMap) {
    List el = eventMap['event_list'];
    MyLogger.entry("Start rebuildEventList() from ${el.length} events in Map");
    events.clear();
    for (var e in el) {
      var eventToAdd = Event.fromJson(e);

      if (eventToAdd.valid == false) {
        throw const FormatException('Invalid event data found.');
      }

      if (eventToAdd.cueVersion <= 0) {
        MyLogger.entry("Ignoring event with no cue sheet.");
        continue;
      }

      if (eventToAdd.startTimeWindow.onTime == null) {
        events.add(eventToAdd); // Permanent
      } else {
        var now = DateTime.now();
        var graceDuration =
            const Duration(hours: keepInFutureEventListAfterFinishHours);
        var eventReallyEnds = eventToAdd.latestFinishTime!.add(graceDuration);
        if (eventReallyEnds.isAfter(now)) {
          events.add(eventToAdd);
        } else {
          MyLogger.entry(
              "Ignoring past event ${eventToAdd.name} ${eventToAdd.distance}K on ${eventToAdd.startTimeWindow.onTime.toString()}");
        }
      }
    }
    events.sort(Event.sort);
    // rider = r;
    var n = events.length;
    MyLogger.entry("Event List rebuilt with $n events.");
  }

  static Future<Map<String, dynamic>?> fetchFutureEventsFromServer(
      String url) async {
    MyLogger.entry('Fetching future event data from $url');

    Map<String, dynamic> decodedResponse;
    http.Response? response;

    try {
      response = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: AppSettings.httpGetTimeoutSeconds));
    } on TimeoutException {
      throw ServerException(
          'No response from $url after (${AppSettings.httpGetTimeoutSeconds} sec timeout).');
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
      if (false == decodedResponse.containsKey('minimum_app_version')) {
        throw ServerException(
            'Missing app version value in response from $url');
      }

      String minimumAppVersion = decodedResponse['minimum_app_version'];

      if (isIncompatibleAppVersion(minimumAppVersion)) {
        throw IncompatibleVersionException(
            actual: AppSettings.version ?? 'unknown',
            required: minimumAppVersion);
      }

      if (false == decodedResponse.containsKey('event_list')) {
        throw ServerException('No event_list key in response from $url');
      }

      if (true == decodedResponse.containsKey('event_errors') &&
          decodedResponse['event_errors'].isNotEmpty) {
        List<String> eventErrors =
            List<String>.from(decodedResponse['event_errors'] as List);
        throw CueWizardException(eventErrors);
      }

      return decodedResponse;
    }
  }

  static const numberOfSubversions = 3;
  static final versionPattern = RegExp(r'^(\d+)\.(\d+)\.(\d+)$');

  static bool isIncompatibleAppVersion(String minimumAppVersion) {
    final myVersion = AppSettings.version ?? '0.0.0';

    RegExpMatch? myVersionMatch = versionPattern.firstMatch(myVersion);
    assert(myVersionMatch != null);

    RegExpMatch? minimumAppVersionMatch =
        versionPattern.firstMatch(minimumAppVersion);

    if (minimumAppVersionMatch == null && myVersionMatch != null) {
      throw ServerException(
          'Empty or invalid app version value in response from server.');
    } else {
      for (var i = 1; i <= numberOfSubversions; i++) {
        var required = int.parse(minimumAppVersionMatch!.group(i)!);
        var mine = int.parse(myVersionMatch!.group(i)!);
        if (mine < required) {
          return true;
        }
        if (mine > required) {
          return false;
        }
      }
      return false;
    }

    // return false;
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
