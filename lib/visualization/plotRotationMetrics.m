function plotRotationMetrics(angles, metric_vals, best_idx, metric_name)
% plotRotationMetrics - Plots the similarity metric values over rotation angles
    figure('Name', ['Rotation - ', upper(metric_name)], 'NumberTitle', 'off');
    plot(angles, metric_vals, '-o', 'LineWidth', 1.5);
    hold on;
    plot(angles(best_idx), metric_vals(best_idx), 'r.', 'MarkerSize', 25);
    xlabel('Rotation Angle [deg]');
    ylabel(upper(metric_name));
    title(['Rotation Optimization (', upper(metric_name), ')']);
    grid on;
end


