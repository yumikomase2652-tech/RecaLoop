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
export type LocalMediaInput = Omit<LocalMediaRecord, "createdAt"> & { createdAt?: string };

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

export async function saveLocalMediaBatch(inputs: LocalMediaInput[], batchSize = 24, progress?: (done: number, total: number) => void) {
  let saved = 0, skipped = 0, done = 0;
  for (let start = 0; start < inputs.length; start += batchSize) {
    const chunk = inputs.slice(start, start + batchSize);
    const db = await openDb();
    await new Promise<void>((resolve, reject) => {
      const tx = db.transaction(storeName, "readwrite");
      const store = tx.objectStore(storeName);
      tx.oncomplete = () => {
        db.close();
        resolve();
      };
      tx.onerror = () => {
        db.close();
        reject(tx.error);
      };
      chunk.forEach(input => {
        const record: LocalMediaRecord = {
          ...input,
          createdAt: input.createdAt || new Date().toISOString(),
        };
        const get = store.get(record.id);
        get.onerror = () => reject(get.error);
        get.onsuccess = () => {
          if (get.result) {
            skipped++;
            done++;
            progress?.(done, inputs.length);
            return;
          }
          const put = store.put(record);
          put.onerror = () => reject(put.error);
          put.onsuccess = () => {
            saved++;
            done++;
            progress?.(done, inputs.length);
          };
        };
      });
    });
    await new Promise(resolve => setTimeout(resolve, 0));
  }
  return { saved, skipped, total: inputs.length };
}

export async function getLocalMedia(id: string) {
  return withStore<LocalMediaRecord | undefined>("readonly", store => store.get(id));
}

export async function localMediaUrl(id: string) {
  const record = await getLocalMedia(id);
  return record ? { record, url: URL.createObjectURL(record.blob) } : null;
}

export async function listLocalMedia() {
  return withStore<LocalMediaRecord[]>("readonly", store => store.getAll());
}

export async function deleteLocalMedia(ids: string[]) {
  if (!ids.length) return 0;
  const db = await openDb();
  return new Promise<number>((resolve, reject) => {
    let deleted = 0;
    const tx = db.transaction(storeName, "readwrite");
    const store = tx.objectStore(storeName);
    tx.oncomplete = () => {
      db.close();
      resolve(deleted);
    };
    tx.onerror = () => {
      db.close();
      reject(tx.error);
    };
    ids.forEach(id => {
      const request = store.delete(id);
      request.onsuccess = () => {
        deleted++;
      };
      request.onerror = () => reject(request.error);
    });
  });
}
