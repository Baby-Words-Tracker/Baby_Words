export interface PhraseTrackerData {
  id?: string;
  createdAt?: unknown; // Firestore timestamp or ISO string
  [key: string]: unknown;
}

/** Minimal model for PhraseTracker docs; used for researchers panel (createdAt only). */
export function parsePhraseTrackerCreatedAt(data: { id?: string; createdAt?: unknown }): Date {
  const raw = data.createdAt;
  if (!raw) return new Date(0);
  if (typeof raw === 'object' && 'toDate' in (raw as object) && typeof (raw as { toDate: () => Date }).toDate === 'function') {
    return (raw as { toDate: () => Date }).toDate();
  }
  const d = new Date(raw as string | number);
  return Number.isNaN(d.getTime()) ? new Date(0) : d;
}
