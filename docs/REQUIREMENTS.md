# ACME Salary Management — Requirements (one page)

## Goal
Replace the Excel workbooks ACME's HR team uses for the salaries of ~10,000 employees in several
countries with a web app. The HR Manager should be able to **keep salary records correct** and
**answer questions about how the org pays people** without building pivot tables by hand.

## Personas
**HR Manager** at ACME (primary). Comfortable with spreadsheets, not technical. Works mostly on a laptop.
Common questions: *"What do we pay a Software Engineer in India?"*, *"Which country is our biggest
payroll cost?"*, *"Is this new offer in line with what peers in the same role and country earn?"*

**HR Viewer** (e.g. an HR business partner or finance analyst): needs to look up and export salary
data, must not be able to change it.

## Scope & features

| # | Feature | Why it matters |
|---|---------|----------------|
| 1 | **Employee directory** — browse 10k employees with server-side pagination, search by name/email, filter by country / department / job title, sort by salary, name or hire date | Replaces scrolling and filtering in Excel; must stay fast at 10k rows |
| 2 | **Manage salary records** — add, view, edit, delete an employee (name, email, job title, department, country, annual salary, employment type, hire date) with validation | Core "manage salaries" job; validation stops the typos Excel lets through |
| 3 | **Country insights** — per country: headcount, min / max / average / median salary in local currency, plus total payroll in USD | "How do we pay people in X?" |
| 4 | **Job title insights within a country** — min / max / average / median per job title | Benchmarking an offer or a raise against peers |
| 5 | **Department insights** — headcount and payroll cost (USD) by department | "Where does our money go?" |
| 6 | **Seed data** — deterministic script generating 10,000 realistic employees | Realistic demo + performance check |
| 7 | **Sign-in and roles** — email + password sign-in; HR Managers can change data, Viewers are read-only (enforced by the API, not just hidden in the UI) | Salary data is the most sensitive data HR holds; nobody should see it anonymously |
| 8 | **Excel export & import** — export exactly the filtered list as an .xlsx; import that same workbook (or a CSV) to create or update employees by email, all-or-nothing, with row-numbered errors | Gets HR off hand-maintained spreadsheets: data moves in and out of Excel without being mangled, and a bad file can't half-apply |

**Currency rule:** salaries are stored in the employee's local currency (the currency is derived
from the country, so it cannot be inconsistent). Cross-country totals are converted to USD with a
fixed, versioned rate table so results are reproducible.

## Deliberately left out (and why)

| Left out | Reason |
|----------|--------|
| SSO, user management screens, password reset | Two roles and seeded accounts are enough to show the access rules. A real rollout would sign in through the company's SSO rather than manage passwords here. |
| Salary history, audit trail, approval workflows | Valuable, but the brief is about managing current salaries and answering questions about them. The schema leaves room for a `salary_changes` table. |
| Payroll run, taxes, bonuses, equity | That's a payroll system, not salary management. |
| Live exchange rates | Static rates keep insight numbers stable and testable. Rates are in one config file. |
| Multiple sheets, formulas or custom layouts in imports | One fixed sheet layout (the export's) keeps validation simple and errors precise. |
| Org chart / managers, performance reviews | Not needed to answer pay questions. |

## Non-functional requirements
- List and insight endpoints respond in well under 300 ms on 10k rows (indexed queries, SQL aggregates, no N+1).
- Seeding 10k employees takes seconds, not minutes (bulk insert). Importing or exporting all 10k rows takes seconds.
- Every API endpoint requires a signed-in user; writes require the HR Manager role.
- Fast, deterministic tests for domain logic, API and key UI behaviour.
- Deployed and usable from a browser; works on a laptop screen first, usable on tablet.

## Success criteria
The HR manager can find any employee in seconds, correct a salary with confidence that bad input is
rejected, move data in and out of Excel without breaking it, and answer the questions above from the
Insights page. Nobody can see salaries without signing in, and viewers can't change them.
