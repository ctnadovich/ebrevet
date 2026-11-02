# Data Formats and Persistence

## Persistent settings

`MySetting<T>` stores application settings in `SharedPreferences`. Values are
serialized as strings, including enum indexes. Changes to enum ordering or
value parsing can therefore affect existing installations.

Settings include rider identity, selected event source, region, custom event
URL and secret, GPS behavior, display preferences, and developer overrides.

## Region data

The region list is cached in `regions.json`. Public region metadata can be
refreshed from the fixed region-list endpoint. Compiled `RegionData` supplies
the default secret and per-region secrets; those values are not obtained from
the public region-list update.

## Scheduled events

`ScheduledEvents` caches downloaded event data in `futureEvents.json`. The
stored wrapper includes the selected source and last-refresh timestamp along
with event data. Incoming data is converted to `Event` and `Control` objects.

The source record identifies the source type but does not currently snapshot
the signing secret. Event objects likewise do not persist a secret.

## Activated events

`MyActivatedEvents` stores activated-event history in `pastEvents.json`, keyed
by event ID. Each entry includes its serialized `Event`, rider ID, start style,
and `EventOutcomes`, including control check-in state and upload state.

Because the embedded event does not currently include signing information,
restoring history still derives the secret from current settings.

## Compatibility guidance

Persistent JSON readers should tolerate missing fields when a new optional
field is introduced. If an event-level signing field is added, old records need
an explicit fallback policy. Possible policies are documented in
[ADR 0001](decisions/0001-event-signing-secret-lifecycle.md).

Never place real secrets or rider information in documentation fixtures. Use
clearly fake values in examples.
