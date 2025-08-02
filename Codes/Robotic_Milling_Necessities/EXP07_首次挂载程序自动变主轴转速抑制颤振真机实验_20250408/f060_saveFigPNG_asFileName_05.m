function f060_saveFigPNG_asFileName_05(scriptFullPath, resetFlag, dpi)
    % 自动根据脚本名保存高分辨率PNG图片，每次调用后会递增文件名后缀
    % 调用示例：
    %   f060_saveFigPNG_asFileName_05(mfilename('fullpath'));  % 默认1500 dpi
    %   f060_saveFigPNG_asFileName_05(mfilename('fullpath'), 1200); % 指定dpi
    %   f060_saveFigPNG_asFileName_05(mfilename('fullpath'), 1500, true); % 重置计数

    arguments
        scriptFullPath (1,:) char
        resetFlag (1,1) logical = true  % 默认为 true，重置
        dpi (1,1) double = 1500
    end

    % 利用 persistent 变量记录调用次数
    persistent callCount

    if resetFlag
        % 如果 resetFlag 为 true，则清零 callCount
        callCount = 1;
    elseif isempty(callCount)
        % 如果 persistent 变量为空，表示是第一次调用，设置为 1
        callCount = 1;
    else
        % 否则递增 callCount
        callCount = callCount + 1;
    end

    % 获取当前脚本名称并去掉开头的 'm'（如果存在）
    [~, scriptName, ~] = fileparts(scriptFullPath);
    if scriptName(1) == 'm'
        scriptName = scriptName(2:end);
    end

    % 根据调用次数生成文件名，仅在 resetFlag = false 时加上 callCount
    if resetFlag
        figName = sprintf('p%s.png', scriptName);
    else
        figName = sprintf('p%s_%d.png', scriptName, callCount);
    end

    % 保存图形为PNG
    print(gcf, figName, '-dpng', ['-r', num2str(dpi)]);
end
