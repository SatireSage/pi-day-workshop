%% Setup serial connection
% portName = "COM3"; % Windows Machine
portName = "/dev/cu.usbmodem2101";
baudRate = 115200;
device = serialport(portName, baudRate);

configureTerminator(device, "LF"); % The Pico prints newline '\n' by default
device.Timeout = 5;               % seconds to wait for data

%% Prepare figure and subplots
figure('Name','Pico Sensor Readings','NumberTitle','off');
% We'll use the same figure but switch what we plot depending on the mode.
% Create two subplots for Voltage vs Sample# and Resistance vs Sample#.
% We'll do this for each sensor type, but we will only update the data 
% relevant to the current mode.

% Subplot placeholders for dynamic updating
subplot(2,1,1);
hPlotVoltage = plot(NaN, NaN, 'b-o');
xlabel('Sample #');
ylabel('Voltage (V)');
title('Voltage vs. Sample');
grid on;

subplot(2,1,2);
hPlotResistance = plot(NaN, NaN, 'r-o');
xlabel('Sample #');
ylabel('Resistance (Ohms)');
title('Resistance vs. Sample');
grid on;

%% Storage for each mode
% We keep separate arrays for Photoresistor (LDR) data and Pot data
photoVoltage = [];
photoResistance = [];
photoSampleIdx = 0;

potVoltage = [];
potResistance = [];
potSampleIdx = 0;

% Fixed resistor in voltage divider (adjust if different in your circuit)
R_fixed = 10e3; % 10 kOhms

%% Start read loop: press Ctrl+C in the Command Window to stop
while true
    % Read one line of text from the Pico
    lineOfData = readline(device);
    disp(lineOfData);  % (Optional) for debugging, display the raw line

    %---------------------------------------------------------------
    % 1) Parse out the Mode, e.g. "Mode: Photoresistor" or "Mode: Potentiometer"
    %    We look for: Mode: {some_string}
    %---------------------------------------------------------------
    modeTokens = regexp(lineOfData, 'Mode:\s*([A-Za-z]+)', 'tokens');
    if isempty(modeTokens)
        % If there's no valid mode line, skip to next
        continue;
    end
    currentMode = modeTokens{1}{1};  % e.g. 'Photoresistor' or 'Potentiometer'

    %---------------------------------------------------------------
    % 2) Parse out the Sensor value, e.g. "Sensor: 12345"
    %---------------------------------------------------------------
    sensorTokens = regexp(lineOfData, 'Sensor:\s*(\d+)', 'tokens');
    if isempty(sensorTokens)
        % If there's no valid sensor line, skip
        continue;
    end
    currentSensorValue = str2double(sensorTokens{1});  % e.g. 12345

    %---------------------------------------------------------------
    % 3) Convert raw ADC reading (0 to 65535) to voltage
    %---------------------------------------------------------------
    sensorVoltage = (currentSensorValue / 65535) * 3.3;

    %---------------------------------------------------------------
    % 4) Compute approximate sensor resistance
    %---------------------------------------------------------------
    if sensorVoltage < 3.3
        sensorResistance = R_fixed * ((3.3 - sensorVoltage) / sensorVoltage);
    else
        % Avoid divide-by-zero if sensorVoltage is extremely close to 3.3
        sensorResistance = Inf; 
    end

    %---------------------------------------------------------------
    % 5) Based on mode, update our arrays and re-plot
    %---------------------------------------------------------------
    switch lower(currentMode)
        case 'photoresistor'
            % Increment index and store new data
            photoSampleIdx = photoSampleIdx + 1;
            photoVoltage(photoSampleIdx)    = sensorVoltage;
            photoResistance(photoSampleIdx) = sensorResistance;

            % Update figure name
            set(gcf, 'Name', 'Photoresistor Data (Pico)');

            % Update subplots with photoresistor data
            subplot(2,1,1);
            set(hPlotVoltage, 'XData', 1:photoSampleIdx, 'YData', photoVoltage);
            xlabel('Sample #');
            ylabel('Voltage (V)');
            title('Photoresistor Voltage');

            subplot(2,1,2);
            set(hPlotResistance, 'XData', 1:photoSampleIdx, 'YData', photoResistance);
            xlabel('Sample #');
            ylabel('Resistance (\Omega)');
            title('Photoresistor Resistance');

        case 'potentiometer'
            % Increment index and store new data
            potSampleIdx = potSampleIdx + 1;
            potVoltage(potSampleIdx)    = sensorVoltage;
            potResistance(potSampleIdx) = sensorResistance;

            % Update figure name
            set(gcf, 'Name', 'Potentiometer Data (Pico)');

            % Update subplots with pot data
            subplot(2,1,1);
            set(hPlotVoltage, 'XData', 1:potSampleIdx, 'YData', potVoltage);
            xlabel('Sample #');
            ylabel('Voltage (V)');
            title('Potentiometer Voltage');

            subplot(2,1,2);
            set(hPlotResistance, 'XData', 1:potSampleIdx, 'YData', potResistance);
            xlabel('Sample #');
            ylabel('Resistance (\Omega)');
            title('Potentiometer Resistance');

        otherwise
            % Unknown mode
            continue;
    end

    % Redraw the figure with the updated data
    drawnow limitrate

    % Brief pause to avoid overwhelming updates
    pause(0.01);
end
