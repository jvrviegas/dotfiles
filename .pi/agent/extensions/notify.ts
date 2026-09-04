/**
 * Pi Notify Extension
 *
 * Sends a native terminal notification when Pi agent is done and waiting for input.
 * Supports multiple terminal protocols:
 * - OSC 777: Ghostty, iTerm2, WezTerm, rxvt-unicode
 * - OSC 99: Kitty
 * - Windows toast: Windows Terminal (WSL)
 */

import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

function windowsToastScript(title: string, body: string): string {
	const type = "Windows.UI.Notifications";
	const mgr = `[${type}.ToastNotificationManager, ${type}, ContentType = WindowsRuntime]`;
	const template = `[${type}.ToastTemplateType]::ToastText01`;
	const toast = `[${type}.ToastNotification]::new($xml)`;
	return [
		`${mgr} > $null`,
		`$xml = [${type}.ToastNotificationManager]::GetTemplateContent(${template})`,
		`$xml.GetElementsByTagName('text')[0].AppendChild($xml.CreateTextNode('${body}')) > $null`,
		`[${type}.ToastNotificationManager]::CreateToastNotifier('${title}').Show(${toast})`,
	].join("; ");
}

function notifyOSC777(title: string, body: string): void {
	const seq = `\x1b]777;notify;${title};${body}\x07`;
	// Inside tmux, wrap in the passthrough DCS (each ESC in the payload doubled)
	// so tmux forwards it to the outer terminal instead of swallowing it.
	const out = process.env.TMUX ? `\x1bPtmux;\x1b${seq}\x1b\\` : seq;
	process.stdout.write(out);
}

function notifyOSC99(title: string, body: string): void {
	// Kitty OSC 99: i=notification id, d=0 means not done yet, p=body for second part
	process.stdout.write(`\x1b]99;i=1:d=0;${title}\x1b\\`);
	process.stdout.write(`\x1b]99;i=1:p=body;${body}\x1b\\`);
}

function notifyWindows(title: string, body: string): void {
	const { execFile } = require("child_process");
	execFile("powershell.exe", ["-NoProfile", "-Command", windowsToastScript(title, body)]);
}

function notify(title: string, body: string): void {
	if (process.env.WT_SESSION) {
		notifyWindows(title, body);
	} else if (process.env.KITTY_WINDOW_ID) {
		notifyOSC99(title, body);
	} else {
		// Ghostty/iTerm2/WezTerm (incl. macOS): native terminal notification via OSC 777
		notifyOSC777(title, body);
	}
}

async function tmux(args: string[]): Promise<string | null> {
	const { execFile } = require("child_process");
	return new Promise((resolve) => {
		execFile("tmux", args, { timeout: 1000 }, (error: Error | null, stdout: string) => {
			if (error) return resolve(null);
			resolve(stdout.trim() || null);
		});
	});
}

async function getTmuxLocation(): Promise<string | null> {
	if (!process.env.TMUX) return null;

	const target = process.env.TMUX_PANE;
	return tmux(target
		? ["display-message", "-p", "-t", target, "#S - #W"]
		: ["display-message", "-p", "#S - #W"]);
}

async function isCurrentTmuxWindow(): Promise<boolean> {
	if (!process.env.TMUX || !process.env.TMUX_PANE) return false;

	const currentPane = await tmux([
		"display-message",
		"-p",
		"-t",
		process.env.TMUX_PANE,
		"#{session_name}\t#{window_name}",
	]);
	if (!currentPane) return false;

	const [currentSession, currentWindow] = currentPane.split("\t");
	const attachedSessions = await tmux(["list-clients", "-F", "#{client_session}"]);
	if (!attachedSessions?.split("\n").includes(currentSession)) return false;

	const activeWindow = await tmux([
		"display-message",
		"-p",
		"-t",
		currentSession,
		"#{window_name}",
	]);
	return activeWindow === currentWindow;
}

export default function (pi: ExtensionAPI) {
	pi.on("agent_end", async () => {
		if (await isCurrentTmuxWindow()) return;

		const tmuxLocation = await getTmuxLocation();
		const body = tmuxLocation ? `Ready for input in ${tmuxLocation}` : "Ready for input";
		notify("Pi", body);
	});
}
