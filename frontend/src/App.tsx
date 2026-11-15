import { AppShell, Burger, Group, NavLink, Text, ThemeIcon } from '@mantine/core'
import { useDisclosure } from '@mantine/hooks'
import { IconChartBar, IconCoin, IconUsers } from '@tabler/icons-react'
import { Navigate, NavLink as RouterNavLink, Route, Routes } from 'react-router-dom'
import { EmployeesPage } from './pages/EmployeesPage'
import { InsightsPage } from './pages/InsightsPage'

const NAV_ITEMS = [
  { to: '/employees', label: 'Employees', icon: IconUsers },
  { to: '/insights', label: 'Insights', icon: IconChartBar },
]

export default function App() {
  const [opened, { toggle, close }] = useDisclosure()

  return (
    <AppShell
      header={{ height: 56 }}
      navbar={{ width: 220, breakpoint: 'sm', collapsed: { mobile: !opened } }}
      padding="lg"
    >
      <AppShell.Header>
        <Group h="100%" px="md" gap="sm">
          <Burger opened={opened} onClick={toggle} hiddenFrom="sm" size="sm" aria-label="Toggle navigation" />
          <ThemeIcon variant="light" size="lg">
            <IconCoin size={20} />
          </ThemeIcon>
          <Text fw={700}>ACME Salaries</Text>
        </Group>
      </AppShell.Header>

      <AppShell.Navbar p="sm">
        {NAV_ITEMS.map(({ to, label, icon: Icon }) => (
          <NavLink
            key={to}
            component={RouterNavLink}
            to={to}
            label={label}
            leftSection={<Icon size={18} />}
            onClick={close}
          />
        ))}
      </AppShell.Navbar>

      <AppShell.Main>
        <Routes>
          <Route path="/" element={<Navigate to="/employees" replace />} />
          <Route path="/employees" element={<EmployeesPage />} />
          <Route path="/insights" element={<InsightsPage />} />
          <Route path="*" element={<Navigate to="/employees" replace />} />
        </Routes>
      </AppShell.Main>
    </AppShell>
  )
}
