export type EmploymentType = 'full_time' | 'part_time' | 'contract'

export interface Employee {
  id: number
  full_name: string
  email: string
  job_title: string
  department: string
  country_code: string
  country_name: string
  currency: string
  salary: number
  salary_usd: number
  employment_type: EmploymentType
  hire_date: string
  updated_at: string
}

export type EmployeeInput = Pick<
  Employee,
  'full_name' | 'email' | 'job_title' | 'department' | 'country_code' | 'salary' | 'employment_type' | 'hire_date'
>

export interface PageMeta {
  page: number
  per_page: number
  total_count: number
  total_pages: number
}

export interface EmployeeQuery {
  q?: string
  country?: string
  department?: string
  job_title?: string
  employment_type?: string
  sort?: string
  direction?: 'asc' | 'desc'
  page?: number
  per_page?: number
}

export interface CountryOption {
  code: string
  name: string
  currency: string
}

export interface Meta {
  countries: CountryOption[]
  departments: string[]
  employment_types: EmploymentType[]
  job_titles: string[]
}

export interface Summary {
  headcount: number
  countries: number
  total_payroll_usd: number
}

export interface SalaryStats {
  headcount: number
  min_salary: number
  max_salary: number
  avg_salary: number
  median_salary: number
}

export interface CountryInsight extends SalaryStats {
  country_code: string
  country_name: string
  currency: string
  total_payroll_usd: number
  avg_salary_usd: number
}

export interface JobTitleInsight extends SalaryStats {
  job_title: string
  currency: string
}

export interface DepartmentInsight {
  department: string
  headcount: number
  total_payroll_usd: number
  avg_salary_usd: number
}

export type Role = 'hr_manager' | 'viewer'

export interface User {
  id: number
  name: string
  email: string
  role: Role
  can_edit: boolean
}

export interface ImportRowError {
  row: number
  email: string
  messages: string[]
}

/** Result of a CSV import. When error_count > 0 nothing was saved. */
export interface ImportResult {
  created: number
  updated: number
  unchanged: number
  errors: ImportRowError[]
  error_count: number
}
