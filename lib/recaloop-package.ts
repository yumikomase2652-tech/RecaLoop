import { getLocalMedia, saveLocalMedia } from "./local-media";
import type { WordCard, WordList } from "./types";

type ZipFile = { path: string; data: Uint8Array };
const encoder = new TextEncoder();
const decoder = new TextDecoder();

function u16(value: number) {
  const out = new Uint8Array(2);
  new DataView(out.buffer).setUint16(0, value, true);
  return out;
}

function u32(value: number) {
  const out = new Uint8Array(4);
  new DataView(out.buffer).setUint32(0, value, true);
  return out;
}

function concat(parts: Uint8Array[]) {
  const size = parts.reduce((sum, part) => sum + part.length, 0);
  const out = new Uint8Array(size);
  let offset = 0;
  parts.forEach(part => {
    out.set(part, offset);
    offset += part.length;
  });
  return out;
}

const crcTable = Array.from({ length: 256 }, (_, index) => {
  let c = index;
  for (let k = 0; k < 8; k++) c = c & 1 ? 0xedb88320 ^ (c >>> 1) : c >>> 1;
  return c >>> 0;
});

function crc32(data: Uint8Array) {
  let crc = 0xffffffff;
  data.forEach(byte => {
    crc = crcTable[(crc ^ byte) & 0xff] ^ (crc >>> 8);
  });
  return (crc ^ 0xffffffff) >>> 0;
}

export function createStoredZip(files: ZipFile[]) {
  const locals: Uint8Array[] = [];
  const centrals: Uint8Array[] = [];
  let offset = 0;
  files.forEach(file => {
    const name = encoder.encode(file.path);
    const crc = crc32(file.data);
    const local = concat([u32(0x04034b50), u16(20), u16(0), u16(0), u16(0), u16(0), u32(crc), u32(file.data.length), u32(file.data.length), u16(name.length), u16(0), name, file.data]);
    locals.push(local);
    centrals.push(concat([u32(0x02014b50), u16(20), u16(20), u16(0), u16(0), u16(0), u16(0), u32(crc), u32(file.data.length), u32(file.data.length), u16(name.length), u16(0), u16(0), u16(0), u16(0), u32(0), u32(offset), name]));
    offset += local.length;
  });
  const central = concat(centrals);
  return new Blob([concat([...locals, central, concat([u32(0x06054b50), u16(0), u16(0), u16(files.length), u16(files.length), u32(central.length), u32(offset), u16(0)])])], { type: "application/zip" });
}

export function readStoredZip(buffer: ArrayBuffer) {
  const bytes = new Uint8Array(buffer);
  const files = new Map<string, Uint8Array>();
  let offset = 0;
  while (offset + 30 <= bytes.length) {
    const view = new DataView(bytes.buffer, bytes.byteOffset + offset);
    if (view.getUint32(0, true) !== 0x04034b50) break;
    const method = view.getUint16(8, true);
    if (method !== 0) throw new Error("この .recaloop は未対応の圧縮形式です。RecaLoopで書き出したファイルを使ってください。");
    const compressedSize = view.getUint32(18, true);
    const nameLength = view.getUint16(26, true);
    const extraLength = view.getUint16(28, true);
    const nameStart = offset + 30;
    const dataStart = nameStart + nameLength + extraLength;
    const name = decoder.decode(bytes.slice(nameStart, nameStart + nameLength));
    files.set(name, bytes.slice(dataStart, dataStart + compressedSize));
    offset = dataStart + compressedSize;
  }
  return files;
}

export async function exportWordDeckPackage(list: WordList, cards: WordCard[]) {
  const files: ZipFile[] = [
    { path: "deck.json", data: encoder.encode(JSON.stringify({ type: "word_list", title: list.title, description: list.description, edition_label: list.edition_label }, null, 2)) },
    { path: "cards.json", data: encoder.encode(JSON.stringify(cards.map(card => ({ card_id: card.card_id, front: card.front, back: card.back, memo: card.memo, order_index: card.order_index, front_media_ids: card.front_media_ids || [], back_media_ids: card.back_media_ids || [] })), null, 2)) },
  ];
  const ids = [...new Set(cards.flatMap(card => [...(card.front_media_ids || []), ...(card.back_media_ids || [])]))];
  for (const id of ids) {
    const media = await getLocalMedia(id);
    if (media) files.push({ path: `media/${id}/${media.fileName}`, data: new Uint8Array(await media.blob.arrayBuffer()) });
  }
  return createStoredZip(files);
}

export async function importWordDeckPackage(file: File) {
  const files = readStoredZip(await file.arrayBuffer());
  const deckRaw = files.get("deck.json");
  const cardsRaw = files.get("cards.json");
  if (!deckRaw || !cardsRaw) throw new Error("deck.json または cards.json が見つかりません。");
  const deck = JSON.parse(decoder.decode(deckRaw)) as { title: string; description?: string | null; edition_label?: string | null };
  const cards = JSON.parse(decoder.decode(cardsRaw)) as (Pick<WordCard, "card_id" | "front" | "back" | "memo" | "order_index"> & { front_media_ids?: string[]; back_media_ids?: string[] })[];
  for (const [path, data] of files.entries()) {
    const match = path.match(/^media\/([^/]+)\/(.+)$/);
    if (!match) continue;
    const [, id, fileName] = match;
    const type = fileName.match(/\.(mp3|m4a|wav)$/i) ? "audio/mpeg" : fileName.match(/\.webp$/i) ? "image/webp" : fileName.match(/\.png$/i) ? "image/png" : "image/jpeg";
    const body = data.buffer.slice(data.byteOffset, data.byteOffset + data.byteLength) as ArrayBuffer;
    await saveLocalMedia(new Blob([body], { type }), fileName, id);
  }
  return { deck, cards };
}

export function downloadRecaloopPackage(blob: Blob, title: string) {
  const url = URL.createObjectURL(blob);
  const a = document.createElement("a");
  a.href = url;
  a.download = `${title || "deck"}.recaloop`;
  a.click();
  URL.revokeObjectURL(url);
}
