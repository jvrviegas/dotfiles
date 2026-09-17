#!/bin/zsh

if [[ "$(uname)" == "Darwin" ]]; then
  DEFAULT_SDK="$HOME/Library/Android/sdk"
else
  DEFAULT_SDK="$HOME/Android/Sdk"
fi

"${ANDROID_HOME:-$DEFAULT_SDK}/emulator/emulator" -avd $1 &
