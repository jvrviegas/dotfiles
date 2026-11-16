// Theme packs for the agent roster. The shown layout picks the pack (LAYOUTS); a pack sets the
// panel's words, fonts, rule color and 8-bit art (art/<pack>/<sprite>.svg, 16x12 px, plus
// <sprite>-eye.svg, the pixels lit in the status color, and emblem.svg for the header).
//
// sections: the priority headers by status. classes: program key -> [name, sprite];
// `other` covers every other program. tag: the second line's id from the terminal id ("6p").
// motion: how a working agent moves (see MOTIONS in main.js).

export const LAYOUTS = {
  "death-star": "imperial",
  "kaer-morhen": "witcher",
  hallownest: "hallownest",
  "horseshoe-overlook": "outlaws",
};

export const PACKS = {
  imperial: {
    title: "IMPERIAL FLEET",
    unit: ["UNIT", "UNITS"],
    head: { family: "Orbitron", weight: 700, size: 10.5 }, // fonts/Orbitron-Bold.ttf (OFL)
    sub: { family: "Share Tech Mono", weight: 400, size: 10.5 }, // fonts/ShareTechMono-Regular.ttf (OFL)
    rule: "blocked",
    sections: { blocked: "AWAITING ORDERS", done: "MISSION COMPLETE", working: "ENGAGED", idle: "STANDING BY" },
    pinned: "FLAGSHIP",
    pinTip: "Make flagship",
    sortTitle: "SORT FLEET",
    empty: "No ships deployed. Agents join the fleet when they report their status. Older versions and agents inside tmux may not.",
    classes: {
      claude: ["STAR DESTROYER", "star-destroyer"],
      codex: ["TIE INTERCEPTOR", "interceptor"],
      opencode: ["TIE FIGHTER", "fighter"],
      pi: ["PROBE DROID", "probe"],
    },
    other: ["SHUTTLE", "shuttle"],
    tag: (id) => `BLACK-${id}`,
    clock: "T+",
    motion: "bob",
  },
  witcher: {
    title: "NOTICE BOARD",
    unit: ["CONTRACT", "CONTRACTS"],
    head: { family: "Cinzel Decorative", weight: 700, size: 10.5 }, // fonts/CinzelDecorative-Bold.ttf (OFL)
    sub: { family: "Alegreya Sans", weight: 500, size: 11 }, // fonts/AlegreyaSans-Medium.ttf (OFL)
    rule: "accent",
    sections: { blocked: "AWAITING YOUR SIGN", done: "CONTRACT FULFILLED", working: "ON THE HUNT", idle: "MEDITATING" },
    pinned: "MAIN QUEST",
    pinTip: "Make it the main quest",
    sortTitle: "SORT CONTRACTS",
    empty: "The notice board is empty. Agents post contracts here when they report their status.",
    classes: {
      claude: ["WOLF SCHOOL", "wolf"],
      codex: ["CAT SCHOOL", "cat"],
      opencode: ["GRIFFIN SCHOOL", "griffin"],
      pi: ["VIPER SCHOOL", "viper"],
    },
    other: ["BEAR SCHOOL", "bear"],
    tag: (id) => `NO. ${id}`,
    clock: "",
    motion: "hum", // the medallion trembles when there's work nearby
  },
  hallownest: {
    title: "HUNTER'S JOURNAL",
    unit: ["ENTRY", "ENTRIES"],
    head: { family: "Cinzel", weight: 700, size: 10.5 }, // fonts/Cinzel-Bold.ttf (OFL)
    sub: { family: "Alegreya Sans", weight: 500, size: 11 },
    rule: "accent",
    sections: { blocked: "SHADE AWAITS", done: "GEO COLLECTED", working: "EXPLORING", idle: "RESTING AT A BENCH" },
    pinned: "PINNED ON THE MAP",
    pinTip: "Pin on the map",
    sortTitle: "SORT JOURNAL",
    empty: "The journal is empty. Bugs appear here when agents report their status.",
    classes: {
      claude: ["THE KNIGHT", "knight"],
      codex: ["HORNET", "hornet"],
      opencode: ["QUIRREL", "quirrel"],
      pi: ["GRUB", "grub"],
    },
    other: ["WANDERING HUSK", "husk"],
    tag: (id) => `ENTRY ${id}`,
    clock: "",
    motion: "float",
  },
  outlaws: {
    title: "THE GANG",
    unit: ["OUTLAW", "OUTLAWS"],
    head: { family: "Rye", weight: 400, size: 11 }, // fonts/Rye-Regular.ttf (OFL)
    sub: { family: "Special Elite", weight: 400, size: 10.5 }, // fonts/SpecialElite-Regular.ttf (Apache 2.0)
    rule: "accent",
    sections: { blocked: "WANTED", done: "JOB DONE", working: "ON A JOB", idle: "AT CAMP" },
    pinned: "HIGH HONOR",
    pinTip: "Mark high honor",
    sortTitle: "SORT THE GANG",
    empty: "Camp is quiet. Outlaws ride in when agents report their status.",
    classes: {
      claude: ["GUNSLINGER", "gunslinger"],
      codex: ["SHARPSHOOTER", "sharpshooter"],
      opencode: ["BOUNTY HUNTER", "bounty-hunter"],
      pi: ["TRAPPER", "trapper"],
    },
    other: ["DRIFTER", "drifter"],
    // The terminal id read as a number makes the reward: t6p -> $241.
    tag: (id) => `REWARD $${Number.isNaN(parseInt(id, 36)) ? id : parseInt(id, 36)}`,
    clock: "",
    motion: "gallop",
  },
};
