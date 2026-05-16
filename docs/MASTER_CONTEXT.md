# CarPool Management App — Master Development Context

## Project Overview

This project is a production-grade Flutter mobile application for managing office carpool operations.

The application replaces the current Excel-based workflow and automates:

* trip management,
* passenger attendance,
* expense calculation,
* monthly settlements,
* reporting,
* synchronization,
* notifications,
* audit tracking.

The application must be:

* scalable,
* modular,
* maintainable,
* Play Store ready,
* offline-first,
* AI-assisted development friendly.

---

# Tech Stack

## Frontend

* Flutter
* Dart

## State Management

* Riverpod ONLY

## Local Database

* Isar

## Cloud Backend

* Firebase Firestore

## Authentication

* Mock authentication initially
* Firebase Auth later

## Notifications

* Firebase Cloud Messaging

## Charts

* fl_chart

## Animations

* Lottie
* Flutter implicit animations

---

# Architecture Requirements

Use:

* Feature-first clean architecture

Required folder structure:

lib/
├── app/
├── core/
├── shared/
├── features/
└── main.dart

Strict separation of:

* presentation
* domain
* data

Never mix:

* UI
* business logic
* repositories
* services

---

# UI/UX Requirements

Design language:

* Material 3
* Modern
* Colorful
* Smooth
* Premium feeling

Inspired by:

* Splitwise
* Google Wallet
* Google Calendar

UI Requirements:

* reusable widgets,
* smooth animations,
* elegant transitions,
* modern cards,
* bottom sheets,
* responsive layouts,
* calendar-centric interactions.

Avoid:

* outdated material UI,
* enterprise-looking tables,
* cluttered layouts.

---

# Business Rules

Current rules:

* One car per day
* One driver per day
* Round trip
* Fixed route distance
* Global mileage value
* Fuel price editable from settings
* Driver also pays split
* Guests allowed
* Guests excluded from settlement
* Partial trip treated as full trip currently
* Monthly settlement cycle
* Admin-only editing
* Audit history required
* Offline-first architecture required

Future extensibility:

* multiple cars/day
* GPS integration
* route templates
* half-trip logic
* Firebase authentication
* Play Store deployment

---

# Offline & Sync Architecture

Architecture:

Flutter App
↓
Isar Local Database
↓
Sync Layer
↓
Firebase Firestore

Rules:

* Local DB is runtime source of truth
* Sync happens in background
* App must work offline
* All entities require sync metadata

Required metadata:

* localId
* cloudId
* syncStatus
* createdAt
* updatedAt

---

# Development Principles

Always prioritize:

1. maintainability
2. readability
3. scalability
4. modularity
5. testability

Avoid:

* giant widgets,
* tightly coupled code,
* duplicated code,
* deeply nested widget trees,
* huge stateful widgets.

Prefer:

* composition,
* reusable widgets,
* immutable models,
* provider-driven state management.

---

# File Size Rules

Preferred limits:

* widgets under 300 lines
* services under 400 lines
* split screens aggressively

Never generate gigantic files.

---

# Coding Standards

Required:

* meaningful naming
* typed models
* async safety
* proper loading states
* proper error handling
* null safety
* repository abstraction

Avoid:

* inline business logic in widgets
* magic numbers
* duplicated validation

---

# State Management Rules

Use Riverpod properly.

Requirements:

* feature-level providers
* repository injection
* isolated provider scopes
* no global mutable state

Do NOT use:

* Provider package
* GetX

---

# Routing Requirements

Preferred router:

* go_router

Requirements:

* auth-aware routing
* scalable route organization
* nested navigation ready

---

# Theme Requirements

Create:

* centralized color system
* typography system
* spacing system
* animation constants
* reusable component styles

Support:

* light theme
* dark theme later

---

# Firebase Rules

Use Firebase for:

* future sync
* notifications
* future authentication

Never tightly couple Firebase directly with UI.

Use:

* service abstraction
* repository abstraction

---

# Error Handling Requirements

Implement:

* centralized error handling
* loading states
* async state wrappers
* empty states
* failure states

---

# Shared Component Strategy

Reusable components required:

* cards
* buttons
* dialogs
* loaders
* snackbars
* bottom sheets
* calendar widgets

---

# Current Development Phase

Current phase:
FOUNDATION & ARCHITECTURE

Focus only on:

* project setup,
* architecture,
* foundations,
* reusable infrastructure.

Do NOT jump into advanced features unless explicitly requested.

---

# AI Development Workflow

Primary development assistant:

* Claude Code

Use incremental feature development.

NEVER:

* generate full app at once.

Correct order:

1. project setup
2. architecture
3. theme
4. navigation
5. database
6. repositories
7. auth
8. dashboard
9. trips
10. calculations
11. settlements
12. reports
13. sync
14. notifications
15. polish

---

# Expected Output Quality

Every implementation must be:

* production-ready,
* scalable,
* modular,
* Play Store quality,
* AI-maintainable,
* animation-friendly.
