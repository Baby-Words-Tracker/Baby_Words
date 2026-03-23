export interface LanguageDetails {
  lemma?: string;
  primaryPartOfSpeech?: string;
  allPOS?: string[];
  primaryCategory?: string;
  allCategories?: string[];
}

export interface WordData {
  id?: string;
  languageDetails?: { [languageCode: string]: LanguageDetails };
  [key: string]: any;
}

export class Word implements WordData {
  static collectionName = 'Word';

  id?: string;
  languageDetails: { [languageCode: string]: LanguageDetails } = {};

  static fromDataWithId(data: any): Word {
    const w = new Word();
    w.id = data.id as string | undefined;
    if (data.languageDetails && typeof data.languageDetails === 'object') {
      w.languageDetails = { ...data.languageDetails };
    }
    return w;
  }
}
