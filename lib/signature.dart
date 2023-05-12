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

import 'package:crypto/crypto.dart';
// import 'package:ebrevet_card/mylogger.dart';
import 'dart:convert';

import 'event.dart';
import 'past_event.dart';
import 'control.dart';

class Signature {
  Signature(
      {required this.event,
      required this.riderID,
      this.data,
      this.codeLength = 4});

  Event event;
  String riderID;
  String? data;
  int codeLength;

  // Alphabetical by fixed field name, data in front, secret at end

  // Finish Certificates

  factory Signature.forCert(PastEvent pastEvent) => Signature(
      event: pastEvent.event,
      riderID: pastEvent.riderID,
      data:
          "${pastEvent.outcomes.overallOutcome.description}:${pastEvent.elapsedTimeStringhhmm}",
      codeLength: 4);

  // Start Code

  factory Signature.startCode(Event event, String riderID) => Signature(
      data: event.cueVersion.toString(),
      event: event,
      riderID: riderID,
      codeLength: 4);

  // Check in code

  factory Signature.checkInCode(PastEvent pe, Control ctrl) {
    var checkInTime = pe.controlCheckInTime(ctrl);
    var riderID = pe.riderID;
    var checkInTimeString =
        checkInTime?.toUtc().toString().substring(0, 16) ?? "Never";
    var checkInData = "C${ctrl.index} $checkInTimeString";
    return Signature(
        data: checkInData, event: pe.event, riderID: riderID, codeLength: 4);
  }

  // Report

  factory Signature.forReport(PastEvent reportingEvent, String timestamp) =>
      Signature(
          riderID: reportingEvent.riderID, // non null by assertion above
          event: reportingEvent.event,
          data: timestamp,
          codeLength: 8);

  // Generic code

  String get cipherText {
    var plainString = [
      if (data != null) data,
      event
          .eventID, // regionID not needed because eventID is sufficient for world uniqueness, as "acp_club_code-pa_event"
      riderID,
      event.region.secret,
    ].join('-');
    var plaintext = utf8.encode(plainString);
    var ciphertext = sha256.convert(plaintext);
    var startCode =
        ciphertext.toString().substring(0, codeLength).toUpperCase();

    // MyLogger.entry(
    //     "Generated Start Code. Plaintext: $plainString; Code: $startCode");
    return startCode;
  }

  String get xyText => Signature.substituteZeroOneXY(cipherText);

  static String substituteZeroOneXY(String s) {
    return s.replaceAll('0', 'X').replaceAll('1', 'Y');
  }

  static String substituteXYZeroOne(String s) {
    return s.replaceAll('X', '0').replaceAll('Y', '1');
  }
}
