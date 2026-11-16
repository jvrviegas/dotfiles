// Agent roster: the agents list dressed by a theme pack (packs.js) chosen by the shown layout:
// the Imperial Fleet (death-star), the Witcher notice board (kaer-morhen), Hollow Knight's
// Hunter's Journal (hallownest), the Red Dead gang (horseshoe-overlook).
// Cloned from Herdr's `agents` mod; same grouping, sorting, pins and sub-agent trees.
// Each agent is an 8-bit character picked by its program; its lit pixels (cockpit, eyes,
// engines) and its motion show the status.

import { View, div, svg, image, PathBuilder, Background } from "gpui-kit";
import { v_flex, h_flex } from "gpui-base";
import { agents, terminals, panes, focused, spaces, run, theme, shared, setShared, setAgentOrder, openOverlay, closeOverlay, props, window, layout } from "herdr";
import { PACKS, LAYOUTS } from "./packs.js";

const ME = "mods/agent-roster";
const packId = () => LAYOUTS[shared("layout")] ?? "imperial";
const packOf = () => PACKS[packId()];

// The character for a program: [name, sprite], from the pack's classes, else its `other`.
const classOf = (P, program, app) => {
  const [name, art] = P.classes[program?.key] ?? P.classes[(app ?? "").replace(/-code$/, "")] ?? P.other;
  return { name, art };
};
// Stable per terminal (t6p -> 6P), so a tag doesn't change when the list re-sorts.
const tagOf = (P, address) => P.tag(address.split("/").pop().replace(/^t/, "").toUpperCase());

// How a working agent moves, `s` screen px per sprite pixel.
const MOTIONS = {
  bob: (el, s) => el.loop("top", { from: 0, to: -s, period: 1200 }),
  float: (el, s) => el.loop("top", { from: 0, to: -s, period: 2400 }),
  gallop: (el, s) => el.loop("top", { from: 0, to: -s, period: 420 }),
  hum: (el, s) => el.loop("left", { from: -s / 2, to: s / 2, period: 160 }),
};

const RECT = () => PathBuilder.fill().move_to("0%", "0%").line_to("100%", "0%").line_to("100%", "100%").line_to("0%", "100%").close().build();
// A layer filling its relative parent with a linear gradient (90 = left to right).
const gradient = (from, to, angle = 90) =>
  globalThis.window.paint_path(RECT(), Background.linear_gradient(angle, from, to)).absolute().top(0).left(0).size_full();

function find(node, id) {
  if (node?.id === id) return node;
  for (const child of node?.children ?? []) {
    const found = find(child, id);
    if (found) return found;
  }
  return null;
}

// The sidebar's rail goes by its width, not a flag: dragging its edge narrows it too.
const narrow = () => (find(layout(), "sidebar")?.size?.px ?? Infinity) < 160;

// To the rail (on macOS wide enough for the traffic lights), or back to the width it had.
function toggleSidebar() {
  const width = find(layout(), "sidebar")?.size?.px;
  if (!narrow()) setShared("sidebar.width", width);
  // Mods edited before the rail went by width still read the flag.
  setShared("sidebar.collapsed", !narrow());
  run("layout.resize", { id: "sidebar", px: narrow() ? (shared("sidebar.width") ?? 268) : window()?.platform === "macos" ? 76 : 44 });
}

// Drops what an agent puts before its title: a status glyph or spinner and the separator
// after it ("✦  Working", "⠋ - Thinking"), and Codex's blinking "[ ! ] " / "[ . ] " mark.
// Stops at an opening bracket or quote, so a title that starts with one ("[web] login") keeps it.
const clean = (s) => (s ?? "").replace(/^[^\p{L}\p{N}\p{Ps}\p{Pi}]+/u, "").replace(/^\[ [!.] \] /, "").trim();

function leadPanes(all) {
  const leads = new Map();
  for (const p of all) {
    if (!p.terminal) continue;
    const current = leads.get(p.tab);
    // First agent, else first focused terminal, else first terminal in the tab.
    if (!current || (!current.program?.agent && (p.program?.agent || (!current.focused && p.focused)))) leads.set(p.tab, p);
  }
  return leads;
}

function title(tab, l) {
  const prog = l?.program?.name;
  const live = clean(l?.title);
  // clean() would strip a path's leading ~ or /: test the title with only its status glyph gone.
  const path = /^[~/]|^[A-Za-z]:\\/.test((l?.title ?? "").replace(/^[^\p{L}\p{N}~/]+/u, ""));
  const telling = live && live !== prog && !path && !live.includes("@") && live.toLowerCase() !== l?.program?.key;
  return (tab.name === prog || !tab.named) && telling ? live : tab.name;
}
const RANK = { blocked: 4, done: 3, working: 2, idle: 1 };
// A sub-agent without a pane isn't in agents(): its raw word, error counting as
// blocked. It's never done: it reports to its parent, and the parent's done is the news.
const kidStatus = (k, listed) => {
  const s = listed.get(k.address) ?? k.status;
  return s === "error" ? "blocked" : s === "done" ? "idle" : s;
};
const SORTS = [
  { id: "priority", label: "Priority", icon: "clock" },
  { id: "grouped", label: "Grouped by space", icon: "layers" },
];
const sortOf = () => SORTS.find((s) => s.id === shared("agents.sort")) ?? SORTS[0];
const SECTION_STATUS = { 4: "blocked", 3: "done", 2: "working", 1: "idle" };

function duration(ms) {
  const m = Math.floor(ms / 60000);
  if (m < 1) return "<1m";
  if (m < 60) return `${m}m`;
  const h = Math.floor(m / 60);
  return h < 24 ? `${h}h` : `${Math.floor(h / 24)}d`;
}

export default class Agents extends View {
  init(_props, cx) {
    if (props()?.sortMenu) return;
    this.folded = new Set();
    // Each agent's last state and when it changed (ms), kept across restarts.
    this.changed = JSON.parse(localStorage.getItem("changed") ?? "{}");
    this.pendingPins = JSON.parse(localStorage.getItem("pins") ?? "[]");
    if (!this.pendingPins.length) localStorage.removeItem("pins");
    this.migratingPins = new Set();
    cx.timer.every(30000, (cx) => cx.notify());
  }

  // Stamps agents whose state changed. Done and idle count as one: looking at a
  // finished agent turns done into idle, and looking isn't the agent doing anything.
  track(list, now) {
    let dirty = false;
    for (const a of list) {
      const s = a.status === "done" ? "idle" : a.status;
      if (this.changed[a.address]?.s === s) continue;
      this.changed[a.address] = { s, at: now };
      dirty = true;
    }
    if (!dirty) return;
    // Gone and old: the list alone is empty right after a start.
    const listed = new Set(list.map((a) => a.address));
    for (const [k, c] of Object.entries(this.changed)) if (!listed.has(k) && now - c.at > 30 * 86400000) delete this.changed[k];
    localStorage.setItem("changed", JSON.stringify(this.changed));
  }

  // Keep offline pins until their terminal returns, and keep each pending until
  // core echoes the label so a failed write doesn't erase the old pin.
  migratePins(all) {
    const listed = new Map(all.filter((t) => t.state === "live").map((t) => [t.address, t]));
    const pending = this.pendingPins.filter((address) => {
      const terminal = listed.get(address);
      if (!terminal) return true;
      if (terminal.labels?.["herdr.pinned"]) return false;
      if (!this.migratingPins.has(address)) {
        this.migratingPins.add(address);
        run("terminal.pin", { terminal: address, pinned: true });
      }
      return true;
    });
    if (pending.length === this.pendingPins.length) return;
    this.pendingPins = pending;
    if (pending.length) localStorage.setItem("pins", JSON.stringify(pending));
    else localStorage.removeItem("pins");
  }

  since(a) {
    return this.changed[a.address]?.at ?? 0;
  }

  rank(a) {
    return RANK[a.status] ?? 0;
  }

  sortMenu(t, P) {
    const on = sortOf().id;
    return v_flex()
      .w_full()
      .p(5)
      .bg(t.popover)
      .text_size(12.8)
      .child(div().px(8).pt(4).pb(6).text_size(10).font_family(P.head.family).font_weight(P.head.weight).text_color(t.dim).child(P.sortTitle))
      .children(SORTS.map((s) => h_flex()
        .id(`sort-${s.id}`)
        .h(31)
        .px(8)
        .gap(9)
        .rounded(2)
        .items_center()
        .text_color(t.foreground)
        .hover((el) => el.bg(t.hover))
        .on_click(() => {
          setShared("agents.sort", s.id);
          closeOverlay(props().overlay);
        })
        .child(svg(`mods/workspace-chrome/${s.icon}.svg`).size(14).flex_none().text_color(t.muted))
        .child(div().flex_1().child(s.label))
        .when(s.id === on, (el) => el.child(svg("mods/workspace-chrome/check.svg").size(14).flex_none().text_color(t.accent)))));
  }

  peek(addr) {
    run("terminal.peek", { terminal: addr });
  }

  // Live sub-agents of `addr`, depth first, each with the tree lines in front of it.
  tree(all, addr, lead = []) {
    const kids = all.filter((k) => k.parent === addr && k.state === "live");
    return kids.flatMap((k, i) => {
      const last = i === kids.length - 1;
      return [
        { t: k, lines: [...lead, last ? "└" : "├"] },
        ...this.tree(all, k.address, [...lead, last ? "" : "│"]),
      ];
    });
  }

  // Sub-agents ride along under their parent as half-size characters.
  subRow(t, P, s, shown) {
    const k = s.t;
    const st = kidStatus(k, this.listed);
    const on = k.address === shown;
    return h_flex()
      .id(`sub-${k.address}`)
      .pl(17)
      .pr(8)
      .rounded(2)
      .h(26)
      .flex_none()
      .gap(0)
      .items_center()
      .text_size(12.5)
      .when(on, (el) => el.bg(t.raised))
      .hover((s) => s.bg(t.hover))
      .on_click(() => (this.listed.has(k.address) ? run("pane.focus", { terminal: k.address }) : this.peek(k.address)))
      .children(s.lines.map(l => div().self_start().mt(-4).w(9).h(17).mr(4).flex_none()
        .when(Boolean(l), el => el.border_l(1.5).border_color(t.input))
        .when(l === "└" || l === "├", el => el.border_b(1.5))))
      .child(div().mr(7).child(this.sprite(t, P, classOf(P, k.program, k.app), st, 1)))
      .child(div().flex_1().truncate().text_color(on ? t.foreground : t.muted).child(k.name || k.template || k.program?.name || k.address))
      .child(h_flex().w(14).flex_none().items_center().justify_center().child(this.status(t, { status: st })));
  }

  // An 8-bit character, `s` screen px per sprite pixel. Its lit pixels show the status:
  // the working color while it moves (the pack's motion), blinking red when it needs you,
  // the done color when finished, dark with the whole sprite dimmed when idle.
  sprite(t, P, cls, status, s = 2) {
    const w = 16 * s, h = 12 * s;
    const art = `${ME}/art/${packId()}/${cls.art}`;
    const lit = { working: t.working, blocked: t.blocked, done: t.done }[status];
    const body = div().absolute().left(0).top(0).w(w).h(h)
      .when(status === "idle", (el) => el.opacity(0.45))
      .when(status === "working", (el) => MOTIONS[P.motion](el, s))
      .child(image(`${art}.svg`).absolute().left(0).top(0).w(w).h(h))
      .when(Boolean(lit), (el) => el.child(svg(`${art}-eye.svg`).absolute().left(0).top(0).w(w).h(h).text_color(lit)
        .when(status === "blocked", (e) => e.loop("opacity", { from: 0.15, to: 1, period: 500 }))
        .when(status === "working", (e) => e.loop("opacity", { from: 0.5, to: 1, period: 900 }))));
    return div().relative().w(w).h(h).flex_none().child(body);
  }

  // The status glyphs for headers and escorts: ▲ needs you, ◎ working (its core pulses),
  // ● done, ○ idle. `null` is the pinned section's emblem.
  status(t, a) {
    if (a.status === "blocked") return svg(`${ME}/alert.svg`).size(11).flex_none().text_color(t.blocked);
    if (a.status === "working") {
      return div().size(11).flex_none().rounded(6).border(1.5).border_color(t.working).flex().items_center().justify_center()
        .child(div().size(3).rounded(2).bg(t.working).loop("opacity", { from: 0.2, to: 1, period: 900 }));
    }
    if (a.status === "done") return div().size(7).mx(2).flex_none().rounded(4).bg(t.done);
    if (a.status === "idle") return div().size(7).mx(2).flex_none().rounded(4).border(1.5).border_color(t.idle ?? t.dim);
    if (a.status === null) return svg(`${ME}/art/${packId()}/emblem.svg`).size(11).flex_none().text_color(t.accent);
    return div().size(7).mx(2).flex_none().rounded(4).bg(t.dim);
  }

  render(cx) {
    const t = theme();
    const P = packOf();
    if (props()?.sortMenu) return this.sortMenu(t, P);
    const head = (el) => el.font_family(P.head.family).font_weight(P.head.weight);
    const sub = (el) => el.font_family(P.sub.family).font_weight(P.sub.weight);
    const collapsed = narrow();
    const sort = sortOf();
    let list = agents();
    this.listed = new Map(list.map((a) => [a.address, a.status]));
    const all = terminals();
    this.migratePins(all);
    const shown = focused()?.agent;
    const now = Date.now();
    this.track(list, now);
    // A kept sub-agent (one with a pane) is in agents() too: where a tree shows
    // it, it gets no row of its own, unless it's pinned.
    const nested = new Set(collapsed ? [] : list.flatMap((a) => this.tree(all, a.address).map((s) => s.t.address)));
    list = list.filter((a) => a.pinned || !nested.has(a.address));
    const tabCounts = new Map();
    for (const a of list) tabCounts.set(a.tab, (tabCounts.get(a.tab) ?? 0) + 1);
    const byPriority = sort.id === "priority";
    const urgency = new Map(list.map((a) => [a.address, Math.max(this.rank(a), ...this.tree(all, a.address).map((s) => RANK[kidStatus(s.t, this.listed)] ?? 0))]));
    const rankOf = (a) => urgency.get(a.address);
    if (byPriority) list = [...list].sort((x, y) => rankOf(y) - rankOf(x) || this.since(y) - this.since(x) || y.seq - x.seq);
    const pinned = list.filter((a) => a.pinned);
    const rest = list.filter((a) => !a.pinned);
    list = [...pinned, ...rest];
    setAgentOrder(list.map((a) => a.address));

    const withKids = (a, i) => {
      const subs = collapsed ? [] : this.tree(all, a.address);
      const r = row(a, i, subs);
      if (this.folded.has(a.address)) return [r];
      return [r, ...subs.map((s) => this.subRow(t, P, s, shown))];
    };

    // The fold chevron; folded, the count too, colored by the most urgent one.
    const fold = (a, subs) => {
      const sts = subs.map((s) => kidStatus(s.t, this.listed));
      const top = sts.reduce((m, s) => ((RANK[s] ?? 0) > (RANK[m] ?? 0) ? s : m), null);
      const open = !this.folded.has(a.address);
      return sub(div())
        .id(`fold-${a.address}`)
        .h(18)
        .px(3)
        .gap(3)
        .flex()
        .items_center()
        .rounded(2)
        .text_size(11)
        .text_color(open ? t.dim : (t[top] ?? t.dim))
        .cursor_pointer()
        .hover((s) => s.bg(t.hover).text_color(t.foreground))
        .on_click((_e, cx) => {
          cx.stop_propagation();
          open ? this.folded.add(a.address) : this.folded.delete(a.address);
          cx.notify();
        })
        .child(svg(`mods/workspace-chrome/chevron-${open ? "down" : "right"}.svg`).size(11).flex_none())
        .when(!open, (el) => el.child(String(subs.length)));
    };

    // A row reads "space › detail": the detail is a tab someone named or the
    // agent's own title, never an automatic tab number unless two rows would
    // otherwise read the same.
    // Read the pane snapshot once: every host read copies the whole list into JS.
    const leads = leadPanes(panes());
    const tabs = new Map(spaces().flatMap(s => s.tabs).map(tab => [tab.id, tab]));
    const labels = new Map(list.map(a => {
      const tab = tabs.get(a.tab);
      const many = tabCounts.get(a.tab) > 1;
      return [a.address, tab ? title(many ? { ...tab, named: false } : tab, many ? a : leads.get(a.tab)) : (a.title || a.program?.name || "")];
    }));
    const label = (a) => labels.get(a.address);
    const detail = new Map(list.map(a => [a.address, /^\d+$/.test(label(a)) ? null : label(a)]));
    const seen = {};
    for (const a of list) { const k = `${a.space_name}\u0000${detail.get(a.address) ?? ""}`; seen[k] = (seen[k] ?? 0) + 1; }
    for (const a of list) {
      if (detail.get(a.address) == null && seen[`${a.space_name}\u0000`] > 1) detail.set(a.address, label(a));
    }

    const row = (a, i, subs = []) => {
      const more = detail.get(a.address);
      // An agent on another machine (`vps/t7`) says which.
      const machine = a.address.includes("/") ? a.address.split("/")[0] : null;
      if (collapsed) {
        return h_flex()
          .id(`ag-${a.address}`)
          .h(26)
          .px(8)
          .flex_none()
          .items_center()
          .gap(4)
          .hover((s) => s.bg(t.hover))
          .on_click(() => run("pane.focus", { pane: a.pane }))
          .child(sub(div()).flex_1().min_w(0).whitespace_nowrap().text_right().text_color(t.muted).child(String(i + 1)))
          .child(h_flex().w(14).flex_none().items_center().justify_center().child(this.status(t, a)));
      }
      const when = this.since(a);
      const idle = a.status === "idle" && !a.focused;
      const blocked = a.status === "blocked";
      const working = a.status === "working";
      const isPinned = a.pinned;
      const cls = classOf(P, a.program, a.app);
      const pin = div()
        .id(`pin-${a.address}`)
        .flex_none()
        .p(2)
        .rounded(2)
        .text_color(t.dim)
        .cursor_pointer()
        .hover((s) => s.bg(t.hover).text_color(t.foreground))
        .tooltip(isPinned ? "Unpin" : P.pinTip)
        .on_click((_e, cx) => {
          cx.stop_propagation();
          run("terminal.pin", { terminal: a.address, pinned: !isPinned });
          // The row moves away from under the pointer, and no hover-out comes.
          this.hovered = null;
          cx.notify();
        })
        .child(svg(`mods/workspace-chrome/${isPinned ? "pin-off" : "pin"}.svg`).size(13));
      // Under a space header the space goes without saying; an automatic tab number says nothing.
      // Without a space header above (priority, pinned) the row names its space.
      const full = byPriority || isPinned;
      const name = full ? a.space_name || label(a) : more ?? (/^\d+$/.test(label(a)) ? a.program?.name || label(a) : label(a));
      return h_flex()
        .id(`ag-${a.address}`)
        .relative()
        .overflow_hidden()
        .pl(10)
        .pr(8)
        .h(40)
        .flex_none()
        .rounded(2)
        .items_center()
        .gap(9)
        .when(blocked, (el) => el.bg(t.blocked + "14"))
        .when(a.focused, (el) => el.bg(t.selected))
        .cursor_pointer()
        .hover((s) => s.bg(t.hover))
        .on_hover((on, cx) => {
          if (on) this.hovered = a.address;
          else if (this.hovered === a.address) this.hovered = null;
          cx.notify();
        })
        .on_click(() => run("pane.focus", { pane: a.pane }))
        // Needs you: a bar on the left edge, pulsing in the blocked color.
        .when(blocked, (el) => el.child(div().absolute().left(0).top(6).bottom(6).w(2).bg(t.blocked).loop("opacity", { from: 0.25, to: 1, period: 1400 })))
        // Working: a sweep along the bottom edge.
        .when(working, (el) => el.child(div().absolute().bottom(0).h(1).w(48).bg(t.working).opacity(0.7).loop("left", { from: -48, to: 240, period: 2600, easing: "linear" })))
        .child(div().id(`agent-fold-${a.address}`).flex_none().flex().items_center().justify_center()
          .when(subs.length > 0, el => el.on_click((_e, cx) => {
            cx.stop_propagation();
            this.folded.has(a.address) ? this.folded.delete(a.address) : this.folded.add(a.address);
            cx.notify();
          }))
          .child(this.sprite(t, P, cls, a.status)))
        .child(v_flex().flex_1().min_w(0).gap(1)
          .child(h_flex().min_w(0).gap(5).items_center()
            .child(div().min_w(0).max_w(full && more ? 120 : 200).truncate().text_color(idle ? t.muted : t.foreground).child(name))
            .when(full && Boolean(more), el => el.child(div().flex_1().min_w(0).truncate().text_color(t.dim).child(`› ${more}`))))
          .child(sub(div()).truncate().text_size(P.sub.size).text_color(t.dim).child(`${cls.name} · ${tagOf(P, a.address)}`)))
        .when(Boolean(machine), el => el.child(sub(div()).text_size(10).text_color(t.dim).child(machine)))
        .when(subs.length > 0, el => el.child(fold(a, subs)))
        .when(this.hovered === a.address, el => el.child(pin))
        .when(this.hovered !== a.address && Boolean(when), el => el.child(sub(div()).flex_none().text_size(11)
          .text_color(working ? t.working : t.dim).child(working ? `${P.clock}${duration(now - when).replace("<1m", P.clock ? "0m" : "<1m")}` : duration(now - when))));
    };

    // Groups in list order: spaces (grouped) or priority sections. Agents of a
    // space are next to each other in agents(), so neighbours make a group.
    const groups = pinned.length ? [{ id: "pinned", label: P.pinned, status: null, members: pinned, themed: true }] : [];
    for (const a of rest) {
      const r = rankOf(a) || RANK.idle;
      const id = byPriority ? `sec-${r}` : `sp-${a.space}`;
      if (groups.at(-1)?.id === id) groups.at(-1).members.push(a);
      else groups.push({ id, label: byPriority ? P.sections[SECTION_STATUS[r]] : (a.space_name || "").toUpperCase(), status: byPriority ? SECTION_STATUS[r] : undefined, members: [a], themed: byPriority });
    }

    // A group's header; it folds the group. Folded, it says how many and the most urgent state.
    // Status sections and the pinned one get their glyph and the pack's heading font; spaces get its second font.
    const header = (g) => {
      const open = !this.folded.has(g.id);
      const top = g.members.reduce((m, a) => ((RANK[a.status] ?? 0) > (RANK[m] ?? 0) ? a.status : m), null);
      return h_flex()
        .id(g.id)
        .px(8)
        .pt(10)
        .h(32)
        .flex_none()
        .gap(6)
        .items_center()
        .text_size(9.5)
        .cursor_pointer()
        .hover((s) => s.text_color(t.foreground))
        .on_click((_e, cx) => {
          open ? this.folded.add(g.id) : this.folded.delete(g.id);
          cx.notify();
        })
        .when(g.themed, (el) => el.child(h_flex().w(14).flex_none().items_center().justify_center().child(this.status(t, { status: g.status }))))
        .child((g.themed ? head : sub)(div()).truncate().text_size(g.themed ? P.head.size - 1 : 11)
          .text_color(t[g.status] ?? (g.status === null ? t.accent : t.dim)).child(g.label))
        .when(byPriority || !open, (el) => el.child(sub(div()).text_size(11).text_color(t.dim).child(`· ${g.members.length}`)))
        .child(div().flex_1())
        .when(!open, (el) => el
          .when(!byPriority && top && top !== "idle", (el) => el.child(this.status(t, { status: top })))
          .child(svg("mods/workspace-chrome/chevron-right.svg").size(11).flex_none().text_color(t.dim)));
    };
    const rows = collapsed
      ? list.flatMap(withKids)
      : groups.flatMap((g) => [header(g), ...(this.folded.has(g.id) ? [] : g.members.flatMap(withKids))]);
    const rule = t[P.rule] ?? t.accent;

    return v_flex()
      .size_full()
      .min_h(0)
      .bg(t.chrome)
      .border_t(1)
      .border_color(t.border)
      .text_size(13)
      .when(!collapsed, (el) =>
        el.child(
          v_flex()
            .flex_none()
            .child(
              h_flex()
                .px(16)
                .h(41)
                .pt(14)
                .pb(5)
                .gap(8)
                .items_center()
                .child(svg(`${ME}/art/${packId()}/emblem.svg`).size(14).flex_none().text_color(t.accent))
                .child(head(div()).text_size(P.head.size).text_color(t.foreground).child(P.title))
                .child(div().flex_1())
                .child(sub(div()).text_size(11).text_color(t.dim).child(`${list.length} ${P.unit[list.length === 1 ? 0 : 1]}`))
                .child(
                  div()
                    .id("ag-sort")
                    .text_size(11)
                    .text_color(t.dim)
                    .hover((s) => s.text_color(t.foreground))
                    .on_click(() => openOverlay({ mod: "agent-roster", kind: "popup", width: 200, height: 140, props: { sortMenu: true } }))
                    .tooltip(`Sort: ${sort.label}`)
                    .child(svg(`mods/workspace-chrome/${sort.icon}.svg`).size(14)),
                ),
            )
            // The rule under the title, fading out to the right.
            .child(div().relative().mx(16).h(1).flex_none().child(gradient(rule, rule + "00"))),
        ),
      )
      .when(list.length === 0 && !collapsed, (el) =>
        el.child(div().px(16).pt(10).text_size(12).text_color(t.dim).child(P.empty)),
      )
      .child(v_flex().id("ag-list").flex_1().min_h(0).px(collapsed ? 0 : 8).overflow_y_scrollbar().mode("always").children(rows))
      .when(collapsed, (el) =>
        el.child(
          h_flex()
            .h(28)
            .items_center()
            .justify_center()
            .child(
              div()
                .id("collapse")
                .text_size(13)
                .text_color(t.dim)
                .hover((s) => s.text_color(t.foreground))
                .on_click(toggleSidebar)
                .child("»"),
            ),
        ),
      );
  }
}
