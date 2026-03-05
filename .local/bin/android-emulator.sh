#!/bin/zsh

"${ANDROID_HOME:-$HOME/Library/Android/sdk}/emulator/emulator" -avd $1 &
