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
// import 'package:ebrevet_card/exception.dart';
// import 'package:ebrevet_card/mylogger.dart';
import 'dart:convert';
import 'dart:typed_data';

import 'event.dart';
import 'activated_event.dart';
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

  factory Signature.forCert(ActivatedEvent pastEvent) => Signature(
      event: pastEvent.event,
      riderID: pastEvent.riderID,
      data:
          "${pastEvent.outcomes.overallOutcome.description}:${pastEvent.elapsedTimeStringhhmm}",
      codeLength: 4);

  // Start Code

  factory Signature.startCode(Event event, String riderID, {int? cueVersion}) =>
      Signature(
          data: cueVersion?.toString() ?? event.cueVersion.toString(),
          event: event,
          riderID: riderID,
          codeLength: 4);

  // Check in code

  factory Signature.checkInCode(ActivatedEvent pe, Control ctrl) {
    var checkInTime = pe.controlCheckInTime(ctrl);
    var checkInData = "Never";

    if (checkInTime != null) {
      // If the checkInTime is incorporated into the checkInCode,
      // then riders must record the time as well as the code.
      // And checking the code requires the time (which must be
      // manually entered since we assume there was no upload).
      // This has some security advantage, "proving" the recorded
      // time, but the app has already enforced the control closing
      // time and arrival in-time at the control is implied by
      // the issuance of the code. Final analysis is that
      // incorporating time into the code is more trouble than
      // it's worth.

      // var checkInDay = checkInTime.toUtc().day;
      // var checkInHour = checkInTime.toUtc().hour;
      // var checkInMinute = checkInTime.toUtc().minute;

      // var checkInTimeString =
      //     checkInTime?.toUtc().toString().substring(0, 16) ?? "Never";
      checkInData = ctrl.index.toString();
      // [
      // ctrl.index.toString(),
      // checkInDay,
      // checkInHour,
      // checkInMinute
      // ].join('-');
    }

    return Signature(
        data: checkInData, event: pe.event, riderID: pe.riderID, codeLength: 4);
  }

  // Report

  factory Signature.forReport(
          ActivatedEvent reportingEvent, String timestamp) =>
      Signature(
          riderID: reportingEvent.riderID, // non null by assertion above
          event: reportingEvent.event,
          data: timestamp,
          codeLength: 8);

  // Generic code

  Digest get rawCipherText {
    var plainString = [
      if (data != null) data,
      event
          .eventID, // regionID not needed because eventID is sufficient for world uniqueness, as "acp_club_code-pa_event"
      riderID,
      event.region.secret,
    ].join('-');
    var plaintext = utf8.encode(plainString);
    return sha256.convert(plaintext);
  }

  String get cipherText {
    // var plainString = [
    //   if (data != null) data,
    //   event
    //       .eventID, // regionID not needed because eventID is sufficient for world uniqueness, as "acp_club_code-pa_event"
    //   riderID,
    //   event.region.secret,
    // ].join('-');
    // var plaintext = utf8.encode(plainString);
    var ciphertext = rawCipherText;
    var startCode =
        ciphertext.toString().substring(0, codeLength).toUpperCase();

    // MyLogger.entry(
    //     "Generated Start Code. Plaintext: $plainString; Code: $startCode");
    return startCode;
  }

  String get plainText {
    var plainString = [
      if (data != null) data,
      event
          .eventID, // regionID not needed because eventID is sufficient for world uniqueness, as "acp_club_code-pa_event"
      riderID,
      // event.region.secret,
    ].join('-');

    return plainString;
  }

  String get xyText => Signature.substituteZeroOneXY(cipherText);

  static String substituteZeroOneXY(String s) {
    return s.replaceAll('0', 'X').replaceAll('1', 'Y');
  }

  static String substituteXYZeroOne(String s) {
    return s.replaceAll('X', '0').replaceAll('Y', '1');
  }

  static const List<String> adjectives = [
    'able',
    'absurd',
    'active',
    'afraid',
    'agreeable',
    'alert',
    'alive',
    'amused',
    'angry',
    'annoyed',
    'anxious',
    'arrogant',
    'ashamed',
    'attractive',
    'average',
    'awful',
    'bad',
    'beautiful',
    'better',
    'bewildered',
    'black',
    'bloody',
    'blue',
    'blue-eyed',
    'blushing',
    'bored',
    'brainy',
    'brave',
    'breakable',
    'bright',
    'busy',
    'calm',
    'careful',
    'cautious',
    'charming',
    'cheerful',
    'clean',
    'clear',
    'clever',
    'cloudy',
    'clumsy',
    'colorful',
    'combative',
    'comfortable',
    'concerned',
    'condemned',
    'confused',
    'cooperative',
    'courageous',
    'crazy',
    'creepy',
    'crowded',
    'cruel',
    'curious',
    'cute',
    'dangerous',
    'dark',
    'dead',
    'defeated',
    'defiant',
    'delightful',
    'depressed',
    'determined',
    'different',
    'difficult',
    'disgusted',
    'distinct',
    'disturbed',
    'dizzy',
    'doubtful',
    'drab',
    'dull',
    'eager',
    'easy',
    'elated',
    'elegant',
    'embarrassed',
    'enchanting',
    'encouraging',
    'energetic',
    'enthusiastic',
    'envious',
    'evil',
    'excited',
    'expensive',
    'exuberant',
    'fair',
    'faithful',
    'famous',
    'fancy',
    'fantastic',
    'fierce',
    'filthy',
    'fine',
    'foolish',
    'fragile',
    'frail',
    'frantic',
    'friendly',
    'frightened',
    'funny',
    'gentle',
    'gifted',
    'glamorous',
    'gleaming',
    'glorious',
    'good',
    'gorgeous',
    'graceful',
    'grieving',
    'grotesque',
    'grumpy',
    'handsome',
    'happy',
    'healthy',
    'helpful',
    'helpless',
    'hilarious',
    'homeless',
    'homely',
    'horrible',
    'hungry',
    'hurt',
    'ill',
    'important',
    'impossible',
    'inexpensive',
    'innocent',
    'inquisitive',
    'itchy',
    'jealous',
    'jittery',
    'jolly',
    'joyous',
    'juicy',
    'kind',
    'lackadaisical',
    'large',
    'lazy',
    'light',
    'lively',
    'lonely',
    'long',
    'lovely',
    'lucky',
    'magnificent',
    'misty',
    'modern',
    'motionless',
    'muddy',
    'mushy',
    'mysterious',
    'nasty',
    'naughty',
    'nervous',
    'nice',
    'nutty',
    'obedient',
    'obnoxious',
    'odd',
    'old-fashioned',
    'open',
    'outrageous',
    'outstanding',
    'panicky',
    'perfect',
    'plain',
    'pleasant',
    'poised',
    'poor',
    'powerful',
    'precious',
    'prickly',
    'proud',
    'puzzled',
    'quaint',
    'quizzical',
    'rambunctious',
    'real',
    'relieved',
    'repulsive',
    'rich',
    'scary',
    'selfish',
    'shiny',
    'shy',
    'silly',
    'sleepy',
    'smiling',
    'smoggy',
    'sore',
    'sparkling',
    'splendid',
    'spotless',
    'stormy',
    'strange',
    'stupid',
    'successful',
    'super',
    'talented',
    'tame',
    'tender',
    'tense',
    'terrible',
    'testy',
    'thankful',
    'thoughtful',
    'thoughtless',
    'tired',
    'tough',
    'troubled',
    'ugliest',
    'ugly',
    'uninterested',
    'unsightly',
    'unusual',
    'upset',
    'uptight',
    'vast',
    'victorious',
    'vivacious',
    'wandering',
    'weary',
    'wicked',
    'wide-eyed',
    'wild',
    'witty',
    'worrisome',
    'worried',
    'wrong',
    'zany',
    'zealous'
  ];

  static const List<String> nouns = [
    'apple', 'banana', 'cherry', 'dog', 'elephant', 'fish', 'grape', 'horse',
    'ice cream', 'jazz',
    'kangaroo', 'lemon', 'mango', 'noodle', 'orange', 'pear', 'quilt', 'rabbit',
    'sunset', 'turtle',
    'umbrella', 'violin', 'watermelon', 'xylophone', 'yellow', 'zebra',
    'airplane', 'ball', 'car', 'desk',
    'egg', 'flower', 'guitar', 'hat', 'island', 'jacket', 'kite', 'lamp',
    'moon', 'notebook',
    'ocean', 'piano', 'queen', 'rose', 'ship', 'train', 'umbrella', 'volcano',
    'wallet', 'xylophone',
    'yacht', 'zeppelin', 'apple', 'banana', 'cherry', 'dog', 'elephant', 'fish',
    'grape', 'horse', 'ice cream',
    'jazz', 'kangaroo', 'lemon', 'mango', 'noodle', 'orange', 'pear', 'quilt',
    'rabbit', 'sunset',
    'turtle', 'umbrella', 'violin', 'watermelon', 'xylophone', 'yellow',
    'zebra', 'airplane', 'ball', 'car',
    'desk', 'egg', 'flower', 'guitar', 'hat', 'island', 'jacket', 'kite',
    'lamp', 'moon',
    'notebook', 'ocean', 'piano', 'queen', 'rose', 'ship', 'train', 'umbrella',
    'volcano', 'wallet',
    'xylophone', 'yacht', 'zeppelin', 'apple', 'banana', 'cherry', 'dog',
    'elephant', 'fish', 'grape',
    'horse', 'ice cream', 'jazz', 'kangaroo', 'lemon', 'mango', 'noodle',
    'orange', 'pear', 'quilt',
    'rabbit', 'sunset', 'turtle', 'umbrella', 'violin', 'watermelon',
    'xylophone', 'yellow', 'zebra',
    'airplane', 'ball', 'car', 'desk', 'egg', 'flower', 'guitar', 'hat',
    'island', 'jacket',
    'kite', 'lamp', 'moon', 'notebook', 'ocean', 'piano', 'queen', 'rose',
    'ship', 'train',
    'umbrella', 'volcano', 'wallet', 'xylophone', 'yacht', 'zeppelin', 'apple',
    'banana', 'cherry', 'dog',
    'elephant', 'fish', 'grape', 'horse', 'ice cream', 'jazz', 'kangaroo',
    'lemon', 'mango', 'noodle',
    'orange', 'pear', 'quilt', 'rabbit', 'sunset', 'turtle', 'umbrella',
    'violin', 'watermelon', 'xylophone',
    'yellow', 'zebra', 'airplane', 'ball', 'car', 'desk', 'egg', 'flower',
    'guitar', 'hat', 'island',
    'jacket', 'kite', 'lamp', 'moon', 'notebook', 'ocean', 'piano', 'queen',
    'rose', 'ship',
    'train', 'umbrella', 'volcano', 'wallet', 'xylophone', 'yacht', 'zeppelin',
    'apple', 'banana', 'cherry',
    'dog', 'elephant', 'fish', 'grape', 'horse', 'ice cream', 'jazz',
    'kangaroo', 'lemon', 'mango',
    'noodle', 'orange', 'pear', 'quilt', 'rabbit', 'sunset', 'turtle',
    'umbrella', 'violin', 'watermelon',
    'xylophone', 'yellow', 'zebra', 'airplane', 'ball', 'car', 'desk', 'egg',
    'flower', 'guitar',
    'hat', 'island', 'jacket', 'kite', 'lamp', 'moon', 'notebook', 'ocean',
    'piano', 'queen',
    'rose', 'ship', 'train', 'umbrella', 'volcano', 'wallet', 'xylophone',
    'yacht', 'zeppelin'
    // Add more nouns as needed
  ];

  String get wordText {
    var ciphertext = rawCipherText;
    var firstEight = ciphertext.bytes.sublist(0, 8);
    var uint8List = Uint8List.fromList(firstEight);
    var byteData = uint8List.buffer.asByteData();
    int cipherInt = byteData.getUint32(0, Endian.big);
    int nounIndex = cipherInt % nouns.length;
    int adjIndex = (cipherInt ~/ nouns.length) % adjectives.length;

    return "${adjectives[adjIndex]} ${nouns[nounIndex]}";
  }
}
