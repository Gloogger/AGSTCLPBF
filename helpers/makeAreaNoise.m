function areaNoise = makeAreaNoise(P, N)

    if ~isfield(P, 'areaNoise') || ~P.areaNoise.enabled
        areaNoise = zeros(1, N);
        return;
    end
    
    sigma = P.areaNoise.sigma_um2*1e-6;
    bias  = P.areaNoise.bias_um2*1e-6;
    
    if isempty(P.areaNoise.seed)
        areaNoise = bias + sigma*randn(1, N);
    else
        oldRng = rng;
        rng(P.areaNoise.seed, 'twister');
        areaNoise = bias + sigma*randn(1, N);
        rng(oldRng);
    end
end