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

// import 'package:flutter_settings_screens/flutter_settings_screens.dart';
import 'snackbarglobal.dart';
import 'location.dart';
import 'current.dart';

// Where is this control in the scheme of thngs
enum SIF { start, intermediate, finish, unknown }

class Control {
  late double distMi;
  late double long;
  late double lat;
  late String name;
  late String style;
  late String address;
  late DateTime open;
  late DateTime close;

  late int index;
  SIF sif = SIF.unknown;
  bool valid = false;

  Map<String, dynamic> get toMap => {
        'dist_mi': distMi,
        'long': long,
        'lat': lat,
        'name': name,
        'style': style,
        'address': address,
        'open': open.toUtc().toIso8601String(),
        'close': close.toUtc().toIso8601String(),
        'index': index,
        'sif': sif == SIF.start
            ? 'start'
            : (sif == SIF.finish ? 'finish' : 'intermediate'),
      };

  Control.fromMap(this.index, Map<String, dynamic> m) {
    try {
      distMi = double.parse(m['dist_mi'].toString());
      lat = double.parse(m['lat'].toString());
      long = double.parse(m['long'].toString());
      name = m['name'] ?? '<unknown>';
      style = m['style'] ?? '<unknown>';
      address = m['address'] ?? '<unknown>';
      open = DateTime.parse(m['open'] ?? '').toLocal();
      close = DateTime.parse(m['close'] ?? '').toLocal();

      switch (m['sif']) {
        case 'start':
          sif = SIF.start;
          break;
        case 'finish':
          sif = SIF.finish;
          break;
        case 'intermediate':
          sif = SIF.intermediate;
          break;
        default:
          sif = SIF.unknown;
          break;
      }
      valid = true;
    } catch (error) {
      var etxt = "Error converting JSON response control map: $error";
      SnackbarGlobal.show(etxt);
    }
  }

  get cLoc => ControlLocation(this);

  Duration openDuration(DateTime s) => open.difference(s);
  Duration closeDuration(DateTime s) => close.difference(s);

  String? closeDurationString(DateTime start){ 
    var d = close.difference(start);
    var a = d.inDays;
    var h = d.inHours;
    var m = d.inMinutes;
    var s = "$m min";
    if (h>0) s = "$h hrs, $s";
    if (a>0) s = "$a days, $s";
    return s;
  }

  get openTimeString =>
      open.toLocal().toString().substring(0, 16) + open.toLocal().timeZoneName;
  get closeTimeString =>
      close.toLocal().toString().substring(0, 16) +
      close.toLocal().timeZoneName;

  
}
