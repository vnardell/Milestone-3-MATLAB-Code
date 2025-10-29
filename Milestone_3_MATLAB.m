data = readtable('BPC_TestSignal (1).csv');
time = data.Time;
pressure_V = data.Ch1;
oscillometric = data.Ch2;

% Calibration points
V_at_150mmHg = 2.76;
V_at_0mmHg = 1.13;
m = (150 - 0) / (V_at_150mmHg - V_at_0mmHg);
b = 0 - m * V_at_0mmHg;
pressure_mmHg = m * pressure_V + b;

% Remove zero values
nonzero_idx = find(pressure_V > 0, 1, 'first');
time = time(nonzero_idx:end);
pressure_V = pressure_V(nonzero_idx:end);
pressure_mmHg = pressure_mmHg(nonzero_idx:end);
oscillometric = oscillometric(nonzero_idx:end);

% Sliding window analysis
window_size = 100;
step_size = 20;
pressure_V_points = [];
pressure_mmHg_points = [];
amplitude_points = [];

for i = 1:step_size:(length(oscillometric) - window_size)
    % Get window of data
    window = oscillometric(i:i+window_size-1);
    pressure_V_window = pressure_V(i:i+window_size-1);
    pressure_mmHg_window = pressure_mmHg(i:i+window_size-1);
    
    % Calculate peak-to-peak amplitude
    amplitude = max(window) - min(window);
    avg_pressure_V = mean(pressure_V_window);
    avg_pressure_mmHg = mean(pressure_mmHg_window);
    
    pressure_V_points = [pressure_V_points; avg_pressure_V];
    pressure_mmHg_points = [pressure_mmHg_points; avg_pressure_mmHg];
    amplitude_points = [amplitude_points; amplitude];
end

% Find Mean Arterial Pressure (MAP) - maximum amplitude
[max_amplitude, max_idx] = max(amplitude_points);
MAP_V = pressure_V_points(max_idx);
MAP_mmHg = pressure_mmHg_points(max_idx);

% Find Systolic Pressure - 0.5x maximum amplitude on the high pressure side
systolic_target = 0.5 * max_amplitude;

% Search only on the high pressure side (before MAP index)
systolic_idx = [];
min_diff = inf;
for i = 1:(max_idx-1)
    diff = abs(amplitude_points(i) - systolic_target);
    if diff < min_diff
        min_diff = diff;
        systolic_idx = i;
    end
end

Systolic_V = pressure_V_points(systolic_idx);
Systolic_mmHg = pressure_mmHg_points(systolic_idx);

% Find Diastolic Pressure - 0.8x maximum amplitude on the low pressure side
diastolic_target = 0.8 * max_amplitude;

% Search only on the low pressure side (after MAP index)
diastolic_idx = [];
min_diff = inf;
for i = (max_idx+1):length(amplitude_points)
    diff = abs(amplitude_points(i) - diastolic_target);
    if diff < min_diff
        min_diff = diff;
        diastolic_idx = i;
    end
end

Diastolic_V = pressure_V_points(diastolic_idx);
Diastolic_mmHg = pressure_mmHg_points(diastolic_idx);

% Display results
fprintf('=== BLOOD PRESSURE RESULTS ===\n');
fprintf('\nMean Arterial Pressure (MAP):\n');
fprintf('  Voltage: %.4f V\n', MAP_V);
fprintf('  Pressure: %.2f mmHg\n', MAP_mmHg);
fprintf('  Maximum Amplitude: %.4f V\n', max_amplitude);

fprintf('\nSystolic Pressure (0.5 × MAP amplitude):\n');
fprintf('  Voltage: %.4f V\n', Systolic_V);
fprintf('  Pressure: %.2f mmHg\n', Systolic_mmHg);
fprintf('  Amplitude: %.4f V (%.2f%% of max)\n', ...
    amplitude_points(systolic_idx), ...
    100*amplitude_points(systolic_idx)/max_amplitude);

fprintf('\nDiastolic Pressure (0.8 × MAP amplitude):\n');
fprintf('  Voltage: %.4f V\n', Diastolic_V);
fprintf('  Pressure: %.2f mmHg\n', Diastolic_mmHg);
fprintf('  Amplitude: %.4f V (%.2f%% of max)\n', ...
    amplitude_points(diastolic_idx), ...
    100*amplitude_points(diastolic_idx)/max_amplitude);

fprintf('\n*** Blood Pressure Reading: %d/%d mmHg ***\n', ...
    round(Systolic_mmHg), round(Diastolic_mmHg));

fprintf('\nConversion formula: mmHg = %.4f * V + %.4f\n', m, b);