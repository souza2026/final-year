# Blueprint: Cultural Discovery App

## Overview

This document outlines the style, design, and features of the Cultural Discovery App. It serves as a single source of truth for the application's development, ensuring consistency and a clear roadmap for new features and improvements.

## Implemented Features & Design

*   **Authentication:** User registration and login functionality using Firebase Authentication.
*   **Routing:** A basic routing setup using `go_router`.
*   **Firestore Integration:** User data is stored in a `users` collection in Cloud Firestore.
*   **Basic UI:** A functional, but unstyled, set of screens for registration, login, and home.

## Current Plan: UI & Theme Enhancement

The current focus is to elevate the visual design and user experience of the application. The previous debugging session for the data entry issue will be paused, and work will now focus on the app's aesthetics.

### Action Steps:

1.  **Integrate Custom Fonts:** Add the `google_fonts` package to the project to improve typography.
2.  **Establish a Centralized Theme:** Create a new theme file to define a consistent color scheme and text styles for the entire application.
3.  **Define Typography:** Create a `TextTheme` using a selection of Google Fonts (e.g., Oswald for headings, Roboto for body text) to establish a clear visual hierarchy.
4.  **Apply Theme to Registration Screen:** Refactor the `register_screen.dart` file to use the new, centralized theme and text styles. This will serve as the first example of the new design system.
5.  **Improve Layout and Styling:** Enhance the visual appeal of the registration screen by applying modern design principles, including improved spacing, component styling, and a more polished layout as per the visual design guidelines.
