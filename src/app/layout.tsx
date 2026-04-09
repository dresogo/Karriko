import type { Metadata } from 'next'
import { DM_Sans, DM_Serif_Display } from 'next/font/google'
import './globals.css'
import Navbar from '@/components/Navbar'
import Footer from '@/components/Footer'

const dmSans = DM_Sans({ subsets: ['latin'], variable: '--font-dm-sans' })
const dmSerifDisplay = DM_Serif_Display({ 
  subsets: ['latin'], 
  variable: '--font-dm-serif-display',
  weight: '400'
})

export const metadata: Metadata = {
  title: 'Karriko',
  description: 'Bewertungsplattform für Auszubildende und Ausbildungsbetriebe',
}

export default function RootLayout({
  children,
}: {
  children: React.ReactNode
}) {
  return (
    <html lang="de" className={`${dmSans.variable} ${dmSerifDisplay.variable}`}>
      <body className="bg-gradient-to-b from-emerald-50 via-emerald-25 to-white text-slate-900 antialiased">
        <Navbar />
        <main className="min-h-screen">
          {children}
        </main>
        <Footer />
      </body>
    </html>
  )
}