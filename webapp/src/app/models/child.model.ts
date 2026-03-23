export interface ChildData {
  id?: string;
  wordCount?: number;
  language?: { name: string }[];
  birthday?: unknown; // Firestore timestamp or ISO string
}

export class Child implements ChildData {
  static collectionName = 'Child';

  id?: string;
  wordCount = 0;
  language: { name: string }[] = [];
  birthday = new Date(0);

  static fromDataWithId(data: any): Child {
    const child = new Child();
    child.id = data.id as string | undefined;
    child.wordCount = typeof data.wordCount === 'number' ? data.wordCount : 0;
    child.language = Array.isArray(data.language)
      ? data.language.map((l: any) => ({ name: String(l.name || l) }))
      : [];
    if (data.birthday) {
      // handle Firestore Timestamp
      child.birthday =
        typeof data.birthday.toDate === 'function'
          ? data.birthday.toDate()
          : new Date(data.birthday);
    }
    return child;
  }
}
