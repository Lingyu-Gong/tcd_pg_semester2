%% example_plot_Pb_vs_EbNo_BPSK.m
%   Example script that plots bit error probability curve
%    for BPSK.


clear all
close all

%% set range for Eb/No values
EbN0_dB = 0:0.1:12; % log scale
EbN0 = 10.^(EbN0_dB/10);  % convert to linear units

%% compute probability of bit error
Pe = qfunc(sqrt(2*EbN0));

%% plot
semilogy(EbN0_dB, Pe)
grid on
xlabel('E_b/N_0 (dB)')
ylabel('probability of bit error')
