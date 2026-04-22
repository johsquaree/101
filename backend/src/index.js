const express = require('express');
const cors = require('cors');
const helmet = require('helmet');

const recognizeRoutes = require('./routes/recognize');
const evaluateRoutes = require('./routes/evaluate');
const authRoutes = require('./routes/auth');

const app = express();
const PORT = process.env.PORT || 3000;

app.use(helmet());
app.use(cors());
app.use(express.json({ limit: '10mb' }));

// Routes
app.use('/api/recognize', recognizeRoutes);
app.use('/api/evaluate', evaluateRoutes);
app.use('/api/auth', authRoutes);

app.get('/health', (req, res) => res.json({ status: 'ok' }));

app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});

module.exports = app;
