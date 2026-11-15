import { Autocomplete, Button, Group, NumberInput, Select, Stack, TextInput } from '@mantine/core'
import { useForm } from '@mantine/form'
import { useState } from 'react'
import { ApiError } from '../api/client'
import type { Employee, EmployeeInput, Meta } from '../api/types'
import { EMPLOYMENT_TYPE_LABELS } from '../lib/format'

interface Props {
  meta: Meta
  employee?: Employee
  onSubmit: (input: EmployeeInput) => Promise<unknown>
  onCancel: () => void
}

type FormValues = Omit<EmployeeInput, 'salary'> & { salary: number | '' }

const EMPTY_VALUES: FormValues = {
  full_name: '',
  email: '',
  job_title: '',
  department: '',
  country_code: '',
  salary: '',
  employment_type: 'full_time',
  hire_date: '',
}

function today() {
  return new Date().toISOString().slice(0, 10)
}

export function EmployeeForm({ meta, employee, onSubmit, onCancel }: Props) {
  const [submitting, setSubmitting] = useState(false)
  const form = useForm<FormValues>({
    mode: 'controlled',
    initialValues: employee ? pickInput(employee) : EMPTY_VALUES,
    validate: {
      full_name: (v) => (v.trim() ? null : 'Name is required'),
      email: (v) => (/^\S+@\S+\.\S+$/.test(v.trim()) ? null : 'Enter a valid email'),
      job_title: (v) => (v.trim() ? null : 'Job title is required'),
      department: (v) => (v ? null : 'Pick a department'),
      country_code: (v) => (v ? null : 'Pick a country'),
      salary: (v) => (typeof v === 'number' && v > 0 ? null : 'Salary must be greater than 0'),
      hire_date: (v) => {
        if (!v) return 'Hire date is required'
        return v > today() ? "Hire date can't be in the future" : null
      },
    },
  })

  const currency = meta.countries.find((c) => c.code === form.values.country_code)?.currency

  const handleSubmit = form.onSubmit(async (values) => {
    setSubmitting(true)
    try {
      await onSubmit({ ...values, salary: Number(values.salary) })
    } catch (error) {
      // Show server-side validation (e.g. duplicate email) next to the matching field.
      if (error instanceof ApiError) {
        form.setErrors(Object.fromEntries(Object.entries(error.fieldErrors).map(([field, msgs]) => [field, msgs[0]])))
      }
    } finally {
      setSubmitting(false)
    }
  })

  return (
    <form onSubmit={handleSubmit} noValidate>
      <Stack gap="sm">
        <TextInput label="Full name" withAsterisk {...form.getInputProps('full_name')} />
        <TextInput label="Email" type="email" withAsterisk {...form.getInputProps('email')} />
        {/* Suggests existing titles but still allows a new one. */}
        <Autocomplete label="Job title" withAsterisk data={meta.job_titles} {...form.getInputProps('job_title')} />
        <Select label="Department" withAsterisk data={meta.departments} {...form.getInputProps('department')} />
        <Select
          label="Country"
          withAsterisk
          searchable
          data={meta.countries.map((c) => ({ value: c.code, label: c.name }))}
          {...form.getInputProps('country_code')}
        />
        <NumberInput
          label={currency ? `Annual salary (${currency})` : 'Annual salary'}
          description="In the employee's local currency"
          withAsterisk
          min={0}
          thousandSeparator=","
          allowNegative={false}
          {...form.getInputProps('salary')}
        />
        <Select
          label="Employment type"
          withAsterisk
          data={meta.employment_types.map((t) => ({ value: t, label: EMPLOYMENT_TYPE_LABELS[t] }))}
          {...form.getInputProps('employment_type')}
        />
        <TextInput label="Hire date" type="date" max={today()} withAsterisk {...form.getInputProps('hire_date')} />

        <Group justify="flex-end" mt="md">
          <Button variant="default" onClick={onCancel}>
            Cancel
          </Button>
          <Button type="submit" loading={submitting}>
            {employee ? 'Save changes' : 'Add employee'}
          </Button>
        </Group>
      </Stack>
    </form>
  )
}

function pickInput(employee: Employee): FormValues {
  const { full_name, email, job_title, department, country_code, salary, employment_type, hire_date } = employee
  return { full_name, email, job_title, department, country_code, salary, employment_type, hire_date }
}
