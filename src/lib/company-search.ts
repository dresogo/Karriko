import { prisma } from '@/lib/prisma'

export interface CompanySearchResult {
  id: string
  name: string
  slug: string
  description: string | null
  industry: string | null
  location: string | null
  verified: boolean
}

function normalizeSearchValue(value: string) {
  return value
    .toLowerCase()
    .normalize('NFD')
    .replace(/\p{Diacritic}/gu, '')
}

function scoreCompany(company: CompanySearchResult, normalizedQuery: string) {
  const haystack = normalizeSearchValue([
    company.name,
    company.description ?? '',
    company.industry ?? '',
    company.location ?? '',
    company.slug,
  ].join(' '))

  if (!normalizedQuery) {
    return company.verified ? 2 : 1
  }

  if (normalizeSearchValue(company.name).startsWith(normalizedQuery)) {
    return 100
  }

  if (normalizeSearchValue(company.name).includes(normalizedQuery)) {
    return 90
  }

  if (company.industry && normalizeSearchValue(company.industry).includes(normalizedQuery)) {
    return 80
  }

  if (company.location && normalizeSearchValue(company.location).includes(normalizedQuery)) {
    return 70
  }

  if (haystack.includes(normalizedQuery)) {
    return 40
  }

  return 0
}

export async function searchCompanies(query: string, limit = 6) {
  let companies: CompanySearchResult[] = []

  try {
    companies = (await prisma.company.findMany({
      select: {
        id: true,
        name: true,
        slug: true,
        description: true,
        industry: true,
        location: true,
        verified: true,
      },
      orderBy: [
        { verified: 'desc' },
        { name: 'asc' },
      ],
    })) as CompanySearchResult[]
  } catch {
    return []
  }

  const normalizedQuery = normalizeSearchValue(query.trim())

  type ScoredCompany = {
    company: CompanySearchResult
    score: number
  }

  return companies
    .map<ScoredCompany>((company) => ({
      company,
      score: scoreCompany(company, normalizedQuery),
    }))
    .filter((entry: ScoredCompany) => entry.score > 0)
    .sort((left: ScoredCompany, right: ScoredCompany) => right.score - left.score || left.company.name.localeCompare(right.company.name, 'de'))
    .slice(0, limit)
    .map((entry: ScoredCompany) => entry.company)
}
