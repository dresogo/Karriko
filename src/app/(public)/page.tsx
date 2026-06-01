import HomeSearch from '@/components/HomeSearch'

export default function HomePage() {
  return (
    <main>
      <section className="hero" aria-labelledby="hero-title">
        <div className="hero-grid">
          <div className="hero-copy">
            <p className="eyebrow">Ausbildung transparent machen</p>
            <h1 id="hero-title">Bewertungen fuer duale Ausbildung im DACH-Markt.</h1>
          </div>

          <HomeSearch />
        </div>
      </section>

      <section className="metrics" aria-label="Plattform Kennzahlen">
        <div>
          <span className="metric-value">3</span>
          <span className="metric-label">Nutzertypen</span>
        </div>
        <div>
          <span className="metric-value">DACH</span>
          <span className="metric-label">Fokusmarkt</span>
        </div>
        <div>
          <span className="metric-value">DSGVO</span>
          <span className="metric-label">von Beginn an</span>
        </div>
      </section>

      <section className="section-grid" id="bewertungen">
        <div className="section-heading">
          <p className="eyebrow">Fuer Azubis</p>
          <h2>Klare Einblicke, bevor die Bewerbung rausgeht.</h2>
        </div>
        <div className="feature-list">
          <article>
            <span>01</span>
            <h3>Bewerten</h3>
            <p>Ausbildungsqualitaet, Betreuung, Lernkultur und Uebernahmechancen strukturiert einordnen.</p>
          </article>
          <article>
            <span>02</span>
            <h3>Vergleichen</h3>
            <p>Betriebe nach Beruf, Standort und Erfahrungswerten anderer Auszubildender entdecken.</p>
          </article>
          <article>
            <span>03</span>
            <h3>Vertrauen</h3>
            <p>Moderierte Rezensionen schaffen hilfreiche Orientierung ohne unnoetige Komplexitaet.</p>
          </article>
        </div>
      </section>

      <section className="audience-band" id="betriebe">
        <div className="audience-card">
          <span>Azubi</span>
          <p>Erfahrungen teilen, Betriebe finden, Ausbildung realistischer einschaetzen.</p>
        </div>
        <div className="audience-card">
          <span>Betrieb</span>
          <p>Profil pflegen, Feedback verstehen, Ausbildung als Qualitaetsmerkmal zeigen.</p>
        </div>
        <div className="audience-card">
          <span>Stellen</span>
          <p>Moderation, Datenschutzprozesse und Plattformqualitaet zentral steuern.</p>
        </div>
      </section>

      <section className="privacy-section" id="datenschutz">
        <div>
          <p className="eyebrow">Privacy by design</p>
          <h2>Datenschutz ist kein Zusatzmodul.</h2>
        </div>
        <p>
          RLS-Policies, AVV-Anforderungen und eine DSGVO-konforme Architektur sind als Produktprinzipien angelegt.
          Die Gestaltung bleibt bewusst ruhig, damit Vertrauen, Nachvollziehbarkeit und Bewertungsqualitaet im
          Vordergrund stehen.
        </p>
      </section>
    </main>
  )
}
