'use client'

import { useMemo } from 'react'

import { PageHeader } from '@/components/layout/PageHeader'
import { ActivityFeed } from '@/components/layout/ActivityFeed'
import { KPICard } from '@/components/ui/kpi-card'
import { DateRangePicker } from '@/components/ui/date-range-picker'
import { AreaChartCard } from '@/components/charts/AreaChartCard'
import { BarChartCard } from '@/components/charts/BarChartCard'
import { DonutChartCard } from '@/components/charts/DonutChartCard'
import { DistributionChartCard } from '@/components/charts/DistributionChartCard'
import {
  useDashboardMetrics,
  useFeedbacksChart,
  useRecentActivity,
  useRevenueChart,
  useTripStatusDistribution,
  useUserRegistrationsChart,
} from '@/features/dashboard/hooks'
import { useDateRange } from '@/hooks/useDateRange'
import { formatCurrency, formatNumber, formatRating } from '@/utils/format'
import { windowDelta } from '@/utils/delta'
import { countBy } from '@/utils/group-by'

export default function OverviewPage() {
  const range = useDateRange()

  const metrics = useDashboardMetrics()
  const usersChart = useUserRegistrationsChart(range.apiPeriod)
  const revenueChart = useRevenueChart(range.apiPeriod)
  const feedbacksChart = useFeedbacksChart()
  const activity = useRecentActivity(10)
  const tripsForStatus = useTripStatusDistribution()

  const usersSeries = useMemo(() => usersChart.data ?? [], [usersChart.data])
  const revenueSeries = useMemo(() => revenueChart.data ?? [], [revenueChart.data])
  const feedbacksSeries = useMemo(() => feedbacksChart.data ?? [], [feedbacksChart.data])

  const usersDelta = useMemo(() => windowDelta(usersSeries), [usersSeries])
  const revenueDelta = useMemo(() => windowDelta(revenueSeries), [revenueSeries])

  const tripStatusData = useMemo(() => {
    const list = tripsForStatus.data?.items ?? []
    return countBy(list, t => t.status ?? 'UNKNOWN')
  }, [tripsForStatus.data])

  return (
    <div className="space-y-8">
      <PageHeader
        title="Overview"
        description="Snapshot du SaaS BagTrip — KPIs, croissance, activité récente."
        actions={<DateRangePicker />}
      />

      {/* KPI strip */}
      <section aria-label="Indicateurs clés">
        <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-4">
          <KPICard
            label="UTILISATEURS"
            value={formatNumber(metrics.data?.totalUsers)}
            delta={usersDelta.delta}
            trend={usersSeries.slice(-7).map(p => p.value)}
            tone="primary"
            href="/app/users"
            isLoading={metrics.isLoading}
          />
          <KPICard
            label="VOYAGES"
            value={formatNumber(metrics.data?.totalTrips)}
            delta={null}
            tone="primary"
            href="/app/trips"
            isLoading={metrics.isLoading}
          />
          <KPICard
            label="REVENUS"
            value={formatCurrency(metrics.data?.totalRevenue)}
            delta={revenueDelta.delta}
            trend={revenueSeries.slice(-7).map(p => p.value)}
            tone="success"
            href="/app/booking-intents"
            isLoading={metrics.isLoading}
          />
          <KPICard
            label="NOTE MOYENNE"
            value={formatRating(metrics.data?.averageRating)}
            delta={null}
            tone="warning"
            href="/app/feedbacks"
            isLoading={metrics.isLoading}
          />
        </div>
      </section>

      {/* Growth charts */}
      <section aria-label="Croissance">
        <div className="grid grid-cols-1 gap-6 lg:grid-cols-2">
          <AreaChartCard
            title="Inscriptions utilisateurs"
            description="Nouveaux comptes créés sur la période sélectionnée."
            data={usersSeries}
            isLoading={usersChart.isLoading}
            valueFormatter={v => formatNumber(v)}
            dataKeyLabel="Inscriptions"
          />
          <BarChartCard
            title="Revenus capturés"
            description="Somme des booking intents encaissés."
            data={revenueSeries}
            isLoading={revenueChart.isLoading}
            valueFormatter={v => formatCurrency(v)}
            tone="success"
          />
        </div>
      </section>

      {/* Breakdowns */}
      <section aria-label="Répartitions">
        <div className="grid grid-cols-1 gap-6 lg:grid-cols-2">
          <DonutChartCard
            title="Statuts des voyages"
            description="Sur les 200 voyages les plus récents."
            data={tripStatusData}
            isLoading={tripsForStatus.isLoading}
          />
          <DistributionChartCard
            title="Distribution des notes"
            description="Répartition des retours par étoiles."
            data={feedbacksSeries}
            isLoading={feedbacksChart.isLoading}
          />
        </div>
      </section>

      {/* Activity feed */}
      <section aria-label="Activité">
        <ActivityFeed items={activity.data?.data ?? []} isLoading={activity.isLoading} />
      </section>
    </div>
  )
}
