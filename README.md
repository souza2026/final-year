# Goa Cultural Discovery App

A Flutter-based mobile application for discovering and navigating cultural heritage sites in Goa, India. Features an interactive map with radius-based filtering, multi-stop route planning, and real-time data from Supabase.

---

## Table of Contents

- [Tech Stack](#tech-stack)
- [Project Structure](#project-structure)
- [Supabase Connection](#supabase-connection)
- [Map & Radius Logic](#map--radius-logic)
- [Route / Path Creation Logic](#route--path-creation-logic)
- [State Management](#state-management)
- [Navigation & Routing](#navigation--routing)
- [Screens Overview](#screens-overview)
- [Getting Started](#getting-started)

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

## Project Structure

```
lib/
├── main.dart                          # App entry point, Supabase init, Provider setup
├── firebase_options.dart              # Legacy Firebase config (unused at runtime)
│
└── src/
    ├── routing/
    │   └── app_router.dart            # GoRouter config with auth guards & role-based redirects
    │
    ├── services/
    │   ├── auth_service.dart          # Supabase Auth wrapper (sign up, sign in, roles)
    │   ├── geocoding_service.dart     # Nominatim reverse/forward geocoding
    │   └── routing_service.dart       # OSRM multi-point route fetching
    │
    ├── providers/
    │   ├── location_provider.dart     # GPS tracking + Supabase real-time location stream
    │   └── map_state_provider.dart    # All map UI state: search, radius, routes, direction panel
    │
    ├── models/
    │   ├── location_model.dart        # Cultural site data (id, name, lat/lng, images, description)
    │   ├── user_model.dart            # User profile (uid, email, role, username, createdAt)
    │   └── waypoint_model.dart        # Route waypoint (latLng + name)
    │
    ├── screens/
    │   ├── main_screen.dart           # Bottom nav shell (Map, History, AI, Profile tabs)
    │   ├── map_screen.dart            # Core map view with markers, overlays, route polyline
    │   ├── onboarding_screen.dart     # Login / Signup forms
    │   ├── profile_screen.dart        # User profile display + logout
    │   ├── history_screen.dart        # Searchable list of all locations
    │   ├── ai_screen.dart             # Placeholder for AI features
    │   ├── edit_profile_screen.dart   # Edit username / photo
    │   ├── user_home_screen.dart      # Legacy user dashboard
    │   ├── admin_home_screen.dart     # Admin dashboard with grid menu
    │   ├── coming_soon_screen.dart    # Placeholder screen
    │   └── admin/
    │       ├── content_upload_screen.dart   # Add new location + image upload
    │       ├── edit_content_screen.dart     # List locations, tap to edit
    │       ├── detailed_edit_screen.dart    # Edit/delete a single location
    │       └── user_management_screen.dart  # View users, change roles
    │
    ├── widgets/
    │   ├── bottom_navigation_bar.dart      # Custom 4-tab nav bar
    │   └── map/
    │       ├── search_bar_widget.dart       # Location search (DB locations only)
    │       ├── radius_selector_widget.dart  # 1/2/5/10 km dropdown + nearby count
    │       ├── location_name_chip.dart      # Reverse-geocoded current place name
    │       └── route_info_bar.dart          # DirectionPanel (route planner + route info)
    │
    └── theme/
        └── theme.dart                 # Material 3 light/dark themes, teal color scheme

assets/
├── images/                            # Background patterns, placeholders
└── data/
    └── locations.json                 # 5 seed locations (Goa cultural sites)
```

---

## Supabase Connection

### Initialization

Supabase is initialized in `main.dart` before any widget renders:

```dart
await Supabase.initialize(
  url: 'https://kclmxvldjbccfdtnautw.supabase.co',
  anonKey: '<anon-key>',
);
```

The `SupabaseClient` instance is then injected into `AuthService` via the Provider tree:

```dart
Provider<AuthService>(
  create: (_) => AuthService(Supabase.instance.client),
),
```

### Database Tables

**`users`** — Stores user profiles, created on signup.

| Column     | Type      | Notes                            |
| ---------- | --------- | -------------------------------- |
| id         | UUID (PK) | Matches Supabase Auth `user.id`  |
| email      | text      |                                  |
| username   | text      |                                  |
| role       | text      | `'user'` or `'admin'`           |
| photo_url  | text      | Optional avatar URL              |
| created_at | timestamp | Auto-generated                   |

**`content`** — Stores cultural site / location data.

| Column      | Type          | Notes                        |
| ----------- | ------------- | ---------------------------- |
| id          | integer (PK)  | Auto-increment               |
| title       | text          | Location name                |
| description | text          | Location description         |
| latitude    | numeric       |                              |
| longitude   | numeric       |                              |
| imageUrl    | text          | Primary image URL (optional) |
| images      | text[]        | Array of image URLs          |
| createdAt   | text          | ISO 8601 timestamp string    |

### Auth Flow

1. **Sign Up** (`AuthService.createUserWithEmailAndPassword`):
   - Calls `supabase.auth.signUp(email, password)`
   - Inserts a row into `users` table with the auth user's `id`, email, username, and role
   - If email is `admin@myapp.com`, role is set to `'admin'`; otherwise `'user'`

2. **Sign In** (`AuthService.signInAndGetUserRole`):
   - Calls `supabase.auth.signInWithPassword(email, password)`
   - Queries `users` table for the role
   - GoRouter redirect sends admin users to `/admin` and regular users to `/map`

3. **Auth State Listener**:
   - `AuthService.user` exposes a `Stream<User?>` from `supabase.auth.onAuthStateChange`
   - GoRouter listens to this stream via `GoRouterRefreshStream` to reactively redirect on login/logout

### Row Level Security (RLS)

The `users` table uses a `SECURITY DEFINER` function to avoid infinite recursion in admin policies:

```sql
CREATE FUNCTION public.is_admin() RETURNS boolean
LANGUAGE sql SECURITY DEFINER SET search_path = public
AS $$ SELECT EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND role = 'admin'); $$;
```

Policies:
- **SELECT**: `auth.uid() = id OR public.is_admin()` — users read own row; admins read all
- **UPDATE (user)**: `auth.uid() = id`
- **UPDATE (admin)**: `public.is_admin()`
- **INSERT**: `auth.uid() = id` — signup only

### Real-Time Data

`LocationProvider` subscribes to the `content` table for live updates:

```dart
_supabase.from('content').stream(primaryKey: ['id']).listen((data) {
  _locations = data.map((row) => LocationModel.fromMap(row)).toList();
  notifyListeners();
});
```

Any location added or edited (by admin or user) is reflected across all connected clients in real time.

### Storage

Admin image uploads go to the `site_images` bucket:
- Path: `uploads/{timestamp}.{extension}`
- Max file size: 5 MB (enforced client-side)
- Public URL retrieved after upload for display

---

## Map & Radius Logic

### How It Works

The map screen displays cultural sites as markers. A **radius circle** is drawn around the user's current location (or the active route destination), and markers inside/outside the radius are styled differently.

### Radius Selection

`RadiusSelectorWidget` offers four fixed options: **1 km, 2 km, 5 km, 10 km** (default: 2 km). Selecting a value calls:

```dart
mapState.setRadius(km, locations: locations, center: center);
```

This updates `_selectedRadius` and recalculates `_nearbyCount` (how many locations fall within the radius).

### Nearby Count Calculation

In `MapStateProvider._updateNearbyCount`:

```dart
const distance = Distance(); // from latlong2 — uses the Haversine formula
_nearbyCount = locations.where((loc) {
  final meters = distance(center, LatLng(loc.latitude, loc.longitude));
  return meters <= _selectedRadius * 1000;
}).length;
```

### Circle Overlay

Drawn as a `CircleLayer` on the FlutterMap:

```dart
CircleMarker(
  point: mapState.routeDestination ?? currentUserLocation,
  radius: mapState.selectedRadius * 1000,  // convert km to meters
  useRadiusInMeter: true,
  color: Color(0xFF005A60).withAlpha(20),       // semi-transparent teal fill
  borderColor: Color(0xFF005A60).withAlpha(80),  // darker teal stroke
  borderStrokeWidth: 2,
)
```

The center shifts to `routeDestination` when a route is active, so the radius filters around the destination instead.

### Marker Styling

In `map_screen.dart`, every location is checked against the radius:

```dart
const distanceCalc = Distance();
final radiusMeters = mapState.selectedRadius * 1000;
final metersFromCenter = distanceCalc(center, locPoint);
final isInsideRadius = metersFromCenter <= radiusMeters;
```

| Marker Type       | Size  | Style                                                 |
| ----------------- | ----- | ----------------------------------------------------- |
| Inside radius     | 45 px | Circle with photo thumbnail + name label below        |
| Outside radius    | 16 px | Small teal dot                                        |
| Current location  | 30 px | Blue dot with white border                            |
| Route destination | 40 px | Red `location_on` icon                                |
| Waypoint (stop)   | 36 px | Orange `location_on` icon                             |

Tapping a marker inside the radius opens a `DraggableScrollableSheet` with the location's photos, description, distance from user, and a "Get Directions" button (opens Google Maps externally).

---

## Route / Path Creation Logic

### Overview

Users can plan multi-stop routes entirely from database locations. The flow is:

1. Tap the **Directions FAB** (bottom-right, compass icon)
2. A **DirectionPanel** slides up in **setup mode**
3. Pick a destination and optionally add up to 3 intermediate stops
4. Tap **Calculate Route** to draw the path on the map

### DirectionPanel (`route_info_bar.dart`)

The panel has two modes:

**Setup Mode** (planning):
```
[ ─── drag handle ─── ]
[ From: My Location (fixed, current GPS)       ]
[ Stop 1: Select stop...                  ✕    ]
[ To: Select destination...               ✕    ]
[ + Add stop                                   ]
[            [ Calculate Route ]               ]
```

- "From" is always the user's current GPS position, not editable
- "To" (destination) and each stop use an inline location picker showing all database locations, filterable by typing
- Already-selected locations are excluded from the picker to prevent duplicates
- Maximum 3 intermediate stops (enforced by `MapStateProvider.maxWaypoints`)

**Route Info Mode** (after calculation):

Collapsed (90 px):
```
[ ─── drag handle ─── ]
[ Destination Name     5.2 km  12 min        ✕ ]
```

Expanded (drag up):
```
[ ─── drag handle ─── ]
[ Destination Name     5.2 km  12 min        ✕ ]
[ ─────────────── divider ─────────────── ]
[ 1  Stop Name                             ✕  ]
[ 2  Stop Name                             ✕  ]
[ Edit route                                   ]
```

- Drag down past threshold (60 px) dismisses the route
- Removing a stop recalculates the route automatically
- "Edit route" switches back to setup mode with fields pre-populated

### OSRM Routing Service (`routing_service.dart`)

Routes are fetched from the OSRM server:

```
GET https://router.project-osrm.org/route/v1/driving/{lon1},{lat1};{lon2},{lat2};...
    ?overview=full&geometries=geojson
```

- Supports any number of waypoints in sequence
- Returns GeoJSON geometry (array of `[lon, lat]` coordinate pairs)
- Returns total `distance` (meters) and `duration` (seconds)
- Timeout: 8 seconds
- **Fallback**: If OSRM fails, a straight-line polyline is drawn between all points with distance calculated via Haversine

### Route Calculation Flow

```
User taps "Calculate Route"
  │
  ├─ DirectionPanel._calculateRoute()
  │    ├─ Gathers origin (GPS), stops (list), destination
  │    └─ Calls mapState.calculateRoute(origin, stops, destination)
  │
  ├─ MapStateProvider.calculateRoute()
  │    ├─ Sets _destination and _waypoints
  │    ├─ Sets _isDirectionPanelOpen = false
  │    └─ Calls _fetchRoute(origin)
  │
  ├─ MapStateProvider._fetchRoute()
  │    ├─ Builds ordered point list: [origin, ...waypoints, destination]
  │    ├─ Calls RoutingService.getRoute(points)
  │    ├─ Stores polyline, distance (km), duration (min)
  │    └─ notifyListeners() → UI rebuilds
  │
  └─ MapScreen callback: onRouteCalculated
       ├─ Fits map bounds to show entire route (80px padding)
       └─ setState() triggers marker/polyline redraw
```

### Polyline Drawing

The route polyline is drawn as a `PolylineLayer` on the FlutterMap:

```dart
Polyline(
  points: mapState.routePolyline,  // List<LatLng> from OSRM GeoJSON
  strokeWidth: 4.0,
  color: Color(0xFF005A60),        // teal
)
```

### UI Behavior During Routing

When the DirectionPanel is open or a route is active:
- **LocationNameChip** and **RadiusSelectorWidget** are hidden to reduce clutter
- **Directions FAB** is hidden (the panel is already open)
- **Zoom controls** and **My Location button** remain visible
- **Search bar** remains on top of everything for quick location lookup

---

## State Management

Three providers manage the app state, all set up in `main.dart` via `MultiProvider`:

### AuthService (Provider)

Not a `ChangeNotifier` — it's a plain service injected via `Provider<AuthService>`.

| Property / Method                  | Purpose                                              |
| ---------------------------------- | ---------------------------------------------------- |
| `user` (Stream)                    | Auth state changes, drives GoRouter refreshes        |
| `currentUser`                      | Synchronous access to logged-in Supabase User        |
| `signInAndGetUserRole()`           | Authenticates + fetches role from `users` table      |
| `createUserWithEmailAndPassword()` | Creates auth user + inserts `users` row              |
| `getUserRole(uid)`                 | Queries `users` table for role string                |
| `updateUserProfile()`              | Updates username/photo in `users` table              |
| `signOut()`                        | Ends the Supabase session                            |

### LocationProvider (ChangeNotifier)

Manages GPS position and the list of cultural sites.

| Property              | Purpose                                                     |
| --------------------- | ----------------------------------------------------------- |
| `currentLocation`     | User's live GPS coordinates (from `location` package)       |
| `locations`           | All cultural sites (from Supabase `content` table)          |
| `isLoading`           | True while initial data is loading                          |

Key behaviors:
- On init, requests GPS permission and fetches initial position
- Loads locations from local JSON as fallback, then activates Supabase real-time stream
- `addCustomLocation()` optimistically adds to the local list and inserts into Supabase
- `importJsonToDatabase()` seeds the `content` table from `assets/data/locations.json`

### MapStateProvider (ChangeNotifier)

All map UI state lives here — search, radius, routing, direction panel.

| State Group     | Key Fields                                                              |
| --------------- | ----------------------------------------------------------------------- |
| Place name      | `currentPlaceName`, `isLoadingPlaceName`                                |
| Search          | `searchResults`, `isSearching`, `isLoadingSearch`                       |
| Route           | `routePolyline`, `routeDestination`, `destinationName`, `waypoints`     |
| Route metrics   | `routeDistanceKm`, `routeDurationMin`, `isLoadingRoute`                 |
| Direction panel | `isDirectionPanelOpen`, `hasActiveRoute`, `canAddStop`, `totalStops`    |
| Radius          | `selectedRadius`, `nearbyCount`                                         |

Key methods:
- `updateCurrentLocationName(lat, lng)` — reverse geocodes with 2-second debounce, skips if moved < 100m
- `search(query, locations)` — filters database locations by name (local only, no external API)
- `calculateRoute(origin, stops, destination)` — sets route state and fetches from OSRM
- `clearRoute()` — resets all route state and closes the direction panel

---

## Navigation & Routing

GoRouter handles all navigation with auth-aware redirects (`app_router.dart`).

### Route Table

| Path                          | Screen                 | Access   |
| ----------------------------- | ---------------------- | -------- |
| `/`                           | OnboardingScreen       | Public   |
| `/map`                        | MainScreen (4 tabs)    | User     |
| `/admin`                      | AdminHomeScreen        | Admin    |
| `/admin/content-upload`       | ContentUploadScreen    | Admin    |
| `/admin/edit-content`         | EditContentScreen      | Admin    |
| `/admin/edit-content/:docId`  | DetailedEditScreen     | Admin    |
| `/admin/user-management`      | UserManagementScreen   | Admin    |
| `/admin/edit-profile`         | EditProfileScreen      | Admin    |

### Redirect Logic

```
User visits any route
  │
  ├─ Not logged in + route != "/"  →  redirect to "/"
  ├─ Logged in + route == "/"      →  fetch role
  │   ├─ role == "admin"           →  redirect to "/admin"
  │   └─ role == "user"            →  redirect to "/map"
  └─ Otherwise                     →  no redirect
```

The router refresh stream listens to `AuthService.user` so navigation reacts instantly to login/logout events.

### Tab Navigation

`MainScreen` uses an `IndexedStack` with 4 tabs:

| Index | Tab      | Screen         |
| ----- | -------- | -------------- |
| 0     | Map      | MapScreen      |
| 1     | History  | HistoryScreen  |
| 2     | AI       | AIScreen       |
| 3     | Profile  | ProfileScreen  |

`IndexedStack` preserves each tab's widget state across switches.

---

## Screens Overview

| Screen                  | Description                                                    |
| ----------------------- | -------------------------------------------------------------- |
| **OnboardingScreen**    | Login/signup toggle with email + password forms                |
| **MapScreen**           | FlutterMap with markers, radius overlay, route polyline, FABs  |
| **HistoryScreen**       | Searchable card list of all cultural locations                 |
| **AIScreen**            | Placeholder with two concept cards (not functional)            |
| **ProfileScreen**       | User avatar, name, email, role, logout button                  |
| **AdminHomeScreen**     | Grid dashboard: upload, edit, users, profile, 2 placeholders   |
| **ContentUploadScreen** | Form to add location with title, description, coords, image   |
| **EditContentScreen**   | Location list with search, tap to edit, cloud seed button      |
| **DetailedEditScreen**  | Full editor for a single location with delete option           |
| **UserManagementScreen**| User list with role dropdown (user/admin)                      |

---

## Getting Started

### Prerequisites

- Flutter SDK 3.9+
- A Supabase project with the `users` and `content` tables created
- Email confirmation disabled in Supabase (Dashboard > Auth > Providers > Email)

### Setup

1. Clone the repository
2. Install dependencies:
   ```bash
   flutter pub get
   ```
3. Update the Supabase URL and anon key in `lib/main.dart` if using your own project
4. Run the RLS policy setup:
   - Execute `supabase_fix_rls_v2.sql` in the Supabase SQL Editor
5. Seed location data:
   - Execute `supabase_seed.sql` in the Supabase SQL Editor, or use the cloud upload button in the admin Edit Content screen
6. Run the app:
   ```bash
   flutter run
   ```

### Build APK

```bash
flutter build apk --release
```

The output APK is at `build/app/outputs/flutter-apk/app-release.apk`.
