// The hosted demo uses fictional data, so its accounts are listed here for reviewers.
// Must match backend/app/services/demo_accounts.rb. A real deployment would sign in through the company's SSO instead.
export const DEMO_ACCOUNTS = [
  { email: 'hr@acme.test', role: 'HR Manager', access: 'View and change salaries, import from Excel' },
  { email: 'viewer@acme.test', role: 'Viewer', access: 'Read only' },
]
export const DEMO_PASSWORD = 'acme-demo-2026'
