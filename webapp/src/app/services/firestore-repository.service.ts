import { Injectable } from '@angular/core';
import {
  Firestore,
  collection,
  getDocs,
  doc,
  getDoc,
  query
} from '@angular/fire/firestore';

export interface IFirestoreRepository {
  readAll(collectionName: string): Promise<any[]>;
  readAllFromSubcollection(
    parentCollection: string,
    parentId: string,
    subcollection: string
  ): Promise<any[]>;
  read(collectionName: string, id: string): Promise<any | null>;
}

@Injectable({ providedIn: 'root' })
export class FirestoreRepository implements IFirestoreRepository {
  constructor(private firestore: Firestore) {}

  async readAll(collectionName: string): Promise<any[]> {
    const snap = await getDocs(collection(this.firestore, collectionName));
    return snap.docs.map((d) => ({ id: d.id, ...(d.data() as any) }));
  }

  async readAllFromSubcollection(
    parentCollection: string,
    parentId: string,
    subcollection: string
  ): Promise<any[]> {
    const parentRef = doc(this.firestore, parentCollection, parentId);
    const q = query(collection(parentRef, subcollection));
    const snap = await getDocs(q);
    return snap.docs.map((d) => ({ id: d.id, ...(d.data() as any) }));
  }

  async read(collectionName: string, id: string): Promise<any | null> {
    const docRef = doc(this.firestore, collectionName, id);
    const snap = await getDoc(docRef);
    if (!snap.exists()) return null;
    return { id: snap.id, ...(snap.data() as any) };
  }
}
