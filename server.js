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

// --- SQLite Setup (Ersatz für MySQL) ---
const dbFile = path.resolve(__dirname, "azubicheck.db");
const initDbNeeded = !fs.existsSync(dbFile);

const dbConnection = new sqlite3.Database(dbFile);

// Wrapper um SQLite wie mysql2 verhalten zu lassen (interface compatibility)
const db = {
  query: function (sql, params, callback) {
    if (typeof params === "function") {
      callback = params;
      params = [];
    }

    const method = sql.trim().toUpperCase().startsWith("SELECT")
      ? "all"
      : "run";

    dbConnection[method](sql, params, function (err, rows) {
      if (method === "run") {
        // Bei .run() ist 'this' der Statement-Kontext mit lastID und changes
        // Callback erwartet (err, result) wobei result = { insertId, ... }
        const result = err
          ? null
          : { insertId: this.lastID, affectedRows: this.changes };
        callback(err, result);
      } else {
        // Bei .all() ist rows das Ergebnis-Array
        callback(err, rows);
      }
    });
  },
};

// Initialisierung der Datenbank falls nicht vorhanden
if (initDbNeeded) {
  console.log("Erstelle lokale SQLite Datenbank...");
  dbConnection.serialize(() => {
    // Tabellen erstellen
    dbConnection.run(
      "CREATE TABLE users (id INTEGER PRIMARY KEY AUTOINCREMENT, email TEXT UNIQUE, password TEXT, username TEXT, role TEXT DEFAULT 'azubi', created_at DATETIME DEFAULT CURRENT_TIMESTAMP)",
    );
    dbConnection.run(
      "CREATE TABLE companies (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT, description TEXT, logo_url TEXT, header_image_url TEXT, created_at DATETIME DEFAULT CURRENT_TIMESTAMP)",
    );
    dbConnection.run(
      "CREATE TABLE jobs (id INTEGER PRIMARY KEY AUTOINCREMENT, company_id INTEGER, title TEXT, location TEXT, image_url TEXT, created_at DATETIME DEFAULT CURRENT_TIMESTAMP)",
    );
    dbConnection.run(
      "CREATE TABLE reviews (id INTEGER PRIMARY KEY AUTOINCREMENT, company_id INTEGER, user_id INTEGER, username TEXT, rating INTEGER, text TEXT, is_anonymous INTEGER DEFAULT 0, weight REAL DEFAULT 1.0, created_at DATETIME DEFAULT CURRENT_TIMESTAMP)",
    );

    // Daten seeden
    const stmtUsers = dbConnection.prepare(
      "INSERT INTO users (email, password, username, role) VALUES (?, ?, ?, ?)",
    );
    stmtUsers.run(
      "test@azubicheck.de",
      "password123",
      "Max Mustermann",
      "azubi",
    );
    stmtUsers.run("lisa@example.com", "securepass", "Lisa M.", "azubi");
    stmtUsers.run("tom@example.com", "123456", "Tom K.", "azubi");
    // Seed Superadmin
    stmtUsers.run(
      "dresogo@web.de",
      "admin.dresogo",
      "Super Admin",
      "superadmin",
    );
    stmtUsers.finalize();

    const stmtComp = dbConnection.prepare(
      "INSERT INTO companies (name, description, logo_url) VALUES (?, ?, ?)",
    );
    stmtComp.run("TechNova Solutions", "Führendes IT-Unternehmen.", "TN");
    stmtComp.run("Global Logistics GmbH", "Weltweite Logistiklösungen.", "GL");
    stmtComp.run("AutoWorks", "Automobilindustrie und Fertigung.", "AW");
    stmtComp.run("Creative Studio", "Design und Marketing Agentur.", "CS");
    stmtComp.run("Bank AG", "Finanzdienstleistungen.", "BA");
    stmtComp.run("StartUp Inc", "Innovatives Start-up.", "SI");
    stmtComp.finalize();

    const stmtJobs = dbConnection.prepare(
      "INSERT INTO jobs (company_id, title, location, image_url) VALUES (?, ?, ?, ?)",
    );
    stmtJobs.run(
      1,
      "Fachinformatiker/in Anwendungsentwicklung",
      "Berlin",
      "https://images.unsplash.com/photo-1498050108023-c5249f4df085?auto=format&fit=crop&w=400&q=80",
    );
    stmtJobs.run(
      2,
      "Kaufmann/-frau für Spedition",
      "Hamburg",
      "https://images.unsplash.com/photo-1497215728101-856f4ea42174?auto=format&fit=crop&w=400&q=80",
    );
    stmtJobs.run(
      3,
      "Mechatroniker/in",
      "München",
      "https://images.unsplash.com/photo-1581091226033-d5c48150dbaa?auto=format&fit=crop&w=400&q=80",
    );
    stmtJobs.run(
      4,
      "Mediengestalter/in Digital",
      "Köln",
      "https://images.unsplash.com/photo-1626785774573-4b799314346d?auto=format&fit=crop&w=400&q=80",
    );
    stmtJobs.finalize();

    const stmtRev = dbConnection.prepare(
      "INSERT INTO reviews (company_id, user_id, username, rating, text, is_anonymous, weight) VALUES (?, ?, ?, ?, ?, ?, ?)",
    );
    stmtRev.run(
      1,
      2,
      "Lisa M.",
      5,
      "Super Arbeitsklima und tolle Betreuung! Man lernt extrem viel.",
      0,
      1.0,
    );
    stmtRev.run(
      3,
      null,
      "Anonym",
      4,
      "Spannende Aufgaben, aber lange Arbeitszeiten in der Produktion.",
      1,
      0.5,
    );
    stmtRev.run(
      1,
      3,
      "Tom K.",
      5,
      "Beste Entscheidung hier anzufangen.",
      0,
      1.0,
    );
    stmtRev.run(
      5,
      null,
      "Anonym",
      3,
      "Solide Ausbildung, aber sehr hierarchisch geprägt.",
      1,
      0.5,
    );
    stmtRev.run(
      6,
      2,
      "Lisa M.",
      5,
      "Hier darf man alles ausprobieren! Tolles Team.",
      0,
      1.0,
    );
    stmtRev.run(
      2,
      null,
      "Kevin P.",
      4,
      "Gutes Gehalt, nette Kollegen, aber viel Stress.",
      0,
      1.0,
    );
    stmtRev.finalize();

    console.log("Datenbank initialisiert.");
  });
} else {
  console.log("Verwende existierende SQLite Datenbank: " + dbFile);
}

// Ensure optional columns exist (safe on existing DBs)
dbConnection.serialize(() => {
  // Add owner_user_id to companies (if not present)
  dbConnection.run(
    "ALTER TABLE companies ADD COLUMN owner_user_id INTEGER",
    function (err) {
      // ignore error if column exists
    },
  );

  // Add bio and avatar_url to users
  dbConnection.run("ALTER TABLE users ADD COLUMN bio TEXT", function (err) {});
  dbConnection.run(
    "ALTER TABLE users ADD COLUMN avatar_url TEXT",
    function (err) {},
  );
});

// --- API Endpoints ---

// 1. Jobs abrufen (Promoted)
app.get("/api/jobs", (req, res) => {
  const sql = `
        SELECT j.*, c.name as company_name 
        FROM jobs j 
        JOIN companies c ON j.company_id = c.id 
        ORDER BY j.created_at DESC LIMIT 4`;

  db.query(sql, (err, results) => {
    if (err) return res.status(500).json({ error: err.message });

    // Formatieren für Frontend
    const jobs = results.map((row) => ({
      title: row.title,
      company: row.company_name,
      location: row.location,
      image: row.image_url,
    }));
    res.json(jobs);
  });
});

// 2. Reviews abrufen (Startseite & Allgemein)
app.get("/api/reviews", (req, res) => {
  const limit = req.query.limit ? parseInt(req.query.limit) : 10;
  const companyId = req.query.companyId;

  let sql = `
        SELECT r.*, c.name as company_name 
        FROM reviews r 
        LEFT JOIN companies c ON r.company_id = c.id 
        WHERE 1=1 
    `;

  const params = [];
  if (companyId) {
    sql += " AND r.company_id = ?";
    params.push(companyId);
  }

  sql += " ORDER BY r.created_at DESC LIMIT ?";
  params.push(limit);

  db.query(sql, params, (err, results) => {
    if (err) return res.status(500).json({ error: err.message });

    // Mapping für Frontend
    const reviews = results.map((row) => ({
      id: row.id,
      user: row.username || "Anonym", // Fallback
      company: row.company_name || "Unbekannt",
      rating: row.rating,
      text: row.text,
      date: row.created_at,
      anonymous: !!row.is_anonymous,
      weight: parseFloat(row.weight),
      image: `https://ui-avatars.com/api/?name=${encodeURIComponent(row.username || "User")}&background=random`,
    }));
    res.json(reviews);
  });
});

// 3. Firmen Suche / Details
app.get("/api/companies", (req, res) => {
  const name = req.query.name;
  const search = req.query.search;

  if (name) {
    // Einzelansicht (Genauer Name)
    const sql = "SELECT * FROM companies WHERE name = ?";
    db.query(sql, [name], (err, results) => {
      if (err) return res.status(500).json({ error: err });
      if (results.length === 0)
        return res.status(404).json({ message: "Company not found" });
      res.json(results[0]);
    });
  } else {
    // Suche (Liste mit Ratings)
    let sql = `
            SELECT c.*, 
                   COUNT(r.id) as review_count, 
                   COALESCE(SUM(r.rating * r.weight) / NULLIF(SUM(r.weight), 0), 0) as avg_rating
            FROM companies c
            LEFT JOIN reviews r ON c.id = r.company_id
        `;

    const params = [];
    if (search) {
      sql += " WHERE c.name LIKE ?";
      params.push(`%${search}%`);
    }

    sql += " GROUP BY c.id ORDER BY avg_rating DESC";

    db.query(sql, params, (err, results) => {
      if (err) return res.status(500).json({ error: err });
      res.json(results);
    });
  }
});

// 4. Login (Mock - Unsicher für Produktion!)
app.post("/api/login", (req, res) => {
  const { email, password } = req.body;
  const sql = "SELECT * FROM users WHERE email = ? AND password = ?";

  db.query(sql, [email, password], (err, results) => {
    if (err) return res.status(500).json({ error: err });

    if (results.length > 0) {
      const user = results[0];
      // Rückgabe eines einfachen Objekts statt Token
      res.json({
        success: true,
        user: {
          id: user.id,
          username: user.username,
          email: user.email,
          role: user.role || "azubi",
        },
      });
    } else {
      res
        .status(401)
        .json({ success: false, message: "Ungültige Zugangsdaten" });
    }
  });
});

// 5. Registrieren
app.post("/api/register", (req, res) => {
  const { email, password, role } = req.body;
  // Einfache Validierung
  const sqlCheck = "SELECT * FROM users WHERE email = ?";
  db.query(sqlCheck, [email], (err, results) => {
    if (err) return res.status(500).json({ error: err });
    if (results.length > 0) {
      return res
        .status(400)
        .json({ success: false, message: "Email bereits vergeben" });
    }

    const username = email.split("@")[0]; // Simple Username Generierung
    const sqlInsert =
      "INSERT INTO users (email, password, username, role) VALUES (?, ?, ?, ?)";

    db.query(
      sqlInsert,
      [email, password, username, role || "azubi"],
      (err, result) => {
        if (err) return res.status(500).json({ error: err });
        res.json({ success: true, message: "Registrierung erfolgreich" });
      },
    );
  });
});

// 6. Social (Simuliert) - erstellt oder liefert User basierend auf Email
app.post("/api/social", (req, res) => {
  const { email, username, role } = req.body;
  if (!email)
    return res
      .status(400)
      .json({ success: false, message: "Email erforderlich" });

  const sqlFind = "SELECT * FROM users WHERE email = ?";
  db.query(sqlFind, [email], (err, results) => {
    if (err) return res.status(500).json({ error: err });

    if (results.length > 0) {
      const user = results[0];
      return res.json({
        success: true,
        user: {
          id: user.id,
          username: user.username,
          email: user.email,
          role: user.role || "azubi",
        },
      });
    }

    // Erstelle neuen User ohne Passwort (Social)
    const uname = username || email.split("@")[0];
    const sqlInsert =
      "INSERT INTO users (email, password, username, role) VALUES (?, ?, ?, ?)";
    db.query(
      sqlInsert,
      [email, null, uname, role || "azubi"],
      (err, result) => {
        if (err) return res.status(500).json({ error: err });
        return res.json({
          success: true,
          user: {
            id: result.insertId,
            username: uname,
            email,
            role: role || "azubi",
          },
        });
      },
    );
  });
});

// 6. Bewertung abgeben
app.post("/api/reviews", (req, res) => {
  const { companyName, rating, text, isAnonymous, weight, username, userId } =
    req.body;

  // Zuerst Company ID finden oder erstellen (einfachheitshalber nehmen wir an sie existiert oder finden über namen)
  // Für dieses Beispiel suchen wir strikt über Namen
  const sqlFindCo = "SELECT id FROM companies WHERE name = ?";
  db.query(sqlFindCo, [companyName], (err, results) => {
    if (err) return res.status(500).json({ error: err });

    let companyId;
    if (results.length === 0) {
      // Firma erstellen (quick fix für Demo)
      // In realer App: Eigener Endpoint "Firma erstellen"
      // Hier: Mock ID 1 oder Fehler
      return res
        .status(404)
        .json({ error: "Firma nicht gefunden (bitte Admin kontaktieren)" });
    } else {
      companyId = results[0].id;
    }

    const sqlInsert = `
            INSERT INTO reviews (company_id, user_id, username, rating, text, is_anonymous, weight) 
            VALUES (?, ?, ?, ?, ?, ?, ?)`;

    // userId kann null sein wenn nicht eingeloggt, wir erwarten aber eingeloggte User laut Logik
    db.query(
      sqlInsert,
      [
        companyId,
        userId || null,
        isAnonymous ? "Anonym" : username,
        rating,
        text,
        isAnonymous,
        weight,
      ],
      (err, result) => {
        if (err) return res.status(500).json({ error: err });
        res.json({ success: true });
      },
    );
  });
});

// --- Company management endpoints ---
// Create company (owner_user_id required in body)
app.post("/api/companies", (req, res) => {
  const { name, description, logo_url, header_image_url, owner_user_id } =
    req.body;
  if (!name)
    return res
      .status(400)
      .json({ success: false, message: "Name erforderlich" });

  const sql =
    "INSERT INTO companies (name, description, logo_url, header_image_url, owner_user_id) VALUES (?, ?, ?, ?, ?)";
  db.query(
    sql,
    [
      name,
      description || null,
      logo_url || null,
      header_image_url || null,
      owner_user_id || null,
    ],
    (err, result) => {
      if (err) return res.status(500).json({ error: err });
      res.json({ success: true, companyId: result.insertId });
    },
  );
});

// Update company
app.put("/api/companies/:id", (req, res) => {
  const id = req.params.id;
  const { name, description, logo_url, header_image_url } = req.body;
  const sql =
    "UPDATE companies SET name = ?, description = ?, logo_url = ?, header_image_url = ? WHERE id = ?";
  db.query(
    sql,
    [name, description || null, logo_url || null, header_image_url || null, id],
    (err, result) => {
      if (err) return res.status(500).json({ error: err });
      res.json({ success: true });
    },
  );
});

// Get company by id
app.get("/api/companies/:id", (req, res) => {
  const id = req.params.id;
  const sql = "SELECT * FROM companies WHERE id = ?";
  db.query(sql, [id], (err, results) => {
    if (err) return res.status(500).json({ error: err });
    if (!results || results.length === 0)
      return res.status(404).json({ message: "Nicht gefunden" });
    res.json(results[0]);
  });
});

// --- User profile endpoints ---
// Get user by id
app.get("/api/users/:id", (req, res) => {
  const id = req.params.id;
  const sql =
    "SELECT id, email, username, role, bio, avatar_url, created_at FROM users WHERE id = ?";
  db.query(sql, [id], (err, results) => {
    if (err) return res.status(500).json({ error: err });
    if (!results || results.length === 0)
      return res.status(404).json({ message: "User nicht gefunden" });
    res.json(results[0]);
  });
});

// Update user profile
app.put("/api/users/:id", (req, res) => {
  const id = req.params.id;
  const { username, bio, avatar_url } = req.body;
  const sql =
    "UPDATE users SET username = ?, bio = ?, avatar_url = ? WHERE id = ?";
  db.query(
    sql,
    [username || null, bio || null, avatar_url || null, id],
    (err, result) => {
      if (err) return res.status(500).json({ error: err });
      res.json({ success: true });
    },
  );
});

// Server starten
app.listen(port, () => {
  console.log(`Server läuft auf http://localhost:${port}`);
});
