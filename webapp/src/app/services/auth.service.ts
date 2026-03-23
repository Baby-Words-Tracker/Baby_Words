import { inject, Injectable } from '@angular/core';
import {
  Auth,
  authState,
  signInWithEmailAndPassword,
  signOut
} from '@angular/fire/auth';
import { Observable } from 'rxjs';

@Injectable({
  providedIn: 'root'
})
export class AuthService {
  private readonly auth = inject(Auth);

  readonly authState$: Observable<import('firebase/auth').User | null> =
    authState(this.auth);

  login(email: string, password: string): Promise<import('firebase/auth').UserCredential> {
    return signInWithEmailAndPassword(this.auth, email, password);
  }

  logout(): Promise<void> {
    return signOut(this.auth);
  }
}
