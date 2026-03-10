export interface WordTrackerData {
  id?: string;
  firstUtterance?: unknown; // timestamp or iso
  language?: { name: string } | null;
  note?: string;
  videoId?: string;
  phraseId?: string;
  phraseText?: string;
  [key: string]: any;
}

export class WordTracker implements WordTrackerData {
  static collectionName = 'WordTracker';

  id?: string;
  firstUtterance = new Date(0);
  language: { name: string } | null = null;
  note?: string;
  videoId?: string;
  phraseId?: string;
  phraseText?: string;

  static fromDataWithId(data: any): WordTracker {
    const wt = new WordTracker();
    wt.id = data.id as string | undefined;
    if (data.firstUtterance) {
      wt.firstUtterance =
        typeof data.firstUtterance.toDate === 'function'
          ? data.firstUtterance.toDate()
          : new Date(data.firstUtterance);
    }
    wt.language = data.language ? { name: String(data.language.name || data.language) } : null;
    wt.note = data.note;
    wt.videoId = data.videoId;
    wt.phraseId = data.phraseId;
    wt.phraseText = data.phraseText;
    return wt;
  }
}
