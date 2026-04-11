%% ========================================================================
%  3D SEGMENTATION OF LEFT ATRIUM USING CHAN–VESE LEVEL SET MODEL
%  Volume Preprocessing, Slice-by-Slice Evolution, Post-Processing & Mesh
%  ========================================================================

%% --------------------- 1. INITIALIZATION ---------------------
clc; clear; close all;

addpath(genpath('mylibs'));

%% --------------------- 2. LOAD 3D MRI VOLUME ---------------------
load(fullfile('IMAGES', 'patient5.mat'));

I = res.imm;                           % 3D MRI volume
pixel_spacing = res.info.ps;          % [dy, dx] in mm
slice_thickness = res.info.st;        % z resolution in mm

[nx, ny, nz] = size(I);
fprintf('\n=== Volume Information ===\n');
fprintf('Dimensions                 : %d × %d × %d (rows × cols × slices)\n', nx, ny, nz);
fprintf('Pixel spacing              : %.3f × %.3f mm\n', pixel_spacing(1), pixel_spacing(2));
fprintf('Slice thickness            : %.3f mm\n', slice_thickness);

%% --------------------- 3. SELECT SLICES OF INTEREST ---------------------
slice_range = 9:35;
I_crop = I(:,:,slice_range);
num_slices = length(slice_range);

I_filtered = zeros(nx, ny, num_slices);  % Preallocate

%% --------------------- 4. PARAMETER SETUP ---------------------
% Anisotropic diffusion
num_iter = 5; delta_t = 0.1; kappa = 15; option = 2;

% Chan–Vese parameters
mu = 0.5;
lambda1 = 30;
lambda2 = -30;
ni = 0.0;
time_step = 1;
epsilon = 1e-6;
max_iterations = 100;
check_interval = 5;
init_radius = 3;

% Memory allocation
PHI = zeros(nx, ny, num_slices);         % Level set function φ
PHI_bin = false(nx, ny, num_slices);     % Binary mask
area_mm2 = zeros(1, num_slices);         % Area per slice

update_center_every_n_slices = 10;

fprintf('\n=== Chan–Vese Segmentation on %d Slices ===\n', num_slices);

%% --------------------- 5. SLICE-BY-SLICE SEGMENTATION ---------------------
for s = 1:num_slices

    % --- Ask for center every N slices ---
    if mod(s - 1, update_center_every_n_slices) == 0
        figure;
        imagesc(I_crop(:,:,s)); colormap gray; axis image;
        title(sprintf('Slice %d — Select center of atrium', s + slice_range(1) - 1));
        disp('Click to select center...');
        [x, y] = ginput(1);
        x = round(x); y = round(y);
        center = [x, y];
        close;
        fprintf('✓ New center selected for slice %d: (x = %d, y = %d)\n', s + slice_range(1) - 1, x, y);
    end

    % --- Preprocessing ---
    I_slice = double(I_crop(:,:,s));
    I_slice = (I_slice - min(I_slice(:))) / (max(I_slice(:)) - min(I_slice(:)));
    I_filt = anisodiff2D(I_slice, num_iter, delta_t, kappa, option);

    % --- Initialize level set function ---
    phi = computeLSF('Domain', [1 ny 1 nx], ...
                     'Center', center, ...
                     'Radius', init_radius, ...
                     'InsidePositive', false);

    % --- Chan–Vese Evolution ---
    area_track = zeros(1, max_iterations);
    for iter = 1:max_iterations
        [phi_x, phi_y] = gradient(phi);
        normGrad = sqrt(phi_x.^2 + phi_y.^2 + epsilon);
        Nx = phi_x ./ normGrad;
        Ny = phi_y ./ normGrad;
        curvature = divergence(Nx, Ny);

        inside = (phi < 0);
        outside = ~inside;

        c1 = sum(I_filt(inside)) / (sum(inside(:)) + epsilon);
        c2 = sum(I_filt(outside)) / (sum(outside(:)) + epsilon);

        phi = phi + time_step * (mu * curvature + ni + ...
              lambda1 * (I_filt - c1).^2 + lambda2 * (I_filt - c2).^2);

        area_track(iter) = nnz(phi < 0);

        if iter > check_interval
            delta_area = abs(area_track(iter) - area_track(iter - check_interval)) ...
                         / (area_track(iter) + epsilon);
            if delta_area < 0.01
                break;
            end
        end
    end

    % --- Post-processing ---
    se = strel('disk', 9);
    mask = imerode(phi < 0, se);
    L = bwlabel(mask);
    label_id = L(y, x);
    selected = (L == label_id);
    mask_clean = imdilate(selected, se);
    mask_clean = imfill(mask_clean, 'holes');

    % --- Save results ---
    PHI(:,:,s) = phi;
    PHI_bin(:,:,s) = mask_clean;
    area_mm2(s) = sum(mask_clean(:)) * pixel_spacing(1) * pixel_spacing(2);

    fprintf('✓ Slice %d segmented (Area = %.2f mm²)\n', s + slice_range(1) - 1, area_mm2(s));
end

%% --------------------- 6. VISUALIZATION OF ALL SLICES ---------------------
fprintf('\n=== Final Visualization: Raw φ vs Cleaned Mask ===\n');

for s = 1:num_slices
    figure(10); clf;
    imagesc(I_crop(:,:,s)); colormap gray; axis image off; hold on;
    contour(PHI(:,:,s), [0 0], 'r', 'LineWidth', 1.5);
    contour(PHI_bin(:,:,s), [0.5 0.5], 'g--', 'LineWidth', 1.5);
    title(sprintf('Slice %d — φ (red) vs cleaned (green)', s + slice_range(1) - 1));
    pause(0.3);
end

%% --------------------- 7. 3D MESH RECONSTRUCTION ---------------------
fprintf('\n=== 3D Mesh Reconstruction ===\n');

[node, elem] = binsurface(PHI_bin);

node(:,1) = node(:,1) * pixel_spacing(2);      % x
node(:,2) = node(:,2) * pixel_spacing(1);      % y
node(:,3) = node(:,3) * slice_thickness;       % z

figure;
plotmesh(node, elem, ...
    'facecolor', 'b', ...
    'edgecolor', 'none', ...
    'facealpha', 0.9);

axis equal off;
camlight headlight;
title('3D Reconstruction — Left Atrium');

volume_mm3 = sum(area_mm2) * slice_thickness;
fprintf('✓ Total segmented volume: %.2f mm³\n', volume_mm3);
