%% ========================================================================
%  SEGMENTATION OF SE06_IM194 (SHORT-AXIS VIEW) USING MALLADI–SETHIAN MODEL
%  Image Preprocessing, Level Set Initialization, Edge-Based Evolution
%  ========================================================================

%% --------------------- 1. INITIALIZATION & IMAGE LOADING ---------------------
clc; clear; close all;

% Add custom function library
addpath(genpath('mylibs'));

% Load target DICOM image
image_folder = fullfile(pwd, 'IMAGES');
image_filename = 'SE06_IM194';  % No extension required
image_path = fullfile(image_folder, image_filename);

info = dicominfo(image_path);
I = double(dicomread(image_path));
pixel_spacing = info.PixelSpacing;  % [dy, dx] in mm

%% --------------------- 2. PREPROCESSING: NORMALIZATION & FILTERING ---------------------

% Normalize intensity to [0, 1]
I_norm = (I - min(I(:))) / (max(I(:)) - min(I(:)));

% Anisotropic diffusion parameters
num_iter = 7;
delta_t = 1/7;
kappa = 7;
option = 1;

% Apply smoothing
I_filt = anisodiff2D(I_norm, num_iter, delta_t, kappa, option);

%% --------------------- 3. LEVEL SET INITIALIZATION — REGION 1 ---------------------
init_radius = 10;

[phi1, X, Y, ~] = computeLSF( ...
    'InputImage', I, ...
    'InteractiveCenter', true, ...
    'Radius', init_radius, ...
    'InsidePositive', false);

plotLSF(phi1, X, Y, 'OverlayImage', I);

%% --------------------- 4. EDGE INDICATOR FUNCTION ---------------------
beta  = 0.1;
alpha = 2;

g = 1 ./ (1 + (Grad(I_filt) ./ beta)).^alpha;

% Gradient visualization
figure('Name','Edge Indicator');
imagesc(g); colormap gray; axis image off;
hold on;
quiver(X, Y, -Dx(g), -Dy(g), 'g');
hold off;

%% --------------------- 5. MALLADI–SETHIAN EVOLUTION — REGION 1 ---------------------
max_iter = 1500;
dt = 0.1;
eps = 2;
ni1 = 2;

fx = Dx(g);
fy = Dy(g);
area_t1 = zeros(max_iter, 1);

for iter = 1:max_iter
    phi1 = phi1 + dt * g .* ((eps * K(phi1) - 1) .* Grad(phi1)) + ni1 .* Gup(phi1, fx, fy);
    area_t1(iter) = nnz(phi1 < 0);

    if mod(iter, 10) == 1
        figure(10); clf;
        imagesc(I_filt); colormap gray; axis image off;
        hold on;
        contour(phi1, [0 0], 'r', 'LineWidth', 1.0);
        title(['Segmentation 1 - Iteration: ', num2str(iter)]);
        drawnow;
        hold off;
    end

    if iter > 140 && area_t1(iter) == area_t1(iter - 10)
        break;
    end
end

area1_px = area_t1(iter);
area1_mm2 = area1_px * pixel_spacing(1) * pixel_spacing(2);

fprintf('\n========== SEGMENTATION 1 REPORT ==========\n');
fprintf('Final Iteration                 : %d\n', iter);
fprintf('Segmented Area (pixels)         : %d px²\n', area1_px);
fprintf('Segmented Area (mm²)            : %.2f mm²\n', area1_mm2);
fprintf('===========================================\n');

%% --------------------- 6. LEVEL SET INITIALIZATION — REGION 2 ---------------------
[phi2, X, Y, ~] = computeLSF( ...
    'InputImage', I, ...
    'InteractiveCenter', true, ...
    'Radius', init_radius, ...
    'InsidePositive', false);

plotLSF(phi2, X, Y, 'OverlayImage', I);

%% --------------------- 7. MALLADI–SETHIAN EVOLUTION — REGION 2 ---------------------
ni2 = 0.8;
area_t2 = zeros(max_iter, 1);

for iter = 1:max_iter
    phi2 = phi2 + dt * g .* ((eps * K(phi2) - 1) .* Grad(phi2)) + ni2 .* Gup(phi2, fx, fy);
    area_t2(iter) = nnz(phi2 < 0);

    if mod(iter, 10) == 1
        figure(10); clf;
        imagesc(I_filt); colormap gray; axis image off;
        hold on;
        contour(phi2, [0 0], 'r', 'LineWidth', 1.0);
        contour(phi1, [0 0], 'm--', 'LineWidth', 2);
        title(['Segmentation 2 - Iteration: ', num2str(iter)]);
        drawnow;
        hold off;
    end

    if iter > 140 && area_t2(iter) == area_t2(iter - 10)
        break;
    end
end

area2_px = area_t2(iter);
area2_mm2 = area2_px * pixel_spacing(1) * pixel_spacing(2);

fprintf('\n========== SEGMENTATION 2 REPORT ==========\n');
fprintf('Final Iteration                 : %d\n', iter);
fprintf('Segmented Area (pixels)         : %d px²\n', area2_px);
fprintf('Segmented Area (mm²)            : %.2f mm²\n', area2_mm2);
fprintf('===========================================\n');

%% --------------------- 8. FINAL VISUALIZATION ---------------------
figure('Name', 'Final Segmentation — Both Regions');
imshow(I, []); colormap gray; axis image off; hold on;
contour(phi1, [0 0], 'm--', 'LineWidth', 2);
contour(phi2, [0 0], 'g--', 'LineWidth', 2);
legend('Area 1', 'Area 2');
title('Final Segmentation — SE06\_IM194 (Malladi–Sethian)');

%% --------------------- 9. SUMMARY REPORT ---------------------
total_area_mm2 = area1_mm2 + area2_mm2;

fprintf('\n========== FINAL SUMMARY ==========\n');
fprintf('Area 1 (mm²)                    : %.2f\n', area1_mm2);
fprintf('Area 2 (mm²)                    : %.2f\n', area2_mm2);
fprintf('Total segmented area (mm²)      : %.2f\n', total_area_mm2);
fprintf('Pixel Spacing                   : [%.3f mm, %.3f mm]\n', pixel_spacing(1), pixel_spacing(2));
fprintf('===================================\n');
