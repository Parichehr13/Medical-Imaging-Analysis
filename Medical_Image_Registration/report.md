# Multimodal Image Registration Report

This report describes a complete **multimodal image registration pipeline** for four medical images:

- `MRI_T2.dcm`
- `MRI_DWI.dcm`
- `PET.dcm`
- `MRI_T2_rot.dcm`

The workflow includes image loading, spatial-resolution harmonization, zero padding, exhaustive translation search, exhaustive rotation search, visual assessment with checkerboard overlays, and evaluation through **SSD**, **NCC**, and **Mutual Information (MI)**.

The implementation follows the requirements of the multimodal registration exercise and uses **MRI T2** as the reference image for translation-based registration.

## 1. Objective

The goal of this exercise is to align multiple imaging modalities into a common spatial frame so that anatomical structures can be compared consistently across acquisitions.

The main tasks are:

1. load the DICOM images and inspect their size and resolution,
2. resample the floating images to match the reference spatial resolution,
3. apply zero padding to obtain a common image size,
4. estimate the best translation for DWI and PET relative to T2,
5. estimate the best rotation for `MRI_T2_rot` relative to `MRI_T2`,
6. evaluate the registration results using SSD, NCC, and MI,
7. visualize the final alignment using checkerboard overlays and summary figures.

## 2. Reference Image Selection

The **T2-weighted MRI** image was selected as the reference image.

This choice is justified by two main reasons:

- it has the **highest in-plane resolution** among the available modalities,
- it provides a detailed anatomical representation that is suitable as a geometric reference for both DWI and PET.

### Input image sizes

| Image | Size (pixels) |
| --- | ---: |
| MRI T2 | 512 Ã— 512 |
| MRI DWI | 128 Ã— 128 |
| PET | 128 Ã— 128 |
| MRI T2 Rot | 512 Ã— 512 |

### Pixel spacing

| Image | Pixel spacing (mm) |
| --- | ---: |
| MRI T2 | 0.449 Ã— 0.449 |
| MRI DWI | 1.750 Ã— 1.750 |
| PET | 2.5743 Ã— 2.5743 |
| MRI T2 Rot | 0.449 Ã— 0.449 |

## 3. Resolution Harmonization and Padding

Before similarity evaluation, the floating images were resampled to match the spatial resolution of the T2 reference image using `imresize`.

### Scaling factors

The scaling factors were computed from the ratio between the floating-image pixel spacing and the T2 pixel spacing:

- **DWI â†’ T2**: `3.8976`
- **PET â†’ T2**: `5.7333`

### Image sizes after scaling

| Image | Size after scaling |
| --- | ---: |
| MRI T2 | 512 Ã— 512 |
| MRI DWI (scaled) | 499 Ã— 499 |
| PET (scaled) | 734 Ã— 734 |

After resampling, all images were zero-padded to a common field of view using the custom `zeroPadding` function. This step ensures that similarity metrics are computed between images of compatible size.

## 4. Translation Registration

Translation-based registration was performed for:

- **T2 vs DWI**
- **T2 vs PET**

A full 2D exhaustive search was carried out over the range:

- `dx, dy âˆˆ [-20, 20]`

For each candidate translation, the following similarity maps were computed:

- **SSD** â€” Sum of Squared Differences
- **NCC** â€” Normalized Cross Correlation
- **MI** â€” Mutual Information

Although all three metrics were evaluated, the final translation applied to the floating images was selected from the **NCC optimum**, because NCC produced visually coherent results and is robust when comparing images with similar anatomical structure but different intensity scaling.

### Best translation-metric values

#### DWI registration

- minimum SSD: `1947122952.0000`
- maximum NCC: `0.9329`
- maximum MI: `0.9518`

#### PET registration

- minimum SSD: `2192681244.0000`
- maximum NCC: `0.9649`
- maximum MI: `0.8851`

### Selected translations

| Floating image | Best translation [x y] (pixels) |
| --- | ---: |
| MRI DWI | `[-1, -1]` |
| PET | `[6, -16]` |

After selecting the optimal shifts, the translated DWI and PET images were generated using `imtranslate`.

## 5. Translation Registration Assessment

To evaluate the translation results, the registered floating images were compared with the T2 reference through:

- **2D heatmaps** of SSD and NCC,
- **MI heatmaps**,
- **checkerboard overlays**.

The heatmaps allow inspection of the similarity landscape and confirmation that the optimum is well localized. The checkerboard visualizations provide a qualitative anatomical assessment of the final overlap.

### Interpretation

The DWI registration produced a strong NCC maximum (`0.9329`) and a high MI value (`0.9518`), indicating good alignment with the T2 image.

The PET registration also produced a high NCC maximum (`0.9649`), although the final MI remained lower than in the DWI case (`0.8837` after registration), which is expected because PET and MRI represent different physical properties and therefore have larger intrinsic intensity differences.

## 6. Rotation Registration

Rotation-based registration was performed between:

- `MRI_T2.dcm`
- `MRI_T2_rot.dcm`

An exhaustive angular search was carried out over:

- angle range: `0Â°` to `359.5Â°`
- step size: `0.5Â°`

At each angle, the rotated image was compared against the T2 reference using:

- SSD
- NCC
- MI

### Optimal rotation

All three metrics identified the same optimal angle:

- **SSD minimum** at `340.00Â°`
- **NCC maximum** at `340.00Â°`
- **MI maximum** at `340.00Â°`

This agreement among the three metrics strongly supports the correctness of the estimated rotation.

The rotated image registered with the best NCC angle was then used as the final rotation-corrected result.

## 7. Rotation Registration Assessment

The quality of the rotational alignment was assessed through:

- side-by-side image comparison,
- joint histogram visualization,
- checkerboard overlay,
- plots of SSD, NCC, and MI as functions of rotation angle.

These plots show a clear optimum at `340.00Â°`, confirming that the search strategy correctly identified the alignment angle.

## 8. Final Mutual Information Values

After completing all registration steps, the final mutual-information values between each registered pair were computed:

| Registered pair | Final MI |
| --- | ---: |
| T2 vs T2_rot_registered | 2.9144 |
| T2 vs DWI_registered | 0.9471 |
| T2 vs PET_registered | 0.8837 |

The highest MI value is obtained for the T2/T2_rot pair, which is expected because these two images come from the same modality and differ mainly by rotation. The lower MI values for DWI and PET reflect the multimodal nature of the comparisons.

## 9. Final Registration Summary Table

| Image | Scaling factor | Translation [x y] (pixels) | Rotation |
| --- | ---: | ---: | ---: |
| `MR_T2.dcm` | REF | `[0, 0]` | `-` |
| `MRI_DWI.dcm` | 3.8976 | `[-1, -1]` | `-` |
| `PET.dcm` | 5.7333 | `[6, -16]` | `-` |
| `MRI_T2_rot.dcm` | `-` | `-` | `340.00Â°` |

## 10. Generated Visual Outputs

The MATLAB pipeline produces a complete set of figures to document the registration process:

- rescaling and padding overview,
- SSD/NCC heatmaps for DWI and PET,
- MI heatmaps,
- checkerboard view for T2 vs DWI,
- checkerboard view for T2 vs PET,
- rotation-registration comparison for T2 vs T2_rot,
- joint histogram after rotation correction,
- checkerboard view for T2 vs T2_rot,
- metric-vs-angle plots,
- bar chart comparing final MI values,
- automatic summary reports for each registered pair.

These figures support both qualitative and quantitative evaluation of the registration pipeline.

## 11. Files Included

- `Medical_Image_Registration.m` â€” full MATLAB script implementing the registration workflow
- `SSD.m` â€” Sum of Squared Differences metric
- `NCC.m` â€” Normalized Cross Correlation metric
- `MI.m` â€” Mutual Information metric
- `zeroPadding.m` â€” helper function for field-of-view harmonization
- `checkerboard_view.m` â€” visual comparison utility
- report figures saved in the repository folder

## 12. Conclusion

The implemented workflow successfully performs **multimodal registration** between T2, DWI, PET, and rotated T2 images.

The main outcomes are:

- the **T2 image** was chosen as the anatomical reference,
- DWI and PET were resampled and padded before translation search,
- the best translations were estimated as `[-1, -1]` for DWI and `[6, -16]` for PET,
- the best rotation for `MRI_T2_rot` was `340.00Â°`,
- checkerboard views and metric maps confirmed a satisfactory final alignment.

Overall, the pipeline provides a complete and coherent solution to the multimodal registration exercise, combining physically consistent preprocessing, exhaustive optimization, metric-based evaluation, and effective visualization.

