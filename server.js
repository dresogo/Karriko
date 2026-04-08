const express = require("express");
const cors = require("cors");
const bodyParser = require("body-parser");
const sqlite3 = require("sqlite3").verbose();
const fs = require("fs");
const path = require("path");

const app = express();
const port = 3000;

// Middleware
app.use(cors());
app.use(bodyParser.json());

// Statische Dateien servieren
app.use(express.static(path.join(__dirname)));

// --- SQLite Setup ---
const dbFile = path.resolve(__dirname, "karriko.db");
const initDbNeeded = !fs.existsSync(dbFile);

const dbConnection = new sqlite3.Database(dbFile);

// Wrapper um SQLite
const db = {
  query: function (sql, params, callback) {
    if (typeof params === "function") {
      callback = params;
      params = [];
    }
    const method = sql.trim().toUpperCase().startsWith("SELECT") ? "all" : "run";
    dbConnection[method](sql, params, function (err, rows) {
      if (method === "run") {
        const result = err ? null : { insertId: this.lastID, affectedRows: this.changes };
        callback(err, result);
      } else {
        callback(err, rows);
      }
    });
  },
};

// --- DB Initialisierung ---
if (initDbNeeded) {
  console.log("Erstelle Karriko Datenbank...");
  dbConnection.serialize(() => {
    // Tabellen
    dbConnection.run(`CREATE TABLE users (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      email TEXT UNIQUE,
      password TEXT,
      username TEXT,
      role TEXT DEFAULT 'azubi',
      bio TEXT,
      avatar_url TEXT,
      phone TEXT,
      created_at DATETIME DEFAULT CURRENT_TIMESTAMP
    )`);

    dbConnection.run(`CREATE TABLE companies (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      owner_user_id INTEGER,
      name TEXT,
      slug TEXT,
      description TEXT,
      industry TEXT,
      location TEXT,
      logo_url TEXT,
      header_image_url TEXT,
      custom_theme_json TEXT,
      verified INTEGER DEFAULT 0,
      created_at DATETIME DEFAULT CURRENT_TIMESTAMP
    )`);

    dbConnection.run(`CREATE TABLE review_categories (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT,
      sort_order INTEGER
    )`);

    dbConnection.run(`CREATE TABLE review_questions (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      category_id INTEGER,
      text TEXT,
      type TEXT DEFAULT 'stars',
      sort_order INTEGER
    )`);

    dbConnection.run(`CREATE TABLE reviews (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      company_id INTEGER,
      user_id INTEGER,
      username TEXT,
      is_anonymous INTEGER DEFAULT 0,
      weight REAL DEFAULT 1.0,
      overall_score REAL,
      text TEXT,
      created_at DATETIME DEFAULT CURRENT_TIMESTAMP
    )`);

    dbConnection.run(`CREATE TABLE review_answers (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      review_id INTEGER,
      question_id INTEGER,
      star_value INTEGER,
      text_value TEXT
    )`);

    dbConnection.run(`CREATE TABLE review_comments (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      review_id INTEGER,
      company_id INTEGER,
      text TEXT,
      created_at DATETIME DEFAULT CURRENT_TIMESTAMP
    )`);

    dbConnection.run(`CREATE TABLE review_helpful (
      review_id INTEGER,
      user_id INTEGER,
      created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
      PRIMARY KEY (review_id, user_id)
    )`);

    dbConnection.run(`CREATE TABLE job_listings (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      company_id INTEGER,
      title TEXT,
      description TEXT,
      location TEXT,
      start_date TEXT,
      requirements TEXT,
      image_url TEXT,
      is_active INTEGER DEFAULT 1,
      created_at DATETIME DEFAULT CURRENT_TIMESTAMP
    )`);

    dbConnection.run(`CREATE TABLE applications (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      job_id INTEGER,
      user_id INTEGER,
      status TEXT DEFAULT 'new',
      cv_url TEXT,
      cover_url TEXT,
      message TEXT,
      created_at DATETIME DEFAULT CURRENT_TIMESTAMP
    )`);

    // --- Seed: Bewertungskategorien & Fragen ---
    const cats = [
      { name: "Arbeitsumfeld & Atmosphäre", order: 1 },
      { name: "Ausbildungsqualität", order: 2 },
      { name: "Vergütung & Benefits", order: 3 },
      { name: "Work-Life-Balance", order: 4 },
      { name: "Karriere & Zukunftsperspektiven", order: 5 },
    ];

    const questions = {
      1: [
        { text: "Wie ist das allgemeine Arbeitsklima?", type: "stars", order: 1 },
        { text: "Wie gut ist die Zusammenarbeit im Team?", type: "stars", order: 2 },
        { text: "Wie respektvoll ist der Umgangston?", type: "stars", order: 3 },
        { text: "Wie modern ist die Arbeitsumgebung?", type: "stars", order: 4 },
        { text: "Gibt es regelmäßige Team-Events?", type: "stars", order: 5 },
      ],
      2: [
        { text: "Wie gut ist die fachliche Betreuung?", type: "stars", order: 1 },
        { text: "Werden die Ausbildungsinhalte eingehalten?", type: "stars", order: 2 },
        { text: "Wie hilfreich sind die Ausbilder?", type: "stars", order: 3 },
        { text: "Gibt es regelmäßige Feedback-Gespräche?", type: "stars", order: 4 },
        { text: "Wirst du auf Prüfungen gut vorbereitet?", type: "stars", order: 5 },
      ],
      3: [
        { text: "Wie fair ist die Ausbildungsvergütung?", type: "stars", order: 1 },
        { text: "Gibt es zusätzliche Benefits (z.B. Fahrtkostenzuschuss)?", type: "stars", order: 2 },
        { text: "Wird Urlaubs-/Weihnachtsgeld gezahlt?", type: "stars", order: 3 },
        { text: "Gibt es Übernahmeprämien?", type: "stars", order: 4 },
        { text: "Wie transparent ist die Gehaltsstruktur?", type: "stars", order: 5 },
      ],
      4: [
        { text: "Wie sind die Arbeitszeiten geregelt?", type: "stars", order: 1 },
        { text: "Gibt es flexible Arbeitszeiten?", type: "stars", order: 2 },
        { text: "Wie viele Überstunden fallen an?", type: "stars", order: 3 },
        { text: "Wird auf private Termine Rücksicht genommen?", type: "stars", order: 4 },
        { text: "Wie ist die Urlaubsregelung?", type: "stars", order: 5 },
      ],
      5: [
        { text: "Wie sind die Übernahmechancen nach der Ausbildung?", type: "stars", order: 1 },
        { text: "Gibt es Aufstiegsmöglichkeiten?", type: "stars", order: 2 },
        { text: "Werden Weiterbildungen gefördert?", type: "stars", order: 3 },
        { text: "Wie zukunftssicher ist der Ausbildungsberuf?", type: "stars", order: 4 },
        { text: "Würdest du den Betrieb weiterempfehlen?", type: "stars", order: 5 },
      ],
    };

    const stmtCat = dbConnection.prepare("INSERT INTO review_categories (name, sort_order) VALUES (?, ?)");
    cats.forEach(c => stmtCat.run(c.name, c.order));
    stmtCat.finalize();

    const stmtQ = dbConnection.prepare("INSERT INTO review_questions (category_id, text, type, sort_order) VALUES (?, ?, ?, ?)");
    Object.entries(questions).forEach(([catId, qs]) => {
      qs.forEach(q => stmtQ.run(parseInt(catId), q.text, q.type, q.order));
    });
    stmtQ.finalize();

    // --- Seed: Users ---
    const stmtUsers = dbConnection.prepare("INSERT INTO users (email, password, username, role) VALUES (?, ?, ?, ?)");
    stmtUsers.run("admin@karriko.de", "admin123", "Admin", "superadmin");
    stmtUsers.run("lisa@example.com", "pass123", "Lisa M.", "azubi");
    stmtUsers.run("tom@example.com", "pass123", "Tom K.", "azubi");
    stmtUsers.run("sarah@example.com", "pass123", "Sarah B.", "azubi");
    stmtUsers.run("max@technova.de", "pass123", "Max Weber", "unternehmen");
    stmtUsers.run("info@globallog.de", "pass123", "Anna Schmidt", "unternehmen");
    stmtUsers.finalize();

    // --- Seed: Companies ---
    const stmtComp = dbConnection.prepare("INSERT INTO companies (owner_user_id, name, slug, description, industry, location, logo_url, header_image_url) VALUES (?, ?, ?, ?, ?, ?, ?, ?)");
    stmtComp.run(5, "TechNova Solutions", "technova-solutions", "Führendes IT-Unternehmen mit über 200 Mitarbeitern. Spezialisiert auf Cloud-Lösungen und Softwareentwicklung.", "IT & Technologie", "Berlin", null, "https://images.unsplash.com/photo-1497366216548-37526070297c?auto=format&fit=crop&w=1200&q=80");
    stmtComp.run(6, "Global Logistics GmbH", "global-logistics", "Internationale Spedition und Logistikdienstleistungen mit Standorten in ganz Europa.", "Logistik & Transport", "Hamburg", null, "https://images.unsplash.com/photo-1586528116311-ad8dd3c8310d?auto=format&fit=crop&w=1200&q=80");
    stmtComp.run(null, "AutoWorks München", "autoworks-muenchen", "Innovatives Unternehmen in der Automobilindustrie und Fertigung.", "Automotive", "München", null, "https://images.unsplash.com/photo-1581091226033-d5c48150dbaa?auto=format&fit=crop&w=1200&q=80");
    stmtComp.run(null, "Creative Studio Berlin", "creative-studio-berlin", "Preisgekrönte Design- und Marketing-Agentur mit Fokus auf digitale Medien.", "Design & Marketing", "Berlin", null, "https://images.unsplash.com/photo-1626785774573-4b799314346d?auto=format&fit=crop&w=1200&q=80");
    stmtComp.run(null, "FinanzPartner AG", "finanzpartner-ag", "Traditionsreiches Finanzunternehmen mit modernem Ausbildungskonzept.", "Finanzen & Versicherung", "Frankfurt", null, "https://images.unsplash.com/photo-1560472354-b33ff0c44a43?auto=format&fit=crop&w=1200&q=80");
    stmtComp.run(null, "MediTech GmbH", "meditech-gmbh", "Innovatives Start-up im Bereich Medizintechnik und digitale Gesundheit.", "Medizintechnik", "Köln", null, "https://images.unsplash.com/photo-1576091160399-112ba8d25d1d?auto=format&fit=crop&w=1200&q=80");
    stmtComp.finalize();

    // --- Seed: Job Listings ---
    const stmtJobs = dbConnection.prepare("INSERT INTO job_listings (company_id, title, description, location, start_date, requirements, image_url) VALUES (?, ?, ?, ?, ?, ?, ?)");
    stmtJobs.run(1, "Fachinformatiker/in Anwendungsentwicklung", "Du lernst bei uns die Entwicklung moderner Webanwendungen mit React, Node.js und Cloud-Technologien. Unser erfahrenes Team begleitet dich durch die gesamte Ausbildung.", "Berlin", "2026-09-01", "Mittlere Reife oder Abitur, Interesse an Programmierung, Teamfähigkeit", "https://images.unsplash.com/photo-1498050108023-c5249f4df085?auto=format&fit=crop&w=400&q=80");
    stmtJobs.run(2, "Kaufmann/-frau für Spedition und Logistik", "Werde Teil unseres internationalen Teams und lerne die Welt der Logistik kennen. Von der Auftragsabwicklung bis zur Zollabfertigung.", "Hamburg", "2026-08-01", "Mittlere Reife, gute Englischkenntnisse, Organisationstalent", "https://images.unsplash.com/photo-1497215728101-856f4ea42174?auto=format&fit=crop&w=400&q=80");
    stmtJobs.run(3, "Mechatroniker/in", "Verbinde Mechanik, Elektronik und IT in einer spannenden Ausbildung. Arbeite an modernsten Fertigungsanlagen.", "München", "2026-09-01", "Guter Realschulabschluss, technisches Verständnis, handwerkliches Geschick", "https://images.unsplash.com/photo-1581091226033-d5c48150dbaa?auto=format&fit=crop&w=400&q=80");
    stmtJobs.run(4, "Mediengestalter/in Digital und Print", "Gestalte kreative Kampagnen für namhafte Kunden. Von Branding über Webdesign bis Social Media.", "Berlin", "2026-08-15", "Kreativität, Kenntnisse in Adobe Creative Suite, Portfoliobeispiele erwünscht", "https://images.unsplash.com/photo-1626785774573-4b799314346d?auto=format&fit=crop&w=400&q=80");
    stmtJobs.run(5, "Bankkaufmann/-frau", "Starte deine Karriere in der Finanzbranche. Beratung, Analyse und Kundenbetreuung.", "Frankfurt", "2026-08-01", "Abitur bevorzugt, gute Mathekenntnisse, kommunikativ", "https://images.unsplash.com/photo-1560472354-b33ff0c44a43?auto=format&fit=crop&w=400&q=80");
    stmtJobs.run(6, "Medizinische/r Fachangestellte/r", "Arbeite an der Schnittstelle von Medizin und Technologie in einem innovativen Start-up.", "Köln", "2026-09-01", "Mittlere Reife, Interesse an Medizin und Technik", "https://images.unsplash.com/photo-1576091160399-112ba8d25d1d?auto=format&fit=crop&w=400&q=80");
    stmtJobs.finalize();

    // --- Seed: Reviews ---
    const stmtRev = dbConnection.prepare("INSERT INTO reviews (company_id, user_id, username, is_anonymous, weight, overall_score, text) VALUES (?, ?, ?, ?, ?, ?, ?)");
    stmtRev.run(1, 2, "Lisa M.", 0, 1.0, 4.8, "Super Arbeitsklima und tolle Betreuung! Man lernt extrem viel und wird in echte Projekte eingebunden.");
    stmtRev.run(1, 3, "Tom K.", 0, 1.0, 4.5, "Beste Entscheidung hier anzufangen. Die Ausbilder nehmen sich wirklich Zeit.");
    stmtRev.run(3, null, "Anonym", 1, 0.5, 3.8, "Spannende Aufgaben, aber lange Arbeitszeiten in der Produktion. Vergütung ist fair.");
    stmtRev.run(5, null, "Anonym", 1, 0.5, 3.2, "Solide Ausbildung, aber sehr hierarchisch geprägt. Die Kollegen sind nett.");
    stmtRev.run(6, 2, "Lisa M.", 0, 1.0, 4.6, "Hier darf man alles ausprobieren! Tolles Team und innovative Projekte.");
    stmtRev.run(2, 4, "Sarah B.", 0, 1.0, 4.2, "Gutes Gehalt, nette Kollegen, internationale Atmosphäre. Manchmal etwas stressig.");
    stmtRev.finalize();

    console.log("Karriko Datenbank initialisiert.");
  });
} else {
  console.log("Verwende existierende Karriko Datenbank: " + dbFile);
}

// Ensure optional columns exist (safe on existing DBs)
dbConnection.serialize(() => {
  dbConnection.run("ALTER TABLE companies ADD COLUMN owner_user_id INTEGER", () => {});
  dbConnection.run("ALTER TABLE users ADD COLUMN bio TEXT", () => {});
  dbConnection.run("ALTER TABLE users ADD COLUMN avatar_url TEXT", () => {});
  dbConnection.run("ALTER TABLE users ADD COLUMN phone TEXT", () => {});
});

// =================================================================
// API ENDPUNKTE
// =================================================================

// --- Jobs (aktiv) ---
app.get("/api/jobs", (req, res) => {
  const limit = req.query.limit ? parseInt(req.query.limit) : 4;
  const companyId = req.query.companyId;

  let sql = `SELECT j.*, c.name as company_name, c.slug as company_slug
             FROM job_listings j
             JOIN companies c ON j.company_id = c.id
             WHERE j.is_active = 1`;
  const params = [];

  if (companyId) {
    sql += " AND j.company_id = ?";
    params.push(companyId);
  }

  sql += " ORDER BY j.created_at DESC LIMIT ?";
  params.push(limit);

  db.query(sql, params, (err, results) => {
    if (err) return res.status(500).json({ error: err.message });
    const jobs = results.map(row => ({
      id: row.id,
      title: row.title,
      description: row.description,
      company: row.company_name,
      company_slug: row.company_slug,
      company_id: row.company_id,
      location: row.location,
      start_date: row.start_date,
      requirements: row.requirements,
      image: row.image_url,
      created_at: row.created_at,
    }));
    res.json(jobs);
  });
});

// --- Job Detail ---
app.get("/api/jobs/:id", (req, res) => {
  const sql = `SELECT j.*, c.name as company_name, c.slug as company_slug
               FROM job_listings j
               JOIN companies c ON j.company_id = c.id
               WHERE j.id = ?`;
  db.query(sql, [req.params.id], (err, results) => {
    if (err) return res.status(500).json({ error: err.message });
    if (!results || results.length === 0) return res.status(404).json({ message: "Stelle nicht gefunden" });
    res.json(results[0]);
  });
});

// --- Job erstellen ---
app.post("/api/jobs", (req, res) => {
  const { company_id, title, description, location, start_date, requirements, image_url } = req.body;
  if (!title || !company_id) return res.status(400).json({ success: false, message: "Titel und Firma erforderlich" });

  const sql = "INSERT INTO job_listings (company_id, title, description, location, start_date, requirements, image_url) VALUES (?, ?, ?, ?, ?, ?, ?)";
  db.query(sql, [company_id, title, description || null, location || null, start_date || null, requirements || null, image_url || null], (err, result) => {
    if (err) return res.status(500).json({ error: err.message });
    res.json({ success: true, jobId: result.insertId });
  });
});

// --- Job aktualisieren ---
app.put("/api/jobs/:id", (req, res) => {
  const { title, description, location, start_date, requirements, image_url, is_active } = req.body;
  const sql = "UPDATE job_listings SET title = ?, description = ?, location = ?, start_date = ?, requirements = ?, image_url = ?, is_active = ? WHERE id = ?";
  db.query(sql, [title, description, location, start_date, requirements, image_url, is_active !== undefined ? is_active : 1, req.params.id], (err) => {
    if (err) return res.status(500).json({ error: err.message });
    res.json({ success: true });
  });
});

// --- Job löschen ---
app.delete("/api/jobs/:id", (req, res) => {
  db.query("DELETE FROM job_listings WHERE id = ?", [req.params.id], (err) => {
    if (err) return res.status(500).json({ error: err.message });
    res.json({ success: true });
  });
});

// --- Reviews ---
app.get("/api/reviews", (req, res) => {
  const limit = req.query.limit ? parseInt(req.query.limit) : 10;
  const companyId = req.query.companyId;

  let sql = `SELECT r.*, c.name as company_name, c.slug as company_slug,
             (SELECT COUNT(*) FROM review_helpful rh WHERE rh.review_id = r.id) as helpful_count
             FROM reviews r
             LEFT JOIN companies c ON r.company_id = c.id
             WHERE 1=1`;
  const params = [];

  if (companyId) {
    sql += " AND r.company_id = ?";
    params.push(companyId);
  }

  sql += " ORDER BY r.created_at DESC LIMIT ?";
  params.push(limit);

  db.query(sql, params, (err, results) => {
    if (err) return res.status(500).json({ error: err.message });
    const reviews = results.map(row => ({
      id: row.id,
      user: row.is_anonymous ? "Anonym" : (row.username || "Anonym"),
      company: row.company_name || "Unbekannt",
      company_slug: row.company_slug,
      rating: row.overall_score || 0,
      text: row.text,
      date: row.created_at,
      anonymous: !!row.is_anonymous,
      weight: parseFloat(row.weight),
      helpful_count: row.helpful_count || 0,
      image: row.is_anonymous
        ? `https://ui-avatars.com/api/?name=A&background=94a3b8&color=fff`
        : `https://ui-avatars.com/api/?name=${encodeURIComponent(row.username || "User")}&background=6366f1&color=fff`,
    }));
    res.json(reviews);
  });
});

// --- Review mit Antworten abgeben ---
app.post("/api/reviews", (req, res) => {
  const { companyName, companyId, rating, text, isAnonymous, weight, username, userId, answers } = req.body;

  const findAndInsert = (coId) => {
    const sqlInsert = `INSERT INTO reviews (company_id, user_id, username, is_anonymous, weight, overall_score, text) VALUES (?, ?, ?, ?, ?, ?, ?)`;
    db.query(sqlInsert, [coId, userId || null, isAnonymous ? "Anonym" : username, isAnonymous ? 1 : 0, weight, rating, text], (err, result) => {
      if (err) return res.status(500).json({ error: err.message });
      const reviewId = result.insertId;

      // Insert individual answers if provided
      if (answers && Array.isArray(answers) && answers.length > 0) {
        const stmtA = dbConnection.prepare("INSERT INTO review_answers (review_id, question_id, star_value, text_value) VALUES (?, ?, ?, ?)");
        answers.forEach(a => stmtA.run(reviewId, a.question_id, a.star_value || null, a.text_value || null));
        stmtA.finalize();
      }

      res.json({ success: true, reviewId });
    });
  };

  if (companyId) {
    findAndInsert(companyId);
  } else if (companyName) {
    db.query("SELECT id FROM companies WHERE name = ?", [companyName], (err, results) => {
      if (err) return res.status(500).json({ error: err.message });
      if (!results || results.length === 0) return res.status(404).json({ error: "Firma nicht gefunden" });
      findAndInsert(results[0].id);
    });
  } else {
    res.status(400).json({ error: "companyId oder companyName erforderlich" });
  }
});

// --- Review Comments (Betriebsantwort) ---
app.get("/api/reviews/:id/comments", (req, res) => {
  db.query("SELECT * FROM review_comments WHERE review_id = ? ORDER BY created_at ASC", [req.params.id], (err, results) => {
    if (err) return res.status(500).json({ error: err.message });
    res.json(results || []);
  });
});

app.post("/api/reviews/:id/comments", (req, res) => {
  const { company_id, text } = req.body;
  // Check if company already commented
  db.query("SELECT id FROM review_comments WHERE review_id = ? AND company_id = ?", [req.params.id, company_id], (err, existing) => {
    if (err) return res.status(500).json({ error: err.message });
    if (existing && existing.length > 0) return res.status(400).json({ error: "Betrieb hat bereits geantwortet" });

    db.query("INSERT INTO review_comments (review_id, company_id, text) VALUES (?, ?, ?)", [req.params.id, company_id, text], (err2) => {
      if (err2) return res.status(500).json({ error: err2.message });
      res.json({ success: true });
    });
  });
});

// --- Review Helpful ---
app.post("/api/reviews/:id/helpful", (req, res) => {
  const { user_id } = req.body;
  db.query("INSERT OR IGNORE INTO review_helpful (review_id, user_id) VALUES (?, ?)", [req.params.id, user_id], (err) => {
    if (err) return res.status(500).json({ error: err.message });
    res.json({ success: true });
  });
});

// --- Bewertungskategorien & Fragen ---
app.get("/api/review-categories", (req, res) => {
  db.query("SELECT * FROM review_categories ORDER BY sort_order", (err, cats) => {
    if (err) return res.status(500).json({ error: err.message });
    db.query("SELECT * FROM review_questions ORDER BY sort_order", (err2, qs) => {
      if (err2) return res.status(500).json({ error: err2.message });
      const result = cats.map(c => ({
        ...c,
        questions: qs.filter(q => q.category_id === c.id),
      }));
      res.json(result);
    });
  });
});

// --- Companies ---
app.get("/api/companies", (req, res) => {
  const name = req.query.name;
  const search = req.query.search;
  const slug = req.query.slug;

  if (name) {
    db.query("SELECT * FROM companies WHERE name = ?", [name], (err, results) => {
      if (err) return res.status(500).json({ error: err.message });
      if (!results || results.length === 0) return res.status(404).json({ message: "Company not found" });
      res.json(results[0]);
    });
  } else if (slug) {
    db.query("SELECT * FROM companies WHERE slug = ?", [slug], (err, results) => {
      if (err) return res.status(500).json({ error: err.message });
      if (!results || results.length === 0) return res.status(404).json({ message: "Company not found" });
      res.json(results[0]);
    });
  } else {
    let sql = `SELECT c.*,
                      COUNT(r.id) as review_count,
                      COALESCE(SUM(r.overall_score * r.weight) / NULLIF(SUM(r.weight), 0), 0) as avg_rating
               FROM companies c
               LEFT JOIN reviews r ON c.id = r.company_id`;
    const params = [];
    if (search) {
      sql += " WHERE c.name LIKE ?";
      params.push(`%${search}%`);
    }
    sql += " GROUP BY c.id ORDER BY avg_rating DESC";
    db.query(sql, params, (err, results) => {
      if (err) return res.status(500).json({ error: err.message });
      res.json(results);
    });
  }
});

app.get("/api/companies/:id", (req, res) => {
  db.query("SELECT * FROM companies WHERE id = ?", [req.params.id], (err, results) => {
    if (err) return res.status(500).json({ error: err.message });
    if (!results || results.length === 0) return res.status(404).json({ message: "Nicht gefunden" });
    res.json(results[0]);
  });
});

app.post("/api/companies", (req, res) => {
  const { name, description, logo_url, header_image_url, owner_user_id, industry, location } = req.body;
  if (!name) return res.status(400).json({ success: false, message: "Name erforderlich" });
  const slug = name.toLowerCase().replace(/[^a-z0-9]+/g, "-").replace(/(^-|-$)/g, "");

  const sql = "INSERT INTO companies (name, slug, description, logo_url, header_image_url, owner_user_id, industry, location) VALUES (?, ?, ?, ?, ?, ?, ?, ?)";
  db.query(sql, [name, slug, description || null, logo_url || null, header_image_url || null, owner_user_id || null, industry || null, location || null], (err, result) => {
    if (err) return res.status(500).json({ error: err.message });
    res.json({ success: true, companyId: result.insertId });
  });
});

app.put("/api/companies/:id", (req, res) => {
  const { name, description, logo_url, header_image_url, industry, location } = req.body;
  const sql = "UPDATE companies SET name = ?, description = ?, logo_url = ?, header_image_url = ?, industry = ?, location = ? WHERE id = ?";
  db.query(sql, [name, description || null, logo_url || null, header_image_url || null, industry || null, location || null, req.params.id], (err) => {
    if (err) return res.status(500).json({ error: err.message });
    res.json({ success: true });
  });
});

// --- Auth ---
app.post("/api/login", (req, res) => {
  const { email, password } = req.body;
  db.query("SELECT * FROM users WHERE email = ? AND password = ?", [email, password], (err, results) => {
    if (err) return res.status(500).json({ error: err.message });
    if (results.length > 0) {
      const user = results[0];
      res.json({ success: true, user: { id: user.id, username: user.username, email: user.email, role: user.role } });
    } else {
      res.status(401).json({ success: false, message: "Ungültige Zugangsdaten" });
    }
  });
});

app.post("/api/register", (req, res) => {
  const { email, password, role } = req.body;
  db.query("SELECT * FROM users WHERE email = ?", [email], (err, results) => {
    if (err) return res.status(500).json({ error: err.message });
    if (results.length > 0) return res.status(400).json({ success: false, message: "E-Mail bereits vergeben" });

    const username = email.split("@")[0];
    db.query("INSERT INTO users (email, password, username, role) VALUES (?, ?, ?, ?)", [email, password, username, role || "azubi"], (err2, result) => {
      if (err2) return res.status(500).json({ error: err2.message });
      res.json({ success: true, message: "Registrierung erfolgreich" });
    });
  });
});

app.post("/api/social", (req, res) => {
  const { email, username, role } = req.body;
  if (!email) return res.status(400).json({ success: false, message: "E-Mail erforderlich" });

  db.query("SELECT * FROM users WHERE email = ?", [email], (err, results) => {
    if (err) return res.status(500).json({ error: err.message });
    if (results.length > 0) {
      const user = results[0];
      return res.json({ success: true, user: { id: user.id, username: user.username, email: user.email, role: user.role } });
    }
    const uname = username || email.split("@")[0];
    db.query("INSERT INTO users (email, password, username, role) VALUES (?, ?, ?, ?)", [email, null, uname, role || "azubi"], (err2, result) => {
      if (err2) return res.status(500).json({ error: err2.message });
      res.json({ success: true, user: { id: result.insertId, username: uname, email, role: role || "azubi" } });
    });
  });
});

// --- Applications ---
app.get("/api/applications", (req, res) => {
  const userId = req.query.userId;
  const jobId = req.query.jobId;
  const companyId = req.query.companyId;

  let sql = `SELECT a.*, j.title as job_title, j.location as job_location, c.name as company_name, u.username as applicant_name, u.email as applicant_email
             FROM applications a
             JOIN job_listings j ON a.job_id = j.id
             JOIN companies c ON j.company_id = c.id
             LEFT JOIN users u ON a.user_id = u.id
             WHERE 1=1`;
  const params = [];

  if (userId) {
    sql += " AND a.user_id = ?";
    params.push(userId);
  }
  if (jobId) {
    sql += " AND a.job_id = ?";
    params.push(jobId);
  }
  if (companyId) {
    sql += " AND j.company_id = ?";
    params.push(companyId);
  }

  sql += " ORDER BY a.created_at DESC";
  db.query(sql, params, (err, results) => {
    if (err) return res.status(500).json({ error: err.message });
    res.json(results || []);
  });
});

app.post("/api/applications", (req, res) => {
  const { job_id, user_id, message, cv_url, cover_url } = req.body;
  if (!job_id || !user_id) return res.status(400).json({ success: false, message: "Job-ID und User-ID erforderlich" });

  // Check for duplicate
  db.query("SELECT id FROM applications WHERE job_id = ? AND user_id = ?", [job_id, user_id], (err, existing) => {
    if (err) return res.status(500).json({ error: err.message });
    if (existing && existing.length > 0) return res.status(400).json({ success: false, message: "Du hast dich bereits beworben" });

    db.query("INSERT INTO applications (job_id, user_id, message, cv_url, cover_url) VALUES (?, ?, ?, ?, ?)",
      [job_id, user_id, message || null, cv_url || null, cover_url || null], (err2, result) => {
      if (err2) return res.status(500).json({ error: err2.message });
      res.json({ success: true, applicationId: result.insertId });
    });
  });
});

app.put("/api/applications/:id/status", (req, res) => {
  const { status } = req.body;
  const validStatuses = ["new", "reviewing", "rejected", "invited"];
  if (!validStatuses.includes(status)) return res.status(400).json({ error: "Ungültiger Status" });

  db.query("UPDATE applications SET status = ? WHERE id = ?", [status, req.params.id], (err) => {
    if (err) return res.status(500).json({ error: err.message });
    res.json({ success: true });
  });
});

// --- Users ---
app.get("/api/users/:id", (req, res) => {
  db.query("SELECT id, email, username, role, bio, avatar_url, created_at FROM users WHERE id = ?", [req.params.id], (err, results) => {
    if (err) return res.status(500).json({ error: err.message });
    if (!results || results.length === 0) return res.status(404).json({ message: "User nicht gefunden" });
    res.json(results[0]);
  });
});

app.put("/api/users/:id", (req, res) => {
  const { username, bio, avatar_url } = req.body;
  db.query("UPDATE users SET username = ?, bio = ?, avatar_url = ? WHERE id = ?", [username || null, bio || null, avatar_url || null, req.params.id], (err) => {
    if (err) return res.status(500).json({ error: err.message });
    res.json({ success: true });
  });
});

// --- Admin: Alle User ---
app.get("/api/admin/users", (req, res) => {
  db.query("SELECT id, email, username, role, created_at FROM users ORDER BY created_at DESC", (err, results) => {
    if (err) return res.status(500).json({ error: err.message });
    res.json(results || []);
  });
});

app.delete("/api/admin/users/:id", (req, res) => {
  db.query("DELETE FROM users WHERE id = ?", [req.params.id], (err) => {
    if (err) return res.status(500).json({ error: err.message });
    res.json({ success: true });
  });
});

app.delete("/api/admin/reviews/:id", (req, res) => {
  db.query("DELETE FROM reviews WHERE id = ?", [req.params.id], (err) => {
    if (err) return res.status(500).json({ error: err.message });
    res.json({ success: true });
  });
});

app.get("/api/admin/stats", (req, res) => {
  const stats = {};
  db.query("SELECT COUNT(*) as count FROM users", (err, r1) => {
    stats.users = r1 ? r1[0].count : 0;
    db.query("SELECT COUNT(*) as count FROM companies", (err2, r2) => {
      stats.companies = r2 ? r2[0].count : 0;
      db.query("SELECT COUNT(*) as count FROM reviews", (err3, r3) => {
        stats.reviews = r3 ? r3[0].count : 0;
        db.query("SELECT COUNT(*) as count FROM job_listings WHERE is_active = 1", (err4, r4) => {
          stats.jobs = r4 ? r4[0].count : 0;
          db.query("SELECT COUNT(*) as count FROM applications", (err5, r5) => {
            stats.applications = r5 ? r5[0].count : 0;
            res.json(stats);
          });
        });
      });
    });
  });
});

// Server starten
app.listen(port, () => {
  console.log(`Karriko Server läuft auf http://localhost:${port}`);
});
