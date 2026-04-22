const jwt = require('jsonwebtoken');

function authMiddleware(req, res, next) {
  const header = req.headers.authorization;
  if (!header || !header.startsWith('Bearer ')) {
    return res.status(401).json({ error: 'Token gerekli' });
  }

  const token = header.slice(7);
  try {
    const payload = jwt.verify(token, process.env.JWT_SECRET || 'dev-secret');
    req.userId = payload.sub;
    next();
  } catch {
    res.status(401).json({ error: 'Geçersiz token' });
  }
}

module.exports = authMiddleware;
