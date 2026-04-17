function H_ls = ls_estimator(Y, pilotPos, pilotValue, N)
    H_pilot_ls = Y(pilotPos) / pilotValue;
    H_ls = interpolate_channel(pilotPos, H_pilot_ls, N);
end