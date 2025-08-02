function [topFreq, topAmp, matchResult] = f050_processFFTMagnitude_findTopFreq_filterfsp_findfchatter_05(f, X_f, topN, spindleFreq, fMax, tol)
    % Function to process FFT magnitude, find top N frequencies, compute spindle harmonics,
    % and match top frequencies with the spindle harmonics.
    % 该函数处理 FFT 幅值，查找前 N 个频率，计算主轴旋转频率的谐波，
    % 并将前 N 个频率与主轴旋转频率的谐波进行匹配。
    % 
    % 输入:
    %   f           - 频率向量 (Frequency vector)
    %   X_f         - 幅值 (Magnitude vector)
    %   topN        - 查找的最大峰值个数 (Number of top peaks to find)
    %   spindleFreq - 主轴旋转频率 (Spindle frequency)
    %   fMax        - 最大频率范围 (Maximum frequency range)
    %   tol         - 谐波匹配的容差 (Tolerance for matching harmonics)
    %
    % 输出:
    %   topFreq     - 前 N 个频率 (Top N frequencies)
    %   topAmp      - 前 N 个频率对应的幅值 (Corresponding amplitudes of top N frequencies)
    %   matchResult - 一个逻辑向量，指示每个 topFreq 是否与主轴旋转频率的谐波匹配 (Logical vector indicating if top frequencies match spindle harmonics)
    
    % Step 1: Find the top N frequencies with the highest magnitudes
    % 步骤 1：查找具有最高幅值的前 N 个频率
    [topFreq, topAmp] = findTopNFreq(f, X_f, topN);
    
    % Step 2: Match top frequencies with spindle harmonics
    % 步骤 2：将 topN 中的频率与主轴旋转频率的谐波进行匹配
    matchResult = TopMatchedSpin(topFreq, spindleFreq, tol, fMax);
    
    % Return the top frequencies, their amplitudes, and match results
    % 返回前 N 个频率，它们的幅值，以及匹配结果
end

function [topNFreq, topNAmp] = findTopNFreq(f, X_f, topN)
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

function harmVec = computeSpindleHarmonics(spindleFreq, fMax)
    % 计算主轴旋转频率及其整数倍谐波（在 fMax 范围内）
    % Compute the spindle frequency and its integer harmonics within the fMax range
    harmVec = [];  % 存储谐波频率
    k = 1;
    while k * spindleFreq <= fMax  % 根据最大频率 fMax 计算谐波
        harmVec(end+1) = k * spindleFreq;  % 添加谐波频率
        k = k + 1;
    end
end

function matchResult = TopMatchedSpin(topFreq, spindleFreq, tol, fMax)
    % 对 topFreq 中的每个频率，判断是否在主轴旋转频率及其谐波附近（tol 内）
    % For each frequency in topFreq, check if it is near the spindle frequency or its harmonics within the tolerance
    harmVec = computeSpindleHarmonics(spindleFreq, fMax);  % 计算主轴谐波
    matchResult = false(size(topFreq));  % 初始化匹配结果
    for i = 1:length(topFreq)  % 遍历每个频率
        if any(abs(topFreq(i) - harmVec) < tol)  % 判断频率是否在谐波附近
            matchResult(i) = true;  % 如果匹配，则设置为 true
        end
    end
end
