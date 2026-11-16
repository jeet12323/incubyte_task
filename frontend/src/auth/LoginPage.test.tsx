import { screen, waitFor } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { describe, expect, it, vi } from 'vitest'
import { hrManager } from '../test/fixtures'
import { jsonResponse, renderWithProviders } from '../test/render'
import { AuthGate } from './AuthGate'
import { UserMenu } from './UserMenu'

function mockSession(signInResponse: Response) {
  return vi
    .spyOn(globalThis, 'fetch')
    .mockImplementation(async (_input, init) =>
      init?.method === 'POST' ? signInResponse : jsonResponse({ error: 'Please sign in' }, 401),
    )
}

async function signInWith(email: string, password: string) {
  const user = userEvent.setup()
  await user.type(screen.getByLabelText('Email'), email)
  await user.type(screen.getByLabelText('Password'), password)
  await user.click(screen.getByRole('button', { name: 'Sign in' }))
}

describe('sign-in', () => {
  it('shows the sign-in screen instead of the app when signed out', async () => {
    mockSession(jsonResponse({}, 201))
    renderWithProviders(<AuthGate>salary data</AuthGate>, { user: 'from-server' })

    expect(await screen.findByRole('button', { name: 'Sign in' })).toBeInTheDocument()
    expect(screen.queryByText('salary data')).not.toBeInTheDocument()
  })

  it('signs in and then shows the app', async () => {
    const fetchMock = mockSession(jsonResponse({ data: hrManager }, 201))
    renderWithProviders(<AuthGate>salary data</AuthGate>, { user: null })

    await signInWith('hr@acme.test', 'acme-demo-2026')

    expect(await screen.findByText('salary data')).toBeInTheDocument()
    const [, init] = fetchMock.mock.calls.find(([, options]) => options?.method === 'POST')!
    expect(JSON.parse(String(init!.body))).toEqual({ email: 'hr@acme.test', password: 'acme-demo-2026' })
  })

  it('shows the server message when the password is wrong', async () => {
    mockSession(jsonResponse({ error: 'Email or password is incorrect' }, 401))
    renderWithProviders(<AuthGate>salary data</AuthGate>, { user: null })

    await signInWith('hr@acme.test', 'nope')

    expect(await screen.findByRole('alert')).toHaveTextContent('Email or password is incorrect')
    expect(screen.queryByText('salary data')).not.toBeInTheDocument()
  })

  it('fills in a demo account when it is clicked', async () => {
    mockSession(jsonResponse({ data: hrManager }, 201))
    const user = userEvent.setup()
    renderWithProviders(<AuthGate>salary data</AuthGate>, { user: null })

    await user.click(screen.getByRole('button', { name: 'viewer@acme.test' }))

    await waitFor(() => expect(screen.getByLabelText('Email')).toHaveValue('viewer@acme.test'))
    expect(screen.getByLabelText('Password')).toHaveValue('acme-demo-2026')
  })

  it('signs out back to the sign-in screen', async () => {
    const fetchMock = vi.spyOn(globalThis, 'fetch').mockResolvedValue(jsonResponse(null, 204))
    const user = userEvent.setup()
    renderWithProviders(
      <AuthGate>
        <UserMenu />
      </AuthGate>,
    )

    // The full button and the phone icon button are both in the DOM; CSS shows one of them.
    await user.click(screen.getAllByRole('button', { name: /Sign out/ })[0])

    expect(await screen.findByRole('button', { name: 'Sign in' })).toBeInTheDocument()
    expect(fetchMock).toHaveBeenCalledWith('/api/v1/session', expect.objectContaining({ method: 'DELETE' }))
  })
})
