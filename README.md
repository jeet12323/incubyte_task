# ACME Salary Management

A web app for ACME's HR Manager to manage the salaries of 10,000 employees in 8 countries, and to
answer questions about how the organization pays people. It replaces the Excel workbooks.

- **Live app:** _add Render URL after deploy_
- **Demo video:** _add link after recording_ ([demo script](docs/DEMO_SCRIPT.md))

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

## Stack

Rails 8 (API) · PostgreSQL · RSpec · React 19 + TypeScript (Vite) · Mantine · TanStack Query ·
Vitest + Testing Library · Docker · Render

## Running locally

Prerequisites: Ruby 3.3, Node 22, PostgreSQL 14+.

```bash
# Backend (defaults to Postgres on 127.0.0.1:5434 as user postgres; override with DB_HOST, DB_PORT, DB_USERNAME, DB_PASSWORD)
cd backend
bundle install
bin/rails db:setup          # creates DBs, loads schema, seeds 10,000 employees (~2s)
bin/rails server            # http://localhost:3000

# Frontend (separate terminal)
cd frontend
npm install
npm run dev                 # http://localhost:5173 (proxies /api to :3000)
```

Smaller seed: `SEED_COUNT=500 bin/rails db:seed`. The seed is deterministic (fixed random seed).

## Tests

```bash
cd backend && bundle exec rspec       # 79 examples: models, query objects, seeder, request specs
cd frontend && npm test               # 25 tests: formatting, API client, form, pages
```

Both suites run in a few seconds and don't need network access. CI runs both on every push
(`.github/workflows/ci.yml`).

## Deploying (Render)

1. Push this repository to GitHub.
2. In Render: **New → Blueprint**, then select the repo. `render.yaml` creates the Postgres
   database and the Docker web service and wires up `DATABASE_URL` and `SECRET_KEY_BASE`.
3. On first boot the container runs migrations and seeds 10,000 employees. Later deploys keep the data.

The Docker image builds the React app and serves it from Rails, so everything is on one URL with
no CORS. On the free plan the service sleeps after ~15 min idle, so the first request can take ~30-60s.

## Project layout

```
backend/   Rails API: app/models, app/queries (EmployeeSearch, SalaryInsights),
           app/services (EmployeeSeeder), app/controllers/api/v1, spec/
frontend/  React app: src/api (typed client + hooks), src/components, src/pages
docs/      Requirements, design, AI workflow, demo script
```
