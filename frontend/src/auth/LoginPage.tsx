import { Alert, Anchor, Button, Center, Paper, PasswordInput, Stack, Table, Text, TextInput, ThemeIcon, Title } from '@mantine/core'
import { useForm } from '@mantine/form'
import { IconCoin } from '@tabler/icons-react'
import { useSignIn } from '../api/hooks'
import { DEMO_ACCOUNTS, DEMO_PASSWORD } from './demoAccounts'

export function LoginPage() {
  const signIn = useSignIn()
  const form = useForm({
    initialValues: { email: '', password: '' },
    validate: {
      email: (value) => (/^\S+@\S+$/.test(value) ? null : 'Enter your work email'),
      password: (value) => (value ? null : 'Enter your password'),
    },
  })

  return (
    <Center mih="100vh" p="md">
      <Stack w="100%" maw={420} gap="lg">
        <Stack align="center" gap={6}>
          <ThemeIcon variant="light" size={48} radius="md">
            <IconCoin size={28} />
          </ThemeIcon>
          <Title order={2}>ACME Salaries</Title>
          <Text c="dimmed" size="sm">
            Sign in with your HR account
          </Text>
        </Stack>

        <Paper withBorder p="lg" radius="md">
          <form onSubmit={form.onSubmit((values) => signIn.mutate(values))} noValidate>
            <Stack>
              {signIn.isError && (
                <Alert color="red" role="alert">
                  {signIn.error.message}
                </Alert>
              )}
              <TextInput label="Email" type="email" autoComplete="username" {...form.getInputProps('email')} />
              <PasswordInput label="Password" autoComplete="current-password" {...form.getInputProps('password')} />
              <Button type="submit" loading={signIn.isPending} fullWidth>
                Sign in
              </Button>
            </Stack>
          </form>
        </Paper>

        <Paper withBorder p="md" radius="md" bg="var(--mantine-color-default-hover)">
          <Text size="sm" fw={600} mb={4}>
            Demo accounts (fictional data)
          </Text>
          <Text size="xs" c="dimmed" mb="xs">
            Password for both: <code>{DEMO_PASSWORD}</code>
          </Text>
          <Table fz="xs" verticalSpacing={4}>
            <Table.Tbody>
              {DEMO_ACCOUNTS.map((account) => (
                <Table.Tr key={account.email}>
                  <Table.Td>
                    <Anchor
                      component="button"
                      type="button"
                      size="xs"
                      onClick={() => form.setValues({ email: account.email, password: DEMO_PASSWORD })}
                    >
                      {account.email}
                    </Anchor>
                  </Table.Td>
                  <Table.Td>{account.role}</Table.Td>
                  <Table.Td c="dimmed">{account.access}</Table.Td>
                </Table.Tr>
              ))}
            </Table.Tbody>
          </Table>
        </Paper>
      </Stack>
    </Center>
  )
}
