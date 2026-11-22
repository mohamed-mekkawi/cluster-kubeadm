const express = require('express');
const jwt = require('jsonwebtoken');
const { Pool } = require('pg');

const PORT = process.env.PORT || 3002;
const JWT_SECRET = process.env.JWT_SECRET;
const BORROW_DAYS = Number(process.env.BORROW_DAYS || 14);
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

// ---------- Middleware: لازم المستخدم يكون عامل login ----------
function requireAuth(req, res, next) {
  const header = req.headers.authorization || '';
  const token = header.startsWith('Bearer ') ? header.slice(7) : null;
  if (!token) return res.status(401).json({ error: 'Please log in first' });
  try {
    req.user = jwt.verify(token, JWT_SECRET);
    next();
  } catch {
    res.status(401).json({ error: 'Invalid or expired token' });
  }
}

// بيشغّل مجموعة queries كـ transaction واحدة (يا كلها يا ولا حاجة)
async function withTransaction(fn) {
  const client = await pool.connect();
  try {
    await client.query('BEGIN');
    const result = await fn(client);
    await client.query('COMMIT');
    return result;
  } catch (err) {
    await client.query('ROLLBACK');
    throw err;
  } finally {
    client.release();
  }
}

class HttpError extends Error {
  constructor(status, message) {
    super(message);
    this.status = status;
  }
}

function handleError(res, err) {
  if (err instanceof HttpError) return res.status(err.status).json({ error: err.message });
  console.error(err);
  res.status(500).json({ error: 'Internal server error' });
}

app.get('/health', (req, res) => res.json({ status: 'ok' }));

// ---------- List books (عام - من غير login) ----------
app.get('/api/books', async (req, res) => {
  try {
    const { rows } = await pool.query('SELECT * FROM books ORDER BY id');
    res.json(
      rows.map((b) => ({
        ...b,
        price: Number(b.price),
        available_for_borrowing: b.available_quantity > 0,
      }))
    );
  } catch (err) {
    handleError(res, err);
  }
});

// ---------- Buy ----------
app.post('/api/books/:id/buy', requireAuth, async (req, res) => {
  const bookId = Number(req.params.id);
  try {
    const tx = await withTransaction(async (c) => {
      const { rows } = await c.query('SELECT * FROM books WHERE id = $1 FOR UPDATE', [bookId]);
      const book = rows[0];
      if (!book) throw new HttpError(404, 'Book not found');
      if (book.available_quantity < 1) throw new HttpError(409, 'Out of stock');

      await c.query(
        'UPDATE books SET total_quantity = total_quantity - 1, available_quantity = available_quantity - 1 WHERE id = $1',
        [bookId]
      );
      const t = await c.query(
        `INSERT INTO transactions (user_id, book_id, type, status)
         VALUES ($1, $2, 'purchase', 'completed') RETURNING *`,
        [req.user.id, bookId]
      );
      return t.rows[0];
    });
    res.status(201).json({ message: 'Purchase completed', transaction: tx });
  } catch (err) {
    handleError(res, err);
  }
});

// ---------- Borrow ----------
app.post('/api/books/:id/borrow', requireAuth, async (req, res) => {
  const bookId = Number(req.params.id);
  try {
    const tx = await withTransaction(async (c) => {
      const { rows } = await c.query('SELECT * FROM books WHERE id = $1 FOR UPDATE', [bookId]);
      const book = rows[0];
      if (!book) throw new HttpError(404, 'Book not found');
      if (book.available_quantity < 1) throw new HttpError(409, 'No copies available for borrowing');

      const already = await c.query(
        `SELECT 1 FROM transactions
         WHERE user_id = $1 AND book_id = $2 AND type = 'borrow' AND status = 'borrowed'`,
        [req.user.id, bookId]
      );
      if (already.rowCount > 0) throw new HttpError(409, 'You already borrowed this book');

      await c.query('UPDATE books SET available_quantity = available_quantity - 1 WHERE id = $1', [
        bookId,
      ]);
      const t = await c.query(
        `INSERT INTO transactions (user_id, book_id, type, status, due_date)
         VALUES ($1, $2, 'borrow', 'borrowed', now() + ($3 || ' days')::interval) RETURNING *`,
        [req.user.id, bookId, String(BORROW_DAYS)]
      );
      return t.rows[0];
    });
    res.status(201).json({ message: 'Book borrowed', transaction: tx });
  } catch (err) {
    handleError(res, err);
  }
});

// ---------- Return ----------
app.post('/api/transactions/:id/return', requireAuth, async (req, res) => {
  const txId = Number(req.params.id);
  try {
    const tx = await withTransaction(async (c) => {
      const { rows } = await c.query(
        'SELECT * FROM transactions WHERE id = $1 AND user_id = $2 FOR UPDATE',
        [txId, req.user.id]
      );
      const t = rows[0];
      if (!t) throw new HttpError(404, 'Transaction not found');
      if (t.type !== 'borrow' || t.status !== 'borrowed') {
        throw new HttpError(409, 'This book is not currently borrowed');
      }

      await c.query('UPDATE books SET available_quantity = available_quantity + 1 WHERE id = $1', [
        t.book_id,
      ]);
      const upd = await c.query(
        `UPDATE transactions SET status = 'returned', returned_at = now() WHERE id = $1 RETURNING *`,
        [txId]
      );
      return upd.rows[0];
    });
    res.json({ message: 'Book returned', transaction: tx });
  } catch (err) {
    handleError(res, err);
  }
});

// ---------- My transactions ----------
app.get('/api/transactions/me', requireAuth, async (req, res) => {
  try {
    const { rows } = await pool.query(
      `SELECT t.*, b.title, b.author
       FROM transactions t JOIN books b ON b.id = t.book_id
       WHERE t.user_id = $1 ORDER BY t.created_at DESC`,
      [req.user.id]
    );
    res.json(rows);
  } catch (err) {
    handleError(res, err);
  }
});

app.listen(PORT, () => console.log(`catalog-service listening on ${PORT}`));
