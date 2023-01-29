function result = dtmf_decode(audio_file) 
    [signal, fs] = audioread(audio_file);   
    N = fs; % The number of samples
    fLow = [697, 770, 852, 941]; % Lower frequencies
    fHigh = [1209, 1336, 1477]; % Higher frequencies
    result = ''; %The phone number
    key = ['1', '2', '3'; 
           '4', '5', '6';
           '7', '8', '9';
           '#', '0', '*']; %The keypad
    
    % Filter the original signal using a bandpass and a bandstop filter
    %[bPass, aPass] = butter(6, [680/(fs/2), 1650/(fs/2)], 'bandpass');
    %[bPass, aPass] = cheby1(6, 0.5, [680/(fs/2), 1650/(fs/2)], 'bandpass');
    [bPass, aPass] = ellip(5, 0.5, 20, [680/(fs/2), 1650/(fs/2)], 'bandpass');
    signal = filter(bPass, aPass, signal); 
    %[bStop, aStop] = butter(6, [960/(fs/2), 1190/(fs/2)], 'stop');
    %[bStop, aStop] = cheby1(6, 0.5, [960/(fs/2), 1190/(fs/2)], 'stop');
    [bStop, aStop] = ellip(5, 0.5, 20, [960/(fs/2), 1190/(fs/2)], 'stop');
    signal = filter(bStop, aStop, signal);
    
    % Filter the signal using a moving average filter  
    %filteredSignal = filter(ones(1, round(N/100)), 1, abs(signal/max(signal)));
    filteredSignal = filter(ones(1, round(N/100)), 1, signal.^2);
    
    % The threshold value to detect a pulse
    %T = 0.4*max(filteredSignal); %for the normalized signal
    T = 0.22*max(filteredSignal); %for the squared signal
    if (T < filteredSignal(1))
        T = filteredSignal(1);
    elseif (T < filteredSignal(end))
        T = filteredSignal(end);
    end

%     % Plotting
%     plot(filteredSignal)
%     yline(T, 'red')
%     title(audio_file)

    % Detecting the start indexes and the end indexes and save them
    startIndex = []; endIndex = []; count = 1; flag = false;

    for i = 1:length(filteredSignal)
        if (filteredSignal(i) > T) && (~flag) % Detect the start of a pulse
            startIndex(count) = i;
            flag = true; %Change the boolean flag
        elseif (filteredSignal(i) < T) && (flag) % Detect the end of a pulse
            endIndex(count) = i;
            flag = false; %Reset the flag
            count = count + 1; %increase the count since a complete pulse is detected
        end
    end
    
    % Convert to the frequency domain and find the pair of frequency
    for i = 1:length(endIndex)
        % Each valid signal pulse should be at least 400-sample long
        if (endIndex(i) - startIndex(i) >= 400)
            % Convert to the frequency domain
            Y = fft(signal(startIndex(i):endIndex(i)), N);
            % Find the amplitude of each frequency in fLow and fHigh. After that, find the frequency that 
            % has the maximum amplitude in each list and extract their index as the row and column value.
            [~, row] = max(Y(fLow));
            [~, col] = max(Y(fHigh));
            % Saving the digit that corresponds to the found column and row
            result = append(result, key(row, col));
        end
    end
end