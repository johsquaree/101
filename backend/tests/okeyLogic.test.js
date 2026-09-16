'use strict';

const { evaluateHand } = require('../src/services/okeyLogic');

// Yardımcı: taş oluşturucu
const t = (color, number) => ({ color, number, isOkey: false });
const joker = () => ({ color: 'joker', number: null, isOkey: false });

// ─────────────────────────────────────────────
// SERİ TESTLERİ
// ─────────────────────────────────────────────

describe('Seri (run)', () => {
  test('3 ardışık aynı renk → isFinished', () => {
    const tiles = [t('red', 3), t('red', 4), t('red', 5)];
    const r = evaluateHand(tiles, null);
    expect(r.isFinished).toBe(true);
    expect(r.runs).toHaveLength(1);
    expect(r.sets).toHaveLength(0);
  });

  test('9 ardışık aynı renk → tek uzun seri', () => {
    const tiles = [1,2,3,4,5,6,7,8,9].map(n => t('blue', n));
    const r = evaluateHand(tiles, null);
    expect(r.isFinished).toBe(true);
    expect(r.runs).toHaveLength(1);
  });

  test('Jokerli seri — orta boşluk', () => {
    const tiles = [t('black', 5), joker(), t('black', 7)];
    const r = evaluateHand(tiles, null);
    expect(r.isFinished).toBe(true);
    expect(r.runs).toHaveLength(1);
  });

  test('Jokerli seri — başta joker', () => {
    const tiles = [joker(), t('yellow', 8), t('yellow', 9)];
    const r = evaluateHand(tiles, null);
    expect(r.isFinished).toBe(true);
  });

  test('Jokerli seri — sonda joker', () => {
    const tiles = [t('red', 11), t('red', 12), joker()];
    const r = evaluateHand(tiles, null);
    expect(r.isFinished).toBe(true);
  });

  test('13\'ten wrap olmaz — 12,13,1 geçersiz', () => {
    const tiles = [t('red', 12), t('red', 13), t('red', 1)];
    const r = evaluateHand(tiles, null);
    // 12-13 iki taş, 1 ayrı — bitmiş sayılmaz
    expect(r.isFinished).toBe(false);
  });

  test('Farklı renk taşlar seri oluşturamaz', () => {
    const tiles = [t('red', 5), t('blue', 6), t('black', 7)];
    const r = evaluateHand(tiles, null);
    expect(r.isFinished).toBe(false);
  });
});

// ─────────────────────────────────────────────
// TAKIM TESTLERİ
// ─────────────────────────────────────────────

describe('Takım (set)', () => {
  test('3 farklı renk aynı sayı → isFinished', () => {
    const tiles = [t('red', 7), t('blue', 7), t('black', 7)];
    const r = evaluateHand(tiles, null);
    expect(r.isFinished).toBe(true);
    expect(r.sets).toHaveLength(1);
  });

  test('4 farklı renk aynı sayı → isFinished', () => {
    const tiles = [t('red', 9), t('blue', 9), t('black', 9), t('yellow', 9)];
    const r = evaluateHand(tiles, null);
    expect(r.isFinished).toBe(true);
  });

  test('Aynı renk 3 taş takım oluşturamaz', () => {
    const tiles = [t('red', 5), t('red', 5), t('red', 5)];
    const r = evaluateHand(tiles, null);
    expect(r.isFinished).toBe(false);
  });

  test('Jokerli takım — 2 gerçek + 1 joker', () => {
    const tiles = [t('red', 4), t('blue', 4), joker()];
    const r = evaluateHand(tiles, null);
    expect(r.isFinished).toBe(true);
  });
});

// ─────────────────────────────────────────────
// OKEY TAŞI TESTLERİ
// ─────────────────────────────────────────────

describe('Okey taşı (göstergeden türetilen wild)', () => {
  test('Okey taşı joker gibi çalışır — seri', () => {
    const okeyTile = { color: 'red', number: 6 };
    const tiles = [t('red', 5), t('red', 6), t('red', 7)];
    // red-6 okey taşı sayılır (wild)
    const r = evaluateHand(tiles, okeyTile);
    expect(r.isFinished).toBe(true);
  });

  test('Okey taşı joker gibi çalışır — takım', () => {
    const okeyTile = { color: 'blue', number: 3 };
    const tiles = [t('red', 3), t('blue', 3), t('black', 3)];
    // blue-3 okey taşı, ama 3 farklı renk takımı oluşturuyor
    const r = evaluateHand(tiles, okeyTile);
    expect(r.isFinished).toBe(true);
  });

  test('Gösterge 13 → okey 1', () => {
    // okeyTile = { color: 'red', number: 1 } (gösterge 13 ise)
    const okeyTile = { color: 'red', number: 1 };
    const tiles = [t('blue', 5), t('blue', 6), t('red', 1)];
    // red-1 wild sayılır
    const r = evaluateHand(tiles, okeyTile);
    expect(r.isFinished).toBe(true);
  });
});

// ─────────────────────────────────────────────
// PUAN VE EL AÇMA TESTLERİ
// ─────────────────────────────────────────────

describe('Puan ve canOpen (101+)', () => {
  test('El bitince totalScore = 0', () => {
    const tiles = [t('red', 5), t('red', 6), t('red', 7)];
    const r = evaluateHand(tiles, null);
    expect(r.totalScore).toBe(0);
  });

  test('Kalan taşların puanı doğru hesaplanır', () => {
    // 1 taş tek başına grup oluşturamaz → kalan = 1 puan
    const tiles = [t('red', 1)];
    const r = evaluateHand(tiles, null);
    expect(r.totalScore).toBe(1);
    expect(r.remaining).toHaveLength(1);
  });

  test('canOpen false — gruplar toplamı 88 (101 altında)', () => {
    // 3+4+...+13 = 88, el biter ama açma şartını sağlamaz
    const tiles = [3,4,5,6,7,8,9,10,11,12,13].map(n => t('red', n));
    const r = evaluateHand(tiles, null);
    expect(r.isFinished).toBe(true);
    expect(r.canOpen).toBe(false);
    expect(r.groupsTotal).toBe(88);
  });

  test('canOpen true — 101+ puan gruplar', () => {
    // 8+9+10+11+12+13 = 63 (kırmızı seri)
    // 8+9+10+11+12+13 = 63 (mavi seri) = 126 toplam
    const tiles = [
      ...[8,9,10,11,12,13].map(n => t('red', n)),
      ...[8,9,10,11,12,13].map(n => t('blue', n)),
    ];
    const r = evaluateHand(tiles, null);
    expect(r.isFinished).toBe(true);
    expect(r.canOpen).toBe(true);
    expect(r.groupsTotal).toBeGreaterThanOrEqual(101);
  });

  test('Joker kalan kalınca 101 puan ceza (işlek taş cezası)', () => {
    // 1 joker tek başına → 101 puan ceza
    const tiles = [joker()];
    const r = evaluateHand(tiles, null);
    expect(r.totalScore).toBe(101);
  });
});

// ─────────────────────────────────────────────
// ÇİFT (PAIR) TESTLERİ
// ─────────────────────────────────────────────

describe('Çift (pair)', () => {
  test('8 çift → çiftle bitmiş sayılır', () => {
    // Renkler/sayılar kasıtlı dağınık: yanlışlıkla seri/takım oluşturmasın diye
    const combos = [
      ['red', 1], ['blue', 3], ['black', 5], ['yellow', 7],
      ['red', 9], ['blue', 11], ['black', 13], ['yellow', 2],
    ];
    const tiles = combos.flatMap(([color, n]) => [t(color, n), t(color, n)]);
    const r = evaluateHand(tiles, null);
    expect(r.isFinished).toBe(true);
    expect(r.meldType).toBe('pair');
    expect(r.pairs).toHaveLength(8);
    expect(r.totalScore).toBe(0);
  });

  test('5 çift → canOpen true (101 altında olsa bile)', () => {
    const tiles = [1, 2, 3, 4, 5].flatMap(n => [t('blue', n), t('blue', n)]);
    const r = evaluateHand(tiles, null);
    expect(r.canOpen).toBe(true);
  });

  test('4 çift → canOpen false', () => {
    const tiles = [1, 2, 3, 4].flatMap(n => [t('blue', n), t('blue', n)]);
    const r = evaluateHand(tiles, null);
    expect(r.canOpen).toBe(false);
  });

  test('Jokerli çift — eşi olmayan taş jokerle eşleşir', () => {
    const tiles = [t('red', 9), joker()];
    const r = evaluateHand(tiles, null);
    expect(r.isFinished).toBe(true);
    expect(r.meldType).toBe('pair');
  });

  test('İki joker birbiriyle çift olur', () => {
    const tiles = [joker(), joker()];
    const r = evaluateHand(tiles, null);
    expect(r.isFinished).toBe(true);
    expect(r.meldType).toBe('pair');
  });

  test('Aynı renk aynı sayıdan 2 taş, farklı renk 2 taş → 1 çift + 2 kalan', () => {
    const tiles = [t('red', 4), t('red', 4), t('blue', 7), t('black', 9)];
    const r = evaluateHand(tiles, null);
    expect(r.isFinished).toBe(false);
    expect(r.meldType).toBe('pair');
    expect(r.pairs).toHaveLength(1);
    expect(r.remaining).toHaveLength(2);
  });

  test('Farklı renk aynı sayı çift oluşturmaz (per ile karıştırılmaz)', () => {
    const tiles = [t('red', 4), t('blue', 4)];
    const r = evaluateHand(tiles, null);
    expect(r.pairs).toHaveLength(0);
  });
});

// ─────────────────────────────────────────────
// KARMAŞIK EL TESTLERİ
// ─────────────────────────────────────────────

describe('Karmaşık eller', () => {
  test('Seri + takım karışık el bitebilir', () => {
    const tiles = [
      t('red', 5), t('red', 6), t('red', 7),      // seri
      t('black', 9), t('blue', 9), t('yellow', 9), // takım
    ];
    const r = evaluateHand(tiles, null);
    expect(r.isFinished).toBe(true);
    expect(r.runs).toHaveLength(1);
    expect(r.sets).toHaveLength(1);
  });

  test('Tipik 21 taşlık el — 7 grup çözümü', () => {
    // 3 seri + 4 takım, hiç çakışma yok
    const tiles = [
      t('red', 1),  t('red', 2),  t('red', 3),    // kırmızı seri
      t('blue', 4), t('blue', 5), t('blue', 6),   // mavi seri
      t('black', 7),t('black', 8),t('black', 9),  // siyah seri
      t('red', 10), t('blue', 10),t('black', 10), // 10 takımı
      t('red', 11), t('blue', 11),t('yellow', 11),// 11 takımı
      t('red', 12), t('black', 12),t('yellow', 12),// 12 takımı
      t('red', 13), t('blue', 13),t('yellow', 13),// 13 takımı
    ];
    const r = evaluateHand(tiles, null);
    expect(r.isFinished).toBe(true);
    expect(r.totalScore).toBe(0);
  });

  test('Hiç grup kurulamazsa tüm taşlar remaining\'de', () => {
    // 1 taşlı elden oluşan diziler
    const tiles = [t('red', 1), t('blue', 3), t('black', 8)];
    const r = evaluateHand(tiles, null);
    expect(r.isFinished).toBe(false);
    expect(r.remaining.length).toBeGreaterThan(0);
    expect(r.totalScore).toBe(1 + 3 + 8);
  });
});
