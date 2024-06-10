data = yout.message_rx.signals.values;
guard_size = 100;
% preamble_size = 128; % Unused in the provided code snippet

% Trimming the guard interval and excess preamble bits
data = data((guard_size + 64 + 32 + 16 + 1) : (end - guard_size) , 1);

% Compute the phase of the data
phases = angle(data);

% Compute the phase differentials and wrap them to the range [0, 2*PI]
phaseDiffs = diff([phases(1); phases]); 
phaseDiffsWrapped = wrapTo2Pi(phaseDiffs);

% Decoding based on phase differentials
decodedBits = phaseDiffsWrapped > pi/2;

% Reshape the data for ASCII conversion
numChars = floor(length(decodedBits) / 8);
decodedChars = reshape(decodedBits(1:numChars*8), 8, numChars).';

% Convert binary to ASCII characters
asciiVals = bi2de(decodedChars, 'left-msb');
decodedMessage = char(asciiVals).';

% Display the decoded message
disp(decodedMessage);