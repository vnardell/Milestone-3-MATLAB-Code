data = readtable('BPC_TestSignal (1).csv');

time = data.Time;
pressure_V = data.Ch1;
oscillometric = data.Ch2;

V_at_150mmHg = 2.76;  
V_at_0mmHg = 1.13;    

m = (150 - 0) / (V_at_150mmHg - V_at_0mmHg);  
b = 0 - m * V_at_0mmHg;  

pressure_mmHg = m * pressure_V + b;

nonzero_idx = find(pressure_V > 0, 1, 'first');
time = time(nonzero_idx:end);
pressure_V = pressure_V(nonzero_idx:end);
pressure_mmHg = pressure_mmHg(nonzero_idx:end);
oscillometric = oscillometric(nonzero_idx:end);

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

[max_amplitude, max_idx] = max(amplitude_points);
MAP_V = pressure_V_points(max_idx);
MAP_mmHg = pressure_mmHg_points(max_idx);

fprintf('=== RESULTS ===\n');
fprintf('Mean Arterial Pressure (MAP):\n');
fprintf('  Voltage: %.4f V\n', MAP_V);
fprintf('  Pressure: %.2f mmHg\n', MAP_mmHg);
fprintf('Maximum Amplitude: %.4f V\n', max_amplitude);
fprintf('Found at index: %d\n', max_idx);
fprintf('\n');
fprintf('Conversion formula: mmHg = %.4f * V + %.4f\n', m, b);