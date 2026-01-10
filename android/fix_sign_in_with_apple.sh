#!/bin/bash

# Script to fix sign_in_with_apple package namespace issue
# This adds the required namespace to the package's build.gradle file

PUB_CACHE="${PUB_CACHE:-$HOME/.pub-cache}"
PACKAGE_PATH="$PUB_CACHE/hosted/pub.dev/sign_in_with_apple-"

# Find all sign_in_with_apple package versions
for package_dir in "$PUB_CACHE"/hosted/pub.dev/sign_in_with_apple-*; do
    if [ -d "$package_dir" ]; then
        BUILD_GRADLE="$package_dir/android/build.gradle"
        
        if [ -f "$BUILD_GRADLE" ]; then
            # Check if namespace is already present
            if ! grep -q "namespace" "$BUILD_GRADLE"; then
                echo "Patching $package_dir/android/build.gradle..."
                
                # Add namespace after 'android {' line
                sed -i.bak "s/android {/android {\n    namespace 'com.aboutyou.dart_packages.sign_in_with_apple'/" "$BUILD_GRADLE"
                
                # Remove backup file
                rm -f "${BUILD_GRADLE}.bak"
                
                echo "✓ Added namespace to $(basename $package_dir)"
            else
                echo "✓ Namespace already present in $(basename $package_dir)"
            fi
        fi
    fi
done

echo "Done!"

