-- Kullanıcılar
CREATE TABLE IF NOT EXISTS users (
  id TEXT PRIMARY KEY,           -- Apple user ID
  email TEXT,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- Satın almalar
CREATE TABLE IF NOT EXISTS purchases (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  user_id TEXT NOT NULL,
  product_id TEXT NOT NULL,      -- 'small_pack', 'large_pack', 'monthly_sub'
  receipt TEXT,
  photos_remaining INTEGER,      -- paketler için kalan hak
  expires_at DATETIME,           -- abonelik için bitiş tarihi
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id)
);

-- Günlük kullanım logu
CREATE TABLE IF NOT EXISTS usage_logs (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  user_id TEXT NOT NULL,
  used_at DATE NOT NULL,
  count INTEGER DEFAULT 0,
  UNIQUE(user_id, used_at),
  FOREIGN KEY (user_id) REFERENCES users(id)
);

-- Fotoğraf arşivi (ileride AI eğitimi için)
CREATE TABLE IF NOT EXISTS photo_archive (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  user_id TEXT NOT NULL,
  image_path TEXT,
  recognized_tiles TEXT,         -- JSON: AI'ın ne gördüğü
  corrected_tiles TEXT,          -- JSON: kullanıcının düzeltmesi (ileride)
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);
