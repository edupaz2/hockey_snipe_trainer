# Hockey Snipe Trainer

A production-ready Flutter app for hockey training with BLE-enabled light-up targets. This app clones the core functionality of SnipeLights - an interactive hockey training system with 4 BLE-enabled targets placed in a hockey goal.

## Features

- **BLE Integration**: Connect up to 4 Snipe targets via Bluetooth Low Energy
- **12 Game Modes**: Various training modes including Random Snipe, Time to 10, Reaction Time, Marksman, Color Hunt, Rapid Fire, and more
- **Modern UI**: Dark mode hockey theme with neon glow effects and smooth animations
- **Statistics Tracking**: High scores per mode, total shots, accuracy, best reaction times
- **Simulation Mode**: Test the app without physical targets
- **Cross-Platform**: Runs on both Android and iOS

## Project Structure

```
lib/
├── main.dart                 # App entry point
├── app.dart                  # MaterialApp configuration
├── core/
│   ├── constants/
│   │   ├── app_colors.dart   # Color palette
│   │   ├── app_theme.dart    # Theme configuration
│   │   └── ble_constants.dart # BLE UUIDs and commands
│   └── utils/
│       └── permissions_handler.dart
├── models/
│   ├── target_device.dart    # BLE device model
│   ├── game_mode.dart        # Game mode definitions
│   ├── game_state.dart       # Game session state
│   └── player_stats.dart     # Statistics models
├── services/
│   ├── ble_service.dart      # BLE connection manager
│   ├── audio_service.dart    # Sound effects
│   └── storage_service.dart  # Hive persistence
├── controllers/
│   └── game_controller.dart  # Game logic
├── screens/
│   ├── splash_screen.dart
│   ├── home_screen.dart
│   ├── device_scan_screen.dart
│   ├── game_selection_screen.dart
│   ├── game_screen.dart
│   ├── stats_screen.dart
│   └── settings_screen.dart
└── widgets/
    ├── neon_button.dart
    ├── device_tile.dart
    ├── target_grid.dart
    ├── score_display.dart
    └── ...
```

## Getting Started

### Prerequisites

- Flutter 3.x or higher
- Android Studio / Xcode for running on devices
- Physical Snipe targets (or use Simulation Mode)

### Installation

1. **Clone and navigate to the project**:
   ```bash
   cd hockey_snipe_trainer
   ```

2. **Install dependencies**:
   ```bash
   flutter pub get
   ```

3. **Add sound assets** (optional):
   Place audio files in `assets/sounds/`:
   - `hit.mp3` - Puck hit sound
   - `miss.mp3` - Miss sound
   - `countdown.mp3` - Countdown beep
   - `game_start.mp3` - Game start
   - `game_end.mp3` - Game end
   - `click.mp3` - Button click
   - `target_on.mp3` - Target activation
   - `streak.mp3` - Combo streak
   - `high_score.mp3` - New high score
   - `error.mp3` - Error sound

4. **Run the app**:
   ```bash
   flutter run
   ```

### Testing Without Physical Targets

The app includes a **Simulation Mode** for testing:

1. On the Home screen, tap "Try Simulation Mode"
2. This creates 4 mock targets and opens the game selection
3. During gameplay, tap the targets on screen to simulate hits

Or use BLE simulators like **nRF Connect** or **LightBlue** to emulate Snipe targets.

## Customizing the BLE Protocol

The app is designed to be easily adapted to your specific Snipe target BLE protocol.

### 1. Update UUIDs

Edit `lib/core/constants/ble_constants.dart`:

```dart
// Service UUIDs - Replace with your actual UUIDs
static final Guid targetServiceUuid = Guid('YOUR-SERVICE-UUID-HERE');

// Characteristic UUIDs
static final Guid colorCharacteristicUuid = Guid('YOUR-COLOR-CHAR-UUID');
static final Guid powerCharacteristicUuid = Guid('YOUR-POWER-CHAR-UUID');
static final Guid hitNotificationUuid = Guid('YOUR-HIT-CHAR-UUID');
```

### 2. Customize Device Detection

In `ble_constants.dart`, update the device name filter:

```dart
static const String targetDeviceNamePrefix = 'YOUR-DEVICE-NAME';

static bool isSnipeTarget(String? deviceName) {
  // Customize detection logic
}
```

### 3. Modify Command Format

The `BleService` class has methods for sending commands:

```dart
// In ble_service.dart

/// Write color to a target
Future<bool> writeColor(String deviceId, List<int> rgb) async {
  // Customize byte format: [mode, R, G, B]
  final command = BleConstants.buildColorCommand(rgb[0], rgb[1], rgb[2]);
  await characteristic.write(command, withoutResponse: true);
}

/// Turn target on/off
Future<bool> writePower(String deviceId, bool on) async {
  // Customize: 0x01 = on, 0x00 = off
  await characteristic.write([on ? 0x01 : 0x00], withoutResponse: true);
}
```

### 4. Parse Hit Notifications

In `ble_service.dart`, update `_handleHitNotification`:

```dart
void _handleHitNotification(String deviceId, List<int> value) {
  // Customize parsing based on your protocol
  if (value[0] == BleConstants.hitEventByte) {
    // Process hit event
  }
}
```

## Game Modes

| Mode | Description | Target Requirement |
|------|-------------|-------------------|
| Random Snipe | Hit random targets in 30 seconds | 2+ |
| Time to 10 | Race to hit 10 targets | 2+ |
| Reaction Time | Test your reflexes | 1+ |
| Marksman | Same target, 10 consecutive hits | 1+ |
| Color Hunt | Match colors, avoid wrong hits | 3+ |
| Rapid Fire | Increasing speed survival | 2+ |
| Snipe Streak | Build combos for multipliers | 2+ |
| Four Corners | Hit all 4 in sequence | 4 |
| Lightning Round | 15-second speed challenge | 2+ |
| Endurance | 2-minute stamina test | 2+ |
| Two Player | Head-to-head competition | 4 |
| Free Practice | Manual control, no scoring | 1+ |

## Platform Notes

### Android

- Permissions auto-requested at runtime
- Requires Android 6.0 (API 23) or higher
- Location permission needed for BLE scanning on some devices

### iOS

- BLE permission requested on first scan
- Background BLE enabled for persistent connections
- Requires iOS 12.0 or higher

## Dependencies

- `flutter_blue_plus` - BLE communication
- `flutter_riverpod` - State management
- `hive_flutter` - Local storage
- `audioplayers` - Sound effects
- `flutter_animate` - Animations
- `google_fonts` - Typography
- `permission_handler` - Runtime permissions

## License

MIT License - Feel free to use and modify for your hockey training needs!

## Contributing

Contributions are welcome! Please feel free to submit pull requests or open issues for bugs and feature requests.
