# Testing

## Current state

Static analysis currently completes without findings. The existing
`test/widget_test.dart` is the generated Flutter counter test and does not
exercise the eBrevet application, so meaningful automated coverage remains to
be added.

## Suggested test layers

### Unit tests

- Event and control JSON parsing and serialization.
- Event filtering and time-window calculations.
- Activation and outcome transitions.
- Skipped, early, late, and automatic check-in behavior.
- Signature stability for fixed event, rider, secret, and input data.
- Settings serialization and fallback behavior.

### Persistence tests

- Reading existing scheduled-event and activated-event JSON.
- Round trips for current models.
- Missing-field behavior for data written by older versions.
- Migration behavior if signing information is added to `Event`.

### Widget tests

- Scheduled event list states.
- Start-code validation and activation flow.
- Control availability and check-in dialogs.
- Finish certificate rendering.
- Settings for regional and custom event sources.

### Integration tests

- Download, cache, restore, activate, check in, upload, and finish flow.
- Offline check-in followed by later upload.
- Switching event sources without changing the signing identity of an existing
  event.

Use only fake secrets and synthetic rider/event information. Signature tests
should use fixed, nonproduction vectors so accidental behavior changes are
visible.
