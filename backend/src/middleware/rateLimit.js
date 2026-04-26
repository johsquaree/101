const { getDb } = require('../db');

function rateLimitMiddleware(req, res, next) {
  const db = getDb();
  const userId = req.userId;
  const today = new Date().toISOString().slice(0, 10);

  // Kullanıcı yoksa oluştur (deploy sonrası DB sıfırlanınca token geçersiz kalmasın)
  db.prepare(`INSERT INTO users (id, email) VALUES (?, NULL) ON CONFLICT(id) DO NOTHING`).run(userId);

  // Aktif abonelik kontrolü (25/gün)
  const sub = db.prepare(`
    SELECT id FROM purchases
    WHERE user_id = ? AND product_id = 'com.okeyapp.sub.monthly'
      AND expires_at > datetime('now')
    ORDER BY created_at DESC LIMIT 1
  `).get(userId);

  if (sub) {
    const log = ensureLog(db, userId, today);
    if (log.count >= 25) {
      return res.status(429).json({ error: 'Günlük limit doldu', used: log.count, limit: 25 });
    }
    incrementLog(db, userId, today);
    req.usageInfo = { type: 'subscription', used: log.count + 1, limit: 25 };
    return next();
  }

  // Paket kontrolü (her kullanım 1 hak düşer)
  const pack = db.prepare(`
    SELECT id, photos_remaining FROM purchases
    WHERE user_id = ? AND product_id IN ('com.okeyapp.pack.small', 'com.okeyapp.pack.large')
      AND photos_remaining > 0
    ORDER BY created_at ASC LIMIT 1
  `).get(userId);

  if (pack) {
    db.prepare('UPDATE purchases SET photos_remaining = photos_remaining - 1 WHERE id = ?').run(pack.id);
    req.usageInfo = { type: 'pack', remaining: pack.photos_remaining - 1 };
    return next();
  }

  // Ücretsiz: günde 1
  const log = ensureLog(db, userId, today);
  if (log.count >= 1) {
    return res.status(429).json({ error: 'Günlük ücretsiz hakkınız doldu', used: log.count, limit: 1 });
  }
  incrementLog(db, userId, today);
  req.usageInfo = { type: 'free', used: log.count + 1, limit: 1 };
  next();
}

function ensureUser(db, userId) {
  db.prepare(`INSERT INTO users (id, email) VALUES (?, NULL) ON CONFLICT(id) DO NOTHING`).run(userId);
}

function ensureLog(db, userId, date) {
  ensureUser(db, userId);
  db.prepare(`
    INSERT INTO usage_logs (user_id, used_at, count) VALUES (?, ?, 0)
    ON CONFLICT(user_id, used_at) DO NOTHING
  `).run(userId, date);
  return db.prepare('SELECT count FROM usage_logs WHERE user_id = ? AND used_at = ?').get(userId, date);
}

function incrementLog(db, userId, date) {
  db.prepare('UPDATE usage_logs SET count = count + 1 WHERE user_id = ? AND used_at = ?').run(userId, date);
}

module.exports = rateLimitMiddleware;
