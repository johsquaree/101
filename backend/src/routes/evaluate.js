const express = require('express');
const router = express.Router();
// TODO: Okey oyun mantığı — idk/services/game-logic/src/index.js referans al

router.post('/', async (req, res) => {
  // Taş listesi alınır, puan hesaplanır, sonuç dönülür
  res.json({ message: 'evaluate endpoint - TODO' });
});

module.exports = router;
