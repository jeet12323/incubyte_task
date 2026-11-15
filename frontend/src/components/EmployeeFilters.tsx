import { Button, Group, Select, TextInput } from '@mantine/core'
import { useDebouncedCallback } from '@mantine/hooks'
import { IconSearch } from '@tabler/icons-react'
import { useEffect, useState } from 'react'
import type { Meta } from '../api/types'

export interface FilterValues {
  q: string
  country: string
  department: string
  job_title: string
}

interface Props {
  meta?: Meta
  values: FilterValues
  onChange: (changes: Partial<FilterValues>) => void
}

export function EmployeeFilters({ meta, values, onChange }: Props) {
  // Local state keeps typing snappy; the search request fires once typing pauses.
  const [search, setSearch] = useState(values.q)
  const debouncedSearch = useDebouncedCallback((q: string) => onChange({ q }), 300)

  useEffect(() => setSearch(values.q), [values.q])

  const hasFilters = Object.values(values).some(Boolean)

  return (
    <Group align="flex-end" gap="sm" wrap="wrap">
      <TextInput
        aria-label="Search employees"
        placeholder="Search name or email"
        leftSection={<IconSearch size={16} />}
        value={search}
        onChange={(event) => {
          setSearch(event.currentTarget.value)
          debouncedSearch(event.currentTarget.value)
        }}
        w={{ base: '100%', sm: 260 }}
      />
      <Select
        aria-label="Country"
        placeholder="All countries"
        clearable
        searchable
        data={meta?.countries.map((c) => ({ value: c.code, label: c.name })) ?? []}
        value={values.country || null}
        onChange={(country) => onChange({ country: country ?? '' })}
        w={{ base: '100%', sm: 180 }}
      />
      <Select
        aria-label="Department"
        placeholder="All departments"
        clearable
        data={meta?.departments ?? []}
        value={values.department || null}
        onChange={(department) => onChange({ department: department ?? '' })}
        w={{ base: '100%', sm: 190 }}
      />
      <Select
        aria-label="Job title"
        placeholder="All job titles"
        clearable
        searchable
        data={meta?.job_titles ?? []}
        value={values.job_title || null}
        onChange={(jobTitle) => onChange({ job_title: jobTitle ?? '' })}
        w={{ base: '100%', sm: 240 }}
      />
      {hasFilters && (
        <Button
          variant="subtle"
          onClick={() => {
            setSearch('')
            onChange({ q: '', country: '', department: '', job_title: '' })
          }}
        >
          Clear filters
        </Button>
      )}
    </Group>
  )
}
