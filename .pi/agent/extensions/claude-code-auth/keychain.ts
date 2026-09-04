import { execFileSync, execSync } from "node:child_process";
import { chmodSync, readFileSync, writeFileSync } from "node:fs";
import { homedir } from "node:os";
import { join } from "node:path";

export interface ClaudeCredentials {
	accessToken: string;
	refreshToken: string;
	expiresAt: number;
	subscriptionType?: string;
}

export interface ClaudeAccount {
	label: string;
	source: string;
	credentials: ClaudeCredentials;
}

const PRIMARY_SERVICE = "Claude Code-credentials";

function parseCredentials(raw: string): ClaudeCredentials | null {
	let parsed: unknown;
	try {
		parsed = JSON.parse(raw);
	} catch {
		return null;
	}

	const data = (parsed as { claudeAiOauth?: unknown }).claudeAiOauth ?? parsed;
	const creds = data as {
		accessToken?: unknown;
		refreshToken?: unknown;
		expiresAt?: unknown;
		subscriptionType?: unknown;
	};

	if (
		typeof creds.accessToken !== "string" ||
		typeof creds.refreshToken !== "string" ||
		typeof creds.expiresAt !== "number"
	) {
		return null;
	}

	return {
		accessToken: creds.accessToken,
		refreshToken: creds.refreshToken,
		expiresAt: creds.expiresAt,
		subscriptionType: typeof creds.subscriptionType === "string" ? creds.subscriptionType : undefined,
	};
}

function readKeychainService(serviceName: string): string | null {
	try {
		return execSync(`security find-generic-password -s "${serviceName}" -w`, {
			timeout: 2000,
			encoding: "utf-8",
		}).trim();
	} catch (err: unknown) {
		const error = err as { status?: number; code?: string; killed?: boolean };
		if (error.killed || error.code === "ETIMEDOUT") {
			throw new Error("Keychain read timed out. Try restarting Keychain Access.", { cause: err });
		}
		if (error.status === 36) {
			throw new Error("macOS Keychain is locked. Unlock it or run: security unlock-keychain ~/Library/Keychains/login.keychain-db", { cause: err });
		}
		if (error.status === 128) {
			throw new Error("Keychain access was denied. Grant access when prompted by macOS.", { cause: err });
		}
		if (error.status === 44) return null;
		throw new Error(`Failed to read Keychain entry ${serviceName} (exit ${error.status ?? "unknown"}).`, { cause: err });
	}
}

function listClaudeKeychainServices(): string[] {
	try {
		const dump = execSync("security dump-keychain", {
			timeout: 5000,
			maxBuffer: 1024 * 1024 * 10,
			encoding: "utf-8",
		});
		const services: string[] = [];
		const seen = new Set<string>();
		const re = /"Claude Code-credentials(?:-[0-9a-f]+)?"/g;
		let match = re.exec(dump);
		while (match) {
			const service = match[0].slice(1, -1);
			if (!seen.has(service)) {
				seen.add(service);
				services.push(service);
			}
			match = re.exec(dump);
		}
		const ordered: string[] = [];
		if (seen.has(PRIMARY_SERVICE)) ordered.push(PRIMARY_SERVICE);
		for (const service of services) if (service !== PRIMARY_SERVICE) ordered.push(service);
		return ordered.length > 0 ? ordered : [PRIMARY_SERVICE];
	} catch {
		return [PRIMARY_SERVICE];
	}
}

function readCredentialsFile(): ClaudeCredentials | null {
	try {
		const raw = readFileSync(join(homedir(), ".claude", ".credentials.json"), "utf-8");
		return parseCredentials(raw);
	} catch {
		return null;
	}
}

function buildAccountLabels(credsList: ClaudeCredentials[]): string[] {
	const baseLabels = credsList.map((c) => {
		if (!c.subscriptionType) return "Claude";
		return `Claude ${c.subscriptionType.charAt(0).toUpperCase()}${c.subscriptionType.slice(1)}`;
	});
	const counts = new Map<string, number>();
	for (const label of baseLabels) counts.set(label, (counts.get(label) ?? 0) + 1);
	const seen = new Map<string, number>();
	return baseLabels.map((base) => {
		if ((counts.get(base) ?? 0) <= 1) return base;
		const n = (seen.get(base) ?? 0) + 1;
		seen.set(base, n);
		return `${base} ${n}`;
	});
}

export function readAllClaudeAccounts(): ClaudeAccount[] {
	if (process.platform !== "darwin") {
		const credentials = readCredentialsFile();
		if (!credentials) return [];
		return [{ label: buildAccountLabels([credentials])[0], source: "file", credentials }];
	}

	const rawAccounts: Array<{ source: string; credentials: ClaudeCredentials }> = [];
	for (const service of listClaudeKeychainServices()) {
		const raw = readKeychainService(service);
		if (!raw) continue;
		const credentials = parseCredentials(raw);
		if (credentials) rawAccounts.push({ source: service, credentials });
	}

	if (rawAccounts.length === 0) {
		const credentials = readCredentialsFile();
		if (credentials) rawAccounts.push({ source: "file", credentials });
	}

	const labels = buildAccountLabels(rawAccounts.map((account) => account.credentials));
	return rawAccounts.map((account, i) => ({ ...account, label: labels[i] }));
}

function updateCredentialBlob(existingJson: string, newCreds: ClaudeCredentials): string | null {
	let parsed: Record<string, unknown>;
	try {
		parsed = JSON.parse(existingJson);
	} catch {
		return null;
	}
	const target = (parsed.claudeAiOauth as Record<string, unknown> | undefined) ?? parsed;
	target.accessToken = newCreds.accessToken;
	target.refreshToken = newCreds.refreshToken;
	target.expiresAt = newCreds.expiresAt;
	return JSON.stringify(parsed);
}

function getKeychainAccountName(serviceName: string): string | null {
	try {
		const output = execFileSync("/usr/bin/security", ["find-generic-password", "-s", serviceName], {
			timeout: 2000,
			encoding: "utf-8",
			stdio: ["pipe", "pipe", "pipe"],
		});
		return /"acct"<blob>="([^"]*)"/.exec(output)?.[1] ?? null;
	} catch {
		return null;
	}
}

export function writeBackCredentials(source: string, creds: ClaudeCredentials): boolean {
	if (source === "file") {
		try {
			const path = join(homedir(), ".claude", ".credentials.json");
			const updated = updateCredentialBlob(readFileSync(path, "utf-8"), creds);
			if (!updated) return false;
			writeFileSync(path, updated, { encoding: "utf-8", mode: 0o600 });
			if (process.platform !== "win32") chmodSync(path, 0o600);
			return true;
		} catch {
			return false;
		}
	}

	if (process.platform !== "darwin") return false;
	try {
		const raw = readKeychainService(source);
		if (!raw) return false;
		const updated = updateCredentialBlob(raw, creds);
		if (!updated) return false;
		const accountName = getKeychainAccountName(source) ?? source;
		execFileSync("/usr/bin/security", ["add-generic-password", "-s", source, "-a", accountName, "-w", updated, "-U"], {
			timeout: 2000,
			stdio: "ignore",
		});
		return true;
	} catch {
		return false;
	}
}

export function refreshAccount(source: string): ClaudeCredentials | null {
	if (source === "file") return readCredentialsFile();
	const raw = readKeychainService(source);
	return raw ? parseCredentials(raw) : null;
}
