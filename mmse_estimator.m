function H_mmse = mmse_estimator(Y, pilotPos, pilotValue, N, noisePower)
    H_ls_pilot = Y(pilotPos) / pilotValue;
    
    numPilots = length(pilotPos);
    
    % Simple correlation model
    Rpp = zeros(numPilots, numPilots);
    for i = 1:numPilots
        for j = 1:numPilots
            delta = abs(pilotPos(i) - pilotPos(j));
            Rpp(i,j) = 0.9^(delta);
        end
    end
    
    Rpp = Rpp + noisePower * eye(numPilots);
    
    R_hp = zeros(N, numPilots);
    for k = 1:N
        for j = 1:numPilots
            delta = abs(k - pilotPos(j));
            R_hp(k,j) = 0.9^(delta);
        end
    end
    
    H_mmse = R_hp / Rpp * H_ls_pilot;
end