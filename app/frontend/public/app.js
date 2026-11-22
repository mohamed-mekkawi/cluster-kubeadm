let token = localStorage.getItem('token');
let user = JSON.parse(localStorage.getItem('user') || 'null');
let registerMode = false;

const $ = (id) => document.getElementById(id);

// ---------- helpers ----------
async function api(path, options = {}) {
  const headers = { 'Content-Type': 'application/json' };
  if (token) headers.Authorization = 'Bearer ' + token;
  const res = await fetch(path, { ...options, headers });
  const data = await res.json().catch(() => ({}));
  if (!res.ok) {
    if (res.status === 401 && token) clearSession(); // token انتهت
    throw new Error(data.error || 'Request failed');
  }
  return data;
}

function showMessage(text, type = 'ok') {
  const m = $('message');
  m.textContent = text;
  m.className = 'message ' + type;
  setTimeout(() => m.classList.add('hidden'), 4000);
}

function clearSession() {
  token = null;
  user = null;
  localStorage.removeItem('token');
  localStorage.removeItem('user');
  renderAll();
}

function el(tag, props = {}, ...children) {
  const e = document.createElement(tag);
  Object.assign(e, props);
  children.forEach((c) => e.append(c));
  return e;
}

// ---------- nav ----------
function renderNav() {
  const nav = $('nav');
  nav.replaceChildren();
  if (user) {
    nav.append(
      el('span', { textContent: 'Hi, ' + user.name }),
      el('button', { textContent: 'Books', onclick: () => showView('books') }),
      el('button', { textContent: 'My books', onclick: () => showView('tx') }),
      el('button', { textContent: 'Logout', onclick: logout })
    );
  } else {
    nav.append(el('button', { textContent: 'Login', onclick: () => showView('auth') }));
  }
}

function showView(view) {
  $('auth-view').classList.toggle('hidden', view !== 'auth');
  $('books-view').classList.toggle('hidden', view !== 'books');
  $('tx-view').classList.toggle('hidden', view !== 'tx');
  if (view === 'tx') loadTransactions();
}

// ---------- auth ----------
function setAuthMode(register) {
  registerMode = register;
  $('auth-title').textContent = register ? 'Register' : 'Login';
  $('auth-submit').textContent = register ? 'Register' : 'Login';
  $('name').classList.toggle('hidden', !register);
  $('name').required = register;
  $('auth-toggle').textContent = register ? 'Have an account? Login' : 'No account? Register';
}

$('auth-toggle').onclick = (e) => {
  e.preventDefault();
  setAuthMode(!registerMode);
};

$('auth-form').onsubmit = async (e) => {
  e.preventDefault();
  const email = $('email').value;
  const password = $('password').value;
  try {
    if (registerMode) {
      await api('/api/auth/register', {
        method: 'POST',
        body: JSON.stringify({ name: $('name').value, email, password }),
      });
      showMessage('Registered! You can login now.');
      setAuthMode(false);
      return;
    }
    const data = await api('/api/auth/login', {
      method: 'POST',
      body: JSON.stringify({ email, password }),
    });
    token = data.token;
    user = data.user;
    localStorage.setItem('token', token);
    localStorage.setItem('user', JSON.stringify(user));
    $('auth-form').reset();
    renderAll();
    showMessage('Welcome ' + user.name);
  } catch (err) {
    showMessage(err.message, 'error'); // أخطاء: بيانات غلط / إيميل مكرر ...
  }
};

async function logout() {
  try { await api('/api/auth/logout', { method: 'POST' }); } catch {}
  clearSession();
}

// ---------- books ----------
function bookCard(b) {
  const cover = b.cover_image
    ? el('img', { src: b.cover_image, alt: b.title, onerror: (ev) => ev.target.replaceWith(el('div', { className: 'cover-fallback', textContent: b.title })) })
    : el('div', { className: 'cover-fallback', textContent: b.title });

  const buy = el('button', { textContent: 'Buy', disabled: b.available_quantity < 1, onclick: () => act('/api/books/' + b.id + '/buy', 'Purchase completed') });
  const borrow = el('button', { textContent: 'Borrow', disabled: !b.available_for_borrowing, onclick: () => act('/api/books/' + b.id + '/borrow', 'Book borrowed') });

  return el('div', { className: 'card book' },
    cover,
    el('h3', { textContent: b.title }),
    el('p', { textContent: b.author }),
    el('p', {}, el('span', { className: 'badge', textContent: b.category })),
    el('p', { textContent: '$' + b.price.toFixed(2) }),
    el('p', { textContent: 'Total: ' + b.total_quantity + ' | Available: ' + b.available_quantity }),
    el('p', {}, el('span', { className: 'badge ' + (b.available_for_borrowing ? 'ok' : 'no'), textContent: b.available_for_borrowing ? 'Available for borrowing' : 'Not available' })),
    el('div', { className: 'actions' }, buy, borrow)
  );
}

async function loadBooks() {
  try {
    const books = await api('/api/books');
    $('books').replaceChildren(...books.map(bookCard));
  } catch (err) {
    showMessage(err.message, 'error');
  }
}

async function act(path, okText) {
  if (!user) {
    showView('auth');
    return showMessage('Please login first', 'error');
  }
  try {
    await api(path, { method: 'POST' });
    showMessage(okText);
    loadBooks();
  } catch (err) {
    showMessage(err.message, 'error');
  }
}

// ---------- my transactions ----------
async function loadTransactions() {
  try {
    const rows = await api('/api/transactions/me');
    const fmt = (d) => (d ? new Date(d).toLocaleDateString() : '-');
    $('tx-body').replaceChildren(
      ...rows.map((t) =>
        el('tr', {},
          el('td', { textContent: t.title }),
          el('td', { textContent: t.type }),
          el('td', { textContent: t.status }),
          el('td', { textContent: fmt(t.created_at) }),
          el('td', { textContent: fmt(t.due_date) }),
          el('td', {}, t.status === 'borrowed'
            ? el('button', { textContent: 'Return', onclick: () => returnBook(t.id) })
            : '')
        )
      )
    );
  } catch (err) {
    showMessage(err.message, 'error');
  }
}

async function returnBook(id) {
  try {
    await api('/api/transactions/' + id + '/return', { method: 'POST' });
    showMessage('Book returned');
    loadTransactions();
    loadBooks();
  } catch (err) {
    showMessage(err.message, 'error');
  }
}

// ---------- start ----------
function renderAll() {
  renderNav();
  showView('books');
  loadBooks();
}
renderAll();
