# Demo script (~5 minutes)

1. **Problem (20s).** HR manages salaries for 10,000 people in 8 countries in Excel. Goal: keep the
   records correct and answer "how do we pay people?"
2. **Sign in (20s).** Open the app: there's no data until you sign in. Click `hr@acme.test` in the demo
   accounts box and sign in. Point at the name and the "HR Manager" badge.
3. **Employees (60s).**
   - 10,000 employees load right away (server-side paging).
   - Filter Country = India, sort by Annual salary descending, and point at the local currency
     (lakh format) with the USD equivalent under it.
   - Search "sharma". Copy the URL into a new tab and the same view opens (filters are in the URL).
4. **Edit a salary (45s).**
   - Edit an employee and change the salary. The label shows the currency of the selected country.
   - Try an existing email: the server rejects it and the error shows next to the field.
   - Try a future hire date: blocked on the client.
   - Add a new employee with a new job title (Autocomplete accepts new titles), then delete them
     (confirmation dialog).
5. **Excel round trip (60s).**
   - With the India filter on, click **Export to Excel** and open the file: only the filtered rows, in
     the same order, with readable columns, a frozen header and dates as YYYY-MM-DD.
   - Change one salary, break another (type `abc`), save, and **Import from Excel**: nothing is saved,
     and the dialog lists the broken row by its Excel row number.
   - Fix it and import again: "0 added, 1 updated, … unchanged".
6. **Insights (50s).**
   - Summary: headcount, countries, annual payroll in USD.
   - Pay by country: medians in local currency. Click Germany to drill into job titles.
   - "What does a Senior Software Engineer earn in India?" Read min / median / max.
   - Payroll by department chart.
7. **Roles (20s).** Sign out and sign in as `viewer@acme.test`: the same data, but no Add, Edit, Delete
   or Import. Export to Excel still works. (The API returns 403 too, not just the UI.)
8. **Engineering (45s).** Requirements doc, commit history, `rspec` + `npm test` running in seconds,
   the SQL-aggregate insights, the all-or-nothing import, the deterministic seeder, one Docker image on
   Render.
