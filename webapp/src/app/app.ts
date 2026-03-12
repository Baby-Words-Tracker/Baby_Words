import { AsyncPipe } from '@angular/common';
import { Component, HostListener, computed, inject, signal } from '@angular/core';
import { FormBuilder, ReactiveFormsModule, Validators } from '@angular/forms';
import { RouterOutlet } from '@angular/router';
import { toObservable } from '@angular/core/rxjs-interop';
import { combineLatest, from, map, of, switchMap, tap } from 'rxjs';
import { BaseChartDirective } from 'ng2-charts';
import { AuthService } from './services/auth.service';
import {
  FirestoreItem,
  FirebaseHandlerService
} from './services/firebase_handler.service';
import { CsvExportService } from './services/csv-export.service';
import { ResearchersDataService } from './services/researchers-data.service';

export interface CollectionGroup {
  collection: string;
  items: FirestoreItem[];
}

@Component({
  selector: 'app-root',
  imports: [AsyncPipe, ReactiveFormsModule, RouterOutlet, BaseChartDirective],
  templateUrl: './app.html',
  styleUrl: './app.css'
})
export class App {
  protected readonly title = signal('wordbuds');
  protected readonly authService = inject(AuthService);
  protected readonly firebaseService = inject(FirebaseHandlerService);
  protected readonly csvExport = inject(CsvExportService);
  protected readonly researchersData = inject(ResearchersDataService);
  protected readonly authState$ = this.authService.authState$;

  /** Resolves to { user, isAdmin } once profile is loaded. Non-admins cannot view dashboard. */
  protected readonly authWithRole$ = this.authState$.pipe(
    switchMap((user) =>
      user
        ? from(this.firebaseService.getCurrentUserProfile(user.uid)).pipe(
            map((p) => ({ user, isAdmin: p?.role === 'admin' }))
          )
        : of({ user: null as import('firebase/auth').User | null, isAdmin: false })
    )
  );

  protected readonly allItems$ = this.firebaseService.getAllItems();
  protected readonly sortMode = signal<'alphabetical' | 'createdAtNewest' | 'createdAtOldest'>('alphabetical');
  private readonly sortMode$ = toObservable(this.sortMode);
  protected readonly roleFilter = signal<'all' | 'parent' | 'admin' | 'researcher'>('all');
  private readonly roleFilter$ = toObservable(this.roleFilter);
  protected readonly selectedUserProfileId = signal<string | null>(null);
  private readonly selectedUserProfileId$ = toObservable(this.selectedUserProfileId);
  protected readonly showCreateUserModal = signal(false);

  protected readonly userProfiles$ = combineLatest([
    this.allItems$,
    this.sortMode$,
    this.roleFilter$
  ]).pipe(
    map(([items, sortMode, roleFilter]) => {
      const userProfiles = items.filter((item) => {
        if (item._collection !== 'UserProfile') return false;
        if (roleFilter === 'all') return true;
        const role = (item['role'] as string | undefined)?.toLowerCase() ?? '';
        return role === roleFilter;
      });

      const getDisplayName = (item: FirestoreItem): string => {
        const name = (item['name'] as string) ?? '';
        const firstName = (item['firstName'] as string) ?? '';
        const lastName = (item['lastName'] as string) ?? '';
        const email = (item['email'] as string) ?? '';
        const combinedName = `${firstName} ${lastName}`.trim();
        const display = (name || combinedName || email).trim();
        return display || email || '(No name)';
      };

      const getCreatedAtMs = (item: FirestoreItem): number => {
        const raw = item['createdAt'];
        if (!raw) return 0;
        if (typeof raw === 'object' && 'toDate' in (raw as { toDate?: () => Date })) {
          const date = (raw as { toDate: () => Date }).toDate();
          return date instanceof Date ? date.getTime() : 0;
        }
        if (typeof raw === 'number') return raw;
        const parsed = new Date(String(raw)).getTime();
        return Number.isNaN(parsed) ? 0 : parsed;
      };

      const sorted = [...userProfiles].sort((a, b) => {
        if (sortMode === 'alphabetical') {
          return getDisplayName(a).localeCompare(getDisplayName(b), undefined, {
            sensitivity: 'base'
          });
        }
        const aMs = getCreatedAtMs(a);
        const bMs = getCreatedAtMs(b);
        if (sortMode === 'createdAtNewest') {
          return bMs - aMs;
        }
        // createdAtOldest
        return aMs - bMs;
      });

      return sorted;
    }),
    tap((profiles) => {
      if (!profiles.length) {
        this.selectedUserProfileId.set(null);
        return;
      }
      const currentId = this.selectedUserProfileId();
      if (!currentId || !profiles.some((p) => p.id === currentId)) {
        this.selectedUserProfileId.set(profiles[0]?.id ?? null);
      }
    })
  );

  protected readonly selectedUserProfile$ = combineLatest([
    this.userProfiles$,
    this.selectedUserProfileId$
  ]).pipe(
    map(([profiles, selectedId]) =>
      profiles.find((p) => p.id === selectedId) ?? null
    )
  );

  protected readonly itemsByCollection$ = this.allItems$.pipe(
    map((items) => {
      const groups = new Map<string, FirestoreItem[]>();
      for (const item of items) {
        const col = item._collection;
        if (!groups.has(col)) groups.set(col, []);
        groups.get(col)!.push(item);
      }
      return Array.from(groups.entries()).map(([collection, groupItems]) => ({
        collection,
        items: groupItems
      }));
    })
  );
  protected readonly expandedCollections = signal<Set<string>>(
    new Set(['UserProfile'])
  );

  protected readonly currentView = signal<'dashboard' | 'admin' | 'researchers'>('dashboard');
  protected readonly showViewDropdown = signal(false);
  protected readonly adminAddMessage = signal<string | null>(null);
  protected readonly exportMessage = signal<string | null>(null);
  protected readonly adminRemoveMessage = signal<string | null>(null);
  /** ID of the UserProfile item currently in edit mode, or null if none. */
  protected readonly editingProfileId = signal<string | null>(null);

  protected readonly researchersChildrenList = signal<{ id: string; wordCount: number }[]>([]);
  protected readonly researchersChildrenLoading = signal(false);
  protected readonly selectedResearcherChildId = signal<string | null>(null);
  protected readonly researchersChildrenSort = signal<'wordCountDesc' | 'wordCountAsc'>('wordCountDesc');
  protected readonly researchersChildrenSorted = computed(() => {
    const sortMode = this.researchersChildrenSort();
    const list = this.researchersChildrenList();
    return [...list].sort((a, b) => {
      if (sortMode === 'wordCountAsc') return a.wordCount - b.wordCount;
      return b.wordCount - a.wordCount;
    });
  });
  protected readonly researchersLoading = signal(false);
  protected readonly researchersChartData = signal<{ labels: string[]; datasets: { label: string; data: number[] }[] }>({
    labels: [],
    datasets: [{ label: 'Utterances', data: [] }]
  });

  protected setView(view: 'dashboard' | 'admin' | 'researchers'): void {
    this.currentView.set(view);
    this.showViewDropdown.set(false);
    this.adminAddMessage.set(null);
    this.adminRemoveMessage.set(null);
    this.editingProfileId.set(null);
    if (view !== 'admin') {
      this.selectedUserProfileId.set(null);
    }
    if (view === 'researchers') {
      this.selectedResearcherChildId.set(null);
      this.researchersChartData.set({ labels: [], datasets: [{ label: 'Utterances', data: [] }] });
      this.loadResearchersChildrenList();
    }
  }

  protected readonly researchersChartOptions = {
    responsive: true,
    maintainAspectRatio: true,
    plugins: {
      title: { display: true, text: 'Utterances over time' }
    },
    scales: {
      y: { beginAtZero: true, ticks: { stepSize: 1 } }
    }
  };

  protected async loadResearchersChildrenList(): Promise<void> {
    this.researchersChildrenLoading.set(true);
    try {
      const children = await this.researchersData.getChildrenWithWordCount();
      this.researchersChildrenList.set(children);
    } catch (e) {
      console.error('Researchers children list load failed:', e);
      this.researchersChildrenList.set([]);
    } finally {
      this.researchersChildrenLoading.set(false);
    }
  }

  protected setResearchersChildrenSort(sort: 'wordCountDesc' | 'wordCountAsc'): void {
    this.researchersChildrenSort.set(sort);
  }

  protected selectResearcherChild(childId: string): void {
    this.selectedResearcherChildId.set(childId);
    this.loadResearchersChartData(childId);
  }

  protected async loadResearchersChartData(childId: string): Promise<void> {
    this.researchersLoading.set(true);
    try {
      const events = await this.researchersData.getUtteranceEventsForChild(childId);
      const { labels, counts } = this.researchersData.aggregateByDay(events);
      this.researchersChartData.set({
        labels,
        datasets: [{ label: 'Utterances', data: counts }]
      });
    } catch (e) {
      console.error('Researchers chart load failed:', e);
      this.researchersChartData.set({ labels: [], datasets: [{ label: 'Utterances', data: [] }] });
    } finally {
      this.researchersLoading.set(false);
    }
  }

  protected setSortMode(mode: 'alphabetical' | 'createdAtNewest' | 'createdAtOldest'): void {
    this.sortMode.set(mode);
  }

  protected setRoleFilter(role: 'all' | 'parent' | 'admin' | 'researcher'): void {
    this.roleFilter.set(role);
  }

  protected toggleViewDropdown(): void {
    this.showViewDropdown.update((v) => !v);
  }

  @HostListener('document:click')
  protected onDocumentClick(): void {
    if (this.showViewDropdown()) this.showViewDropdown.set(false);
  }

  protected readonly adminAddForm = inject(FormBuilder).group({
    collectionName: ['UserProfile'],
    firstName: [''],
    lastName: [''],
    phoneNumber: [''],
    email: ['', [Validators.required, Validators.email]],
    role: ['']
  });

  protected async addAccount(): Promise<void> {
    this.adminAddMessage.set(null);
    const { collectionName, firstName, lastName, phoneNumber, email, role } = this.adminAddForm.value;
    if (!collectionName || !email || this.adminAddForm.invalid) return;
    const roleVal = role?.trim() ? role.trim().toLowerCase() : 'parent';
    const validRoles = ['admin', 'researcher', 'parent'];
    const finalRole = validRoles.includes(roleVal) ? roleVal : 'parent';
    try {
      await this.firebaseService.addItem(collectionName, {
        role: finalRole,
        status: 'active',
        email: email.trim(),
        name: `${(firstName ?? '').trim()} ${(lastName ?? '').trim()}`.trim() || null,
        firstName: firstName?.trim() || null,
        lastName: lastName?.trim() || null,
        phoneNumber: phoneNumber?.trim() || null,
        institution: null,
        emailVerified: false,
        twoFactorEnabled: false,
        twoFactorEnabledAt: null,
        acceptedPrivacyPolicy: false,
        policyVersion: null,
        consentDate: null,
        surveyCompleted: false,
        surveyVersion: null,
        surveyCompletedAt: null,
        childIDs: [],
        preferredLanguage: null
      });
      this.firebaseService.refreshItems();
      this.adminAddForm.patchValue({ firstName: '', lastName: '', phoneNumber: '', email: '', role: '' });
      this.adminAddMessage.set('Account added successfully.');
      this.showCreateUserModal.set(false);
    } finally {
      // after account add we could optionally clear exportMessage
      this.exportMessage.set(null);
    }
  }

  protected async exportAllWords(): Promise<void> {
    this.exportMessage.set(null);
    try {
      const ok = await this.csvExport.exportAllWordsToCSV();
      this.exportMessage.set(ok ? 'Export started' : 'Nothing to export');
    } catch (e) {
      this.exportMessage.set(e instanceof Error ? e.message : 'Export failed');
    }
  }
  // remove account not allowed according to firebase rules
  // protected async removeAccount(collectionName: string, docId: string): Promise<void> {
  //   this.adminRemoveMessage.set(null);
  //   try {
  //     await this.firebaseService.removeItem(collectionName, docId);
  //     this.adminRemoveMessage.set('Account removed.');
  //   } catch (err) {
  //     this.adminRemoveMessage.set(
  //       err instanceof Error ? err.message : 'Failed to remove account'
  //     );
  //   }
  // }


  protected toggleCollection(name: string): void {
    this.expandedCollections.update((set) => {
      const next = new Set(set);
      if (next.has(name)) next.delete(name);
      else next.add(name);
      return next;
    });
  }

  protected isExpanded(name: string): boolean {
    return this.expandedCollections().has(name);
  }

  protected startEditingProfile(item: FirestoreItem): void {
    if (item._collection === 'UserProfile' && item.id) this.editingProfileId.set(item.id);
  }

  protected stopEditingProfile(): void {
    this.editingProfileId.set(null);
  }

  protected isEditingProfile(item: FirestoreItem): boolean {
    return item._collection === 'UserProfile' && item.id === this.editingProfileId();
  }

  protected selectUserProfile(item: FirestoreItem): void {
    if (item._collection !== 'UserProfile' || !item.id) return;
    this.selectedUserProfileId.set(item.id);
    this.stopEditingProfile();
  }

  protected isSelectedUserProfile(item: FirestoreItem): boolean {
    return item._collection === 'UserProfile' && item.id === this.selectedUserProfileId();
  }

  protected openCreateUserModal(): void {
    this.showCreateUserModal.set(true);
    this.adminAddMessage.set(null);
  }

  protected closeCreateUserModal(): void {
    this.showCreateUserModal.set(false);
  }

  protected readonly errorMessage = signal<string | null>(null);

  protected readonly loginForm = inject(FormBuilder).group({
    email: ['', [Validators.required, Validators.email]],
    password: ['', Validators.required]
  });
  // TODO Check if this is secure, I imagine the password passed as a string is not good.
  protected async login(): Promise<void> {
    this.errorMessage.set(null);
    const { email, password } = this.loginForm.value;
    if (!email || !password || this.loginForm.invalid) return;
    try {
      await this.authService.login(email, password);
      this.loginForm.reset();
    } catch (err) {
      this.errorMessage.set(err instanceof Error ? err.message : 'Login failed');
    }
  }

  protected logout(): void {
    this.authService.logout();
  }

  protected getDisplayEntries(item: FirestoreItem): [string, any][] {
    const allowed =
      item._collection === 'UserProfile'
        ? this.firebaseService.userProfileDisplayFields
        : null;
    return Object.entries(item).filter(
      ([key]) =>
        key !== '_collection' &&
        (allowed === null || allowed.includes(key))
    );
  }

  protected handleFieldEditBlur(
    item: FirestoreItem,
    field: string,
    newValue: string,
    inputEl: HTMLInputElement
  ): void {
    const original = this.formatValue(item[field]);
    if (newValue === original) return;
    if (!confirm('Are you sure you want to save this change?')) {
      inputEl.value = original;
      return;
    }
    this.saveFieldEdit(item, field, newValue);
  }

  protected async saveFieldEdit(
    item: FirestoreItem,
    field: string,
    newValue: string
  ): Promise<void> {
    if (item._collection !== 'UserProfile' || !item.id) return;
    let parsed: any = newValue;
    const raw = item[field];
    if (typeof raw === 'boolean') parsed = newValue === 'true';
    else if (Array.isArray(raw)) {
      try {
        parsed = JSON.parse(newValue || '[]');
      } catch {
        return;
      }
    }
    try {
      await this.firebaseService.updateItem(item._collection, item.id, {
        [field]: parsed
      });
      this.firebaseService.refreshItems();
      (item as Record<string, any>)[field] = parsed;
    } catch (err) {
      console.error('Failed to update:', err);
    }
  }

  protected formatValue(value: any): string {
    if (value == null) return '';
    if (typeof value === 'object' && 'toDate' in value && typeof (value as { toDate: () => Date }).toDate === 'function') {
      return (value as { toDate: () => Date }).toDate().toLocaleString();
    }
    if (Array.isArray(value)) return JSON.stringify(value);
    if (typeof value === 'boolean') return value ? 'true' : 'false';
    return String(value);
  }

  protected getUserDisplayName(item: FirestoreItem): string {
    const name = (item['name'] as string) ?? '';
    const firstName = (item['firstName'] as string) ?? '';
    const lastName = (item['lastName'] as string) ?? '';
    const email = (item['email'] as string) ?? '';
    const combinedName = `${firstName} ${lastName}`.trim();
    const display = (name || combinedName || email).trim();
    return display || email || '(No name)';
  }

  protected isEditableType(value: any): boolean {
    if (value == null) return true;
    if (typeof value === 'object' && 'toDate' in value) return false; // Timestamps read-only
    return typeof value === 'string' || typeof value === 'boolean' || Array.isArray(value);
  }
}
