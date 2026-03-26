'use client'

import { Component, type ReactNode } from 'react'
import { Button } from '@/components/ui/button'

interface Props {
  tabName: string
  children: ReactNode
}

interface State {
  hasError: boolean
  error: Error | null
}

export class TabErrorBoundary extends Component<Props, State> {
  constructor(props: Props) {
    super(props)
    this.state = { hasError: false, error: null }
  }

  static getDerivedStateFromError(error: Error): State {
    return { hasError: true, error }
  }

  render() {
    if (this.state.hasError) {
      return (
        <div className="bg-white rounded-lg shadow p-8 text-center">
          <h3 className="text-lg font-semibold text-gray-900 mb-2">
            Erreur dans l&apos;onglet {this.props.tabName}
          </h3>
          <p className="text-sm text-gray-600 mb-4">
            {this.state.error?.message || 'Une erreur inattendue est survenue.'}
          </p>
          <Button
            onClick={() => this.setState({ hasError: false, error: null })}
          >
            Réessayer
          </Button>
        </div>
      )
    }

    return this.props.children
  }
}
