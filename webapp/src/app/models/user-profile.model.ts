export interface DemographicData {
  gender: string | null;
  otherChildCare: string | null;
  otherParentEducation: string | null;
  childCareArrangements: string[];
  primaryLanguage: string;
  genderOther: string | null;
  educationLevel: string;
  childAges: string[];
  householdIncome: string;
  numberOfAdults: string;
  otherLanguages: string;
  completedAt: string;
  ageRange: string;
}

export interface UserProfileData {
  id?: string;
  role: string;
  surveyVersion: string | null;
  demographicData?: DemographicData;
  // Other fields can be added as needed
}

export class UserProfile implements UserProfileData {
  static collectionName = 'UserProfile';

  id?: string;
  role: string = 'parent';
  surveyVersion: string | null = null;
  demographicData?: DemographicData;

  static fromDataWithId(data: any): UserProfile {
    const profile = new UserProfile();
    profile.id = data.id as string | undefined;
    profile.role = String(data.role || 'parent');
    profile.surveyVersion = data.surveyVersion ? String(data.surveyVersion) : null;
    profile.demographicData = data.demographicData as DemographicData | undefined;
    return profile;
  }
}