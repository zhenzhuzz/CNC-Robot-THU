function [X_f_filtered] = f070_filterFreqs_05(f, X_f, frequencies, tol)
    % 过滤掉与频率相差 ±tol 的频率
    % Function to remove frequencies within the tolerance of given frequencies
    X_f_filtered = X_f;  % Initialize the filtered FFT to the original
    for i = 1:length(frequencies)
        % Remove frequencies within the tolerance range
        freq_mask = abs(f - frequencies(i)) < tol;
        X_f_filtered(freq_mask) = 0;  % Set corresponding FFT magnitudes to zero
    end
end