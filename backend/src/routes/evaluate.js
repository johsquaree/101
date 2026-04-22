const express = require('express');
const router = express.Router();
const { evaluateHand } = require('../services/okeyLogic');

router.post('/', (req, res) => {
  const { tiles, okeyTile } = req.body;

  if (!tiles || !Array.isArray(tiles)) {
    return res.status(400).json({ error: 'tiles dizisi gerekli' });
  }

  if (tiles.length === 0) {
    return res.status(400).json({ error: 'Taş bulunamadı' });
  }

  try {
    const result = evaluateHand(tiles, okeyTile || null);
    res.json(result);
  } catch (err) {
    console.error('Evaluate error:', err);
    res.status(500).json({ error: 'El hesaplama başarısız' });
  }
});

module.exports = router;
