# Project Blueprint

## Overview

The application is a cultural discovery app that allows users to explore points of interest on a map. It includes user authentication (login, registration), role-based access control (regular user vs. admin), and a map-based interface. Administrators have access to a separate dashboard for content management and user administration.

## Key Features

*   **User Authentication:**
    *   Login with email and password.
    *   User registration with email, password, and username.
    *   Secure session management.
*   **Role-Based Access:**
    *   **User Role:** Can view the main map screen with points of interest.
    *   **Admin Role:** Can access a dedicated admin dashboard with additional functionalities.
*   **Routing:**
    *   Declarative routing using the `go_router` package.
    *   Authentication-based redirects (e.g., non-logged-in users are redirected to the login screen).
    *   Role-based redirects (e.g., admins are redirected to the admin dashboard after login).
*   **Screens:**
    *   **Onboarding/Login Screen:** A unified screen for both login and user registration.
    *   **Main Screen:** Displays the map with cultural points of interest (for regular users).
    *   **Admin Home Screen:** The main dashboard for administrators, with options for content management and user management.
    *   **Content Upload Screen (Admin):** Allows admins to upload new content.
    *   **Edit Content Screen (Admin):** Allows admins to edit existing content.
    *   **User Management Screen (Admin):** Allows admins to manage user accounts.
    *   **Edit Profile Screen (Admin):** Allows admins to edit their own profile.
*   **Styling and Theming:**
    *   Custom theming with light and dark modes.
    *   Use of `google_fonts` for consistent typography.
    *   Centralized theme management using `ThemeProvider`.

## Current Plan

*   **Consolidate Admin Content Management:** The separate "Content Upload" and "Edit Content" options on the admin home screen have been verified to be correctly routed. The admin workflow for content is now clear and functional.

