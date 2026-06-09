'use strict';

process.env.JWT_SECRET = 'test-secret';
process.env.DB_PATH = ':memory:';

const request = require('supertest');
const app = require('../src/index');

const t = (color, number) => ({ color, number, isOkey: false });

// ─────────────────────────────────────────────
// HEALTH
// ─────────────────────────────────────────────

describe('GET /health', () => {
  test('200 döner', async () => {
    const res = await request(app).get('/health');
    expect(res.status).toBe(200);
    expect(res.body.status).toBe('ok');
  });
});

// ─────────────────────────────────────────────
// AUTH
// ─────────────────────────────────────────────

describe('POST /api/auth/dev-login', () => {
  test('Token döner', async () => {
    const res = await request(app).post('/api/auth/dev-login');
    expect(res.status).toBe(200);
    expect(res.body.token).toBeDefined();
    expect(res.body.userId).toBe('dev-test-user-001');
  });
});

describe('GET /api/auth/usage', () => {
  test('Token olmadan 401', async () => {
    const res = await request(app).get('/api/auth/usage');
    expect(res.status).toBe(401);
  });

  test('Geçerli token ile kullanım bilgisi döner', async () => {
    const login = await request(app).post('/api/auth/dev-login');
    const token = login.body.token;

    const res = await request(app)
      .get('/api/auth/usage')
      .set('Authorization', `Bearer ${token}`);

    expect(res.status).toBe(200);
    expect(res.body).toHaveProperty('remaining');
    expect(res.body).toHaveProperty('subscriptionActive');
  });
});

// ─────────────────────────────────────────────
// EVALUATE
// ─────────────────────────────────────────────

describe('POST /api/evaluate', () => {
  test('tiles olmadan 400', async () => {
    const res = await request(app).post('/api/evaluate').send({});
    expect(res.status).toBe(400);
  });

  test('Boş dizi 400', async () => {
    const res = await request(app).post('/api/evaluate').send({ tiles: [] });
    expect(res.status).toBe(400);
  });

  test('Basit seri → isFinished true', async () => {
    const res = await request(app)
      .post('/api/evaluate')
      .send({ tiles: [t('red', 5), t('red', 6), t('red', 7)] });

    expect(res.status).toBe(200);
    expect(res.body.isFinished).toBe(true);
    expect(res.body.totalScore).toBe(0);
    expect(res.body.runs).toHaveLength(1);
  });

  test('Basit takım → isFinished true', async () => {
    const res = await request(app)
      .post('/api/evaluate')
      .send({ tiles: [t('red', 9), t('blue', 9), t('black', 9)] });

    expect(res.status).toBe(200);
    expect(res.body.isFinished).toBe(true);
    expect(res.body.sets).toHaveLength(1);
  });

  test('Grup kurulamayan el → isFinished false, puan var', async () => {
    const res = await request(app)
      .post('/api/evaluate')
      .send({ tiles: [t('red', 1), t('blue', 5), t('black', 13)] });

    expect(res.status).toBe(200);
    expect(res.body.isFinished).toBe(false);
    expect(res.body.totalScore).toBeGreaterThan(0);
  });

  test('okeyTile ile değerlendirme', async () => {
    const res = await request(app)
      .post('/api/evaluate')
      .send({
        tiles: [t('red', 5), t('red', 6), t('red', 7)],
        okeyTile: { color: 'blue', number: 3 },
      });

    expect(res.status).toBe(200);
    expect(res.body.isFinished).toBe(true);
  });

  test('canOpen — 101+ puan gruplar', async () => {
    const tiles = [
      ...[8,9,10,11,12,13].map(n => t('red', n)),
      ...[8,9,10,11,12,13].map(n => t('blue', n)),
    ];
    const res = await request(app).post('/api/evaluate').send({ tiles });
    expect(res.status).toBe(200);
    expect(res.body.canOpen).toBe(true);
    expect(res.body.groupsTotal).toBeGreaterThanOrEqual(101);
  });

  test('response şeması doğru', async () => {
    const res = await request(app)
      .post('/api/evaluate')
      .send({ tiles: [t('red', 1), t('red', 2), t('red', 3)] });

    const body = res.body;
    expect(body).toHaveProperty('isFinished');
    expect(body).toHaveProperty('canOpen');
    expect(body).toHaveProperty('totalScore');
    expect(body).toHaveProperty('groupsTotal');
    expect(body).toHaveProperty('runs');
    expect(body).toHaveProperty('sets');
    expect(body).toHaveProperty('remaining');
    expect(body).toHaveProperty('message');
  });
});
