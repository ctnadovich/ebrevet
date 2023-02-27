import 'package:crypto/crypto.dart';
import 'dart:convert';

import 'event.dart';
import 'rider.dart';
import 'region.dart';

class Signature {
  Signature(
      {required this.event,
      required this.rider,
      required this.region,
      this.data,
      this.codeLength = 4});

  Event event;
  Rider rider;
  Region region;
  String? data;
  int codeLength;

  // Alphabetical by fixed field name, data in front, secret at end

  String get text {
    var plainString = [
      if (data != null) data,
      event
          .eventID, // regionID not needed because eventID is sufficient for world uniqueness, as "acp_club_code-pa_event"
      rider.rusaID,
      region.secret,
    ].join('-');
    var plaintext = utf8.encode(plainString);
    var ciphertext = sha256.convert(plaintext);
    var startCode =
        ciphertext.toString().substring(0, codeLength).toUpperCase();
    return startCode;
  }
}
