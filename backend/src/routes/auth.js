const express = require('express');
const jwt = require('jsonwebtoken');
const router = express.Router();

const authMiddleware = require('../middleware/auth');
const { getDb } = require('../db');

const JWT_SECRET = process.env.JWT_SECRET || 'dev-secret';

// Apple Sign In
// iOS'tan gelen identityToken decode edilir, Apple user ID alınır.
// Production'da Apple JWKS ile imza doğrulanmalı.
router.post('/apple', (req, res) => {
  const { identityToken } = req.body;
  if (!identityToken) return res.status(400).json({ error: 'identityToken gerekli' });

  const decoded = jwt.decode(identityToken);
  if (!decoded?.sub) return res.status(400).json({ error: 'Geçersiz Apple token' });

  const appleUserId = decoded.sub;
  const email = decoded.email || null;

  const db = getDb();
  db.prepare(`
    INSERT INTO users (id, email) VALUES (?, ?)
    ON CONFLICT(id) DO NOTHING
  `).run(appleUserId, email);

  const token = jwt.sign({ sub: appleUserId }, JWT_SECRET, { expiresIn: '30d' });
  res.json({ token, userId: appleUserId });
});

// Günlük kullanım durumu
router.get('/usage', authMiddleware, (req, res) => {
  const db = getDb();
  const userId = req.userId;
  const today = new Date().toISOString().slice(0, 10);

  const sub = db.prepare(`
    SELECT * FROM purchases
    WHERE user_id = ? AND product_id = 'com.okeyapp.sub.monthly'
      AND expires_at > datetime('now')
    ORDER BY created_at DESC LIMIT 1
  `).get(userId);

  const pack = db.prepare(`
    SELECT COALESCE(SUM(photos_remaining), 0) as total FROM purchases
    WHERE user_id = ? AND product_id IN ('com.okeyapp.pack.small', 'com.okeyapp.pack.large')
      AND photos_remaining > 0
  `).get(userId);

  const log = db.prepare('SELECT count FROM usage_logs WHERE user_id = ? AND used_at = ?').get(userId, today);
  const used = log?.count || 0;

  if (sub) {
    return res.json({ used, limit: 25, remaining: Math.max(0, 25 - used), photosRemaining: 0, subscriptionActive: true, type: 'subscription' });
  }

  if (pack?.total > 0) {
    return res.json({ used: 0, limit: pack.total, remaining: pack.total, photosRemaining: pack.total, subscriptionActive: false, type: 'pack' });
  }

  res.json({ used, limit: 1, remaining: Math.max(0, 1 - used), photosRemaining: 0, subscriptionActive: false, type: 'free' });
});

// Apple in-app satın alma doğrulama
// Production'da Apple StoreKit API ile sunucu taraflı doğrulama yapılmalı.
router.post('/verify-purchase', authMiddleware, (req, res) => {
  const { productId, transactionId } = req.body;
  if (!productId || !transactionId) {
    return res.status(400).json({ error: 'productId ve transactionId gerekli' });
  }

  const db = getDb();
  const userId = req.userId;

  // Aynı transaction tekrar işlenmesin
  const exists = db.prepare('SELECT id FROM purchases WHERE receipt = ?').get(transactionId);
  if (exists) return res.json({ success: true, alreadyProcessed: true });

  let photosToAdd = 0;
  let expiresAt = null;

  if (productId === 'com.okeyapp.pack.small') photosToAdd = 15;
  else if (productId === 'com.okeyapp.pack.large') photosToAdd = 50;
  else if (productId === 'com.okeyapp.sub.monthly') {
    expiresAt = new Date(Date.now() + 30 * 24 * 60 * 60 * 1000).toISOString();
  } else {
    return res.status(400).json({ error: 'Geçersiz ürün ID' });
  }

  db.prepare(`
    INSERT INTO purchases (user_id, product_id, receipt, photos_remaining, expires_at)
    VALUES (?, ?, ?, ?, ?)
  `).run(userId, productId, transactionId, photosToAdd, expiresAt);

  res.json({ success: true, productId });
});

module.exports = router;
