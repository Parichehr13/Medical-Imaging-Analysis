# Medical Imaging Analysis

Curated MATLAB portfolio project covering classical medical image analysis workflows across multimodal registration, level-set segmentation, quantitative morphometry, and 3D reconstruction.

The repository is best read as one compact imaging-analysis portfolio rather than as a framework: it collects representative studies on MRI, CT, and PET data, with an emphasis on interpretable classical methods, visual validation, and physically meaningful measurements.

## Overview

The project is organized around four complementary tasks:

- **Multimodal registration:** align T2 MRI, DWI MRI, PET, and rotated MRI slices using SSD, NCC, and mutual information.
- **Classical segmentation:** segment renal, cardiac, and breast structures with Malladi-Sethian and Chan-Vese level-set methods.
- **Quantitative morphometry:** compute structure-specific areas in `mm^2` and volumetric estimates in `mm^3`.
- **3D reconstruction:** reconstruct the left atrium from slice-wise MRI segmentation.

## Main Components

- [`Medical_Image_Registration/`](Medical_Image_Registration) implements resolution harmonization, translation and rotation search, similarity heatmaps, and checkerboard-based registration assessment.
- [`Medical_Image_Segmentation/Kidney_Segmentation/`](Medical_Image_Segmentation/Kidney_Segmentation) combines ROI-based registration, Chan-Vese segmentation, and kidney/medulla/cortex area estimation.
- [`Medical_Image_Segmentation/Cardiac_Ventricle_Segmentation/`](Medical_Image_Segmentation/Cardiac_Ventricle_Segmentation) segments left and right ventricular cavities from short-axis cardiac MRI.
- [`Medical_Image_Segmentation/Left_Atrium_Segmentation/`](Medical_Image_Segmentation/Left_Atrium_Segmentation) performs slice-by-slice atrial segmentation, volume estimation, and 3D surface reconstruction.
- [`Medical_Image_Segmentation/MR_Breast_Segmentation/`](Medical_Image_Segmentation/MR_Breast_Segmentation) applies an edge-based level-set workflow to breast lesion delineation.

## Key Outputs

- Registration heatmaps, joint histograms, checkerboard overlays, and summary figures for multimodal alignment
- Segmentation overlays and intermediate contour-evolution visualizations
- Quantitative area and volume estimates reported in physical units
- A 3D left-atrium surface reconstruction from segmented MRI slices

## Representative Methods

- Similarity metrics: `SSD`, `NCC`, `MI`
- Segmentation models: `Malladi-Sethian`, `Chan-Vese`
- Preprocessing: intensity normalization, sigmoid contrast enhancement, Gaussian smoothing, anisotropic diffusion
- Post-processing: connected-component filtering, morphological cleanup, surface extraction

## Repository Structure

```text
Medical-Imaging-Analysis/
|-- Medical_Image_Registration/
|   |-- Medical_Image_Registration.m
|   |-- figures/
|   `-- report.md
|-- Medical_Image_Segmentation/
|   |-- Cardiac_Ventricle_Segmentation/
|   |-- Kidney_Segmentation/
|   |-- Left_Atrium_Segmentation/
|   `-- MR_Breast_Segmentation/
|-- data/
|-- lib/
`-- README.md
```

## Requirements

- MATLAB with Image Processing Toolbox and DICOM support
- Repository helper functions in [`lib/`](lib)
- Input datasets stored in [`data/`](data)
- **Optional:** [Iso2Mesh](https://iso2mesh.sourceforge.net/) on the MATLAB path for the 3D reconstruction step in the left-atrium workflow

The MATLAB scripts now resolve `data/` and `lib/` relative to the repository root, which makes the checked-in structure portable across machines.

## Detailed Reports

- Registration: [`Medical_Image_Registration/report.md`](Medical_Image_Registration/report.md)
- Kidney segmentation: [`Medical_Image_Segmentation/Kidney_Segmentation/report.md`](Medical_Image_Segmentation/Kidney_Segmentation/report.md)
- Cardiac ventricle segmentation: [`Medical_Image_Segmentation/Cardiac_Ventricle_Segmentation/report.md`](Medical_Image_Segmentation/Cardiac_Ventricle_Segmentation/report.md)
- Left atrium segmentation and 3D reconstruction: [`Medical_Image_Segmentation/Left_Atrium_Segmentation/report.md`](Medical_Image_Segmentation/Left_Atrium_Segmentation/report.md)
- Breast lesion segmentation: [`Medical_Image_Segmentation/MR_Breast_Segmentation/report.md`](Medical_Image_Segmentation/MR_Breast_Segmentation/report.md)
