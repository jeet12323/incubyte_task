const moneyFormatters = new Map<string, Intl.NumberFormat>()

/** Formats a whole-unit amount in the given currency, e.g. formatMoney(2500000, 'INR') -> "₹25,00,000". */
export function formatMoney(amount: number, currency: string): string {
  let formatter = moneyFormatters.get(currency)
  if (!formatter) {
    formatter = new Intl.NumberFormat(localeFor(currency), {
      style: 'currency',
      currency,
      maximumFractionDigits: 0,
    })
    moneyFormatters.set(currency, formatter)
  }
  return formatter.format(amount)
}

/** Short form for dashboards: 766136897 -> "$766.1M". */
export function formatCompactUsd(amount: number): string {
  return new Intl.NumberFormat('en-US', {
    style: 'currency',
    currency: 'USD',
    notation: 'compact',
    maximumFractionDigits: 1,
  }).format(amount)
}

export function formatNumber(value: number): string {
  return new Intl.NumberFormat('en-US').format(value)
}

export function formatDate(isoDate: string): string {
  const [year, month, day] = isoDate.split('-').map(Number)
  return new Date(Date.UTC(year, month - 1, day)).toLocaleDateString('en-GB', {
    day: 'numeric',
    month: 'short',
    year: 'numeric',
    timeZone: 'UTC',
  })
}

export const EMPLOYMENT_TYPE_LABELS: Record<string, string> = {
  full_time: 'Full-time',
  part_time: 'Part-time',
  contract: 'Contract',
}

// Indian rupee amounts read naturally with lakh/crore grouping; everything else uses en-US.
function localeFor(currency: string): string {
  return currency === 'INR' ? 'en-IN' : 'en-US'
}
