import { getLocalMedia, saveLocalMedia } from "./local-media";
import type { MaterialDeck, MaterialNode, WordCard, WordList } from "./types";

type ZipFile = { path: string; data: Uint8Array };
export type RecaloopDeckMeta = { deckId: string; title: string; description?: string | null; createdAt: string; updatedAt: string; appVersion: string; reviewMode: "default" | "light" };
export type RecaloopCardImport = Pick<WordCard, "card_id" | "front" | "back" | "memo" | "order_index"> & { front_media_ids: string[]; back_media_ids: string[] };

const encoder = new TextEncoder();
const decoder = new TextDecoder();

function u16(value: number) { const out = new Uint8Array(2); new DataView(out.buffer).setUint16(0, value, true); return out; }
function u32(value: number) { const out = new Uint8Array(4); new DataView(out.buffer).setUint32(0, value, true); return out; }
function concat(parts: Uint8Array[]) { const size = parts.reduce((sum, part) => sum + part.length, 0), out = new Uint8Array(size); let offset = 0; parts.forEach(part => { out.set(part, offset); offset += part.length; }); return out; }

const crcTable = Array.from({ length: 256 }, (_, index) => { let c = index; for (let k = 0; k < 8; k++) c = c & 1 ? 0xedb88320 ^ (c >>> 1) : c >>> 1; return c >>> 0; });
function crc32(data: Uint8Array) { let crc = 0xffffffff; data.forEach(byte => { crc = crcTable[(crc ^ byte) & 0xff] ^ (crc >>> 8); }); return (crc ^ 0xffffffff) >>> 0; }

export function createStoredZip(files: ZipFile[]) {
  const locals: Uint8Array[] = [], centrals: Uint8Array[] = [];
  let offset = 0;
  files.forEach(file => {
    const name = encoder.encode(file.path), crc = crc32(file.data);
    const local = concat([u32(0x04034b50), u16(20), u16(0), u16(0), u16(0), u16(0), u32(crc), u32(file.data.length), u32(file.data.length), u16(name.length), u16(0), name, file.data]);
    locals.push(local);
    centrals.push(concat([u32(0x02014b50), u16(20), u16(20), u16(0), u16(0), u16(0), u16(0), u32(crc), u32(file.data.length), u32(file.data.length), u16(name.length), u16(0), u16(0), u16(0), u16(0), u32(0), u32(offset), name]));
    offset += local.length;
  });
  const central = concat(centrals);
  return new Blob([concat([...locals, central, concat([u32(0x06054b50), u16(0), u16(0), u16(files.length), u16(files.length), u32(central.length), u32(offset), u16(0)])])], { type: "application/zip" });
}

export function readStoredZip(buffer: ArrayBuffer) {
  const bytes = new Uint8Array(buffer), files = new Map<string, Uint8Array>();
  let offset = 0;
  while (offset + 30 <= bytes.length) {
    const view = new DataView(bytes.buffer, bytes.byteOffset + offset);
    if (view.getUint32(0, true) !== 0x04034b50) break;
    if (view.getUint16(8, true) !== 0) throw new Error("この .recaloop は未対応の圧縮形式です。RecaLoopで書き出したファイルを使ってください。");
    const size = view.getUint32(18, true), nameLength = view.getUint16(26, true), extraLength = view.getUint16(28, true), nameStart = offset + 30, dataStart = nameStart + nameLength + extraLength;
    files.set(decoder.decode(bytes.slice(nameStart, nameStart + nameLength)), bytes.slice(dataStart, dataStart + size));
    offset = dataStart + size;
  }
  return files;
}

function csvCell(value: string | null | undefined) {
  const text = value || "";
  return /[",\n;]/.test(text) ? `"${text.replace(/"/g, '""')}"` : text;
}
function parseCsv(text: string) {
  const rows: string[][] = [], current: string[] = [];
  let cell = "", quoted = false;
  for (let i = 0; i < text.length; i++) {
    const ch = text[i], next = text[i + 1];
    if (quoted && ch === '"' && next === '"') { cell += '"'; i++; }
    else if (ch === '"') quoted = !quoted;
    else if (!quoted && ch === ",") { current.push(cell.trim()); cell = ""; }
    else if (!quoted && (ch === "\n" || ch === "\r")) { if (ch === "\r" && next === "\n") i++; current.push(cell.trim()); if (current.some(Boolean)) rows.push([...current]); current.length = 0; cell = ""; }
    else cell += ch;
  }
  current.push(cell.trim()); if (current.some(Boolean)) rows.push(current);
  return rows;
}
function mediaRefName(id: string, fileName: string) {
  const ext = fileName.includes(".") ? fileName.slice(fileName.lastIndexOf(".")) : "";
  return `${id}${ext}`;
}
function withRefs(text: string, refs: string[]) {
  return `${text || ""}${refs.map(ref => `[${ref}]`).join("")}`;
}
function stripRefs(text: string, deckId: string) {
  const ids: string[] = [];
  const clean = text.replace(/\[([^\]]+)\]/g, (_, fileName: string) => {
    ids.push(mediaId(deckId, fileName));
    return "";
  }).trim();
  return { text: clean, ids };
}
function mediaId(deckId: string, fileName: string) {
  return `recaloop:${deckId}:${fileName}`;
}
function mimeFromName(fileName: string) {
  return fileName.match(/\.(mp3|m4a|wav)$/i) ? "audio/mpeg" : fileName.match(/\.webp$/i) ? "image/webp" : fileName.match(/\.png$/i) ? "image/png" : "image/jpeg";
}

export async function exportWordDeckPackage(list: WordList, cards: WordCard[]) {
  const deckId = list.external_deck_id || list.source_content_id || list.id;
  const mediaNames = new Map<string, string>();
  const files: ZipFile[] = [];
  for (const id of [...new Set(cards.flatMap(card => [...(card.front_media_ids || []), ...(card.back_media_ids || [])]))]) {
    const media = await getLocalMedia(id);
    if (!media) continue;
    const name = mediaRefName(id.replace(/^recaloop:[^:]+:/, ""), media.fileName);
    mediaNames.set(id, name);
    files.push({ path: `media/${name}`, data: new Uint8Array(await media.blob.arrayBuffer()) });
  }
  const now = new Date().toISOString();
  const deck: RecaloopDeckMeta = { deckId, title: list.title, description: list.description || null, createdAt: list.created_at || now, updatedAt: list.updated_at || now, appVersion: "recaloop-web", reviewMode: list.review_mode || "default" };
  const csvRows = cards.sort((a, b) => a.order_index - b.order_index).map((card, index) => {
    const frontRefs = (card.front_media_ids || []).map(id => mediaNames.get(id)).filter(Boolean) as string[];
    const backRefs = (card.back_media_ids || []).map(id => mediaNames.get(id)).filter(Boolean) as string[];
    return [list.title, "カード", "", "", "", card.card_id || String(index + 1).padStart(4, "0"), `${withRefs(card.front, frontRefs)};${withRefs(card.back, backRefs)}`].map(csvCell).join(",");
  });
  return createStoredZip([{ path: "deck.json", data: encoder.encode(JSON.stringify(deck, null, 2)) }, { path: "cards.csv", data: encoder.encode(csvRows.join("\n")) }, ...files]);
}

export async function exportMaterialDeckPackage(deck: MaterialDeck, nodes: MaterialNode[]) {
  const deckId = deck.external_deck_id || deck.source_content_id || deck.id;
  const now = new Date().toISOString();
  const meta: RecaloopDeckMeta = { deckId, title: deck.title, description: deck.description || null, createdAt: deck.created_at || now, updatedAt: deck.updated_at || now, appVersion: "recaloop-web", reviewMode: deck.review_mode || "default" };
  const byId = new Map(nodes.map(node => [node.id, node]));
  const pathFor = (node: MaterialNode) => {
    const titles: string[] = [];
    let parent = node.parent_id;
    while (parent) {
      const current = byId.get(parent);
      if (!current) break;
      titles.unshift(current.title);
      parent = current.parent_id;
    }
    return titles;
  };
  const rows = nodes
    .filter(node => node.node_type === "item")
    .sort((a, b) => a.order_index - b.order_index)
    .map(node => {
      const hierarchy = [...pathFor(node), node.title].slice(0, 6);
      while (hierarchy.length < 6) hierarchy.push("");
      return [...hierarchy, node.memo || node.title].map(csvCell).join(",");
    });
  return createStoredZip([
    { path: "deck.json", data: encoder.encode(JSON.stringify(meta, null, 2)) },
    { path: "cards.csv", data: encoder.encode(rows.join("\n")) },
  ]);
}

export async function importWordDeckPackage(file: File) {
  const files = readStoredZip(await file.arrayBuffer()), deckRaw = files.get("deck.json"), cardsRaw = files.get("cards.csv") || files.get("cards.json");
  if (!deckRaw || !cardsRaw) throw new Error("deck.json または cards.csv が見つかりません。");
  const deck = JSON.parse(decoder.decode(deckRaw)) as RecaloopDeckMeta;
  for (const [path, data] of files.entries()) {
    const match = path.match(/^media\/(.+)$/);
    if (!match) continue;
    const fileName = match[1], body = data.buffer.slice(data.byteOffset, data.byteOffset + data.byteLength) as ArrayBuffer;
    await saveLocalMedia(new Blob([body], { type: mimeFromName(fileName) }), fileName, mediaId(deck.deckId, fileName));
  }
  const decoded = decoder.decode(cardsRaw);
  const cards = files.has("cards.json")
    ? (JSON.parse(decoded) as RecaloopCardImport[])
    : parseCsv(decoded).map((row, index) => {
      const content = row.at(-1) || "", before = row.slice(0, -1).filter(Boolean), [frontRaw, ...backParts] = content.split(";"), front = stripRefs(frontRaw || "", deck.deckId), back = stripRefs(backParts.join(";"), deck.deckId);
      return { card_id: before.at(-1) || String(index + 1).padStart(4, "0"), front: front.text, back: back.text, memo: before.slice(0, -1).join(" / ") || null, order_index: index, front_media_ids: front.ids, back_media_ids: back.ids };
    });
  return { deck, cards };
}

export function downloadRecaloopPackage(blob: Blob, title: string) {
  const url = URL.createObjectURL(blob), a = document.createElement("a");
  a.href = url;
  a.download = `${title || "deck"}.recaloop`;
  a.click();
  URL.revokeObjectURL(url);
}
