# Control Timing Rules

## Overview

Controls can be treated as timed or untimed. Timing affects how the app
describes a control, determines whether it is open, and detects late check-ins.
The central policy is implemented by `Event.isUntimedControl`.

## Start and finish override

The first and last controls of an event are always timed. Their position takes
precedence over both control style and the explicit `timed` field.

Consequently, a start or finish remains timed when:

- Its style is `photo`, `info`, or `postcard`.
- Event data specifies `timed=no`.
- The event has a nonzero gravel distance.

This override reflects the requirement that the event's start and completion
remain subject to their applicable time windows. Event data cannot accidentally
make either terminal control untimed.

## Intermediate controls

Existing untimed behavior is retained for controls between the start and
finish. An intermediate control is untimed when any of these conditions is
true:

- Its style is `photo`, `info`, or `postcard`.
- The event has a nonzero gravel distance.
- The control explicitly specifies `timed=no`.

Otherwise, the intermediate control is timed.

The precedence can be summarized as:

```text
start or finish                    -> timed
intermediate + untimed style       -> untimed
intermediate + gravel event        -> untimed
intermediate + timed=no            -> untimed
all other intermediate controls    -> timed
```

## Effects in the application

Callers use `Event.isUntimedControl` as the single policy point. The result
affects:

- Control-card status and open/close labels.
- Open-time enforcement in `ActivatedEvent.isControlOpen`.
- Late-check-in detection in `ActivatedEvent.checkedInLate`.

Start activation also has start-style-specific rules in `Event.isStartable`.
Those rules remain separate from control timing and cover mass starts, free
starts, pre-rides, and permanents.

## Regression coverage

`test/event_test.dart` verifies that:

- Photo, info, and postcard starts and finishes remain timed.
- `timed=no` cannot make a start or finish untimed.
- Untimed style and `timed=no` behavior remains unchanged for intermediate
  controls.

Future changes to timing policy should update the centralized predicate, these
tests, and this document together.
