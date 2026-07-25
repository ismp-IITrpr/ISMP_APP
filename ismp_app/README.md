# IIT Ropar ISMP Application (Official) 🚀
Official mobile application for the **Institute Student Mentorship Program (ISMP)** at IIT Ropar, designed for the upcoming fresher batches (2026-27). 

This app serves as a centralized bridge connecting freshers, mentors, and club representatives. It facilitates event management, real-time news/blogs sharing, student profiles, "Moments" sharing, and automated QR-code-based attendance tracking.

---

## 🔑 Crucial Access & Credentials Guide

For future developers maintaining and deploying the project, please note the following access controls:

### 1. Firebase Project Access
* **Account:** Always log in using the official `ismp` account credentials (usually linked to the ISMP admin team email / `ismp@iitrpr.ac.in`).
* **Firebase Project ID:** `iit-ropar-ismp-app`
* *Do not modify the Firebase SDK options/configuration without aligning with the core ISMP team.*

### 2. GitHub Access
* **Account:** Use the `ismp` organization account (`ismp-IITrpr`) for repository administration and code commits.
* **Auto iOS Build Pipeline:** The repository includes a GitHub Action workflow [Build iOS IPA (Unsigned)](.github/workflows/ios_build.yml) that automatically builds the unsigned iOS `.ipa` package from the repository's main branch.

### 3. Moments Section (ImgBB Image Hosting API) ⚠️
* The "Moments" section allows users to upload and share images. These images are hosted externally on **ImgBB**.
* **API Key Location:** The API key is hardcoded directly as a constant inside [firebase_service.dart](lib/services/firebase_service.dart#L19).
* **API Owner:** This API key is registered under **Parag Gupta (2025chb1137)**.
* 🚨 **CRITICAL NOTE:** The API key configuration is fully working. **DO NOT ALTER OR REMOVE** the configuration constant in `firebase_service.dart` so that image/moments uploads continue to work as expected.

---

## 📱 How the Application Works (Architecture)

The system consists of three main components: **Flutter Client App**, **Firebase Backend Services**, and **Admin Seeding Scripts**.

### User Roles & Authentication
Authentication is done via Google Sign-In, restricted strictly to IIT Ropar emails (`@iitrpr.ac.in`).
* **Students:** 
  * Access is permitted if the email starts with `2026` (the fresher batch) or matches authorized 2025 batch student coordinator emails (defined in `_allowed2025Emails` in [firebase_service.dart](lib/services/firebase_service.dart#L340)).
  * Upon their first login, a Firestore document is automatically generated under `/users/{rollNo}` with default profile parameters.
* **Representatives (Club Reps/Admins):** 
  * Access is automatically granted if the logged-in email is present in the `_repEmailToClub` map in [firebase_service.dart](lib/services/firebase_service.dart#L364).
  * The main admin email `ismp@iitrpr.ac.in` is mapped to the 'ISMP' club.

### Core App Features
1. **Dashboard / Homepage:** Displays recent announcements/blogs, a horizontal feed of "Moments" (shared photos), quick shortcuts, and the core development team profile screen.
2. **QR-Based Attendance System:**
   * **Reps** can choose an event and spin up a live **Attendance Session**. A unique session ID is generated and displayed as a QR code.
   * **Students** open the in-app **Scanner** and scan the rep's QR code.
   * **Reps** monitor the live scan count in real-time. If a student's scanner fails, the rep can manually search/add them using their Roll Number.
   * Clicking "Submit Attendance" updates the attendance records of all targeted students (present or absent) and increments their "Stickers Collected" count (first-time club event attendance award).
3. **Event Schedule:** Calendar screen displaying day-wise orientation events.
4. **Academic Handbook:** PDF reader component that directly displays the ISMP fresher handbook (`assets/handbook.pdf`).
5. **Real-time Notifications:** Firestore collection triggers background push notifications to target devices using Firebase Cloud Messaging (FCM).

---

## 🛠️ Project Setup & How to Run

### Prerequisite Checklist
* **Flutter SDK:** Version `3.12.0` or higher.
* **Dart SDK:** Version `3.12.0` or higher.
* **Firebase CLI:** Installed and logged in (`firebase login`).
* **Python 3:** Needed for running database seeding scripts.

---

### Step 1: Run the Flutter Mobile App
1. Navigate to the mobile application directory:
   ```bash
   cd ismp_app
   ```
2. Fetch and configure all Dart package dependencies:
   ```bash
   flutter pub get
   ```
3. Run the application on a connected emulator or physical device:
   ```bash
   flutter run
   ```
   * *Note: Database seeding is run asynchronously in debug mode automatically on startup.*

---

### Step 2: Deploy Cloud Functions (Backend)
The backend functions handle notifications, automatic target roll number computation, and high-performance batch attendance submissions.

1. Navigate to the functions directory from the project root:
   ```bash
   cd functions
   ```
2. Install npm dependencies:
   ```bash
   npm install
   ```
3. Compile TS and deploy to your Firebase project:
   ```bash
   firebase deploy --only functions
   ```

---

### Step 3: Run the Mentor Seeding Script
If you need to upload or sync the list of ISMP mentors into the Firestore database, a script is provided under `mentor_details_script`.

1. Navigate to the script directory:
   ```bash
   cd mentor_details_script
   ```
2. Obtain the `serviceAccountKey.json` credentials file:
   * Go to **Firebase Console** -> **Project Settings** -> **Service Accounts**.
   * Click **Generate New Private Key** and save it as `serviceAccountKey.json` inside this folder.
3. Install required Python packages:
   * Recommended to use a virtual environment:
     ```bash
     python -m venv venv
     # Activate on Windows:
     venv\Scripts\activate
     # Activate on macOS/Linux:
     source venv/bin/activate
     
     pip install pandas firebase-admin openpyxl
     ```
4. Place the parsed tuple lists in `mentor_tuples.txt` and `mentor_pg_tuples.txt`.
5. Run the upload script:
   ```bash
   python upload_mentors.py
   ```
   * *This will parse the files, map mentor images to their hosted GitHub paths under `ismp-IITrpr/ismp-mentors-images`, compile `mentors.csv`, and upload the data directly to Firestore.*

---

## 📁 Repository Directory Structure

```
ISMP_APP/
├── .github/
│   └── workflows/
│       └── ios_build.yml          # GitHub Actions CI/CD for unsigned iOS build
├── functions/                     # Firebase Cloud Functions (TypeScript)
│   ├── src/
│   │   └── index.ts               # Core backend triggers (Notification, Target Roll calculation)
│   ├── package.json
│   └── tsconfig.json
├── ismp_app/                      # Core Flutter Mobile Application
│   ├── assets/                    # Handbook PDF, Logos, Carousel & Theme assets
│   ├── lib/
│   │   ├── models/                # Data structures (Blogs, Attendance, Moments, Events)
│   │   ├── screens/               # Mobile UI Views (Homepage, Scanner, Rep Dashboard, Auth)
│   │   ├── services/              # Firebase interactions, Auth Preferences, Notifications
│   │   ├── theme/                 # Dark Theme system styling config
│   │   ├── widgets/               # Reusable UI widgets and custom layouts
│   │   ├── firebase_options.dart  # Firebase Platform Configurations
│   │   └── main.dart              # Entry Point of Flutter application
│   ├── pubspec.yaml               # Flutter package configuration
│   └── firebase.json              # Firebase build target platforms map
└── mentor_details_script/         # Administrative helper scripts
    ├── upload_mentors.py          # Python automation script to upload mentors list to DB
    ├── mentor_tuples.txt          # Source mentor data list
    ├── mentor_pg_tuples.txt       # Source postgraduate mentor data list
    └── serviceAccountKey.json     # Firebase admin service account key (add manually)
```

---

## ⚡ Performance Optimizations
* **Offline Persistence:** Firestore offline caching is explicitly enabled in `main.dart` with unlimited cache size. Reads served from the cache are free and do not count against Firestore's daily reads quota.
* **Batch Operations:** Cloud Functions are deployed to handle mass operations (like marking attendance for hundreds of students at once) to avoid thousands of individual client-side database calls.

