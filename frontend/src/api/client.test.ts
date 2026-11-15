import { describe, expect, it, vi } from 'vitest'
import { jsonResponse } from '../test/render'
import { ApiError, api, toQueryString } from './client'

describe('toQueryString', () => {
  it('drops empty values', () => {
    expect(toQueryString({ q: '', country: 'IN', page: 2, department: undefined })).toBe('?country=IN&page=2')
  })

  it('returns an empty string when nothing is set', () => {
    expect(toQueryString({ q: '' })).toBe('')
  })
})

describe('api', () => {
  it('requests the versioned API with filters in the query string', async () => {
    const fetchMock = vi.spyOn(globalThis, 'fetch').mockResolvedValue(jsonResponse({ data: [], meta: {} }))

    await api.listEmployees({ country: 'IN', page: 1 })

    expect(fetchMock).toHaveBeenCalledWith('/api/v1/employees?country=IN&page=1', expect.any(Object))
  })

  it('wraps the payload under "employee" when creating', async () => {
    const fetchMock = vi.spyOn(globalThis, 'fetch').mockResolvedValue(jsonResponse({ data: {} }, 201))

    await api.createEmployee({ full_name: 'Ana' } as never)

    const [, init] = fetchMock.mock.calls[0]
    expect(init?.method).toBe('POST')
    expect(JSON.parse(String(init?.body))).toEqual({ employee: { full_name: 'Ana' } })
  })

  it('raises an ApiError carrying field errors on 422', async () => {
    vi.spyOn(globalThis, 'fetch').mockResolvedValue(jsonResponse({ errors: { email: ['has already been taken'] } }, 422))

    const error = await api.createEmployee({} as never).catch((e: unknown) => e)

    expect(error).toBeInstanceOf(ApiError)
    expect(error).toMatchObject({ status: 422, fieldErrors: { email: ['has already been taken'] } })
  })

  it('uses the server message for other errors', async () => {
    vi.spyOn(globalThis, 'fetch').mockResolvedValue(jsonResponse({ error: 'Employee not found' }, 404))

    await expect(api.deleteEmployee(1)).rejects.toThrow('Employee not found')
  })

  it('handles 204 No Content', async () => {
    vi.spyOn(globalThis, 'fetch').mockResolvedValue(jsonResponse(null, 204))

    await expect(api.deleteEmployee(1)).resolves.toBeUndefined()
  })
})
