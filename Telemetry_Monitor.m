% Telemetry_Monitor_fixed.m
% Pure simulation: generate telemetry samples (HR, SpO2), detect alerts,
% plot time-series, and save results locally (CSV + MAT).

clc; clear; close all;

%% Parameters
numSamples = 120;         % number of simulated samples
sampleIntervalSec = 1;    % seconds between samples (logical simulation)
hr_baseline = 75;         % nominal heart rate (bpm)
sp_baseline = 98;         % nominal SpO2 (%)
hr_noise_level = 6;       % std dev for HR noise
sp_noise_level = 1;       % std dev for SpO2 noise

% Alert thresholds
HR_HIGH = 100;    % bpm
HR_LOW  = 50;     % bpm
SPO2_LOW = 94;    % percent

%% Preallocate
readings = DeviceReading.empty(numSamples,0);
startTime = datetime('now');

%% Simulate readings
for i = 1:numSamples
    t = startTime + seconds((i-1)*sampleIntervalSec);

    % base values + random noise + occasional simulated events
    hr = round(hr_baseline + randn()*hr_noise_level + abnormalHeartEvent(i));
    sp = round(sp_baseline + randn()*sp_noise_level + abnormalSpO2Event(i),1);

    % clamp to realistic physiological ranges
    hr = max(30, min(220, hr));
    sp = max(50, min(100, sp));

    readings(i) = DeviceReading(t, hr, sp);
end

%% Alert detection
alerts = {};
for i = 1:numel(readings)
    r = readings(i);
    if r.HeartRate > HR_HIGH
        alerts{end+1} = sprintf('%s - High HR: %d bpm', datestr(r.Time,'HH:MM:SS'), r.HeartRate); %#ok<SAGROW>
    elseif r.HeartRate < HR_LOW
        alerts{end+1} = sprintf('%s - Low HR: %d bpm', datestr(r.Time,'HH:MM:SS'), r.HeartRate); %#ok<SAGROW>
    end
    if r.SPO2 < SPO2_LOW
        alerts{end+1} = sprintf('%s - Low SpO2: %.1f%%', datestr(r.Time,'HH:MM:SS'), r.SPO2); %#ok<SAGROW>
    end
end

% Print alerts
if isempty(alerts)
    fprintf('No alerts detected.\n');
else
    fprintf('Alerts (%d):\n', numel(alerts));
    fprintf('  %s\n', alerts{:});
end

%% Prepare arrays for plotting and saving
times = [readings.Time]';
hr_values = [readings.HeartRate]';
sp_values = [readings.SPO2]';

%% Plot results (use datetime-friendly formatting)
hFig = figure('Name','Telemetry Monitor','Units','normalized','Position',[0.15 0.2 0.7 0.6]);

ax1 = subplot(2,1,1, 'Parent', hFig);
plot(ax1, times, hr_values, '-o', 'MarkerSize',3);
hold(ax1,'on');
yline(ax1, HR_HIGH,'r--','High Threshold');
yline(ax1, HR_LOW,'r--','Low Threshold');
ylabel(ax1,'Heart Rate (bpm)');
title(ax1,'Heart Rate (simulated)');
grid(ax1,'on');
% Use datetime tick format (preferred over datetick)
ax1.XAxis.TickLabelFormat = 'HH:mm:ss';

ax2 = subplot(2,1,2, 'Parent', hFig);
plot(ax2, times, sp_values, '-o', 'MarkerSize',3);
hold(ax2,'on');
yline(ax2, SPO2_LOW,'r--','SpO2 Low');
ylabel(ax2,'SpO2 (%)');
title(ax2,'SpO2 (simulated)');
grid(ax2,'on');
ax2.XAxis.TickLabelFormat = 'HH:mm:ss';

% Link x-axes using axis handles (cleaner & avoids warnings)
linkaxes([ax1, ax2], 'x');

%% Save outputs (local files)
out_csv = 'telemetry_readings.csv';
T = table(times, hr_values, sp_values, 'VariableNames', {'Time','HeartRate_bpm','SpO2_percent'});
writetable(T, out_csv);
save('telemetry_readings.mat','readings','T');
fprintf('Saved: %s and telemetry_readings.mat\n', out_csv);

%% Nested helper functions (pure simulation logic)
    function offset = abnormalHeartEvent(idx)
        % produce occasional spikes/drops to simulate events
        offset = 0;
        if idx >= 30 && idx <= 35
            if rand() > 0.4
                offset = 25 + 10*rand(); % spike
            end
        elseif idx >= 80 && idx <= 82
            if rand() > 0.5
                offset = -25 - 10*rand(); % drop
            end
        end
    end

    function offset = abnormalSpO2Event(idx)
        offset = 0;
        if idx >= 50 && idx <= 55
            if rand() > 0.3
                offset = -6*rand();
            end
        elseif idx >= 100 && idx <= 104
            if rand() > 0.6
                offset = -8*rand();
            end
        end
    end
