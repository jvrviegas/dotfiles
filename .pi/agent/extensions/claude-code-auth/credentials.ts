import { execFileSync, execSync } from "node:child_process";
import { tmpdir } from "node:os";
import { readAllClaudeAccounts, refreshAccount, writeBackCredentials, type ClaudeAccount, type ClaudeCredentials } from "./keychain.ts";

const CREDENTIAL_CACHE_TTL_MS = 30_000;
export const OAUTH_TOKEN_URL = "https://claude.ai/v1/oauth/token";
export const OAUTH_CLIENT_ID = "9d1c250a-e61b-44d9-88ed-5944d1962f5e";

let allAccounts: ClaudeAccount[] = [];
let activeAccountSource: string | null = null;
const accountCacheMap = new Map<string, { creds: ClaudeCredentials; cachedAt: number }>();

export function initClaudeAccounts(): ClaudeAccount[] {
	allAccounts = readAllClaudeAccounts();
	activeAccountSource = process.env.CLAUDE_CODE_ACCOUNT_SOURCE ?? allAccounts[0]?.source ?? null;
	return allAccounts;
}

function getActiveAccount(): ClaudeAccount | null {
	if (allAccounts.length === 0) initClaudeAccounts();
	if (allAccounts.length === 0) return null;
	if (activeAccountSource) {
		const found = allAccounts.find((a) => a.source === activeAccountSource);
		if (found) return found;
	}
	return allAccounts[0];
}

function parseOAuthResponse(raw: string, currentRefreshToken: string, now = Date.now()): ClaudeCredentials | null {
	let data: { access_token?: string; refresh_token?: string; expires_in?: number };
	try {
		data = JSON.parse(raw);
	} catch {
		return null;
	}
	if (!data.access_token) return null;
	return {
		accessToken: data.access_token,
		refreshToken: data.refresh_token ?? currentRefreshToken,
		expiresAt: now + (data.expires_in ?? 36_000) * 1000,
	};
}

function refreshViaOAuth(refreshToken: string): ClaudeCredentials | null {
	const script = `
process.stdin.resume();
let input = '';
process.stdin.on('data', c => input += c);
process.stdin.on('end', () => {
  const body = new URLSearchParams({
    grant_type: 'refresh_token',
    client_id: '${OAUTH_CLIENT_ID}',
    refresh_token: input.trim()
  });
  fetch('${OAUTH_TOKEN_URL}', {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: body.toString()
  })
    .then(r => { if (!r.ok) throw new Error(String(r.status)); return r.json(); })
    .then(d => process.stdout.write(JSON.stringify(d)))
    .catch(e => { process.stdout.write(JSON.stringify({ error: String(e) })); process.exit(1); });
});`;

	try {
		const result = execFileSync(process.execPath, ["-e", script], {
			input: refreshToken,
			timeout: 15_000,
			encoding: "utf-8",
			stdio: ["pipe", "pipe", "ignore"],
		});
		return parseOAuthResponse(result, refreshToken);
	} catch {
		return null;
	}
}

function refreshViaCli(): void {
	try {
		execSync("claude -p . --model haiku", {
			timeout: 60_000,
			encoding: "utf-8",
			env: { ...process.env, TERM: "dumb" },
			stdio: "ignore",
			cwd: tmpdir(),
		});
	} catch {
		// Best-effort fallback only.
	}
}

function refreshIfNeeded(account: ClaudeAccount): ClaudeCredentials | null {
	if (account.credentials.expiresAt > Date.now() + 60_000) return account.credentials;

	if (account.credentials.refreshToken) {
		const oauthCreds = refreshViaOAuth(account.credentials.refreshToken);
		if (oauthCreds && oauthCreds.expiresAt > Date.now() + 60_000) {
			account.credentials = oauthCreds;
			writeBackCredentials(account.source, oauthCreds);
			return oauthCreds;
		}
	}

	refreshViaCli();
	const refreshed = refreshAccount(account.source);
	if (refreshed && refreshed.expiresAt > Date.now() + 60_000) {
		account.credentials = refreshed;
		return refreshed;
	}
	return null;
}

export function getClaudeCodeCredentials(): ClaudeCredentials | null {
	const account = getActiveAccount();
	if (!account) return null;

	const now = Date.now();
	const cached = accountCacheMap.get(account.source);
	if (cached && now - cached.cachedAt < CREDENTIAL_CACHE_TTL_MS && cached.creds.expiresAt > now + 60_000) {
		return cached.creds;
	}

	const fresh = refreshIfNeeded(account);
	if (!fresh) {
		accountCacheMap.delete(account.source);
		return null;
	}
	accountCacheMap.set(account.source, { creds: fresh, cachedAt: now });
	return fresh;
}
