// ===================================================================
// KARRIKO – Main Script
// ===================================================================

const API_URL = "http://localhost:3000/api";

// DOM Elements
const authModal = document.getElementById("auth-modal");
const btnLogin = document.getElementById("btn-login");
const btnRegister = document.getElementById("btn-register");
const closeModalEl = document.querySelector(".close-modal");
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

// Initialize
document.addEventListener("DOMContentLoaded", () => {
  checkAuthStatus();
  renderJobs();
  renderReviews();
  loadStats();

  // Navbar scroll effect
  window.addEventListener("scroll", () => {
    const nav = document.getElementById("main-navbar");
    if (nav) nav.classList.toggle("scrolled", window.scrollY > 20);
  });

  // Auth Listeners
  if (btnLogin) btnLogin.addEventListener("click", () => openModal("login"));
  if (btnRegister) btnRegister.addEventListener("click", () => openModal("register"));
  if (closeModalEl) closeModalEl.addEventListener("click", closeAuthModal);
  if (switchAuth) switchAuth.addEventListener("click", (e) => { e.preventDefault(); toggleAuthMode(); });
  if (authForm) authForm.addEventListener("submit", handleAuth);
  if (document.getElementById("btn-logout")) {
    document.getElementById("btn-logout").addEventListener("click", logout);
  }

  // Close modal on backdrop click
  if (authModal) {
    authModal.addEventListener("click", (e) => {
      if (e.target === authModal) closeAuthModal();
    });
  }

  // Search Logic
  if (searchInput) {
    searchInput.addEventListener("input", handleSearch);
    searchInput.addEventListener("keydown", (e) => {
      if (e.key === "Enter") handleSearchSubmit();
    });
  }
  if (searchBtn) searchBtn.addEventListener("click", handleSearchSubmit);

  // Close search results on click outside
  document.addEventListener("click", (e) => {
    if (searchResults && !e.target.closest(".search-container")) {
      searchResults.classList.add("hidden");
    }
  });

  // Intersection Observer for fade-in animations
  const observer = new IntersectionObserver((entries) => {
    entries.forEach(entry => {
      if (entry.isIntersecting) {
        entry.target.classList.add("fade-in");
        observer.unobserve(entry.target);
      }
    });
  }, { threshold: 0.1 });

  document.querySelectorAll(".section-header, .grid").forEach(el => {
    el.style.opacity = "0";
    observer.observe(el);
  });
});

// ===== DATA =====
async function renderJobs() {
  const container = document.getElementById("promoted-jobs");
  if (!container) return;

  try {
    const response = await fetch(`${API_URL}/jobs?limit=4`);
    const jobs = await response.json();

    if (jobs.length === 0) {
      container.innerHTML = '<p style="grid-column: 1/-1; text-align: center; color: var(--text-muted)">Keine Stellenanzeigen gefunden.</p>';
      return;
    }

    container.innerHTML = jobs.map((job, i) => `
      <div class="card" style="animation-delay: ${i * 0.1}s" onclick="window.location.href='job-detail.html?id=${job.id}'">
        <img src="${job.image || 'https://images.unsplash.com/photo-1497366216548-37526070297c?auto=format&fit=crop&w=400&q=80'}" class="card-image" alt="${job.title}" loading="lazy">
        <div class="card-tag">
          <span class="tag tag-primary">Neu</span>
        </div>
        <h3 style="font-size: 1.05rem; margin-bottom: 0.3rem">${job.title}</h3>
        <div class="job-card-company">
          <i data-lucide="building-2" style="width:14px; height:14px"></i>
          <span>${job.company}</span>
        </div>
        <div class="job-card-footer">
          <span class="tag tag-neutral">
            <i data-lucide="map-pin" style="width:12px; height:12px"></i> ${job.location || "DE"}
          </span>
          <span style="color: var(--primary); font-weight: 600; font-size: 0.85rem; cursor: pointer">Details →</span>
        </div>
      </div>
    `).join("");

    lucide.createIcons();
  } catch (e) {
    console.error("Fehler beim Laden der Jobs:", e);
    container.innerHTML = '<p style="grid-column: 1/-1; text-align: center; color: var(--text-muted)">Verbindung zum Server fehlgeschlagen.</p>';
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

    container.innerHTML = reviews.map((review, i) => `
      <div class="card" style="animation-delay: ${i * 0.08}s; cursor: default">
        <div class="review-card-header">
          <img src="${review.image}" class="review-avatar" alt="${review.user}" loading="lazy">
          <div>
            <strong style="font-size: 0.95rem">${review.user}</strong>
            ${review.anonymous ? '<span class="tag tag-neutral" style="margin-left: 0.5rem; font-size: 0.7rem">Anonym</span>' : ''}
            <div class="review-stars">${"★".repeat(Math.round(review.rating))}${"☆".repeat(5 - Math.round(review.rating))}</div>
          </div>
        </div>
        <p class="review-text">"${review.text}"</p>
        <div class="review-footer">
          <span>bei <strong>${review.company}</strong></span>
          <span class="tag tag-primary" style="font-size: 0.7rem">${review.weight === 1 ? '100%' : '50%'} Gewichtung</span>
        </div>
      </div>
    `).join("");
  } catch (e) {
    console.error("Fehler beim Laden der Reviews:", e);
  }
}

async function loadStats() {
  try {
    const res = await fetch(`${API_URL}/admin/stats`);
    const stats = await res.json();
    const animate = (el, target) => {
      if (!el) return;
      let current = 0;
      const step = Math.ceil(target / 30);
      const interval = setInterval(() => {
        current += step;
        if (current >= target) { current = target; clearInterval(interval); }
        el.textContent = current;
      }, 30);
    };
    animate(document.getElementById("stat-companies"), stats.companies || 0);
    animate(document.getElementById("stat-reviews"), stats.reviews || 0);
    animate(document.getElementById("stat-jobs"), stats.jobs || 0);
  } catch (e) {
    console.error("Stats laden fehlgeschlagen", e);
  }
}

// ===== AUTH =====
function checkAuthStatus() {
  const user = JSON.parse(localStorage.getItem("karriko_user"));
  if (user) {
    if (authButtons) authButtons.classList.add("hidden");
    if (userProfile) userProfile.classList.remove("hidden");
    const nameEl = document.getElementById("user-name");
    if (nameEl) nameEl.textContent = user.username;

    // Add profile link
    const profileLinkId = "user-profile-link";
    let existing = document.getElementById(profileLinkId);
    if (!existing && userProfile) {
      const a = document.createElement("a");
      a.id = profileLinkId;
      a.className = "btn btn-ghost btn-sm";
      userProfile.insertBefore(a, userProfile.firstChild);
      existing = a;
    }
    if (existing) {
      if (user.role === "azubi") {
        existing.textContent = "Dashboard";
        existing.href = "dashboard.html";
        existing.onclick = (e) => { e.preventDefault(); window.location.href = "dashboard.html"; };
      } else if (user.role === "unternehmen" || user.role === "superadmin") {
        existing.textContent = user.role === "superadmin" ? "Admin" : "Unternehmen";
        existing.href = user.role === "superadmin" ? "admin.html" : "company_dashboard.html";
        existing.onclick = (e) => { e.preventDefault(); window.location.href = existing.href; };
      }
    }
  } else {
    if (authButtons) authButtons.classList.remove("hidden");
    if (userProfile) userProfile.classList.add("hidden");
  }
}

function logout() {
  localStorage.removeItem("karriko_user");
  window.location.reload();
}

function openModal(mode) {
  isLoginMode = mode === "login";
  updateModalUI();
  authModal.classList.remove("hidden");
  void authModal.offsetWidth;
  authModal.classList.add("active");
}

function closeAuthModal() {
  authModal.classList.remove("active");
  setTimeout(() => authModal.classList.add("hidden"), 300);
}

function toggleAuthMode() {
  isLoginMode = !isLoginMode;
  updateModalUI();
}

function updateModalUI() {
  if (modalTitle) modalTitle.textContent = isLoginMode ? "Willkommen zurück" : "Konto erstellen";
  if (authSubmitBtn) authSubmitBtn.textContent = isLoginMode ? "Anmelden" : "Registrieren";
  if (switchAuth) switchAuth.textContent = isLoginMode ? "Registrieren" : "Anmelden";
  const roleWrapper = document.getElementById("role-wrapper");
  if (roleWrapper) {
    roleWrapper.classList.toggle("hidden", isLoginMode);
  }
  const switchText = document.querySelector(".auth-switch");
  if (switchText) {
    switchText.firstChild.textContent = isLoginMode ? "Noch kein Konto? " : "Bereits registriert? ";
  }
}

async function handleAuth(e) {
  e.preventDefault();
  const email = document.getElementById("email").value;
  const password = document.getElementById("password").value;
  const endpoint = isLoginMode ? "/login" : "/register";

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
        localStorage.setItem("karriko_user", JSON.stringify(data.user));
        closeAuthModal();
        checkAuthStatus();
      } else {
        // Switch to login mode after successful registration
        isLoginMode = true;
        updateModalUI();
        showToast("Registrierung erfolgreich! Bitte anmelden.", "success");
      }
    } else {
      showToast(data.message || "Fehler bei der Authentifizierung", "error");
    }
  } catch (error) {
    showToast("Serverfehler: " + error.message, "error");
  }
}

function authGoogle() {
  const email = prompt("Simulierte Google-Email eingeben:", "google.user@example.com");
  if (!email) return;
  const roleEl = document.getElementById("role");
  const role = roleEl && !roleEl.closest(".hidden") ? roleEl.value : null;

  fetch(`${API_URL}/social`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ email, username: null, role }),
  })
    .then(r => r.json())
    .then(data => {
      if (data && data.success) {
        localStorage.setItem("karriko_user", JSON.stringify(data.user));
        closeAuthModal();
        checkAuthStatus();
      } else {
        showToast("Fehler bei Social Login", "error");
      }
    })
    .catch(err => showToast("Netzwerkfehler: " + err.message, "error"));
}

function authApple() {
  const email = prompt("Simulierte Apple-Email eingeben:", "apple.user@example.com");
  if (!email) return;
  const roleEl = document.getElementById("role");
  const role = roleEl && !roleEl.closest(".hidden") ? roleEl.value : null;

  fetch(`${API_URL}/social`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ email, username: null, role }),
  })
    .then(r => r.json())
    .then(data => {
      if (data && data.success) {
        localStorage.setItem("karriko_user", JSON.stringify(data.user));
        closeAuthModal();
        checkAuthStatus();
      } else {
        showToast("Fehler bei Social Login", "error");
      }
    })
    .catch(err => showToast("Netzwerkfehler: " + err.message, "error"));
}

// ===== SEARCH =====
let searchTimeout;
async function handleSearch(e) {
  const val = e.target.value;
  clearTimeout(searchTimeout);
  searchTimeout = setTimeout(async () => {
    if (val.length < 2) {
      searchResults.classList.add("hidden");
      return;
    }

    try {
      const res = await fetch(`${API_URL}/companies?search=${encodeURIComponent(val)}`);
      const companies = await res.json();

      if (companies.length > 0) {
        searchResults.innerHTML = companies.map(c => `
          <div class="search-result-row">
            <div class="search-result-text" onclick="window.location.href='company.html?name=${encodeURIComponent(c.name)}'">
              <strong>${c.name}</strong>
              <span style="color: var(--text-light); font-size: 0.8rem; margin-left: 0.5rem">${c.industry || ''}</span>
            </div>
            <button class="search-fill-btn" onclick="fillSearch('${c.name.replace(/'/g, "\\'")}')" title="Übernehmen">
              <i data-lucide="arrow-up-left" style="width:16px; height:16px;"></i>
            </button>
          </div>
        `).join("");
        lucide.createIcons();
        searchResults.classList.remove("hidden");
      } else {
        searchResults.innerHTML = '<div class="search-result-empty">Kein Unternehmen gefunden</div>';
        searchResults.classList.remove("hidden");
      }
    } catch (e) {
      console.error(e);
    }
  }, 300);
}

window.fillSearch = function (name) {
  if (searchInput) {
    searchInput.value = name;
    searchInput.focus();
    searchResults.classList.add("hidden");
  }
};

function handleSearchSubmit() {
  const val = searchInput ? searchInput.value : "";
  if (val) window.location.href = `search.html?q=${encodeURIComponent(val)}`;
}

// ===== TOAST =====
function showToast(message, type = "info") {
  const existing = document.querySelector(".toast");
  if (existing) existing.remove();

  const toast = document.createElement("div");
  toast.className = "toast";
  const colors = { success: "#10b981", error: "#ef4444", info: "#6366f1", warning: "#f59e0b" };
  toast.style.cssText = `
    position: fixed; bottom: 2rem; right: 2rem; z-index: 9999;
    background: ${colors[type] || colors.info}; color: white;
    padding: 0.85rem 1.5rem; border-radius: 0.75rem;
    font-size: 0.9rem; font-weight: 500; font-family: inherit;
    box-shadow: 0 10px 25px rgba(0,0,0,0.15);
    animation: slideUp 0.3s ease;
    max-width: 400px;
  `;
  toast.textContent = message;
  document.body.appendChild(toast);
  setTimeout(() => {
    toast.style.opacity = "0";
    toast.style.transform = "translateY(10px)";
    toast.style.transition = "0.3s";
    setTimeout(() => toast.remove(), 300);
  }, 3500);
}

// Make toast globally available
window.showToast = showToast;
window.checkAuthStatus = checkAuthStatus;
