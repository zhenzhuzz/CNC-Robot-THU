function f040_saveFigPNG_asFileName_01(scriptFullPath, dpi)
    % 自动根据脚本名保存高分辨率PNG图片，每次调用后会递增文件名后缀
    % 调用示例：
    %   f040_saveFigPNG_asFileName_01(mfilename('fullpath'));  % 默认1500 dpi
    %   f040_saveFigPNG_asFileName_01(mfilename('fullpath'), 1200); % 指定dpi

    arguments
        scriptFullPath (1,:) char
        dpi (1,1) double = 1500
    end

    % 利用 persistent 变量记录调用次数
    persistent callCount
    if isempty(callCount)
        callCount = 1;
    else
        callCount = callCount + 1;
    end

    % 获取当前脚本名称并去掉开头的 'm'（如果存在）
    [~, scriptName, ~] = fileparts(scriptFullPath);
    if scriptName(1) == 'm'
        scriptName = scriptName(2:end);
    end

    % 根据调用次数生成文件名
    figName = sprintf('p%s_%d.png', scriptName, callCount);
    print(gcf, figName, '-dpng', ['-r', num2str(dpi)]);
end
