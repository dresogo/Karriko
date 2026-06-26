'use client'

import { useState } from 'react'

export interface JobListing {
  id: number
  title: string
  company: string
  location: string
  badge: string
  badgeVariant: 'new' | 'recent' | 'days'
  icon: string
  iconBg: string
}

const badgeStyles = {
  new: 'bg-[#1a3a2a] text-white text-xs font-semibold px-2.5 py-0.5 rounded-full uppercase tracking-wider',
  recent: 'bg-[#f0fdf4] text-[#1a3a2a] border border-[#bbf7d0] text-xs font-medium px-2.5 py-0.5 rounded-full',
  days: 'bg-[#f5f5f5] text-[#6b7280] text-xs font-normal px-2.5 py-0.5 rounded-full',
}

export default function JobCard({ job }: { job: JobListing }) {
  const [hovered, setHovered] = useState(false)

  return (
    <div
      onMouseEnter={() => setHovered(true)}
      onMouseLeave={() => setHovered(false)}
      className={`karriko-card cursor-pointer gap-3.5 flex flex-col transition-all ${
        hovered
          ? 'shadow-lg shadow-[rgba(26,58,42,0.12)] -translate-y-0.5'
          : 'shadow-sm'
      }`}
    >
      {/* Top row: icon + badge */}
      <div className="flex items-start justify-between">
        <div
          className="w-10 h-10 rounded-[10px] flex items-center justify-center text-lg"
          style={{ backgroundColor: job.iconBg }}
        >
          {job.icon}
        </div>
        <span className={badgeStyles[job.badgeVariant]}>{job.badge}</span>
      </div>

      {/* Job info */}
      <div>
        <h3 className="font-serif-display text-base font-semibold text-[#111827] leading-snug mb-1">
          {job.title}
        </h3>
        <p className="text-xs text-[#6b7280]">{job.company}</p>
      </div>

      {/* Location */}
      <div className="flex items-center gap-1 text-xs text-[#9ca3af]">
        <span>📍</span>
        <span>{job.location}</span>
      </div>
    </div>
  )
}
