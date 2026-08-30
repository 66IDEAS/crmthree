import { db, auth } from '../config/firebase';
import {
  collection,
  doc,
  getDoc,
  getDocs,
  setDoc,
  updateDoc,
  query,
  where,
  limit,
} from 'firebase/firestore';
import {
  signInWithEmailAndPassword,
  signInWithPopup,
  GoogleAuthProvider,
  signOut as firebaseSignOut,
} from 'firebase/auth';
import { v4 as uuidv4 } from 'uuid';
import { isEmailWhitelisted } from './WhitelistService';

const googleProvider = new GoogleAuthProvider();

const DEFAULT_PIPELINE_STAGES = [
  { name: 'Prospecting', sort_order: 1, default_probability: 10, is_closed: false, is_won: false, active: true },
  { name: 'Qualification', sort_order: 2, default_probability: 20, is_closed: false, is_won: false, active: true },
  { name: 'Needs Analysis', sort_order: 3, default_probability: 40, is_closed: false, is_won: false, active: true },
  { name: 'Proposal', sort_order: 4, default_probability: 60, is_closed: false, is_won: false, active: true },
  { name: 'Negotiation', sort_order: 5, default_probability: 80, is_closed: false, is_won: false, active: true },
  { name: 'Closed Won', sort_order: 6, default_probability: 100, is_closed: true, is_won: true, active: true },
  { name: 'Closed Lost', sort_order: 7, default_probability: 0, is_closed: true, is_won: false, active: true },
];

const ALL_RIBBON_ITEMS = [
  'Account', 'Contact', 'Lead', 'Opportunity', 'DealRoom', 'Quotation', 'SalesOrder',
  'Invoice', 'Product', 'Activity', 'Ticket', 'KnowledgeArticle', 'Asset',
  'SLA', 'ServiceContract',
];

const DEFAULT_ROLES = [
  {
    name: 'Admin',
    description: 'Full system access',
    is_system_role: true,
    permissions: { '*': { create: true, read: true, read_all: true, update: true, delete: true } },
    ribbon_items: ALL_RIBBON_ITEMS,
    visible_cards: null,
    layout_config: null,
    active: true,
  },
  {
    name: 'Manager',
    description: 'Team management with broad read access',
    is_system_role: true,
    permissions: { '*': { create: true, read: true, read_all: true, update: true, delete: false } },
    ribbon_items: [
      'Account', 'Contact', 'Lead', 'Opportunity', 'Quotation', 'SalesOrder',
      'Invoice', 'Activity', 'Ticket',
    ],
    visible_cards: null,
    layout_config: null,
    active: true,
  },
  {
    name: 'User',
    description: 'Standard user with own-record access',
    is_system_role: true,
    permissions: { '*': { create: true, read: true, read_all: false, update: true, delete: false } },
    ribbon_items: ['Account', 'Contact', 'Lead', 'Opportunity', 'Activity', 'Ticket'],
    visible_cards: null,
    layout_config: null,
    active: true,
  },
];

/**
 * Sign in with email and password.
 */
export async function signInWithEmail(email, password) {
  if (!auth) throw new Error('Firebase Auth is not configured');
  return signInWithEmailAndPassword(auth, email, password);
}

/**
 * Sign in with Google popup.
 */
export async function signInWithGoogle() {
  if (!auth) throw new Error('Firebase Auth is not configured');
  return signInWithPopup(auth, googleProvider);
}

/**
 * Sign out.
 */
export async function signOut() {
  if (!auth) return;
  return firebaseSignOut(auth);
}

/**
 * Fetch UserProfile by Firebase Auth UID.
 * Returns the profile document or null.
 */
export async function fetchUserProfile(authUid) {
  if (!db) return null;
  const q = query(
    collection(db, 'userProfiles'),
    where('auth_uid', '==', authUid),
    limit(1)
  );
  const snapshot = await getDocs(q);
  if (snapshot.empty) return null;
  const docSnap = snapshot.docs[0];
  return { id: docSnap.id, ...docSnap.data() };
}

/**
 * Fetch a Role document by ID.
 */
export async function fetchRole(roleId) {
  if (!db || !roleId) return null;
  const docSnap = await getDoc(doc(db, 'roles', roleId));
  if (!docSnap.exists()) return null;
  return { id: docSnap.id, ...docSnap.data() };
}

/**
 * Check if any UserProfile documents exist in Firestore.
 */
/**
 * Claim a pending UserProfile — one an admin created by email before the person
 * had ever signed in, so its auth_uid is still empty. Matched case-insensitively
 * on email; the uid is written to the profile and it becomes a normal profile.
 * Returns the claimed profile, or null when there is nothing to claim.
 */
export async function claimPendingProfile(firebaseUser) {
  if (!db || !firebaseUser?.email) return null;
  const email = firebaseUser.email.toLowerCase();
  const q = query(collection(db, 'userProfiles'), where('auth_uid', '==', ''));
  const snapshot = await getDocs(q);
  const match = snapshot.docs.find(
    (d) => (d.data().email || '').toLowerCase() === email
  );
  if (!match) return null;

  const now = new Date().toISOString();
  await updateDoc(doc(db, 'userProfiles', match.id), {
    auth_uid: firebaseUser.uid,
    avatar_url: firebaseUser.photoURL || match.data().avatar_url || '',
    updated_at: now,
  });
  return { id: match.id, ...match.data(), auth_uid: firebaseUser.uid };
}

async function hasAnyUsers() {
  if (!db) return false;
  const q = query(collection(db, 'userProfiles'), limit(1));
  const snapshot = await getDocs(q);
  return !snapshot.empty;
}

/**
 * Seed default roles if they don't exist.
 * Returns the Admin role document (with id).
 */
async function seedDefaultRoles() {
  if (!db) throw new Error('Firestore is not configured');
  let adminRole = null;

  for (const roleDef of DEFAULT_ROLES) {
    // Check if role already exists by name
    const q = query(
      collection(db, 'roles'),
      where('name', '==', roleDef.name),
      limit(1)
    );
    const snapshot = await getDocs(q);

    if (snapshot.empty) {
      const id = uuidv4();
      const now = new Date().toISOString();
      const roleDoc = {
        ...roleDef,
        id,
        created_at: now,
        updated_at: now,
      };
      await setDoc(doc(db, 'roles', id), roleDoc);
      if (roleDef.name === 'Admin') {
        adminRole = { id, ...roleDoc };
      }
    } else if (roleDef.name === 'Admin') {
      const d = snapshot.docs[0];
      adminRole = { id: d.id, ...d.data() };
    }
  }

  return adminRole;
}

/**
 * Seed default pipeline stages if they don't exist.
 */
async function seedDefaultPipelineStages() {
  if (!db) return;
  const q = query(collection(db, 'pipelineStages'), limit(1));
  const snapshot = await getDocs(q);
  if (!snapshot.empty) return; // Already seeded

  for (const stageDef of DEFAULT_PIPELINE_STAGES) {
    const id = uuidv4();
    const now = new Date().toISOString();
    await setDoc(doc(db, 'pipelineStages', id), {
      ...stageDef,
      id,
      created_at: now,
      updated_at: now,
    });
  }
}

/**
 * First-user setup: seeds roles, pipeline stages, and creates an Admin UserProfile.
 * Called when a user signs in but no UserProfile exists and no other users exist.
 */
export async function setupFirstUser(firebaseUser) {
  if (!db) throw new Error('Firestore is not configured');

  // Seed default roles and pipeline stages
  const [adminRole] = await Promise.all([
    seedDefaultRoles(),
    seedDefaultPipelineStages(),
  ]);

  // Create UserProfile
  const id = uuidv4();
  const now = new Date().toISOString();
  const profile = {
    id,
    auth_uid: firebaseUser.uid,
    email: firebaseUser.email,
    first_name: firebaseUser.displayName?.split(' ')[0] || '',
    last_name: firebaseUser.displayName?.split(' ').slice(1).join(' ') || '',
    role_id: adminRole.id,
    team_id: null,
    avatar_url: firebaseUser.photoURL || null,
    xp_total: 0,
    level: 1,
    level_name: 'Rookie',
    current_streak_days: 0,
    longest_streak_days: 0,
    active: true,
    theme_preference: 'System',
    notification_preferences: null,
    created_at: now,
    updated_at: now,
  };

  await setDoc(doc(db, 'userProfiles', id), profile);
  return { profile, role: adminRole };
}

/**
 * Fetches or creates a UserProfile for the given Firebase user.
 * On first-ever sign-in (no users exist), runs the first-user setup.
 * Returns { profile, role }.
 */
export async function resolveUserSession(firebaseUser) {
  // Check whitelist (empty whitelist = everyone allowed)
  const whitelisted = await isEmailWhitelisted(firebaseUser.email);

  // Try to find existing profile
  let profile = await fetchUserProfile(firebaseUser.uid);

  if (!profile) {
    // An admin may have invited this person by email before they ever signed in
    profile = await claimPendingProfile(firebaseUser);
  }

  if (!profile) {
    // Check if this is the very first user
    const anyUsersExist = await hasAnyUsers();
    if (!anyUsersExist) {
      // First-user setup — always allowed (whitelist is necessarily empty)
      return setupFirstUser(firebaseUser);
    }
    // Not whitelisted — reject
    if (!whitelisted) {
      return { profile: null, role: null, rejected: 'not_whitelisted' };
    }
    // Whitelisted but no profile — they need to be provisioned by an admin
    return { profile: null, role: null };
  }

  // Existing profile but not whitelisted (admin removed them from whitelist)
  if (!whitelisted) {
    return { profile: null, role: null, rejected: 'not_whitelisted' };
  }

  // Profile deactivated by an admin — keep the data, refuse the session
  if (profile.active === false) {
    return { profile: null, role: null, rejected: 'deactivated' };
  }

  // Fetch role
  const role = await fetchRole(profile.role_id);

  // Ensure pipeline stages exist
  seedDefaultPipelineStages().catch(() => {});

  // Ensure Admin role ribbon_items stays in sync with ALL_RIBBON_ITEMS
  if (role?.ribbon_items) {
    const missing = ALL_RIBBON_ITEMS.filter((item) => !role.ribbon_items.includes(item));
    if (missing.length > 0) {
      role.ribbon_items = [...role.ribbon_items, ...missing];
      updateDoc(doc(db, 'roles', role.id), {
        ribbon_items: role.ribbon_items,
        updated_at: new Date().toISOString(),
      }).catch(() => {});
    }
  }

  return { profile, role };
}
