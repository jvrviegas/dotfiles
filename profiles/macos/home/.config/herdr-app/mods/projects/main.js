// cmd-shift-f (keys.json): herdr-sessionizer as a native popup. Lists folders
// under ~/Projects (5 levels deep) plus Git repositories directly in $HOME.
// Type to filter (fuzzy, space-separated terms), ↑/↓ and Enter to open, Esc
// to leave. Opening goes to the space named parent_folder if this computer
// has one, else makes it in that folder, the same as herdr-sessionizer.

import { View, div, svg } from "gpui-kit";
import { v_flex, h_flex, InputState, Input, Scrollbar, v_virtual_list, VirtualListScrollHandle } from "gpui-base";
import { exec, home, spaces, run, theme, props, closeOverlay } from "herdr";

const LIST = `
if [[ -d $HOME/Projects ]]; then fd . "$HOME/Projects" --min-depth 1 --max-depth 5 --type d; fi
for dir in "$HOME"/*; do if [[ -d $dir/.git ]]; then printf '%s\\n' "$dir"; fi; done
`;
const ROW = 32;
const VISIBLE = 12;

// The space name herdr-sessionizer gives a folder: parent_current, dots -> underscores.
function label(path) {
  const parts = path.split("/");
  return `${parts.at(-2)}_${parts.at(-1)}`.replaceAll(".", "_");
}

// Higher is better; null when a term doesn't match. A term found in the
// folder's own name beats one found in its path, which beats a scattered match.
function score(p, terms) {
  let total = 0;
  for (const term of terms) {
    const at = p.name.indexOf(term);
    if (at === 0) total += 400;
    else if (at > 0) total += 300;
    else if (p.rel.includes(term)) total += 200;
    else {
      let i = -1, first = -1;
      for (const ch of term) {
        i = p.rel.indexOf(ch, i + 1);
        if (i < 0) return null;
        if (first < 0) first = i;
      }
      total += Math.max(1, 100 - (i - first));
    }
  }
  return total;
}

export default class Projects extends View {
  init(_props, cx) {
    this.all = null;
    this.error = null;
    this.matches = [];
    this.at = 0;
    this.list = VirtualListScrollHandle.new();
    this.input = InputState.new({ placeholder: "Search projects…" });
    this.input.on("change", (_e, cx) => { this.refilter(); cx.notify(); });
    this.input.on("submit", () => this.go(this.matches[this.at]));
    this.input.focus();
    cx.timer.after(600, () => this.input.focus());
    this.handle = cx.focus_handle();
    cx.spawn(async (cx) => {
      try {
        const r = await exec("bash", ["-c", LIST]);
        if (r.code !== 0) throw new Error(r.stderr.trim() || `exit ${r.code}`);
        const h = home();
        const paths = [...new Set(r.stdout.split("\n").filter(Boolean).map((p) => p.replace(/\/+$/, "")))].sort();
        this.all = paths.map((path) => {
          const rel = path.startsWith(h + "/") ? "~" + path.slice(h.length) : path;
          const cut = rel.lastIndexOf("/");
          return { path, rel: rel.toLowerCase(), name: rel.slice(cut + 1).toLowerCase(), shownName: rel.slice(cut + 1), shownParent: rel.slice(0, cut + 1), label: label(path) };
        });
        this.refilter();
      } catch (e) {
        this.error = String(e?.message ?? e);
      }
      cx.notify();
    });
  }

  close() {
    this.list.release();
  }

  refilter() {
    if (!this.all) return;
    const terms = this.input.value().toLowerCase().split(/\s+/).filter(Boolean);
    this.matches = !terms.length
      ? this.all
      : this.all
          .map((p) => ({ p, s: score(p, terms) }))
          .filter((m) => m.s !== null)
          .sort((a, b) => b.s - a.s || a.p.path.length - b.p.path.length || (a.p.path < b.p.path ? -1 : 1))
          .map((m) => m.p);
    this.at = 0;
    this.list.scroll_to_item(0);
  }

  go(p) {
    if (!p) return;
    closeOverlay(props().overlay);
    const open = spaces().find((s) => s.machine == null && s.name === p.label);
    if (open) run("space.select", { id: open.id });
    else run("space.new", { name: p.label, folder: p.path });
  }

  render() {
    const t = theme();
    const open = new Set(spaces().filter((s) => s.machine == null).map((s) => s.name));
    const n = this.matches.length;
    const note = this.error ? `Couldn't list projects: ${this.error}` : !this.all ? "Loading…" : n ? null : "No matching folders";

    const row = (p, on) =>
      h_flex()
        .mx(4)
        .px(10)
        .h(ROW)
        .rounded(7)
        .gap(8)
        .items_center()
        .cursor_pointer()
        .when(on, (el) => el.bg(t.hover))
        .child(svg("mods/workspace-chrome/folder.svg").size(14).flex_none().text_color(open.has(p.label) ? t.accent : t.dim))
        .child(div().flex_none().text_color(t.foreground).when(on, (d) => d.font_semibold()).child(p.shownName))
        .child(div().flex_1().truncate().text_size(11).text_color(t.dim).child(p.shownParent))
        .when(open.has(p.label), (el) => el.child(div().flex_none().text_size(11).text_color(t.dim).child("open")));

    return v_flex()
      .id("projects")
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
      .child(h_flex().items_center().child(div().flex_1().text_size(15).font_semibold().text_color(t.foreground).child("Open project…")).child(div().text_size(11).text_color(t.dim).child("Esc")))
      .child(
        h_flex().h(36).flex_none().px(10).gap(8).items_center().rounded(9).border_1().border_color(t.accent).bg(t.background)
          .child(svg("mods/workspace-chrome/search.svg").size(15).text_color(t.dim))
          .child(Input.new(this.input).flex_1().h_full().text_size(12.8).text_color(t.foreground))
          .when(this.all, (el) => el.child(div().flex_none().text_size(11).text_color(t.dim).child(`${n}/${this.all.length}`))),
      )
      .when(note, (el) => el.child(div().px(10).py(6).mb(6).text_color(this.error ? t.blocked : t.dim).child(note)))
      .when(!note, (el) =>
        el.child(
          v_flex()
            .relative()
            .h(Math.min(n, VISIBLE) * ROW)
            .mb(6)
            .child(
              v_virtual_list("pj-list", n, ROW, (i) => this.matches[i].path, (range) =>
                this.matches.slice(range.start, range.end).map((p, k) => row(p, range.start + k === this.at)))
                .track_scroll(this.list)
                .on_item_click((key) => this.go(this.matches.find((p) => p.path === key)))
                .size_full(),
            )
            .child(Scrollbar.vertical("pj-list").absolute().inset_0()),
        ));
  }
}
