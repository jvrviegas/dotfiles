import Clutter from 'gi://Clutter';
import * as Main from 'resource:///org/gnome/shell/ui/main.js';
import { Extension } from 'resource:///org/gnome/shell/extensions/extension.js';

export default class PopLauncherToggle extends Extension {
    enable() {
        // The launcher is modal, so the normal GNOME shortcut cannot toggle it.
        this._signal = global.stage.connect('captured-event', (_stage, event) => {
            if (event.type() !== Clutter.EventType.KEY_PRESS ||
                event.get_key_symbol() !== Clutter.KEY_space)
                return Clutter.EVENT_PROPAGATE;

            const modifiers = event.get_state();
            if (!(modifiers & Clutter.ModifierType.SUPER_MASK) ||
                modifiers & (Clutter.ModifierType.CONTROL_MASK |
                    Clutter.ModifierType.MOD1_MASK | Clutter.ModifierType.SHIFT_MASK))
                return Clutter.EVENT_PROPAGATE;

            const launcher = Main.extensionManager.lookup('pop-shell@system76.com')?.stateObj?.window_search;
            if (!launcher?.opened)
                return Clutter.EVENT_PROPAGATE;

            launcher.close();
            return Clutter.EVENT_STOP;
        });
    }

    disable() {
        if (this._signal) {
            global.stage.disconnect(this._signal);
            this._signal = null;
        }
    }
}
