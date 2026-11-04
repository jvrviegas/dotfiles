// ctrl-b w (keys.json): go to a space. The picker (cmd-p) without its tabs
// and new-work rows: one row per space, in the sidebar's order, opening on
// the shown one. Type to filter, ↑/↓ and Enter to go, Esc to leave.

import { View, div, svg } from "gpui-kit";
import { v_flex, h_flex, InputState, Input, Scrollbar, v_virtual_list, VirtualListScrollHandle } from "gpui-base";
import { spaces, run, theme, props, closeOverlay, shared, setShared } from "herdr";

const ROW = 32;
const VISIBLE = 12;
const MARK = { ansi6: "#22a99a", ansi3: "#e3814f", ansi4: "#5b8def", ansi5: "#8b7cf6", ansi2: "#3fae6a", ansi1: "#d9649a" };

// Space colors, as the picker and sidebar keep them (shared "space.colors"),
// so a space has the same color here as everywhere else.
const PROJECT_COLORS = ["ansi6", "ansi3", "ansi4", "ansi5", "ansi2", "ansi1"];
function spaceColors() {
  const ids = new Set(spaces().map((p) => p.id));
  const kept = Object.fromEntries(Object.entries(shared("space.colors") ?? {}).filter(([id]) => ids.has(id)));
  let changed = Object.keys(kept).length !== Object.keys(shared("space.colors") ?? {}).length;
  for (const p of spaces()) {
    if (kept[p.id] || p.name === "~") continue;
    const uses = (c) => Object.values(kept).filter((v) => v === c).length;
    kept[p.id] = PROJECT_COLORS.reduce((best, c) => (uses(c) < uses(best) ? c : best));
    changed = true;
  }
  if (changed) setShared("space.colors", kept);
  return kept;
}
function spaceColor(t, p) {
  if (p.name === "~") return t.dim;
  const c = spaceColors()[p.id] ?? PROJECT_COLORS[0];
  return c.startsWith("#") ? c : (MARK[c] ?? t[c]);
}

export default class SpacePicker extends View {
  init(_props, cx) {
    this.filter = "";
    this.at = null;
    this.list = VirtualListScrollHandle.new();
    this.input = InputState.new({ placeholder: "Go to a space…" });
    this.input.on("change", (_e, cx) => { this.filter = this.input.value().toLowerCase(); this.at = 0; this.list.scroll_to_item(0); cx.notify(); });
    this.input.on("submit", () => this.go(this.rows()[this.at]));
    this.input.focus();
    cx.timer.after(600, () => this.input.focus());
    this.handle = cx.focus_handle();
  }

  close() {
    this.list.release();
  }

  rows() {
    const f = this.filter;
    return spaces().filter((s) => !f || [s.name, s.branch ?? "", s.machine ?? "", s.folder].join(" ").toLowerCase().includes(f));
  }

  go(s) {
    if (!s) return;
    closeOverlay(props().overlay);
    run("space.select", { id: s.id });
  }

  glyph(t, st) {
    if (st === "working") return svg("mods/workspace-chrome/spinner.svg").size(12).flex_none().text_color(t.working).spin(900);
    return div().w(12).flex_none().text_color(t[st] ?? t.dim).child(st === "idle" ? "○" : st ? "●" : "·");
  }

  render() {
    const t = theme();
    const rows = this.rows();
    const n = rows.length;
    // Opens on the shown space.
    if (this.at === null) {
      this.at = Math.max(0, rows.findIndex((s) => s.active));
      this.list.scroll_to_item(this.at);
    }
    this.at = Math.max(0, Math.min(this.at, n - 1));

    const row = (s, on) => {
      const tabs = `${s.tabs.length} tab${s.tabs.length === 1 ? "" : "s"}`;
      const info = [s.machine, s.branch, tabs].filter(Boolean).join(" · ");
      return h_flex()
        .mx(4)
        .px(10)
        .h(ROW)
        .rounded(7)
        .gap(10)
        .items_center()
        .cursor_pointer()
        .when(on, (el) => el.bg(t.hover))
        .child(this.glyph(t, s.status))
        .child(h_flex().size(18).flex_none().rounded(5).bg(spaceColor(t, s)).items_center().justify_center().text_size(10.5).font_bold().text_color("#ffffff").child([...s.name][0]?.toUpperCase() ?? "?"))
        .child(div().flex_1().truncate().text_color(t.foreground).when(s.active, (d) => d.font_semibold()).child(s.name))
        .when(s.status === "blocked", (el) => el.child(div().flex_none().text_size(11).text_color(t.blocked).child("needs you")))
        .when(s.status === "done", (el) => el.child(div().flex_none().text_size(11).text_color(t.done).child("finished")))
        .child(div().flex_none().text_size(11).text_color(t.dim).child(info));
    };

    return v_flex()
      .id("space-picker")
      .track_focus(this.handle)
      .w_full()
      .min_h(0)
      .p(18)
      .gap(10)
      .bg(t.popover)
      .text_size(13)
      .on_key_down((e, cx) => {
        if (e.key === "escape") return closeOverlay(props().overlay);
        if (!n) return;
        if (e.key === "down") this.at = (this.at + 1) % n;
        else if (e.key === "up") this.at = (this.at + n - 1) % n;
        else return;
        this.list.scroll_to_item(this.at);
        cx.stop_propagation();
        cx.notify();
      })
      .child(h_flex().items_center().child(div().flex_1().text_size(15).font_semibold().text_color(t.foreground).child("Go to space…")).child(div().text_size(11).text_color(t.dim).child("Esc")))
      .child(
        h_flex().h(36).flex_none().px(10).gap(8).items_center().rounded(9).border_1().border_color(t.accent).bg(t.background)
          .child(svg("mods/workspace-chrome/search.svg").size(15).text_color(t.dim))
          .child(Input.new(this.input).flex_1().h_full().text_size(12.8).text_color(t.foreground)),
      )
      .when(!n, (el) => el.child(div().px(10).py(6).mb(6).text_color(t.dim).child("No matching spaces")))
      .when(n, (el) =>
        el.child(
          v_flex()
            .relative()
            .h(Math.min(n, VISIBLE) * ROW)
            .mb(6)
            .child(
              v_virtual_list("sp-list", n, ROW, (i) => rows[i].id, (range) =>
                rows.slice(range.start, range.end).map((s, k) => row(s, range.start + k === this.at)))
                .track_scroll(this.list)
                .on_item_click((key) => this.go(spaces().find((s) => s.id === key)))
                .size_full(),
            )
            .child(Scrollbar.vertical("sp-list").absolute().inset_0()),
        ));
  }
}
