import 'snackbarglobal.dart';
import 'control.dart';
import 'time_till.dart';


// The Event object documents an event details
// with no reference to who is riding the event
// or what the event outcomes are

class Event {
  bool valid = false;
  late String name;
  late DateTime startDateTime;
  late DateTime endDateTime;
  // late String date;
  late String distance; // Official distance in KM
  late String startCity;
  late String startState;
  late int cueVersion;
  late String
      eventID; // This must be unique worldwide (could be contstructed "$regionID-$regionEventID")

// For now, eventID is a String, but... 
// Maybe the eventID needs to be wrapped in a class

  late int regionID; // Numeric ACP Club Code
  final List<Control> controls = [];

  Map<String, dynamic> get toMap =>
  {
    'name':name,
    'start_datetime_utc':startDateTime.toUtc().toIso8601String(),
    'end_datetime_utc':endDateTime.toUtc().toIso8601String(),
    'distance':distance,
    'start_city':startCity,
    'start_state':startState,
    'cue_version':cueVersion,
    'event_id':eventID,
    'club_acp_code':regionID,
    'controls':[for (var cntrl in controls) cntrl.toMap],
  };


  Event.fromMap(Map<String, dynamic> json) {
    try {
      name = json['name'];
      String startDateTimeUTCString = json['start_datetime_utc'];
      String endDateTimeUTCString = json['end_datetime_utc'];
      startDateTime = DateTime.parse(startDateTimeUTCString);
      endDateTime = DateTime.parse(endDateTimeUTCString);
      distance = json['distance'];
      startCity = json['start_city'];
      startState = json['start_state'];
      cueVersion = (json['cue_version'] is int) ? json['cue_version'] : int.tryParse(json['cue_version'])!;
      eventID = json['event_id'];
      regionID = (json['club_acp_code'] is int) ? json['club_acp_code'] : int.tryParse(json['club_acp_code'])!;
      List<dynamic> controlsListMap = json['controls'];
      print('Event.fromMap() restored $name from JSON. Found ${controlsListMap.length} controls.');
      controls.clear();
      for (var i = 0; i < controlsListMap.length; i++) {
        var controlMap = controlsListMap[i];
        var c = Control.fromMap(i, controlMap);
        if (c.valid) {
          controls.add(c);
        } else {
          break;
        }
      }
      valid = true;
    } catch (error) {
      var etxt = "Error converting JSON future event response: $error";
      SnackbarGlobal.show(etxt);
      print(etxt);
    }
  }

  get nameDist {
    return '$name ${distance}K';
  }

  // The event_id from server must be unique worldwide
  // String get key {
  //   return "$regionID-$eventID";
  // }

  get dateTime {
    var sdtl = startDateTime.toLocal();
    return sdtl.toString().substring(0, 16);
  }

  get status {
    DateTime now = DateTime.now();
    if (startDateTime.isAfter(now)) {
      // Event in future
      var tt = TimeTill(startDateTime);
      return "Starts in ${tt.interval} ${tt.unit}";
    } else if (endDateTime.isBefore(now)) {
      // Event in past
      var tt = TimeTill(endDateTime);
      return "Ended ${tt.interval} ${tt.unit} ago";
    } else {
      return 'Underway!';
    }
  }

  String get cueVersionString {
    if (cueVersion > 0) {
      return '$cueVersion';
    } else {
      return 'No cue sheet';
    }
  }

  int get finishControlKey {
    return controls.last.index;
  }

  int get startControlKey {
    return controls.first.index;
  }
}
