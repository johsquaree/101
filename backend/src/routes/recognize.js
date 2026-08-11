const express = require('express');
const multer = require('multer');
const path = require('path');
const fs = require('fs');
const router = express.Router();

const authMiddleware = require('../middleware/auth');
const rateLimitMiddleware = require('../middleware/rateLimit');
const { recognizeTiles } = require('../services/visionService');
const { getDb, getImagesDir } = require('../db');

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

    const archiveId = result.lastInsertRowid;
    const imagePath = saveArchiveImage(archiveId, req.file.buffer, mimeType);
    db.prepare('UPDATE photo_archive SET image_path = ? WHERE id = ?').run(imagePath, archiveId);

    res.json({ tiles, archiveId, usage: req.usageInfo });
  } catch (err) {
    console.error('Recognize error:', err);
    res.status(500).json({ error: 'Taş tanıma başarısız: ' + err.message });
  }
});

const EXT_BY_MIME = { 'image/jpeg': 'jpg', 'image/png': 'png', 'image/webp': 'webp', 'image/heic': 'heic' };

// Eval/regresyon testleri fotoğrafı yeniden AI'a gönderebilsin diye kalıcı diske yazar.
function saveArchiveImage(archiveId, buffer, mimeType) {
  const ext = EXT_BY_MIME[mimeType] || 'jpg';
  const filePath = path.join(getImagesDir(), `${archiveId}.${ext}`);
  fs.writeFileSync(filePath, buffer);
  return filePath;
}

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
