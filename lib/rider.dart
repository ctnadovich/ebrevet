import 'package:flutter_settings_screens/flutter_settings_screens.dart';

class Rider {
  static const int maxRUSAID = 99999;

  static bool isValidRusaID(String? value) {
    if (value == null) return false;
    final rusaid = num.tryParse(value);
    if (rusaid == null ||
        rusaid is! int ||
        rusaid < 1 ||
        rusaid > Rider.maxRUSAID) {
      return false;
    }
    return true;
  }

  final String firstName;
  final String lastName;
  final String rusaID; // Should this be int? Or, like event ID, does it need to
  // be string for extensibility?

  Rider(this.firstName, this.lastName, this.rusaID);

  static get isSet {
    var fn = Settings.getValue<String>('key-first-name');
    var ln = Settings.getValue<String>('key-last-name');
    var id = Settings.getValue<String>('key-rusa-id');

    return (fn == null ||
            fn.isEmpty ||
            ln == null ||
            ln.isEmpty ||
            id == null ||
            id.isEmpty ||
            !isValidRusaID(id))
        ? false
        : true;
  }

  Rider.fromSettings()
      : this(
          Settings.getValue<String>('key-first-name', defaultValue: 'Unknown')!,
          Settings.getValue<String>('key-last-name', defaultValue: '')!,
          Settings.getValue<String>('key-rusa-id', defaultValue: 'Not Set')!,
        );

  String get firstLast {
    return "$firstName $lastName";
  }

  String get firstLastRUSA {
    return "$firstName $lastName (RUSA# $rusaID)";
  }
}
