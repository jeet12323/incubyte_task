import { screen } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { describe, expect, it, vi } from 'vitest'
import { meta } from '../test/fixtures'
import { jsonResponse, renderWithProviders } from '../test/render'
import { InsightsPage } from './InsightsPage'

const stats = { min_salary: 1000000, max_salary: 6000000, avg_salary: 2450000, median_salary: 1500000 }

function mockApi() {
  return vi.spyOn(globalThis, 'fetch').mockImplementation(async (input) => {
    const url = String(input)
    if (url.endsWith('/meta')) return jsonResponse({ data: meta })
    if (url.endsWith('/insights/summary')) return jsonResponse({ data: { headcount: 10000, countries: 8, total_payroll_usd: 766136897 } })
    if (url.endsWith('/insights/countries'))
      return jsonResponse({
        data: [
          { country_code: 'IN', country_name: 'India', currency: 'INR', headcount: 4, ...stats, total_payroll_usd: 117600, avg_salary_usd: 29400 },
          { country_code: 'US', country_name: 'United States', currency: 'USD', headcount: 2, min_salary: 100000, max_salary: 140000, avg_salary: 120000, median_salary: 120000, total_payroll_usd: 240000, avg_salary_usd: 120000 },
        ],
      })
    if (url.includes('/countries/IN/job_titles'))
      return jsonResponse({ data: [{ job_title: 'Software Engineer', currency: 'INR', headcount: 3, ...stats }] })
    if (url.includes('/countries/US/job_titles'))
      return jsonResponse({ data: [{ job_title: 'Product Manager', currency: 'USD', headcount: 2, min_salary: 100000, max_salary: 140000, avg_salary: 120000, median_salary: 120000 }] })
    return jsonResponse({ data: [] })
  })
}

describe('InsightsPage', () => {
  it('shows org-wide summary figures', async () => {
    mockApi()
    renderWithProviders(<InsightsPage />)

    expect(await screen.findByText('10,000')).toBeInTheDocument()
    expect(screen.getByText('$766.1M')).toBeInTheDocument()
  })

  it('labels converted figures and lists the fixed rates behind them', async () => {
    mockApi()
    renderWithProviders(<InsightsPage />)

    expect(await screen.findByText('Annual payroll (USD, converted)')).toBeInTheDocument()
    expect(await screen.findByText(/Fixed rates as of 1 Nov 2026/)).toBeInTheDocument()
    expect(screen.getByText('1 INR = 0.012 USD')).toBeInTheDocument()
    expect(screen.queryByText(/1 USD =/)).not.toBeInTheDocument()
  })

  it('shows per-country stats in local currency', async () => {
    mockApi()
    renderWithProviders(<InsightsPage />)

    expect(await screen.findByRole('row', { name: /India/ })).toBeInTheDocument()
    expect(screen.getByText('₹15,00,000')).toBeInTheDocument()
  })

  it('drills into job titles for the largest country, then for a clicked country', async () => {
    const fetchMock = mockApi()
    const user = userEvent.setup()
    renderWithProviders(<InsightsPage />)

    expect(await screen.findByText('Software Engineer')).toBeInTheDocument()

    await user.click(screen.getByRole('row', { name: /United States/ }))

    expect(await screen.findByText('Product Manager')).toBeInTheDocument()
    expect(fetchMock).toHaveBeenCalledWith('/api/v1/insights/countries/US/job_titles', expect.any(Object))
  })
})
