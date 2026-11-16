import { screen } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { describe, expect, it, vi } from 'vitest'
import { jsonResponse, renderWithProviders } from '../test/render'
import { ImportEmployeesModal } from './ImportEmployeesModal'

async function uploadFile() {
  const user = userEvent.setup()
  const onClose = vi.fn()
  renderWithProviders(<ImportEmployeesModal opened onClose={onClose} />)
  const input = document.querySelector<HTMLInputElement>('input[type="file"]')!
  await user.upload(input, new File(['email,full_name\n'], 'employees.csv', { type: 'text/csv' }))
  await user.click(screen.getByRole('button', { name: 'Import' }))
  return { onClose }
}

describe('ImportEmployeesModal', () => {
  it('imports the file and closes when every row is valid', async () => {
    const fetchMock = vi
      .spyOn(globalThis, 'fetch')
      .mockResolvedValue(jsonResponse({ data: { created: 2, updated: 1, unchanged: 0, errors: [], error_count: 0 } }))

    const { onClose } = await uploadFile()

    await vi.waitFor(() => expect(onClose).toHaveBeenCalled())
    expect(fetchMock).toHaveBeenCalledWith('/api/v1/employees/import', expect.objectContaining({ method: 'POST' }))
  })

  it('lists the rows to fix when the import is rejected', async () => {
    const errors = [{ row: 3, email: 'bad@acme.test', messages: ['Salary must be a number', 'Full name is blank'] }]
    vi.spyOn(globalThis, 'fetch').mockResolvedValue(
      jsonResponse({ data: { created: 0, updated: 0, unchanged: 0, error_count: 1, errors } }, 422),
    )

    const { onClose } = await uploadFile()

    expect(await screen.findByText(/Nothing was imported: 1 row/)).toBeInTheDocument()
    const row = screen.getByRole('row', { name: /bad@acme.test/ })
    expect(row).toHaveTextContent('3')
    expect(row).toHaveTextContent('Salary must be a number; Full name is blank')
    expect(onClose).not.toHaveBeenCalled()
  })

  it('shows why a file could not be read', async () => {
    vi.spyOn(globalThis, 'fetch').mockResolvedValue(jsonResponse({ error: 'Missing columns: salary' }, 422))

    await uploadFile()

    expect(await screen.findByText('Missing columns: salary')).toBeInTheDocument()
  })
})
