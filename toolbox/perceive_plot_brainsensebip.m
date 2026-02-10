function perceive_plot_brainsensebip(fulldata, bsl, hdr)
% perceive_plot_brainsensebip Plots BrainSense BIP data with time-frequency analysis
%
% Inputs:
%   fulldata - Structure containing trial data, time vector, sample rate, labels, and filename
%   bsl      - Structure containing baseline data with TherapySnapshot info
%   hdr      - Header structure with file path info for saving the figure
%
% This function generates a 2x2 subplot figure visualizing raw signals, LFP, stimulation amplitudes,
% and time-frequency spectrograms for left and right channels, with additional zoomed-in views.

% Check if recording is long enough (> 20 seconds at 250 Hz * 20 = 5000 samples)
if size(fulldata.trial{1}, 2) > 250*20
    figure('Units', 'centimeters', 'PaperUnits', 'centimeters', 'Position', [1 1 40 20])
    
    % --- Subplot 1 (Top-left) ---
    subplot(2,2,1)
    yyaxis left
    plot(fulldata.time{1}, fulldata.trial{1}(1,:))
    ylabel('Raw amplitude')
    
    % Determine peak frequency for left or right TherapySnapshot
    if isfield(bsl.data.hdr.BSL.TherapySnapshot, 'Left')
        pkfreq = bsl.data.hdr.BSL.TherapySnapshot.Left.FrequencyInHertz;
    elseif isfield(bsl.data.hdr.BSL.TherapySnapshot, 'Right')
        pkfreq = bsl.data.hdr.BSL.TherapySnapshot.Right.FrequencyInHertz;
    else
        error('Neither Left nor Right TherapySnapshot present');
    end
    
    hold on
    [tf, t, f] = perceive_raw_tf(fulldata.trial{1}(1,:), fulldata.fsample, 128, 0.3);
    mpow = nanmean(tf(perceive_sc(f, pkfreq-4):perceive_sc(f, pkfreq+4), :));
    
    yyaxis right
    ylabel('LFP and STIM amplitude')
    plot(fulldata.time{1}, fulldata.trial{1}(3,:))
    xlim([fulldata.time{1}(1), fulldata.time{1}(end)])
    hold on
    plot(fulldata.time{1}, fulldata.trial{1}(5,:) * 1000)
    plot(t, mpow * 1000)
    
    title(strrep({fulldata.label{3}, fulldata.label{5}}, '_', ' '))
    
    % Small inset: power spectrum
    axes('Position', [.34 .8 .1 .1])
    box off
    plot(f, nanmean(log(tf), 2))
    xlabel('Frequency (Hz)')
    ylabel('Power')
    xlim([3 40])
    
    % Small inset: zoomed raw amplitude
    axes('Position', [.16 .8 .1 .1])
    box off
    plot(fulldata.time{1}, fulldata.trial{1}(1,:))
    xlabel('Time (s)')
    ylabel('Amplitude')
    xx = randi([round(fulldata.time{1}(1)), round(fulldata.time{1}(end))], 1);
    xlim([xx xx+1.5])
    
    % Time-frequency spectrogram
    subplot(2,2,3)
    imagesc(t, f, log(tf))
    axis xy
    xlabel('Time [s]')
    ylabel('Frequency [Hz]')
    
    % --- Subplot 2 (Top-right) ---
    subplot(2,2,2)
    yyaxis left
    plot(fulldata.time{1}, fulldata.trial{1}(2,:))
    ylabel('Raw amplitude')
    
    % Determine peak frequency for right or left TherapySnapshot (reverse order)
    if isfield(bsl.data.hdr.BSL.TherapySnapshot, 'Right')
        pkfreq = bsl.data.hdr.BSL.TherapySnapshot.Right.FrequencyInHertz;
    elseif isfield(bsl.data.hdr.BSL.TherapySnapshot, 'Left')
        pkfreq = bsl.data.hdr.BSL.TherapySnapshot.Left.FrequencyInHertz;
    else
        error('Neither Left nor Right TherapySnapshot present');
    end
    
    hold on
    [tf, t, f] = perceive_raw_tf(fulldata.trial{1}(2,:), fulldata.fsample, fulldata.fsample, 0.5);
    mpow = nanmean(tf(perceive_sc(f, pkfreq-4):perceive_sc(f, pkfreq+4), :));
    
    yyaxis right
    ylabel('LFP and STIM amplitude')
    plot(fulldata.time{1}, fulldata.trial{1}(4,:))
    xlim([fulldata.time{1}(1), fulldata.time{1}(end)])
    hold on
    plot(fulldata.time{1}, fulldata.trial{1}(6,:) * 1000)
    plot(t, mpow * 1000)
    
    title(strrep({fulldata.fname, fulldata.label{4}, fulldata.label{6}}, '_', ' '))
    
    % Small inset: power spectrum
    axes('Position', [.78 .8 .1 .1])
    box off
    plot(f, nanmean(log(tf), 2))
    xlabel('Frequency (Hz)')
    ylabel('Power')
    xlim([3 40])
    
    % Small inset: zoomed raw amplitude
    axes('Position', [.6 .8 .1 .1])
    box off
    plot(fulldata.time{1}, fulldata.trial{1}(2,:))
    xlabel('Time (s)')
    ylabel('Amplitude')
    xlim([xx xx+1.5])
    
    % Time-frequency spectrogram
    subplot(2,2,4)
    imagesc(t, f, log(tf))
    axis xy
    xlabel('Time [s]')
    ylabel('Frequency [Hz]')
    
    % Save or print figure
    perceive_print(fullfile('.', hdr.fpath, fulldata.fname))
else
    disp('The recording was less than 20 seconds. No figure created.');
    disp('Please review if missing expected output.');
end

end
