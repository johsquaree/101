const Anthropic = require('@anthropic-ai/sdk');

const client = new Anthropic({ apiKey: process.env.ANTHROPIC_API_KEY });

const PROMPT = `Bu fotoğrafta Türk Okey taşlarını tanı.

Okey taşları:
- Renkler: red (kırmızı), yellow (sarı), blue (mavi), black (siyah)
- Sayılar: 1-13
- Özel: joker taşlar (sahte joker, genellikle yıldızlı veya farklı işaretli)

Gördüğün her taş için JSON döndür. Sadece JSON array yaz, başka hiçbir şey yazma.

Format: [{"color":"red|yellow|blue|black|joker","number":1-13,"isOkey":false}]

Kurallar:
- Joker taşların number değeri null olur
- isOkey alanı her zaman false (bu backend tarafından belirlenir)
- Belirsiz taşlarda en iyi tahmini yap
- Sadece JSON array döndür, açıklama yazma`;

async function recognizeTiles(imageBase64, mimeType = 'image/jpeg') {
  const response = await client.messages.create({
    model: 'claude-haiku-4-5-20251001',
    max_tokens: 1024,
    messages: [
      {
        role: 'user',
        content: [
          {
            type: 'image',
            source: { type: 'base64', media_type: mimeType, data: imageBase64 },
          },
          { type: 'text', text: PROMPT },
        ],
      },
    ],
  });

  const text = response.content[0].text.trim();
  const match = text.match(/\[[\s\S]*\]/);
  if (!match) throw new Error('AI geçerli JSON döndürmedi');

  const tiles = JSON.parse(match[0]);

  // Basit doğrulama
  return tiles.filter(
    t =>
      ['red', 'yellow', 'blue', 'black', 'joker'].includes(t.color) &&
      (t.color === 'joker' ? t.number === null || t.number === undefined : t.number >= 1 && t.number <= 13)
  ).map(t => ({
    color: t.color,
    number: t.color === 'joker' ? null : t.number,
    isOkey: false,
  }));
}

module.exports = { recognizeTiles };
