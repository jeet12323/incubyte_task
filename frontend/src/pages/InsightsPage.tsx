import { Alert, Card, Group, Loader, Paper, Select, SimpleGrid, Stack, Table, Text, Title } from '@mantine/core'
import { BarChart } from '@mantine/charts'
import { useState } from 'react'
import { useCountryInsights, useDepartmentInsights, useJobTitleInsights, useSummary } from '../api/hooks'
import type { CountryInsight } from '../api/types'
import { formatCompactUsd, formatMoney, formatNumber } from '../lib/format'

function StatCard({ label, value }: { label: string; value: string | undefined }) {
  return (
    <Card withBorder padding="md">
      <Text size="xs" c="dimmed" tt="uppercase" fw={700}>
        {label}
      </Text>
      <Text size="xl" fw={700} mt={4}>
        {value ?? '—'}
      </Text>
    </Card>
  )
}

function Section({ title, description, children }: { title: string; description: string; children: React.ReactNode }) {
  return (
    <Paper withBorder p="md">
      <Title order={4}>{title}</Title>
      <Text size="sm" c="dimmed" mb="md">
        {description}
      </Text>
      {children}
    </Paper>
  )
}

function QueryState({ isPending, error }: { isPending: boolean; error: Error | null }) {
  if (error) return <Alert color="red">{error.message}</Alert>
  if (isPending) return <Loader size="sm" />
  return null
}

export function InsightsPage() {
  const summary = useSummary()
  const countries = useCountryInsights()
  const departments = useDepartmentInsights()
  const [selectedCountry, setSelectedCountry] = useState<string | null>(null)
  // Default the drill-down to the largest country once data arrives.
  const countryCode = selectedCountry ?? countries.data?.[0]?.country_code ?? null
  const jobTitles = useJobTitleInsights(countryCode)

  return (
    <Stack gap="lg">
      <div>
        <Title order={2}>Salary insights</Title>
        <Text c="dimmed" size="sm">
          Local-currency figures stay in each country's currency. Totals across countries are converted to USD at fixed
          rates.
        </Text>
      </div>

      <SimpleGrid cols={{ base: 1, sm: 3 }}>
        <StatCard label="Headcount" value={summary.data && formatNumber(summary.data.headcount)} />
        <StatCard label="Countries" value={summary.data && formatNumber(summary.data.countries)} />
        <StatCard label="Annual payroll (USD)" value={summary.data && formatCompactUsd(summary.data.total_payroll_usd)} />
      </SimpleGrid>

      <Section title="Pay by country" description="How much people earn in each country. Click a row to see job titles.">
        <QueryState isPending={countries.isPending} error={countries.error} />
        {countries.data && (
          <CountryTable rows={countries.data} selected={countryCode} onSelect={setSelectedCountry} />
        )}
      </Section>

      <Section title="Pay by job title" description="Benchmark a role against peers in the same country.">
        <Select
          aria-label="Country for job titles"
          data={countries.data?.map((c) => ({ value: c.country_code, label: c.country_name })) ?? []}
          value={countryCode}
          onChange={setSelectedCountry}
          allowDeselect={false}
          w={240}
          mb="md"
        />
        <QueryState isPending={jobTitles.isPending && Boolean(countryCode)} error={jobTitles.error} />
        {jobTitles.data && (
          <Table.ScrollContainer minWidth={640}>
            <Table striped>
              <Table.Thead>
                <Table.Tr>
                  <Table.Th>Job title</Table.Th>
                  <Table.Th ta="right">Headcount</Table.Th>
                  <Table.Th ta="right">Min</Table.Th>
                  <Table.Th ta="right">Median</Table.Th>
                  <Table.Th ta="right">Average</Table.Th>
                  <Table.Th ta="right">Max</Table.Th>
                </Table.Tr>
              </Table.Thead>
              <Table.Tbody>
                {jobTitles.data.map((row) => (
                  <Table.Tr key={row.job_title}>
                    <Table.Td>{row.job_title}</Table.Td>
                    <Table.Td ta="right">{formatNumber(row.headcount)}</Table.Td>
                    <Table.Td ta="right">{formatMoney(row.min_salary, row.currency)}</Table.Td>
                    <Table.Td ta="right">{formatMoney(row.median_salary, row.currency)}</Table.Td>
                    <Table.Td ta="right">{formatMoney(row.avg_salary, row.currency)}</Table.Td>
                    <Table.Td ta="right">{formatMoney(row.max_salary, row.currency)}</Table.Td>
                  </Table.Tr>
                ))}
              </Table.Tbody>
            </Table>
          </Table.ScrollContainer>
        )}
      </Section>

      <Section title="Payroll by department" description="Annual payroll cost per department, in USD.">
        <QueryState isPending={departments.isPending} error={departments.error} />
        {departments.data && (
          <BarChart
            h={320}
            data={departments.data}
            dataKey="department"
            series={[{ name: 'total_payroll_usd', label: 'Payroll (USD)', color: 'indigo.6' }]}
            valueFormatter={formatCompactUsd}
            tickLine="y"
            xAxisProps={{ interval: 0, angle: -20, textAnchor: 'end', height: 60 }}
          />
        )}
      </Section>
    </Stack>
  )
}

function CountryTable({
  rows,
  selected,
  onSelect,
}: {
  rows: CountryInsight[]
  selected: string | null
  onSelect: (code: string) => void
}) {
  return (
    <Table.ScrollContainer minWidth={760}>
      <Table highlightOnHover>
        <Table.Thead>
          <Table.Tr>
            <Table.Th>Country</Table.Th>
            <Table.Th ta="right">Headcount</Table.Th>
            <Table.Th ta="right">Median</Table.Th>
            <Table.Th ta="right">Average</Table.Th>
            <Table.Th ta="right">Range</Table.Th>
            <Table.Th ta="right">Payroll (USD)</Table.Th>
          </Table.Tr>
        </Table.Thead>
        <Table.Tbody>
          {rows.map((row) => (
            <Table.Tr
              key={row.country_code}
              onClick={() => onSelect(row.country_code)}
              bg={row.country_code === selected ? 'var(--mantine-primary-color-light)' : undefined}
              style={{ cursor: 'pointer' }}
            >
              <Table.Td>
                <Group gap={6}>
                  <Text size="sm" fw={500}>
                    {row.country_name}
                  </Text>
                  <Text size="xs" c="dimmed">
                    {row.currency}
                  </Text>
                </Group>
              </Table.Td>
              <Table.Td ta="right">{formatNumber(row.headcount)}</Table.Td>
              <Table.Td ta="right">{formatMoney(row.median_salary, row.currency)}</Table.Td>
              <Table.Td ta="right">{formatMoney(row.avg_salary, row.currency)}</Table.Td>
              <Table.Td ta="right">
                {formatMoney(row.min_salary, row.currency)} – {formatMoney(row.max_salary, row.currency)}
              </Table.Td>
              <Table.Td ta="right">{formatCompactUsd(row.total_payroll_usd)}</Table.Td>
            </Table.Tr>
          ))}
        </Table.Tbody>
      </Table>
    </Table.ScrollContainer>
  )
}
