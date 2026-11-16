# How AI was used

This project was built with **Claude Code** (an agentic coding assistant) in a terminal and desktop
session. I made the product and design decisions. The agent wrote most of the code under my
direction. Every change went through tests, linting and a manual check in the browser before it
was committed.

## Workflow

1. **Requirements first.** I gave the agent the assessment brief and asked for a plan before any
   code. Before writing anything it asked me about the stack (Rails vs Node, because Ruby wasn't
   installed), the database (Postgres vs SQLite) and the host (Render). The one-page requirements
   doc was written and committed before the code.
2. **Small vertical slices, specs first.** Each slice was: write the spec, implement, run the suite,
   run RuboCop/ESLint, commit. The git log follows this order: model → search → CRUD API →
   insights → seeder → UI → deploy.
3. **Verify against the real thing.** After the unit tests passed I ran the app on the 10k seed and
   used it in a browser: filters, sorting, the add/edit drawer, the insights drill-down, sign-in as each
   role, a viewer's write attempt (403), and a full 10k export → import round trip. I also timed every
   endpoint and booted the app in production mode locally before writing the deploy config.

## Representative prompts

> Build employee salary management software for an HR manager at an org with 10,000 employees
> across countries. [full brief pasted] Plan first: requirements doc, architecture, test strategy,
> commit sequence. Ask before assuming anything that changes the design.

> Salaries are in local currency. Make it impossible for an employee to have a currency that
> doesn't match their country, and keep cross-country totals reproducible.

> Write the spec for SalaryInsights with numbers small enough to verify by hand, including the
> median for an even-sized group, then implement it with SQL aggregates only.

> Seed 10,000 employees that look real: role-based pay, country pay levels, locale-appropriate
> names, deterministic. It must be fast and re-runnable.

> Install the prerequisites yourself (Ruby, toolchain, dev database) without touching my
> existing Postgres credentials.

> Authentication/roles and CSV import/export were in "left out". I think both should be in: salary
> data shouldn't be visible without signing in, and HR needs a way off Excel. Add them if feasible and
> update everything.

That last prompt changed the scope after the first version was done. The agent agreed, and argued for
an httpOnly session cookie instead of a token, two roles enforced in the API, and an all-or-nothing
import. It then updated the requirements doc rather than only adding code.

## Where AI output was wrong or needed judgment (and what changed)

| Issue | How it was caught | Fix |
|-------|-------------------|-----|
| `rails new --skip-git` creates no `.gitignore`, so `config/master.key` and the bootsnap cache were committed | Reviewing `git ls-files` before writing the deploy config | Purged from the (never pushed) history, key rotated, `.gitignore` added. Production uses `SECRET_KEY_BASE` from the environment. |
| Used Ruby 3.4's `it` block parameter on Ruby 3.3 | Request specs failed | Explicit block parameter; pinned `.ruby-version` |
| Request specs assumed `type:` is inferred from the folder | Specs failed with `undefined method get` | Tagged `type: :request` explicitly |
| Job title used a `Select` with a hack to allow new values | Code review: brittle and confusing | Switched to `Autocomplete`, which suggests existing titles and accepts new ones |
| Employment-type badge truncated to "FULL…" | Seen in the browser, not by any test | Fixed the badge styles |
| Insight tests matched country names that also appear in the dropdown | Ambiguous-match failures | Scoped the queries to table rows (closer to what a user actually clicks) |
| Charting library pushed the main bundle past 500 kB | Vite build warning | Lazy-loaded the Insights page |
| Signing out crashed to a blank page: the cache was cleared while the header was still reading the user | Using the app in the browser (no test covered sign-out) | Signed-in user is provided through React context from the auth gate. Sign-out sets the session to null before dropping cached data. Added a sign-out test. |
| Excel's byte-order mark wasn't stripped: a shell one-liner turned the `\uFEFF` escape into a literal `?` | The BOM spec failed with "Missing columns: email" | Edited the file directly. The spec now guards it. |
| Test helper treated `user: undefined` as "use the default user", so the signed-out test was actually signed in | The signed-out test failed | Explicit `'from-server'` option |
| Header items wrapped below the bar on a phone; a list in the import dialog overflowed sideways | Checked at 375 px width in the browser | Icon-only sign-out and no role badge on small screens; replaced the list with plain text |
| CSV export didn't survive Excel: saving it rewrote hire dates in the local format (`12-12-2025`), and the date column showed `####` | I tried the round trip in real Excel. The tests passed because they never went through Excel | Switched export and import to a real `.xlsx` (date cells, column widths, one shared column definition). CSV import kept, with an error that explains the cause. |
| CI was red from the first push: bin scripts committed without the executable bit (exit 126), then a Windows-only `#!/usr/bin/env ruby.exe` shebang (exit 127), and the Vite config used `process` without Node types | Reading the GitHub Actions run. Local runs on Windows hid all three | Set mode 100755, portable `ruby` shebang, added `@types/node`. The same bin script fixes stop the Docker image failing on Render. Lesson: run the exact CI commands (`npm run build`, not only `tsc` and the tests). |
| Local Postgres needed a password the agent shouldn't handle | Auth failure | Started a separate, local-only dev cluster on port 5434 with trust auth. The system database and its credentials were left alone. |

## Product observation from using the data

Part-time salaries are stored pro-rated, so they pull down the minimum in a role's range (e.g. a
Sales Manager minimum well below the median). The median holds up against this, which is why it is
shown next to the average. A next step is an "FTE-adjusted" toggle or a full-time-only filter on
Insights. See the follow-ups in [DESIGN.md](DESIGN.md).
