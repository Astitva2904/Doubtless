# 📱 Doubtless – Real-Time Peer Tutoring iOS App

## 🚀 Overview

Doubtless is a live peer-tutoring iOS application designed to enable instant 1:1 doubt resolution through real-time video sessions. The platform connects students with peer solvers and facilitates seamless academic interaction using low-latency communication and live data synchronization.

---

## ✨ Features

* 🎥 Real-time 1:1 video sessions using Agora RTC
* 🔐 Secure role-based authentication (Student / Solver) via Apple Sign-In
* ⚡ Live session coordination with Supabase Realtime
* 📸 Media upload and access using Supabase Storage
* 🧠 Structured doubt-solving workflow (request → match → session)
* 📱 Fully programmatic UI (no Storyboards)

---

## 🏗️ Architecture

The project follows the **MVVM (Model-View-ViewModel)** architecture to ensure clean separation of concerns and scalability:

* **Models** – Data structures and session entities
* **Views** – UIKit-based UI components
* **ViewModels** – Business logic and state management
* **Services** – External integrations (Agora, Supabase)

---

## 🛠️ Tech Stack

* **Language:** Swift
* **UI Framework:** UIKit (Programmatic UI)
* **Real-Time Communication:** Agora RTC
* **Backend & Realtime:** Supabase
* **Authentication:** Apple Sign-In
* **Storage:** Supabase Storage

---

## 🎥 Live Session Flow

1. Student submits a doubt request
2. Matching logic assigns an available solver
3. Unique session/channel is created
4. Users join via Agora RTC
5. Real-time interaction begins

---

## 📂 Project Structure

```bash
DoubtlessApp/
├── Models/
├── Views/
│   └── LiveSession/
├── ViewModels/
├── Services/
│   ├── AgoraService.swift
│   ├── SupabaseService.swift
├── Utilities/
```

---

## 🔧 Key Implementation Details

* Custom abstraction layer (`AgoraService`) built over Agora SDK
* Channel-based session management for scalability
* Real-time updates handled via Supabase subscriptions
* Modular service layer for backend communication
* Clean and maintainable UIKit layout using programmatic constraints

---

## 🧪 Future Improvements

* AI-based doubt classification and routing
* Session recording and playback
* Push notifications for session alerts
* Enhanced matching algorithm
* Performance optimization for large-scale usage

---

## 👨‍💻 Author

Developed by **Astitva Mishra**

---

## ⚠️ Disclaimer

This project is independently developed for educational and experimental purposes. It is not affiliated with or intended to replicate any existing commercial platform.
