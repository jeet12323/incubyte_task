# How I used AI

I built this with **Claude Code**, an agentic coding assistant. I used it as a fast pair: I owned
the product decisions, the scope and the quality bar, and it did most of the typing. Nothing was
committed until it passed the tests and linters and I had seen it work in the running app.

## Ground rules I set for the agent

1. **Plan before code.** The first prompt asked for requirements, architecture, a test strategy and
   a commit plan, and told the agent to ask instead of assuming anything that changes the design.
2. **Specs first, small slices.** Each slice was: write the spec, implement, run the full suite and
   RuboCop/ESLint, then commit. The git log follows that order: model → search → CRUD API →
   insights → seeder → UI → deploy.
3. **Commits tell the story.** One logical change per commit, with a message that explains *why*.
   Fixes found later get their own commit instead of rewriting history.
4. **Green tests aren't proof.** Every feature was also checked by hand in the browser on the full
   10k dataset, including each role, a mobile width, and real Excel for the import/export.
5. **Clarify, then document.** Open product questions went to Incubyte. The answers are recorded in
   [REQUIREMENTS.md](REQUIREMENTS.md), and the code was changed to match them.

## Key decisions and how I steered them

| Moment | My direction | Result |
|--------|--------------|--------|
| Start | Plan first: one-page requirements, architecture, test strategy, commit sequence. Rails 8 API + PostgreSQL + React, deployed on Render as one service | Requirements doc committed before any code. One Docker image, no CORS |
| Data model | A salary is in the employee's local currency, and an employee must never have a currency that doesn't match their country | Currency is derived from the country, never stored separately. Cross-country totals use a fixed, dated USD rate table so they're reproducible |
| Insights | Specs with numbers small enough to check by hand, including the median of an even-sized group. Aggregates in SQL only | `percentile_cont` median, no Ruby loops over 10k rows, every endpoint well under 300 ms |
| Seed | 10k employees that look real (pay by role and country, local names), repeatable, fast | Fixed random seed, bulk insert, about 10 s on Render |
| Scope review | After v1 I moved auth/roles and Excel import/export from "left out" into scope: salary data shouldn't be visible without signing in, and HR needs a way off Excel | Session cookie, HR Manager vs read-only Viewer enforced in the API, all-or-nothing import. Requirements updated first, then code |
| Real-world test | Opening the CSV export in Excel and saving it changed the dates (`12-12-2025`), so the import rejected the file. I asked for export and import to use exactly the same format | Switched to a real `.xlsx` with date cells and preset column widths, with one column definition shared by export and import. The round trip on 10,001 rows comes back unchanged |
| CI | I checked GitHub Actions and asked for the failing pipeline to be fixed properly, not patched | Three Linux-only causes fixed (see below). The same fixes stopped the Render image failing |
| Clarifications | I sent Incubyte the open questions, with my assumption for each | All assumptions confirmed. Converted values now say "USD, converted", and the rates and their date are shown in the app |
| Commits | Commits carry only my identity, and history is kept honest | Every commit is authored by me. Mistakes stay visible as follow-up fixes |

## Representative prompts (condensed)

> Build salary management for an HR manager with 10,000 employees across countries. [brief]
> Plan first: requirements, architecture, test strategy, commit sequence. Ask before assuming
> anything that changes the design.

> Salaries are in local currency. Make an employee with the wrong currency for their country
> impossible, and keep cross-country totals reproducible.

> Write the SalaryInsights spec with hand-checkable numbers, including the median of an even-sized
> group, then implement it with SQL aggregates only.

> Auth/roles and import/export are in "left out", but I think both belong: salary data shouldn't be
> visible without signing in, and HR needs a way off Excel. Add them if feasible and update the
> docs, not just the code.

> The file I export and the file I import end up in different formats: Excel rewrote the dates.
> Make them the same format, size the date column so nobody has to widen it, and commit in
> steps that can each be justified.

> CI is failing on GitHub. Find the root cause instead of skipping the step.

## What review caught (and what changed)

Agent output was treated like a pull request from a fast teammate: useful, but checked.

| Issue | How it was caught | Fix |
|-------|-------------------|-----|
| `rails new --skip-git` creates no `.gitignore`, so `config/master.key` would have been committed | Reviewing `git ls-files` before the first push | Removed from history before it was ever pushed, key rotated, `.gitignore` added. Production reads `SECRET_KEY_BASE` from the environment |
| CSV export didn't survive Excel: dates rewritten, the date column showed `####` | A manual round trip in real Excel. The automated tests passed because they never went through Excel | Real `.xlsx` with date cells and widths. CSV still accepted, with an error that explains the cause |
| CI failed on Linux: bin scripts lacked the executable bit, had a Windows-only `ruby.exe` shebang, and the Vite config used `process` without Node types | Reading the GitHub Actions logs | Mode 100755, portable shebang, `@types/node`. Lesson: run the exact CI commands locally, including `npm run build` |
| Signing out crashed to a blank page | Using the app. No test covered sign-out | The user is provided through React context, and sign-out clears the session before cached data. Added a regression test |
| A "signed-out" test was actually signed in, because of a test-helper default | That test failed | Explicit `'from-server'` option in the helper |
| Header and import dialog overflowed on a phone | Checked at 375 px width | Compact header on small screens, plain text instead of a list |
| Job title picker used a hack to allow new values | Code review | Replaced with `Autocomplete` |
| Charting library pushed the main bundle past 500 kB | Vite build warning | Lazy-loaded the Insights page |
| Ruby 3.4-only syntax on Ruby 3.3, and specs relying on an inferred `type:` | Failing specs | Explicit block parameter and `type: :request`, Ruby version pinned |

## Product observation from using the data

Part-time salaries are stored pro-rated, so they pull down the minimum of a role's range (e.g. a
Sales Manager minimum well below the median). The median holds up against this, which is why it
is shown next to the average. A next step is an "FTE-adjusted" toggle or a full-time-only filter on
Insights. See the follow-ups in [DESIGN.md](DESIGN.md).
