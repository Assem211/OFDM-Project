function H_full = interpolate_channel(pilotPos, H_pilot, N)
    allPos = 1:N;
    
    H_real = interp1(pilotPos, real(H_pilot), allPos, 'linear', 'extrap');
    H_imag = interp1(pilotPos, imag(H_pilot), allPos, 'linear', 'extrap');
    
    H_full = H_real + 1j*H_imag;
    H_full = H_full(:);
end