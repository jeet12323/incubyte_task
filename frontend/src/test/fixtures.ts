import type { Employee, Meta, User } from '../api/types'

export const hrManager: User = { id: 1, name: 'Hannah Reed', email: 'hr@acme.test', role: 'hr_manager', can_edit: true }
export const viewer: User = { id: 2, name: 'Victor Shah', email: 'viewer@acme.test', role: 'viewer', can_edit: false }

export const meta: Meta = {
  countries: [
    { code: 'IN', name: 'India', currency: 'INR' },
    { code: 'US', name: 'United States', currency: 'USD' },
  ],
  departments: ['Engineering', 'Sales'],
  employment_types: ['full_time', 'part_time', 'contract'],
  job_titles: ['Account Executive', 'Software Engineer'],
}

export function buildEmployee(overrides: Partial<Employee> = {}): Employee {
  return {
    id: 1,
    full_name: 'Priya Sharma',
    email: 'priya.sharma@acme.example',
    job_title: 'Software Engineer',
    department: 'Engineering',
    country_code: 'IN',
    country_name: 'India',
    currency: 'INR',
    salary: 2500000,
    salary_usd: 30000,
    employment_type: 'full_time',
    hire_date: '2022-04-11',
    updated_at: '2026-11-01T10:00:00Z',
    ...overrides,
  }
}
