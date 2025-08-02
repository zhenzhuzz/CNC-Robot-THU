function f040_saveFigPNG(scriptFullPath, dpi)
    % 自动根据脚本名保存高分辨率PNG图片
    %
    % 调用示例：
    % f040_saveFigPNG(mfilename('fullpath')); % 默认1500 dpi
    % f040_saveFigPNG(mfilename('fullpath'), 1200); % 指定dpi

    arguments
        scriptFullPath (1,:) char
        dpi (1,1) double = 1500
    end

    % 获取当前脚本名称并替换开头m为p
    [~, scriptName, ~] = fileparts(scriptFullPath);
    if scriptName(1)=='m'
        figName = ['p', scriptName(2:end), '.png'];
    else
        figName = [scriptName, '.png'];
    end

    % 保存当前figure为PNG
    print(gcf, figName, '-dpng', ['-r', num2str(dpi)]);
end
