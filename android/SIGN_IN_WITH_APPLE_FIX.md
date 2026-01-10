# Sign In With Apple Namespace Fix

## Problem
The `sign_in_with_apple` package (versions 4.1.0 and 4.3.0) is missing a `namespace` declaration in its Android `build.gradle` file, which is required by Android Gradle Plugin (AGP) 8.0+.

## Solution
A patch script has been created that automatically adds the required namespace to the package's build.gradle file.

## Files
- `android/fix_sign_in_with_apple.sh` - Shell script that patches the package
- `android/build.gradle.kts` - Gradle configuration that runs the patch automatically before builds

## Usage

### Automatic (Recommended)
The patch is automatically applied before each build via the Gradle task `fixSignInWithAppleNamespace`. No manual intervention needed.

### Manual
If you need to run the patch manually (e.g., after `flutter pub get`), run:

```bash
bash android/fix_sign_in_with_apple.sh
```

## What the Fix Does
The script adds the following line to the `android` block in the package's `build.gradle`:

```gradle
namespace 'com.aboutyou.dart_packages.sign_in_with_apple'
```

## Note
This patch modifies files in your `.pub-cache` directory. If you run `flutter pub get` or `flutter clean`, you may need to run the patch script again. The Gradle build is configured to automatically apply the patch before each build.

## Verification
To verify the fix is applied, check:

```bash
grep -A 2 "android {" ~/.pub-cache/hosted/pub.dev/sign_in_with_apple-*/android/build.gradle
```

You should see `namespace 'com.aboutyou.dart_packages.sign_in_with_apple'` in the output.

