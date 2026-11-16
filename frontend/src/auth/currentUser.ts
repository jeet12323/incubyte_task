import { createContext, useContext } from 'react'
import type { User } from '../api/types'

/** Provided by AuthGate, so everything inside the signed-in app always has a user. */
export const CurrentUserContext = createContext<User | null>(null)

export function useCurrentUser(): User {
  const user = useContext(CurrentUserContext)
  if (!user) throw new Error('useCurrentUser must be used inside <AuthGate>')
  return user
}
