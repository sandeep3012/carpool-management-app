# CarPool Management App — Product Requirement Document

# Product Overview

A Flutter-based office carpool management application for handling:

* trip management,
* attendance tracking,
* expense calculations,
* settlement optimization,
* reporting,
* notifications,
* synchronization.

The app replaces the current Excel workflow.

---

# Primary Goals

## Problems To Solve

* Manual calculations
* Settlement confusion
* Expense tracking issues
* Sharing problems
* Calculation errors
* Data entry difficulty

## Product Goals

* Automate calculations
* Simplify trip entry
* Improve transparency
* Generate optimized settlements
* Provide offline functionality
* Synchronize data across users
* Deliver premium user experience

---

# User Roles

## Admin

Can:

* manage members
* create/edit/delete trips
* modify expenses
* edit historical records
* generate reports
* manage settings
* view audit logs

## Member

Can:

* login
* view trips
* view settlements
* view reports
* receive notifications

Future:

* optional trip creation permissions

---

# Functional Modules

## Authentication

Phase 1:

* hardcoded credentials

Phase 2:

* Firebase Auth

---

## Dashboard

Features:

* monthly expense summary
* settlement overview
* upcoming driving reminders
* quick actions
* recent activities

---

## Member Management

Features:

* add/edit members
* activate/deactivate members
* assign roles

---

## Trip Management

Current rules:

* one car/day
* one driver/day
* round trip
* fixed route distance

Features:

* select date
* select driver
* mark attendance
* add guests
* add expenses
* auto calculations

---

# Expense Calculation

## Fuel Expense

Formula:

Fuel Expense = (Distance / Mileage) × Fuel Rate

---

## Total Expense

Formula:

Total Expense = Fuel + Toll + Parking + Other Charges

---

## Per Person Split

Formula:

Per Person Share = Total Expense / Total Passengers

Rules:

* driver included
* guests included in daily split
* guests excluded from settlement
* partial trip currently billed full

---

# Settlement Engine

Monthly settlement cycle.

## Net Balance

Formula:

Net Balance = Driver Contribution - Ride Charges

---

## Settlement Output

Optimized settlements:

Example:

* Member A pays ₹500 to Member B

Goals:

* reduce number of transactions
* optimize settlement flow

---

# Guest Management

Guests:

* permanently stored
* included in daily expense split
* excluded from settlement logic

---

# Notifications

Notifications supported:

* driving reminders
* settlement pending
* monthly reports
* expense modified
* trip created
* member absent

Technology:

* Firebase Cloud Messaging

---

# Reporting

Reports:

* monthly summaries
* member summaries
* expense reports
* settlement reports
* driver contribution reports

Export:

* PDF
* WhatsApp sharing

---

# Audit Logging

Track:

* trip edits
* expense modifications
* settlement recalculations
* admin actions

---

# Offline & Sync Requirements

Architecture:

* offline-first

Local:

* Isar database

Cloud:

* Firebase Firestore

Rules:

* app must work offline
* sync in background
* local DB is source of truth

---

# Technical Stack

| Layer         | Technology               |
| ------------- | ------------------------ |
| Frontend      | Flutter                  |
| State         | Riverpod                 |
| Local DB      | Isar                     |
| Cloud         | Firebase                 |
| Notifications | Firebase Cloud Messaging |
| Charts        | fl_chart                 |
| Animations    | Lottie                   |
| Routing       | go_router                |

---

# UI/UX Direction

Style:

* Material 3
* modern
* colorful
* animated
* premium feel

Inspired by:

* Splitwise
* Google Wallet
* Google Calendar

---

# Planned Screens

## Authentication

* splash
* login

## Main

* dashboard
* calendar
* trip details
* settlement screen
* monthly summary

## Admin

* member management
* settings
* audit logs

## Reports

* monthly reports
* export reports

---

# Future Enhancements

* multiple cars/day
* GPS integration
* route templates
* half-trip pricing
* UPI integration
* QR settlements
* Play Store release
* web admin panel

---

# Constraints

Current constraints:

* single car/day
* one driver/day
* fixed route
* global mileage
* manual attendance

---

# Non-Functional Requirements

Requirements:

* smooth animations
* offline reliability
* fast local performance
* scalable architecture
* maintainable codebase
* modular structure

---

# Development Roadmap

## Phase 1

Foundation

* project setup
* architecture
* theme
* navigation

## Phase 2

Core Data

* database models
* repositories
* local storage

## Phase 3

Authentication

* role-based mock login

## Phase 4

Trip System

* calendar
* trip entry
* calculations

## Phase 5

Settlement Engine

* optimized settlements

## Phase 6

Reports

* PDF
* sharing

## Phase 7

Cloud Sync

* Firebase integration

## Phase 8

Notifications

## Phase 9

UI Polish

* animations
* UX improvements
* performance tuning

---

# Success Metrics

## MVP Success

* accurate calculations
* stable settlement logic
* easy trip entry
* reliable synchronization

## Product Success

* reduced manual work
* improved transparency
* easier settlements
* high adoption within office group
