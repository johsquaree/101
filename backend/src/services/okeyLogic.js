'use strict';

const COLORS = ['red', 'yellow', 'blue', 'black'];

// Bir oyuncu elini açmadan biten oyunda, işlenmemiş her joker/okey taşı için
// kaybeden 101 puan ceza yer (bkz. 101 Okey kuralları — işlek taş cezası).
const UNUSED_WILD_PENALTY = 101;

// Açmak için gereken minimum: per/seri toplamı ya da 5 çift.
const MIN_PAIRS_TO_OPEN = 5;

/**
 * Ana değerlendirme fonksiyonu.
 * tiles: [{ color, number, isOkey }]
 * okeyTile: { color, number } | null  — gösterge taşının bir sonraki taşı
 *
 * Döndürür:
 * { tiles, totalScore, canOpen, isFinished, meldType, runs, sets, pairs, remaining, groupsTotal, message }
 *
 * meldType: 'run-set' | 'pair' — el hangi yolla değerlendirildi.
 * Kurallara göre çift ile per/seri aynı elde karıştırılamaz, bu yüzden
 * iki yaklaşım ayrı ayrı hesaplanır ve oyuncu için daha avantajlı olan raporlanır.
 */
function evaluateHand(tiles, okeyTile) {
  const isWild = t =>
    t.color === 'joker' ||
    (okeyTile && t.color === okeyTile.color && t.number === okeyTile.number);

  const wilds = tiles.filter(isWild);
  const normals = tiles.filter(t => !isWild(t));

  const sorted = [...normals].sort((a, b) => {
    const cc = a.color.localeCompare(b.color);
    return cc !== 0 ? cc : a.number - b.number;
  });

  const pairResult = evaluatePairs(tiles, isWild);
  const pairsFinished = pairResult.remaining.length === 0 && pairResult.pairs.length > 0;
  const pairsCanOpen = pairResult.pairs.length >= MIN_PAIRS_TO_OPEN;

  // Tüm taşları yerleştirmeye çalış (el bitirme kontrolü) — per/seri yolu
  const solution = solveAll(sorted, wilds.length);

  if (solution !== null) {
    const runs = solution.filter(g => g.type === 'run').map(g => g.tiles);
    const sets = solution.filter(g => g.type === 'set').map(g => g.tiles);
    const groupsTotal = calcGroupsTotal(solution);
    return {
      tiles,
      totalScore: 0,
      canOpen: groupsTotal >= 101 || pairsCanOpen,
      isFinished: true,
      meldType: 'run-set',
      runs,
      sets,
      pairs: [],
      remaining: [],
      groupsTotal,
      message: 'El tamam! Açabilirsiniz.',
    };
  }

  if (pairsFinished) {
    return {
      tiles,
      totalScore: 0,
      canOpen: true,
      isFinished: true,
      meldType: 'pair',
      runs: [],
      sets: [],
      pairs: pairResult.pairs,
      remaining: [],
      groupsTotal: 0,
      message: `El çiftle tamam! (${pairResult.pairs.length} çift) Açabilirsiniz.`,
    };
  }

  // En iyi kısmi yerleştirme — per/seri yolu
  const { groups, remaining, wildsLeft } = bestPartial(sorted, wilds.length);
  const groupsTotal = calcGroupsTotal(groups);
  const unusedWilds = wilds.slice(0, wildsLeft);
  const remainingAll = [...remaining, ...unusedWilds];
  const runSetScore =
    remaining.reduce((s, t) => s + (t.number || 0), 0) + wildsLeft * UNUSED_WILD_PENALTY;

  // En iyi kısmi yerleştirme — çift yolu
  const pairScore = pairResult.remaining.reduce(
    (s, t) => s + (isWild(t) ? UNUSED_WILD_PENALTY : t.number || 0),
    0
  );

  // Çift yolu daha az puan bırakıyorsa (oyuncu için daha avantajlıysa) onu raporla.
  if (pairResult.pairs.length > 0 && pairScore <= runSetScore) {
    return {
      tiles,
      totalScore: pairScore,
      canOpen: pairsCanOpen || groupsTotal >= 101,
      isFinished: false,
      meldType: 'pair',
      runs: [],
      sets: [],
      pairs: pairResult.pairs,
      remaining: pairResult.remaining,
      groupsTotal: 0,
      message: `${pairScore} puan kaldı (${pairResult.pairs.length} çift)`,
    };
  }

  return {
    tiles,
    totalScore: runSetScore,
    canOpen: groupsTotal >= 101 || pairsCanOpen,
    isFinished: false,
    meldType: 'run-set',
    runs: groups.filter(g => g.type === 'run').map(g => g.tiles),
    sets: groups.filter(g => g.type === 'set').map(g => g.tiles),
    pairs: [],
    remaining: remainingAll,
    groupsTotal,
    message: `${runSetScore} puan kaldı`,
  };
}

/**
 * Taşları çift (aynı renk + aynı sayı ikilisi) olarak eşleştirmeye çalışır.
 * Joker/okey taşı, eşi bulunamayan tek taşların ya da başka bir jokerin
 * eşi olabilir. Açgözlü eşleştirme yeterli: her joker en fazla bir çifti
 * tamamlayabileceğinden, önce tek kalan gerçek taşları kurtarmak, jokerleri
 * kendi aralarında eşlemekten her zaman en az o kadar iyidir.
 */
function evaluatePairs(tiles, isWild) {
  const wildTiles = tiles.filter(isWild);
  const normals = tiles.filter(t => !isWild(t));

  const groups = new Map();
  for (const t of normals) {
    const key = `${t.color}-${t.number}`;
    if (!groups.has(key)) groups.set(key, []);
    groups.get(key).push(t);
  }

  const pairs = [];
  const singles = [];
  for (const group of groups.values()) {
    let i = 0;
    for (; i + 1 < group.length; i += 2) pairs.push([group[i], group[i + 1]]);
    if (i < group.length) singles.push(group[i]);
  }

  const wildsPool = [...wildTiles];
  for (const single of singles) {
    if (wildsPool.length === 0) break;
    pairs.push([single, wildsPool.shift()]);
  }
  const pairedSingleCount = Math.min(singles.length, wildTiles.length);
  const unpairedSingles = singles.slice(pairedSingleCount);

  while (wildsPool.length >= 2) {
    pairs.push([wildsPool.shift(), wildsPool.shift()]);
  }

  return { pairs, remaining: [...unpairedSingles, ...wildsPool] };
}

/** Tüm taşları geçerli gruplara yerleştirmeye çalışır. Başarılıysa group dizisi, değilse null. */
function solveAll(sorted, wilds) {
  if (sorted.length === 0 && wilds === 0) return [];
  if (sorted.length === 0) return null; // kullanılmayan joker = el bitmez
  if (sorted.length + wilds < 3) return null;

  const [first, ...rest] = sorted;
  const maxLen = Math.min(13, sorted.length + wilds);

  // Seri dene (uzundan kısaya — daha iyi puan için)
  for (let len = maxLen; len >= 3; len--) {
    const run = tryRun(first, rest, wilds, len);
    if (run) {
      const sub = solveAll(run.remaining, run.wilds);
      if (sub !== null) return [{ type: 'run', tiles: run.used }, ...sub];
    }
  }

  // Takım dene
  for (let len = Math.min(4, sorted.length + wilds); len >= 3; len--) {
    const set = trySet(first, rest, wilds, len);
    if (set) {
      const sub = solveAll(set.remaining, set.wilds);
      if (sub !== null) return [{ type: 'set', tiles: set.used }, ...sub];
    }
  }

  return null;
}

/**
 * 'first' taşını içeren, verilen uzunlukta bir seri kurmaya çalışır.
 * first taşı serinin herhangi bir pozisyonunda olabilir (joker offset ile).
 */
function tryRun(first, rest, wilds, len) {
  const color = first.color;

  for (let offset = 0; offset < len; offset++) {
    const startNum = first.number - offset;
    if (startNum < 1 || startNum + len - 1 > 13) continue;

    const used = [];
    const remaining = [...rest];
    let wildLeft = wilds;
    let firstPlaced = false;
    let valid = true;

    for (let i = 0; i < len; i++) {
      const need = startNum + i;

      if (!firstPlaced && need === first.number) {
        used.push(first);
        firstPlaced = true;
        continue;
      }

      const idx = remaining.findIndex(t => t.color === color && t.number === need);
      if (idx !== -1) {
        used.push(remaining.splice(idx, 1)[0]);
      } else if (wildLeft > 0) {
        used.push({ color, number: need, isWild: true });
        wildLeft--;
      } else {
        valid = false;
        break;
      }
    }

    if (valid && firstPlaced) return { used, remaining, wilds: wildLeft };
  }

  return null;
}

/**
 * 'first' taşını içeren, verilen uzunlukta bir takım kurmaya çalışır.
 * Takım: aynı sayı, farklı renkler (max 4).
 */
function trySet(first, rest, wilds, len) {
  if (!first.number) return null;

  const num = first.number;
  const usedColors = new Set([first.color]);
  const used = [first];
  const remaining = [...rest];
  let wildLeft = wilds;

  for (let i = 1; i < len; i++) {
    const available = COLORS.filter(c => !usedColors.has(c));
    let found = false;

    for (const col of available) {
      const idx = remaining.findIndex(t => t.color === col && t.number === num);
      if (idx !== -1) {
        usedColors.add(col);
        used.push(remaining.splice(idx, 1)[0]);
        found = true;
        break;
      }
    }

    if (!found) {
      if (wildLeft > 0) {
        const placeholder = available[0] || 'wild';
        usedColors.add(placeholder);
        used.push({ color: placeholder, number: num, isWild: true });
        wildLeft--;
      } else {
        return null;
      }
    }
  }

  return { used, remaining, wilds: wildLeft };
}

/** Olabildiğince çok taşı gruplayan açgözlü algoritma. */
function bestPartial(sorted, wilds) {
  let remaining = [...sorted];
  let wildLeft = wilds;
  const groups = [];

  let improved = true;
  while (improved) {
    improved = false;

    for (let i = 0; i < remaining.length; i++) {
      const tile = remaining[i];
      const rest = [...remaining.slice(0, i), ...remaining.slice(i + 1)];

      // Seri dene (uzundan kısaya)
      for (let len = Math.min(13, remaining.length + wildLeft); len >= 3; len--) {
        const run = tryRun(tile, rest, wildLeft, len);
        if (run) {
          groups.push({ type: 'run', tiles: run.used });
          remaining = run.remaining;
          wildLeft = run.wilds;
          improved = true;
          break;
        }
      }
      if (improved) break;

      // Takım dene
      for (let len = Math.min(4, remaining.length + wildLeft); len >= 3; len--) {
        const set = trySet(tile, rest, wildLeft, len);
        if (set) {
          groups.push({ type: 'set', tiles: set.used });
          remaining = set.remaining;
          wildLeft = set.wilds;
          improved = true;
          break;
        }
      }
      if (improved) break;
    }
  }

  return { groups, remaining, wildsLeft: wildLeft };
}

function calcGroupsTotal(groups) {
  return groups.reduce((sum, g) => {
    const tiles = Array.isArray(g.tiles) ? g.tiles : [];
    return sum + tiles.reduce((s, t) => s + (t.isWild ? t.number || 0 : t.number || 0), 0);
  }, 0);
}

module.exports = { evaluateHand };
