import type { ReactElement } from 'react'
import { MantineProvider } from '@mantine/core'
import { QueryClient, QueryClientProvider } from '@tanstack/react-query'
import { MemoryRouter } from 'react-router-dom'
import { render } from '@testing-library/react'
import { theme } from '../theme'
import type { User } from '../api/types'
import { CurrentUserContext } from '../auth/currentUser'
import { hrManager } from './fixtures'

// Renders a component with the same providers as the real app, with retries off so failures
// surface immediately and each test gets a fresh cache. Signed in as an HR manager unless
// `user` says otherwise: null renders signed out, 'from-server' leaves the session to be fetched.
export function renderWithProviders(
  ui: ReactElement,
  { route = '/', user = hrManager }: { route?: string; user?: User | null | 'from-server' } = {},
) {
  const queryClient = new QueryClient({
    defaultOptions: { queries: { retry: false }, mutations: { retry: false } },
  })
  if (user !== 'from-server') queryClient.setQueryData(['session'], user)
  return render(
    <MantineProvider theme={theme}>
      <QueryClientProvider client={queryClient}>
        <CurrentUserContext.Provider value={user === 'from-server' ? null : user}>
          <MemoryRouter initialEntries={[route]}>{ui}</MemoryRouter>
        </CurrentUserContext.Provider>
      </QueryClientProvider>
    </MantineProvider>,
  )
}

export function jsonResponse(body: unknown, status = 200) {
  return new Response(status === 204 ? null : JSON.stringify(body), {
    status,
    headers: { 'Content-Type': 'application/json' },
  })
}
