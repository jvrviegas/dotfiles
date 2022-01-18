#!/bin/bash

npx react-native bundle --platform android --dev false --entry-file index.js --bundle-output android/app/src/main/assets/index.android.bundle --assets-dest android/app/src/main/res &&
cd android/app/src/main/res && rm -rf drawable-hdpi drawable-mdpi drawable-xhdpi drawable-xxhdpi drawable-xxxhdpi raw &&
cd ../../../../ && ./gradlew clean && ./gradlew assembleRelease && cd ../
