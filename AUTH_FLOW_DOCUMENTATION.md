# Authentication Flow Documentation

## Overview

The CarPool Management app implements a **mock authentication system** with role-based access control (RBAC). The authentication layer is built with:
- **Riverpod** for state management (`AuthNotifier` and `authStateProvider`)
- **Isar** local database for storing user data offline
- **Firebase Auth** integration ready (currently mocked for development)

---

## Architecture

### Authentication Stack

```
┌─────────────────────────────────────┐
│  UI Layer                           │
│  (Splash, Login, Profile Pages)     │
└────────────┬────────────────────────┘
             │
┌────────────▼────────────────────────┐
│  Riverpod State Management          │
│  (AuthNotifier + authStateProvider) │
└────────────┬────────────────────────┘
             │
┌────────────▼────────────────────────┐
│  Domain Layer                       │
│  (AuthRepository interface)         │
└────────────┬────────────────────────┘
             │
┌────────────▼────────────────────────┐
│  Data Layer                         │
│  (AuthRepositoryImpl)                │
└────────────┬────────────────────────┘
             │
┌────────────▼────────────────────────┐
│  Isar Local Database                │
│  (UserModel collection)             │
└─────────────────────────────────────┘
```

---

## Mock Credentials

The app provides two pre-configured accounts for testing:

### Admin Account
- **Email**: `admin@carpool.com`
- **Password**: `admin123`
- **Role**: `admin`
- **Capabilities**: 
  - Approve/reject settlements
  - View audit logs
  - Manage all members
  - Generate reports
  - Access admin dashboard

### Member Account
- **Email**: `member@carpool.com`
- **Password**: `member123`
- **Role**: `member`
- **Capabilities**:
  - Create and manage own trips
  - Add expenses
  - View settlements
  - Manage profile

---

## Authentication Flow Sequence

### 1. App Launch → Splash Screen
```dart
// main.dart
main() {
  ProviderScope(
    child: MyApp(), // Renders Splash via GoRouter
  )
}
```

**What happens**:
- App initializes ProviderScope (Riverpod dependency injection)
- GoRouter's `redirect()` evaluates `authStateProvider`
- Routes to `SplashPage` (animated loading screen)

### 2. Splash Screen Checks Auth State
```dart
// splash_page.dart (after 2 seconds)
void _checkAuthentication() {
  final authState = ref.read(authStateProvider);
  
  if (authState.isAuthenticated) {
    context.pushNamed('home');  // User already logged in
  } else {
    context.pushNamed('login');  // Show login form
  }
}
```

**What happens**:
- Reads current user from local database via `authStateProvider`
- If user found → redirect to Home (authenticated state)
- If no user → redirect to Login (unauthenticated state)

### 3. Login Page - User Enters Credentials
```dart
// login_page.dart
void _performLogin(String email, String password) async {
  await ref.read(authStateProvider.notifier).login(
    email: email,
    password: password,
  );
  context.pushNamed('home');
}
```

**What happens**:
- User taps "Sign In" button
- Calls `AuthNotifier.login(email, password)` (StateNotifier)
- `login()` calls `AuthRepository.login()` (domain layer)
- `AuthRepositoryImpl` validates against mock credentials
- If valid → creates/updates user in Isar database
- Sets `isCurrentUser = true` for this account
- Returns `UserEntity` to domain layer
- Notifier updates state: `state.user = userEntity`

### 4. Router Evaluates New Auth State
```dart
// app_router.dart
redirect: (context, state) {
  final isAuthenticated = authState.isAuthenticated;
  
  if (isAuthenticated && location == '/login') {
    return '/home';  // Redirect to home
  }
}
```

**What happens**:
- GoRouter watches `authStateProvider`
- Detects state change (user is now set)
- Evaluates redirect logic
- Since user is authenticated and location is /login
- Automatically redirects to /home

### 5. Home Page with Role-Based Navigation
```dart
// home_page.dart (to be implemented)
@override
Widget build(BuildContext context, WidgetRef ref) {
  final authState = ref.watch(authStateProvider);
  
  if (authState.isAdmin) {
    return AdminDashboard();
  } else if (authState.isMember) {
    return MemberDashboard();
  }
}
```

**What happens**:
- Home page checks user role from `authState.user.role`
- Renders role-appropriate UI
- Admin sees: settlements management, audit logs, member management
- Member sees: trips, expenses, settlements

### 6. Profile/Settings Page - Logout
```dart
// profile_page.dart
void _logout(BuildContext context, WidgetRef ref) async {
  await ref.read(authStateProvider.notifier).logout();
  context.pushNamed('login');
}
```

**What happens**:
- User taps "Logout" button
- Calls `AuthNotifier.logout()`
- Sets `isCurrentUser = false` in Isar database
- Clears state: `state = AuthState()` (user = null)
- GoRouter detects unauthenticated state
- Automatically redirects to /login

---

## AuthState Model

```dart
class AuthState {
  final UserEntity? user;           // Currently logged-in user
  final bool isLoading;             // During login/logout
  final String? error;              // Login error message
  
  bool get isAuthenticated => user != null;
  bool get isAdmin => user?.role == 'admin';
  bool get isMember => user?.role == 'member';
}
```

### State Transitions

```
[Initial]
  ↓ (app launch)
isAuthenticated: false, user: null
  ↓
[Splash checks auth]
  ├─ If local user found → isAuthenticated: true, user: UserEntity
  └─ If no local user → stays false
  ↓
[Login Page]
  ├─ Valid credentials → isAuthenticated: true, user: UserEntity
  └─ Invalid credentials → error: "Invalid email or password"
  ↓
[Home Page]
  (User navigates, data operations)
  ↓
[Logout]
  ├─ Clear user state → isAuthenticated: false, user: null
  └─ Redirect to login
```

---

## File Structure

```
lib/features/auth/
├── domain/
│   ├── entities/
│   │   └── user_entity.dart              # Pure domain model
│   └── repositories/
│       └── auth_repository.dart          # Abstract interface
├── data/
│   ├── models/
│   │   └── user_model.dart               # Data transfer object
│   └── repositories/
│       └── auth_repository_impl.dart     # Implementation with mock auth
└── presentation/
    ├── providers/
    │   └── auth_state_provider.dart      # Riverpod state management
    └── pages/
        ├── splash_page.dart              # Initial loading screen
        ├── login_page.dart               # Credentials entry + quick login
        └── profile_page.dart             # User info + logout

lib/routes/
├── app_router.dart                       # GoRouter with auth redirects
└── route_names.dart                      # Route constants
```

---

## Role-Based Access Control (RBAC)

### Admin Permissions
```dart
if (authState.isAdmin) {
  // Access denied without admin role
  // Show admin-only features
}
```

Features:
- Approve/reject settlements
- View audit logs for all users
- Add/remove members
- Generate reports
- View all trips across team

### Member Permissions
```dart
if (authState.isMember) {
  // Standard member access
}
```

Features:
- Create own trips
- Add expenses to trips
- View personal settlements
- View team members
- Manage own profile

### Protected Routes (Future)
```dart
GoRoute(
  path: '/admin/settlements',
  builder: (context, state) => SettlementApprovalPage(),
  redirect: (context, state) {
    final authState = ref.watch(authStateProvider);
    if (!authState.isAdmin) {
      return '/home';  // Non-admins redirected to home
    }
    return null;
  },
)
```

---

## Mock Authentication Implementation

### Login with Mock Credentials
```dart
// auth_repository_impl.dart
Future<UserEntity> login(String email, String password) async {
  if (email == 'admin@carpool.com' && password == 'admin123') {
    return await _createOrUpdateMockUser(
      email: email,
      name: 'Admin User',
      role: 'admin',
    );
  }
  if (email == 'member@carpool.com' && password == 'member123') {
    return await _createOrUpdateMockUser(
      email: email,
      name: 'Regular Member',
      role: 'member',
    );
  }
  throw ValidationError(message: 'Invalid email or password');
}
```

### Offline-First User Storage
```dart
// UserModel stored in Isar with:
String userId           // Cloud ID (Firebase)
String email            // Unique email
String name             // Display name
String role             // admin | member
bool isActive           // Account status
bool isCurrentUser      // Currently logged in (only 1 at a time)
DateTime lastLoginAt    // Track last access
```

---

## Firebase Integration (Future)

When ready to migrate to Firebase Auth:

```dart
// Will replace mock auth:
class AuthRepositoryImpl implements AuthRepository {
  final FirebaseAuth _firebaseAuth;
  
  @override
  Future<UserEntity> login(String email, String password) async {
    final userCredential = await _firebaseAuth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    // Fetch user profile from Firestore
    final userDoc = await _firestore.collection('users')
        .doc(userCredential.user!.uid)
        .get();
    // Map to local database
    // Return UserEntity
  }
}
```

---

## Quick Login Feature

Login page displays quick-access buttons for demo accounts:

```dart
// login_page.dart
AppButton(
  label: 'Login as Admin',
  onPressed: () => _quickLogin('admin@carpool.com', 'admin123'),
)

AppButton(
  label: 'Login as Member',
  onPressed: () => _quickLogin('member@carpool.com', 'member123'),
)
```

**Use case**: Quickly switch between roles for testing

---

## Error Handling

### Login Errors
```dart
try {
  await authStateProvider.notifier.login(email, password);
} catch (e) {
  // Shows snackbar: "Login failed: Invalid email or password"
  context.showErrorSnackbar('Login failed: ${e.toString()}');
}
```

### Auth State Errors
```dart
final authState = ref.watch(authStateProvider);

if (authState.error != null) {
  // Display error message in login page
  Text(authState.error!)
}
```

---

## Testing the Flow

### Test Login as Admin
1. Launch app → Splash (2 seconds)
2. Tap "Login as Admin" quick button
3. Redirected to Home
4. Check Profile: shows "Admin User", "admin" role
5. Can access admin features
6. Tap Logout → back to Login

### Test Login as Member
1. Launch app → Splash (2 seconds)
2. Tap "Login as Member" quick button
3. Redirected to Home
4. Check Profile: shows "Regular Member", "member" role
5. Can access member features
6. Tap Logout → back to Login

### Test Persistent Login
1. Login as Admin
2. Go to Home → navigate between pages
3. Kill app (close completely)
4. Relaunch app
5. Splash checks local database
6. Finds stored user → goes directly to Home (no login needed!)

### Test Multiple Accounts
1. Login as Admin
2. Go to Profile → Logout
3. Login as Member (same device)
4. Check: `isCurrentUser = true` only for Member
5. Logout → Login as Admin again
6. Previous session is restored

---

## Key Design Decisions

### 1. **Offline-First**
- User stored in Isar local database
- Works without internet connection
- Sync metadata tracks cloud sync status

### 2. **Single Current User**
- Only one account can be "current" at a time
- Logout clears current user flag
- Prevents session conflicts

### 3. **State Notifier Pattern**
- Centralized auth state in `AuthNotifier`
- Single source of truth via Riverpod
- Easy to watch changes across widgets

### 4. **Role-Based Rendering**
- UI checks `isAdmin`, `isMember` getters
- Different dashboards for different roles
- Protected routes handled by GoRouter redirects

### 5. **Mock for Development**
- Hardcoded credentials for easy testing
- No backend dependency during dev
- Seamless swap to Firebase Auth later

---

## Summary

The authentication system provides:
✅ Mock login with admin/member roles
✅ Offline-first user storage (Isar)
✅ Splash screen with auto-redirect
✅ Role-based UI and features
✅ Quick login buttons for testing
✅ Profile/logout page
✅ Persistent login across restarts
✅ Proper error handling
✅ GoRouter integration with auth guards
✅ Ready for Firebase Auth migration
