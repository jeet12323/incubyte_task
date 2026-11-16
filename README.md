# ACME Salary Management

A web app for ACME's HR Manager to manage the salaries of 10,000 employees in 8 countries, and to
answer questions about how the organization pays people. It replaces the Excel workbooks.

- **Live app:** _add Render URL after deploy_
- **Demo video:** _add link after recording_ ([demo script](docs/DEMO_SCRIPT.md))
- **Demo sign-in** (fictional data): `hr@acme.test` (HR Manager) or `viewer@acme.test` (read-only),
  password `acme-demo-2026`. Both accounts are also listed on the login page.

| Doc | What's in it |
|-----|--------------|
| [docs/REQUIREMENTS.md](docs/REQUIREMENTS.md) | One-page requirements: goal, scope, what's deliberately left out and why |
| [docs/DESIGN.md](docs/DESIGN.md) | Architecture diagram, domain model, API, trade-offs, performance numbers |
| [docs/AI_WORKFLOW.md](docs/AI_WORKFLOW.md) | How AI was used, the prompts, and where its output was corrected |

## What it does

- **Employees:** browse 10k employees with server-side paging, search, filters (country, department,
  job title) and sorting. Add, edit and delete employees with validation on both client and server.
  Filters live in the URL, so a view can be bookmarked or shared.
- **Insights:** org headcount and USD payroll; per-country min / median / average / max in local
  currency; job-title benchmarks within a country; payroll by department.
- **Excel export & import:** export exactly the filtered list as an `.xlsx` (dates, widths and number
  formats set), edit it in Excel and import it back to create or update employees by email. Nothing is
  saved if any row is invalid, and the errors are listed by spreadsheet row. CSV is accepted too.
- **Sign-in & roles:** every API call needs a signed-in user. HR Managers can change data; Viewers
  can only read and export. The API enforces this, not just the UI.

## Stack

Rails 8 (API) · PostgreSQL · RSpec · React 19 + TypeScript (Vite) · Mantine · TanStack Query ·
Vitest + Testing Library · Docker · Render

## Running locally

Prerequisites: Ruby 3.3, Node 22, PostgreSQL 14+.

```bash
# Backend (defaults to Postgres on 127.0.0.1:5434 as user postgres; override with DB_HOST, DB_PORT, DB_USERNAME, DB_PASSWORD)
cd backend
bundle install
bin/rails db:setup          # creates DBs, loads schema, seeds 10,000 employees (~2s) + demo accounts
bin/rails server            # http://localhost:3000

# Frontend (separate terminal)
cd frontend
npm install
npm run dev                 # http://localhost:5173 (proxies /api to :3000)
```

Smaller seed: `SEED_COUNT=500 bin/rails db:seed`. The seed is deterministic (fixed random seed).
Already have a database from before sign-in existed? Run `bin/rails db:migrate db:seed_if_empty` to add
the users table and the demo accounts without touching employees.

## Tests

```bash
cd backend && bundle exec rspec       # 122 examples: models, queries, seeder, Excel/CSV import, auth, request specs
cd frontend && npm test               # 39 tests: API client, sign-in, form, import dialog, pages
```

Both suites run in a few seconds and don't need network access. CI runs both on every push
(`.github/workflows/ci.yml`).

## Deploying (Render)

1. Push this repository to GitHub.
2. In Render: **New → Blueprint**, then select the repo. `render.yaml` creates the Postgres
   database and the Docker web service and wires up `DATABASE_URL` and `SECRET_KEY_BASE`.
3. On first boot the container runs migrations, creates the demo accounts and seeds 10,000 employees.
   Later deploys keep the data (missing demo accounts are re-created; existing ones are left alone).

The Docker image builds the React app and serves it from Rails, so everything is on one URL with
no CORS. On the free plan the service sleeps after ~15 min idle, so the first request can take ~30-60s.

## Project layout

```
backend/   Rails API: app/models (Employee, User, Country), app/queries (EmployeeSearch, SalaryInsights),
           app/services (EmployeeSeeder, EmployeeImport, EmployeeSpreadsheet, DemoAccounts),
           app/controllers/api/v1, spec/
frontend/  React app: src/api (typed client + hooks), src/auth (sign-in, roles), src/components, src/pages
docs/      Requirements, design, AI workflow, demo script
```
