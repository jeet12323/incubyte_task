import { StrictMode } from 'react'
import { createRoot } from 'react-dom/client'
import { MantineProvider } from '@mantine/core'
import { Notifications } from '@mantine/notifications'
import { MutationCache, QueryCache, QueryClient, QueryClientProvider } from '@tanstack/react-query'
import { BrowserRouter } from 'react-router-dom'
import '@mantine/core/styles.css'
import '@mantine/notifications/styles.css'
import '@mantine/charts/styles.css'
import { theme } from './theme'
import App from './App'
import { ApiError } from './api/client'
import { queryKeys } from './api/hooks'

// If the session expires mid-use, any 401 sends the user back to the sign-in screen.
function signOutOnUnauthorized(error: Error) {
  if (error instanceof ApiError && error.status === 401) queryClient.setQueryData(queryKeys.session, null)
}

const queryClient = new QueryClient({
  defaultOptions: { queries: { staleTime: 30_000, refetchOnWindowFocus: false } },
  queryCache: new QueryCache({ onError: signOutOnUnauthorized }),
  mutationCache: new MutationCache({ onError: signOutOnUnauthorized }),
})

createRoot(document.getElementById('root')!).render(
  <StrictMode>
    <MantineProvider theme={theme} defaultColorScheme="auto">
      <Notifications position="top-right" />
      <QueryClientProvider client={queryClient}>
        <BrowserRouter>
          <App />
        </BrowserRouter>
      </QueryClientProvider>
    </MantineProvider>
  </StrictMode>,
)
