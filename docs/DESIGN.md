# Design notes

## Architecture

```mermaid
flowchart LR
  HR[HR Manager<br/>browser] -->|HTTPS| Rails
  subgraph Render web service
    Rails[Rails 8 API<br/>/api/v1/*] -->|serves built SPA| SPA[React + Mantine<br/>static files in /public]
  end
  Rails -->|ActiveRecord| PG[(PostgreSQL)]
```

**One deployable.** The React app is built with Vite and copied into Rails' `public/`. Rails
serves the API under `/api/v1` and falls back to `index.html` for client routes. One service means
no CORS, one URL, one thing to deploy. In development, Vite runs on :5173 and proxies `/api` to
Rails on :3000.

### Repository layout
```
backend/   Rails 8 API-only app, PostgreSQL, RSpec
frontend/  Vite + React + TypeScript, Mantine UI, TanStack Query, Vitest + Testing Library
docs/      requirements, design, AI workflow
render.yaml
```

## Domain model

`employees`
| column | type | notes |
|--------|------|-------|
| full_name | string, not null | |
| email | string, not null, unique (case-insensitive) | |
| job_title | string, not null | indexed |
| department | string, not null | indexed |
| country_code | string(2), not null | ISO 3166 alpha-2, indexed |
| salary | decimal(12,2), not null | annual, local currency, > 0 |
| employment_type | string, not null | `full_time` / `part_time` / `contract` |
| hire_date | date, not null | not in the future |

**Countries are configuration, not a table.** `config/countries.yml` holds code, name, currency and
a USD rate. A `Country` value object reads it. Currency is derived from the country, so an employee
can never have "India + EUR". Adding a country is a one-line config change with a test.

Composite index `(country_code, job_title)` backs the most common insight query.

## Backend structure
- **Controllers** stay thin: parse params, call a query/service, render JSON.
- **`EmployeeSearch`** (query object): whitelisted filters, `ILIKE` search, whitelisted sort
  columns/directions, `page`/`per_page` (capped at 100). Returns records + pagination meta.
- **`SalaryInsights`** (query object): pure SQL aggregates — `COUNT`, `MIN`, `MAX`, `AVG`,
  `percentile_cont(0.5)` for the median, USD conversion via a `CASE` built from the country config.
  One query per insight, regardless of row count.
- **Errors:** 404 `{error}`; 422 `{errors: {field: [messages]}}`; 400 for bad params.

### API (`/api/v1`)
| Method | Path | Purpose |
|--------|------|---------|
| GET | /employees?q=&country=&department=&job_title=&sort=&direction=&page=&per_page= | list |
| GET/POST/PATCH/DELETE | /employees(/:id) | CRUD |
| GET | /insights/countries | per-country stats |
| GET | /insights/countries/:code/job_titles | per-title stats in a country |
| GET | /insights/departments | headcount + USD payroll per department |
| GET | /meta | countries, departments, job titles for dropdowns |

## Seeding
`EmployeeSeeder` builds rows with `Random.new(42)` so every run produces the same data. Names come
from first/last name lists; salary = job-level base × country multiplier × ±15% noise, rounded.
Rows are inserted with `insert_all` in batches of 1,000.

## Trade-offs
| Decision | Alternative | Why |
|----------|-------------|-----|
| Offset pagination | Keyset/cursor | Users jump to page N and sort by many columns; offset at 10k rows is cheap. Revisit at 1M+. |
| `ILIKE` search | pg_trgm / full-text | Enough for 10k rows; trigram index is the upgrade path. |
| Country config file | `countries` table + admin UI | Changes rarely; config is versioned and testable. |
| SQL aggregates | Load rows into Ruby | Constant memory, one round trip, Postgres has `percentile_cont`. |
| Single service | Separate static host + API | Simpler deploy, no CORS, one URL in the demo. |
| No auth | Devise / SSO | Single persona; documented as first follow-up. |

## Performance notes
See the numbers recorded in the README after seeding and load checks.
