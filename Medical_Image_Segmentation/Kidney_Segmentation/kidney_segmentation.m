%% ========================================================================
%  SEGMENTATION OF RENAL STRUCTURES FROM DUAL CT IMAGES (CONTRAST/NON-CONTRAST)
%  Registration, Preprocessing, Chan–Vese Evolution, and Area Quantification
% ========================================================================

%% --------------------- 1. INITIALIZATION & IMAGE LOADING ---------------------
clc; clear; close all;
repoRoot = fileparts(fileparts(fileparts(mfilename('fullpath'))));
addpath(genpath(fullfile(repoRoot, 'lib')));

% Load DICOM images
info_fixed  = dicominfo(fullfile(repoRoot, 'data', 'IM3696'));   % No contrast
info_moving = dicominfo(fullfile(repoRoot, 'data', 'IM1883'));   % With contrast

I_fixed  = double(dicomread(info_fixed));
I_moving = double(dicomread(info_moving));
pixel_spacing = info_moving.PixelSpacing;

fprintf('\n=== Image Information ===\n');
fprintf('Fixed image (no contrast)      : %d × %d pixels\n', size(I_fixed));
fprintf('Moving image (with contrast)   : %d × %d pixels\n', size(I_moving));
fprintf('Pixel spacing                  : [%.3f mm, %.3f mm]\n', ...
        pixel_spacing(1), pixel_spacing(2));

%% --------------------- 2. TRANSLATIONAL REGISTRATION ---------------------
% ROI-based alignment using normalized cross-correlation (NCC)

figure; imshow(I_fixed, []); axis image;
title('Select ROI for registration');
roi = round(getrect()); close;

crop_fixed  = imcrop(I_fixed, roi);
crop_moving = imcrop(I_moving, roi);

[~, reg_params, ~] = smartRegister(crop_fixed, crop_moving, ...
    'trasl', 'metric', 'NCC', 'verbose', true, 'max_shift', 30);
translation = reg_params.translation;
fprintf('✓ Estimated translation        : Δx = %.1f px, Δy = %.1f px\n', ...
        translation(1), translation(2));

I_moving_registered = imtranslate(I_moving, translation, 'FillValues', 0);

%% --------------------- 3. ROI SELECTION FOR SEGMENTATION ---------------------
figure; imshow(I_fixed, []); axis image;
title('Select ROI for segmentation');
roi = round(getrect()); close;

x_start = max(1, roi(1));
y_start = max(1, roi(2));
x_end   = min(size(I_fixed,2), x_start + roi(3) - 1);
y_end   = min(size(I_fixed,1), y_start + roi(4) - 1);

I_fixed_crop      = I_fixed(y_start:y_end, x_start:x_end);
I_registered_crop = I_moving_registered(y_start:y_end, x_start:x_end);

roi_width  = x_end - x_start + 1;
roi_height = y_end - y_start + 1;

fprintf('\n=== Segmentation ROI ===\n');
fprintf('Top-left corner         : (x = %d, y = %d)\n', x_start, y_start);
fprintf('Size                    : %d × %d pixels\n', roi_width, roi_height);

%% --------------------- 4. IMAGE PREPROCESSING ---------------------
I_fixed_norm      = (I_fixed_crop - min(I_fixed_crop(:))) / (max(I_fixed_crop(:)) - min(I_fixed_crop(:)));
I_registered_norm = (I_registered_crop - min(I_registered_crop(:))) / (max(I_registered_crop(:)) - min(I_registered_crop(:)));

sigmoid = @(x) 1 ./ (1 + exp(-20 * (x - 0.65)));
I_fixed_sigmoid      = sigmoid(I_fixed_norm);
I_registered_sigmoid = sigmoid(I_registered_norm);

I_fixed_smooth = imgaussfilt(I_fixed_sigmoid, 1.0);

n_iter = 15; delta_t = 1/7; kappa = 30; option = 1;
I_registered_proc = anisodiff2D(I_registered_sigmoid, n_iter, delta_t, kappa, option);

figure('Name', 'Segmentation ROI & Preprocessed Images');
tiledlayout(2,2, 'Padding','compact', 'TileSpacing','compact');
nexttile;
imshow(I_fixed, []); hold on;
rectangle('Position', [x_start, y_start, roi_width, roi_height], 'EdgeColor', 'r', 'LineWidth', 1.5);
title('Fixed Image (No Contrast)'); axis image;
nexttile;
imshow(I_moving_registered, []); hold on;
rectangle('Position', [x_start, y_start, roi_width, roi_height], 'EdgeColor', 'r', 'LineWidth', 1.5);
title('Registered Image (With Contrast)'); axis image;
nexttile;
imshow(I_fixed_smooth, []); title('Preprocessed ROI — Fixed'); axis image;
nexttile;
imshow(I_registered_proc, []); title('Preprocessed ROI — Registered'); axis image;

%% --------------------- 5. KIDNEY SEGMENTATION (CHAN–VESE) ---------------------
Image = I_registered_proc;
max_iter = 200;
dt = 0.1; eps = 1e-6;
mu = 0.5; lambda1 = 30; lambda2 = -30; ni = 0.0;
radius = 30;

[phi, ~, ~, center_seed] = computeLSF( ...
    'InputImage', Image, ...
    'InteractiveCenter', true, ...
    'Radius', radius, ...
    'InsidePositive', false);

area_track = zeros(1, max_iter);
for i = 1:max_iter
    [phi_x, phi_y] = gradient(phi);
    normGrad = sqrt(phi_x.^2 + phi_y.^2 + eps);
    Nx = phi_x ./ normGrad;
    Ny = phi_y ./ normGrad;
    curvature = divergence(Nx, Ny);

    inside  = phi < 0;
    outside = ~inside;
    c1 = sum(Image(inside)) / (nnz(inside) + eps);
    c2 = sum(Image(outside)) / (nnz(outside) + eps);

    phi = phi + dt * (mu * curvature + ni + ...
        lambda1 * (Image - c1).^2 + lambda2 * (Image - c2).^2);
    area_track(i) = nnz(phi < 0);

    if mod(i,2) == 1
        figure(100); imagesc(Image); colormap gray; axis image off; hold on;
        contour(phi, [0 0], 'r', 'LineWidth', 1.5);
        title(sprintf('Chan–Vese Iteration %d', i)); drawnow;
        hold off;
    end
    if i > 10
        delta = abs(area_track(i) - area_track(i-10)) / (area_track(i) + eps);
        if delta < 0.01
            fprintf('✓ Kidney segmentation converged at iteration %d\n', i);
            break;
        end
    end
end

BW = phi < 0;
marker = false(size(BW));
x0 = round(center_seed(1));
y0 = round(center_seed(2));
if x0 >= 1 && x0 <= size(BW,2) && y0 >= 1 && y0 <= size(BW,1)
    marker(y0, x0) = true;
else
    warning('Seed point outside ROI bounds');
end

mask_kidney = imreconstruct(marker, BW);
mask_kidney = imfill(mask_kidney, 'holes');
phi_kidney = phi;

[x_phi_kidney, y_phi_kidney] = meshgrid(0:roi_width-1, 0:roi_height-1);
x_phi_kidney = x_phi_kidney + x_start;
y_phi_kidney = y_phi_kidney + y_start;

%% --------------------- 6. MEDULLA SEGMENTATION (CHAN–VESE) ---------------------
Image = I_fixed_smooth;
max_iter = 250;
dt = 0.1; eps = 1e-6;
mu = 0.5; lambda1 = 50; lambda2 = -50; ni = 0.0;
radius = 5;

[phi, X, Y, center_seed] = computeLSF( ...
    'InputImage', Image, ...
    'InteractiveCenter', true, ...
    'Radius', radius, ...
    'InsidePositive', false);

area_track = zeros(1, max_iter);
for i = 1:max_iter
    [phi_x, phi_y] = gradient(phi);
    normGrad = sqrt(phi_x.^2 + phi_y.^2 + eps);
    Nx = phi_x ./ normGrad;
    Ny = phi_y ./ normGrad;
    curvature = divergence(Nx, Ny);

    inside  = phi < 0;
    outside = ~inside;
    c1 = sum(Image(inside)) / (nnz(inside) + eps);
    c2 = sum(Image(outside)) / (nnz(outside) + eps);

    phi = phi + dt * (mu * curvature + ni + ...
        lambda1 * (Image - c1).^2 + lambda2 * (Image - c2).^2);
    area_track(i) = nnz(phi < 0);

    if mod(i,2) == 1
        figure(101); imagesc(Image); colormap gray; axis image off; hold on;
        contour(phi, [0 0], 'r', 'LineWidth', 1.5);
        title(sprintf('Chan–Vese Iteration %d', i)); drawnow;
        hold off;
    end
    if i > 10
        delta = abs(area_track(i) - area_track(i-10)) / (area_track(i) + eps);
        if delta < 0.001
            fprintf('✓ Medulla segmentation converged at iteration %d\n', i);
            break;
        end
    end
end

mask_medulla = phi < 0;
phi_medulla = phi;

[x_phi_medulla, y_phi_medulla] = meshgrid(0:roi_width-1, 0:roi_height-1);
x_phi_medulla = x_phi_medulla + x_start;
y_phi_medulla = y_phi_medulla + y_start;

L = bwlabel(mask_medulla);
stats = regionprops(mask_medulla, 'Area');
areas = [stats.Area];
[~, idx_sorted] = sort(areas, 'descend');
selected_idx = idx_sorted(2:4);
mask_medulla_filtered = ismember(L, selected_idx);

%% --------------------- 7. FINAL VISUALIZATION ---------------------
Xgrid = x_phi_kidney;
Ygrid = y_phi_kidney;

figure('Name', 'Final Segmentation Overview', 'Position', [100 100 1200 500]);
tiledlayout(1,2, 'Padding', 'compact', 'TileSpacing', 'compact');
nexttile;
imshow(I_moving_registered, []); hold on;
contour(Xgrid, Ygrid, mask_kidney, [0.5 0.5], 'm', 'LineWidth', 1.5);
contour(Xgrid, Ygrid, mask_medulla_filtered, [0.5 0.5], 'g', 'LineWidth', 1.5);
title('Full Image (Registered) — Kidney + Medulla');
axis image off;

nexttile;
imshow(I_registered_crop, []); hold on;
contour(mask_kidney, [0.5 0.5], 'm', 'LineWidth', 3);
contour(mask_medulla_filtered, [0.5 0.5], 'g', 'LineWidth', 3);
title('Cropped ROI — Kidney + Medulla');
axis image off;

%% --------------------- 8. AREA QUANTIFICATION ---------------------
area_kidney_mm2     = nnz(mask_kidney) * prod(pixel_spacing);
area_medulla_mm2    = nnz(mask_medulla_filtered) * prod(pixel_spacing);
area_cortex_mm2     = area_kidney_mm2 - area_medulla_mm2;

fprintf('\n=== FINAL AREA REPORT ===\n');
fprintf('Kidney area (mm²)              : %.2f\n', area_kidney_mm2);
fprintf('Medulla area (mm²)             : %.2f\n', area_medulla_mm2);
fprintf('Cortex area (Kidney - Medulla) : %.2f\n', area_cortex_mm2);
