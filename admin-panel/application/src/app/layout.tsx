import type { Metadata } from 'next'
import { Providers } from '@/components/providers/Providers'
import './globals.css'

// Conditionally import next/font only when not in coverage mode
// This allows Babel instrumentation to work during coverage tests
let fontVariables = ''

if (process.env.CYPRESS_COVERAGE !== 'true') {
  // Dynamic import not possible at module level, so we use require conditionally
  // eslint-disable-next-line @typescript-eslint/no-require-imports
  const { Geist, Geist_Mono } = require('next/font/google')
  const geistSans = Geist({
    variable: '--font-geist-sans',
    subsets: ['latin'],
  })
  const geistMono = Geist_Mono({
    variable: '--font-geist-mono',
    subsets: ['latin'],
  })
  fontVariables = `${geistSans.variable} ${geistMono.variable}`
}

export const metadata: Metadata = {
  title: 'BagTrip Admin',
  description: 'Administration interface for BagTrip application',
}

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode
}>) {
  return (
    <html lang="fr">
      <body className={`${fontVariables} antialiased`}>
        <Providers>{children}</Providers>
      </body>
    </html>
  )
}
