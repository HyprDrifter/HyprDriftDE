# HyprDriftDE Update Log

## 2026-07-18 — Quickshell v0.3 networking, Bluetooth, and shell update

This update modernizes QuickDrift Shell for the Quickshell v0.3 API and adds
native network and Bluetooth management. It also removes several script-driven
and dispatcher-driven paths in favor of reactive QML services.

### Quickshell v0.3 compatibility

- Updated shell execution paths for Quickshell v0.3 instead of relying on
  `Hyprland.dispatch("exec …")`.
- Detached commands now use Quickshell argument arrays, while commands that
  intentionally accept shell syntax are explicitly passed through
  `bash -lc`.
- Application launching now uses Quickshell's native desktop-entry model and
  `DesktopEntry.execute()`.
- Audio playback uses `Quickshell.execDetached(["paplay", file])`.
- Power-menu, clipboard, icon-resolution, and minimize operations use safer,
  separated process arguments and validated input.

### Networking

- Added a native network controller backed by `Quickshell.Networking`; no
  `nmcli`, helper scripts, or polling loops are used.
- Added a reactive taskbar icon for wired, Wi-Fi, connecting, disconnected,
  and unavailable states.
- Added an animated, anchored network flyout using the active semantic Base16
  colors from `Settings.qml`.
- Added wired-interface status, link details, and enable/disable controls.
- Added Wi-Fi adapter detection and automatic Wi-Fi power synchronization when
  adapters are added or removed.
- Added automatic and manual Wi-Fi discovery with a five-second scan window.
- Added available-network sorting with saved networks first, signal strength,
  security type, and compact status icons.
- Added password entry and validation for secured networks, connection status,
  disconnect controls, and forgetting saved networks.
- Preserved discovered entries across scan completion so unsaved networks do
  not disappear when active discovery stops.
- Added focus, Escape, outside-click, and pointer-leave dismissal behavior.
- Added animated opening, closing, resizing, and anchor-position changes to
  avoid geometry popping as network data updates.

### Bluetooth

- Added a native Bluetooth controller backed by `Quickshell.Bluetooth`; no
  `bluetoothctl`, helper scripts, or polling loops are used.
- Added reactive adapter hot-plug handling and taskbar states for connected,
  scanning, enabled, transitioning, blocked, disabled, and unavailable states.
- Added an animated, anchored Bluetooth flyout using the active semantic
  Base16 colors from `Settings.qml`.
- Added discovery across enabled adapters with owned-scan tracking, manual
  cancellation, timeout handling, and protection for discovery started by
  other applications.
- Added serialized pairing, pairing cancellation, automatic trust and connect
  after pairing, and retryable timeout errors.
- Added connect, disconnect, confirmed unpair/forget, adapter identification,
  and battery reporting when BlueZ provides it.
- Added connected-first paired-device ordering and separate available-device
  results.
- Added focus, Escape, outside-click, and pointer-leave dismissal behavior,
  plus animated opening, closing, resizing, and positioning.
- Authenticated PIN or numeric-confirmation pairing still requires an external
  BlueZ agent because Quickshell v0.3 does not expose an Agent1/passkey API.

### Application launcher and process safety

- Replaced generated `apps.json` files and the recurring application-list
  script with `DesktopEntries.applications`.
- Added native desktop-entry execution and exact trimmed command execution for
  unmatched launcher input.
- Removed obsolete generated application artifacts and `Get-Apps.sh`.
- Reworked clipboard restoration to validate cliphist IDs and pass them as
  positional process arguments.
- Reworked icon lookup to avoid interpolated shell pipelines and filter
  candidate paths in QML.
- Corrected power-menu argument handling and removed obsolete dispatcher
  examples.

### Performance monitoring

- Replaced CPU, RAM, and GPU polling scripts with the shared `SystemMetrics`
  singleton.
- CPU and RAM readings now come directly from `/proc`; supported GPU readings
  use sysfs with an NVIDIA monitor fallback.
- Metrics continue updating every 250 ms without overlapping script launches
  and retain their last valid readings through transient failures.
- Removed the old CPU, RAM, and GPU helper scripts and hardcoded
  `/etc/hyprdrift` metric paths.

### Minimize and preview handling

- Added validated, serialized minimize operations and safe preview paths.
- Preview capture is best-effort, while window movement and model updates are
  ordered so failed operations do not create false minimized entries.
- Restore handling now retains failed entries and removes successful entries
  and generated previews from the manager.
- Added overlap protection, address and geometry validation, preview-directory
  permission handling, and safe stale-preview cleanup.
- Removed the unused `AltTab.qml` implementation containing obsolete process
  handlers.

### Installation and service updates

- The installer now executes user-service operations in the target user's
  systemd session instead of the root session.
- Installation overwrites both supported system-wide user-unit locations so a
  stale `/etc/systemd/user/quickdrift.service` cannot shadow the updated unit.
- The installer reloads the user systemd manager and enables and restarts the
  QuickDrift service after copying the updated shell.

### User-interface polish

- Network and Bluetooth flyouts center on their taskbar buttons while
  respecting horizontal and vertical taskbar placement.
- Flyouts stay clear of the taskbar edge, close consistently when interaction
  leaves them, and no longer show taskbar hover tooltips.
- Network entries and wired details use a denser layout with saved and
  connection states represented by compact icons.
- Network and Bluetooth colors are sourced directly from the existing semantic
  Base16 roles in `Settings.qml` and update with the selected imported theme.
