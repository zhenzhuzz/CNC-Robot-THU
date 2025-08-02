function [topNFreq, topNAmp] = f051_findTopNFreq_05(f, X_f, topN)
    % 查找 FFT 幅值中最大 topN 个峰值对应的频率，要求每个峰值之间至少相差 20Hz
    % Find the top N peaks in the FFT magnitude corresponding to frequencies, ensuring that each peak is at least 20Hz apart
    tol = 20;  % Hz, 最小频率差（20Hz）
    [sortedAmp, sortedIdx] = sort(X_f, 'descend');  % 按幅值从大到小排序
    topNFreq = [];  % 存储前 N 个频率
    topNAmp = [];   % 存储前 N 个幅值
    for i = 1:length(sortedAmp)
        candidateFreq = f(sortedIdx(i));  % 当前候选频率
        candidateAmp = sortedAmp(i);      % 当前候选幅值
        if isempty(topNFreq) || all(abs(candidateFreq - topNFreq) >= tol)  % 确保相邻的峰值至少相差 20Hz
            topNFreq(end+1) = candidateFreq;  % 存储频率
            topNAmp(end+1) = candidateAmp;    % 存储幅值
        end
        if length(topNFreq) >= topN  % 如果已找到足够的峰值，则停止
            break;
        end
    end
end