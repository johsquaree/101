const Anthropic = require('@anthropic-ai/sdk');

const client = new Anthropic({ apiKey: process.env.ANTHROPIC_API_KEY });

const PROMPT = `Bu fotoğrafta Türk Okey (101) taşlarını tanı. Çok dikkatli ol.

TAŞLARIN GÖRÜNÜMÜ:
- Taşlar beyaz/krem zemin üzerine renkli sayılardan oluşur
- Rengi sayının rengi belirler, zemin değil:
  * Mavi sayı = "blue"
  * Kırmızı sayı = "red"
  * Siyah sayı = "black"
  * Sarı/turuncu sayı = "yellow"
- Sayılar 1'den 13'e kadar
- Taşların altında küçük kalp (♥) işareti olabilir, bunu görmezden gel
- Her taşı tek tek say, hiçbirini atlama

JOKER TAŞLAR:
- Sahte jokerler genellikle ters duran, yıldızlı veya farklı desenli taşlardır
- Okey taşı: ters/yan duran veya özel işaretli taş — bunlar joker görevi görür
- Joker taşları {"color":"joker","number":null,"isOkey":false} olarak yaz

KURALLAR:
- Her gördüğün taşı listele, hiç atlama
- Rengi sayı rengine göre belirle, taş zemininin rengine göre değil
- Belirsiz taşlarda en yakın tahmini yap
- Sadece JSON array döndür, başka hiçbir şey yazma

FORMAT: [{"color":"red|yellow|blue|black|joker","number":1-13 veya null,"isOkey":false}]

ÖRNEK: Mavi 7, kırmızı 3, siyah 11, sarı 13, joker taş:
[{"color":"blue","number":7,"isOkey":false},{"color":"red","number":3,"isOkey":false},{"color":"black","number":11,"isOkey":false},{"color":"yellow","number":13,"isOkey":false},{"color":"joker","number":null,"isOkey":false}]`;

async function recognizeTiles(imageBase64, mimeType = 'image/jpeg') {
  const response = await client.messages.create({
    model: 'claude-sonnet-4-6',
    max_tokens: 2048,
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
