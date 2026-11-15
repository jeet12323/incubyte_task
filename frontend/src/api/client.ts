import type {
  CountryInsight,
  DepartmentInsight,
  Employee,
  EmployeeInput,
  EmployeeQuery,
  JobTitleInsight,
  Meta,
  PageMeta,
  Summary,
} from './types'

export type FieldErrors = Record<string, string[]>

export class ApiError extends Error {
  readonly status: number
  readonly fieldErrors: FieldErrors

  constructor(status: number, message: string, fieldErrors: FieldErrors = {}) {
    super(message)
    this.name = 'ApiError'
    this.status = status
    this.fieldErrors = fieldErrors
  }
}

const BASE_PATH = '/api/v1'

/** Builds a query string, dropping empty values so URLs stay clean. */
export function toQueryString(params: object): string {
  const search = new URLSearchParams()
  Object.entries(params).forEach(([key, value]) => {
    if (value !== undefined && value !== null && value !== '') search.set(key, String(value))
  })
  const query = search.toString()
  return query ? `?${query}` : ''
}

async function request<T>(path: string, init: RequestInit = {}): Promise<T> {
  const response = await fetch(`${BASE_PATH}${path}`, {
    ...init,
    headers: { 'Content-Type': 'application/json', Accept: 'application/json', ...init.headers },
  })

  if (response.status === 204) return undefined as T

  const body = await response.json().catch(() => ({}))
  if (!response.ok) {
    const fieldErrors: FieldErrors = body.errors ?? {}
    const message = body.error ?? (Object.keys(fieldErrors).length ? 'Please fix the highlighted fields' : 'Something went wrong')
    throw new ApiError(response.status, message, fieldErrors)
  }
  return body as T
}

export const api = {
  listEmployees: (query: EmployeeQuery) =>
    request<{ data: Employee[]; meta: PageMeta }>(`/employees${toQueryString(query)}`),

  createEmployee: (input: EmployeeInput) =>
    request<{ data: Employee }>('/employees', { method: 'POST', body: JSON.stringify({ employee: input }) }),

  updateEmployee: (id: number, input: Partial<EmployeeInput>) =>
    request<{ data: Employee }>(`/employees/${id}`, { method: 'PATCH', body: JSON.stringify({ employee: input }) }),

  deleteEmployee: (id: number) => request<void>(`/employees/${id}`, { method: 'DELETE' }),

  meta: () => request<{ data: Meta }>('/meta'),

  summary: () => request<{ data: Summary }>('/insights/summary'),
  countryInsights: () => request<{ data: CountryInsight[] }>('/insights/countries'),
  jobTitleInsights: (countryCode: string) =>
    request<{ data: JobTitleInsight[] }>(`/insights/countries/${encodeURIComponent(countryCode)}/job_titles`),
  departmentInsights: () => request<{ data: DepartmentInsight[] }>('/insights/departments'),
}
