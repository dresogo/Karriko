// DOM Elements
const authModal = document.getElementById("auth-modal");
const btnLogin = document.getElementById("btn-login");
const btnRegister = document.getElementById("btn-register");
const closeModal = document.querySelector(".close-modal");
const authForm = document.getElementById("auth-form");
const authSubmitBtn = document.getElementById("auth-submit");
const switchAuth = document.getElementById("switch-auth");
const modalTitle = document.getElementById("modal-title");
const userProfile = document.getElementById("user-profile");
const authButtons = document.getElementById("auth-buttons");
const searchInput = document.getElementById("company-search");
const searchResults = document.getElementById("search-results");
const searchBtn = document.getElementById("search-btn");

let isLoginMode = true;
const API_URL = "http://localhost:3000/api";

// Initialize
document.addEventListener("DOMContentLoaded", () => {
  // Check Auth State
  checkAuthStatus();

  // Load Data
  renderJobs();
  renderReviews();

  // Event Listeners
  if (btnLogin) btnLogin.addEventListener("click", () => openModal("login"));
  if (btnRegister)
    btnRegister.addEventListener("click", () => openModal("register"));
  if (closeModal)
    closeModal.addEventListener("click", () =>
      authModal.classList.remove("active"),
    );
  if (switchAuth)
    switchAuth.addEventListener("click", (e) => {
      e.preventDefault();
      toggleAuthMode();
    });
  if (authForm) authForm.addEventListener("submit", handleAuth);
  if (document.getElementById("btn-logout")) {
    document.getElementById("btn-logout").addEventListener("click", logout);
  }

  // Search Logic
  if (searchInput) {
    searchInput.addEventListener("input", handleSearch);
    searchInput.addEventListener("keydown", (e) => {
      if (e.key === "Enter") handleSearchSubmit();
    });
  }
  if (searchBtn) searchBtn.addEventListener("click", handleSearchSubmit);
});

async function renderJobs() {
  const container = document.getElementById("promoted-jobs");
  if (!container) return;

  try {
    const response = await fetch(`${API_URL}/jobs`);
    const jobs = await response.json();

    if (jobs.length === 0) {
      container.innerHTML =
        '<p style="grid-column: 1/-1; text-align: center;">Keine Stellenanzeigen gefunden.</p>';
      return;
    }

    container.innerHTML = jobs
      .map(
        (job) => `
            <div class="card">
                <img src="${job.image || "https://via.placeholder.com/400x200"}" class="card-image" alt="${job.title}">
                <h3>${job.title}</h3>
                <p style="color:var(--text-muted)">${job.company} • ${job.location || "DE"}</p>
                <button class="btn btn-secondary" style="margin-top:auto">Ansehen</button>
            </div>
        `,
      )
      .join("");
  } catch (e) {
    console.error("Fehler beim Laden der Jobs:", e);
    container.innerHTML = "<p>Fehler beim Verbinden zum Server.</p>";
  }
}

async function renderReviews() {
  const container = document.getElementById("platform-reviews");
  if (!container) return;

  try {
    const response = await fetch(`${API_URL}/reviews?limit=6`);
    const reviews = await response.json();

    if (reviews.length === 0) {
      container.innerHTML = "<p>Noch keine Bewertungen vorhanden.</p>";
      return;
    }

    container.innerHTML = reviews
      .map(
        (review) => `
            <div class="card" style="align-items: flex-start">
                <div style="display:flex; align-items:center; gap:1rem; margin-bottom:1rem;">
                    <img src="${review.image}" style="width:40px; height:40px; border-radius:50%">
                    <div>
                       <strong>${review.user}</strong>
                       <div style="color: gold; font-size:0.9rem;">${"★".repeat(review.rating)}${"☆".repeat(5 - review.rating)}</div>
                    </div>
                </div>
                <p>"${review.text}"</p>
                <small style="margin-top:0.5rem; color:var(--text-muted)">bei ${review.company}</small>
            </div>
        `,
      )
      .join("");
  } catch (e) {
    console.error("Fehler beim Laden der Reviews:", e);
  }
}

// Auth Handlers
function checkAuthStatus() {
  const user = JSON.parse(localStorage.getItem("azubi_user"));
  if (user) {
    authButtons.classList.add("hidden");
    userProfile.classList.remove("hidden");
    document.getElementById("user-name").textContent = user.username;
    // add quick links for profile / company dashboard
    const profileLinkId = "user-profile-link";
    let existing = document.getElementById(profileLinkId);
    if (!existing) {
      const a = document.createElement("a");
      a.id = profileLinkId;
      a.style.marginLeft = "1rem";
      a.className = "btn btn-sm";
      userProfile.appendChild(a);
      existing = a;
    }
    if (user.role === "azubi") {
      existing.textContent = "Profil bearbeiten";
      existing.href = "azubi_profile.html";
      existing.onclick = (e) => {
        e.preventDefault();
        window.location.href = "azubi_profile.html";
      };
    } else if (user.role === "unternehmen" || user.role === "superadmin") {
      existing.textContent = "Unternehmensbereich";
      existing.href = "company_dashboard.html";
      existing.onclick = (e) => {
        e.preventDefault();
        window.location.href = "company_dashboard.html";
      };
    } else {
      existing.remove();
    }
  } else {
    authButtons.classList.remove("hidden");
    userProfile.classList.add("hidden");
  }
}

function logout() {
  localStorage.removeItem("azubi_user");
  window.location.reload();
}

function openModal(mode) {
  isLoginMode = mode === "login";
  updateModalUI();
  authModal.classList.add("active");
  authModal.classList.remove("hidden");
}

function toggleAuthMode() {
  isLoginMode = !isLoginMode;
  updateModalUI();
}

function updateModalUI() {
  modalTitle.textContent = isLoginMode ? "Anmelden" : "Registrieren";
  authSubmitBtn.textContent = isLoginMode ? "Anmelden" : "Konto erstellen";
  switchAuth.textContent = isLoginMode ? "Registrieren" : "Anmelden";
  // Show role selection only in register mode
  const roleWrapper = document.getElementById("role-wrapper");
  if (roleWrapper) {
    if (isLoginMode) roleWrapper.classList.add("hidden");
    else roleWrapper.classList.remove("hidden");
  }
}

async function handleAuth(e) {
  e.preventDefault();
  const email = document.getElementById("email").value;
  const password = document.getElementById("password").value;
  const endpoint = isLoginMode ? "/login" : "/register";

  // Include role for registration
  let role = null;
  if (!isLoginMode) {
    const roleEl = document.getElementById("role");
    role = roleEl ? roleEl.value : "azubi";
  }

  try {
    const payload = { email, password };
    if (role) payload.role = role;

    const res = await fetch(`${API_URL}${endpoint}`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(payload),
    });

    const data = await res.json();

    if (data.success) {
      if (isLoginMode) {
        localStorage.setItem("azubi_user", JSON.stringify(data.user));
        authModal.classList.remove("active");
        setTimeout(() => authModal.classList.add("hidden"), 300);
        checkAuthStatus();
      } else {
        alert("Registrierung erfolgreich! Bitte anmelden.");
        toggleAuthMode();
      }
    } else {
      alert("Fehler: " + (data.message || "Unbekannter Fehler"));
    }
  } catch (error) {
    alert("Serverfehler: " + error.message);
  }
}

function authGoogle() {
  // Simulierter Google-Flow: frage Email und rufe /api/social auf
  const email = prompt(
    "Simulierte Google-Email eingeben:",
    "google.user@example.com",
  );
  if (!email) return;
  const roleEl = document.getElementById("role");
  const role =
    roleEl && !roleEl.classList.contains("hidden") ? roleEl.value : null;

  fetch(`${API_URL}/social`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ email, username: null, role }),
  })
    .then((r) => r.json())
    .then((data) => {
      if (data && data.success) {
        localStorage.setItem("azubi_user", JSON.stringify(data.user));
        authModal.classList.remove("active");
        setTimeout(() => authModal.classList.add("hidden"), 300);
        checkAuthStatus();
      } else {
        alert("Fehler bei Social Login");
      }
    })
    .catch((err) => alert("Netzwerkfehler: " + err.message));
}

function authApple() {
  const email = prompt(
    "Simulierte Apple-Email eingeben:",
    "apple.user@example.com",
  );
  if (!email) return;
  const roleEl = document.getElementById("role");
  const role =
    roleEl && !roleEl.classList.contains("hidden") ? roleEl.value : null;

  fetch(`${API_URL}/social`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ email, username: null, role }),
  })
    .then((r) => r.json())
    .then((data) => {
      if (data && data.success) {
        localStorage.setItem("azubi_user", JSON.stringify(data.user));
        authModal.classList.remove("active");
        setTimeout(() => authModal.classList.add("hidden"), 300);
        checkAuthStatus();
      } else {
        alert("Fehler bei Social Login");
      }
    })
    .catch((err) => alert("Netzwerkfehler: " + err.message));
}

// Search Logic
let searchTimeout;
async function handleSearch(e) {
  const val = e.target.value;

  // Debounce
  clearTimeout(searchTimeout);
  searchTimeout = setTimeout(async () => {
    if (val.length < 2) {
      searchResults.classList.add("hidden");
      return;
    }

    try {
      // Backend Search
      const res = await fetch(
        `${API_URL}/companies?search=${encodeURIComponent(val)}`,
      );
      const companies = await res.json();

      if (companies.length > 0) {
        // New: Text only suggestions with arrow
        searchResults.innerHTML = companies
          .map(
            (c) => `
          <div class="search-result-row">
             <div class="search-result-text" onclick="window.location.href='company.html?name=${encodeURIComponent(c.name)}'">
                ${c.name}
             </div>
             <button class="search-fill-btn" onclick="fillSearch('${c.name}')" title="Übernehmen">
                <i data-lucide="arrow-up-left" style="width:16px; height:16px;"></i>
             </button>
          </div>
        `,
          )
          .join("");
        lucide.createIcons();
        searchResults.classList.remove("hidden");
      } else {
        searchResults.innerHTML =
          '<div class="search-result-empty">Keine Firma gefunden</div>';
        searchResults.classList.remove("hidden");
      }
    } catch (e) {
      console.error(e);
    }
  }, 300);
}

// Function to fill search input
window.fillSearch = function (name) {
  if (searchInput) {
    searchInput.value = name;
    searchInput.focus();
  }
};

function handleSearchSubmit() {
  const val = searchInput.value;
  // Redirect to search results page
  if (val) window.location.href = `search.html?q=${encodeURIComponent(val)}`;
}
