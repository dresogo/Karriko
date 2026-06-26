import { NextResponse } from 'next/server'
import { searchCompanies } from '@/lib/company-search'

export async function GET(request: Request) {
  try {
    const { searchParams } = new URL(request.url)
    const query = searchParams.get('q') ?? ''
    const suggestions = await searchCompanies(query, 5)

    return NextResponse.json({ suggestions })
  } catch (error) {
    console.error('search-suggestions failed', error)
    return NextResponse.json({ suggestions: [] }, { status: 200 })
  }
}
