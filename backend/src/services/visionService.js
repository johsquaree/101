const Anthropic = require('@anthropic-ai/sdk');

const client = new Anthropic({ apiKey: process.env.ANTHROPIC_API_KEY });

const PROMPT = `Bu fotoğrafta Türk Okey (101) taşlarını say ve tanı.

TAŞLARIN GÖRÜNÜMÜ:
- Taşlar beyaz/krem zemin üzerine renkli sayılardan oluşur
- Rengi sayının rengi belirler, zemin değil:
  * Mavi sayı = "blue"
  * Kırmızı sayı = "red"
  * Siyah sayı = "black"
  * Sarı/turuncu sayı = "yellow"
- Sayılar 1-13 arası
- Taşların altındaki küçük kalp (♥) işaretini görmezden gel

JOKER/OKEY TAŞLARI (ÖNEMLİ):
- Ters duran taş = joker
- Yan yatmış taş = joker
- Baş aşağı duran taş = joker
- Normal taşlardan farklı görünen taş = joker
- Jokerler: {"color":"joker","number":null,"isOkey":false}

KURALLAR:
- Her taşı tek tek listele, hiçbirini atlama
- Sadece JSON array döndür, başka hiçbir şey yazma

FORMAT: [{"color":"red|yellow|blue|black|joker","number":1-13 veya null,"isOkey":false}]`;

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

  return tiles
    .filter(
      t =>
        ['red', 'yellow', 'blue', 'black', 'joker'].includes(t.color) &&
        (t.color === 'joker'
          ? t.number === null || t.number === undefined
          : t.number >= 1 && t.number <= 13)
    )
    .map(t => ({
      color: t.color,
      number: t.color === 'joker' ? null : t.number,
      isOkey: false,
    }));
}

module.exports = { recognizeTiles };
