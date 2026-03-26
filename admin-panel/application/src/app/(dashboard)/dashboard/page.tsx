'use client'

import { Suspense } from 'react'
import { useAuth } from '@/hooks'
import { TAB_REGISTRY } from '@/features/registry'
import { useDashboardStore } from '@/stores/useDashboardStore'
import { TabErrorBoundary } from '@/shared/components/TabErrorBoundary'
import { TabSkeleton } from '@/shared/components/TabSkeleton'
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs'
import { Button } from '@/components/ui/button'

export default function DashboardPage() {
  const { user, logout } = useAuth()
  const { activeTab, setActiveTab } = useDashboardStore()

  if (!user) {
    return (
      <div className="min-h-screen flex items-center justify-center">
        <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-600"></div>
      </div>
    )
  }

  return (
    <div className="min-h-screen bg-gray-50">
      <nav className="bg-white shadow">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="flex justify-between h-16">
            <div className="flex items-center">
              <h1 className="text-xl font-semibold text-gray-900">BagTrip Admin</h1>
            </div>
            <div className="flex items-center space-x-4">
              <span className="text-sm text-gray-700">Bonjour, {user.email}</span>
              <Button variant="destructive" size="sm" onClick={logout}>
                Déconnexion
              </Button>
            </div>
          </div>
        </div>
      </nav>

      <main className="max-w-7xl mx-auto py-6 sm:px-6 lg:px-8">
        <div className="px-4 py-6 sm:px-0">
          <h2 className="text-2xl font-bold text-gray-900 mb-4">Tableau de bord</h2>

          <Tabs value={activeTab} onValueChange={setActiveTab}>
            <TabsList>
              {TAB_REGISTRY.map(tab => (
                <TabsTrigger key={tab.id} value={tab.id}>
                  {tab.name}
                </TabsTrigger>
              ))}
            </TabsList>

            {TAB_REGISTRY.map(tab => (
              <TabsContent key={tab.id} value={tab.id}>
                <TabErrorBoundary tabName={tab.name}>
                  <Suspense fallback={<TabSkeleton />}>
                    <tab.component isActive={activeTab === tab.id} />
                  </Suspense>
                </TabErrorBoundary>
              </TabsContent>
            ))}
          </Tabs>
        </div>
      </main>
    </div>
  )
}
