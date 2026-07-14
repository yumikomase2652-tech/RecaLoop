import { getLocalMedia, saveLocalMediaBatch, type LocalMediaInput } from "./local-media";
import type { MaterialDeck, MaterialNode, WordCard, WordList } from "./types";

type ZipFile = { path: string; data: Uint8Array };
export type RecaloopDeckMeta = { deckId: string; title: string; description?: string | null; createdAt: string; updatedAt: string; appVersion: string; reviewMode: "default" | "light"; version?: string };
export type RecaloopCardImport = Pick<WordCard, "card_id" | "front" | "back" | "memo" | "order_index"> & { front_media_ids: string[]; back_media_ids: string[] };
export type RecaloopExportSummary = { title: string; cardCount: number; imageCount: number; audioCount: number; mediaCount: number; missingMedia: string[]; fileName: string };
export type RecaloopImportProgress = { phase: string; cardsDone?: number; cardsTotal?: number; mediaDone?: number; mediaTotal?: number; imageCount?: number; audioCount?: number; elapsedMs?: number };
export type RecaloopImportResult = { deck: RecaloopDeckMeta; cards: RecaloopCardImport[]; skipped?: boolean; stats: { cardCount: number; imageCount: number; audioCount: number; mediaCount: number; elapsedMs: number; timings: Record<string, number>; mediaSaved: number; mediaSkipped: number } };
type RecaloopImportOptions = { onProgress?: (progress: RecaloopImportProgress) => void; shouldSkip?: (deck: RecaloopDeckMeta) => boolean };

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

async function inflateRaw(data: Uint8Array) {
  if (typeof DecompressionStream === "undefined") throw new Error("ZIPの構成が正しくありません: このブラウザでは圧縮ZIPを展開できません。");
  const body = data.buffer.slice(data.byteOffset, data.byteOffset + data.byteLength) as ArrayBuffer;
  const stream = new Blob([body]).stream().pipeThrough(new DecompressionStream("deflate-raw" as CompressionFormat));
  return new Uint8Array(await new Response(stream).arrayBuffer());
}

export async function readZip(buffer: ArrayBuffer) {
  const bytes = new Uint8Array(buffer), files = new Map<string, Uint8Array>();
  const view = new DataView(bytes.buffer, bytes.byteOffset, bytes.byteLength);
  let eocd = -1;
  for (let i = bytes.length - 22; i >= Math.max(0, bytes.length - 65557); i--) {
    if (view.getUint32(i, true) === 0x06054b50) { eocd = i; break; }
  }
  if (eocd < 0) throw new Error("ZIPの構成が正しくありません: ZIPの終端情報が見つかりません。");
  const entries = view.getUint16(eocd + 10, true), centralOffset = view.getUint32(eocd + 16, true);
  let offset = centralOffset;
  for (let index = 0; index < entries; index++) {
    if (view.getUint32(offset, true) !== 0x02014b50) throw new Error("ZIPの構成が正しくありません: 中央ディレクトリを読めません。");
    const method = view.getUint16(offset + 10, true), compressedSize = view.getUint32(offset + 20, true), nameLength = view.getUint16(offset + 28, true), extraLength = view.getUint16(offset + 30, true), commentLength = view.getUint16(offset + 32, true), localOffset = view.getUint32(offset + 42, true);
    const name = decoder.decode(bytes.slice(offset + 46, offset + 46 + nameLength));
    offset += 46 + nameLength + extraLength + commentLength;
    if (!name || name.endsWith("/")) continue;
    if (view.getUint32(localOffset, true) !== 0x04034b50) throw new Error(`ZIPの構成が正しくありません: ${name} のデータ位置を読めません。`);
    const localNameLength = view.getUint16(localOffset + 26, true), localExtraLength = view.getUint16(localOffset + 28, true), dataStart = localOffset + 30 + localNameLength + localExtraLength, compressed = bytes.slice(dataStart, dataStart + compressedSize);
    if (method === 0) files.set(name, compressed);
    else if (method === 8) files.set(name, await inflateRaw(compressed));
    else throw new Error(`ZIPの構成が正しくありません: ${name} の圧縮方式に対応していません。`);
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
function withRefs(text: string, refs: string[]) {
  return `${text || ""}${refs.map(ref => `[${ref}]`).join("")}`;
}
function mediaId(deckId: string, fileName: string) {
  return `recaloop:${deckId}:${fileName}`;
}
function cleanCell(value: string | null | undefined) {
  const text = (value || "").trim();
  return /^(none|null|undefined)$/i.test(text) ? "" : text.replace(/[;:](none|null|undefined)$/i, "").trim();
}
function normalizeMediaName(value: string) {
  const trimmed = value.trim().replace(/\\/g, "/").replace(/^\.?\//, "").replace(/^media\//i, "");
  try {
    return decodeURIComponent(trimmed).normalize("NFC").toLowerCase();
  } catch {
    return trimmed.normalize("NFC").toLowerCase();
  }
}
function displayMediaName(value: string) {
  const trimmed = value.trim().replace(/\\/g, "/").replace(/^\.?\//, "").replace(/^media\//i, "");
  try {
    return decodeURIComponent(trimmed).normalize("NFC");
  } catch {
    return trimmed.normalize("NFC");
  }
}
function isMediaRef(value: string) {
  return /\.(png|jpe?g|webp|gif|mp3|m4a|wav|ogg)$/i.test(value.trim());
}
type MediaEntry = { path: string; fileName: string; data: Uint8Array };
function parseCardSide(raw: string, deckId: string, side: "front" | "back", mediaIndex: Map<string, MediaEntry>, mediaQueue: Map<string, { input: LocalMediaInput; side: "front" | "back"; path: string }>) {
  const ids: string[] = [], refs: string[] = [];
  let text = cleanCell(raw);
  refs.push(...[...text.matchAll(/\[([^\]]+)\]/g)].map(match => match[1]).filter(isMediaRef));
  for (const ref of refs) {
    const fileName = displayMediaName(ref), matched = mediaIndex.get(normalizeMediaName(ref));
    console.info("Detected media reference:", fileName);
    if (!matched) throw new Error(`media/${fileName} が見つかりません。`);
    const id = mediaId(deckId, fileName), body = matched.data.buffer.slice(matched.data.byteOffset, matched.data.byteOffset + matched.data.byteLength) as ArrayBuffer, blob = new Blob([body], { type: mimeFromName(matched.fileName) });
    if (!mediaQueue.has(id)) mediaQueue.set(id, { input: { id, fileName: matched.fileName, mimeType: blob.type || "application/octet-stream", kind: isAudioMedia(matched.fileName, blob.type) ? "audio" : "image", size: blob.size, blob }, side, path: matched.path });
    console.info("Matched ZIP entry:", matched.path);
    console.info("Queued mediaId:", id);
    console.info("Attached to:", side);
    ids.push(id);
  }
  text = cleanCell(text.replace(/\[([^\]]+)\]/g, (_, ref: string) => isMediaRef(ref) ? "" : `[${ref}]`));
  return { text, ids };
}
function splitCardContent(content: string) {
  const index = content.indexOf(";");
  return index < 0 ? [content, ""] as const : [content.slice(0, index), content.slice(index + 1)] as const;
}
function parseRecaloopCsvRow(row: string[], index: number) {
  const content = row.at(-1) || "";
  const problemNumber = cleanCell(row.at(-2) || "");
  const hierarchy = row.slice(0, -2).map(cleanCell).filter(Boolean);
  const explicitCardId = problemNumber || null;
  const [frontRaw, backRaw] = splitCardContent(content);
  return { content, hierarchy, problemNumber, explicitCardId, frontRaw, backRaw, rowNumber: index + 1 };
}
function hashString(value: string) {
  let hash = 2166136261;
  for (let i = 0; i < value.length; i++) {
    hash ^= value.charCodeAt(i);
    hash = Math.imul(hash, 16777619);
  }
  return (hash >>> 0).toString(36);
}
function stableCardId(deckId: string, sourceId: string | null | undefined, fallback: string) {
  return sourceId || `card_${hashString(`${deckId}:${fallback}`)}`;
}
function mimeFromName(fileName: string) {
  return fileName.match(/\.(mp3|m4a|wav)$/i) ? "audio/mpeg" : fileName.match(/\.webp$/i) ? "image/webp" : fileName.match(/\.png$/i) ? "image/png" : "image/jpeg";
}
function mediaExtension(fileName: string) {
  const match = fileName.match(/\.[a-z0-9]+$/i);
  return match ? match[0].toLowerCase() : "";
}
function numberedMediaName(index: number, fileName: string) {
  return `${String(index + 1).padStart(4, "0")}${mediaExtension(fileName) || ".bin"}`;
}
function cleanFileName(value: string) {
  return (value || "deck").replace(/\.recaloop$/i, "").replace(/[\\/:*?"<>|]/g, "_").replace(/\s+/g, "_").replace(/^_+|_+$/g, "") || "deck";
}
export function recaloopFileName(value: string) {
  return `${cleanFileName(value)}.recaloop`;
}
function isAudioMedia(fileName: string, mimeType?: string) {
  return Boolean(mimeType?.startsWith("audio/") || fileName.match(/\.(mp3|m4a|wav|ogg)$/i));
}
async function collectWordMedia(cards: WordCard[]) {
  const ids = [...new Set(cards.flatMap(card => [...(card.front_media_ids || []), ...(card.back_media_ids || [])]))], mediaNames = new Map<string, string>(), files: ZipFile[] = [], missingMedia: string[] = [];
  let imageCount = 0, audioCount = 0;
  for (const [index, id] of ids.entries()) {
    const media = await getLocalMedia(id);
    if (!media) { missingMedia.push(id); continue; }
    const name = numberedMediaName(index, media.fileName);
    mediaNames.set(id, name);
    if (isAudioMedia(media.fileName, media.mimeType)) audioCount++; else imageCount++;
    files.push({ path: `media/${name}`, data: new Uint8Array(await media.blob.arrayBuffer()) });
  }
  return { mediaNames, files, imageCount, audioCount, missingMedia };
}
export async function summarizeWordDeckPackage(list: WordList, cards: WordCard[]): Promise<RecaloopExportSummary> {
  const media = await collectWordMedia(cards);
  return { title: list.title, cardCount: cards.length, imageCount: media.imageCount, audioCount: media.audioCount, mediaCount: media.imageCount + media.audioCount, missingMedia: media.missingMedia, fileName: recaloopFileName(list.title) };
}
export function summarizeMaterialDeckPackage(deck: MaterialDeck, nodes: MaterialNode[]): RecaloopExportSummary {
  return { title: deck.title, cardCount: nodes.filter(node => node.node_type === "item").length, imageCount: 0, audioCount: 0, mediaCount: 0, missingMedia: [], fileName: recaloopFileName(deck.title) };
}

export async function exportWordDeckPackage(list: WordList, cards: WordCard[]) {
  const deckId = list.external_deck_id || list.source_content_id || list.id;
  const { mediaNames, files, missingMedia } = await collectWordMedia(cards);
  if (missingMedia.length) throw new Error(`メディア参照切れがあります: ${missingMedia.length}件`);
  const now = new Date().toISOString();
  const deck: RecaloopDeckMeta = { deckId, title: list.title, description: list.description || null, createdAt: list.created_at || now, updatedAt: list.updated_at || now, appVersion: "recaloop-web", reviewMode: list.review_mode || "default", version: list.updated_at || now };
  const csvRows = cards.sort((a, b) => a.order_index - b.order_index).map((card, index) => {
    const frontRefs = (card.front_media_ids || []).map(id => mediaNames.get(id)).filter(Boolean) as string[];
    const backRefs = (card.back_media_ids || []).map(id => mediaNames.get(id)).filter(Boolean) as string[];
    const problemNumber = card.card_id || String(index + 1).padStart(4, "0");
    return [list.title, "カード", "", "", "", problemNumber, `${withRefs(card.front, frontRefs)};${withRefs(card.back, backRefs)}`].map(csvCell).join(",");
  });
  return createStoredZip([{ path: "deck.json", data: encoder.encode(JSON.stringify(deck, null, 2)) }, { path: "cards.csv", data: encoder.encode(csvRows.join("\n")) }, ...files]);
}

export async function exportMaterialDeckPackage(deck: MaterialDeck, nodes: MaterialNode[]) {
  const deckId = deck.external_deck_id || deck.source_content_id || deck.id;
  const now = new Date().toISOString();
  const meta: RecaloopDeckMeta = { deckId, title: deck.title, description: deck.description || null, createdAt: deck.created_at || now, updatedAt: deck.updated_at || now, appVersion: "recaloop-web", reviewMode: deck.review_mode || "default", version: deck.updated_at || now };
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
      const hierarchy = pathFor(node).slice(0, 5);
      while (hierarchy.length < 5) hierarchy.push("");
      return [...hierarchy, node.title, node.memo || ""].map(csvCell).join(",");
    });
  return createStoredZip([
    { path: "deck.json", data: encoder.encode(JSON.stringify(meta, null, 2)) },
    { path: "cards.csv", data: encoder.encode(rows.join("\n")) },
  ]);
}

function logTiming(timings: Record<string, number>, label: string, started: number) {
  const elapsed = Math.round(performance.now() - started);
  timings[label] = elapsed;
  console.info(`${label} ${elapsed}ms`);
}

export async function importWordDeckPackage(file: File, options: RecaloopImportOptions = {}): Promise<RecaloopImportResult> {
  const totalStart = performance.now(), timings: Record<string, number> = {};
  let started = performance.now();
  const files = await readZip(await file.arrayBuffer());
  logTiming(timings, "ZIP解凍", started);
  const deckRaw = files.get("deck.json"), cardsRaw = files.get("cards.csv") || files.get("cards.json");
  if (!deckRaw) throw new Error("ZIPの構成が正しくありません: deck.json が見つかりません。");
  if (!cardsRaw) throw new Error("ZIPの構成が正しくありません: cards.csv が見つかりません。");
  let deck: RecaloopDeckMeta;
  started = performance.now();
  try {
    deck = JSON.parse(decoder.decode(deckRaw)) as RecaloopDeckMeta;
  } catch {
    throw new Error("ZIPの構成が正しくありません: deck.json を読み込めません。");
  }
  logTiming(timings, "deck.json 読み込み", started);
  if (!deck.deckId) throw new Error("ZIPの構成が正しくありません: deck.json に deckId がありません。");
  deck.version ||= deck.updatedAt || "1.0.0";
  if (options.shouldSkip?.(deck)) {
    const elapsedMs = Math.round(performance.now() - totalStart);
    console.info(`インポート合計 ${elapsedMs}ms`);
    options.onProgress?.({ phase: "既に最新", cardsDone: 0, cardsTotal: 0, mediaDone: 0, mediaTotal: 0, elapsedMs });
    return { deck, cards: [], skipped: true, stats: { cardCount: 0, imageCount: 0, audioCount: 0, mediaCount: 0, elapsedMs, timings, mediaSaved: 0, mediaSkipped: 0 } };
  }
  started = performance.now();
  const mediaIndex = new Map<string, MediaEntry>();
  for (const [path, data] of files.entries()) {
    const match = path.match(/^media\/(.+)$/i);
    if (!match) continue;
    const fileName = displayMediaName(match[1]);
    mediaIndex.set(normalizeMediaName(fileName), { path, fileName, data });
  }
  logTiming(timings, "media一覧作成", started);
  started = performance.now();
  const decoded = decoder.decode(cardsRaw);
  logTiming(timings, "cards.csv 読み込み", started);
  const cards = files.has("cards.json")
    ? (JSON.parse(decoded) as RecaloopCardImport[])
    : [];
  const mediaQueue = new Map<string, { input: LocalMediaInput; side: "front" | "back"; path: string }>();
  if (!files.has("cards.json")) {
    started = performance.now();
    const rows = parseCsv(decoded);
    logTiming(timings, "CSV解析", started);
    started = performance.now();
    for (const [index, row] of rows.entries()) {
      const parsed = parseRecaloopCsvRow(row, index), front = parseCardSide(parsed.frontRaw || "", deck.deckId, "front", mediaIndex, mediaQueue), back = parseCardSide(parsed.backRaw || "", deck.deckId, "back", mediaIndex, mediaQueue), fingerprint = `${parsed.hierarchy.join("/")}:${parsed.problemNumber}:${front.text}:${back.text}:${index}`;
      console.info("Parsed hierarchy:", parsed.hierarchy.join(" / "));
      console.info("Parsed frontText:", front.text);
      console.info("Parsed backText:", back.text);
      console.info("Parsed front media:", front.ids.length);
      console.info("Parsed back media:", back.ids.length);
      console.info("Has back side:", Boolean(back.text || back.ids.length));
      cards.push({ card_id: stableCardId(deck.deckId, parsed.explicitCardId, fingerprint), front: front.text, back: back.text, memo: parsed.hierarchy.join(" / ") || null, order_index: index, front_media_ids: front.ids, back_media_ids: back.ids });
      if (index % 100 === 0) {
        options.onProgress?.({ phase: "カード解析", cardsDone: index + 1, cardsTotal: rows.length });
        await new Promise(resolve => setTimeout(resolve, 0));
      }
    }
    logTiming(timings, "カード生成", started);
  }
  const mediaInputs = [...mediaQueue.values()].map(item => item.input), imageCount = mediaInputs.filter(item => item.kind === "image").length, audioCount = mediaInputs.filter(item => item.kind === "audio").length;
  started = performance.now();
  const mediaResult = await saveLocalMediaBatch(mediaInputs, 24, (done, total) => options.onProgress?.({ phase: "メディア保存", mediaDone: done, mediaTotal: total, imageCount, audioCount, cardsDone: cards.length, cardsTotal: cards.length }));
  logTiming(timings, "画像保存", started);
  const elapsedMs = Math.round(performance.now() - totalStart);
  console.info(`インポート合計 ${elapsedMs}ms`);
  options.onProgress?.({ phase: "解析完了", cardsDone: cards.length, cardsTotal: cards.length, mediaDone: mediaInputs.length, mediaTotal: mediaInputs.length, imageCount, audioCount, elapsedMs });
  return { deck, cards, stats: { cardCount: cards.length, imageCount, audioCount, mediaCount: mediaInputs.length, elapsedMs, timings, mediaSaved: mediaResult.saved, mediaSkipped: mediaResult.skipped } };
}

export function downloadRecaloopPackage(blob: Blob, title: string) {
  const url = URL.createObjectURL(blob), a = document.createElement("a");
  a.href = url;
  a.download = recaloopFileName(title || "deck");
  a.click();
  URL.revokeObjectURL(url);
}
