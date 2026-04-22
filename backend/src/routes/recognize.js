const express = require('express');
const router = express.Router();
// TODO: Claude Haiku veya Gemini Flash Vision entegrasyonu

router.post('/', async (req, res) => {
  // Fotoğraf alınır, AI'ya gönderilir, taşlar JSON dönülür
  res.json({ message: 'recognize endpoint - TODO' });
});

module.exports = router;
