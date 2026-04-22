%% ========================================================================
% This script implements a complete and refined pipeline for multimodal image 
% registration using T2-weighted MRI, diffusion-weighted MRI (DWI), and PET images.
% The goal is to spatially align these modalities to enable direct and reliable 
% comparison across imaging techniques. The pipeline includes scaling, padding,
% full 2D translational and rotational registration, and evaluation using multiple metrics.
% ============================================================

%% --------------------- 1. INITIALIZATION & IMAGE LOADING ---------------------
clc; clear; close all;
repoRoot = fileparts(fileparts(mfilename('fullpath')));
addpath(genpath(fullfile(repoRoot, 'lib')));

% Load DICOM images and metadata
info_T2 = dicominfo(fullfile(repoRoot, 'data', 'MRI_T2.dcm'));
I_T2 = dicomread(info_T2);

info_DWI = dicominfo(fullfile(repoRoot, 'data', 'MRI_DWI.dcm'));
I_DWI = dicomread(info_DWI);

info_PET = dicominfo(fullfile(repoRoot, 'data', 'PET.dcm'));
I_PET = dicomread(info_PET);
I_PET = squeeze(I_PET);  % Remove extra singleton dimension

info_T2_rot = dicominfo(fullfile(repoRoot, 'data', 'MRI_T2_rot.dcm'));
I_T2_rot = dicomread(info_T2_rot);

% Display original image sizes
disp('--- Image Sizes (rows x cols) ---');
disp(['MRI T2       : ', num2str(size(I_T2,1)), ' x ', num2str(size(I_T2,2))]);
disp(['MRI DWI      : ', num2str(size(I_DWI,1)), ' x ', num2str(size(I_DWI,2))]);
disp(['PET          : ', num2str(size(I_PET,1)), ' x ', num2str(size(I_PET,2))]);
disp(['MRI T2 Rot   : ', num2str(size(I_T2_rot,1)), ' x ', num2str(size(I_T2_rot,2))]);

fprintf('=============================================================\n');

% Extract and display pixel spacing
ps_T2  = info_T2.PixelSpacing;
ps_DWI = info_DWI.PixelSpacing;
ps_PET = info_PET.PixelSpacing;

disp('--- Pixel Spacing (dy, dx) ---');
disp(['MRI T2       : [', num2str(ps_T2(1)), ', ', num2str(ps_T2(2)), ']']);
disp(['MRI DWI      : [', num2str(ps_DWI(1)), ', ', num2str(ps_DWI(2)), ']']);
disp(['PET          : [', num2str(ps_PET(1)), ', ', num2str(ps_PET(2)), ']']);
disp(['MRI T2 Rot   : [', num2str(info_T2_rot.PixelSpacing(1)), ', ', num2str(info_T2_rot.PixelSpacing(2)), ']']);
fprintf('=============================================================\n');

% Compute scaling factors
scale_DWI = ps_DWI(1) / ps_T2(1);
scale_PET = ps_PET(1) / ps_T2(1);

disp('--- Scaling Factors (DWI and PET → MRI T2) ---');
fprintf('DWI  scale factor: %.4f\n', scale_DWI);
fprintf('PET  scale factor: %.4f\n', scale_PET);
fprintf('=============================================================\n');

% Rescale DWI and PET to match MRI T2 resolution
I_DWI_scaled = imresize(I_DWI, scale_DWI);
I_PET_scaled = imresize(I_PET, scale_PET);
I_T2_scaled = I_T2;

disp('--- Image Sizes After Scaling ---');
fprintf('MRI T2         : %d x %d (reference, unchanged)\n', size(I_T2_scaled,1), size(I_T2_scaled,2));
fprintf('MRI DWI scaled : %d x %d\n', size(I_DWI_scaled,1), size(I_DWI_scaled,2));
fprintf('PET scaled     : %d x %d\n', size(I_PET_scaled,1), size(I_PET_scaled,2));
fprintf('=============================================================\n');

scaled_images = {I_T2_scaled, I_DWI_scaled, I_PET_scaled};
scaled_titles = {'MRI T2', 'MRI DWI (scaled)', 'PET (scaled)'};

I_T2_padded  = zeroPadding(I_T2_scaled, I_PET_scaled);
I_DWI_padded = zeroPadding(I_DWI_scaled, I_PET_scaled);
I_PET_padded = zeroPadding(I_PET_scaled, I_PET_scaled);

padded_images = {I_T2_padded, I_DWI_padded, I_PET_padded};
padded_titles = {'MRI T2 (padded)', 'MRI DWI (padded)', 'PET (padded)'};

figure('Name', 'Rescaling and Padding Overview', 'NumberTitle', 'off');
for i = 1:3
    subplot(2,3,i);
    imagesc(scaled_images{i}); axis image off; colormap gray; colorbar;
    sz = size(scaled_images{i});
    ps = ps_T2;
    title(sprintf('%s\nResolution: %.3f × %.3f mm/pixel', scaled_titles{i}, ps(1), ps(2)), 'FontSize', 10, 'FontWeight', 'bold');
    text(10, sz(1)-10, sprintf('Size: %d × %d px', sz(1), sz(2)), 'Color', 'yellow', 'FontSize', 9, 'BackgroundColor', 'black', 'VerticalAlignment', 'bottom');
end

for i = 1:3
    subplot(2,3,i+3);
    imagesc(padded_images{i}); axis image off; colormap gray; colorbar;
    sz = size(padded_images{i});
    title(sprintf('%s\nResolution: %.3f × %.3f mm/pixel', padded_titles{i}, ps(1), ps(2)), 'FontSize', 10, 'FontWeight', 'bold');
    text(10, sz(1)-10, sprintf('Size: %d × %d px', sz(1), sz(2)), 'Color', 'yellow', 'FontSize', 9, 'BackgroundColor', 'black', 'VerticalAlignment', 'bottom');
end

%% --------------------- 2. Translation Registration using SSD and NCC (MI is computed separately) ---------------------
max_shift = 20;
N = 2 * max_shift + 1;

%Initialize similarity maps
SSD_DWI_map = zeros(N, N);  NCC_DWI_map = zeros(N, N);  MI_DWI_map  = zeros(N, N);
SSD_PET_map = zeros(N, N);  NCC_PET_map = zeros(N, N);  MI_PET_map  = zeros(N, N);

for dx = -max_shift:max_shift    %Loop over all shifts and evaluate similarity
    for dy = -max_shift:max_shift
        idx_x = dx + max_shift + 1;
        idx_y = dy + max_shift + 1;
        translation = [dx, dy];
        translated_DWI = imtranslate(I_DWI_padded, translation, 'FillValues', 0); %Apply shift and compute similarity
        translated_PET = imtranslate(I_PET_padded, translation, 'FillValues', 0);
        SSD_DWI_map(idx_y, idx_x) = SSD(I_T2_padded, translated_DWI);
        NCC_DWI_map(idx_y, idx_x) = NCC(I_T2_padded, translated_DWI);
        SSD_PET_map(idx_y, idx_x) = SSD(I_T2_padded, translated_PET);
        NCC_PET_map(idx_y, idx_x) = NCC(I_T2_padded, translated_PET);
    end
end

% Display best SSD and NCC values
fprintf('--- Best Similarity Values ---\n');
fprintf('DWI - Min SSD: %.4f\n', min(SSD_DWI_map(:)));
fprintf('DWI - Max NCC: %.4f\n', max(NCC_DWI_map(:)));
fprintf('PET - Min SSD: %.4f\n', min(SSD_PET_map(:)));
fprintf('PET - Max NCC: %.4f\n', max(NCC_PET_map(:)));

[~, idx_SSD_DWI] = min(SSD_DWI_map(:));
[~, idx_SSD_PET] = min(SSD_PET_map(:));
[y_ssd_dwi, x_ssd_dwi] = ind2sub(size(SSD_DWI_map), idx_SSD_DWI);
[y_ssd_pet, x_ssd_pet] = ind2sub(size(SSD_PET_map), idx_SSD_PET);

[~, idx_NCC_DWI] = max(NCC_DWI_map(:));
[~, idx_NCC_PET] = max(NCC_PET_map(:));
[y_ncc_dwi, x_ncc_dwi] = ind2sub(size(NCC_DWI_map), idx_NCC_DWI);
[y_ncc_pet, x_ncc_pet] = ind2sub(size(NCC_PET_map), idx_NCC_PET);

best_shift_DWI = [x_ncc_dwi - max_shift - 1, y_ncc_dwi - max_shift - 1];
best_shift_PET = [x_ncc_pet - max_shift - 1, y_ncc_pet - max_shift - 1];

I_DWI_registered = imtranslate(I_DWI_padded, best_shift_DWI, 'FillValues', 0);
I_PET_registered = imtranslate(I_PET_padded, best_shift_PET, 'FillValues', 0);

figure('Name', '2D Similarity Heatmaps (DWI and PET)', 'NumberTitle', 'off');
metrics = {'SSD', 'NCC'};
maps_DWI = {SSD_DWI_map, NCC_DWI_map};
maps_PET = {SSD_PET_map, NCC_PET_map};
best_coords = {[x_ssd_dwi, y_ssd_dwi; x_ncc_dwi, y_ncc_dwi], [x_ssd_pet, y_ssd_pet; x_ncc_pet, y_ncc_pet]};
for i = 1:2
    subplot(2, 2, i);
    imagesc(-max_shift:max_shift, -max_shift:max_shift, maps_DWI{i}); axis image; colorbar;
    title([metrics{i} ' - DWI']); xlabel('Shift X'); ylabel('Shift Y');
    hold on;
    plot(best_coords{1}(i,1)-max_shift-1, best_coords{1}(i,2)-max_shift-1, 'rx', 'MarkerSize', 12, 'LineWidth', 2);
    hold off;

    subplot(2, 2, i+2);
    imagesc(-max_shift:max_shift, -max_shift:max_shift, maps_PET{i}); axis image; colorbar;
    title([metrics{i} ' - PET']); xlabel('Shift X'); ylabel('Shift Y');
    hold on;
    plot(best_coords{2}(i,1)-max_shift-1, best_coords{2}(i,2)-max_shift-1, 'rx', 'MarkerSize', 12, 'LineWidth', 2);
    hold off;
end

for dx = -max_shift:max_shift
    for dy = -max_shift:max_shift
        idx_x = dx + max_shift + 1;
        idx_y = dy + max_shift + 1;
        translation = [dx, dy];
        translated_DWI = imtranslate(I_DWI_padded, translation, 'FillValues', 0);
        translated_PET = imtranslate(I_PET_padded, translation, 'FillValues', 0);
        MI_DWI_map(idx_y, idx_x) = MI(I_T2_padded, translated_DWI);
        MI_PET_map(idx_y, idx_x) = MI(I_T2_padded, translated_PET);
    end
end

figure('Name', 'Mutual Information Heatmaps', 'NumberTitle', 'off');
subplot(1, 2, 1);
imagesc(-max_shift:max_shift, -max_shift:max_shift, MI_DWI_map); axis image; colorbar;
title('MI - DWI'); xlabel('Shift X'); ylabel('Shift Y');
[max_MI_DWI, idx_MI_DWI] = max(MI_DWI_map(:));
[y_mi_dwi, x_mi_dwi] = ind2sub(size(MI_DWI_map), idx_MI_DWI);
hold on;
plot(x_mi_dwi - max_shift - 1, y_mi_dwi - max_shift - 1, 'rx', 'MarkerSize', 12, 'LineWidth', 2);
hold off;

subplot(1, 2, 2);
imagesc(-max_shift:max_shift, -max_shift:max_shift, MI_PET_map); axis image; colorbar;
title('MI - PET'); xlabel('Shift X'); ylabel('Shift Y');
[max_MI_PET, idx_MI_PET] = max(MI_PET_map(:));
[y_mi_pet, x_mi_pet] = ind2sub(size(MI_PET_map), idx_MI_PET);
hold on;
plot(x_mi_pet - max_shift - 1, y_mi_pet - max_shift - 1, 'rx', 'MarkerSize', 12, 'LineWidth', 2);
hold off;

fprintf('--- Best MI Values ---\n');
fprintf('DWI - Max MI: %.4f\n', max_MI_DWI);
fprintf('PET - Max MI: %.4f\n', max_MI_PET);

T2_img  = mat2gray(I_T2_padded);
DWI_img = mat2gray(I_DWI_registered);
PET_img = mat2gray(I_PET_registered);

figure('Name', 'DWI Registered to T2 (Checkerboard)', 'NumberTitle', 'off');
checkerboard_view(T2_img, DWI_img, 20);
title('Checkerboard: T2 vs DWI (Registered)', 'FontWeight', 'bold');

figure('Name', 'PET Registered to T2 (Checkerboard)', 'NumberTitle', 'off');
checkerboard_view(T2_img, PET_img, 20);
title('Checkerboard: T2 vs PET (Registered)', 'FontWeight', 'bold');

%% --------------------- 3.  ROTATIONAL REGISTRATION - T2 vs T2_rot using all similarity metrics ---------------------

% Define rotation parameters
rotation_step = 0.5;
max_rotation = 360;
angles = 0:rotation_step:(max_rotation - rotation_step);

% Initialize similarity arrays
SSD_rot = zeros(size(angles));
NCC_rot = zeros(size(angles));
MI_rot  = zeros(size(angles));

% Evaluate similarity at each rotation angle
for i = 1:length(angles)
    angle = angles(i);
    rotated_img = imrotate(I_T2_rot, angle, 'bilinear', 'crop');
    SSD_rot(i) = SSD(I_T2, rotated_img);
    NCC_rot(i) = NCC(I_T2, rotated_img);
    MI_rot(i)  = MI(I_T2, rotated_img);
end

% Identify best angles for each metric
[~, best_idx_ssd] = min(SSD_rot);
[~, best_idx_ncc] = max(NCC_rot);
[~, best_idx_mi]  = max(MI_rot);

% Display optimal values
fprintf('\n--- Optimal Rotation Angles ---\n');
fprintf('SSD -> Min at %.2f°\n', angles(best_idx_ssd));
fprintf('NCC -> Max at %.2f°\n', angles(best_idx_ncc));
fprintf('MI  -> Max at %.2f°\n', angles(best_idx_mi));

% Apply best rotation (we'll use NCC as standard)
best_rotation_deg = angles(best_idx_ncc);
I_T2_rot_registered = imrotate(I_T2_rot, best_rotation_deg, 'bilinear', 'crop');

%% --------------------- 4. VISUALIZATION ---------------------
figure('Name', 'Rotational Registration: T2 vs T2_rot', 'NumberTitle', 'off');
subplot(1,2,1); imagesc(I_T2); axis image off; colormap gray;
title('MRI T2');
subplot(1,2,2); imagesc(I_T2_rot_registered); axis image off; colormap gray;
title(['T2 Rotated (Registered at ', num2str(best_rotation_deg), '°)']);

% Joint Histogram
numBins = 128;
H_rot = compute_joint_histogram(I_T2, I_T2_rot_registered, numBins);
figure('Name', 'Joint Histogram: T2 vs T2_{rot} (Registered)', 'NumberTitle', 'off');
imagesc(log(H_rot + 1)); colormap('hot'); colorbar;
title(['Joint Histogram: T2 vs T2_{rot} (', num2str(best_rotation_deg), '°)'], 'FontWeight', 'bold');
xlabel('T2_{rot} Intensity'); ylabel('T2 Intensity'); axis on;

% Checkerboard
figure('Name', 'Checkerboard View: T2 vs T2_rot (Registered)', 'NumberTitle', 'off');
checkerboard_view(double(I_T2), double(I_T2_rot_registered), 10);
title(['Checkerboard: T2 vs T2_{rot} Registered (' num2str(best_rotation_deg) '°)']);

% Metric trends with markers at optimal points
figure('Name', 'Similarity Metrics vs Rotation Angle', 'NumberTitle', 'off');

subplot(1,3,1);
plot(angles, SSD_rot, '-o', 'Color', [0.2 0.2 0.8]); hold on;
plot(angles(best_idx_ssd), SSD_rot(best_idx_ssd), 'ro', 'MarkerSize', 8, 'LineWidth', 2);
title('SSD vs Rotation'); xlabel('Angle (°)'); ylabel('SSD'); grid on;

subplot(1,3,2);
plot(angles, NCC_rot, '-o', 'Color', [0.1 0.6 0.1]); hold on;
plot(angles(best_idx_ncc), NCC_rot(best_idx_ncc), 'ro', 'MarkerSize', 8, 'LineWidth', 2);
title('NCC vs Rotation'); xlabel('Angle (°)'); ylabel('NCC'); grid on;

subplot(1,3,3);
plot(angles, MI_rot, '-o', 'Color', [0.8 0.2 0.2]); hold on;
plot(angles(best_idx_mi), MI_rot(best_idx_mi), 'ro', 'MarkerSize', 8, 'LineWidth', 2);
title('MI vs Rotation'); xlabel('Angle (°)'); ylabel('Mutual Information'); grid on;

% Final reporting for MI after all registrations
fprintf('\n--- Final Mutual Information Values ---\n');
mi_rot = MI(I_T2, I_T2_rot_registered);
mi_dwi = MI(I_T2_padded, I_DWI_registered);
mi_pet = MI(I_T2_padded, I_PET_registered);
fprintf('MI(T2, T2_rot_registered) = %.4f\n', mi_rot);
fprintf('MI(T2, DWI_registered)    = %.4f\n', mi_dwi);
fprintf('MI(T2, PET_registered)    = %.4f\n', mi_pet);

% Bar plot of MI
figure('Name', 'MI Color-Coded');
bar_data = [mi_rot, mi_dwi, mi_pet];
labels = {'T2 vs T2_{rot}', 'T2 vs DWI', 'T2 vs PET'};
colors = [0.8 0.2 0.2; 0.2 0.8 0.2; 0.2 0.2 0.8];
b = bar(bar_data, 'FaceColor', 'flat');
for i = 1:3
    b.CData(i,:) = colors(i,:);
end
set(gca, 'XTickLabel', labels);
ylabel('Mutual Information');
title('Mutual Information Across Registered Pairs');


%% --------------------- 5. Generate summary reports for each registration pair ---------------------

generate_registration_report(I_T2_padded, I_DWI_padded, I_DWI_registered, 'T2-DWI', 128);
generate_registration_report(I_T2_padded, I_PET_padded, I_PET_registered, 'T2-PET', 128);
generate_registration_report(I_T2, I_T2_rot, I_T2_rot_registered, 'T2-T2', 128);

% Display tabular summary of key parameters
fprintf('\n=============================================================\n');
fprintf('                     REGISTRATION SUMMARY TABLE\n');
fprintf('=============================================================\n');
ps_T2 = info_T2.PixelSpacing(1);
ps_DWI = info_DWI.PixelSpacing(1);
ps_PET = info_PET.PixelSpacing(1);

scale_DWI = ps_DWI / ps_T2;
scale_PET = ps_PET / ps_T2;

fprintf('|====================================================================|\n');
fprintf('| Image            | Scaling      | Translation [x y] | Rotation     |\n');
fprintf('|------------------|--------------|-------------------|--------------|\n');
fprintf('| MR_T2.dcm        | REF          | [ 0   0 ]         | -            |\n');
fprintf('| MRI_DWI.dcm      | %.4f       | [%3d %3d]         | -            |\n', scale_DWI, best_shift_DWI(1), best_shift_DWI(2));
fprintf('| PET.dcm          | %.4f       | [%3d %3d]         | -            |\n', scale_PET, best_shift_PET(1), best_shift_PET(2));
fprintf('| MRI_T2_rot.dcm   | -            | -                 | %.2f°      |\n', best_rotation_deg);
fprintf('|====================================================================|\n');

