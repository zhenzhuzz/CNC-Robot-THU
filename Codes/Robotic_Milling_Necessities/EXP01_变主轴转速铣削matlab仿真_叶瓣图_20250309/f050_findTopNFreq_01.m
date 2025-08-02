%% 查找 FFT 幅值中最大 topN 个峰值对应的频率，要求各峰值间至少相差 tol Hz
function [topNFreq, topNAmp] = findTopNFreq(f, X_f, topN)
    % 参数说明:
    %   f     - 频率向量 (Hz)
    %   X_f   - FFT归一化后的幅值向量
    %   topN  - 需要选出的峰值个数（例如3或1）
    %
    % 输出:
    %   topNFreq - 选出的峰值对应的频率
    %   topNAmp  - 对应的幅值

    tol = 20;  % 频率容差，单位 Hz

    % 将幅值从大到小排序
    [sortedAmp, sortedIdx] = sort(X_f, 'descend');

    % 初始化输出
    topNFreq = [];
    topNAmp = [];

    % 遍历候选峰值
    for i = 1:length(sortedAmp)
        candidateFreq = f(sortedIdx(i));
        candidateAmp = sortedAmp(i);
        
        % 如果还没有选中任何峰值，则直接选取
        if isempty(topNFreq)
            topNFreq(end+1) = candidateFreq;
            topNAmp(end+1) = candidateAmp;
        else
            % 检查候选频率与已选频率之间的差是否都不少于 tol
            if all(abs(candidateFreq - topNFreq) >= tol)
                topNFreq(end+1) = candidateFreq;
                topNAmp(end+1) = candidateAmp;
            end
        end
        
        % 如果已经选够 topN 个，则退出循环
        if length(topNFreq) >= topN
            break;
        end
    end
end
