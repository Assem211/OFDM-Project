function X = insert_pilots(N, dataPos, pilotPos, dataSymbols, pilotValue)
    X = zeros(N,1);
    X(dataPos) = dataSymbols;
    X(pilotPos) = pilotValue;
end