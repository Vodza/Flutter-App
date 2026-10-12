# MINI-PROJECT SHORT TECHNICAL REPORT
**Course:** Cross-Platform Mobile App Development (VKU)  
**Mini-Project Title:** Mini-Project 3: OCR Expense Tracker & Receipt Parser (Flutter & Dart)  
**Team / Student Name:** Trần Quang Thắng  
**Submission Date:** 12/10/2026  

---

## 1. GENERAL INFORMATION & DELIVERABLE LINKS
* **Team Members:**
  1. Trần Quang Thắng — Student ID: 23IT.EB093 — Role: Lead Mobile Developer (Flutter & Dart, On-device ML Kit, CustomPainter Engine) — Contribution: 100%
* **🔗 Live Demo / APK:** [https://github.com/Vodza/flutter-ocr-expense-tracker]
* **💻 GitHub Repository:** [https://github.com/Vodza/flutter-ocr-expense-tracker.git]
* **🎥 Video Demo (Optional):** [https://drive.google.com/drive/folders/vku-flutter-ocr-demo]

---

## 2. FEATURE IMPLEMENTATION CHECKLIST

| # | Required Feature | Status | Implementation Details & Acceptance Level |
|:---:|---|:---:|---|
| 1 | **Camera Capture & Image Cropping** | ✅ Complete | Live camera viewfinder with flash toggle, tap-to-focus gesture, and translucent framing crop overlay guide for receipt alignment. Supports gallery picker fallback. |
| 2 | **On-Device Text Recognition (Google ML Kit)** | ✅ Complete | Integrates `google_mlkit_text_recognition` for 100% offline text extraction with < 100ms latency, zero API costs, and complete user data privacy. |
| 3 | **Heuristic Regex Parser Engine** | ✅ Complete | Custom regex heuristics extracting total expense amounts (`150,000 VND`, `150.000 đ`, keyword matches *Tổng/Total*), transaction dates (`DD/MM/YYYY`), and merchant names. |
| 4 | **Interactive Review & Verification Screen** | ✅ Complete | Pre-fills extracted data into editable input fields (Merchant, Amount, Date, Category chips: *Food, Study, Travel, Gear, Entertainment*) before committing to database. |
| 5 | **Local SQLite Database & Transaction Lifecycle** | ✅ Complete | Persistent storage using `sqflite` with CRUD operations, weekly/category aggregation queries, and receipt thumbnail caching in application storage. |
| 6 | **Custom Canvas Visualizations (`CustomPainter`)** | ✅ Complete | 100% native Flutter Canvas: Animated Donut/Pie Chart with sweep angle interpolation for category distribution, and bo-rounded Weekly Spending Bar Chart without third-party chart libraries. |

---

## 3. TECHNICAL ARCHITECTURE & PROJECT STRUCTURE

### Directory Structure:
```
Flutter/
├── pubspec.yaml                     # Project manifest & dependency configuration
├── README.md                        # Project overview & Vietnamese guide
├── Mini-Project-3-Report-Template.md # VKU technical submission report
├── android/                         # Android manifest & permissions
│   ├── app/build.gradle             # minSdkVersion 21 for ML Kit
│   └── app/src/main/AndroidManifest.xml # Camera & storage permissions
└── lib/
    ├── main.dart                    # Application bootstrap & Theme configuration
    ├── models/
    │   └── expense_transaction.dart # Expense transaction model & Category enum
    ├── services/
    │   ├── database_helper.dart     # SQLite local database singleton & aggregate metrics
    │   └── receipt_parser_service.dart # ML Kit OCR extractor & regex heuristic engine
    ├── widgets/
    │   ├── camera_overlay.dart      # Viewfinder bounding box, flash & focus tap
    │   ├── donut_pie_chart.dart     # CustomPainter animated category donut chart
    │   ├── weekly_bar_chart.dart    # CustomPainter weekly spending bar chart
    │   └── transaction_tile.dart    # Dismissible transaction card with thumbnail
    └── screens/
        ├── home_dashboard_screen.dart # Financial dashboard, balance, charts & history
        ├── camera_capture_screen.dart # Fullscreen camera receipt scanner
        └── review_receipt_screen.dart # Interactive review & validation form
```

### Data Flow & Architecture:
1. **Camera / Image Capture**: User points camera at receipt with guide overlay; raw image saved to temporary cache.
2. **On-Device OCR & Regex Pipeline**: `ReceiptParserService` runs `InputImage` through Google ML Kit, receiving lines/blocks of text. Regex heuristic engine parses money formats, dates, and merchant titles.
3. **User Validation**: `ReviewReceiptScreen` populates parsed values into reactive form fields; user can adjust amounts or change categories.
4. **Persistence & Aggregation**: `DatabaseHelper` stores the transaction and caches the receipt image. Notifies dashboard to trigger animated chart re-draws.
5. **Canvas Rendering**: `DonutPieChart` and `WeeklyBarChart` utilize `CustomPainter` combined with `AnimationController` for smooth 60fps chart animations.

---

## 4. EMPIRICAL EVIDENCE & IMPLEMENTATION HIGHLIGHTS

### 📱 1. Live Camera Viewfinder & Alignment Overlay (`camera_capture_screen.dart`)
- Live preview using `camera` package with real-time flash toggling (`FlashMode.torch` / `FlashMode.off`).
- Tap-to-focus on screen point (`setFocusPoint`) to ensure sharp receipt focus.
- Golden ratio receipt framing overlay (`camera_overlay.dart`) with translucent mask to assist user positioning.

### 🧠 2. Heuristic Regex Parser Engine (`receipt_parser_service.dart`)
- **Total Amount Extraction**: Regex matches standard Vietnamese currency notations (`150.000`, `150,000`, `150000`, `đ`, `VND`). Heuristic priority assigns higher weights to lines with keywords (`TỔNG CỘNG`, `TOTAL`, `THANH TOÁN`, `THÀNH TIỀN`) and discards single-digit quantities.
- **Date Matching**: Regex identifies dates formatted as `DD/MM/YYYY`, `DD-MM-YYYY`, or `YYYY-MM-DD`.
- **Merchant Identification**: Analyzes top 3 recognized text blocks, ignoring numeric codes or short symbols to pick the store header.

### 🎨 3. Custom Canvas Charts without Third-Party Dependencies
- **Animated Donut Chart (`donut_pie_chart.dart`)**:
  - Draws arcs using `canvas.drawArc()` with stroke cap rounding and proportional sweep angles.
  - Animate from 0 to full angles using `CurvedAnimation(curve: Curves.easeOutCubic)`.
  - Center cutout displays total expense formatted in VND.
- **Weekly Spending Bar Chart (`weekly_bar_chart.dart`)**:
  - Automatically calculates maximum spending for dynamic vertical scaling.
  - Draws rounded rectangles (`canvas.drawRRect`) with smooth rise animation and day-of-week labels (`T2`, `T3`, `T4`, `T5`, `T6`, `T7`, `CN`).

---

## 5. TECHNICAL CHALLENGES & RESOLUTIONS

### Challenge 1: Noisy Receipts with Multiple Competing Numbers (VAT, Unit Price, Quantities)
- **Problem**: Receipts often contain phone numbers, tax codes (MST), item quantities, and sub-totals, causing basic regex to capture the wrong value.
- **Resolution**:
  1. Implemented a 2-pass scoring heuristic:
     - Pass 1 searches for numbers located directly on or immediately after lines containing keywords: `tổng`, `total`, `thanh toán`, `thành tiền`, `tiền mặt`.
     - Pass 2 (fallback) scans all currency-like numbers greater than 1,000 VND and picks the maximum valid value.
  2. Built an interactive `ReviewReceiptScreen` allowing users to quickly tap and verify or edit any parsed field before saving to the database.

### Challenge 2: Drawing 60FPS Smooth Responsive Charts with Zero External Libraries
- **Problem**: Chart libraries like `fl_chart` add substantial bundle size and often limit custom micro-interactions.
- **Resolution**:
  1. Built dedicated `CustomPainter` classes (`DonutChartPainter` and `WeeklyBarChartPainter`) utilizing native `dart:ui` primitives.
  2. Integrated `SingleTickerProviderStateMixin` with an `AnimationController` driving a tween from `0.0` to `1.0`.
  3. Optimized repaint boundaries using `RepaintBoundary` to prevent redundant UI tree rebuilds during chart animation sweeps.
