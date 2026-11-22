-- بيتنفذ مرة واحدة أول ما الـ database تتعمل

CREATE TABLE users (
  id            SERIAL PRIMARY KEY,
  name          VARCHAR(100) NOT NULL,
  email         VARCHAR(255) NOT NULL UNIQUE,
  password_hash VARCHAR(255) NOT NULL,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE books (
  id                 SERIAL PRIMARY KEY,
  title              VARCHAR(255) NOT NULL,
  author             VARCHAR(255) NOT NULL,
  category           VARCHAR(100) NOT NULL,
  cover_image        TEXT,
  price              NUMERIC(8,2) NOT NULL CHECK (price >= 0),
  total_quantity     INTEGER NOT NULL CHECK (total_quantity >= 0),
  available_quantity INTEGER NOT NULL CHECK (available_quantity >= 0),
  CHECK (available_quantity <= total_quantity)
);

-- كل عملية شراء أو استعارة
CREATE TABLE transactions (
  id          SERIAL PRIMARY KEY,
  user_id     INTEGER NOT NULL REFERENCES users(id),
  book_id     INTEGER NOT NULL REFERENCES books(id),
  type        VARCHAR(10) NOT NULL CHECK (type IN ('purchase', 'borrow')),
  status      VARCHAR(10) NOT NULL CHECK (status IN ('completed', 'borrowed', 'returned')),
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
  due_date    TIMESTAMPTZ,
  returned_at TIMESTAMPTZ
);

CREATE INDEX idx_transactions_user ON transactions(user_id);

INSERT INTO books (title, author, category, cover_image, price, total_quantity, available_quantity) VALUES
('The Great Gatsby',       'F. Scott Fitzgerald', 'Classic',   'https://covers.openlibrary.org/b/isbn/9780743273565-M.jpg', 12.99, 5, 5),
('1984',                   'George Orwell',       'Dystopian', 'https://covers.openlibrary.org/b/isbn/9780451524935-M.jpg',  9.99, 4, 4),
('To Kill a Mockingbird',  'Harper Lee',          'Classic',   'https://covers.openlibrary.org/b/isbn/9780061120084-M.jpg', 11.50, 3, 3),
('Pride and Prejudice',    'Jane Austen',         'Romance',   'https://covers.openlibrary.org/b/isbn/9780141439518-M.jpg',  8.75, 6, 6),
('The Catcher in the Rye', 'J. D. Salinger',      'Fiction',   'https://covers.openlibrary.org/b/isbn/9780316769488-M.jpg', 10.25, 2, 2),
('The Hobbit',             'J. R. R. Tolkien',    'Fantasy',   'https://covers.openlibrary.org/b/isbn/9780547928227-M.jpg', 14.00, 4, 4);
