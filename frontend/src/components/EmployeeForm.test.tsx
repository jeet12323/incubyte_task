import { screen } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { describe, expect, it, vi } from 'vitest'
import { ApiError } from '../api/client'
import { buildEmployee, meta } from '../test/fixtures'
import { renderWithProviders } from '../test/render'
import { EmployeeForm } from './EmployeeForm'

function renderForm(props: Partial<Parameters<typeof EmployeeForm>[0]> = {}) {
  const onSubmit = props.onSubmit ?? vi.fn().mockResolvedValue(undefined)
  renderWithProviders(<EmployeeForm meta={meta} onSubmit={onSubmit} onCancel={vi.fn()} {...props} />)
  return { onSubmit, user: userEvent.setup() }
}

async function pickOption(user: ReturnType<typeof userEvent.setup>, label: string, option: string) {
  await user.click(screen.getByRole('textbox', { name: label }))
  await user.click(await screen.findByRole('option', { name: option }))
}

describe('EmployeeForm', () => {
  it('shows validation messages and does not submit an empty form', async () => {
    const { onSubmit, user } = renderForm()

    await user.click(screen.getByRole('button', { name: 'Add employee' }))

    expect(screen.getByText('Name is required')).toBeInTheDocument()
    expect(screen.getByText('Enter a valid email')).toBeInTheDocument()
    expect(screen.getByText('Salary must be greater than 0')).toBeInTheDocument()
    expect(onSubmit).not.toHaveBeenCalled()
  })

  it('submits a complete employee with a numeric salary', async () => {
    const { onSubmit, user } = renderForm()

    await user.type(screen.getByRole('textbox', { name: 'Full name' }), 'Ana Lima')
    await user.type(screen.getByRole('textbox', { name: 'Email' }), 'ana@acme.example')
    await user.type(screen.getByRole('textbox', { name: 'Job title' }), 'Data Analyst')
    await pickOption(user, 'Department', 'Engineering')
    await pickOption(user, 'Country', 'India')
    await user.type(screen.getByRole('textbox', { name: /Annual salary/ }), '1800000')
    await user.type(screen.getByLabelText(/Hire date/), '2024-03-01')
    await user.click(screen.getByRole('button', { name: 'Add employee' }))

    expect(onSubmit).toHaveBeenCalledWith({
      full_name: 'Ana Lima',
      email: 'ana@acme.example',
      job_title: 'Data Analyst',
      department: 'Engineering',
      country_code: 'IN',
      salary: 1800000,
      employment_type: 'full_time',
      hire_date: '2024-03-01',
    })
  })

  it("labels the salary with the selected country's currency", async () => {
    renderForm({ employee: buildEmployee({ country_code: 'IN' }) })

    expect(screen.getByRole('textbox', { name: 'Annual salary (INR)' })).toBeInTheDocument()
  })

  it('pre-fills values when editing', () => {
    renderForm({ employee: buildEmployee() })

    expect(screen.getByRole('textbox', { name: 'Full name' })).toHaveValue('Priya Sharma')
    expect(screen.getByRole('button', { name: 'Save changes' })).toBeInTheDocument()
  })

  it('shows server-side field errors next to the field', async () => {
    const onSubmit = vi.fn().mockRejectedValue(new ApiError(422, 'invalid', { email: ['has already been taken'] }))
    const { user } = renderForm({ employee: buildEmployee(), onSubmit })

    await user.click(screen.getByRole('button', { name: 'Save changes' }))

    expect(await screen.findByText('has already been taken')).toBeInTheDocument()
  })
})
