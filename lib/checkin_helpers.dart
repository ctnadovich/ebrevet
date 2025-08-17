import 'utility.dart';
import 'control.dart';

String? convertToLocalTime(String? isoString) {
  if (isoString == null) return null;
  try {
    final dt = DateTime.parse(isoString).toLocal();
    return Utility.toBriefDateTimeString(dt);
  } catch (e) {
    return null;
  }
}

List<Map<String, dynamic>> extractComments(List<dynamic>? checklist) {
  if (checklist == null) return [];

  final comments = <Map<String, dynamic>>[];

  for (int i = 0; i < checklist.length; i++) {
    final entry = checklist[i];
    if (entry != null) {
      final comment = entry['comment'];
      if (comment != null) {
        final text = comment.toString().trim();
        if (text.isNotEmpty && !text.contains("Automatic Check In")) {
          comments.add({
            'index': i,
            'comment': text,
          });
        }
      }
    }
  }

  return comments;
}

Map<String, dynamic>? getLastCheckin(List<dynamic>? checklist) {
  if (checklist == null || checklist.isEmpty) return null;

  for (int i = checklist.length - 1; i >= 0; i--) {
    final item = checklist[i] as Map<String, dynamic>?;
    if (item != null) {
      item['index'] = i + 1;
      return item;
    }
  }

  return null;
}

String formatCheckinWithControlTimes(
    Map<String, dynamic> checkin, Control control) {
  final checkinRaw = checkin['checkin_datetime']?.toString();
  if (checkinRaw == null || checkinRaw.isEmpty) return "No check-in";

  final controlNum = control.index + 1;

  final checkinDT = DateTime.parse(checkinRaw).toLocal();
  //final openDT = control.open.toLocal();
  //final closeDT = control.close.toLocal();

  //final openTime = Utility.toBriefTimeString(openDT);
  //final closeTime = Utility.toBriefTimeString(closeDT);
  final checkinTime = Utility.toBriefDateTimeString(checkinDT);

  // Use the existing booleans
  final isEarly = checkin['is_earlyq'] == true;
  final isLate = checkin['is_lateq'] == true;

  final warning = (isEarly || isLate) ? ' ⚠️' : '';

  return "Control $controlNum: $checkinTime $warning";
}
