function perceive_plot_bsl_bipolar(d)

% plots LFP and stimulation amplitude for BrainSense LFP bipolar recordings (BSL)
%
% input:
%   d: FieldTrip-compatible struct with fields:
%      - realtime: timestamps
%      - trial{1}: matrix of signal and stimulation data
%      - label: channel labels
%
% LEFT = rows 1 (LFP) and 3 (stimulation)
% RIGHT = rows 2 (LFP) and 4 (stimulation)

fig = figure('Units','centimeters','PaperUnits','centimeters','Position',[1 1 40 20]);
%fig = figure('Units','centimeters','Position',[1 1 40 20]); set(fig, 'Renderer', 'opengl');
%fig = figure('Units','pixels','Position',[100 100 1200 700]);
set(fig, 'Renderer', 'opengl');

% Define colors swapped
darkYellow = [184, 134, 11]/255; % DarkGoldenRod (LFP)
darkRed = [139, 0, 0]/255;       % dark red (Stimulation)

% Helper function to get stimulation ylim with minimum [0, 2.5]
getStimYLim = @(data) [0, max(2.5, max(data))];

% LEFT
subplot(2,1,1)

yyaxis left
lp = plot(d.realtime, d.trial{1}(1,:), 'LineWidth', 2, 'Color', darkYellow);
ylabel('LFP Amplitude')
ax = gca;
ax.YColor = darkYellow;  % left y-axis color now dark yellow
ax.YAxis(1).Exponent = 0; % remove x10^n on left y-axis

yyaxis right
sp = plot(d.realtime, d.trial{1}(3,:), 'LineWidth', 2, 'LineStyle', '--', 'Color', darkRed);
ylabel('Stimulation Amplitude')
ax.YColor = darkRed; % right y-axis color now dark red

% Fix right y-axis limits for stimulation amplitude
stimDataLeft = d.trial{1}(3,:);
ylimRightLeft = getStimYLim(stimDataLeft);
ax.YAxis(2).Limits = ylimRightLeft;

title('LEFT')
legend([lp sp], strrep(d.label([1 3]), '_', ' '), 'Location', 'northoutside')
xlabel('Time')
xlim([d.realtime(1) d.realtime(end)])

% RIGHT
subplot(2,1,2)

yyaxis left
lp = plot(d.realtime, d.trial{1}(2,:), 'LineWidth', 2, 'Color', darkYellow);
ylabel('LFP Amplitude')
ax = gca;
ax.YColor = darkYellow;  % left y-axis color now dark yellow
ax.YAxis(1).Exponent = 0; % remove x10^n on left y-axis

yyaxis right
sp = plot(d.realtime, d.trial{1}(4,:), 'LineWidth', 2, 'LineStyle', '--', 'Color', darkRed);
ylabel('Stimulation Amplitude')
ax.YColor = darkRed; % right y-axis color now dark red

% Fix right y-axis limits for stimulation amplitude
stimDataRight = d.trial{1}(4,:);
ylimRightRight = getStimYLim(stimDataRight);
ax.YAxis(2).Limits = ylimRightRight;

title('RIGHT')
legend([lp sp], strrep(d.label([2 4]), '_', ' '), 'Location', 'northoutside')
xlabel('Time')
xlim([d.realtime(1) d.realtime(end)])

% title for entire figure
d.fname=strrep(d.fname, 'BSL','BSL-LFPAmpStimAmp');
sgtitle(regexprep(d.fname, '_', '\\_'))

exportgraphics(fig, fullfile(d.hdr.fpath, d.fname + ".png"), 'Resolution', 200);


%perceive_print(fullfile(d.hdr.fpath,[strrep(d.fname, 'BSL','BrainSenseBip')]))
perceive_print(fullfile(d.hdr.fpath,[d.fname]))


end
