'use strict';

// Kullanıcı düzeltmelerini "gerçek doğru cevap" (ground truth) olarak kullanıp
// mevcut visionService.recognizeTiles() promptunu bu verilerle yeniden test eder.
// Kullanım: node scripts/evalAccuracy.js [--limit 50]

require('dotenv').config();
const path = require('path');
const fs = require('fs');
const { DatabaseSync } = require('node:sqlite');
const { recognizeTiles } = require('../src/services/visionService');

const MIME_BY_EXT = { jpg: 'image/jpeg', jpeg: 'image/jpeg', png: 'image/png', webp: 'image/webp', heic: 'image/heic' };

function parseArgs(argv) {
  const limitIdx = argv.indexOf('--limit');
  const limit = limitIdx !== -1 ? parseInt(argv[limitIdx + 1], 10) : Infinity;
  return { limit };
}

// Beklenen (kullanıcı düzeltmesi) taş listesiyle tahmin edilen listeyi
// multiset olarak eşleştirir; eşleşmeyenler için basit bir hata sınıflandırması yapar.
function diffTiles(expected, predicted) {
  const predPool = [...predicted];
  let exactMatches = 0;
  const misses = [];

  for (const exp of expected) {
    const idx = predPool.findIndex(p => p.color === exp.color && p.number === exp.number);
    if (idx !== -1) {
      exactMatches++;
      predPool.splice(idx, 1);
    } else {
      misses.push(exp);
    }
  }

  const extras = predPool;
  const mistakes = [];

  for (const miss of misses) {
    const colorConfusionIdx = extras.findIndex(e => e.number === miss.number && e.color !== miss.color);
    const numberConfusionIdx = extras.findIndex(e => e.color === miss.color && e.number !== miss.number);

    if (colorConfusionIdx !== -1) {
      const got = extras.splice(colorConfusionIdx, 1)[0];
      mistakes.push({ type: 'renk-karisikligi', expected: miss, got });
    } else if (numberConfusionIdx !== -1) {
      const got = extras.splice(numberConfusionIdx, 1)[0];
      mistakes.push({ type: 'sayi-karisikligi', expected: miss, got });
    } else {
      mistakes.push({ type: 'kayip-tas', expected: miss, got: null });
    }
  }

  for (const extra of extras) {
    mistakes.push({ type: 'fazla-tas', expected: null, got: extra });
  }

  return { exactMatches, mistakes };
}

function tileLabel(t) {
  if (!t) return '-';
  return t.color === 'joker' ? 'joker' : `${t.color}-${t.number}`;
}

async function main() {
  const { limit } = parseArgs(process.argv.slice(2));

  const dbPath = process.env.DB_PATH || '/app/database/okey.db';
  if (!fs.existsSync(dbPath)) {
    console.error(`DB bulunamadı: ${dbPath}`);
    process.exit(1);
  }
  const db = new DatabaseSync(dbPath, { readOnly: true });

  const rows = db.prepare(`
    SELECT id, image_path, recognized_tiles, corrected_tiles
    FROM photo_archive
    WHERE corrected_tiles IS NOT NULL AND image_path IS NOT NULL
    ORDER BY id DESC
    LIMIT ?
  `).all(Number.isFinite(limit) ? limit : -1);

  if (rows.length === 0) {
    console.log('Değerlendirilecek düzeltilmiş kayıt yok (photo_archive.corrected_tiles boş).');
    return;
  }

  console.log(`${rows.length} düzeltilmiş fotoğraf üzerinde eval çalıştırılıyor...\n`);

  let totalExpected = 0;
  let totalExact = 0;
  const mistakesByType = {};
  const skipped = [];

  for (const row of rows) {
    if (!fs.existsSync(row.image_path)) {
      skipped.push({ id: row.id, reason: 'görsel dosyası yok: ' + row.image_path });
      continue;
    }

    const ext = path.extname(row.image_path).slice(1).toLowerCase();
    const mimeType = MIME_BY_EXT[ext] || 'image/jpeg';
    const imageBase64 = fs.readFileSync(row.image_path).toString('base64');

    let predicted;
    try {
      predicted = await recognizeTiles(imageBase64, mimeType);
    } catch (err) {
      skipped.push({ id: row.id, reason: 'AI hatası: ' + err.message });
      continue;
    }

    const expected = JSON.parse(row.corrected_tiles);
    const { exactMatches, mistakes } = diffTiles(expected, predicted);

    totalExpected += expected.length;
    totalExact += exactMatches;

    for (const m of mistakes) {
      mistakesByType[m.type] = (mistakesByType[m.type] || 0) + 1;
    }

    if (mistakes.length > 0) {
      console.log(`#${row.id} — ${exactMatches}/${expected.length} doğru`);
      for (const m of mistakes) {
        console.log(`   ${m.type}: beklenen=${tileLabel(m.expected)} tahmin=${tileLabel(m.got)}`);
      }
    }
  }

  const accuracy = totalExpected > 0 ? ((totalExact / totalExpected) * 100).toFixed(1) : '0.0';

  console.log('\n──── Özet ────');
  console.log(`Doğru tanınan taş: ${totalExact}/${totalExpected} (%${accuracy})`);
  console.log('Hata dağılımı:', mistakesByType);
  if (skipped.length > 0) {
    console.log(`Atlanan kayıt: ${skipped.length}`);
    skipped.forEach(s => console.log(`   #${s.id}: ${s.reason}`));
  }
}

main().catch(err => {
  console.error(err);
  process.exit(1);
});
