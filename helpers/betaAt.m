function beta = betaAt(betaPlant, t)
    if isa(betaPlant, 'function_handle')
        beta = betaPlant(t);
    else
        beta = betaPlant;
    end
end