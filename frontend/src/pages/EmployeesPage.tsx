import { Alert, Button, Center, Drawer, Group, Loader, Modal, Pagination, Paper, Stack, Text, Title } from '@mantine/core'
import { notifications } from '@mantine/notifications'
import { IconDownload, IconPlus, IconUpload } from '@tabler/icons-react'
import { useState } from 'react'
import { useSearchParams } from 'react-router-dom'
import { api } from '../api/client'
import { useDeleteEmployee, useEmployees, useMeta, useSaveEmployee } from '../api/hooks'
import { useCurrentUser } from '../auth/currentUser'
import type { Employee, EmployeeQuery } from '../api/types'
import { EmployeeFilters, type FilterValues } from '../components/EmployeeFilters'
import { EmployeeForm } from '../components/EmployeeForm'
import { EmployeeTable, type SortState } from '../components/EmployeeTable'
import { ImportEmployeesModal } from '../components/ImportEmployeesModal'
import { formatNumber } from '../lib/format'

const PER_PAGE = 25

type EditorState = { mode: 'closed' } | { mode: 'create' } | { mode: 'edit'; employee: Employee }

export function EmployeesPage() {
  // Filters, sort and page live in the URL so a view can be bookmarked or shared.
  const [searchParams, setSearchParams] = useSearchParams()
  const filters: FilterValues = {
    q: searchParams.get('q') ?? '',
    country: searchParams.get('country') ?? '',
    department: searchParams.get('department') ?? '',
    job_title: searchParams.get('job_title') ?? '',
  }
  const sort: SortState = {
    sort: searchParams.get('sort') ?? 'full_name',
    direction: searchParams.get('direction') === 'desc' ? 'desc' : 'asc',
  }
  const page = Math.max(1, Number(searchParams.get('page')) || 1)
  const query: EmployeeQuery = { ...filters, ...sort, page, per_page: PER_PAGE }

  const { can_edit: canEdit } = useCurrentUser()
  const employees = useEmployees(query)
  const meta = useMeta()
  const saveEmployee = useSaveEmployee()
  const deleteEmployee = useDeleteEmployee()
  const [editor, setEditor] = useState<EditorState>({ mode: 'closed' })
  const [pendingDelete, setPendingDelete] = useState<Employee | null>(null)
  const [importOpen, setImportOpen] = useState(false)

  function updateParams(changes: Record<string, string | number>, resetPage = true) {
    setSearchParams((current) => {
      const next = new URLSearchParams(current)
      Object.entries(changes).forEach(([key, value]) => (value ? next.set(key, String(value)) : next.delete(key)))
      if (resetPage) next.delete('page')
      return next
    })
  }

  async function handleSave(input: Parameters<typeof saveEmployee.mutateAsync>[0]['input']) {
    const id = editor.mode === 'edit' ? editor.employee.id : undefined
    const { data } = await saveEmployee.mutateAsync({ id, input })
    notifications.show({ color: 'green', message: `${data.full_name} ${id ? 'updated' : 'added'}` })
    setEditor({ mode: 'closed' })
  }

  async function handleDelete() {
    if (!pendingDelete) return
    try {
      await deleteEmployee.mutateAsync(pendingDelete.id)
      notifications.show({ color: 'green', message: `${pendingDelete.full_name} deleted` })
    } catch {
      notifications.show({ color: 'red', message: 'Could not delete employee. Please try again.' })
    } finally {
      setPendingDelete(null)
    }
  }

  const totalCount = employees.data?.meta.total_count

  return (
    <Stack gap="md">
      <Group justify="space-between">
        <div>
          <Title order={2}>Employees</Title>
          <Text c="dimmed" size="sm">
            {totalCount === undefined ? 'Loading…' : `${formatNumber(totalCount)} employees`}
          </Text>
        </div>
        <Group gap="xs">
          <Button
            component="a"
            href={api.exportUrl(query)}
            download
            variant="default"
            leftSection={<IconDownload size={16} />}
            title="Download every employee matching the current filters as an Excel workbook"
          >
            Export to Excel
          </Button>
          {canEdit && (
            <>
              <Button variant="default" leftSection={<IconUpload size={16} />} onClick={() => setImportOpen(true)}>
                Import from Excel
              </Button>
              <Button leftSection={<IconPlus size={16} />} onClick={() => setEditor({ mode: 'create' })} disabled={!meta.data}>
                Add employee
              </Button>
            </>
          )}
        </Group>
      </Group>

      <EmployeeFilters meta={meta.data} values={filters} onChange={(changes) => updateParams(changes)} />

      <Paper withBorder p="xs" pos="relative">
        {employees.isError ? (
          <Alert color="red" title="Could not load employees">
            {employees.error.message}
          </Alert>
        ) : employees.isPending ? (
          <Center h={200}>
            <Loader />
          </Center>
        ) : employees.data.data.length === 0 ? (
          <Center h={160}>
            <Text c="dimmed">No employees match these filters.</Text>
          </Center>
        ) : (
          <EmployeeTable
            employees={employees.data.data}
            sort={sort}
            onSortChange={(next) => updateParams({ ...next })}
            canEdit={canEdit}
            onEdit={(employee) => setEditor({ mode: 'edit', employee })}
            onDelete={setPendingDelete}
          />
        )}
      </Paper>

      {employees.data && employees.data.meta.total_pages > 1 && (
        <Group justify="center">
          <Pagination
            total={employees.data.meta.total_pages}
            value={page}
            onChange={(next) => updateParams({ page: next }, false)}
            siblings={1}
          />
        </Group>
      )}

      <Drawer
        opened={editor.mode !== 'closed'}
        onClose={() => setEditor({ mode: 'closed' })}
        title={editor.mode === 'edit' ? `Edit ${editor.employee.full_name}` : 'Add employee'}
        position="right"
        size="md"
      >
        {meta.data && editor.mode !== 'closed' && (
          <EmployeeForm
            key={editor.mode === 'edit' ? editor.employee.id : 'new'}
            meta={meta.data}
            employee={editor.mode === 'edit' ? editor.employee : undefined}
            onSubmit={handleSave}
            onCancel={() => setEditor({ mode: 'closed' })}
          />
        )}
      </Drawer>

      <ImportEmployeesModal opened={importOpen} onClose={() => setImportOpen(false)} />

      <Modal opened={pendingDelete !== null} onClose={() => setPendingDelete(null)} title="Delete employee?" centered>
        <Text size="sm">
          This permanently removes <b>{pendingDelete?.full_name}</b> and their salary record.
        </Text>
        <Group justify="flex-end" mt="lg">
          <Button variant="default" onClick={() => setPendingDelete(null)}>
            Cancel
          </Button>
          <Button color="red" loading={deleteEmployee.isPending} onClick={handleDelete}>
            Delete
          </Button>
        </Group>
      </Modal>
    </Stack>
  )
}
