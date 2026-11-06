# ✨ Lumora – A Voice Beyond Words

<p align="center">
  <strong>An Assistive Communication and Learning Application for Children</strong>
</p>

<p align="center">
  Built with Flutter and Dart | Android Application
</p>

---

## 🌟 About Lumora

**Lumora – A Voice Beyond Words** is an Android-based assistive communication and learning application developed using Flutter and Dart.

It is designed to help children with speech and communication difficulties express their needs, emotions, preferences, and thoughts through picture-based communication and text-to-speech technology.

Lumora combines Augmentative and Alternative Communication (AAC)-inspired tools, interactive educational activities, emotional regulation exercises, medical information management, emergency assistance, and parental monitoring in a single mobile application.

The application aims to make everyday communication more accessible while providing parents and caregivers with useful tools to support children's communication, learning, and safety.

## 🎯 Project Objectives

- Provide alternative communication methods for children with speech difficulties.
- Enable communication through visual picture cards and text-to-speech.
- Support emotional expression and everyday needs.
- Encourage learning through interactive educational activities.
- Provide simple breathing exercises for emotional regulation.
- Help caregivers manage medical information and emergency contacts.
- Improve child safety through GPS-based emergency location sharing.
- Allow parents to monitor communication and learning activities.

---

## 🚀 Features

### 🗣️ 1. Talk – Picture-Based Communication

A visual communication system that helps children express themselves without depending entirely on spoken language.

- Picture-based communication cards.
- Categorized communication options.
- Selection of multiple pictures.
- Sentence construction using selected cards.
- Text-to-speech conversion of constructed sentences.
- Custom communication card support.

### 💬 2. My Needs

Helps children communicate their everyday needs through visual and text-based options.

- Selectable communication phrases.
- Easy expression of basic needs.
- Text-to-speech support for selected phrases.
- Helps communicate requests and discomfort.

### ❤️ 3. My Feelings

Allows children to express their emotions using visual selections.

- Visual emotion options.
- Simple emotion selection.
- Text-to-speech output.
- Supports emotional expression and communication.

### 📚 4. Learn & Play

An interactive educational module designed to make learning engaging.

**Learning Categories:**
- Colours
- Shapes
- Numbers
- Alphabets
- Animals
- Fruits
- Vegetables
- Vehicles
- Body Parts
- Household Objects
- Community Helpers

**Interactive Activities:**
- Matching exercises.
- Sorting activities.
- Memory exercises.
- Learning progress tracking.

### 🧘 5. Calm Space

A simple relaxation module designed to encourage emotional regulation.

- Guided breathing exercises.
- Controlled breathing activities.
- Simple relaxation experience.
- Helps children practise calming techniques.

### 📅 6. My Routine

Helps children access their routine-related activities and information.

### 🏥 7. Medical Profile

Allows parents and caregivers to maintain important child-related medical information.

- Add child information.
- Store medical profile details.
- Edit existing information.
- Access saved medical information.
- Local data management.

### 🆘 8. Safety – Emergency SOS

An emergency assistance module that integrates Android device capabilities.

**Features:**
- Add emergency contacts.
- Edit and delete emergency contacts.
- Validate phone numbers.
- SOS confirmation dialog.
- Retrieve current GPS location.
- Generate Google Maps location links.
- Send emergency SMS alerts to saved contacts.
- Maintain emergency activity history with date and time.

**Emergency Workflow:**

1. User opens the Safety module.
2. User initiates the SOS operation.
3. Application displays a confirmation dialog.
4. GPS retrieves the current device location.
5. A Google Maps location link is generated.
6. An emergency SMS containing location information is sent to the saved contact.
7. Emergency activity is recorded in the application.

*Note: SMS transmission depends on device permissions and mobile network availability. Sending an SMS does not guarantee its delivery to the recipient.*

### 👨‍👩‍👧 9. Parent Dashboard

Provides parents and caregivers with tools to monitor and manage child-related activities.

- Communication history.
- Activity information.
- Learning progress monitoring.
- Progress charts and graphs.
- Multiple child profile management.
- Per-child settings and permissions.
- Parental controls.

### 🎨 10. Profile & Settings

Provides application customization and personalization options.

- Profile management.
- Multiple application themes.
- Adjustable font sizes.
- Limited multilingual support.
- Communication card customization.

---

## 🛠️ Technology Stack

| Technology | Purpose |
|---|---|
| Flutter | Mobile application development |
| Dart | Programming language |
| Android SDK | Android platform integration |
| Text-to-Speech | Voice-based communication |
| GPS / Location Services | Emergency location retrieval |
| Android SMS Services | Emergency messaging |
| Local Device Storage | Application data persistence |
| Runtime Permissions | Device service access |

---

## 🏗️ Application Architecture

Lumora follows a layered application architecture consisting of four major layers.

### 1. Presentation Layer
- Developed using Flutter and Dart.
- Displays application screens and interfaces.
- Handles user interactions and navigation.
- Provides parent and child interfaces.
- Manages themes and font-size preferences.

### 2. Application Logic Layer
- Authentication and account management.
- Communication board management.
- Sentence construction.
- Text-to-speech operations.
- Educational activities.
- Breathing exercises.
- Medical profile management.
- Emergency SOS processing.
- Parent dashboard and activity monitoring.

### 3. Local Data Layer
- Manages application data.
- Stores user and account information.
- Maintains medical profile details.
- Stores emergency contacts.
- Maintains communication and SOS history.
- Stores application settings and preferences.
- Supports local data encryption.

### 4. Android Service Layer
Integrates Android device capabilities.

- GPS for location retrieval.
- SMS services for emergency messaging.
- Text-to-speech for voice output.
- Runtime permissions for accessing device functionality.

### Architecture Overview

```text
              LUMORA APPLICATION
                      |
          +-----------+-----------+
          |                       |
    Presentation Layer      User Interface
          |
    Application Logic
          |
    +-----+------+--------+---------+
    |            |        |         |
Communication  Learning  Safety   Caregiver
    |            |        |         |
    +------------+--------+---------+
                      |
                Local Data Layer
                      |
             Android Service Layer
                      |
          +-----------+-----------+
          |           |           |
         GPS         SMS         TTS
```

---

## 📱 Application Platform

- **Platform:** Android
- **Framework:** Flutter
- **Language:** Dart
- **Application Type:** Standalone Android Application
- **Build Format:** APK

---

## ⚙️ Getting Started

### Prerequisites

Before running Lumora, ensure you have:

- Flutter SDK installed.
- Dart SDK installed.
- Android Studio or Visual Studio Code.
- Android SDK and required development tools.
- Android Emulator or a physical Android device.

### Installation

**1. Clone the repository**

```bash
git clone YOUR_REPOSITORY_URL
```

**2. Navigate to the project directory**

```bash
cd lumora
```

**3. Install project dependencies**

```bash
flutter pub get
```

**4. Check Flutter configuration**

```bash
flutter doctor
```

**5. Run the application**

```bash
flutter run
```

### Build APK

To generate an Android APK:

```bash
flutter build apk --release
```

The generated APK can be found in:

```text
build/app/outputs/flutter-apk/app-release.apk
```

---

## 📸 Screenshots

Screenshots of the application will be added here to demonstrate its interface and functionality.

Suggested screenshots:

| Module | Screenshot |
|---|---|
| Home Dashboard | Add screenshot |
| Talk / Communication | Add screenshot |
| My Needs | Add screenshot |
| My Feelings | Add screenshot |
| Learn & Play | Add screenshot |
| Calm Space | Add screenshot |
| Medical Profile | Add screenshot |
| Emergency SOS | Add screenshot |
| Parent Dashboard | Add screenshot |

---

## 🔐 Data Management & Privacy

Lumora uses local device storage to manage application information.

Data categories include:

- Account information.
- Child medical profiles.
- Emergency contact information.
- Communication history.
- Emergency activity history.
- Application preferences.
- Learning progress information.

**Security features:**
- Local data encryption.
- Local data persistence.
- Runtime permission management.

Cloud synchronization and cloud-based backup are not currently available.

---

## 🚧 Future Enhancements

- Cloud-based data synchronization.
- Cloud backup and restoration.
- Improved cross-device data accessibility.
- Further improvements to application performance.
- Expanded multilingual support.
- Additional accessibility enhancements.
- Further improvements to caregiver monitoring.

---

## 📌 Current Limitations

- Cloud synchronization is not currently available.
- Cloud-based backup and restoration are not currently supported.

---

## 💡 Project Significance

Lumora aims to make communication more accessible for children who experience speech and communication difficulties.

By combining visual communication, text-to-speech, educational activities, emotional regulation exercises, and emergency assistance, the application provides multiple forms of support through a single platform.

It also demonstrates the integration of Flutter-based mobile development with native Android capabilities such as GPS, SMS, and text-to-speech.

---

## 👨‍💻 Development

**Project:** Lumora – A Voice Beyond Words  
**Domain:** Assistive Technology / Mobile Application Development  
**Framework:** Flutter  
**Language:** Dart  
**Platform:** Android

---

<p align="center">
  <strong>✨ Lumora – A Voice Beyond Words</strong>
  <br>
  <em>Giving every child a way to express themselves.</em>
</p>
