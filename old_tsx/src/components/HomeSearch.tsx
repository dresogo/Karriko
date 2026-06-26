'use client'

import Link from 'next/link'
import { useEffect, useId, useState } from 'react'

interface SearchSuggestion {
  id: string
  name: string
  slug: string
  description: string | null
  industry: string | null
  location: string | null
  verified: boolean
}

export default function HomeSearch() {
  const inputId = useId()
  const [query, setQuery] = useState('')
  const [isFocused, setIsFocused] = useState(false)
  const [suggestions, setSuggestions] = useState<SearchSuggestion[]>([])

  const showSuggestions = isFocused && suggestions.length > 0

  useEffect(() => {
    const trimmedQuery = query.trim()

    if (!trimmedQuery) {
      setSuggestions([])
      return
    }

    const controller = new AbortController()
    const timeoutId = window.setTimeout(async () => {
      try {
        const response = await fetch(`/api/search-suggestions?q=${encodeURIComponent(trimmedQuery)}`, {
          signal: controller.signal,
        })

        if (!response.ok) {
          setSuggestions([])
          return
        }

        const data: { suggestions?: SearchSuggestion[] } = await response.json()
        setSuggestions(data.suggestions ?? [])
      } catch (error) {
        if (!(error instanceof DOMException && error.name === 'AbortError')) {
          setSuggestions([])
        }
      }
    }, 180)

    return () => {
      controller.abort()
      window.clearTimeout(timeoutId)
    }
  }, [query])

  return (
    <form className="search-panel" role="search" aria-label="Ausbildungsbetrieb suchen" action="/suche" method="get">
      <label htmlFor={inputId}>Ausbildungsbetrieb, Beruf oder Ort suchen</label>

      <div className="search-field-group">
        <div className="search-row">
          <input
            id={inputId}
            name="q"
            type="search"
            placeholder="z. B. Mechatroniker Berlin, Bosch, Wien"
            autoComplete="off"
            value={query}
            onChange={(event) => setQuery(event.target.value)}
            onFocus={() => setIsFocused(true)}
            onBlur={() => {
              window.setTimeout(() => setIsFocused(false), 120)
            }}
          />
          <button type="submit" aria-label="Suche starten">
            <svg aria-hidden="true" viewBox="0 0 24 24">
              <path d="m21 21-4.35-4.35m1.35-5.15a6.5 6.5 0 1 1-13 0 6.5 6.5 0 0 1 13 0Z" />
            </svg>
          </button>
        </div>

        {showSuggestions ? (
          <div className="search-suggestions" role="listbox" aria-label="Suchvorschläge">
            {suggestions.map((suggestion) => (
              <Link
                key={suggestion.id}
                className="search-suggestion"
                href={`/suche?q=${encodeURIComponent(suggestion.name)}`}
                onMouseDown={(event) => event.preventDefault()}
              >
                <span className="search-suggestion-title">{suggestion.name}</span>
                <span className="search-suggestion-meta">
                  {suggestion.industry ?? 'Betrieb'}
                  {suggestion.location ? ` · ${suggestion.location}` : ''}
                  {suggestion.verified ? ' · Verifiziert' : ''}
                </span>
                <span className="search-suggestion-description">{suggestion.description}</span>
              </Link>
            ))}
          </div>
        ) : null}
      </div>
    </form>
  )
}
