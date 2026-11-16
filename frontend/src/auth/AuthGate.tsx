import { Alert, Center, Loader } from '@mantine/core'
import type { ReactNode } from 'react'
import { useSession } from '../api/hooks'
import { CurrentUserContext } from './currentUser'
import { LoginPage } from './LoginPage'

/** Shows the sign-in screen until there is a session, then the app. */
export function AuthGate({ children }: { children: ReactNode }) {
  const session = useSession()

  if (session.isPending) {
    return (
      <Center h="100vh">
        <Loader />
      </Center>
    )
  }
  if (session.isError) {
    return (
      <Center h="100vh" p="md">
        <Alert color="red" title="Could not reach the server">
          {session.error.message}
        </Alert>
      </Center>
    )
  }
  if (!session.data) return <LoginPage />
  return <CurrentUserContext.Provider value={session.data}>{children}</CurrentUserContext.Provider>
}
