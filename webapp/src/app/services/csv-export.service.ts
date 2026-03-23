import { Injectable } from '@angular/core';
import { IFirestoreRepository, FirestoreRepository } from './firestore-repository.service';
import { Child } from '../models/child.model';
import { Word } from '../models/word.model';
import { WordTracker } from '../models/word-tracker.model';
import { downloadAsCSV } from '../util/download-as-csv';

@Injectable({ providedIn: 'root' })
export class CsvExportService {
  private fireRepo: IFirestoreRepository;

  constructor(private repository: FirestoreRepository) {
    // Angular will provide the concrete implementation
    this.fireRepo = repository;
  }

  /**
   * exports all words from all children to a CSV file
   * excludes child names for anonymity
   * returns true if successful
   */
  async exportAllWordsToCSV(): Promise<boolean> {
    try {
      console.debug('CsvExportService: Starting to export all words to CSV');

      const allChildren = await this._getAllChildren();
      if (allChildren.length === 0) {
        console.debug('CsvExportService: No children found in database');
        return false;
      }
      console.debug(
        `CsvExportService: Found ${allChildren.length} children to process`
      );

      const csvData: string[][] = [];

      for (const child of allChildren) {
        console.debug(`CsvExportService: Processing child ${child.id}`);

        const wordTrackers = await this.fireRepo.readAllFromSubcollection(
          Child.collectionName,
          child.id ?? '',
          WordTracker.collectionName
        );

        for (const trackerData of wordTrackers) {
          const tracker = WordTracker.fromDataWithId(trackerData);

          const word = await this._getWordDetails(tracker.id ?? '');
          console.debug('CsvExportService: fetched word details', word);

          let lemma = '';
          let primaryPOS = '';
          let allPOS = '';
          let primaryCategory = '';
          let allCategories = '';

          if (word && tracker.language) {
            const langDetails = word.languageDetails[tracker.language.name];
            if (langDetails) {
              lemma = langDetails.lemma ?? '';
              primaryPOS = langDetails.primaryPartOfSpeech ?? '';
              allPOS = (langDetails.allPOS || []).join(';');
              primaryCategory = langDetails.primaryCategory ?? '';
              allCategories = (langDetails.allCategories || []).join(';');
            }
          }

          const row = [
            child.id ?? '',
            tracker.id ?? '',
            tracker.firstUtterance.toISOString(),
            tracker.language?.name ?? '',
            lemma,
            primaryPOS,
            allPOS,
            primaryCategory,
            allCategories,
            tracker.note ?? '',
            tracker.videoId ?? '',
            tracker.phraseId ?? '',
            tracker.phraseText ?? '',
            String(child.wordCount ?? ''),
            (child.language || []).map((l) => l.name).join(';'),
            child.birthday.toISOString(),
            tracker.language?.name ?? ''
          ];

          csvData.push(row);
        }
      }

      if (csvData.length === 0) {
        console.debug('CsvExportService: No word data found to export');
        return false;
      }

      console.debug(`CsvExportService: Exporting ${csvData.length} word records`);

      const csvHeader = [
        'Child_ID',
        'Word',
        'First_Utterance_DateTime',
        'Word_Language',
        'Lemma',
        'Primary_Part_Of_Speech',
        'All_Parts_Of_Speech',
        'Primary_Category',
        'All_Categories',
        'Notes',
        'Video_ID',
        'Phrase_ID',
        'Phrase_Text',
        'Child_Total_Word_Count',
        'Child_Languages',
        'Child_Birthday',
        'Utterance_Language'
      ];

      await downloadAsCSV(csvHeader, csvData, 'full_word_list');
      console.debug(
        `CsvExportService: Successfully exported ${csvData.length} words to CSV`
      );
      return true;
    } catch (e) {
      console.debug('CsvExportService: Error exporting to CSV:', e);
      return false;
    }
  }

  private async _getAllChildren(): Promise<Child[]> {
    try {
      const data = await this.fireRepo.readAll(Child.collectionName);
      return data.map((d) => Child.fromDataWithId(d));
    } catch (e) {
      console.debug('CsvExportService: Error getting all children:', e);
      return [];
    }
  }

  private async _getWordDetails(wordId: string): Promise<Word | null> {
    try {
      const data = await this.fireRepo.read(Word.collectionName, wordId);
      if (!data) return null;
      return Word.fromDataWithId(data);
    } catch (e) {
      console.debug(`CsvExportService: Error getting word details for ${wordId}:`, e);
      return null;
    }
  }
}
