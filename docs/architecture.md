# Architecture

## Overview

eBrevet is a Flutter application that acts as an electronic brevet card. It
downloads scheduled events, lets a rider activate an event, enforces control
time and location rules, records check-ins, uploads results when connectivity
is available, and produces a finish certificate.

The Dart source currently has a flat layout under `lib/`. The main groups are:

- Domain objects: `Event`, `Control`, `ActivatedEvent`, `EventOutcomes`,
  `Checkin`, and `Region`.
- Persistence and services: `ScheduledEvents`, `MyActivatedEvents`,
  `FileStorage`, `Report`, `RiderLocation`, and `Signature`.
- UI: event lists and cards, control cards, check-in status views,
  certificates, settings, logs, and navigation.
- Application state: `Provider`/`ChangeNotifier` is used for theme, control
  state, and source selection. Several services also maintain static state.

## Startup

`main.dart` initializes Flutter bindings, shared preferences, package metadata,
the region list, scheduled events, and activated-event history. It then starts
the widget tree with providers for `DayNight`, `ControlState`, and
`SourceSelection`.

The initial page is `ScheduledEventsPage`, wrapped in `UpgradeAlert`.

## Event lifecycle

1. The rider selects a regional, international, or custom-URL event source.
2. `ScheduledEvents` downloads and validates event data, then caches it on
   disk.
3. A start code is validated before activation.
4. `MyActivatedEvents` creates and persists an `ActivatedEvent`, which combines
   an `Event` with rider identity, start style, and outcomes.
5. `ActivatedEvent` records control check-ins and computes ride status.
6. `Report` uploads signed state to the event server.
7. A completed event can display a signed finish certificate.

## State and persistence boundaries

Settings are stored through `SharedPreferences`. Regions, scheduled events,
and activated events are stored as JSON in the application documents
directory. These formats are effectively persistent interfaces and should be
changed with backward compatibility in mind.

Some behavior is derived from mutable global settings rather than stored on an
event. Event signing secrets are an important example; see
[Event signing](event-signing.md) and
[ADR 0001](decisions/0001-event-signing-secret-lifecycle.md).
