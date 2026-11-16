import { Alert, Button, FileInput, Group, Modal, ScrollArea, Stack, Table, Text } from '@mantine/core'
import { notifications } from '@mantine/notifications'
import { IconFileSpreadsheet } from '@tabler/icons-react'
import { useState } from 'react'
import { useImportEmployees } from '../api/hooks'
import { formatNumber } from '../lib/format'

interface Props {
  opened: boolean
  onClose: () => void
}

const COLUMNS = 'email, full_name, job_title, department, country_code, salary, employment_type, hire_date'

export function ImportEmployeesModal({ opened, onClose }: Props) {
  const [file, setFile] = useState<File | null>(null)
  const importEmployees = useImportEmployees()
  const result = importEmployees.data

  function close() {
    setFile(null)
    importEmployees.reset()
    onClose()
  }

  async function handleImport() {
    if (!file) return
    const outcome = await importEmployees.mutateAsync(file).catch(() => null)
    if (outcome && outcome.error_count === 0) {
      notifications.show({
        color: 'green',
        message: `Imported: ${formatNumber(outcome.created)} added, ${formatNumber(outcome.updated)} updated, ${formatNumber(outcome.unchanged)} unchanged`,
      })
      close()
    }
  }

  return (
    <Modal opened={opened} onClose={close} title="Import employees from Excel" size="lg" centered>
      <Stack>
        <Text size="sm">
          Rows are matched on <b>email</b>: a known email updates that employee, a new one adds an employee. Every row is
          checked first. If any row has a problem, <b>nothing is saved</b> and you'll see what to fix.
        </Text>
        <Stack gap={4}>
          <Text size="xs" c="dimmed">
            Easiest: <b>Export to Excel</b>, edit the workbook, save it (keep it as .xlsx) and import it here.
          </Text>
          <Text size="xs" c="dimmed">
            Columns: {COLUMNS}. Currency is optional and checked against the country. A .csv with the same columns
            also works (dates as YYYY-MM-DD).
          </Text>
        </Stack>

        <FileInput
          label="Excel file"
          placeholder="Choose an .xlsx file"
          accept=".xlsx,.csv,application/vnd.openxmlformats-officedocument.spreadsheetml.sheet,text/csv"
          leftSection={<IconFileSpreadsheet size={18} />}
          value={file}
          onChange={(next) => {
            setFile(next)
            importEmployees.reset()
          }}
          clearable
        />

        {importEmployees.isError && (
          <Alert color="red" title="Could not import this file">
            {importEmployees.error.message}
          </Alert>
        )}

        {result && result.error_count > 0 && (
          <Alert color="red" title={`Nothing was imported: ${formatNumber(result.error_count)} row(s) need fixing`}>
            {result.error_count > result.errors.length && (
              <Text size="xs" mb="xs">
                Showing the first {result.errors.length}.
              </Text>
            )}
            <ScrollArea.Autosize mah={240}>
              <Table fz="xs" verticalSpacing={4} aria-label="Import errors">
                <Table.Thead>
                  <Table.Tr>
                    <Table.Th>Row</Table.Th>
                    <Table.Th>Email</Table.Th>
                    <Table.Th>Problem</Table.Th>
                  </Table.Tr>
                </Table.Thead>
                <Table.Tbody>
                  {result.errors.map((error) => (
                    <Table.Tr key={error.row}>
                      <Table.Td>{error.row}</Table.Td>
                      <Table.Td>{error.email || '—'}</Table.Td>
                      <Table.Td>{error.messages.join('; ')}</Table.Td>
                    </Table.Tr>
                  ))}
                </Table.Tbody>
              </Table>
            </ScrollArea.Autosize>
          </Alert>
        )}

        <Group justify="flex-end">
          <Button variant="default" onClick={close}>
            Cancel
          </Button>
          <Button onClick={handleImport} disabled={!file} loading={importEmployees.isPending}>
            Import
          </Button>
        </Group>
      </Stack>
    </Modal>
  )
}
