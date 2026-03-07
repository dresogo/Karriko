const params = new URLSearchParams(window.location.search);
const companyNameParam = params.get('name');
const companyName = companyNameParam || "Beispiel Firma GmbH";

// API
const API_URL = "http://localhost:3000/api";

// Main
document.addEventListener('DOMContentLoaded', () => {
    initRatingForm();
    loadCompanyData();
    checkAuthStatus(); // Check on load

    document.getElementById('sort-select').addEventListener('change', () => loadReviews(currentCompanyId));

    // Modal & Auth Events
    setupEvents();
});

let currentCompanyId = null;
let allReviews = [];
let isLoginMode = true;

// Auth UI Elements
const authModal = document.getElementById('auth-modal');
const btnLogin = document.getElementById('btn-login');
const btnRegister = document.getElementById('btn-register');
const btnLogout = document.getElementById('btn-logout');
const authForm = document.getElementById('auth-form');
const authSubmitBtn = document.getElementById('auth-submit');
const switchAuth = document.getElementById('switch-auth');
const modalTitle = document.getElementById('modal-title');
const userProfile = document.getElementById('user-profile');
const authButtons = document.getElementById('auth-buttons');
const closeAuthModal = document.querySelector('.close-auth-modal');

async function loadCompanyData() {
    // 1. Company Infos laden
    try {
        const res = await fetch(`${API_URL}/companies?name=${encodeURIComponent(companyName)}`);

        if (!res.ok) throw new Error("Firma nicht gefunden");

        const company = await res.json();
        currentCompanyId = company.id;

        // UI Update
        document.title = `${company.name} | Bewertungen`;
        document.getElementById('company-name').textContent = company.name;
        document.getElementById('company-logo').textContent = company.name.substring(0, 2).toUpperCase();

        // Jetzt Reviews laden
        loadReviews(company.id);

        // Load Jobs (Mock/Real)
        renderJobs([
            { title: "Musterstelle 1", location: "Zentrale" },
            { title: "Ausbildung 2026", location: "Lokal" }
        ]);

    } catch (e) {
        console.error(e);
        document.getElementById('company-name').textContent = companyName + " (Nicht gefunden)";
    }
}

async function loadReviews(companyId) {
    if (!companyId) return;

    try {
        const res = await fetch(`${API_URL}/reviews?companyId=${companyId}`);
        const reviews = await res.json();
        allReviews = reviews;

        renderStats(reviews);
        renderReviewsList(reviews);
    } catch (e) {
        console.error("Fehler beim Laden der Reviews", e);
    }
}

function renderStats(reviews) {
    const totalWeight = reviews.reduce((acc, r) => acc + (r.weight || (r.anonymous ? 0.5 : 1.0)), 0);
    const weightedSum = reviews.reduce((acc, r) => acc + (r.rating * (r.weight || (r.anonymous ? 0.5 : 1.0))), 0);
    const avg = totalWeight > 0 ? (weightedSum / totalWeight).toFixed(1) : "0.0";

    document.getElementById('avg-rating').textContent = avg;
    document.getElementById('total-reviews').textContent = `(${reviews.length} Bewertungen)`;
}

function renderReviewsList(reviews) {
    const list = document.getElementById('reviews-list');
    const sortVal = document.getElementById('sort-select').value;

    let sorted = [...reviews];
    if (sortVal === 'newest') sorted.sort((a, b) => new Date(b.date) - new Date(a.date));
    else sorted.sort((a, b) => b.rating - a.rating);

    if (sorted.length === 0) {
        list.innerHTML = "<p>Noch keine Bewertungen.</p>";
        return;
    }

    list.innerHTML = sorted.map(r => `
        <div class="card" style="padding:1.5rem">
            <div style="display:flex; justify-content:space-between; margin-bottom:1rem">
                <div>
                   <span style="font-weight:bold">${r.user}</span>
                   ${r.anonymous ? '<span style="font-size:0.8rem; color:gray; margin-left:5px">(Gewichtung: 50%)</span>' : ''}
                </div>
                <div style="color:gold">${"★".repeat(Math.round(r.rating))}</div>
            </div>
            <p>${r.text}</p>
            <div style="margin-top:0.5rem; font-size:0.8rem; color:#888">${new Date(r.date).toLocaleDateString()}</div>
        </div>
    `).join('');
}

function renderJobs(jobs) {
    const jobList = document.getElementById('jobs-list');
    jobList.innerHTML = jobs.map(j => `
        <div class="card" style="padding:1rem">
            <h4 style="margin-bottom:0.25rem">${j.title}</h4>
            <small>${j.location}</small>
            <button class="btn btn-secondary" style="font-size:0.8rem; padding:0.25rem 0.5rem; margin-top:0.5rem">Bewerben</button>
        </div>
    `).join('');
}

// Rating Form & Modal
const categories = ["Arbeitsatmosphäre", "Ausbilder", "Aufgaben", "Karriere", "Vergütung"];

function initRatingForm() {
    const container = document.getElementById('questions-container');
    container.innerHTML = categories.map((cat, i) => `
        <div style="margin-bottom:1.5rem">
            <h4 style="margin-bottom:0.5rem">${cat}</h4>
            <div style="display:flex; gap:0.5rem">
               ${[1, 2, 3, 4, 5].map(v => `
                 <label style="cursor:pointer">
                    <input type="radio" name="cat_${i}" value="${v}" required> ${v}★
                 </label>
               `).join('')}
            </div>
        </div>
    `).join('');
}

function setupEvents() {
    // Rating Modal
    const ratingModal = document.getElementById('rating-modal');
    const btnRate = document.getElementById('btn-rate');
    const closeRating = document.querySelector('.close-rating-modal');

    btnRate.addEventListener('click', () => {
        // Auth Check
        const user = JSON.parse(localStorage.getItem('azubi_user'));
        if (!user) {
            // Zeige Auth Modal statt Alert
            openAuthModal('login');
            return;
        }
        ratingModal.classList.remove('hidden');
        ratingModal.classList.add('active');
    });

    closeRating.addEventListener('click', () => {
        ratingModal.classList.remove('active');
        setTimeout(() => ratingModal.classList.add('hidden'), 300);
    });

    document.getElementById('rating-form').addEventListener('submit', handleRatingSubmit);

    // Auth Events
    if (btnLogin) btnLogin.addEventListener('click', () => openAuthModal('login'));
    if (btnRegister) btnRegister.addEventListener('click', () => openAuthModal('register'));
    if (btnLogout) btnLogout.addEventListener('click', logout);
    if (closeAuthModal) closeAuthModal.addEventListener('click', () => authModal.classList.remove('active'));

    if (switchAuth) switchAuth.addEventListener('click', (e) => {
        e.preventDefault();
        toggleAuthMode();
    });

    if (authForm) authForm.addEventListener('submit', handleAuthSubmit);
}

// Auth Handlers
function checkAuthStatus() {
    const user = JSON.parse(localStorage.getItem('azubi_user'));
    if (user) {
        authButtons.classList.add('hidden');
        userProfile.classList.remove('hidden');
        document.getElementById('user-name').textContent = user.username;
    } else {
        authButtons.classList.remove('hidden');
        userProfile.classList.add('hidden');
    }
}

function logout() {
    localStorage.removeItem('azubi_user');
    window.location.reload();
}

function openAuthModal(mode) {
    isLoginMode = mode === 'login';
    updateModalUI();
    authModal.classList.remove('hidden');
    // small reflow trigger
    void authModal.offsetWidth;
    authModal.classList.add('active');
}

function toggleAuthMode() {
    isLoginMode = !isLoginMode;
    updateModalUI();
}

function updateModalUI() {
    modalTitle.textContent = isLoginMode ? 'Anmelden' : 'Registrieren';
    authSubmitBtn.textContent = isLoginMode ? 'Anmelden' : 'Konto erstellen';
    switchAuth.textContent = isLoginMode ? 'Registrieren' : 'Anmelden';
}

async function handleAuthSubmit(e) {
    e.preventDefault();
    const email = document.getElementById('email').value;
    const password = document.getElementById('password').value;
    const endpoint = isLoginMode ? '/login' : '/register';

    try {
        const res = await fetch(`${API_URL}${endpoint}`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ email, password })
        });

        const data = await res.json();

        if (data.success) {
            if (isLoginMode) {
                localStorage.setItem('azubi_user', JSON.stringify(data.user));
                authModal.classList.remove('active');
                setTimeout(() => authModal.classList.add('hidden'), 300);
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

async function handleRatingSubmit(e) {
    e.preventDefault();

    let sum = 0; let count = 0;
    categories.forEach((_, i) => {
        const val = document.querySelector(`input[name="cat_${i}"]:checked`);
        if (val) { sum += parseInt(val.value); count++; }
    });
    const finalRating = count > 0 ? Math.round(sum / count) : 0;
    const text = document.getElementById('rating-text').value;
    const isAnon = document.querySelector('input[name="anonymity"]:checked').value === 'anonymous';

    const user = JSON.parse(localStorage.getItem('azubi_user'));

    const payload = {
        companyName: companyName,
        rating: finalRating,
        text: text,
        isAnonymous: isAnon,
        weight: isAnon ? 0.5 : 1.0,
        username: user.username,
        userId: user.id
    };

    try {
        const res = await fetch(`${API_URL}/reviews`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(payload)
        });
        const data = await res.json();

        if (data.success) {
            alert("Bewertung erfolgreich veröffentlicht!");
            document.getElementById('rating-modal').classList.remove('active');
            if (currentCompanyId) loadReviews(currentCompanyId);
        } else {
            alert("Fehler: " + (data.error || "Unbekannt"));
        }
    } catch (e) {
        console.error(e);
        alert("Sendefehler.");
    }
}
