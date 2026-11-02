# ADR 0001: Event Signing Secret Lifecycle

Status: Proposed

## Context

Start codes, check-in phrases, finish codes, and report signatures all depend
on `event.region.secret`. `Event.region` creates a `Region` on demand, and the
`Region` constructor selects a secret from current application settings.

For regional sources, the secret is selected from compiled region data using
the event's region ID. For a custom URL source, a nonempty custom secret from
settings takes precedence. Neither `Event` nor `ActivatedEvent` records which
secret was selected when the event was downloaded or activated.

This means mutable settings can alter signing results for existing events. A
rider can download or activate an event, switch sources or edit the custom
secret, and then receive different check-in phrases, report signatures, or
finish codes. Restored activated-event history has the same dependency on
current settings.

## Required behavior

The signing identity of an event should remain stable throughout its lifecycle:

1. The start code is generated and validated with the event's signing secret.
2. The same secret generates every check-in phrase.
3. Uploaded reports use the same secret.
4. The finish certificate continues to verify later, even after settings have
   changed or the app has restarted.

## Options considered

### Continue deriving from current settings

This requires no data-format change but does not provide stable codes. It is
the current behavior and does not meet the requirement.

### Store the secret only in `ActivatedEvent`

This stabilizes check-in, report, and finish signing after activation. It does
not naturally cover start-code validation because validation occurs before the
`ActivatedEvent` exists. It also duplicates signing concerns between scheduled
and activated event paths.

### Store a signing-secret snapshot in `Event`

The secret is selected when trusted event data enters the application and is
stored with the event. Start-code validation and all later signatures then use
the same value. Because `ActivatedEvent` embeds its serialized event, the
snapshot follows the event into history.

This option best matches the lifecycle requirement and is the proposed design.

### Store a key identifier instead of the secret

An event could persist an immutable key ID and resolve the secret from a secure
key store. This avoids duplicating plaintext secret material in event JSON and
supports key rotation, but requires a key-distribution and retention design.
Old certificates and offline operation require old keys to remain available.
It is a stronger long-term model but a larger protocol change.

## Proposed decision

Add immutable signing information to `Event`, populated by the event-loading
boundary rather than by UI code. `Signature` should consume that event-owned
value and must not consult mutable source settings.

The field could initially be a `final String signingSecret`. A more explicit
model could include a key identifier and signing scheme version as well:

```text
signing_key_id
signing_scheme_version
signing_secret
```

The exact serialized names and whether a key ID is required remain open design
questions. No production secret should ever appear in logs.

## Migration questions

Existing `futureEvents.json` and `pastEvents.json` records will not contain the
new field. Before implementation, choose and test a fallback policy:

- Derive once using the legacy rules, assign the result to the in-memory event,
  and persist it on the next write.
- Require affected scheduled events to be refreshed while preserving a legacy
  fallback for activated history.
- Mark records without signing information as legacy and warn when their
  signing identity cannot be determined reliably.

Custom-URL events are the ambiguous case: if current settings no longer match
the original source, the original secret cannot be reconstructed. Silently
capturing the current custom secret may preserve the wrong identity. Migration
behavior should favor an explicit warning over creating plausible but invalid
codes.

## Security model impact

The application already contains compiled regional secrets, and the custom
secret is already stored in application preferences. These are shared signing
secrets distributed to client devices, not hardware-protected private keys.
They should therefore be treated as a compatibility and tamper-resistance
mechanism rather than as protection against a determined user controlling a
device or application binary.

Persisting a secret in event JSON increases the number of plaintext copies and
makes event backups self-contained. On a compromised or user-controlled device,
however, the current compiled or preference-backed secrets are already
recoverable. The practical incremental exposure may be limited, but it should
still be minimized:

- Never log a full secret. Existing diagnostic logging that includes a secret
  should be removed or masked.
- Do not include secrets in screenshots, exported logs, documentation, crash
  reports, or test fixtures.
- Apply normal platform data protection to application files.
- Consider persisting a key ID and using platform secure storage if the server
  protocol evolves to support key lookup and rotation.
- Version the signing scheme so future changes can coexist with old events.

The strongest design would avoid distributing a shared signing secret to the
client and instead use asymmetric signatures or server-issued event/rider
tokens. That would require coordinated server and application changes and may
conflict with offline operation, so it is outside this incremental decision.

## Consequences

- Codes remain stable when users change event-source settings.
- Scheduled and activated event JSON gain a compatibility-sensitive field.
- Migration behavior must be defined for existing records.
- Secret rotation becomes an event/versioning concern rather than an immediate
  global setting change.
- Tests need fixed fake signing vectors and source-switching coverage.
