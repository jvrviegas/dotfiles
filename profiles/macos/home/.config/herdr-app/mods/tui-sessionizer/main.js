// ctrl-b s (keys.json): herdr-sessionizer in a split that closes when it exits, like the herdr TUI's prefix+s.
import { View, div } from "gpui-kit";
import { run, closeOverlay, props } from "herdr";

const COMMAND = "herdr-sessionizer";

export default class Launch extends View {
  init() {
    const overlay = props()?.overlay;
    if (!overlay) return; // only act when opened by its key (mod.open), not on `herdr-app check`
    closeOverlay(overlay);
    run("pane.split", {
      direction: "right",
      argv: ["/bin/zsh", "-lic", `${COMMAND}; herdr-app do terminal.kill --terminal $HC_TERMINAL_ID >/dev/null`],
    });
  }
  render() {
    return div();
  }
}
