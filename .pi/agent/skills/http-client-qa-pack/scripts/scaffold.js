#!/usr/bin/env node
const fs = require('fs');
const path = require('path');

function parseArgs(argv) {
  const args = {};
  for (let i = 2; i < argv.length; i += 1) {
    const arg = argv[i];
    if (!arg.startsWith('--')) continue;
    const key = arg.slice(2);
    const value = argv[i + 1] && !argv[i + 1].startsWith('--') ? argv[++i] : 'true';
    args[key] = value;
  }
  return args;
}

function slugify(input) {
  return String(input || 'api-qa')
    .trim()
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, '-')
    .replace(/^-+|-+$/g, '');
}

function writeNew(file, content) {
  if (fs.existsSync(file)) {
    console.error(`Refusing to overwrite existing file: ${file}`);
    process.exitCode = 1;
    return;
  }
  fs.mkdirSync(path.dirname(file), { recursive: true });
  fs.writeFileSync(file, content);
  console.log(`created ${file}`);
}

const args = parseArgs(process.argv);
const root = args.root || 'http-client';
const issue = args.issue || 'ISSUE-KEY';
const slug = slugify(args.slug || issue);
const title = args.title || `${issue} API QA`;
const dir = path.join(root, slug);
const requestFile = path.join(dir, `${slug}.http`);

const readme = `# ${issue} QA — ${title}\n\nManual HTTP checks for ${issue}. Replace placeholders with endpoint-specific setup, happy paths, negative cases, and read-back checks.\n\n## Prerequisites\n\n1. Backend running locally.\n2. rest.nvim env selected:\n\n   \`\`\`vim\n   :Rest env set http-client/env/local.env\n   \`\`\`\n\n3. Open \`${slug}.http\` and run requests with \`:Rest run\`.\n\n## How to run\n\n1. Run **Login as GET2C admin** first.\n2. Run setup requests and copy returned IDs into top-level variables.\n3. Run happy-path requests in order.\n4. Run negative requests and confirm expected status codes.\n5. Run read-back/list requests and verify response fields.\n\n## Expected results\n\n- Happy-path requests return success responses.\n- Invalid requests return the expected 4xx responses.\n- Read endpoints expose the fields required by the acceptance criteria.\n- Audit/history tables contain rows for successful state changes when applicable.\n\n## Optional DB check\n\n\`\`\`bash\ncd get2c-dash2zero-backend\ndocker compose exec db psql -U postgres -d dash2zero\n\`\`\`\n\nAdd issue-specific SQL here if needed.\n\n## Sample data\n\nSee \`sample-data/payloads.json\`.\n`;

const http = `# ${issue} — ${title}\n#\n# Run Login first, then setup requests. Copy returned IDs into these variables.\n\n@resourceId = paste-resource-id-here\n\n### Login as GET2C admin\n# @name login\nPOST {{baseUrl}}/auth/login\nContent-Type: application/json\n\n{\n  "email": "{{get2cEmail}}",\n  "password": "{{get2cPassword}}"\n}\n\n### Current session — expect authenticated user\nGET {{baseUrl}}/auth/session\n\n### Setup — create or fetch required test data\n# TODO: replace with issue-specific setup request.\nGET {{baseUrl}}/companies?limit=5\n\n### Happy path — TODO\n# TODO: replace route, method, and payload.\nGET {{baseUrl}}/companies/{{resourceId}}\n\n### Negative — TODO, expect 400/403/404 as appropriate\n# TODO: replace route, method, and invalid payload.\nGET {{baseUrl}}/companies/not-a-uuid\n\n### Read-back/list verification — TODO\nGET {{baseUrl}}/companies?limit=20\n\n### Logout\nPOST {{baseUrl}}/auth/logout\n`;

const sample = `{
  "notes": "Replace with issue-specific safe test payloads. Do not include secrets or production data.",
  "exampleCompany": {
    "name": "${issue} Test Company Lda",
    "nif": "501964843",
    "email": "${slug}@example.pt",
    "caeCode": "10110",
    "district": "Lisboa",
    "municipality": "Lisboa",
    "referenceYear": 2025,
    "dataSource": "${slug}-qa"
  }
}
`;

writeNew(path.join(dir, 'README.md'), readme);
writeNew(requestFile, http);
writeNew(path.join(dir, 'sample-data', 'payloads.json'), sample);
