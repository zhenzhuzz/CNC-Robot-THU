function f050_createFFT_GUI(time, accX, samplingRate, windowSize, maxFreq)
% 实时FFT分析GUI (无插值版, 已去直流, linewidth加粗)
%
% 调用示例：
% f050_createFFT_GUI(time, accX, 8000, 0.3, 2000);

arguments
    time (:,1) double
    accX (:,1) double
    samplingRate (1,1) double
    windowSize (1,1) double = 0.3
    maxFreq (1,1) double = samplingRate/2
end

totalSamples = length(time);
windowSamples = round(windowSize * samplingRate);

%% 创建GUI窗口
fig = uifigure('Name', '实时FFT分析', 'Position', [100 100 900 700]);

axWidth = 800; axHeight = 160; leftMargin = 50;
sliderHeight = 3;

% 创建三个图区域（长度一致）
ax1 = uiaxes(fig, 'Position',[leftMargin, 500, axWidth, axHeight]);
ax2 = uiaxes(fig, 'Position',[leftMargin, 320, axWidth, axHeight]);
ax3 = uiaxes(fig, 'Position',[leftMargin, 140, axWidth, axHeight]);

% 创建滑块
slider = uislider(fig,...
    'Position',[leftMargin, 80, axWidth, sliderHeight],...
    'Limits',[1 totalSamples-windowSamples+1],...
    'Value',1);
slider.ValueChangingFcn = @(src,event)updatePlots(round(event.Value));

% 首次显示
updatePlots(1);

%% 局部函数: 更新图像
    function updatePlots(currentIdx,~,~)
        if nargin < 1
            currentIdx = round(slider.Value);
        end
        if currentIdx+windowSamples-1 > totalSamples
            currentIdx = totalSamples-windowSamples+1;
        end

        % 当前窗口数据
        t_window = time(currentIdx:currentIdx+windowSamples-1);
        acc_window = accX(currentIdx:currentIdx+windowSamples-1);

        % FFT计算（去除直流偏置）
        [f,X_f] = f010_fourier(t_window, acc_window, true);

        % 上图: 全貌信号和红色窗口
        plot(ax1,time,accX,'k','LineWidth',1.2); hold(ax1,'on');
        rectangle(ax1,'Position',...
            [t_window(1),min(accX),windowSize,range(accX)],...
            'EdgeColor','r','LineWidth',1.2);
        hold(ax1,'off');
        title(ax1,'全貌加速度信号');
        xlabel(ax1,'时间(s)');
        ylabel(ax1,'加速度(g)');
        grid(ax1,'on');

        % 中图: 当前窗口信号 (线加粗)
        plot(ax2,t_window,acc_window,'b','LineWidth',1.2);
        title(ax2,'当前窗口加速度信号');
        xlabel(ax2,'时间(s)');
        ylabel(ax2,'加速度(g)');
        grid(ax2,'on');

        % 下图: FFT频谱 (线加粗)
        plot(ax3,f,X_f,'b','LineWidth',1.2);
        xlim(ax3,[0 maxFreq]);
        title(ax3,'FFT频谱');
        xlabel(ax3,'频率(Hz)');
        ylabel(ax3,'幅值');
        grid(ax3,'on');

        drawnow;
    end

end
