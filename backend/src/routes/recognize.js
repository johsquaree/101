const express = require('express');
const multer = require('multer');
const router = express.Router();

const authMiddleware = require('../middleware/auth');
const rateLimitMiddleware = require('../middleware/rateLimit');
const { recognizeTiles } = require('../services/visionService');
const { getDb } = require('../db');

const upload = multer({
  storage: multer.memoryStorage(),
  limits: { fileSize: 10 * 1024 * 1024 },
  fileFilter: (_, file, cb) => {
    if (file.mimetype.startsWith('image/')) cb(null, true);
    else cb(new Error('Sadece görsel dosyaları kabul edilir'));
  },
});

// Fotoğraf gönder → taşları tanı
router.post('/', authMiddleware, rateLimitMiddleware, upload.single('image'), async (req, res) => {
  if (!req.file) return res.status(400).json({ error: 'Görsel gerekli' });

  try {
    const imageBase64 = req.file.buffer.toString('base64');
    const mimeType = req.file.mimetype;

    const tiles = await recognizeTiles(imageBase64, mimeType);

    const db = getDb();
    const result = db.prepare(`
      INSERT INTO photo_archive (user_id, recognized_tiles) VALUES (?, ?)
    `).run(req.userId, JSON.stringify(tiles));

    res.json({ tiles, archiveId: result.lastInsertRowid, usage: req.usageInfo });
  } catch (err) {
    console.error('Recognize error:', err);
    res.status(500).json({ error: 'Taş tanıma başarısız: ' + err.message });
  }
});

// Kullanıcı düzeltmesini kaydet (AI eğitimi için)
router.post('/correct', authMiddleware, (req, res) => {
  const { archiveId, correctedTiles } = req.body;
  if (!archiveId || !correctedTiles) {
    return res.status(400).json({ error: 'archiveId ve correctedTiles gerekli' });
  }

  const db = getDb();
  db.prepare(`
    UPDATE photo_archive SET corrected_tiles = ? WHERE id = ? AND user_id = ?
  `).run(JSON.stringify(correctedTiles), archiveId, req.userId);

  res.json({ success: true });
});

module.exports = router;
