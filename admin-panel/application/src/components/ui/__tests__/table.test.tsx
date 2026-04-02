import { describe, it, expect } from 'vitest'
import { render } from '@testing-library/react'
import {
  Table,
  TableHeader,
  TableBody,
  TableRow,
  TableHead,
  TableCell,
  TableCaption,
  TableFooter,
} from '../table'

describe('Table components', () => {
  it('renders table element', () => {
    const { container } = render(<Table />)
    expect(container.querySelector('table')).toBeInTheDocument()
  })

  it('renders thead', () => {
    const { container } = render(
      <table><TableHeader data-testid="thead"><tr><th>H</th></tr></TableHeader></table>
    )
    expect(container.querySelector('thead')).toBeInTheDocument()
  })

  it('renders tbody', () => {
    const { container } = render(
      <table><TableBody><tr><td>B</td></tr></TableBody></table>
    )
    expect(container.querySelector('tbody')).toBeInTheDocument()
  })

  it('renders tr', () => {
    const { container } = render(
      <table><tbody><TableRow><td>R</td></TableRow></tbody></table>
    )
    expect(container.querySelector('tr')).toBeInTheDocument()
  })

  it('renders th', () => {
    const { container } = render(
      <table><thead><tr><TableHead>Head</TableHead></tr></thead></table>
    )
    expect(container.querySelector('th')).toBeInTheDocument()
  })

  it('renders td', () => {
    const { container } = render(
      <table><tbody><tr><TableCell>Cell</TableCell></tr></tbody></table>
    )
    expect(container.querySelector('td')).toBeInTheDocument()
  })

  it('renders caption', () => {
    const { container } = render(
      <table><TableCaption>Caption</TableCaption></table>
    )
    expect(container.querySelector('caption')).toBeInTheDocument()
  })

  it('renders tfoot', () => {
    const { container } = render(
      <table><TableFooter><tr><td>F</td></tr></TableFooter></table>
    )
    expect(container.querySelector('tfoot')).toBeInTheDocument()
  })
})
