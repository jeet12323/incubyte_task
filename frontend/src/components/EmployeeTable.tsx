import { ActionIcon, Badge, Group, Table, Text, UnstyledButton } from '@mantine/core'
import { IconChevronDown, IconChevronUp, IconPencil, IconSelector, IconTrash } from '@tabler/icons-react'
import type { Employee } from '../api/types'
import { EMPLOYMENT_TYPE_LABELS, formatDate, formatMoney } from '../lib/format'

export interface SortState {
  sort: string
  direction: 'asc' | 'desc'
}

interface Props {
  employees: Employee[]
  sort: SortState
  onSortChange: (sort: SortState) => void
  onEdit: (employee: Employee) => void
  onDelete: (employee: Employee) => void
}

function SortableHeader({
  column,
  label,
  sort,
  onSortChange,
  align = 'left',
}: {
  column: string
  label: string
  sort: SortState
  onSortChange: (sort: SortState) => void
  align?: 'left' | 'right'
}) {
  const active = sort.sort === column
  const Icon = !active ? IconSelector : sort.direction === 'asc' ? IconChevronUp : IconChevronDown
  const nextDirection = active && sort.direction === 'asc' ? 'desc' : 'asc'

  return (
    <Table.Th style={{ textAlign: align }} aria-sort={active ? (sort.direction === 'asc' ? 'ascending' : 'descending') : 'none'}>
      <UnstyledButton onClick={() => onSortChange({ sort: column, direction: nextDirection })}>
        <Group gap={4} justify={align === 'right' ? 'flex-end' : 'flex-start'} wrap="nowrap">
          <Text fw={600} size="sm">
            {label}
          </Text>
          <Icon size={14} />
        </Group>
      </UnstyledButton>
    </Table.Th>
  )
}

export function EmployeeTable({ employees, sort, onSortChange, onEdit, onDelete }: Props) {
  const headerProps = { sort, onSortChange }

  return (
    <Table.ScrollContainer minWidth={900}>
      <Table striped highlightOnHover verticalSpacing="sm">
        <Table.Thead>
          <Table.Tr>
            <SortableHeader column="full_name" label="Employee" {...headerProps} />
            <SortableHeader column="job_title" label="Job title" {...headerProps} />
            <SortableHeader column="department" label="Department" {...headerProps} />
            <SortableHeader column="country_code" label="Country" {...headerProps} />
            <SortableHeader column="salary" label="Annual salary" align="right" {...headerProps} />
            <Table.Th>Type</Table.Th>
            <SortableHeader column="hire_date" label="Hired" {...headerProps} />
            <Table.Th aria-label="Actions" />
          </Table.Tr>
        </Table.Thead>
        <Table.Tbody>
          {employees.map((employee) => (
            <Table.Tr key={employee.id}>
              <Table.Td>
                <Text size="sm" fw={500}>
                  {employee.full_name}
                </Text>
                <Text size="xs" c="dimmed">
                  {employee.email}
                </Text>
              </Table.Td>
              <Table.Td>{employee.job_title}</Table.Td>
              <Table.Td>{employee.department}</Table.Td>
              <Table.Td>{employee.country_name}</Table.Td>
              <Table.Td style={{ textAlign: 'right' }}>
                <Text size="sm" fw={500}>
                  {formatMoney(employee.salary, employee.currency)}
                </Text>
                {employee.currency !== 'USD' && (
                  <Text size="xs" c="dimmed">
                    ≈ {formatMoney(employee.salary_usd, 'USD')}
                  </Text>
                )}
              </Table.Td>
              <Table.Td>
                <Badge variant="light" color={employee.employment_type === 'full_time' ? 'indigo' : 'gray'}>
                  {EMPLOYMENT_TYPE_LABELS[employee.employment_type]}
                </Badge>
              </Table.Td>
              <Table.Td>{formatDate(employee.hire_date)}</Table.Td>
              <Table.Td>
                <Group gap={4} justify="flex-end" wrap="nowrap">
                  <ActionIcon variant="subtle" aria-label={`Edit ${employee.full_name}`} onClick={() => onEdit(employee)}>
                    <IconPencil size={16} />
                  </ActionIcon>
                  <ActionIcon
                    variant="subtle"
                    color="red"
                    aria-label={`Delete ${employee.full_name}`}
                    onClick={() => onDelete(employee)}
                  >
                    <IconTrash size={16} />
                  </ActionIcon>
                </Group>
              </Table.Td>
            </Table.Tr>
          ))}
        </Table.Tbody>
      </Table>
    </Table.ScrollContainer>
  )
}
