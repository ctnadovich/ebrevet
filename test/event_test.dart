import 'package:ebrevet_card/event.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _control({
  required String name,
  required String style,
  String timed = 'yes',
}) {
  return {
    'dist_mi': 0,
    'long': 0,
    'lat': 0,
    'name': name,
    'style': style,
    'address': '',
    'open': '2026-01-01T00:00:00Z',
    'close': '2026-01-01T01:00:00Z',
    'timed': timed,
  };
}

Event _eventWithControls(List<Map<String, dynamic>> controls) {
  return Event.fromJson({
    'name': 'Test Event',
    'start_datetime_utc': '2026-01-01T00:00:00Z',
    'distance': 200,
    'gravel_distance': 0,
    'start_city': 'Test City',
    'start_state': 'TS',
    'cue_version': 1,
    'event_id': 'test-event',
    'club_acp_code': '000000',
    'checkin_post_url': 'https://example.invalid/checkin',
    'controls': controls,
  });
}

void main() {
  group('Event.isUntimedControl', () {
    test('start is timed even when its style normally implies untimed', () {
      for (final style in ['photo', 'info', 'postcard']) {
        final event = _eventWithControls([
          _control(name: 'Start', style: style),
          _control(name: 'Finish', style: 'staffed'),
        ]);

        expect(
          event.isUntimedControl(event.controls.first),
          isFalse,
          reason: '$style start controls must be timed',
        );
      }
    });

    test('start is timed even when explicitly marked timed=no', () {
      final event = _eventWithControls([
        _control(name: 'Start', style: 'staffed', timed: 'no'),
        _control(name: 'Finish', style: 'staffed'),
      ]);

      expect(event.isUntimedControl(event.controls.first), isFalse);
    });

    test('finish is timed even when its style normally implies untimed', () {
      for (final style in ['photo', 'info', 'postcard']) {
        final event = _eventWithControls([
          _control(name: 'Start', style: 'staffed'),
          _control(name: 'Finish', style: style),
        ]);

        expect(
          event.isUntimedControl(event.controls.last),
          isFalse,
          reason: '$style finish controls must be timed',
        );
      }
    });

    test('finish is timed even when explicitly marked timed=no', () {
      final event = _eventWithControls([
        _control(name: 'Start', style: 'staffed'),
        _control(name: 'Finish', style: 'staffed', timed: 'no'),
      ]);

      expect(event.isUntimedControl(event.controls.last), isFalse);
    });

    test('intermediate untimed behavior is unchanged', () {
      final event = _eventWithControls([
        _control(name: 'Start', style: 'staffed'),
        _control(name: 'Photo', style: 'photo'),
        _control(name: 'Explicitly untimed', style: 'staffed', timed: 'no'),
        _control(name: 'Finish', style: 'staffed'),
      ]);

      expect(event.isUntimedControl(event.controls[1]), isTrue);
      expect(event.isUntimedControl(event.controls[2]), isTrue);
    });
  });
}
