'use client'

import { DataTable } from '@/components/DataTable'
import {
  flightBookingsColumns,
  hotelBookingsColumns,
  travelersColumns,
  tripsColumns,
} from '@/components/tables'
import { useAuth } from '@/hooks'
import {
  useAdminFlightBookings,
  useAdminHotelBookings,
  useAdminTravelers,
  useAdminTrips,
} from '@/hooks/useAdminData'
import { usersService } from '@/services'
import type { User } from '@/types'
import { PAGINATION_DEFAULTS } from '@/utils/constants'
import { safeFormatDate } from '@/utils/date'
import { useQuery } from '@tanstack/react-query'
import type { ColumnDef } from '@tanstack/react-table'
import { useState } from 'react'

const usersColumns: ColumnDef<User>[] = [
  {
    accessorKey: 'id',
    header: 'ID',
    cell: ({ row }) => (
      <span className="font-mono text-xs">{(row.getValue('id') as string).slice(0, 8)}...</span>
    ),
  },
  {
    accessorKey: 'email',
    header: 'Email',
    cell: ({ row }) => <span className="text-gray-900">{row.getValue('email')}</span>,
  },
  {
    accessorKey: 'created_at',
    header: 'Créé le',
    cell: ({ row }) => {
      const date = row.getValue('created_at') as string | null
      return (
        <span className="text-gray-500 text-xs">{safeFormatDate(date, 'dd/MM/yyyy HH:mm')}</span>
      )
    },
  },
  {
    accessorKey: 'updated_at',
    header: 'Modifié le',
    cell: ({ row }) => {
      const date = row.getValue('updated_at') as string | null
      return (
        <span className="text-gray-500 text-xs">{safeFormatDate(date, 'dd/MM/yyyy HH:mm')}</span>
      )
    },
  },
]

type TabType = 'users' | 'trips' | 'travelers' | 'hotels' | 'flights'

export default function DashboardPage() {
  const { user, logout } = useAuth()
  const [activeTab, setActiveTab] = useState<TabType>('users')
  const [usersPage, setUsersPage] = useState(1)
  const [tripsPage, setTripsPage] = useState(1)
  const [travelersPage, setTravelersPage] = useState(1)
  const [hotelsPage, setHotelsPage] = useState(1)
  const [flightsPage, setFlightsPage] = useState(1)

  // Users query
  const { data: usersData, isLoading: usersLoading } = useQuery({
    queryKey: ['users', usersPage],
    queryFn: () =>
      usersService.getUsers({
        page: usersPage,
        limit: PAGINATION_DEFAULTS.LIMIT,
      }),
  })

  // Admin data queries
  const { data: tripsData, isLoading: tripsLoading } = useAdminTrips({
    page: tripsPage,
    limit: PAGINATION_DEFAULTS.LIMIT,
  })

  const { data: travelersData, isLoading: travelersLoading } = useAdminTravelers({
    page: travelersPage,
    limit: PAGINATION_DEFAULTS.LIMIT,
  })

  const { data: hotelsData, isLoading: hotelsLoading } = useAdminHotelBookings({
    page: hotelsPage,
    limit: PAGINATION_DEFAULTS.LIMIT,
  })

  const { data: flightsData, isLoading: flightsLoading } = useAdminFlightBookings({
    page: flightsPage,
    limit: PAGINATION_DEFAULTS.LIMIT,
  })

  if (!user) {
    return (
      <div className="min-h-screen flex items-center justify-center">
        <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-600"></div>
      </div>
    )
  }

  const tabs = [
    { id: 'users' as TabType, name: 'Utilisateurs', count: usersData?.pagination?.total },
    { id: 'trips' as TabType, name: 'Trips', count: tripsData?.total },
    { id: 'travelers' as TabType, name: 'Voyageurs', count: travelersData?.total },
    { id: 'hotels' as TabType, name: 'Réservations Hôtels', count: hotelsData?.total },
    { id: 'flights' as TabType, name: 'Réservations Vols', count: flightsData?.total },
  ]

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
              <button
                onClick={logout}
                className="bg-red-600 hover:bg-red-700 text-white px-4 py-2 rounded-md text-sm font-medium disabled:opacity-50"
              >
                Déconnexion
              </button>
            </div>
          </div>
        </div>
      </nav>

      <main className="max-w-7xl mx-auto py-6 sm:px-6 lg:px-8">
        <div className="px-4 py-6 sm:px-0">
          <div className="mb-6">
            <h2 className="text-2xl font-bold text-gray-900 mb-4">Tableau de bord</h2>

            {/* Tabs */}
            <div className="border-b border-gray-200">
              <nav className="-mb-px flex space-x-8" aria-label="Tabs">
                {tabs.map(tab => (
                  <button
                    key={tab.id}
                    onClick={() => setActiveTab(tab.id)}
                    className={`
                      whitespace-nowrap py-4 px-1 border-b-2 font-medium text-sm
                      ${
                        activeTab === tab.id
                          ? 'border-blue-500 text-blue-600'
                          : 'border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300'
                      }
                    `}
                  >
                    {tab.name}
                    {tab.count !== undefined && (
                      <span
                        className={`ml-2 py-0.5 px-2 rounded-full text-xs ${
                          activeTab === tab.id
                            ? 'bg-blue-100 text-blue-600'
                            : 'bg-gray-100 text-gray-600'
                        }`}
                      >
                        {tab.count}
                      </span>
                    )}
                  </button>
                ))}
              </nav>
            </div>
          </div>

          {/* Tab Content */}
          <div className="mt-6">
            {activeTab === 'users' && (
              <DataTable
                data={usersData?.data || []}
                columns={usersColumns}
                isLoading={usersLoading}
                pagination={
                  usersData?.pagination
                    ? {
                        page: usersData.pagination.page,
                        limit: usersData.pagination.limit,
                        total: usersData.pagination.total,
                        total_pages: usersData.pagination.total_pages,
                      }
                    : undefined
                }
                onPaginationChange={(page, limit) => {
                  setUsersPage(page)
                }}
              />
            )}

            {activeTab === 'trips' && (
              <DataTable
                data={tripsData?.items || []}
                columns={tripsColumns}
                isLoading={tripsLoading}
                pagination={
                  tripsData
                    ? {
                        page: tripsData.page,
                        limit: tripsData.limit,
                        total: tripsData.total,
                        total_pages: tripsData.total_pages,
                      }
                    : undefined
                }
                onPaginationChange={(page, limit) => {
                  setTripsPage(page)
                }}
              />
            )}

            {activeTab === 'travelers' && (
              <DataTable
                data={travelersData?.items || []}
                columns={travelersColumns}
                isLoading={travelersLoading}
                pagination={
                  travelersData
                    ? {
                        page: travelersData.page,
                        limit: travelersData.limit,
                        total: travelersData.total,
                        total_pages: travelersData.total_pages,
                      }
                    : undefined
                }
                onPaginationChange={(page, limit) => {
                  setTravelersPage(page)
                }}
              />
            )}

            {activeTab === 'hotels' && (
              <DataTable
                data={hotelsData?.items || []}
                columns={hotelBookingsColumns}
                isLoading={hotelsLoading}
                pagination={
                  hotelsData
                    ? {
                        page: hotelsData.page,
                        limit: hotelsData.limit,
                        total: hotelsData.total,
                        total_pages: hotelsData.total_pages,
                      }
                    : undefined
                }
                onPaginationChange={(page, limit) => {
                  setHotelsPage(page)
                }}
              />
            )}

            {activeTab === 'flights' && (
              <DataTable
                data={flightsData?.items || []}
                columns={flightBookingsColumns}
                isLoading={flightsLoading}
                pagination={
                  flightsData
                    ? {
                        page: flightsData.page,
                        limit: flightsData.limit,
                        total: flightsData.total,
                        total_pages: flightsData.total_pages,
                      }
                    : undefined
                }
                onPaginationChange={(page, limit) => {
                  setFlightsPage(page)
                }}
              />
            )}
          </div>
        </div>
      </main>
    </div>
  )
}
