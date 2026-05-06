/**
 * INPTIC — Gestion des Étudiants
 * Frontend JavaScript — exploite l'API REST /api/etudiants
 */

'use strict';

// ── Configuration ─────────────────────────────────────────────────────
const API_BASE = '/api';
const API_TOKEN = '42caf83f7df3498f4010d2f49487bdb4575fb71ee4f659d9443c3b82e39172b9';

// État de la pagination
const state = {
    page: 1,
    perPage: 10,
    total: 0,
    search: '',
    filiere: '',
    annee: '',
};

// ── Utilitaires HTTP ──────────────────────────────────────────────────

async function apiFetch(path, options = {}) {
    const url = `${API_BASE}${path}`;
    const headers = {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${API_TOKEN}`,
        ...options.headers,
    };

    try {
        const response = await fetch(url, { ...options, headers });
        const data = await response.json();

        if (!response.ok) {
            throw new Error(data.error || `Erreur HTTP ${response.status}`);
        }
        return data;
    } catch (err) {
        if (err instanceof TypeError) {
            throw new Error('Impossible de joindre le serveur. Vérifiez votre connexion.');
        }
        throw err;
    }
}

// ── Navigation ────────────────────────────────────────────────────────

function showView(viewName) {
    // Masquer toutes les vues
    document.querySelectorAll('.view').forEach(v => v.classList.remove('active'));
    document.querySelectorAll('.nav-btn').forEach(b => b.classList.remove('active'));

    // Afficher la vue demandée
    const view = document.getElementById(`view-${viewName}`);
    const btn  = document.querySelector(`[data-view="${viewName}"]`);
    if (view) view.classList.add('active');
    if (btn)  btn.classList.add('active');

    // Charger les données selon la vue
    if (viewName === 'dashboard') loadDashboard();
    if (viewName === 'etudiants') loadEtudiants();
}

// Écouter les clics sur la nav
document.querySelectorAll('.nav-btn').forEach(btn => {
    btn.addEventListener('click', () => showView(btn.dataset.view));
});

// ── Dashboard ─────────────────────────────────────────────────────────

async function loadDashboard() {
    try {
        const stats = await apiFetch('/stats');

        document.getElementById('stat-total').textContent    = stats.total_etudiants;
        document.getElementById('stat-filieres').textContent = stats.par_filiere.length;
        document.getElementById('stat-annees').textContent   = stats.par_annee.length;

        renderBarChart('chart-filieres', stats.par_filiere, 'filiere');
        renderBarChart('chart-annees',   stats.par_annee,   'annee');

        // Peupler les filtres
        populateFilter('filter-filiere', stats.par_filiere, 'filiere');
        populateFilter('filter-annee',   stats.par_annee,   'annee');

    } catch (err) {
        showToast('Erreur chargement dashboard : ' + err.message, 'error');
    }
}

function renderBarChart(containerId, data, labelKey) {
    const container = document.getElementById(containerId);
    if (!data.length) {
        container.innerHTML = '<p style="color:#aaa;text-align:center;padding:2rem">Aucune donnée</p>';
        return;
    }

    const max = Math.max(...data.map(d => d.count));
    container.innerHTML = data.map(item => `
        <div class="chart-bar">
            <div class="chart-label" title="${item[labelKey]}">${item[labelKey]}</div>
            <div class="chart-bar-container">
                <div class="chart-bar-fill" style="width:${(item.count / max * 100).toFixed(1)}%">
                    ${item.count}
                </div>
            </div>
        </div>
    `).join('');
}

function populateFilter(selectId, data, labelKey) {
    const select = document.getElementById(selectId);
    const current = select.value;
    // Garder l'option "Tous"
    const firstOption = select.options[0];
    select.innerHTML = '';
    select.appendChild(firstOption);
    data.forEach(item => {
        const opt = document.createElement('option');
        opt.value = item[labelKey];
        opt.textContent = `${item[labelKey]} (${item.count})`;
        select.appendChild(opt);
    });
    select.value = current;
}

// ── Liste des étudiants ───────────────────────────────────────────────

async function loadEtudiants() {
    const tbody = document.getElementById('etudiants-tbody');
    tbody.innerHTML = '<tr><td colspan="8" class="loading">⏳ Chargement...</td></tr>';

    try {
        const params = new URLSearchParams({
            page:     state.page,
            per_page: state.perPage,
        });
        if (state.search)  params.set('search',  state.search);
        if (state.filiere) params.set('filiere', state.filiere);
        if (state.annee)   params.set('annee',   state.annee);

        const result = await apiFetch(`/etudiants?${params}`);
        state.total = result.pagination.total;

        renderTable(result.data);
        renderPagination(result.pagination);

    } catch (err) {
        tbody.innerHTML = `<tr><td colspan="8" class="loading" style="color:#e74c3c">
            ❌ ${err.message}
        </td></tr>`;
    }
}

function renderTable(etudiants) {
    const tbody = document.getElementById('etudiants-tbody');

    if (!etudiants.length) {
        tbody.innerHTML = '<tr><td colspan="8" class="loading">Aucun étudiant trouvé</td></tr>';
        return;
    }

    tbody.innerHTML = etudiants.map(e => `
        <tr>
            <td><strong>#${e.id}</strong></td>
            <td>${escapeHtml(e.nom)}</td>
            <td>${escapeHtml(e.prenom)}</td>
            <td><a href="mailto:${escapeHtml(e.email)}">${escapeHtml(e.email)}</a></td>
            <td><span class="badge">${escapeHtml(e.filiere)}</span></td>
            <td>${escapeHtml(e.annee)}</td>
            <td>${formatDate(e.date_inscription)}</td>
            <td>
                <div class="actions">
                    <button class="btn-icon edit" title="Modifier" onclick="openModifier(${e.id})">✏️</button>
                    <button class="btn-icon delete" title="Supprimer" onclick="confirmerSuppression(${e.id}, '${escapeHtml(e.prenom)} ${escapeHtml(e.nom)}')">🗑️</button>
                </div>
            </td>
        </tr>
    `).join('');
}

function renderPagination(pagination) {
    const container = document.getElementById('pagination');
    const { page, pages, total, per_page } = pagination;

    if (pages <= 1) {
        container.innerHTML = `<span class="pagination-info">${total} étudiant${total > 1 ? 's' : ''}</span>`;
        return;
    }

    const start = (page - 1) * per_page + 1;
    const end   = Math.min(page * per_page, total);

    let html = `<span class="pagination-info">${start}–${end} sur ${total}</span>`;
    html += `<button onclick="goToPage(1)" ${page === 1 ? 'disabled' : ''}>«</button>`;
    html += `<button onclick="goToPage(${page - 1})" ${page === 1 ? 'disabled' : ''}>‹</button>`;

    // Pages autour de la page courante
    const range = 2;
    for (let i = Math.max(1, page - range); i <= Math.min(pages, page + range); i++) {
        html += `<button onclick="goToPage(${i})" class="${i === page ? 'active' : ''}">${i}</button>`;
    }

    html += `<button onclick="goToPage(${page + 1})" ${page === pages ? 'disabled' : ''}>›</button>`;
    html += `<button onclick="goToPage(${pages})" ${page === pages ? 'disabled' : ''}>»</button>`;

    container.innerHTML = html;
}

function goToPage(page) {
    state.page = page;
    loadEtudiants();
}

// ── Filtres ───────────────────────────────────────────────────────────

let searchTimeout;
document.getElementById('search-input').addEventListener('input', e => {
    clearTimeout(searchTimeout);
    searchTimeout = setTimeout(() => {
        state.search = e.target.value.trim();
        state.page   = 1;
        loadEtudiants();
    }, 400);
});

document.getElementById('filter-filiere').addEventListener('change', e => {
    state.filiere = e.target.value;
    state.page    = 1;
    loadEtudiants();
});

document.getElementById('filter-annee').addEventListener('change', e => {
    state.annee = e.target.value;
    state.page  = 1;
    loadEtudiants();
});

function resetFilters() {
    state.search  = '';
    state.filiere = '';
    state.annee   = '';
    state.page    = 1;
    document.getElementById('search-input').value   = '';
    document.getElementById('filter-filiere').value = '';
    document.getElementById('filter-annee').value   = '';
    loadEtudiants();
}

// ── Ajouter un étudiant ───────────────────────────────────────────────

document.getElementById('form-ajouter').addEventListener('submit', async e => {
    e.preventDefault();
    const btn = e.target.querySelector('[type="submit"]');
    btn.disabled = true;
    btn.textContent = '⏳ Enregistrement...';

    const payload = {
        nom:     document.getElementById('input-nom').value.trim(),
        prenom:  document.getElementById('input-prenom').value.trim(),
        email:   document.getElementById('input-email').value.trim(),
        filiere: document.getElementById('input-filiere').value,
        annee:   document.getElementById('input-annee').value,
    };

    try {
        const etudiant = await apiFetch('/etudiants', {
            method: 'POST',
            body:   JSON.stringify(payload),
        });

        showMessage('form-message', `✅ Étudiant ${etudiant.prenom} ${etudiant.nom} ajouté avec succès ! Un email de notification a été envoyé.`, 'success');
        showToast(`✅ ${etudiant.prenom} ${etudiant.nom} ajouté`, 'success');
        resetForm();

        // Rafraîchir le dashboard si on y revient
        setTimeout(() => loadDashboard(), 500);

    } catch (err) {
        showMessage('form-message', `❌ ${err.message}`, 'error');
        showToast(err.message, 'error');
    } finally {
        btn.disabled = false;
        btn.textContent = '✅ Enregistrer';
    }
});

function resetForm() {
    document.getElementById('form-ajouter').reset();
    const msg = document.getElementById('form-message');
    msg.className = 'message';
    msg.textContent = '';
}

// ── Modifier un étudiant ──────────────────────────────────────────────

async function openModifier(id) {
    try {
        const etudiant = await apiFetch(`/etudiants/${id}`);

        document.getElementById('edit-id').value      = etudiant.id;
        document.getElementById('edit-nom').value     = etudiant.nom;
        document.getElementById('edit-prenom').value  = etudiant.prenom;
        document.getElementById('edit-email').value   = etudiant.email;
        document.getElementById('edit-filiere').value = etudiant.filiere;
        document.getElementById('edit-annee').value   = etudiant.annee;

        document.getElementById('modal-modifier').classList.add('active');

    } catch (err) {
        showToast('Erreur chargement étudiant : ' + err.message, 'error');
    }
}

document.getElementById('form-modifier').addEventListener('submit', async e => {
    e.preventDefault();
    const btn = e.target.querySelector('[type="submit"]');
    btn.disabled = true;
    btn.textContent = '⏳ Enregistrement...';

    const id = document.getElementById('edit-id').value;
    const payload = {
        nom:     document.getElementById('edit-nom').value.trim(),
        prenom:  document.getElementById('edit-prenom').value.trim(),
        email:   document.getElementById('edit-email').value.trim(),
        filiere: document.getElementById('edit-filiere').value,
        annee:   document.getElementById('edit-annee').value,
    };

    try {
        const etudiant = await apiFetch(`/etudiants/${id}`, {
            method: 'PUT',
            body:   JSON.stringify(payload),
        });

        showToast(`✅ ${etudiant.prenom} ${etudiant.nom} modifié`, 'success');
        closeModal();
        loadEtudiants();

    } catch (err) {
        showToast('Erreur modification : ' + err.message, 'error');
    } finally {
        btn.disabled = false;
        btn.textContent = '💾 Enregistrer';
    }
});

function closeModal() {
    document.getElementById('modal-modifier').classList.remove('active');
}

// Fermer le modal en cliquant en dehors
document.getElementById('modal-modifier').addEventListener('click', e => {
    if (e.target === e.currentTarget) closeModal();
});

// ── Supprimer un étudiant ─────────────────────────────────────────────

function confirmerSuppression(id, nom) {
    if (!confirm(`⚠️ Supprimer l'étudiant "${nom}" ?\n\nUn email de notification sera envoyé.`)) return;
    supprimerEtudiant(id, nom);
}

async function supprimerEtudiant(id, nom) {
    try {
        await apiFetch(`/etudiants/${id}`, { method: 'DELETE' });
        showToast(`🗑️ ${nom} supprimé — notification email envoyée`, 'success');
        loadEtudiants();
        loadDashboard();
    } catch (err) {
        showToast('Erreur suppression : ' + err.message, 'error');
    }
}

// ── Notifications Toast ───────────────────────────────────────────────

function showToast(message, type = 'info') {
    const container = document.getElementById('toast-container');
    const toast = document.createElement('div');
    toast.className = `toast ${type}`;
    toast.textContent = message;
    container.appendChild(toast);

    setTimeout(() => {
        toast.style.opacity = '0';
        toast.style.transform = 'translateX(100px)';
        toast.style.transition = 'all 0.3s ease';
        setTimeout(() => toast.remove(), 300);
    }, 4000);
}

function showMessage(elementId, message, type) {
    const el = document.getElementById(elementId);
    el.textContent = message;
    el.className = `message ${type}`;
}

// ── Utilitaires ───────────────────────────────────────────────────────

function escapeHtml(str) {
    const div = document.createElement('div');
    div.appendChild(document.createTextNode(str || ''));
    return div.innerHTML;
}

function formatDate(isoString) {
    if (!isoString) return '—';
    const d = new Date(isoString);
    return d.toLocaleDateString('fr-FR', {
        day:   '2-digit',
        month: '2-digit',
        year:  'numeric',
        hour:  '2-digit',
        minute:'2-digit',
    });
}

// ── Initialisation ────────────────────────────────────────────────────

document.addEventListener('DOMContentLoaded', () => {
    loadDashboard();
});
