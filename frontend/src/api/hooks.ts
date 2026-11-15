import { keepPreviousData, useMutation, useQuery, useQueryClient } from '@tanstack/react-query'
import { api } from './client'
import type { EmployeeInput, EmployeeQuery } from './types'

export const queryKeys = {
  employees: (query: EmployeeQuery) => ['employees', query] as const,
  meta: ['meta'] as const,
  insights: ['insights'] as const,
}

export function useEmployees(query: EmployeeQuery) {
  return useQuery({
    queryKey: queryKeys.employees(query),
    queryFn: () => api.listEmployees(query),
    // Keep the current page on screen while the next one loads, so the table doesn't flash.
    placeholderData: keepPreviousData,
  })
}

export function useMeta() {
  return useQuery({ queryKey: queryKeys.meta, queryFn: () => api.meta().then((r) => r.data), staleTime: 5 * 60_000 })
}

export function useSummary() {
  return useQuery({ queryKey: [...queryKeys.insights, 'summary'], queryFn: () => api.summary().then((r) => r.data) })
}

export function useCountryInsights() {
  return useQuery({
    queryKey: [...queryKeys.insights, 'countries'],
    queryFn: () => api.countryInsights().then((r) => r.data),
  })
}

export function useJobTitleInsights(countryCode: string | null) {
  return useQuery({
    queryKey: [...queryKeys.insights, 'job_titles', countryCode],
    queryFn: () => api.jobTitleInsights(countryCode!).then((r) => r.data),
    enabled: Boolean(countryCode),
  })
}

export function useDepartmentInsights() {
  return useQuery({
    queryKey: [...queryKeys.insights, 'departments'],
    queryFn: () => api.departmentInsights().then((r) => r.data),
  })
}

/** Any salary change invalidates the directory, insights and job title list together. */
function useInvalidateSalaryData() {
  const queryClient = useQueryClient()
  return () =>
    Promise.all([
      queryClient.invalidateQueries({ queryKey: ['employees'] }),
      queryClient.invalidateQueries({ queryKey: queryKeys.insights }),
      queryClient.invalidateQueries({ queryKey: queryKeys.meta }),
    ])
}

export function useSaveEmployee() {
  const invalidate = useInvalidateSalaryData()
  return useMutation({
    mutationFn: ({ id, input }: { id?: number; input: EmployeeInput }) =>
      id ? api.updateEmployee(id, input) : api.createEmployee(input),
    onSuccess: invalidate,
  })
}

export function useDeleteEmployee() {
  const invalidate = useInvalidateSalaryData()
  return useMutation({ mutationFn: (id: number) => api.deleteEmployee(id), onSuccess: invalidate })
}
