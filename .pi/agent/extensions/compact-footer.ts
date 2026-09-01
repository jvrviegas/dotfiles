import type { AssistantMessage } from "@earendil-works/pi-ai";
import type { ExtensionAPI, ExtensionContext } from "@earendil-works/pi-coding-agent";

function truncateToWidth(text: string, width: number): string {
	if (width <= 0) return "";

	let visible = 0;
	let result = "";
	for (let i = 0; i < text.length; i++) {
		const char = text[i];

		// Preserve ANSI escape sequences without counting them as visible width.
		if (char === "\x1b" && text[i + 1] === "[") {
			let j = i + 2;
			while (j < text.length && !/[A-Za-z]/.test(text[j])) j++;
			if (j < text.length) {
				result += text.slice(i, j + 1);
				i = j;
				continue;
			}
		}

		if (visible >= width) break;
		result += char;
		visible++;
	}

	return result;
}

/**
 * Compact Footer Extension
 *
 * Replaces pi's default footer with a single compact status line showing:
 * - git branch
 * - active model
 * - thinking level, when available
 * - extension statuses set via ctx.ui.setStatus()
 * - current context usage
 * - accumulated cost for assistant messages in the active branch
 *
 * Commands:
 * - /compact-footer on
 * - /compact-footer off
 * - /compact-footer toggle
 */
export default function (pi: ExtensionAPI) {
	let enabled = true;

	function formatCount(n: number): string {
		if (!Number.isFinite(n)) return "0";
		if (Math.abs(n) < 1000) return `${Math.round(n)}`;
		if (Math.abs(n) < 1_000_000) return `${(n / 1000).toFixed(1)}k`;
		return `${(n / 1_000_000).toFixed(1)}m`;
	}

	function branchCost(ctx: ExtensionContext): number {
		let cost = 0;
		for (const entry of ctx.sessionManager.getBranch()) {
			if (entry.type !== "message" || entry.message.role !== "assistant") continue;
			const message = entry.message as AssistantMessage;
			cost += message.usage?.cost?.total ?? 0;
		}
		return cost;
	}

	function installFooter(ctx: ExtensionContext) {
		ctx.ui.setFooter((tui, theme, footerData) => {
			const unsubscribeBranch = footerData.onBranchChange(() => tui.requestRender());

			return {
				dispose: unsubscribeBranch,
				invalidate() {},
				render(width: number): string[] {
					const branch = footerData.getGitBranch() ?? "no-git";
					const cwd = process.env.HOME && ctx.cwd.startsWith(process.env.HOME)
						? `~${ctx.cwd.slice(process.env.HOME.length)}`
						: ctx.cwd;
					const model = ctx.model?.id ?? "no-model";
					const thinking = pi.getThinkingLevel ? ` ${pi.getThinkingLevel()}` : "";
					const usage = ctx.getContextUsage();
					const cost = branchCost(ctx);

					const statuses = [...footerData.getExtensionStatuses().values()]
						.map((s) => s.trim())
						.filter(Boolean)
						.join("  ");

					const contextText = usage
						? `${usage.tokens == null ? "?" : formatCount(usage.tokens)}/${formatCount(usage.contextWindow)} ${usage.percent == null ? "?" : Math.round(usage.percent)}%`
						: "ctx n/a";

					const parts = [
						theme.fg("accent", cwd),
						theme.fg("accent", branch),
						theme.fg("dim", model + thinking),
						statuses ? theme.fg("muted", statuses) : undefined,
						theme.fg("dim", contextText),
						theme.fg("dim", `$${cost.toFixed(4)}`),
					].filter((part): part is string => Boolean(part));

					return [truncateToWidth(parts.join(theme.fg("muted", " │ ")), width)];
				},
			};
		});
	}

	pi.on("session_start", async (_event, ctx) => {
		if (enabled) installFooter(ctx);
	});

	pi.registerCommand("compact-footer", {
		description: "Toggle the compact custom footer (args: on, off, toggle)",
		handler: async (args, ctx) => {
			const action = args.trim().toLowerCase() || "toggle";
			if (action === "on") enabled = true;
			else if (action === "off") enabled = false;
			else enabled = !enabled;

			if (enabled) {
				installFooter(ctx);
				ctx.ui.notify("Compact footer enabled", "info");
			} else {
				ctx.ui.setFooter(undefined);
				ctx.ui.notify("Default footer restored", "info");
			}
		},
	});
}
