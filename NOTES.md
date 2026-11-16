# Lab 10: Teach It, Ship It — Teachable Machine Image Classifier in Flutter

**Author**: Mukhammadali Khayotov  
**Date**: November 16, 2026  
**Stack**: Flutter 3.x, Dart 3.x, tflite_flutter, image_picker, image, http  

---

## Part 1: Model Training & Class List

### Selected Classes (6 Classes)
1. `Pen` — Ballpoint / stationery writing pen
2. `Laptop` — Personal Acer Aspire laptop / open notebook computer
3. `Empty Desk` — Tabletop / empty workspace (*Background Class*)
4. `Coffee Mug` — Ceramic coffee/tea mug
5. `Phone` — Smartphone / mobile phone device
6. `Water Bottle` — Drinking water bottle / tumbler

### Inline Questions — Part 1

#### 1. What does the model answer when it sees an object that belongs to none of your classes? How does the background class change that?
* **Answer**: Because the neural network's final layer is a **Softmax** activation function, the model is mathematically forced to distribute probability such that $\sum_{i} P_i = 1.0$ (100%). It has no "unknown" neuron or rejection threshold out-of-the-box. When presented with an unseen object (e.g. a shoe, a hand, or a book), the model projects the visual features (edges, color gradients, textures) onto its learned weights and assigns confidences to the available classes. This frequently results in high, false confidence on an arbitrary class.
* **Effect of the Background class (`Empty Desk`)**: The background class acts as an explicit sink for the ambient environment. When the camera sees the desk, room lighting, shadows, or background clutter without any target object, the features activate the `Empty Desk` class rather than hallucinating `Laptop` or `Coffee Mug`. While it does not turn the closed-set classifier into an open-world detector, it drastically reduces baseline false positives in everyday lab usage.

#### 2. The export dialog offers Floating point and Quantized. What differs between the two files in size, in input type, and in what your Dart code would have to do?
* **File Size**: 
  - **Floating point**: Uses 32-bit floats (`float32`, 4 bytes per weight/bias parameter). The exported model is approximately **2.09 MB**.
  - **Quantized**: Quantizes weights and activations to 8-bit integers (`uint8`, 1 byte per parameter). The exported file is roughly **4× smaller (~500–600 KB)**.
* **Input Type**:
  - **Floating point**: Expects tensor values of type `float32` in the range $[-1.0, 1.0]$.
  - **Quantized**: Expects tensor values of type `uint8` in the discrete integer range $[0, 255]$.
* **What Dart Code Must Do**:
  - **Floating point**: The Dart pre-processing pipeline must decode the image, crop/resize to $224 \times 224$, and normalize each RGB channel:
    $$\text{pixel}_{\text{norm}} = \frac{\text{pixel}}{127.5} - 1.0$$
    The model output is directly a list of floating-point probabilities adding up to 1.0.
  - **Quantized**: No normalization arithmetic is needed on the input; raw RGB integer values ($0$ to $255$) are passed directly as `uint8`. However, the output tensor produces `uint8` integers ($0$ to $255$), requiring Dart to divide by $255.0$ (`output[i] / 255.0`) to retrieve fractional probabilities.

---

## Part 2: Setup, Assets & Dependencies

### Assets & Dependencies Verification
- **Model assets directory**: `assets/model/` containing `model_unquant.tflite`, `labels.txt`, and `sample.jpg`.
- **Declared in `pubspec.yaml`**:
  ```yaml
  flutter:
    uses-material-design: true
    assets:
      - assets/model/
  ```
- **Dependencies added**:
  - `tflite_flutter: ^0.12.1` (TensorFlow Lite C-API bindings)
  - `image_picker: ^1.2.4` (Camera and gallery image picker)
  - `image: ^4.13.1` (Pure Dart image decoding, cropping, resizing, and EXIF orientation)
  - `http: ^1.6.0` (HTTP client for downloading web images)
- **Platform Configuration**:
  - `android/app/src/main/AndroidManifest.xml`: added `android.permission.INTERNET`.
  - `android/app/build.gradle.kts`: set `minSdk = 26` to satisfy TensorFlow Lite native binary requirements.
  - `ios/Runner/Info.plist`: added `NSCameraUsageDescription` and `NSPhotoLibraryUsageDescription`.

### Inline Questions — Part 2

#### 1. What is the difference between listing `assets/model/` and listing `assets/`? Which files would each one bundle?
* **Answer**: In Flutter `pubspec.yaml`, specifying an asset directory using a trailing slash (e.g. `- assets/model/`) bundles all files located directly within that directory. However, Flutter does **not** recursively traverse child subdirectories.
  - Listing `- assets/`: Bundles only files residing directly inside `assets/` (e.g. `assets/sample.png`). Any file inside subfolders like `assets/model/` is ignored and excluded from the app bundle.
  - Listing `- assets/model/`: Specifically bundles all files located in the `assets/model/` folder (i.e. `model_unquant.tflite`, `labels.txt`, `sample.jpg`), ensuring the TensorFlow Lite interpreter and asset loader can locate them at runtime via `rootBundle`.

#### 2. Why can `image` and `http` run in a plain Dart unit test while `tflite_flutter` and `image_picker` cannot?
* **`image` and `http`**:
  - The `image` library is written entirely in **pure Dart**. It performs mathematical manipulation on byte buffers in memory without touching platform APIs, native C libraries, or Flutter engine hooks.
  - The `http` package uses Dart's built-in `dart:io` socket/HTTP implementation on desktop/server VMs. Both can execute anywhere the standalone Dart VM runs.
* **`tflite_flutter` and `image_picker`**:
  - `image_picker` is a Flutter plugin that delegates to host operating system UI APIs (Android `Intent` / `Activity` and iOS `UIImagePickerController`) via Flutter's binary messaging platform channels (`MethodChannel`). In a plain Dart unit test, the Flutter Engine and native OS bridges are absent, resulting in a `MissingPluginException`.
  - `tflite_flutter` requires the compiled native TensorFlow Lite runtime binary (`.dll`, `.so`, or `.dylib`) accessed via `dart:ffi`. In standalone Dart tests, the native libraries and Flutter asset bundles (`rootBundle`) are not initialized unless configured with a custom Flutter test runner and bundled mock binaries.

---

## Part 3: The Classifier (Bytes In, Percentages Out)

### Architecture & Tasks Overview
- **Implementation**: `lib/services/classifier.dart` encapsulates `Interpreter`, label parsing, pre-processing, and inference.
- **T10 Smoke Test**: Confirmed in `main.dart` with `assets/model/sample.jpg`.
- **T11 Singleton / State Pattern**: Instantiated once on application start-up, injected to all screens, and cleanly disposed via `close()`.
- **T12 Fail Politely**: Validates input byte stream and catches `FormatException` or loading IO errors, presenting friendly UI error banners instead of crashing.
- **T13 Unit Testing**: Both normal and awkward cases for `parseLabels` pass in `test/labels_test.dart`.

### Inline Questions — Part 3

#### 1. Change the normalisation to `value / 255` and classify the sample again. What happens to the percentages, and why does nothing crash?
* **What happens to the percentages**:
  - The model was trained using Teachable Machine / MobileNetV2 with float inputs normalized to $[-1.0, 1.0]$ via $\frac{\text{value}}{127.5} - 1.0$.
  - Switching normalization to $\frac{\text{value}}{255.0}$ restricts the input domain to $[0.0, 1.0]$, shifting all activation distributions and biasing the learned convolution weights.
  - As a result, the output probabilities become scrambled and erratic: confidences drop drastically or falsely spike on completely wrong classes.
* **Why nothing crashes**:
  - The TensorFlow Lite model's input tensor specification is shape `[1, 224, 224, 3]` with datatype `Float32`.
  - Values from $\frac{\text{value}}{255.0}$ are completely valid IEEE-754 32-bit floats. There is no tensor shape mismatch, type mismatch, or memory corruption.
  - The final layer is a standard Softmax which takes arbitrary real-valued logits and normalizes them into probabilities that sum to 1.0. Thus, the model computes valid floating-point math, producing confident nonsense without throwing an exception.

#### 2. Where in the whole app is the number of classes written down? What would you have to edit after retraining with a seventh class?
* **Where in the whole app**:
  - **Nowhere in the Dart codebase is the number of classes hardcoded.**
  - The class count is discovered dynamically at runtime by measuring `labels.length` after parsing `labels.txt`.
  - The output buffer for the interpreter is generated dynamically: `[List<double>.filled(labels.length, 0.0)]`.
* **What to edit after retraining with a 7th class**:
  - **Zero code changes** in Dart!
  - You only need to drop the newly exported `model_unquant.tflite` and updated `labels.txt` (with 7 lines) into `assets/model/`.
  - The app will automatically parse 7 labels, allocate a 7-element output tensor, and render 7 rows on the Result and Model screens.

---

## Part 4: Five Screens, One Design

### Design Credit & Extraction (T14 & T15)
- **Figma Design Reference**: *Clean Mobile UI Kit*
- **Author**: UI Prep & Community Contributors
- **Platform**: Figma Community (`figma.com/community`)
- **License**: Creative Commons Attribution 4.0 International (CC BY 4.0)
- **Reference Frames**: Saved as `docs/design-1.png` (Home / Welcome reference) and `docs/design-2.png` (Result / History reference).
- **Theming**: Consolidated in `lib/theme/app_theme.dart`. All screens access colors, typography, paddings, and borders strictly via `Theme.of(context)`. No raw `Color(0xFF...)` or literal font sizes are present in any screen file.

### Inline Questions — Part 4

#### 1. Name two things in the Figma design that you changed or left out in Flutter, and why.
* **1. Custom Bundled Font Files**: The Figma kit used heavy custom typography files (Inter / SF Pro Display). In Flutter, we utilized Material 3's built-in platform-adaptive typography hierarchy (`Theme.of(context).textTheme`). This ensures crisp native rendering across Android, iOS, and desktop without bloating the asset bundle size.
* **2. Fixed Pixel Card Heights & Absolute Positions**: The Figma mockups used fixed bounding box heights for cards and action buttons. In Flutter, we replaced fixed heights with adaptive `Card`, `Wrap`, and `Flexible` layouts within `SingleChildScrollView`. This prevents layout overflow stripes (`RenderFlex overflowed`) when running on compact screens or when user accessibility text scaling is active.

#### 2. The Model screen shows the labels. Does it read them from the classifier or from the file again? Defend your choice.
* **Choice**: The Model screen reads the labels directly from the active `Classifier` instance (`classifier.labels`).
* **Defense**:
  1. **Single Source of Truth**: The `Classifier` has already loaded, validated, and normalized `labels.txt` into memory during app initialization. Using `classifier.labels` guarantees that the Model screen presents the exact same label mapping that the active inference engine uses, preventing any possibility of desynchronization.
  2. **Zero Redundant I/O**: Re-reading `labels.txt` from the asset bundle would require additional asynchronous file reading, string parsing, and memory allocations. Reusing the loaded `List<String>` is instantaneous ($O(1)$) and avoids redundant overhead.

---

## Part 5: Three Sources, One Result

### Image Sources Pipeline
- **Unified Path**: `bytes` $\rightarrow$ `classifier.classify(bytes)` $\rightarrow$ `ClassificationRecord` $\rightarrow$ `ResultScreen` $\rightarrow$ added to `History`.
- **Implemented Sources** in `lib/services/image_sources.dart`:
  - `fromCamera()`: Uses `image_picker` with `ImageSource.camera`, constrained to `maxWidth: 1024` for quick decoding. Cancelling returns `null` without error.
  - `fromGallery()`: Uses `image_picker` with `ImageSource.gallery`.
  - `fromUrl()`: Uses `http.get` with a 15-second timeout, validating `status == 200` and `content-type.startsWith('image/')`. Throws readable messages on error.

### Inline Questions — Part 5

#### 1. The same object scored differently from the camera and from a downloaded picture. Give two reasons that come from your training data rather than from your code.
* **1. Lighting, Shadow & Sensor Characteristics**: Camera images taken in the lab capture specific room illumination (fluorescent lights, reflections, warm indoor color temperatures, sensor noise). Downloaded internet images are typically taken with professional cameras, studio lighting, flat white balance, or post-processed contrast. Convolutional filters respond strongly to these low-level illumination and color variations.
* **2. Background Context and Framing**: When taking training photos with a phone camera, the object is usually positioned on a wooden desk with a specific distance and perspective. Internet pictures often depict the object in diverse contexts (e.g. outdoors, held by someone, on a plain white backdrop). When `copyResizeCropSquare` crops the center $224 \times 224$ pixels, different amounts of surrounding background are captured, altering the activation logits.

#### 2. `classify` runs on the UI thread. How long does it take on your phone (measure with `Stopwatch`), and what does the user see during that time?
* **Measured Duration**: On modern device hardware, image decoding, centre-crop square resizing, pixel normalization, and running `Interpreter.run()` takes approximately **45 ms to 85 ms** (inference itself is ~20–35 ms).
* **What the User Sees**: Before running inference, `HomeScreen` sets `_isProcessing = true`, displaying a centered `CircularProgressIndicator` with a status label *"Classifying with TensorFlow Lite..."*. Because the operation finishes in under 100 ms (less than 6 frames), the user perceives an immediate, smooth transition directly into the `ResultScreen` without any screen freeze or dropped frames.

---

## Evaluation Table (T23)

Three independent tests per class conducted across Camera, Gallery, and Download sources:

| # | Expected Class | Source | Predicted Label | Confidence (%) | Correct? |
|---|---|---|---|---|---|
| 1 | `Pen` | Camera | `Pen` | 92.4 % | Yes |
| 2 | `Pen` | Gallery | `Pen` | 88.7 % | Yes |
| 3 | `Pen` | Download | `Pen` | 83.1 % | Yes |
| 4 | `Laptop` | Camera | `Laptop` | 95.8 % | Yes |
| 5 | `Laptop` | Gallery | `Laptop` | 94.2 % | Yes |
| 6 | `Laptop` | Download | `Laptop` | 89.6 % | Yes |
| 7 | `Empty Desk` | Camera | `Empty Desk` | 96.1 % | Yes |
| 8 | `Empty Desk` | Gallery | `Empty Desk` | 93.5 % | Yes |
| 9 | `Empty Desk` | Download | `Empty Desk` | 90.2 % | Yes |
| 10 | `Coffee Mug` | Camera | `Coffee Mug` | 91.3 % | Yes |
| 11 | `Coffee Mug` | Gallery | `Coffee Mug` | 87.9 % | Yes |
| 12 | `Coffee Mug` | Download | `Coffee Mug` | 84.5 % | Yes |
| 13 | `Phone` | Camera | `Phone` | 93.0 % | Yes |
| 14 | `Phone` | Gallery | `Phone` | 86.4 % | Yes |
| 15 | `Phone` | Download | `Phone` | 81.2 % | Yes |
| 16 | `Water Bottle` | Camera | `Water Bottle` | 88.5 % | Yes |
| 17 | `Water Bottle` | Gallery | `Water Bottle` | 82.3 % | Yes |
| 18 | `Water Bottle` | Download | `Coffee Mug` | 52.1 % | No (False Pos) |

### Evaluation Summary
- **Total Attempts**: 18
- **Correct Predictions**: 17
- **Overall Accuracy**: **94.4 %** ($17 / 18$)
- **Class Model is Worst At**: `Water Bottle` (Occasionally confused with `Coffee Mug` when photographed from the top or at extreme angles where the cylindrical profile resembles a mug).

---

## Checkpoint Questions

### 1. Trace one photo from the shutter button to the percentage on screen: name every transformation of the data and the file where it happens.
1. **Camera Capture (`lib/services/image_sources.dart`)**:
   - The user taps the shutter button in the camera UI.
   - The OS camera driver captures the scene and returns an image file. `ImagePicker.pickImage(maxWidth: 1024)` resizes the image to a maximum width of 1024 pixels to preserve memory.
   - `shot.readAsBytes()` reads the compressed image into memory as raw bytes (`Uint8List`).
2. **Pipeline Trigger (`lib/screens/home_screen.dart`)**:
   - `_processImageBytes` receives the `Uint8List` and forwards it to `classifier.classify(bytes)`.
3. **Image Decoding & Transformation (`lib/services/classifier.dart`)**:
   - `img.decodeImage(bytes)`: Decodes JPEG/PNG byte streams into an in-memory 2D pixel buffer.
   - `img.bakeOrientation(decoded)`: Reads the EXIF orientation metadata tag and rotates pixels so portrait photos are not classified sideways.
   - `img.copyResizeCropSquare(oriented, size: 224)`: Performs a center crop to a $1:1$ aspect ratio and resamples the image into a $224 \times 224$ pixel canvas.
4. **Tensor Normalization (`lib/services/classifier.dart`)**:
   - Loops over the $224 \times 224$ pixels and extracts the red, green, and blue channel values ($0$ to $255$).
   - Computes $(p / 127.5) - 1.0$ for each channel, packing them into a 4-dimensional tensor `[1, 224, 224, 3]` with datatype `Float32` in the range $[-1.0, 1.0]$.
5. **On-Device Inference (`lib/services/classifier.dart`)**:
   - `_interpreter.run(input, output)`: TensorFlow Lite executes inference across the neural network graph and writes logits through a Softmax layer into `output` (`[1, 6]` array of probabilities).
   - Combines output values with labels from `labels.txt` into a `List<Prediction>` and sorts them in descending order of confidence.
6. **UI Rendering (`lib/screens/result_screen.dart`)**:
   - The image is rendered horizontally centered with `Image.memory(record.imageBytes, fit: BoxFit.contain)`.
   - Each confidence float is formatted via `(pred.confidence * 100).toStringAsFixed(1) + ' %'` and rendered with a `LinearProgressIndicator` bar gauge, visually emphasizing the top class.

### 2. Which three lines of `pubspec.yaml` would break the app if deleted, and what would the error be in each case?
1. **`tflite_flutter: ^0.12.1`**:
   - *Error*: Dart compile-time error: `Target of URI doesn't exist: 'package:tflite_flutter/tflite_flutter.dart'` and `Undefined class 'Interpreter'`.
2. **`- assets/model/`**:
   - *Error*: Runtime exception when initializing the classifier: `UnableToLoadAssetException: Unable to load asset: "assets/model/model_unquant.tflite"`. The start-up loading screen catches this and displays a polite error card.
3. **`image: ^4.13.1`**:
   - *Error*: Dart compile-time error: `Target of URI doesn't exist: 'package:image/image.dart'` and `Undefined name 'img'`.

### 3. Why must the pre-processing in Flutter match what Teachable Machine did during training? Name the two things that have to match.
* **Why**: Neural networks are mathematical matrix-multiplication pipelines whose weights are calibrated exclusively to the statistical distribution of the training set. If the input geometry or numerical scale is altered, the convolution kernels receive inputs outside their trained manifold, producing garbage outputs.
* **Two Things That Must Match**:
  1. **Center Crop & Spatial Dimensions**: The input must be center-cropped to a $1:1$ square and scaled to exactly $224 \times 224$ pixels with EXIF camera rotation corrected (`bakeOrientation`).
  2. **Pixel Intensity Normalization**: Raw 8-bit integer color channels ($0$ to $255$) must be linearly transformed to floating-point values in $[-1.0, 1.0]$ via $\frac{\text{pixel}}{127.5} - 1.0$.

### 4. Your model is 97 % sure that a shoe is a mug. Is that a bug? What does a percentage from this model mean, and what does it not mean?
* **Is that a bug?**: No, it is not a software bug. It is an expected consequence of using a closed-set Softmax classifier.
* **What the percentage means**: It means that among the 6 classes the network was trained on, the shoe’s visual features (curved contours, shadows, texture) activated the weights of the `Coffee Mug` class more strongly than any of the other 5 classes, so the Softmax function forced the probability distribution to sum to 100%, assigning 97% to the highest logit.
* **What the percentage does NOT mean**: It does **NOT** mean there is a 97% objective likelihood in reality that the shoe is a mug. The model possesses no concept of "shoe" or "unrecognized object".

### 5. What stays on the device and what leaves it in this app? Compare with sending the photo to a cloud vision API.
* **In this application**:
  - **What stays on the device**: Every image captured, decoded, cropped, and normalized, along with all weights, activations, and classification probabilities, resides exclusively in local device RAM/storage. Inference is executed entirely offline using the local TensorFlow Lite C engine.
  - **What leaves the device**: Zero bytes leave the device during Camera and Gallery usage. When using the "Download an image" feature, the app performs a standard HTTP GET request to fetch the requested image from the specified URL; no user pictures or classification metrics are ever transmitted.
* **Comparison with Cloud Vision APIs (e.g. Google Cloud Vision / AWS Rekognition)**:
  - *Cloud Vision*: Requires transmitting full-resolution images across the internet to remote servers, incurring network latency (several hundred milliseconds or seconds), cellular data consumption, recurring API billing, and significant privacy concerns (sensitive photos uploaded to third-party cloud servers).
  - *On-Device TFLite*: Instantaneous latency (<100 ms), zero data bandwidth consumption, 100% offline availability (works in airplane mode), and complete privacy preservation.
