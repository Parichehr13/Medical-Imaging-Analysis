# Medical Imaging Analysis

MATLAB-based repository for **medical image registration** and **medical image segmentation**.

This project presents practical implementations of classical medical image analysis workflows on real datasets, including **multimodal registration**, **level set segmentation**, **active contours**, and **3D anatomical reconstruction**.

---

## Overview

The repository is organized into two main parts:

- **Medical Image Registration**
- **Medical Image Segmentation**

The implemented workflows include:

- **Multimodal image registration** using:
  - Sum of Squared Differences (**SSD**)
  - Normalized Cross Correlation (**NCC**)
  - Mutual Information (**MI**)
- **Segmentation** using:
  - **Malladi-Sethian** level set model
  - **Chan-Vese** active contour model
- **Preprocessing** techniques such as:
  - intensity normalization
  - Gaussian filtering
  - anisotropic diffusion
- **Post-processing** with morphological operations
- **Quantitative analysis**:
  - area estimation in **mm^2**
  - volume estimation in **mm^3**
- **3D reconstruction** from segmented MRI data

---

## Repository Structure

```text
Medical-Imaging-Analysis/
|-- Medical_Image_Registration/
|   |-- report.md
|   `-- ...
|-- Medical_Image_Segmentation/
|   |-- Kidney_Segmentation/
|   |   |-- report.md
|   |   `-- ...
|   |-- Cardiac_Ventricle_Segmentation/
|   |   |-- report.md
|   |   `-- ...
|   |-- Left_Atrium_Segmentation/
|   |   |-- report.md
|   |   `-- ...
|   |-- MR_Breast_Segmentation/
|   |   |-- report.md
|   |   `-- ...
|   `-- ...
`-- README.md
```

---

## Medical Image Registration

This section focuses on **multimodal registration** between:

- **MRI T2**
- **MRI DWI**
- **PET**
- **Rotated MRI T2**

### Main operations

- DICOM loading and metadata extraction
- spatial resolution harmonization through rescaling
- zero padding for consistent image size
- exhaustive 2D search for the best **translation**
- exhaustive search for the best **rotation**
- metric-based comparison using **SSD**, **NCC**, and **MI**
- qualitative validation through **checkerboard visualization**
- joint histogram analysis and summary reporting

### Detailed report

See:

- [`Medical_Image_Registration/report.md`](Medical_Image_Registration/report.md)

---

## Medical Image Segmentation

This section contains multiple segmentation tasks based on **level set methods** applied to medical DICOM and MRI datasets.

### Included projects

#### 1. Kidney Segmentation

Segmentation of the **left kidney**, **medulla**, and **cortex** from abdominal CT data using the **Chan-Vese model**, including registration between acquisitions and area quantification.

Detailed report:

- [`Medical_Image_Segmentation/Kidney_Segmentation/report.md`](Medical_Image_Segmentation/Kidney_Segmentation/report.md)

#### 2. Cardiac Ventricle Segmentation

Segmentation of the **left ventricle (LV)** and **right ventricle (RV)** endocardial regions from a short-axis cardiac image using the **Malladi-Sethian model**.

Detailed report:

- [`Medical_Image_Segmentation/Cardiac_Ventricle_Segmentation/report.md`](Medical_Image_Segmentation/Cardiac_Ventricle_Segmentation/report.md)

#### 3. Left Atrium Segmentation

Slice-by-slice **3D segmentation of the left atrium** from cardiac MRI data using the **Chan-Vese model**, with **volume estimation** and **3D mesh reconstruction**.

Detailed report:

- [`Medical_Image_Segmentation/Left_Atrium_Segmentation/report.md`](Medical_Image_Segmentation/Left_Atrium_Segmentation/report.md)

#### 4. MR Breast Lesion Segmentation

Segmentation of a breast lesion in a contrast-enhanced MR image using the **Malladi-Sethian level set model**, including contour extraction and area estimation.

Detailed report:

- [`Medical_Image_Segmentation/MR_Breast_Segmentation/report.md`](Medical_Image_Segmentation/MR_Breast_Segmentation/report.md)

---

## Methods Used

### Registration

- **SSD**
- **NCC**
- **Mutual Information**
- translation search
- rotation search
- checkerboard visualization
- joint histogram analysis

### Segmentation

- **Malladi-Sethian active contours**
- **Chan-Vese active contours**
- morphological refinement
- area and volume computation
- 3D mesh generation

### Preprocessing

- intensity normalization
- Gaussian smoothing
- anisotropic diffusion filtering
- sigmoid contrast enhancement

---

## Requirements

This project was developed in **MATLAB** and relies on:

- standard MATLAB image processing functions
- DICOM support
- custom helper functions stored in `mylibs`
- optionally, **Iso2Mesh** for 3D mesh generation

---
