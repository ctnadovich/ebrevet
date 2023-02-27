class TimeTill {
  late Duration d;
  late int days;
  late int hours;
  late int minutes;
  late int seconds;
  late String unit;
  late String interval;
  late String inn;
  late String ed;
  late String ago;
  late String s;

  TimeTill(DateTime t) {
    d = t.difference(DateTime.now());
    var dAbs = d.abs();
    days = dAbs.inDays;
    hours = dAbs.inHours;
    minutes = dAbs.inMinutes;
    seconds = dAbs.inSeconds;

    if (days > 0) {
      interval = days.toString();
      unit = 'day';
      s = (days == 1) ? '' : 's';
    } else if (hours > 0) {
      interval = myToStringAsFixed(minutes / 60.0);
      unit = 'hour';
      if (interval == '1' || interval == '1.0') {
        s = '';
        interval = '1';
      } else {
        s = 's';
      }
    } else if (minutes >= 1) {
      interval = myToStringAsFixed(seconds / 60.0);
      unit = 'minute';
      if (interval == '1' || interval == '1.0') {
        s = '';
        interval = '1';
      } else {
        s = 's';
      }
    } else {
      interval = 'less than 1 minute';
      s = '';
      unit = '';
    }

    unit = unit + s;

    inn = (d.inMicroseconds >= 0) ? 'in ' : '';
    ed = (d.inMicroseconds >= 0) ? 's' : 'ed';
    ago = (d.inMicroseconds >= 0) ? '' : ' ago';
  }

  myToStringAsFixed(
    double d, {
    int n = 1,
  }) {
    return (d.toStringAsFixed(2).endsWith('.000000000000'.substring(0, n)))
        ? d.toStringAsFixed(n)
        : d.toStringAsFixed(n);
  }
}
