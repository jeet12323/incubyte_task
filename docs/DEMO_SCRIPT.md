# Demo script (~4 minutes)

1. **Problem (20s).** HR manages salaries for 10,000 people in 8 countries in Excel. Goal: keep the
   records correct and answer "how do we pay people?"
2. **Employees (60s).**
   - 10,000 employees load right away (server-side paging).
   - Filter Country = India, sort by Annual salary descending, and point at the local currency
     (lakh format) with the USD equivalent under it.
   - Search "sharma". Copy the URL into a new tab and the same view opens (filters are in the URL).
3. **Edit a salary (45s).**
   - Edit an employee and change the salary. The label shows the currency of the selected country.
   - Try an existing email: the server rejects it and the error shows next to the field.
   - Try a future hire date: blocked on the client.
   - Add a new employee with a new job title (Autocomplete accepts new titles), then delete them
     (confirmation dialog).
4. **Insights (60s).**
   - Summary: headcount, countries, annual payroll in USD.
   - Pay by country: medians in local currency. Click Germany to drill into job titles.
   - "What does a Senior Software Engineer earn in India?" Read min / median / max.
   - Payroll by department chart.
5. **Engineering (45s).** Requirements doc, commit history, `rspec` + `npm test` running in a
   few seconds, the SQL-aggregate insights, the deterministic seeder, one Docker image on Render.
