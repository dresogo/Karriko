/**
 * Blog Artikel Details
 * 
 * Route: /blog/[slug]
 * Rendering: SSG + ISR
 * 
 * Frontmatter (Markdown):
 * - title
 * - description
 * - date
 * - category
 * - author
 * - image
 */

export async function generateMetadata({ params }: { params: { slug: string } }) {
  // TODO: Parse markdown frontmatter
  return {
    title: 'Artikel - Karriko',
    description: 'Blog Artikel'
  }
}

export default function BlogArticlePage({ params }: { params: { slug: string } }) {
  return (
    <article className="container mx-auto px-4 py-8 max-w-3xl">
      <header className="mb-8">
        <h1 className="text-4xl font-bold mb-4">
          {/* TODO: Article title */}
        </h1>
        <div className="flex gap-4 text-gray-600 mb-4">
          {/* TODO: Author, date, category */}
        </div>
        {/* TODO: Featured image */}
      </header>

      <div className="prose prose-lg max-w-none">
        {/* TODO: Article content from markdown */}
      </div>

      {/* Related Articles */}
      <section className="mt-16 pt-8 border-t">
        <h2 className="text-2xl font-bold mb-8">Weitere Artikel</h2>
        {/* TODO: Related articles */}
      </section>
    </article>
  )
}
