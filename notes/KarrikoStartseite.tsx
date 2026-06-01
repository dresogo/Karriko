import { useState } from "react";

// ─── Types ───────────────────────────────────────────────────────────────────

interface JobListing {
  id: number;
  title: string;
  company: string;
  location: string;
  badge: string;
  badgeVariant: "new" | "recent" | "days";
  icon: string;
  iconBg: string;
}

interface Review {
  id: number;
  author: string;
  rating: number;
  text: string;
  isAnonymous: boolean;
}

// ─── Data ─────────────────────────────────────────────────────────────────────

const JOB_LISTINGS: JobListing[] = [
  {
    id: 1,
    title: "Fachinformatiker (m/w/d)",
    company: "TechSolutions GmbH",
    location: "München",
    badge: "Vor 2 Tagen",
    badgeVariant: "days",
    icon: "💻",
    iconBg: "#1a3a2a",
  },
  {
    id: 2,
    title: "Industriekaufmann (m/w/d)",
    company: "Global Logistics AG",
    location: "Hamburg",
    badge: "Vor 4 Tagen",
    badgeVariant: "days",
    icon: "📦",
    iconBg: "#c8b89a",
  },
  {
    id: 3,
    title: "Mediengestalter (m/w/d)",
    company: "Creative Pulse Media",
    location: "Berlin",
    badge: "Gestern",
    badgeVariant: "recent",
    icon: "🎨",
    iconBg: "#e8d5b0",
  },
  {
    id: 4,
    title: "Mechatroniker (m/w/d)",
    company: "AutoTech Solutions",
    location: "Stuttgart",
    badge: "Neu",
    badgeVariant: "new",
    icon: "⚙️",
    iconBg: "#1a3a2a",
  },
];

const REVIEWS: Review[] = [
  {
    id: 1,
    author: "Anonym",
    rating: 5,
    text: "Super Einarbeitung und tolles Team. Man darf von Anfang an Verantwortung übernehmen.",
    isAnonymous: true,
  },
  {
    id: 2,
    author: "Lukas M.",
    rating: 4,
    text: "Die Vergütung ist top, aber die Arbeitszeiten sind manchmal etwas lang.",
    isAnonymous: false,
  },
  {
    id: 3,
    author: "Sarah K.",
    rating: 5,
    text: "Beste Entscheidung meines Lebens. Die Projekte sind abwechslungsreich und modern.",
    isAnonymous: false,
  },
  {
    id: 4,
    author: "Anonym",
    rating: 3,
    text: "Solide Ausbildung, aber die digitale Ausstattung könnte besser sein.",
    isAnonymous: true,
  },
  {
    id: 5,
    author: "Jonas W.",
    rating: 4,
    text: "Sehr familiäre Atmosphäre. Hier wird man als Mensch geschätzt, nicht nur als Azubi.",
    isAnonymous: false,
  },
  {
    id: 6,
    author: "Elena R.",
    rating: 3,
    text: "Gute Struktur, aber die Lerninhalte sind teilweise etwas veraltet.",
    isAnonymous: false,
  },
];

const POPULAR_SEARCHES = ["Informatik", "Berlin", "Nachhaltigkeit"];

const FOOTER_LINKS = {
  Rechtliches: ["Impressum", "Datenschutz", "AGB"],
  Plattform: ["Job Market", "Unternehmen", "Community"],
  Support: ["Hilfe Center", "Kontakt", "Accessibility"],
};

// ─── Sub-components ───────────────────────────────────────────────────────────

function StarRating({ rating, max = 5 }: { rating: number; max?: number }) {
  return (
    <div style={{ display: "flex", gap: "2px" }}>
      {Array.from({ length: max }).map((_, i) => (
        <span
          key={i}
          style={{
            color: i < rating ? "#1a3a2a" : "#d1d5db",
            fontSize: "13px",
          }}
        >
          ★
        </span>
      ))}
    </div>
  );
}

function BadgePill({
  text,
  variant,
}: {
  text: string;
  variant: "new" | "recent" | "days";
}) {
  const styles: Record<string, React.CSSProperties> = {
    new: {
      background: "#1a3a2a",
      color: "#fff",
      fontSize: "11px",
      fontWeight: 600,
      padding: "3px 10px",
      borderRadius: "999px",
      letterSpacing: "0.04em",
      textTransform: "uppercase" as const,
    },
    recent: {
      background: "#f0fdf4",
      color: "#1a3a2a",
      border: "1px solid #bbf7d0",
      fontSize: "11px",
      fontWeight: 500,
      padding: "3px 10px",
      borderRadius: "999px",
    },
    days: {
      background: "#f5f5f5",
      color: "#6b7280",
      fontSize: "11px",
      fontWeight: 400,
      padding: "3px 10px",
      borderRadius: "999px",
    },
  };

  return <span style={styles[variant]}>{text}</span>;
}

function JobCard({ job }: { job: JobListing }) {
  const [hovered, setHovered] = useState(false);

  return (
    <div
      onMouseEnter={() => setHovered(true)}
      onMouseLeave={() => setHovered(false)}
      style={{
        background: "#fff",
        borderRadius: "16px",
        padding: "24px",
        border: "1px solid #e5e7eb",
        cursor: "pointer",
        transition: "box-shadow 0.2s ease, transform 0.2s ease",
        boxShadow: hovered
          ? "0 8px 32px rgba(26,58,42,0.12)"
          : "0 1px 4px rgba(0,0,0,0.04)",
        transform: hovered ? "translateY(-2px)" : "none",
        display: "flex",
        flexDirection: "column",
        gap: "14px",
        minWidth: 0,
      }}
    >
      {/* Top row: icon + badge */}
      <div
        style={{
          display: "flex",
          justifyContent: "space-between",
          alignItems: "flex-start",
        }}
      >
        <div
          style={{
            width: 40,
            height: 40,
            borderRadius: "10px",
            background: job.iconBg,
            display: "flex",
            alignItems: "center",
            justifyContent: "center",
            fontSize: "18px",
          }}
        >
          {job.icon}
        </div>
        <BadgePill text={job.badge} variant={job.badgeVariant} />
      </div>

      {/* Job info */}
      <div>
        <div
          style={{
            fontFamily: "'DM Serif Display', Georgia, serif",
            fontSize: "16px",
            fontWeight: 600,
            color: "#111827",
            lineHeight: 1.3,
            marginBottom: "4px",
          }}
        >
          {job.title}
        </div>
        <div style={{ fontSize: "13px", color: "#6b7280" }}>{job.company}</div>
      </div>

      {/* Location */}
      <div
        style={{
          display: "flex",
          alignItems: "center",
          gap: "4px",
          fontSize: "12px",
          color: "#9ca3af",
        }}
      >
        <span>📍</span>
        <span>{job.location}</span>
      </div>
    </div>
  );
}

function ReviewCard({ review }: { review: Review }) {
  return (
    <div
      style={{
        background: "#fff",
        borderRadius: "16px",
        padding: "24px",
        border: "1px solid #e5e7eb",
        display: "flex",
        flexDirection: "column",
        gap: "12px",
      }}
    >
      <div style={{ display: "flex", alignItems: "center", gap: "12px" }}>
        <div
          style={{
            width: 36,
            height: 36,
            borderRadius: "50%",
            background: "#f3f4f6",
            display: "flex",
            alignItems: "center",
            justifyContent: "center",
            fontSize: "18px",
            color: "#9ca3af",
          }}
        >
          👤
        </div>
        <div>
          <div
            style={{
              fontSize: "14px",
              fontWeight: 600,
              color: "#111827",
              fontFamily: "'DM Serif Display', Georgia, serif",
            }}
          >
            {review.author}
          </div>
          <StarRating rating={review.rating} />
        </div>
      </div>
      <p
        style={{
          fontSize: "13px",
          color: "#4b5563",
          lineHeight: 1.6,
          margin: 0,
        }}
      >
        "{review.text}"
      </p>
    </div>
  );
}

// ─── Main Component ───────────────────────────────────────────────────────────

export default function KarrikoStartseite() {
  const [searchValue, setSearchValue] = useState("");

  return (
    <div
      style={{
        fontFamily: "'DM Sans', 'Helvetica Neue', sans-serif",
        background: "#f4f6f4",
        minHeight: "100vh",
        color: "#111827",
      }}
    >
      {/* ── Google Fonts ── */}
      <style>{`
        @import url('https://fonts.googleapis.com/css2?family=DM+Serif+Display&family=DM+Sans:wght@300;400;500;600&display=swap');

        * { box-sizing: border-box; }

        .karriko-search-input::placeholder { color: #9ca3af; }
        .karriko-search-input:focus { outline: none; box-shadow: 0 0 0 2px #1a3a2a; }

        .karriko-nav-link {
          text-decoration: none;
          font-size: 14px;
          font-weight: 500;
          color: #374151;
          padding: 6px 12px;
          border-radius: 8px;
          transition: background 0.15s;
        }
        .karriko-nav-link:hover { background: #e5e7eb; }

        .karriko-tag {
          background: #fff;
          border: 1px solid #e5e7eb;
          border-radius: 999px;
          padding: 4px 14px;
          font-size: 13px;
          color: #374151;
          cursor: pointer;
          transition: border-color 0.15s, background 0.15s;
        }
        .karriko-tag:hover { border-color: #1a3a2a; background: #f0fdf4; }

        .karriko-btn-primary {
          background: #1a3a2a;
          color: #fff;
          border: none;
          border-radius: 10px;
          padding: 12px 28px;
          font-size: 14px;
          font-weight: 600;
          cursor: pointer;
          transition: background 0.15s, transform 0.1s;
        }
        .karriko-btn-primary:hover { background: #112519; transform: translateY(-1px); }

        .karriko-footer-link {
          color: #6b7280;
          text-decoration: none;
          font-size: 12px;
          letter-spacing: 0.04em;
          text-transform: uppercase;
          transition: color 0.15s;
        }
        .karriko-footer-link:hover { color: #1a3a2a; }

        .jobs-grid {
          display: grid;
          grid-template-columns: repeat(4, 1fr);
          gap: 20px;
        }

        .reviews-grid {
          display: grid;
          grid-template-columns: repeat(3, 1fr);
          gap: 20px;
        }

        @media (max-width: 900px) {
          .jobs-grid { grid-template-columns: repeat(2, 1fr); }
          .reviews-grid { grid-template-columns: repeat(2, 1fr); }
        }
        @media (max-width: 600px) {
          .jobs-grid { grid-template-columns: 1fr; }
          .reviews-grid { grid-template-columns: 1fr; }
        }
      `}</style>

      {/* ── Navigation ── */}
      <nav
        style={{
          background: "#fff",
          borderBottom: "1px solid #e5e7eb",
          position: "sticky",
          top: 0,
          zIndex: 50,
        }}
      >
        <div
          style={{
            maxWidth: "1200px",
            margin: "0 auto",
            padding: "0 32px",
            height: "60px",
            display: "flex",
            alignItems: "center",
            justifyContent: "space-between",
          }}
        >
          {/* Logo */}
          <span
            style={{
              fontFamily: "'DM Serif Display', Georgia, serif",
              fontSize: "20px",
              fontWeight: 400,
              color: "#111827",
              letterSpacing: "-0.02em",
            }}
          >
            Karriko
          </span>

          {/* Links */}
          <div style={{ display: "flex", gap: "4px" }}>
            {["Job Market", "Reviews", "Companies"].map((link) => (
              <a key={link} href="#" className="karriko-nav-link">
                {link}
              </a>
            ))}
          </div>

          {/* Right icons */}
          <div style={{ display: "flex", alignItems: "center", gap: "12px" }}>
            <button
              style={{
                background: "none",
                border: "none",
                cursor: "pointer",
                fontSize: "18px",
                color: "#6b7280",
                padding: "4px",
              }}
              title="Benachrichtigungen"
            >
              🔔
            </button>
            <button
              style={{
                background: "none",
                border: "none",
                cursor: "pointer",
                fontSize: "18px",
                color: "#6b7280",
                padding: "4px",
              }}
              title="Hilfe"
            >
              ❓
            </button>
            <div
              style={{
                width: 36,
                height: 36,
                borderRadius: "50%",
                background: "#1a3a2a",
                color: "#fff",
                display: "flex",
                alignItems: "center",
                justifyContent: "center",
                fontSize: "13px",
                fontWeight: 700,
                cursor: "pointer",
              }}
            >
              AC
            </div>
          </div>
        </div>
      </nav>

      {/* ── Hero ── */}
      <section
        style={{
          background: "linear-gradient(160deg, #eef2ee 0%, #f4f6f4 60%, #e8f0e8 100%)",
          padding: "96px 32px 80px",
          textAlign: "center",
        }}
      >
        <div style={{ maxWidth: "680px", margin: "0 auto" }}>
          <h1
            style={{
              fontFamily: "'DM Serif Display', Georgia, serif",
              fontSize: "clamp(40px, 6vw, 64px)",
              fontWeight: 400,
              lineHeight: 1.1,
              letterSpacing: "-0.03em",
              color: "#0d1f16",
              margin: "0 0 20px",
            }}
          >
            Der transparente Kompass für deine Karriere.
          </h1>
          <p
            style={{
              fontSize: "16px",
              color: "#4b5563",
              lineHeight: 1.6,
              margin: "0 0 40px",
              fontWeight: 300,
            }}
          >
            Finde Ausbildungsplätze, die wirklich zu dir passen. Basierend auf
            echten Erfahrungen und kuratierten Daten.
          </p>

          {/* Search bar */}
          <div
            style={{
              display: "flex",
              background: "#fff",
              borderRadius: "14px",
              padding: "8px 8px 8px 20px",
              border: "1px solid #e5e7eb",
              boxShadow: "0 4px 24px rgba(0,0,0,0.06)",
              alignItems: "center",
              gap: "8px",
              maxWidth: "560px",
              margin: "0 auto 20px",
            }}
          >
            <span style={{ fontSize: "18px", color: "#9ca3af" }}>🔍</span>
            <input
              className="karriko-search-input"
              type="text"
              placeholder="Suche nach Unternehmen, Stadt oder Branche"
              value={searchValue}
              onChange={(e) => setSearchValue(e.target.value)}
              style={{
                flex: 1,
                border: "none",
                background: "transparent",
                fontSize: "14px",
                color: "#111827",
                fontFamily: "inherit",
              }}
            />
            <button className="karriko-btn-primary">Suchen</button>
          </div>

          {/* Popular searches */}
          <div
            style={{
              display: "flex",
              justifyContent: "center",
              alignItems: "center",
              gap: "8px",
              flexWrap: "wrap",
            }}
          >
            <span style={{ fontSize: "13px", color: "#9ca3af" }}>
              Beliebte Suchen:
            </span>
            {POPULAR_SEARCHES.map((tag) => (
              <button
                key={tag}
                className="karriko-tag"
                onClick={() => setSearchValue(tag)}
              >
                {tag}
              </button>
            ))}
          </div>
        </div>
      </section>

      {/* ── Aktuelle Ausbildungsplätze ── */}
      <section style={{ padding: "72px 32px" }}>
        <div style={{ maxWidth: "1200px", margin: "0 auto" }}>
          <div
            style={{
              display: "flex",
              justifyContent: "space-between",
              alignItems: "flex-end",
              marginBottom: "28px",
            }}
          >
            <div>
              <h2
                style={{
                  fontFamily: "'DM Serif Display', Georgia, serif",
                  fontSize: "28px",
                  fontWeight: 400,
                  color: "#111827",
                  margin: "0 0 4px",
                  letterSpacing: "-0.02em",
                }}
              >
                Aktuelle Ausbildungsplätze
              </h2>
              <p style={{ fontSize: "13px", color: "#9ca3af", margin: 0 }}>
                Die neuesten Einstiegsmöglichkeiten für dich.
              </p>
            </div>
            <a
              href="#"
              style={{
                fontSize: "13px",
                color: "#1a3a2a",
                fontWeight: 600,
                textDecoration: "none",
                display: "flex",
                alignItems: "center",
                gap: "4px",
              }}
            >
              Alle Jobs ansehen →
            </a>
          </div>

          <div className="jobs-grid">
            {JOB_LISTINGS.map((job) => (
              <JobCard key={job.id} job={job} />
            ))}
          </div>
        </div>
      </section>

      {/* ── Neueste Bewertungen ── */}
      <section
        style={{
          padding: "72px 32px",
          background: "#f9fafb",
          borderTop: "1px solid #e5e7eb",
          borderBottom: "1px solid #e5e7eb",
        }}
      >
        <div style={{ maxWidth: "1200px", margin: "0 auto" }}>
          <div style={{ textAlign: "center", marginBottom: "48px" }}>
            <h2
              style={{
                fontFamily: "'DM Serif Display', Georgia, serif",
                fontSize: "32px",
                fontWeight: 400,
                color: "#111827",
                margin: "0 0 8px",
                letterSpacing: "-0.02em",
              }}
            >
              Neueste Bewertungen
            </h2>
            <p style={{ fontSize: "14px", color: "#9ca3af", margin: 0 }}>
              Ehrliche Einblicke von Azubis für Azubis. Ohne Filter.
            </p>
          </div>

          <div className="reviews-grid">
            {REVIEWS.map((review) => (
              <ReviewCard key={review.id} review={review} />
            ))}
          </div>
        </div>
      </section>

      {/* ── Footer ── */}
      <footer
        style={{
          background: "#fff",
          borderTop: "1px solid #e5e7eb",
          padding: "48px 32px 32px",
        }}
      >
        <div
          style={{
            maxWidth: "1200px",
            margin: "0 auto",
            display: "grid",
            gridTemplateColumns: "2fr 1fr 1fr 1fr",
            gap: "40px",
          }}
        >
          {/* Brand */}
          <div>
            <div
              style={{
                fontFamily: "'DM Serif Display', Georgia, serif",
                fontSize: "20px",
                color: "#111827",
                marginBottom: "8px",
              }}
            >
              Karriko
            </div>
            <div
              style={{
                fontSize: "11px",
                color: "#9ca3af",
                letterSpacing: "0.06em",
                textTransform: "uppercase",
              }}
            >
              © 2024 Karriko. The Transparent Curator
            </div>
          </div>

          {/* Footer links */}
          {Object.entries(FOOTER_LINKS).map(([heading, links]) => (
            <div key={heading}>
              <div
                style={{
                  fontSize: "11px",
                  fontWeight: 700,
                  letterSpacing: "0.08em",
                  textTransform: "uppercase",
                  color: "#374151",
                  marginBottom: "16px",
                }}
              >
                {heading}
              </div>
              <div style={{ display: "flex", flexDirection: "column", gap: "10px" }}>
                {links.map((link) => (
                  <a key={link} href="#" className="karriko-footer-link">
                    {link}
                  </a>
                ))}
              </div>
            </div>
          ))}
        </div>
      </footer>
    </div>
  );
}
