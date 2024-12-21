import type { Metadata } from 'next'
import { Inter, Outfit } from 'next/font/google'
import './globals.css'

const inter = Inter({ subsets: ['latin'] })
const outfit = Outfit({ subsets: ['latin'], variable: '--font-outfit' })

export const metadata: Metadata = {
  title: 'baos.fun - Coming to Berachain in Q5',
  description: 'Custom AI Agents for Berachain yield farming',
}

export default function RootLayout({
  children,
}: {
  children: React.ReactNode
}) {
  return (
    <html lang="en" className={`${outfit.variable} dark`}>
      <body className={`${inter.className} min-h-screen bg-black`}>{children}</body>
    </html>
  )
} 