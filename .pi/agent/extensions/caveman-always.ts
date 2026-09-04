import type { ExtensionAPI, ExtensionContext } from "@earendil-works/pi-coding-agent";
import { readFileSync } from "node:fs";
import { homedir } from "node:os";
import { join } from "node:path";

const CAVEMAN_SKILL_PATH = join(homedir(), ".agents", "skills", "caveman", "SKILL.md");

function loadCavemanInstructions(): string {
	try {
		const skill = readFileSync(CAVEMAN_SKILL_PATH, "utf8");
		// Strip YAML frontmatter so only behavioral instructions hit the model.
		return skill.replace(/^---[\s\S]*?---\s*/, "").trim();
	} catch (error) {
		return `Respond terse like smart caveman. All technical substance stay. Only fluff die.

ACTIVE EVERY RESPONSE. Drop articles, filler, pleasantries, hedging. Fragments OK. Short synonyms. Use arrows for causality. Technical terms stay exact. Code blocks unchanged. Errors quoted exact.

Auto-clarity exception: drop caveman temporarily for security warnings, irreversible action confirmations, or multi-step sequences where fragments risk misread. Resume after clear part done.`;
	}
}

const cavemanInstructions = loadCavemanInstructions();

export default function cavemanAlways(pi: ExtensionAPI) {
	let cavemanEnabled = false;

	function statusText() {
		return cavemanEnabled ? "caveman: on" : "caveman: off";
	}

	function toggleCaveman(ctx: Pick<ExtensionContext, "ui">) {
		cavemanEnabled = !cavemanEnabled;
		ctx.ui.setStatus("caveman", statusText());
		ctx.ui.notify(`Caveman mode ${cavemanEnabled ? "enabled" : "disabled"}.`, "info");
	}

	pi.on("session_start", (_event, ctx) => {
		ctx.ui.setStatus("caveman", statusText());
	});

	pi.on("before_agent_start", (event) => {
		if (!cavemanEnabled) return undefined;

		return {
			systemPrompt: `${event.systemPrompt}

## Caveman Skill

The caveman skill is currently enabled for every response in this session. Use /caveman to toggle it off or on.

${cavemanInstructions}
`,
		};
	});

	pi.registerCommand("caveman", {
		description: "Toggle caveman response style on/off (disabled by default)",
		handler: async (_args, ctx) => {
			toggleCaveman(ctx);
		},
	});

	pi.registerShortcut("ctrl+shift+k", {
		description: "Toggle caveman response style on/off",
		handler: async (ctx) => {
			toggleCaveman(ctx);
		},
	});

	pi.registerCommand("caveman-always", {
		description: "Show caveman mode status",
		handler: async (_args, ctx) => {
			ctx.ui.notify(`Caveman mode ${cavemanEnabled ? "enabled" : "disabled"}. Use /caveman to toggle.`, "info");
		},
	});
}
