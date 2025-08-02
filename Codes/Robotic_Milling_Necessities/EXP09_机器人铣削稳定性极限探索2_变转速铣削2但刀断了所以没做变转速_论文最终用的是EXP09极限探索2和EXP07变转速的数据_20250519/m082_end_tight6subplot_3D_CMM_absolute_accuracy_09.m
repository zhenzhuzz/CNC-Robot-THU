%% 清理环境 / Clear workspace and close figures
clear; clc; close all;

%% 加载数据 / Load data
load('ZerrorBySpeed.mat', 'ZerrorBySpeed');  % 从 MAT 文件加载结构体 / load struct

%% 参数设置 / Parameters
% 将两组转速放进 cell 数组，和它们对应的保存标志
spindleGroups = {3000:1000:6000, 7000:1000:10000};  
saveFlags     = [true, false];   % 第一组用 true 覆盖保存，第二组用 false 不覆盖

% 子图布局参数 / subplot layout
nRows    = 2;                     
nCols    = 2;
gap      = [-0.3, 0.14];             % tight_subplot 的子图间距 [vertical, horizontal] gap
marg_h   = [0, 0];                % 上下边距[bottom, top] margins
marg_w   = [0.12, 0.04];           % 左右边距 [left, right] margins

%% 对每一组转速分别作图并保存 / Loop over each group, plot & save
for g = 1:numel(spindleGroups)
    rpms = spindleGroups{g};  

    % 新建 figure / create a new figure
    figure('Units','centimeters','Position',[5 1 13.8 15]);
    
    % 生成紧凑子图布局 / tight subplot
    [ha, ~] = tight_subplot(nRows, nCols, gap, marg_h, marg_w);

    % 循环每个转速绘 3D 柱状图 / loop over RPMs and plot
    for i = 1:numel(rpms)
        rpm = rpms(i);
        ax  = ha(i);
        axes(ax);  % 切换到当前子图

        % 取出对应 Z 方向切深误差矩阵 / retrieve Z-error matrix
        Zm = ZerrorBySpeed.(sprintf('n%d', rpm));

        % 绘制 3D 柱状 / draw 3D bars (取负值以便正确显示)
        b = bar3(-Zm);
        view(-35, 35);

        % 按高度插色 / interpolate color by height
        for k = 1:numel(b)
            zdata        = b(k).ZData;
            b(k).CData   = zdata;
            b(k).FaceColor = 'interp';
        end

        % 统一色标 / set color limits & colormap
        clim([-0.2, 0.5]);
        colormap(jet);

        % X、Y 轴刻度 / configure axes ticks & labels
        ax.XTick      = round(linspace(1, size(Zm,2), 6));  
        ax.XTickLabel = 0:30:150;                          
        ax.YTick      = [2, 4, 6, 8, 10]; 
        ax.YTickLabel = [2, 4, 6, 8, 10]; 
        % ax.YTickLabel = 1:2:size(Zm,1);                   

        % 优化图形（自定义函数）/ custom optimization
        f031_3DFigOptimized_05(...
            ax, ...
            '{\it l} (mm)', ...      % X 轴标签
            '{\it a}_p (mm)', ...    % Y 轴标签
            'Δ{\it a}_p (mm)', ...   % Z 轴标签
            '', ...                  % 标题
            [0.01, 0.01], ...        % 标签偏移
            'tight', 'tight', ...    % 紧凑风格
            [-0.2, 0.5] ...          % 色标范围
        );
    end

    % 保存当前 figure / save current figure
    f060_saveFigPNG_asFileName_05( mfilename('fullpath'), saveFlags(g) );
    
end


%%
% Create a new figure for the colorbar
figure('Units','centimeters','Position',[25 0 7 25]); % New figure for the colorbar
% Hide the axis for the colorbar
axis off;
% Add the colorbar to the new figure
cbar1 = colorbar;
colormap(jet);
clim([-0.2, 0.5]);
% Customize the colorbar appearance
f034_colorbar_05(cbar1, '', 10.5, 'Times New Roman', 1); % Customize colorbar
f060_saveFigPNG_asFileName_05(mfilename('fullpath'),false);