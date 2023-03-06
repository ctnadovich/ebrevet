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

import 'package:crypto/crypto.dart';
import 'dart:convert';

import 'event.dart';
// import 'rider.dart';
// import 'region.dart';

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

  String get text {
    var plainString = [
      if (data != null) data,
      event.eventID, // regionID not needed because eventID is sufficient for world uniqueness, as "acp_club_code-pa_event"
      riderID,
      event.secret,
    ].join('-');
    var plaintext = utf8.encode(plainString);
    var ciphertext = sha256.convert(plaintext);
    var startCode =
        ciphertext.toString().substring(0, codeLength).toUpperCase();
    return startCode;
  }
}
