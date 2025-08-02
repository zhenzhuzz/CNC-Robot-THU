function acc_info(dt, df, Fs)
    
    % Display the information
    disp([' df  = ', num2str(df, '%8.4g'), ' Hz']);
    disp([' dt  = ', num2str(dt, '%8.4g'), ' sec']);
    disp([' sr  = ', num2str(Fs, '%8.4g'), ' samples/sec']);
end
