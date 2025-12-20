# App Icon Setup Instructions

## Required App Icon Specifications

To set up the UWAIS QORNY logo as your app icon, you need to:

### 1. Create the Source Icon
- **File name**: `app_icon.png`
- **Location**: `assets/images/app_icon.png`
- **Size**: 1024x1024 pixels (minimum)
- **Format**: PNG with transparent background
- **Content**: The UWAIS QORNY logo from the attached image

### 2. Icon Requirements
- **Resolution**: High resolution (1024x1024 or higher)
- **Background**: Transparent or solid color
- **Content**: The golden "UQ" monogram with "UWAIS QORNY" text
- **Quality**: Sharp and clear at all sizes

### 3. Steps to Complete Setup

1. **Save the UWAIS QORNY logo** as `app_icon.png` in the `assets/images/` folder
2. **Run the icon generation command**:
   ```bash
   flutter pub get
   flutter pub run flutter_launcher_icons:main
   ```
3. **Clean and rebuild**:
   ```bash
   flutter clean
   flutter pub get
   flutter run
   ```

### 4. What This Will Generate

The flutter_launcher_icons package will automatically create:

#### Android Icons:
- `android/app/src/main/res/mipmap-*/ic_launcher.png` (all densities)
- `android/app/src/main/res/mipmap-*/ic_launcher_round.png` (all densities)

#### iOS Icons:
- `ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-*.png` (all sizes)

#### Web Icons:
- `web/icons/Icon-192.png`
- `web/icons/Icon-512.png`
- `web/icons/Icon-maskable-192.png`
- `web/icons/Icon-maskable-512.png`

#### Windows Icons:
- `windows/runner/resources/app_icon.ico`

#### macOS Icons:
- `macos/Runner/Assets.xcassets/AppIcon.appiconset/` (all sizes)

### 5. Current Configuration

The `pubspec.yaml` file has been configured with:
```yaml
flutter_launcher_icons:
  android: "launcher_icon"
  ios: true
  web:
    generate: true
    image_path: "assets/images/app_icon.png"
    background_color: "#hexcode"
    theme_color: "#hexcode"
  windows:
    generate: true
    image_path: "assets/images/app_icon.png"
    icon_size: 48
  macos:
    generate: true
    image_path: "assets/images/app_icon.png"
  image_path: "assets/images/app_icon.png"
```

### 6. Next Steps

1. Replace this instruction file with your actual `app_icon.png`
2. Run the generation commands
3. Test the app to see the new icon

The icon will appear on:
- Home screen
- App drawer
- Recent apps
- App store listings
- Web app manifest
- Desktop shortcuts




