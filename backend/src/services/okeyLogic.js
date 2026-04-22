'use strict';

const COLORS = ['red', 'yellow', 'blue', 'black'];

/**
 * Ana değerlendirme fonksiyonu.
 * tiles: [{ color, number, isOkey }]
 * okeyTile: { color, number } | null  — gösterge taşının bir sonraki taşı
 *
 * Döndürür:
 * { tiles, totalScore, canOpen, isFinished, runs, sets, remaining, groupsTotal, message }
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

  // Tüm taşları yerleştirmeye çalış (el bitirme kontrolü)
  const solution = solveAll(sorted, wilds.length);

  if (solution !== null) {
    const runs = solution.filter(g => g.type === 'run').map(g => g.tiles);
    const sets = solution.filter(g => g.type === 'set').map(g => g.tiles);
    const groupsTotal = calcGroupsTotal(solution);
    return {
      tiles,
      totalScore: 0,
      canOpen: groupsTotal >= 101,
      isFinished: true,
      runs,
      sets,
      remaining: [],
      groupsTotal,
      message: 'El tamam! Açabilirsiniz.',
    };
  }

  // En iyi kısmi yerleştirme
  const { groups, remaining, wildsLeft } = bestPartial(sorted, wilds.length);
  const groupsTotal = calcGroupsTotal(groups);
  const unusedWilds = wilds.slice(0, wildsLeft);
  const remainingAll = [...remaining, ...unusedWilds];
  const score = remaining.reduce((s, t) => s + (t.number || 0), 0) + wildsLeft * 30;

  return {
    tiles,
    totalScore: score,
    canOpen: groupsTotal >= 101,
    isFinished: false,
    runs: groups.filter(g => g.type === 'run').map(g => g.tiles),
    sets: groups.filter(g => g.type === 'set').map(g => g.tiles),
    remaining: remainingAll,
    groupsTotal,
    message: `${score} puan kaldı`,
  };
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
