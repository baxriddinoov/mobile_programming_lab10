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
