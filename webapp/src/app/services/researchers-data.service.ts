import { Injectable } from '@angular/core';
import { Child } from '../models/child.model';
import { WordTracker } from '../models/word-tracker.model';
import { FirestoreRepository } from './firestore-repository.service';

export interface UtteranceEvent {
  date: Date;
  source: 'word';
  childId?: string;
}

export interface AggregatedUtterances {
  labels: string[];
  counts: number[];
}

@Injectable({ providedIn: 'root' })
export class ResearchersDataService {
  constructor(private fireRepo: FirestoreRepository) {}

  /** Returns list of children (id only) for anonymous selection in researchers panel. */
  async getChildren(): Promise<{ id: string }[]> {
    const data = await this.fireRepo.readAll(Child.collectionName);
    return data.map((d) => ({ id: d.id as string }));
  }

  /** Returns list of children with word count (WordTracker doc count) for researchers panel. */
  async getChildrenWithWordCount(): Promise<{ id: string; wordCount: number }[]> {
    const data = await this.fireRepo.readAll(Child.collectionName);
    return data.map((d) => {
      const child = Child.fromDataWithId(d);
      return { id: child.id ?? String(d.id ?? ''), wordCount: child.wordCount };
    });
  }

  /** Fetches utterance events (WordTracker firstUtterance) for a single child. */
  async getUtteranceEventsForChild(childId: string): Promise<UtteranceEvent[]> {
    const events: UtteranceEvent[] = [];

    const wordTrackers = await this.fireRepo.readAllFromSubcollection(
      Child.collectionName,
      childId,
      WordTracker.collectionName
    );
    for (const wtData of wordTrackers) {
      const wt = WordTracker.fromDataWithId(wtData);
      if (wt.firstUtterance && wt.firstUtterance.getTime() > 0) {
        events.push({ date: wt.firstUtterance, source: 'word', childId });
      }
    }

    return events;
  }

  /** Fetches all utterance events (WordTracker firstUtterance) across all children. */
  async getUtteranceEvents(): Promise<UtteranceEvent[]> {
    const events: UtteranceEvent[] = [];
    const children = await this.getChildren();

    for (const { id: childId } of children) {
      const childEvents = await this.getUtteranceEventsForChild(childId);
      events.push(...childEvents);
    }

    return events;
  }

  /** Aggregates events by day (YYYY-MM-DD). Returns sorted labels and counts. */
  aggregateByDay(events: UtteranceEvent[]): AggregatedUtterances {
    const byDay = new Map<string, number>();
    for (const e of events) {
      const key = e.date.toISOString().slice(0, 10);
      byDay.set(key, (byDay.get(key) ?? 0) + 1);
    }
    const labels = Array.from(byDay.keys()).sort();
    const counts = labels.map((label) => byDay.get(label) ?? 0);
    return { labels, counts };
  }
}
