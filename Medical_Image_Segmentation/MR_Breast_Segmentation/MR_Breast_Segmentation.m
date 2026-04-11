%% ========================================================================
%  SEGMENTATION OF MR BREAST IMAGE USING MALLADI–SETHIAN LEVEL SET MODEL
%  Preprocessing, Edge Indicator, and Level Set Evolution
%  ========================================================================

%% --------------------- 1. INITIALIZATION & IMAGE LOADING ---------------------
clc; clear; close all;

addpath(genpath('mylibs'));

% Define image path
image_dir = 'C:\Users\admin\OneDrive\Desktop\Lab8\IMAGES';
folder = fullfile(pwd, 'IMAGES');
filename = 'MR_breast';
full_path = fullfile(folder, filename);

% Load DICOM image and metadata
info = dicominfo(full_path);
I = double(dicomread(full_path));
ps = info.PixelSpacing;   % [dy, dx] in mm

fprintf('\n=== Image Information ===\n');
fprintf('Image size                  : %d × %d pixels\n', size(I,1), size(I,2));
fprintf('Pixel spacing               : %.3f × %.3f mm\n', ps(1), ps(2));

%% --------------------- 2. PREPROCESSING: NORMALIZATION & FILTERING ---------------------

% Normalize to [0, 1]
I_norm = (I - min(I(:))) / (max(I(:)) - min(I(:)));

% Anisotropic diffusion
num_iter = 7;
delta_t = 1/7;
kappa = 7;
option = 1;

I_filt = anisodiff2D(I_norm, num_iter, delta_t, kappa, option);

%% --------------------- 3. LSF INITIALIZATION ---------------------
init_radius = 3;

[phi, X, Y, center] = computeLSF( ...
    'InputImage', I, ...
    'InteractiveCenter', true, ...
    'Radius', init_radius, ...
    'InsidePositive', false);

plotLSF(phi, X, Y, 'OverlayImage', I);

%% --------------------- 4. EDGE INDICATOR FUNCTION ---------------------
beta  = 0.1;
alpha = 2;

g = 1 ./ (1 + (Grad(I_filt) ./ beta)).^alpha;

% Display edge indicator + vector field
figure('Name','Edge Indicator Visualization');
imagesc(g); colormap gray; axis image off; hold on;
quiver(X, Y, -Dx(g), -Dy(g), 'g');
hold off;

%% --------------------- 5. MALLADI–SETHIAN EVOLUTION ---------------------
maxIter = 1500;
dt = 0.1;
eps = 3;

fx = Dx(g);
fy = Dy(g);

area_track = zeros(maxIter, 1);

for i = 1:maxIter
    phi = phi + dt * g .* ((eps * K(phi) - 1) .* Grad(phi)) + Gup(phi, fx, fy);

    A = phi < 0;
    area_track(i) = sum(A(:));

    if mod(i, 10) == 1
        figure(10); clf;
        imagesc(I_filt); colormap gray; axis image off; hold on;
        contour(phi, [0 0], 'g', 'LineWidth', 1.5);
        title(['Iteration: ', num2str(i)]);
        drawnow;
        hold off;
    end

    if i > 140 && area_track(i) == area_track(i - 10)
        break;
    end
end

%% --------------------- 6. FINAL REPORT ---------------------
finalArea = area_track(i);
area_mm2 = finalArea * ps(1) * ps(2);

fprintf('\n========== FINAL SEGMENTATION REPORT ==========\n');
fprintf('Final Iteration                 : %d\n', i);
fprintf('Segmented Area (in pixels)      : %d px²\n', finalArea);
fprintf('Segmented Area (in mm²)         : %.2f mm²\n', area_mm2);
fprintf('Pixel Spacing                   : [%.3f mm, %.3f mm]\n', ps(1), ps(2));
fprintf('===============================================\n');

%% --------------------- 7. FINAL VISUALIZATION ---------------------
figure('Name', 'Final Segmentation');
imshow(I, []); colormap gray; axis image off; hold on;
contour(phi, [0 0], 'g', 'LineWidth', 2);
title('Final Segmentation — MR Breast');
legend('Segmented Region');
