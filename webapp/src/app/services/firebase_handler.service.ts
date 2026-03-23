import { inject, Injectable } from '@angular/core';
import {
  addDoc,
  collection,
  deleteDoc,
  doc,
  Firestore,
  getDoc,
  getDocs,
  serverTimestamp,
  updateDoc
} from '@angular/fire/firestore';
import { BehaviorSubject } from 'rxjs';
import { catchError, combineLatest, from, map, Observable, of } from 'rxjs';

export interface FirestoreItem {
  id: string;
  _collection: string;
  [key: string]: unknown;
}

@Injectable({
  providedIn: 'root'
})
export class FirebaseHandlerService {
  private readonly firestore = inject(Firestore);
  private readonly refresh$ = new BehaviorSubject(0);
  // Only fetch UserProfile collection for admin panel
  private readonly collectionNames = ['UserProfile'];

  /** Trigger a refresh of the items list (e.g. after edit). */
  refreshItems(): void {
    this.refresh$.next(this.refresh$.value + 1);
  }

  // All editable fields for UserProfile documents (admins can edit any)
  readonly userProfileDisplayFields = [
    'role', 'status', 'name', 'email', 'firstName', 'lastName',
    'phoneNumber', 'institution', 'emailVerified', 'twoFactorEnabled',
    'acceptedPrivacyPolicy', 'surveyCompleted', 'childIDs', 'preferredLanguage',
    'createdAt', 'updatedAt'
  ];
  getAllItems(): Observable<FirestoreItem[]> {
    const observables = [
      this.refresh$,
      ...this.collectionNames.map((name) =>
        from(getDocs(collection(this.firestore, name))).pipe(
        map((snapshot) =>
          snapshot.docs.map((doc) => ({
            id: doc.id,
            _collection: name,
            ...doc.data()
          }))
        ),
        catchError((err) => {
          console.error(`Firestore error loading collection "${name}":`, err);
          return of([]);
        })
      )
    )];

    return combineLatest(observables).pipe(
      map((results) => (results.slice(1) as unknown as FirestoreItem[][]).flat())
    );
  }

  /** Get a single UserProfile document by ID. */
  async getCurrentUserProfile(uid: string): Promise<{ role: string } | null> {
    const docRef = doc(this.firestore, 'UserProfile', uid);
    const snap = await getDoc(docRef);
    if (!snap.exists()) return null;
    const data = snap.data();
    return { role: (data?.['role'] as string) ?? 'parent' };
  }
// Add a new document to a collection. 
  async addItem(
    collectionName: string,
    data: Record<string, unknown>
  ): Promise<string> {
    const colRef = collection(this.firestore, collectionName);
    const payload = { ...data };
    if (collectionName === 'UserProfile') {
      const now = serverTimestamp();
      if (payload['createdAt'] === undefined) payload['createdAt'] = now;
      if (payload['updatedAt'] === undefined) payload['updatedAt'] = now;
    }
    const ref = await addDoc(colRef, payload);
    return ref.id;
  }

  // Remove a document from a collection. 
  async removeItem(collectionName: string, docId: string): Promise<void> {
    const docRef = doc(this.firestore, collectionName, docId);
    await deleteDoc(docRef);
  }

  /** Update a document. Used by admins to edit UserProfile fields. */
  async updateItem(
    collectionName: string,
    docId: string,
    updates: Record<string, unknown>
  ): Promise<void> {
    const docRef = doc(this.firestore, collectionName, docId);
    const payload = { ...updates };
    if (collectionName === 'UserProfile') {
      payload['updatedAt'] = serverTimestamp();
    }
    await updateDoc(docRef, payload);
  }

  // Collection names available for admin (add/remove). 
  readonly adminCollectionNames = this.collectionNames;
}
