# Goa Maps

A Flutter-based mobile application for discovering and navigating cultural heritage sites in Goa, India. Features an interactive map with radius-based filtering, multi-stop route planning, turn-by-turn navigation, and real-time data synchronization with Supabase.

---

## Table of Contents

- [Features](#features)
- [Tech Stack](#tech-stack)
- [Prerequisites](#prerequisites)
- [Getting Started](#getting-started)
- [Project Structure](#project-structure)
- [Architecture](#architecture)
- [Supabase Setup](#supabase-setup)
- [Key Concepts](#key-concepts)
- [Screens Overview](#screens-overview)
- [Configuration](#configuration)
- [Building for Production](#building-for-production)

---

## Features

- Interactive OpenStreetMap with location markers for cultural heritage sites
- Radius-based filtering (1 km / 2 km / 5 km / 10 km) around user's location
- Multi-stop route planning with up to 3 intermediate stops via OSRM
- Turn-by-turn navigation with auto-rerouting
- Category filtering (Churches, Forts, Beaches, Museums, Heritage, etc.)
- Real-time data sync — locations added by admins appear for all users instantly
- Admin panel for managing locations (add, edit, delete) and user roles
- Image upload to Supabase Storage
- Reverse geocoding to show current place name
- Role-based access control (user vs admin)

---

## Tech Stack

| Layer              | Technology                                      |
| ------------------ | ----------------------------------------------- |
| Framework          | Flutter (Dart 3.9+)                             |
| Backend / Auth     | Supabase (Auth + PostgreSQL + Storage)          |
| State Management   | Provider (ChangeNotifier pattern)               |
| Map                | flutter_map (OpenStreetMap) + CartoDB Voyager    |
| Geocoding          | Nominatim (OpenStreetMap)                       |
| Routing            | OSRM (Open Source Routing Machine)              |
| Navigation         | GoRouter (role-based redirects)                 |
| Fonts              | Google Fonts (Inter, Oswald)                    |

---

## Prerequisites

Before you begin, ensure you have the following installed:

1. **Flutter SDK 3.9+** — [Install Flutter](https://docs.flutter.dev/get-started/install)
2. **Dart 3.9+** (comes with Flutter)
3. **Android Studio** or **VS Code** with Flutter extensions
4. **Git** for version control
5. A **Supabase account** — [Sign up free](https://supabase.com)
6. An Android device or emulator (API 21+)

Verify your setup:
```bash
flutter doctor
```

---

## Getting Started

### 1. Clone the Repository

```bash
git clone <repository-url>
cd final-year-main
```

### 2. Install Dependencies

```bash
flutter pub get
```

### 3. Set Up Supabase

See the [Supabase Setup](#supabase-setup) section below for full instructions on creating tables, storage, and RLS policies.

### 4. Configure Supabase Credentials

Open `lib/main.dart` and update the Supabase URL and anon key with your own project credentials:

```dart
await Supabase.initialize(
  url: 'https://YOUR_PROJECT.supabase.co',
  anonKey: 'YOUR_ANON_KEY',
);
```

### 5. Run the App

```bash
flutter run
```

### 6. Generate App Icons (Optional)

The app uses `flutter_launcher_icons` to generate launcher icons from `assets/logo.png`:

```bash
dart run flutter_launcher_icons
```

---

## Project Structure

```
lib/
├── main.dart                          # App entry point, Supabase init, Provider tree
│
└── src/
    ├── routing/
    │   └── app_router.dart            # GoRouter config with auth guards & role-based redirects
    │
    ├── services/
    │   ├── auth_service.dart          # Supabase Auth wrapper (sign up, sign in, roles)
    │   ├── geocoding_service.dart     # Nominatim reverse/forward geocoding
    │   ├── routing_service.dart       # OSRM multi-point route fetching
    │   └── image_upload_service.dart  # Image upload to Supabase Storage
    │
    ├── providers/
    │   ├── location_provider.dart     # GPS tracking + Supabase real-time location stream
    │   └── map_state_provider.dart    # All map UI state: search, radius, routes, navigation
    │
    ├── models/
    │   ├── location_model.dart        # Cultural site data (id, name, lat/lng, images, category)
    │   ├── user_model.dart            # User profile (uid, email, role, username, createdAt)
    │   ├── waypoint_model.dart        # Route waypoint (latLng + name)
    │   └── route_step_model.dart      # Turn-by-turn route step instructions
    │
    ├── screens/
    │   ├── main_screen.dart           # Bottom nav shell (Map, History, AI, Profile tabs)
    │   ├── map_screen.dart            # Core map view with markers, overlays, route polyline
    │   ├── onboarding_screen.dart     # Login / Signup forms
    │   ├── profile_screen.dart        # User profile display + logout
    │   ├── history_screen.dart        # Searchable list of all locations
    │   ├── ai_screen.dart             # Placeholder for AI features
    │   ├── edit_profile_screen.dart   # Edit username / photo
    │   ├── admin_home_screen.dart     # Admin dashboard with grid menu
    │   └── admin/
    │       ├── content_upload_screen.dart   # Add new location + image upload
    │       ├── edit_content_screen.dart     # List locations, tap to edit
    │       ├── detailed_edit_screen.dart    # Edit/delete a single location
    │       └── user_management_screen.dart  # View users, change roles
    │
    ├── widgets/
    │   ├── location_card.dart              # Location card for list views
    │   ├── location_detail_sheet.dart      # Bottom sheet for location details
    │   ├── admin/
    │   │   ├── admin_search_bar.dart       # Reusable search input
    │   │   ├── admin_back_button.dart      # Reusable back button
    │   │   ├── admin_scaffold.dart         # Background pattern wrapper
    │   │   └── category_dropdown.dart      # Category selection dropdown
    │   └── map/
    │       ├── search_bar_widget.dart       # Location search overlay
    │       ├── radius_selector_widget.dart  # 1/2/5/10 km dropdown + nearby count
    │       ├── location_name_chip.dart      # Reverse-geocoded current place name
    │       ├── category_chips_widget.dart   # Category filter chips
    │       ├── map_controls.dart            # Zoom and location buttons
    │       ├── map_markers.dart             # Map marker builder
    │       ├── navigation_bar_widget.dart   # Turn-by-turn navigation display
    │       ├── route_info_bar.dart          # Direction panel (route planner + info)
    │       └── search_bar_widget.dart       # Map search bar
    │
    ├── constants/
    │   └── categories.dart            # 11 predefined location categories
    │
    └── theme/
        └── theme.dart                 # Material 3 light/dark themes, teal color scheme

assets/
├── logo.png                           # App logo (used as launcher icon and in-app)
├── images/                            # Background patterns, placeholders
└── images/categories/                 # Category icon images
```

---

## Architecture

### State Management (Provider Pattern)

The app uses Flutter's `Provider` package with `ChangeNotifier` for reactive state:

```
main.dart (Provider Tree)
├── ThemeProvider         — Light/dark theme toggle
├── AuthService           — Supabase auth (not a ChangeNotifier)
├── LocationProvider      — GPS position + location database
├── MapStateProvider      — Map search, routing, navigation, filters
├── ValueNotifier<int>    — Current tab index
└── ValueNotifier<LocationModel?> — Selected location
```

### Data Flow

1. **User opens app** → `OnboardingScreen` checks auth state
2. **Login/Signup** → `AuthService` → Supabase Auth + `users` table
3. **Redirect** → GoRouter sends admin to `/admin`, users to `/map`
4. **Map loads** → `LocationProvider` starts GPS + Supabase real-time stream
5. **User interacts** → `MapStateProvider` handles search, routes, filters
6. **Admin adds content** → `ImageUploadService` uploads images → `LocationProvider` adds to database
7. **Real-time sync** → All connected clients see new locations instantly

### Navigation (GoRouter)

| Path                         | Screen              | Access |
| ---------------------------- | ------------------- | ------ |
| `/`                          | OnboardingScreen    | Public |
| `/map`                       | MainScreen (4 tabs) | User   |
| `/admin`                     | AdminHomeScreen     | Admin  |
| `/admin/content-upload`      | ContentUploadScreen | Admin  |
| `/admin/edit-content`        | EditContentScreen   | Admin  |
| `/admin/edit-content/:docId` | DetailedEditScreen  | Admin  |
| `/admin/user-management`     | UserManagementScreen| Admin  |
| `/admin/edit-profile`        | EditProfileScreen   | Admin  |

---

## Supabase Setup

### 1. Create a Supabase Project

Go to [supabase.com](https://supabase.com), create a new project, and note your:
- **Project URL** (e.g., `https://xxxx.supabase.co`)
- **Anon Key** (found in Settings > API)

### 2. Create Database Tables

Run the following SQL in the Supabase SQL Editor:

```sql
-- Users table
CREATE TABLE public.users (
  id UUID PRIMARY KEY REFERENCES auth.users(id),
  email TEXT NOT NULL,
  username TEXT NOT NULL,
  role TEXT NOT NULL DEFAULT 'user',
  photo_url TEXT DEFAULT '',
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Content table (locations)
CREATE TABLE public.content (
  id SERIAL PRIMARY KEY,
  title TEXT NOT NULL,
  description TEXT,
  "longDescription" TEXT,
  latitude NUMERIC,
  longitude NUMERIC,
  "imageUrl" TEXT,
  images JSONB DEFAULT '[]',
  category TEXT,
  "howTo" TEXT,
  "whatTo" TEXT,
  "createdAt" TEXT
);
```

### 3. Set Up Row Level Security (RLS)

```sql
-- Enable RLS
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.content ENABLE ROW LEVEL SECURITY;

-- Helper function for admin check
CREATE OR REPLACE FUNCTION public.is_admin() RETURNS BOOLEAN
LANGUAGE sql SECURITY DEFINER SET search_path = public
AS $$ SELECT EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND role = 'admin'); $$;

-- Users table policies
CREATE POLICY "Users can read own profile" ON public.users FOR SELECT USING (auth.uid() = id OR public.is_admin());
CREATE POLICY "Users can update own profile" ON public.users FOR UPDATE USING (auth.uid() = id);
CREATE POLICY "Admins can update any user" ON public.users FOR UPDATE USING (public.is_admin());
CREATE POLICY "Users can insert own profile" ON public.users FOR INSERT WITH CHECK (auth.uid() = id);

-- Content table policies
CREATE POLICY "Anyone can read content" ON public.content FOR SELECT USING (true);
CREATE POLICY "Admins can insert content" ON public.content FOR INSERT WITH CHECK (public.is_admin());
CREATE POLICY "Admins can update content" ON public.content FOR UPDATE USING (public.is_admin());
CREATE POLICY "Admins can delete content" ON public.content FOR DELETE USING (public.is_admin());
```

### 4. Create Storage Bucket

1. Go to **Storage** in the Supabase dashboard
2. Create a bucket named `site_images`
3. Set it to **Public** (so image URLs are accessible without auth)
4. Add a storage policy allowing authenticated users to upload

### 5. Configure Auth

1. Go to **Auth > Providers > Email**
2. Disable "Confirm email" for development (optional)
3. Create your first admin user by signing up, then manually setting their `role` to `'admin'` in the `users` table

---

## Key Concepts

### Map & Radius Filtering

- The map uses `flutter_map` with CartoDB Voyager tiles
- A circle overlay shows the selected radius (1–10 km) around the user
- Markers inside the radius are large with thumbnails; outside are small dots
- The Haversine formula (via `latlong2`) calculates distances
- When a route is active, the radius centers on the destination

### Route Planning

- Users select a destination and up to 3 intermediate stops
- Routes are calculated via OSRM (Open Source Routing Machine)
- The route polyline is drawn on the map in teal
- Turn-by-turn steps are provided with maneuver icons
- If OSRM fails, a straight-line fallback is used

### Admin Location Management

- **Add**: Fill a form with title, description, coordinates, category, and images
- **Edit**: Select from a list, modify any field, manage images (add/remove)
- **Delete**: Confirmation dialog prevents accidental deletion
- Coordinates are validated to be within the Goa region (lat 14.5–16.0, lng 73.0–74.5)
- All changes sync in real-time to all connected clients

---

## Screens Overview

| Screen                  | Description                                                    |
| ----------------------- | -------------------------------------------------------------- |
| **OnboardingScreen**    | Login/signup toggle with email + password forms                |
| **MapScreen**           | FlutterMap with markers, radius overlay, route polyline        |
| **HistoryScreen**       | Searchable card list of all cultural locations                 |
| **AIScreen**            | Placeholder for future AI features                             |
| **ProfileScreen**       | User avatar, name, email, role, logout button                  |
| **AdminHomeScreen**     | Grid dashboard: upload, edit, users, profile                   |
| **ContentUploadScreen** | Form to add location with title, description, coords, images   |
| **EditContentScreen**   | Location list with search, tap to edit                         |
| **DetailedEditScreen**  | Full editor for a single location with delete option           |
| **UserManagementScreen**| User list with role dropdown (user/admin)                      |

---

## Configuration

### Supabase Credentials

Update in `lib/main.dart`:
```dart
await Supabase.initialize(
  url: 'YOUR_SUPABASE_URL',
  anonKey: 'YOUR_ANON_KEY',
);
```

### Theme Colors

Defined in `lib/src/theme/theme.dart`:
- Primary: `#005A60` (deep teal)
- Secondary: `#E0F7FA` (light teal)
- Accent: `#26A69A` (medium teal)

### Location Categories

Defined in `lib/src/constants/categories.dart`. Currently 11 categories:
Christ the King, Piazza Crosses, Our Lady's Grotto, Rock Carvings, Hindu Deities, Stone Inscriptions, Forts, Churches, Beaches, Museums, Heritage.

---

## Building for Production

### Android APK

```bash
flutter build apk --release
```

Output: `build/app/outputs/flutter-apk/app-release.apk`

### Android App Bundle

```bash
flutter build appbundle --release
```

Output: `build/app/outputs/bundle/release/app-release.aab`

### Web

```bash
flutter build web --release
```

Output: `build/web/`
