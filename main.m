clear;
clc;
close all;

%% Parameters
N = 64;                    % Number of subcarriers
cpLen = 16;                % Cyclic prefix length
numSymbols = 500;          % Number of OFDM symbols per SNR
snr_dB = 0:5:30;           % SNR range
pilotSpacingSet = [4 8 16];% Different pilot spacings
modOrder = 4;              % QPSK
bitsPerSymbol = log2(modOrder);

% Channel parameters
L = 4;                     % Number of channel taps

% Results storage
MSE_LS_all = zeros(length(pilotSpacingSet), length(snr_dB));
MSE_MMSE_all = zeros(length(pilotSpacingSet), length(snr_dB));
BER_LS_all = zeros(length(pilotSpacingSet), length(snr_dB));
BER_MMSE_all = zeros(length(pilotSpacingSet), length(snr_dB));

%% Main loops
for p = 1:length(pilotSpacingSet)
    pilotSpacing = pilotSpacingSet(p);
    pilotPos = 1:pilotSpacing:N;
    dataPos = setdiff(1:N, pilotPos);
    
    numPilots = length(pilotPos);
    numData = length(dataPos);
    bitsPerOFDM = numData * bitsPerSymbol;
    
    fprintf('Running for pilot spacing = %d\n', pilotSpacing);
    
    for s = 1:length(snr_dB)
        snr = snr_dB(s);
        
        mse_ls_sum = 0;
        mse_mmse_sum = 0;
        ber_ls_err = 0;
        ber_mmse_err = 0;
        total_bits = 0;
        
        for sym = 1:numSymbols
            
            %% Generate random bits
            txBits = randi([0 1], bitsPerOFDM, 1);
            
            %% QPSK modulation
            txDataSymbols = qpsk_mod(txBits);
            
            %% Insert pilots
            pilotValue = 1 + 1j;
            X = insert_pilots(N, dataPos, pilotPos, txDataSymbols, pilotValue);
            
            %% OFDM modulation
            x_ifft = ifft(X, N);
            x_cp = [x_ifft(end-cpLen+1:end); x_ifft];
            
            %% Rayleigh multipath channel
            h = (randn(L,1) + 1j*randn(L,1)) / sqrt(2*L);
            y_channel = conv(x_cp, h);
            
            %% Add AWGN
            signalPower = mean(abs(y_channel).^2);
            noisePower = signalPower / (10^(snr/10));
            noise = sqrt(noisePower/2) * (randn(size(y_channel)) + 1j*randn(size(y_channel)));
            y_rx = y_channel + noise;
            
            %% Receiver: remove extra samples from convolution
            y_rx = y_rx(1:length(x_cp));
            
            %% Remove cyclic prefix
            y_no_cp = y_rx(cpLen+1:cpLen+N);
            
            %% FFT
            Y = fft(y_no_cp, N);
            
            %% True channel in frequency domain
            H_true = fft(h, N);
            
            %% LS Estimation
            H_ls = ls_estimator(Y, pilotPos, pilotValue, N);
            
            %% MMSE Estimation
            H_mmse = mmse_estimator(Y, pilotPos, pilotValue, N, noisePower);
            
            %% Equalization
            X_hat_ls = Y(dataPos) ./ H_ls(dataPos);
            X_hat_mmse = Y(dataPos) ./ H_mmse(dataPos);
            
            %% Demodulation
            rxBits_ls = qpsk_demod(X_hat_ls);
            rxBits_mmse = qpsk_demod(X_hat_mmse);
            
            %% BER
            ber_ls_err = ber_ls_err + sum(txBits ~= rxBits_ls);
            ber_mmse_err = ber_mmse_err + sum(txBits ~= rxBits_mmse);
            total_bits = total_bits + length(txBits);
            
            %% MSE
            mse_ls_sum = mse_ls_sum + mean(abs(H_true(:) - H_ls(:)).^2);
            mse_mmse_sum = mse_mmse_sum + mean(abs(H_true(:) - H_mmse(:)).^2);
        end
        
        MSE_LS_all(p,s) = mse_ls_sum / numSymbols;
        MSE_MMSE_all(p,s) = mse_mmse_sum / numSymbols;
        BER_LS_all(p,s) = ber_ls_err / total_bits;
        BER_MMSE_all(p,s) = ber_mmse_err / total_bits;
    end
end

%% Plot MSE for each pilot spacing
for p = 1:length(pilotSpacingSet)
    figure;
    semilogy(snr_dB, MSE_LS_all(p,:), '-o', 'LineWidth', 2); hold on;
    semilogy(snr_dB, MSE_MMSE_all(p,:), '-s', 'LineWidth', 2);
    grid on;
    xlabel('SNR (dB)');
    ylabel('MSE');
    title(['MSE vs SNR (Pilot Spacing = ', num2str(pilotSpacingSet(p)), ')']);
    legend('LS', 'MMSE');
end

%% Plot BER for each pilot spacing
for p = 1:length(pilotSpacingSet)
    figure;
    semilogy(snr_dB, BER_LS_all(p,:), '-o', 'LineWidth', 2); hold on;
    semilogy(snr_dB, BER_MMSE_all(p,:), '-s', 'LineWidth', 2);
    grid on;
    xlabel('SNR (dB)');
    ylabel('BER');
    title(['BER vs SNR (Pilot Spacing = ', num2str(pilotSpacingSet(p)), ')']);
    legend('LS', 'MMSE');
end

%% Pilot efficiency plot at one SNR example
chosenSNRindex = 4; % around 15 dB if snr_dB = 0:5:30
figure;
plot(pilotSpacingSet, MSE_LS_all(:,chosenSNRindex), '-o', 'LineWidth', 2); hold on;
plot(pilotSpacingSet, MSE_MMSE_all(:,chosenSNRindex), '-s', 'LineWidth', 2);
grid on;
xlabel('Pilot Spacing');
ylabel('MSE');
title(['Effect of Pilot Spacing on MSE at SNR = ', num2str(snr_dB(chosenSNRindex)), ' dB']);
legend('LS', 'MMSE');

disp('Simulation finished successfully.');