const express = require('express');
const router = express.Router();
// TODO: Apple Sign In doğrulama, JWT üretimi

router.post('/apple', async (req, res) => {
  // Apple identity token alınır, doğrulanır, JWT dönülür
  res.json({ message: 'apple auth endpoint - TODO' });
});

router.get('/usage', async (req, res) => {
  // Kullanıcının günlük kalan hakkı
  res.json({ message: 'usage endpoint - TODO' });
});

router.post('/verify-purchase', async (req, res) => {
  // Apple receipt doğrulama
  res.json({ message: 'verify-purchase endpoint - TODO' });
});

module.exports = router;
