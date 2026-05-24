'use client'

import Link from 'next/link'
import { usePathname } from 'next/navigation'

import {
  Breadcrumb as BreadcrumbRoot,
  BreadcrumbItem,
  BreadcrumbLink,
  BreadcrumbList,
  BreadcrumbPage,
  BreadcrumbSeparator,
} from '@/components/ui/breadcrumb'
import { findNavItem } from '@/config/navigation'

/**
 * Derives breadcrumb trail from the current pathname.
 * Example: /app/users → [Overview, Utilisateurs]
 */
export function Breadcrumb() {
  const pathname = usePathname() ?? '/app'
  const trail = buildTrail(pathname)

  return (
    <BreadcrumbRoot>
      <BreadcrumbList>
        {trail.map((crumb, idx) => {
          const last = idx === trail.length - 1
          return (
            <span key={crumb.href} className="flex items-center gap-2">
              <BreadcrumbItem>
                {last ? (
                  <BreadcrumbPage>{crumb.label}</BreadcrumbPage>
                ) : (
                  <BreadcrumbLink asChild>
                    <Link href={crumb.href}>{crumb.label}</Link>
                  </BreadcrumbLink>
                )}
              </BreadcrumbItem>
              {!last && <BreadcrumbSeparator />}
            </span>
          )
        })}
      </BreadcrumbList>
    </BreadcrumbRoot>
  )
}

function buildTrail(pathname: string): Array<{ href: string; label: string }> {
  if (pathname === '/app') {
    return [{ href: '/app', label: 'Overview' }]
  }

  const match = findNavItem(pathname)
  return [
    { href: '/app', label: 'Overview' },
    { href: match?.href ?? pathname, label: match?.label ?? pathname },
  ]
}
