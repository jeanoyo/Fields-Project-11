function results = fit2E(CpPredicted, times, singleBloodDraw, ...
    bloodDrawTime, singleBloodDrawErrFactor)
%FIT2E Summary of this function goes here
%   Detailed explanation goes here
    
    fity = @(b,x) b(1)*exp(-b(2)*x) + b(3)*exp(-b(4)*x)+b(5);
    
    phi1 = @(b) trapz((CpPredicted - fity(b,times)).^2) + singleBloodDrawErrFactor * ...
        ( (fity(b, bloodDrawTime + 0.05) - fity(b, bloodDrawTime - .05)) * 10 ...
        - singleBloodDraw) ^ 2;
    % Takes single blood draw into account for error.

    tic;
    results = simulatedAnnealing(phi1,...
        [0.1 0.002 0.1 0 0], ...
        [-1e6 0 -1e6 0 0], ...
        [0 0.01 0 0.001 2e6 ], 1e6, 1e-7, 0.90);
    disp(['Time elapsed in round ' num2str(1) ':']);
    toc;
end

