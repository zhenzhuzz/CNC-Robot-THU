clc;
close all;
clear;

% Load the saved stability results from the .mat file
load('stabilityResults.mat', 'stabilityResults');  % Load the results

% Example: Assume you have 'stabilityResults', 'n', and 'ap' values already loaded or defined
% For demonstration purposes, assume stabilityResults is already available

% Define the spindle speed (n) and depth of cut (ap)
n = 3000:1000:10000;  % Spindle speed values: 3000rpm, 4000rpm, ..., 10000rpm
ap = 1:1:10;  % Depth of cut values: 1mm, 2mm, ..., 10mm

% Ensure the length of stabilityResults matches numDepths * numSpindleSpeeds
numSpindleSpeeds = length(n);  % Number of unique spindle speeds
numDepths = length(ap);  % Number of unique depth of cuts

% Check if the size matches
if numel(stabilityResults) ~= numSpindleSpeeds * numDepths
    error('The number of stabilityResults does not match the expected grid size!');
end

% Reshape stabilityResults into a 2D matrix (depths x spindle speeds)
stabilityMatrix = reshape(stabilityResults, numDepths, numSpindleSpeeds);

% Step 2: Create a new figure for stability map
figure('Units', 'centimeters', 'Position', [5 2 10.5 11]);

% Step 3: Generate a meshgrid for n (spindle speed) and ap (depth of cut)
% Create meshgrid of spindle speed and depth of cut
[N, AP] = meshgrid(n, ap);

% Step 4: Plot the results based on the reshaped stabilityResults
hold on;

% Plot dummy points for the legend
plot(N(1,1), AP(1,1), 'v', 'MarkerEdgeColor', 'b', 'MarkerFaceColor', 'none', 'MarkerSize', 6, 'LineWidth', 1.5); % Stable
plot(N(10,1), AP(10,1), 'p', 'MarkerEdgeColor', 'r', 'MarkerFaceColor', 'none', 'MarkerSize', 6, 'LineWidth', 1.5); % Chatter


for i = 1:numSpindleSpeeds
    for j = 1:numDepths
        % For each (n, ap) pair, plot either 'v' (stable) or 'p' (unstable)
        if stabilityMatrix(j, i) == 0
            % Stable (matches spindle harmonics), use blue 'v' marker
            plot(N(j, i), AP(j, i), 'v', 'MarkerEdgeColor', 'b', 'MarkerFaceColor', 'none', 'MarkerSize', 6, 'LineWidth', 1.5);
        else
            % Unstable (does not match spindle harmonics), use red 'p' marker
            plot(N(j, i), AP(j, i), 'p', 'MarkerEdgeColor', 'r', 'MarkerFaceColor', 'r', 'MarkerSize', 6, 'LineWidth', 1.5);
        end
    end
end

% Custom xlim and ylim values
xlim_vals = [2200 10800];
ylim_vals = [0.2 10.8];

% Apply the f030_optimizeFig_Paper_05 function to improve figure appearance
f030_optimizeFig_Paper_05(gca, '{\it n} (rpm)', '{\it a}_p (mm)', '', xlim_vals, ylim_vals);

% Add the legend after the loop
legend({'稳定', '颤振'}, 'Location', 'northoutside','FontName','宋体','FontSize',10.5);
f060_saveFigPNG_asFileName_05(mfilename('fullpath'));
