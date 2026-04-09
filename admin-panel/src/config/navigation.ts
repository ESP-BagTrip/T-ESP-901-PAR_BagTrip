import {
  LayoutDashboard,
  Users,
  Luggage,
  Share2,
  CreditCard,
  Plane,
  CalendarDays,
  BedDouble,
  ShoppingBag,
  Wallet,
  Search,
  MessageSquare,
  Bell,
  UserCircle,
  IdCard,
  Settings,
  type LucideIcon,
} from 'lucide-react'

export interface NavItem {
  href: string
  label: string
  icon: LucideIcon
  /** Optional keyword(s) to improve command palette fuzzy search. */
  keywords?: string[]
  /** When true, the item is only shown in development. */
  devOnly?: boolean
}

export interface NavSection {
  label: string
  items: NavItem[]
}

/**
 * Single source of truth for the admin shell navigation.
 * Consumed by Sidebar, Breadcrumb, CommandPalette.
 */
export const NAV_SECTIONS: NavSection[] = [
  {
    label: 'Vue d’ensemble',
    items: [
      { href: '/app', label: 'Overview', icon: LayoutDashboard, keywords: ['home', 'accueil'] },
    ],
  },
  {
    label: 'Croissance',
    items: [
      { href: '/app/users', label: 'Utilisateurs', icon: Users, keywords: ['users'] },
      { href: '/app/trips', label: 'Voyages', icon: Luggage, keywords: ['trips'] },
      { href: '/app/trip-shares', label: 'Partages', icon: Share2, keywords: ['shares'] },
    ],
  },
  {
    label: 'Revenus',
    items: [
      {
        href: '/app/booking-intents',
        label: 'Intentions de paiement',
        icon: CreditCard,
        keywords: ['booking', 'stripe', 'payments'],
      },
      {
        href: '/app/flight-bookings',
        label: 'Réservations vols',
        icon: Plane,
        keywords: ['bookings', 'amadeus'],
      },
    ],
  },
  {
    label: 'Contenu',
    items: [
      {
        href: '/app/activities',
        label: 'Activités',
        icon: CalendarDays,
        keywords: ['activities'],
      },
      {
        href: '/app/accommodations',
        label: 'Hébergements',
        icon: BedDouble,
        keywords: ['accommodations', 'hotels'],
      },
      { href: '/app/baggage', label: 'Bagages', icon: ShoppingBag, keywords: ['baggage'] },
      { href: '/app/budget', label: 'Budget', icon: Wallet, keywords: ['budget'] },
      {
        href: '/app/flight-searches',
        label: 'Recherches vols',
        icon: Search,
        keywords: ['flights', 'searches'],
      },
    ],
  },
  {
    label: 'Communauté',
    items: [
      {
        href: '/app/feedbacks',
        label: 'Retours',
        icon: MessageSquare,
        keywords: ['feedbacks', 'ratings'],
      },
      { href: '/app/notifications', label: 'Notifications', icon: Bell, keywords: ['push'] },
      { href: '/app/travelers', label: 'Voyageurs', icon: UserCircle, keywords: ['travelers'] },
      {
        href: '/app/traveler-profiles',
        label: 'Profils voyageurs',
        icon: IdCard,
        keywords: ['profiles'],
      },
    ],
  },
]

/** Secondary section for less-used destinations (settings, dev tools). */
export const SECONDARY_NAV: NavItem[] = [
  { href: '/app/settings', label: 'Paramètres', icon: Settings, keywords: ['settings'] },
]

/** Flat list of all nav items — used by CommandPalette & Breadcrumb. */
export const ALL_NAV_ITEMS: NavItem[] = [
  ...NAV_SECTIONS.flatMap(section => section.items),
  ...SECONDARY_NAV,
]

/** Resolve a breadcrumb label for a given pathname. */
export function findNavItem(pathname: string): NavItem | undefined {
  // Prefer exact match first
  return (
    ALL_NAV_ITEMS.find(item => item.href === pathname) ??
    ALL_NAV_ITEMS.find(item => pathname.startsWith(`${item.href}/`))
  )
}
