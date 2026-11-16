# Teach It, Ship It: Teachable Machine Image Classifier in Flutter

An on-device machine learning Flutter application running a custom 6-class image classification model trained in Google's Teachable Machine and deployed with TensorFlow Lite (`tflite_flutter`), operating completely offline.

---

## 🎯 Model & Classes

The model was exported from Google Teachable Machine as a floating-point TensorFlow Lite model (`assets/model/model_unquant.tflite`) with input shape `[1, 224, 224, 3]` and output probabilities for **6 classes**:

1. **`Pen`** — Stationery writing ballpoint pen
2. **`Laptop`** — Laptop computer / open notebook on desk
3. **`Empty Desk`** — Empty tabletop / workspace (*Background class*)
4. **`Coffee Mug`** — Ceramic coffee and tea mug
5. **`Phone`** — Smartphone / mobile phone device
6. **`Water bottle`** — Drinking water bottle / tumbler

---

## 📱 App Architecture & Screens

The app is built using a unified Material 3 theme (`lib/theme/app_theme.dart`) and consists of 5 core screens:

1. **Welcome Screen** (`lib/screens/welcome_screen.dart`): App description, model class chips, start-up model loading indicator, and error handling.
2. **Home Screen** (`lib/screens/home_screen.dart`): Three distinct input source triggers (**Camera**, **Gallery**, and **Web Download**) plus preview of the most recent classification.
3. **Result Screen** (`lib/screens/result_screen.dart`): Centered uncropped image (`BoxFit.contain`, max half screen), progress gauge for every label with percentages, highlighted top class, and source badge.
4. **History Screen** (`lib/screens/history_screen.dart`): Session history (newest first) with image thumbnails, top predictions, percentages, source icons, and tap-to-reopen without re-running inference.
5. **Model Screen** (`lib/screens/model_screen.dart`): Model metadata (file name, tensor input size, normalization range, parsed labels from `labels.txt`) and design credits.

---

## 🛠️ Tech Stack & Dependencies

- **Flutter 3.x / Dart 3.x**
- `tflite_flutter: ^0.12.1` — On-device C-API TensorFlow Lite bindings
- `image_picker: ^1.2.4` — Camera capture and photo gallery picker
- `image: ^4.13.1` — Pure Dart EXIF orientation correction, centre-cropping, and resizing
- `http: ^1.6.0` — Web image download with status code and MIME validation

---

## 🧪 Testing & Verification

Run the test suite:
```powershell
flutter test
```
*Result: All unit tests in `test/labels_test.dart` pass.*

Run static analysis:
```powershell
flutter analyze
```
*Result: No issues found!*

---

## 🚀 Running the App

```powershell
flutter run
```

---

## 📋 Lab Notes & Evaluation

See [`NOTES.md`](NOTES.md) for full answers to:
- Inline questions for Parts 1–5
- 18-attempt evaluation table across Camera, Gallery, and Download sources
- Answers to all 5 checkpoint questions
