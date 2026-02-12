import { inject, Injectable } from '@angular/core';
import {
  addDoc,
  collection,
  deleteDoc,
  doc,
  Firestore,
  getDocs,
  serverTimestamp
} from '@angular/fire/firestore';
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
  // Only fetch UserProfile collection for admin panel
  private readonly collectionNames = ['UserProfile'];

  // Fields to display for UserProfile documents 
  readonly userProfileDisplayFields = ['name', 'email', 'createdAt', 'role'];
  getAllItems(): Observable<FirestoreItem[]> {
    const observables = this.collectionNames.map((name) =>
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
    );

    return combineLatest(observables).pipe(
      map((results) => results.flat() as FirestoreItem[])
    );
  }
// Add a new document to a collection. 
  async addItem(
    collectionName: string,
    data: Record<string, unknown>
  ): Promise<string> {
    const colRef = collection(this.firestore, collectionName);
    const payload = { ...data };
    if (collectionName === 'UserProfile' && payload['createdAt'] === undefined) {
      payload['createdAt'] = serverTimestamp();
    }
    const ref = await addDoc(colRef, payload);
    return ref.id;
  }

  // Remove a document from a collection. 
  async removeItem(collectionName: string, docId: string): Promise<void> {
    const docRef = doc(this.firestore, collectionName, docId);
    await deleteDoc(docRef);
  }

  // Collection names available for admin (add/remove). 
  readonly adminCollectionNames = this.collectionNames;
}
