# Blueprint: Cultural Discovery App

## Overview

This document outlines the style, design, and features of the Cultural Discovery App. It serves as a single source of truth for the application's development, ensuring consistency and a clear roadmap for new features and improvements.

## Implemented Features & Design

*   **Authentication:** User registration and login functionality using Firebase Authentication.
*   **Routing:** A basic routing setup using `go_router`.
*   **Firestore Integration:** User data is stored in a `users` collection in Cloud Firestore.
*   **Basic UI:** A functional, but unstyled, set of screens for registration, login, and home.
*   **Search Bar:** A search bar has been added to the `coming_soon_screen.dart` file.
*   **Google Maps Integration:** A real Google Map has been integrated into the `map_screen.dart` file, replacing the previous placeholder. The map is centered on the location of Betalbatim, Goa, India.
*   **Community Forum:** A new feature allowing users to interact with each other through posts.
    *   **Post Model:** A `Post` model has been created in `lib/src/models/post_model.dart`.
    *   **Community Service:** A `CommunityService` has been created in `lib/src/services/community_service.dart` to manage Firestore database operations for posts.
    *   **Community Screen:** A `CommunityScreen` has been created in `lib/src/screens/community_screen.dart` to display posts and allow users to add new posts.
    *   **Navigation:** The community feature is integrated into the main app navigation.

## Current Plan: Awaiting User Feedback

The Community feature has been successfully implemented. The next steps will be determined by the user's feedback and requests. The application is now ready for further enhancements or new feature development.
