import { ActionIcon, Badge, Button, Group, Text } from '@mantine/core'
import { IconLogout } from '@tabler/icons-react'
import { useSignOut } from '../api/hooks'
import { useCurrentUser } from './currentUser'

export function UserMenu() {
  const user = useCurrentUser()
  const signOut = useSignOut()

  return (
    <Group gap="sm" wrap="nowrap">
      <Text size="sm" visibleFrom="sm">
        {user.name}
      </Text>
      <Badge variant="light" color={user.can_edit ? 'indigo' : 'gray'} tt="none" visibleFrom="xs">
        {user.can_edit ? 'HR Manager' : 'Viewer'}
      </Badge>
      <Button
        variant="subtle"
        size="compact-sm"
        leftSection={<IconLogout size={16} />}
        loading={signOut.isPending}
        onClick={() => signOut.mutate()}
        visibleFrom="sm"
      >
        Sign out
      </Button>
      <ActionIcon
        variant="subtle"
        aria-label="Sign out"
        loading={signOut.isPending}
        onClick={() => signOut.mutate()}
        hiddenFrom="sm"
      >
        <IconLogout size={18} />
      </ActionIcon>
    </Group>
  )
}
