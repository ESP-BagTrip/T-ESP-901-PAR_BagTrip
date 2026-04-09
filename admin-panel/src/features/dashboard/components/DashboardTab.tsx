'use client'

import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import {
  useDashboardMetrics,
  useUserRegistrationsChart,
  useRevenueChart,
  useFeedbacksChart,
} from '../hooks'
import {
  BarChart,
  Bar,
  LineChart,
  Line,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  ResponsiveContainer,
} from 'recharts'

function MetricCard({
  title,
  value,
  subtitle,
}: {
  title: string
  value: string | number
  subtitle?: string
}) {
  return (
    <Card>
      <CardHeader className="pb-2">
        <CardTitle className="text-sm font-medium text-gray-500">{title}</CardTitle>
      </CardHeader>
      <CardContent>
        <div className="text-2xl font-bold">{value}</div>
        {subtitle && <p className="text-xs text-gray-500 mt-1">{subtitle}</p>}
      </CardContent>
    </Card>
  )
}

export default function DashboardTab({ isActive }: { isActive: boolean }) {
  const { data: metrics, isLoading: metricsLoading } = useDashboardMetrics({ enabled: isActive })
  const { data: usersChart } = useUserRegistrationsChart({ enabled: isActive })
  const { data: revenueChart } = useRevenueChart({ enabled: isActive })
  const { data: feedbacksChart } = useFeedbacksChart({ enabled: isActive })

  if (metricsLoading) {
    return (
      <div className="grid grid-cols-2 md:grid-cols-4 gap-4 animate-pulse">
        {Array.from({ length: 8 }).map((_, i) => (
          <Card key={i}>
            <CardContent className="p-6">
              <div className="h-4 bg-gray-200 rounded w-1/2 mb-2" />
              <div className="h-8 bg-gray-200 rounded w-3/4" />
            </CardContent>
          </Card>
        ))}
      </div>
    )
  }

  return (
    <div className="space-y-6">
      {/* KPI Cards */}
      <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
        <MetricCard title="Utilisateurs" value={metrics?.totalUsers ?? 0} />
        <MetricCard
          title="Actifs"
          value={metrics?.activeUsers ?? 0}
          subtitle={`${metrics?.inactiveUsers ?? 0} inactifs`}
        />
        <MetricCard title="Trips" value={metrics?.totalTrips ?? 0} />
        <MetricCard
          title="Revenus"
          value={`${(metrics?.totalRevenue ?? 0).toLocaleString('fr-FR', { style: 'currency', currency: 'EUR' })}`}
        />
        <MetricCard title="Feedbacks" value={metrics?.totalFeedbacks ?? 0} />
        <MetricCard
          title="Note moyenne"
          value={metrics?.averageRating ? `${metrics.averageRating}/5` : '—'}
        />
        <MetricCard title="Feedbacks en attente" value={metrics?.pendingFeedbacks ?? 0} />
      </div>

      {/* Charts */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {/* User Registrations Chart */}
        <Card>
          <CardHeader>
            <CardTitle className="text-base">Inscriptions utilisateurs</CardTitle>
          </CardHeader>
          <CardContent>
            {usersChart && usersChart.length > 0 ? (
              <ResponsiveContainer width="100%" height={300}>
                <LineChart data={usersChart}>
                  <CartesianGrid strokeDasharray="3 3" />
                  <XAxis dataKey="name" tick={{ fontSize: 12 }} />
                  <YAxis allowDecimals={false} />
                  <Tooltip />
                  <Line type="monotone" dataKey="value" stroke="#3b82f6" strokeWidth={2} />
                </LineChart>
              </ResponsiveContainer>
            ) : (
              <p className="text-gray-400 text-sm text-center py-12">Aucune donnée</p>
            )}
          </CardContent>
        </Card>

        {/* Revenue Chart */}
        <Card>
          <CardHeader>
            <CardTitle className="text-base">Revenus</CardTitle>
          </CardHeader>
          <CardContent>
            {revenueChart && revenueChart.length > 0 ? (
              <ResponsiveContainer width="100%" height={300}>
                <BarChart data={revenueChart}>
                  <CartesianGrid strokeDasharray="3 3" />
                  <XAxis dataKey="name" tick={{ fontSize: 12 }} />
                  <YAxis />
                  <Tooltip
                    formatter={(value: number) =>
                      value.toLocaleString('fr-FR', { style: 'currency', currency: 'EUR' })
                    }
                  />
                  <Bar dataKey="value" fill="#10b981" radius={[4, 4, 0, 0]} />
                </BarChart>
              </ResponsiveContainer>
            ) : (
              <p className="text-gray-400 text-sm text-center py-12">Aucune donnée</p>
            )}
          </CardContent>
        </Card>

        {/* Feedbacks Distribution Chart */}
        <Card className="lg:col-span-2">
          <CardHeader>
            <CardTitle className="text-base">Distribution des feedbacks</CardTitle>
          </CardHeader>
          <CardContent>
            {feedbacksChart && feedbacksChart.length > 0 ? (
              <ResponsiveContainer width="100%" height={300}>
                <BarChart data={feedbacksChart}>
                  <CartesianGrid strokeDasharray="3 3" />
                  <XAxis dataKey="name" />
                  <YAxis allowDecimals={false} />
                  <Tooltip />
                  <Bar dataKey="value" fill="#f59e0b" radius={[4, 4, 0, 0]} />
                </BarChart>
              </ResponsiveContainer>
            ) : (
              <p className="text-gray-400 text-sm text-center py-12">Aucune donnée</p>
            )}
          </CardContent>
        </Card>
      </div>
    </div>
  )
}
