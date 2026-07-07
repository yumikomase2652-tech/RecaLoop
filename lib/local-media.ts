export type LocalMediaKind = "image" | "audio";

export interface LocalMediaRecord {
  id: string;
  fileName: string;
  mimeType: string;
  kind: LocalMediaKind;
  size: number;
  createdAt: string;
  blob: Blob;
}

const dbName = "recaloop-local-media";
const storeName = "media";

function mediaKind(type: string): LocalMediaKind {
  return type.startsWith("audio/") ? "audio" : "image";
}

function openDb() {
  return new Promise<IDBDatabase>((resolve, reject) => {
    const request = indexedDB.open(dbName, 1);
    request.onupgradeneeded = () => request.result.createObjectStore(storeName, { keyPath: "id" });
    request.onerror = () => reject(request.error);
    request.onsuccess = () => resolve(request.result);
  });
}

async function withStore<T>(mode: IDBTransactionMode, run: (store: IDBObjectStore) => IDBRequest<T>) {
  const db = await openDb();
  return new Promise<T>((resolve, reject) => {
    const tx = db.transaction(storeName, mode);
    const request = run(tx.objectStore(storeName));
    request.onerror = () => reject(request.error);
    request.onsuccess = () => resolve(request.result);
    tx.oncomplete = () => db.close();
    tx.onerror = () => {
      db.close();
      reject(tx.error);
    };
  });
}

export async function saveLocalMedia(file: File | Blob, fileName?: string, preferredId?: string) {
  const id = preferredId || crypto.randomUUID();
  const name = fileName || (file instanceof File ? file.name : id);
  const record: LocalMediaRecord = {
    id,
    fileName: name,
    mimeType: file.type || "application/octet-stream",
    kind: mediaKind(file.type || ""),
    size: file.size,
    createdAt: new Date().toISOString(),
    blob: file,
  };
  await withStore("readwrite", store => store.put(record));
  return record;
}

export async function getLocalMedia(id: string) {
  return withStore<LocalMediaRecord | undefined>("readonly", store => store.get(id));
}

export async function localMediaUrl(id: string) {
  const record = await getLocalMedia(id);
  return record ? { record, url: URL.createObjectURL(record.blob) } : null;
}
