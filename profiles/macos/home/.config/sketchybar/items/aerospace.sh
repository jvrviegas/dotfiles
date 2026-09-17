sketchybar -m --add item aerospace_mode left \
              --set aerospace_mode update_freq=3 \
              --set aerospace_mode script="$PLUGIN_DIR/aerospace_mode.sh" \
              --subscribe aerospace_mode aerospace_workspace_change
