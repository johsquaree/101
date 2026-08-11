const Anthropic = require('@anthropic-ai/sdk');

const client = new Anthropic({ apiKey: process.env.ANTHROPIC_API_KEY });

const VALID_COLORS = ['red', 'yellow', 'blue', 'black', 'joker'];

const PROMPT = `Bu fotoğrafta Türk Okey (101) taşlarını say ve tanı.

RENK TANIMA (en sık hata buradan çıkar, dikkatli ol):
- Zeminin rengi değil, ÜZERİNDEKİ SAYININ rengi taşın rengini belirler
- Mavi sayı = "blue", Kırmızı sayı = "red", Siyah sayı = "black", Sarı/turuncu sayı = "yellow"
- Her taşı tanımadan önce sadece o taşın üzerindeki rakamın rengine odaklan, komşu taşların rengine veya genel ışığa/gölgeye kanma
- Aynı sayıyı taşıyan farklı taşları birbirine karıştırma; her taşı ayrı ayrı, sırayla değerlendir

SAYI TANIMA:
- Sayılar 1 ile 13 arasındadır, iki haneli sayıları (10, 11, 12, 13) tek haneli okuma hatasına karşı dikkatli ol
- Taşların altındaki küçük kalp (♥) işaretini görmezden gel, bu sayı değildir

JOKER TANIMA (çok önemli):
Şu iki tür taş jokerdir, color="joker" number=null olarak işaretle:
1. TAMAMEN BOŞ BEYAZ TAŞ: Üzerinde hiç sayı yok, sadece düz beyaz/krem yüzey
2. SEMBOLLÜ TAŞ: Sayı yerine daire, yuvarlak, karalama veya özel işaret var (sayı değil)

NOT: Gösterge taşı (okeyin bir önceki taşı) elde normal görünür, sayısı olan sıradan bir taştır — onu normal taş olarak tanı, joker değil.
NOT: Okey taşı da elde normal görünür — sayısı olan sıradan bir taş gibi görünür, joker değil. Kullanıcı hangisinin okey olduğunu ayrıca belirtecek.

KURALLAR:
- Fotoğraftaki her taşı tek tek listele, hiçbirini atlama, hiçbirini uydurma
- report_tiles tool'unu kullanarak sonucu bildir`;

const TOOL = {
  name: 'report_tiles',
  description: 'Fotoğrafta tanınan Okey taşlarının listesini bildirir.',
  input_schema: {
    type: 'object',
    properties: {
      tiles: {
        type: 'array',
        items: {
          type: 'object',
          properties: {
            color: { type: 'string', enum: VALID_COLORS },
            number: { type: ['integer', 'null'], minimum: 1, maximum: 13 },
          },
          required: ['color', 'number'],
        },
      },
    },
    required: ['tiles'],
  },
};

async function recognizeTiles(imageBase64, mimeType = 'image/jpeg') {
  const response = await client.messages.create({
    model: 'claude-haiku-4-5-20251001',
    max_tokens: 1536,
    tools: [TOOL],
    tool_choice: { type: 'tool', name: 'report_tiles' },
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

  const toolUse = response.content.find(b => b.type === 'tool_use' && b.name === 'report_tiles');
  if (!toolUse || !Array.isArray(toolUse.input?.tiles)) {
    throw new Error('AI geçerli taş listesi döndürmedi');
  }

  return toolUse.input.tiles
    .filter(
      t =>
        VALID_COLORS.includes(t.color) &&
        (t.color === 'joker'
          ? t.number === null || t.number === undefined
          : Number.isInteger(t.number) && t.number >= 1 && t.number <= 13)
    )
    .map(t => ({
      color: t.color,
      number: t.color === 'joker' ? null : t.number,
      isOkey: false,
    }));
}

module.exports = { recognizeTiles };
