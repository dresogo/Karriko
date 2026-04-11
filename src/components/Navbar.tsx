'use client'

import Link from 'next/link'
import { useState } from 'react'
import { FontAwesomeIcon } from '@fortawesome/react-fontawesome'
import { faBell, faQuestion } from '@fortawesome/free-solid-svg-icons'

export default function Navbar() {
  const [isMenuOpen, setIsMenuOpen] = useState(false)

  return (
    <nav className="sticky top-0 z-50 border-b border-[#e5e7eb] bg-white/95 backdrop-blur-sm shadow-sm">
      <div className="mx-auto flex max-w-7xl items-center justify-between px-8 py-4">
        {/* Logo */}
        <Link href="/" className="font-serif-display text-xl font-light tracking-tight text-[#111827]">
          Karriko
        </Link>

        {/* Links - Desktop */}
        <div className="hidden md:flex md:items-center md:gap-1">
          <Link href="/jobs" className="px-3 py-1.5 text-sm font-medium text-[#374151] rounded-lg transition hover:bg-[#e5e7eb]">
            Job Market
          </Link>
          <Link href="/" className="px-3 py-1.5 text-sm font-medium text-[#374151] rounded-lg transition hover:bg-[#e5e7eb]">
            Reviews
          </Link>
          <Link href="/company" className="px-3 py-1.5 text-sm font-medium text-[#374151] rounded-lg transition hover:bg-[#e5e7eb]">
            Companies
          </Link>
        </div>

        {/* Right Icons - Desktop */}
        <div className="hidden md:flex md:items-center md:gap-3">
          <button 
            className="inline-flex items-center justify-center rounded-full transition text-[#6b7280] hover:text-[#111827] p-1"
            title="Benachrichtigungen"
          >
            <FontAwesomeIcon icon={faBell} className="text-lg" />
          </button>
          <button 
            className="inline-flex items-center justify-center rounded-full transition text-[#6b7280] hover:text-[#111827] p-1"
            title="Hilfe"
          >
            <FontAwesomeIcon icon={faQuestion} className="text-lg" />
          </button>
          <div className="inline-flex items-center justify-center rounded-full bg-[#1a3a2a] w-9 h-9 text-xs font-bold text-white cursor-pointer">
            AC
          </div>
        </div>

        {/* Mobile Menu Button */}
        <div className="flex items-center md:hidden">
          <button
            onClick={() => setIsMenuOpen(!isMenuOpen)}
            className="inline-flex items-center justify-center rounded-md p-2 text-[#6b7280] transition hover:bg-[#f5f5f5] hover:text-[#111827]"
          >
            <span className="sr-only">Navigation �ffnen</span>
            <svg className="h-6 w-6" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d={isMenuOpen ? 'M6 18L18 6M6 6l12 12' : 'M4 6h16M4 12h16M4 18h16'} />
            </svg>
          </button>
        </div>
      </div>

      {/* Mobile Menu */}
      {isMenuOpen && (
        <div className="border-t border-[#e5e7eb] bg-white px-4 py-3 md:hidden">
          <div className="flex flex-col gap-2">
            <Link href="/jobs" className="px-3 py-2 text-sm font-medium text-[#374151] rounded-lg transition hover:bg-[#f5f5f5]">
              Job Market
            </Link>
            <Link href="/" className="px-3 py-2 text-sm font-medium text-[#374151] rounded-lg transition hover:bg-[#f5f5f5]">
              Reviews
            </Link>
            <Link href="/company" className="px-3 py-2 text-sm font-medium text-[#374151] rounded-lg transition hover:bg-[#f5f5f5]">
              Companies
            </Link>
          </div>
        </div>
      )}
    </nav>
  )
}
