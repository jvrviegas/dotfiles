#!/usr/bin/env bash

JSON_FILE="$HOME/.local/state/zmk-battery/battery.json"

if [ ! -f "$JSON_FILE" ]; then
  echo "CONNECTED=false"
  echo "LEVELS="
  exit 0
fi

python3 -c "
import json, time
try:
    d = json.load(open('$JSON_FILE'))
    ts = d.get('timestamp', 0)
    if (time.time() - ts) > 300:
        print('CONNECTED=false')
        print('LEVELS=')
    else:
        connected = 'true' if d.get('connected', False) else 'false'
        levels = d.get('levels', [])
        print(f'CONNECTED={connected}')
        print('LEVELS=' + ','.join(str(l) for l in levels))
except Exception:
    print('CONNECTED=false')
    print('LEVELS=')
"
