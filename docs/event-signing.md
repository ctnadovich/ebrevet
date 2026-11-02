# Event Signing

## Purpose

eBrevet generates deterministic values that allow rider actions and results to
be checked against event and rider information:

- Start codes authorize activation of an event.
- Check-in phrases provide a paper-card backup for control check-ins.
- Finish codes identify the outcome and elapsed time on a certificate.
- Report signatures authenticate data uploaded to the event server.

## Current derivation

All four forms use `Signature.rawCipherText`, which hashes a string containing
form-specific data, the event ID, rider ID, and `event.region.secret`.

The form-specific data is currently:

- Start code: cue version.
- Check-in phrase: control index.
- Finish code: outcome description and elapsed time.
- Report signature: report timestamp.

The resulting digest is rendered differently for each purpose. Codes are
truncated hexadecimal text, check-in phrases map digest bytes to words, and
report signatures use a longer hexadecimal value.

## Current secret selection

`Event.region` constructs a new `Region` from the event's region ID whenever it
is accessed. The `Region` constructor chooses the secret using current
application settings:

- For a custom URL source with a nonempty custom secret, it uses the trimmed
  custom secret.
- Otherwise it uses the compiled secret for the event's region ID, or the
  compiled default secret.

The selected secret is not currently stored in `Event` or `ActivatedEvent`.
Consequently, changing the selected source or custom secret can change codes
for an already downloaded or activated event.

## Desired invariant

An event should use the same signing authority for its entire lifecycle. The
start code accepted before activation, later check-in phrases, uploaded report
signatures, and final certificate should not change because the user browsed a
different event source or edited settings.

The proposed approach is to snapshot signing information on the `Event` when
trusted event data enters the application. An `ActivatedEvent` already embeds
and persists its event, so this covers both pre-activation start-code checks and
post-activation signing. Storing the secret only on `ActivatedEvent` would not
cover start-code validation, which happens first.

See [ADR 0001](decisions/0001-event-signing-secret-lifecycle.md) for alternatives,
migration questions, and security implications.
