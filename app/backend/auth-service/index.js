const express = require('express');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const { Pool } = require('pg');

const PORT = process.env.PORT || 3001;
const JWT_SECRET = process.env.JWT_SECRET;
if (!JWT_SECRET) {
  console.error('JWT_SECRET is required');
  process.exit(1);
}

const pool = new Pool({
  host: process.env.DB_HOST || 'localhost',
  port: Number(process.env.DB_PORT || 5432),
  user: process.env.DB_USER || 'library',
  password: process.env.DB_PASSWORD,
  database: process.env.DB_NAME || 'library',
});

const app = express();
app.use(express.json());

const EMAIL_RE = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

// للـ Kubernetes liveness/readiness probes
app.get('/health', (req, res) => res.json({ status: 'ok' }));

// ---------- Register ----------
app.post('/api/auth/register', async (req, res) => {
  const { name, email, password } = req.body || {};

  if (!name || !email || !password) {
    return res.status(400).json({ error: 'Name, email and password are required' });
  }
  if (!EMAIL_RE.test(email)) {
    return res.status(400).json({ error: 'Invalid email format' });
  }
  if (password.length < 6) {
    return res.status(400).json({ error: 'Password must be at least 6 characters' });
  }

  try {
    const hash = await bcrypt.hash(password, 10);
    const { rows } = await pool.query(
      'INSERT INTO users (name, email, password_hash) VALUES ($1, $2, $3) RETURNING id, name, email',
      [name.trim(), email.toLowerCase().trim(), hash]
    );
    res.status(201).json({ message: 'Registered successfully', user: rows[0] });
  } catch (err) {
    if (err.code === '23505') {
      return res.status(409).json({ error: 'Email is already registered' });
    }
    console.error(err);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// ---------- Login ----------
app.post('/api/auth/login', async (req, res) => {
  const { email, password } = req.body || {};
  if (!email || !password) {
    return res.status(400).json({ error: 'Email and password are required' });
  }

  try {
    const { rows } = await pool.query('SELECT * FROM users WHERE email = $1', [
      email.toLowerCase().trim(),
    ]);
    const user = rows[0];
    // نفس الرسالة للحالتين عشان ما نكشفش هل الإيميل موجود
    const ok = user && (await bcrypt.compare(password, user.password_hash));
    if (!ok) {
      return res.status(401).json({ error: 'Invalid email or password' });
    }

    const token = jwt.sign({ id: user.id, email: user.email, name: user.name }, JWT_SECRET, {
      expiresIn: '2h',
    });
    res.json({ token, user: { id: user.id, name: user.name, email: user.email } });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// ---------- Logout ----------
// الـ JWT stateless، فالـ logout الفعلي بيحصل لما الـ frontend يمسح الـ token
app.post('/api/auth/logout', (req, res) => {
  res.json({ message: 'Logged out' });
});

// ---------- Current user ----------
app.get('/api/auth/me', (req, res) => {
  const header = req.headers.authorization || '';
  const token = header.startsWith('Bearer ') ? header.slice(7) : null;
  if (!token) return res.status(401).json({ error: 'Not authenticated' });
  try {
    const p = jwt.verify(token, JWT_SECRET);
    res.json({ user: { id: p.id, name: p.name, email: p.email } });
  } catch {
    res.status(401).json({ error: 'Invalid or expired token' });
  }
});

app.listen(PORT, () => console.log(`auth-service listening on ${PORT}`));
