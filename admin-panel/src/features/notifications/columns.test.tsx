import { describe, it, expect } from 'vitest'
import { render } from '@testing-library/react'
import { notificationsColumns } from './columns'

function makeMockRow(data: Record<string, unknown>) {
  return {
    getValue: (key: string) => data[key],
    original: data,
  } as never
}

describe('notificationsColumns', () => {
  it('defines the expected columns', () => {
    const ids = notificationsColumns.map(c => (c as any).accessorKey)
    expect(ids).toEqual([
      'id',
      'user_email',
      'trip_title',
      'type',
      'title',
      'body',
      'is_read',
      'sent_at',
      'created_at',
    ])
  })

  it('has correct headers', () => {
    const headers = notificationsColumns.map(c => c.header)
    expect(headers).toEqual([
      'ID',
      'Utilisateur',
      'Trip',
      'Type',
      'Titre',
      'Message',
      'Lu',
      'Envoyé le',
      'Créé le',
    ])
  })

  it('ID cell truncates to first 8 chars', () => {
    const cell = notificationsColumns[0].cell as any
    const { container } = render(cell({ row: makeMockRow({ id: 'abcdefghij1234' }) }))
    expect(container.textContent).toBe('abcdefgh...')
  })

  it('trip_title falls back to dash', () => {
    const cell = notificationsColumns[2].cell as any
    const { container } = render(cell({ row: makeMockRow({ trip_title: '' }) }))
    expect(container.textContent).toBe('—')
  })

  it('type cell renders DEPARTURE_REMINDER with primary color', () => {
    const cell = notificationsColumns[3].cell as any
    const { container } = render(cell({ row: makeMockRow({ type: 'DEPARTURE_REMINDER' }) }))
    const span = container.querySelector('span')
    expect(span?.className).toContain('text-primary')
    expect(span?.textContent).toBe('DEPARTURE_REMINDER')
  })

  it('type cell renders ADMIN with destructive color', () => {
    const cell = notificationsColumns[3].cell as any
    const { container } = render(cell({ row: makeMockRow({ type: 'ADMIN' }) }))
    const span = container.querySelector('span')
    expect(span?.className).toContain('text-destructive')
  })

  it('type cell renders BUDGET_ALERT with orange color', () => {
    const cell = notificationsColumns[3].cell as any
    const { container } = render(cell({ row: makeMockRow({ type: 'BUDGET_ALERT' }) }))
    const span = container.querySelector('span')
    expect(span?.className).toContain('text-orange-800')
  })

  it('type cell falls back for unknown type', () => {
    const cell = notificationsColumns[3].cell as any
    const { container } = render(cell({ row: makeMockRow({ type: 'UNKNOWN' }) }))
    const span = container.querySelector('span')
    expect(span?.className).toContain('bg-secondary')
  })

  it('body truncates long text', () => {
    const cell = notificationsColumns[5].cell as any
    const longText = 'A'.repeat(60)
    const { container } = render(cell({ row: makeMockRow({ body: longText }) }))
    expect(container.textContent).toBe('A'.repeat(50) + '...')
  })

  it('body shows full short text', () => {
    const cell = notificationsColumns[5].cell as any
    const { container } = render(cell({ row: makeMockRow({ body: 'Short message' }) }))
    expect(container.textContent).toBe('Short message')
  })

  it('is_read shows Lu when true', () => {
    const cell = notificationsColumns[6].cell as any
    const { container } = render(cell({ row: makeMockRow({ is_read: true }) }))
    expect(container.textContent).toBe('Lu')
    const span = container.querySelector('span')
    expect(span?.className).toContain('text-success')
  })

  it('is_read shows Non lu when false', () => {
    const cell = notificationsColumns[6].cell as any
    const { container } = render(cell({ row: makeMockRow({ is_read: false }) }))
    expect(container.textContent).toBe('Non lu')
    const span = container.querySelector('span')
    expect(span?.className).toContain('text-destructive')
  })

  it('sent_at shows dash when null', () => {
    const cell = notificationsColumns[7].cell as any
    const { container } = render(cell({ row: makeMockRow({ sent_at: null }) }))
    expect(container.textContent).toBe('—')
  })

  it('sent_at formats a valid date', () => {
    const cell = notificationsColumns[7].cell as any
    const { container } = render(
      cell({ row: makeMockRow({ sent_at: '2024-06-15T10:30:00Z' }) })
    )
    expect(container.textContent).toMatch(/15\/06\/2024/)
  })

  it('user_email renders email', () => {
    const cell = notificationsColumns[1].cell as any
    const { container } = render(cell({ row: makeMockRow({ user_email: 'a@b.com' }) }))
    expect(container.textContent).toBe('a@b.com')
  })

  it('title renders text', () => {
    const cell = notificationsColumns[4].cell as any
    const { container } = render(cell({ row: makeMockRow({ title: 'Reminder' }) }))
    expect(container.textContent).toBe('Reminder')
  })

  it('type cell renders FLIGHT_H4 with indigo color', () => {
    const cell = notificationsColumns[3].cell as any
    const { container } = render(cell({ row: makeMockRow({ type: 'FLIGHT_H4' }) }))
    const span = container.querySelector('span')
    expect(span?.className).toContain('text-indigo-800')
  })

  it('type cell renders FLIGHT_H1 with chart-4 color', () => {
    const cell = notificationsColumns[3].cell as any
    const { container } = render(cell({ row: makeMockRow({ type: 'FLIGHT_H1' }) }))
    const span = container.querySelector('span')
    expect(span?.className).toContain('text-chart-4')
  })

  it('type cell renders MORNING_SUMMARY with warning color', () => {
    const cell = notificationsColumns[3].cell as any
    const { container } = render(cell({ row: makeMockRow({ type: 'MORNING_SUMMARY' }) }))
    const span = container.querySelector('span')
    expect(span?.className).toContain('text-warning')
  })

  it('type cell renders ACTIVITY_H1 with success color', () => {
    const cell = notificationsColumns[3].cell as any
    const { container } = render(cell({ row: makeMockRow({ type: 'ACTIVITY_H1' }) }))
    const span = container.querySelector('span')
    expect(span?.className).toContain('text-success')
  })

  it('type cell renders TRIP_ENDED with secondary color', () => {
    const cell = notificationsColumns[3].cell as any
    const { container } = render(cell({ row: makeMockRow({ type: 'TRIP_ENDED' }) }))
    const span = container.querySelector('span')
    expect(span?.className).toContain('bg-secondary')
  })

  it('type cell renders TRIP_SHARED with teal color', () => {
    const cell = notificationsColumns[3].cell as any
    const { container } = render(cell({ row: makeMockRow({ type: 'TRIP_SHARED' }) }))
    const span = container.querySelector('span')
    expect(span?.className).toContain('text-teal-800')
  })

  it('created_at formats a valid date', () => {
    const cell = notificationsColumns[8].cell as any
    const { container } = render(cell({ row: makeMockRow({ created_at: '2024-01-15T09:00:00Z' }) }))
    expect(container.textContent).toMatch(/15\/01\/2024/)
  })

  it('created_at shows dash for null', () => {
    const cell = notificationsColumns[8].cell as any
    const { container } = render(cell({ row: makeMockRow({ created_at: null }) }))
    expect(container.textContent).toBe('—')
  })
})
