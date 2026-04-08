// ===================================================================
// KARRIKO – Company Profile Script
// ===================================================================

const params = new URLSearchParams(window.location.search);
const companyNameParam = params.get("name");
const companyName = companyNameParam || "Beispiel Firma GmbH";

const API_URL = "http://localhost:3000/api";

let currentCompanyId = null;
let allReviews = [];
let categories = [];
let currentStep = 0;
let isLoginMode = true;

// DOM Elements
const authModal = document.getElementById("auth-modal");
const btnLogin = document.getElementById("btn-login");
const btnRegister = document.getElementById("btn-register");
const btnLogout = document.getElementById("btn-logout");
const authForm = document.getElementById("auth-form");
const authSubmitBtn = document.getElementById("auth-submit");
const switchAuth = document.getElementById("switch-auth");
const modalTitle = document.getElementById("modal-title");
const userProfile = document.getElementById("user-profile");
const authButtons = document.getElementById("auth-buttons");
const closeAuthModal = document.querySelector(".close-auth-modal");

document.addEventListener("DOMContentLoaded", () => {
  loadCategories();
  loadCompanyData();
  checkAuthStatus();
  setupEvents();

  // Navbar scroll
  window.addEventListener("scroll", () => {
    const nav = document.getElementById("main-navbar");
    if (nav) nav.classList.toggle("scrolled", window.scrollY > 20);
  });
});

// ===== COMPANY DATA =====
async function loadCompanyData() {
  try {
    const res = await fetch(`${API_URL}/companies?name=${encodeURIComponent(companyName)}`);
    if (!res.ok) throw new Error("Firma nicht gefunden");

    const company = await res.json();
    currentCompanyId = company.id;

    document.title = `${company.name} | Karriko`;
    document.getElementById("company-name").textContent = company.name;
    document.getElementById("company-logo").textContent = company.name.substring(0, 2).toUpperCase();
    document.getElementById("company-desc").textContent = company.description || "";

    if (company.industry) {
      document.getElementById("company-industry").querySelector("span").textContent = company.industry;
    }

    if (company.header_image_url) {
      document.getElementById("company-header").style.background =
        `linear-gradient(rgba(0,0,0,0.2), rgba(0,0,0,0.5)), url('${company.header_image_url}')`;
      document.getElementById("company-header").style.backgroundSize = "cover";
      document.getElementById("company-header").style.backgroundPosition = "center";
    }

    loadReviews(company.id);
    loadCompanyJobs(company.id);
  } catch (e) {
    console.error(e);
    document.getElementById("company-name").textContent = companyName + " (Nicht gefunden)";
  }
}

// ===== REVIEWS =====
async function loadReviews(companyId) {
  if (!companyId) return;
  try {
    const res = await fetch(`${API_URL}/reviews?companyId=${companyId}&limit=50`);
    const reviews = await res.json();
    allReviews = reviews;
    renderStats(reviews);
    renderReviewsList(reviews);
  } catch (e) {
    console.error("Fehler beim Laden der Reviews", e);
  }
}

function renderStats(reviews) {
  const totalWeight = reviews.reduce((acc, r) => acc + r.weight, 0);
  const weightedSum = reviews.reduce((acc, r) => acc + (r.rating * r.weight), 0);
  const avg = totalWeight > 0 ? (weightedSum / totalWeight).toFixed(1) : "0.0";

  document.getElementById("avg-rating").textContent = avg;
  document.getElementById("total-reviews").textContent = `(${reviews.length} Bewertungen)`;
}

function renderReviewsList(reviews) {
  const list = document.getElementById("reviews-list");
  const sortVal = document.getElementById("sort-select").value;

  let sorted = [...reviews];
  if (sortVal === "newest") sorted.sort((a, b) => new Date(b.date) - new Date(a.date));
  else sorted.sort((a, b) => b.rating - a.rating);

  if (sorted.length === 0) {
    list.innerHTML = '<div class="empty-state"><i data-lucide="message-circle" style="width:48px; height:48px"></i><p>Noch keine Bewertungen. Sei der Erste!</p></div>';
    lucide.createIcons();
    return;
  }

  const user = JSON.parse(localStorage.getItem("karriko_user"));

  list.innerHTML = sorted.map(r => `
    <div class="card" style="padding: 1.5rem">
      <div style="display: flex; justify-content: space-between; align-items: flex-start; margin-bottom: 1rem">
        <div class="review-card-header" style="margin-bottom: 0">
          <img src="${r.image}" class="review-avatar" alt="${r.user}" loading="lazy">
          <div>
            <strong>${r.user}</strong>
            ${r.anonymous ? '<span class="tag tag-warning" style="margin-left: 0.5rem; font-size: 0.65rem">50% Gewichtung</span>' : '<span class="tag tag-success" style="margin-left: 0.5rem; font-size: 0.65rem">100% Gewichtung</span>'}
            <div class="review-stars">${"★".repeat(Math.round(r.rating))}${"☆".repeat(5 - Math.round(r.rating))}</div>
          </div>
        </div>
        <span style="font-size: 0.8rem; color: var(--text-light)">${new Date(r.date).toLocaleDateString("de-DE")}</span>
      </div>
      <p class="review-text">${r.text}</p>
      <div class="review-actions">
        <button class="helpful-btn" onclick="markHelpful(${r.id})">
          <i data-lucide="thumbs-up" style="width:14px; height:14px"></i>
          Hilfreich ${r.helpful_count > 0 ? `(${r.helpful_count})` : ''}
        </button>
      </div>
      <div id="reply-${r.id}"></div>
    </div>
  `).join("");

  lucide.createIcons();

  // Load replies
  sorted.forEach(r => loadReviewReply(r.id));
}

async function loadReviewReply(reviewId) {
  try {
    const res = await fetch(`${API_URL}/reviews/${reviewId}/comments`);
    const comments = await res.json();
    const container = document.getElementById(`reply-${reviewId}`);
    if (container && comments.length > 0) {
      container.innerHTML = comments.map(c => `
        <div class="review-reply">
          <strong>Antwort des Unternehmens</strong>
          <p style="margin-top: 0.5rem; color: var(--text-secondary)">${c.text}</p>
          <small style="color: var(--text-light)">${new Date(c.created_at).toLocaleDateString("de-DE")}</small>
        </div>
      `).join("");
    }
  } catch (e) { /* ignore */ }
}

async function markHelpful(reviewId) {
  const user = JSON.parse(localStorage.getItem("karriko_user"));
  if (!user) {
    openAuthModalFn("login");
    return;
  }
  try {
    await fetch(`${API_URL}/reviews/${reviewId}/helpful`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ user_id: user.id }),
    });
    if (currentCompanyId) loadReviews(currentCompanyId);
  } catch (e) { console.error(e); }
}

// ===== JOBS =====
async function loadCompanyJobs(companyId) {
  try {
    const res = await fetch(`${API_URL}/jobs?companyId=${companyId}&limit=10`);
    const jobs = await res.json();
    const jobList = document.getElementById("jobs-list");

    if (jobs.length === 0) {
      jobList.innerHTML = '<p style="color: var(--text-muted); font-size: 0.9rem">Keine offenen Stellen.</p>';
      return;
    }

    jobList.innerHTML = jobs.map(j => `
      <div class="card" style="padding: 1.25rem; cursor: pointer" onclick="window.location.href='job-detail.html?id=${j.id}'">
        <h4 style="margin-bottom: 0.3rem; font-size: 0.95rem">${j.title}</h4>
        <div style="display: flex; gap: 0.5rem; align-items: center; color: var(--text-muted); font-size: 0.8rem">
          <i data-lucide="map-pin" style="width:12px; height:12px"></i>
          <span>${j.location || 'Standort'}</span>
        </div>
        <span style="color: var(--primary); font-weight: 500; font-size: 0.8rem; margin-top: 0.5rem; display: inline-block">Details →</span>
      </div>
    `).join("");

    lucide.createIcons();
  } catch (e) {
    console.error(e);
  }
}

// ===== RATING FORM (Multi-Step) =====
async function loadCategories() {
  try {
    const res = await fetch(`${API_URL}/review-categories`);
    categories = await res.json();
    buildRatingSteps();
  } catch (e) {
    console.error("Kategorien laden fehlgeschlagen", e);
  }
}

function buildRatingSteps() {
  const container = document.getElementById("questions-container");
  const indicator = document.getElementById("step-indicator");

  // Build step indicators (categories + comment)
  const totalSteps = categories.length + 1;
  indicator.innerHTML = Array.from({ length: totalSteps }, (_, i) =>
    `<div class="step-dot ${i === 0 ? 'active' : ''}" data-step="${i}"></div>`
  ).join("");

  // Build category steps
  container.innerHTML = categories.map((cat, catIdx) => `
    <div class="category-step ${catIdx === 0 ? 'active' : ''}" data-step="${catIdx}">
      <h3 style="margin-bottom: 1.25rem; color: var(--primary)">${cat.name}</h3>
      ${cat.questions.map((q, qIdx) => `
        <div style="margin-bottom: 1.25rem">
          <label style="display: block; margin-bottom: 0.4rem; font-weight: 500; font-size: 0.9rem; color: var(--text-secondary)">${q.text}</label>
          <div style="display: flex; gap: 0.4rem">
            ${[1, 2, 3, 4, 5].map(v => `
              <label style="cursor: pointer; padding: 0.35rem 0.65rem; border: 1px solid var(--border); border-radius: var(--radius-md); transition: 0.15s; font-size: 0.85rem; display: flex; align-items: center; gap: 0.2rem">
                <input type="radio" name="q_${q.id}" value="${v}" style="display:none" required>
                <span class="star-label">${v}★</span>
              </label>
            `).join("")}
          </div>
        </div>
      `).join("")}
    </div>
  `).join("");

  // Make radio labels interactive
  container.querySelectorAll('label').forEach(label => {
    const radio = label.querySelector('input[type="radio"]');
    if (radio) {
      label.addEventListener('click', () => {
        radio.checked = true;
        // Highlight selected
        const name = radio.name;
        document.querySelectorAll(`input[name="${name}"]`).forEach(r => {
          r.closest('label').style.background = '';
          r.closest('label').style.borderColor = 'var(--border)';
          r.closest('label').style.color = '';
        });
        label.style.background = 'var(--primary-light)';
        label.style.borderColor = 'var(--primary)';
        label.style.color = 'var(--primary)';
      });
    }
  });

  currentStep = 0;
  updateStepUI();
}

function updateStepUI() {
  const steps = document.querySelectorAll(".category-step");
  const dots = document.querySelectorAll(".step-dot");
  const totalSteps = categories.length + 1; // +1 for comment
  const isLastCategoryStep = currentStep === categories.length - 1;
  const isCommentStep = currentStep === categories.length;

  // Show/hide steps
  steps.forEach((s, i) => s.classList.toggle("active", i === currentStep));

  // Show/hide comment
  const commentEl = document.getElementById("step-comment");
  commentEl.style.display = isCommentStep ? "block" : "none";

  // Update dots
  dots.forEach((d, i) => {
    d.classList.toggle("active", i === currentStep);
    d.classList.toggle("done", i < currentStep);
  });

  // Show/hide buttons
  document.getElementById("btn-prev-step").style.display = currentStep > 0 ? "inline-flex" : "none";
  document.getElementById("btn-next-step").style.display = isCommentStep ? "none" : "inline-flex";
  document.getElementById("btn-submit-review").style.display = isCommentStep ? "inline-flex" : "none";
}

function setupEvents() {
  // Rating Modal
  const ratingModal = document.getElementById("rating-modal");
  const btnRate = document.getElementById("btn-rate");
  const closeRating = document.querySelector(".close-rating-modal");

  btnRate.addEventListener("click", () => {
    const user = JSON.parse(localStorage.getItem("karriko_user"));
    if (!user) {
      openAuthModalFn("login");
      return;
    }
    currentStep = 0;
    updateStepUI();
    ratingModal.classList.remove("hidden");
    void ratingModal.offsetWidth;
    ratingModal.classList.add("active");
  });

  closeRating.addEventListener("click", () => {
    ratingModal.classList.remove("active");
    setTimeout(() => ratingModal.classList.add("hidden"), 300);
  });

  ratingModal.addEventListener("click", (e) => {
    if (e.target === ratingModal) {
      ratingModal.classList.remove("active");
      setTimeout(() => ratingModal.classList.add("hidden"), 300);
    }
  });

  // Step navigation
  document.getElementById("btn-next-step").addEventListener("click", () => {
    if (currentStep < categories.length) {
      currentStep++;
      updateStepUI();
    }
  });

  document.getElementById("btn-prev-step").addEventListener("click", () => {
    if (currentStep > 0) {
      currentStep--;
      updateStepUI();
    }
  });

  document.getElementById("rating-form").addEventListener("submit", handleRatingSubmit);
  document.getElementById("sort-select").addEventListener("change", () => {
    if (currentCompanyId) loadReviews(currentCompanyId);
  });

  // Auth Events
  if (btnLogin) btnLogin.addEventListener("click", () => openAuthModalFn("login"));
  if (btnRegister) btnRegister.addEventListener("click", () => openAuthModalFn("register"));
  if (btnLogout) btnLogout.addEventListener("click", logout);
  if (closeAuthModal) closeAuthModal.addEventListener("click", () => {
    authModal.classList.remove("active");
    setTimeout(() => authModal.classList.add("hidden"), 300);
  });
  if (switchAuth) switchAuth.addEventListener("click", (e) => { e.preventDefault(); toggleAuthMode(); });
  if (authForm) authForm.addEventListener("submit", handleAuthSubmit);
}

// ===== AUTH =====
function checkAuthStatus() {
  const user = JSON.parse(localStorage.getItem("karriko_user"));
  if (user) {
    if (authButtons) authButtons.classList.add("hidden");
    if (userProfile) userProfile.classList.remove("hidden");
    document.getElementById("user-name").textContent = user.username;
  } else {
    if (authButtons) authButtons.classList.remove("hidden");
    if (userProfile) userProfile.classList.add("hidden");
  }
}

function logout() {
  localStorage.removeItem("karriko_user");
  window.location.reload();
}

function openAuthModalFn(mode) {
  isLoginMode = mode === "login";
  updateModalUI();
  authModal.classList.remove("hidden");
  void authModal.offsetWidth;
  authModal.classList.add("active");
}

function toggleAuthMode() {
  isLoginMode = !isLoginMode;
  updateModalUI();
}

function updateModalUI() {
  if (modalTitle) modalTitle.textContent = isLoginMode ? "Anmelden" : "Registrieren";
  if (authSubmitBtn) authSubmitBtn.textContent = isLoginMode ? "Anmelden" : "Konto erstellen";
  if (switchAuth) switchAuth.textContent = isLoginMode ? "Registrieren" : "Anmelden";
}

async function handleAuthSubmit(e) {
  e.preventDefault();
  const email = document.getElementById("email").value;
  const password = document.getElementById("password").value;
  const endpoint = isLoginMode ? "/login" : "/register";

  try {
    const res = await fetch(`${API_URL}${endpoint}`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ email, password }),
    });
    const data = await res.json();

    if (data.success) {
      if (isLoginMode) {
        localStorage.setItem("karriko_user", JSON.stringify(data.user));
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

// ===== SUBMIT RATING =====
async function handleRatingSubmit(e) {
  e.preventDefault();

  const user = JSON.parse(localStorage.getItem("karriko_user"));
  if (!user) { openAuthModalFn("login"); return; }

  // Collect answers
  const answers = [];
  let totalStars = 0;
  let starCount = 0;

  categories.forEach(cat => {
    cat.questions.forEach(q => {
      const selected = document.querySelector(`input[name="q_${q.id}"]:checked`);
      if (selected) {
        const val = parseInt(selected.value);
        answers.push({ question_id: q.id, star_value: val });
        totalStars += val;
        starCount++;
      }
    });
  });

  const overallScore = starCount > 0 ? (totalStars / starCount) : 0;
  const text = document.getElementById("rating-text").value;
  const isAnon = document.querySelector('input[name="anonymity"]:checked').value === "anonymous";

  const payload = {
    companyId: currentCompanyId,
    companyName: companyName,
    rating: parseFloat(overallScore.toFixed(1)),
    text: text,
    isAnonymous: isAnon,
    weight: isAnon ? 0.5 : 1.0,
    username: user.username,
    userId: user.id,
    answers: answers,
  };

  try {
    const res = await fetch(`${API_URL}/reviews`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(payload),
    });
    const data = await res.json();

    if (data.success) {
      const ratingModal = document.getElementById("rating-modal");
      ratingModal.classList.remove("active");
      setTimeout(() => ratingModal.classList.add("hidden"), 300);
      if (currentCompanyId) loadReviews(currentCompanyId);
      if (window.showToast) window.showToast("Bewertung erfolgreich veröffentlicht!", "success");
      else alert("Bewertung erfolgreich veröffentlicht!");
    } else {
      alert("Fehler: " + (data.error || "Unbekannt"));
    }
  } catch (e) {
    console.error(e);
    alert("Sendefehler.");
  }
}
