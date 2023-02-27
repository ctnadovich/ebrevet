import 'package:flutter_settings_screens/flutter_settings_screens.dart';
import 'snackbarglobal.dart';
import 'location.dart';

// Where is this control in the scheme of thngs
enum SIF {
  start,
  intermediate,
  finish,
  unknown
} 

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

  Map<String, dynamic> get toMap =>
  {
  'dist_mi': distMi,
  'long': long,
  'lat': lat,
  'name': name,
  'style': style,
  'address': address,
  'open': open.toUtc().toIso8601String(),
  'close': close.toUtc().toIso8601String(),
  'index': index,
  'sif': sif==SIF.start?'start':(sif==SIF.finish?'finish':'intermediate'),
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

  bool get isOpen {
    var now = DateTime.now();
    return (open.isBefore(now) && close.isAfter(now));
  }

  get cLoc => ControlLocation(this);

  static  bool get isPrerideMode =>
      Settings.getValue<bool>('key-preride-mode', defaultValue: false)!;

  
  get isAvailable => isPrerideMode ||
        isOpen && cLoc.isNearControl; 

  get openTimeString  => open.toLocal().toString().substring(0,16) + open.toLocal().timeZoneName;
  get closeTimeString  => close.toLocal().toString().substring(0,16) + close.toLocal().timeZoneName;


  
}
