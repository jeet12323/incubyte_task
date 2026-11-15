import { screen, waitFor, within } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { describe, expect, it, vi } from 'vitest'
import { buildEmployee, meta } from '../test/fixtures'
import { jsonResponse, renderWithProviders } from '../test/render'
import { EmployeesPage } from './EmployeesPage'

const employees = [
  buildEmployee(),
  buildEmployee({ id: 2, full_name: 'John Smith', email: 'john@acme.example', country_code: 'US', country_name: 'United States', currency: 'USD', salary: 120000, salary_usd: 120000 }),
]

function mockApi(listResponse = { data: employees, meta: { page: 1, per_page: 25, total_count: 2, total_pages: 1 } }) {
  return vi.spyOn(globalThis, 'fetch').mockImplementation(async (input, init) => {
    const url = String(input)
    if (url.startsWith('/api/v1/meta')) return jsonResponse({ data: meta })
    if (init?.method === 'DELETE') return jsonResponse(null, 204)
    return jsonResponse(listResponse)
  })
}

function requestedUrls(fetchMock: ReturnType<typeof mockApi>) {
  return fetchMock.mock.calls.map(([input]) => String(input))
}

describe('EmployeesPage', () => {
  it('lists employees with local and USD salaries', async () => {
    mockApi()
    renderWithProviders(<EmployeesPage />)

    expect(await screen.findByText('Priya Sharma')).toBeInTheDocument()
    expect(screen.getByText('2 employees')).toBeInTheDocument()
    expect(screen.getByText('₹25,00,000')).toBeInTheDocument()
    expect(screen.getByText('≈ $30,000')).toBeInTheDocument()
  })

  it('reads filters from the URL and sends them to the API', async () => {
    const fetchMock = mockApi()
    renderWithProviders(<EmployeesPage />, { route: '/employees?country=IN&sort=salary&direction=desc&page=2' })

    await screen.findByText('Priya Sharma')

    expect(requestedUrls(fetchMock)).toContain(
      '/api/v1/employees?country=IN&sort=salary&direction=desc&page=2&per_page=25',
    )
  })

  it('re-queries sorted by salary when the header is clicked', async () => {
    const fetchMock = mockApi()
    const user = userEvent.setup()
    renderWithProviders(<EmployeesPage />)
    await screen.findByText('Priya Sharma')

    await user.click(screen.getByRole('button', { name: /Annual salary/ }))

    await waitFor(() =>
      expect(requestedUrls(fetchMock)).toContain('/api/v1/employees?sort=salary&direction=asc&page=1&per_page=25'),
    )
  })

  it('searches after the user stops typing', async () => {
    const fetchMock = mockApi()
    const user = userEvent.setup()
    renderWithProviders(<EmployeesPage />)
    await screen.findByText('Priya Sharma')

    await user.type(screen.getByRole('textbox', { name: 'Search employees' }), 'smith')

    await waitFor(() => expect(requestedUrls(fetchMock).some((url) => url.includes('q=smith'))).toBe(true))
    expect(requestedUrls(fetchMock).some((url) => url.includes('q=s&'))).toBe(false)
  })

  it('shows an empty state when nothing matches', async () => {
    mockApi({ data: [], meta: { page: 1, per_page: 25, total_count: 0, total_pages: 0 } })
    renderWithProviders(<EmployeesPage />)

    expect(await screen.findByText('No employees match these filters.')).toBeInTheDocument()
  })

  it('asks for confirmation and then deletes the employee', async () => {
    const fetchMock = mockApi()
    const user = userEvent.setup()
    renderWithProviders(<EmployeesPage />)
    await screen.findByText('Priya Sharma')

    await user.click(screen.getByRole('button', { name: 'Delete Priya Sharma' }))
    const dialog = await screen.findByRole('dialog', { name: 'Delete employee?' })
    await user.click(within(dialog).getByRole('button', { name: 'Delete' }))

    await waitFor(() =>
      expect(fetchMock).toHaveBeenCalledWith('/api/v1/employees/1', expect.objectContaining({ method: 'DELETE' })),
    )
  })
})
