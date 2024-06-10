
data =  yout.message_rx.signals.values;
guard_size = 100;
preamble_size = 128;
asize = size(data, 1);

data = data((guard_size + 64 + 32 + 16 + 1) : (asize - guard_size) , 1);
datasize = size(data);
datalen = datasize/8;

% converts the image part to phase
phases = angle(data);

% compute phase differetial and converts in range(0, 2*PI)
phaseDiffs = diff([phases(1); phases]); 
phaseDiffsWrapped = wrapTo2Pi(phaseDiffs);

% decoding
decodedBits = zeros(size(phaseDiffsWrapped));
for i = 1:length(phaseDiffsWrapped)
    % set the threshold to pi/2
    if abs(wrapToPi(phaseDiffsWrapped(i))) < pi/2
        decodedBits(i) = 0;
    else
        decodedBits(i) = 1;
    end
end
data = decodedBits;

% converts ASCII to string
numChars = (size(data,1) / 8);
data = reshape(data, 8, numChars).';
str = num2str(data);
b = bin2dec(str);
fprintf(char(b));
