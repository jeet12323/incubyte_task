import { describe, expect, it } from 'vitest'
import { formatCompactUsd, formatDate, formatMoney } from './format'

describe('formatMoney', () => {
  it('formats whole amounts in the given currency', () => {
    expect(formatMoney(120000, 'USD')).toBe('$120,000')
    expect(formatMoney(65000.4, 'EUR')).toBe('€65,000')
  })

  it('uses lakh grouping for Indian rupees', () => {
    expect(formatMoney(2500000, 'INR')).toBe('₹25,00,000')
  })
})

describe('formatCompactUsd', () => {
  it('abbreviates large totals', () => {
    expect(formatCompactUsd(766136897)).toBe('$766.1M')
  })
})

describe('formatDate', () => {
  it('formats an ISO date without timezone drift', () => {
    expect(formatDate('2024-03-01')).toBe('1 Mar 2024')
  })
})
