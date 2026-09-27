function P = setParameters()

    P.figureConsistent = true;
    
    % Table 1 and Sec. 4 parameters in [A]
    P.a       = 3.9143;      % thermal diffusivity, [mm^2/s]
    P.Ar_um2  = 10942;       % desired melt-pool area, [um^2]
    P.Ar      = P.Ar_um2*1e-6; % [mm^2]
    P.cL      = 680;         % molten material specific heat, [J/(kg K)]
    P.cS      = 405;         % solid material specific heat, [J/(kg K)]
    P.hSL     = 2.87e5;      % latent heat of fusion, [J/kg]
    P.hSP     = 0.1;         % hatch spacing, [mm]
    P.k       = 0.0182;      % thermal conductivity, [W/(mm K)]
    P.r       = 1.75;        % width-to-depth ratio
    P.Ta      = 292;         % ambient temperature, [K]
    P.Tm      = 1568;        % melting temperature, [K]
    P.v       = 800;         % scan speed, [mm/s]
    P.alphaG  = 220/1e6;     % gas convection coefficient, [W/(mm^2 K)]
    P.betaNom = 10;          % nominal length-to-width ratio
    P.deltaBeta = 4;         % uncertainty half-width used in Sec. 4
    P.epsilon = 0.43;        % melt-surface emissivity
    P.eta     = 0.4;         % laser transmission efficiency
    P.mu      = 0.2;         % material temperature ratio
    P.rho     = 8440/1e9;    % density, [kg/mm^3]
    P.sigmaSB = 5.67e-8/1e6; % Stefan-Boltzmann constant, [W/(mm^2 K^4)]

    % For case 3 only:
    P.etaPlantTrue = P.eta;
    P.etaCtrlNom   = P.eta;
    P.betaCtrlNom  = P.betaNom;
    
    if P.figureConsistent
        P.L = 10;              % mm; figure-consistent value
        P.Kp = 500;            % 1/s; figure-consistent value
        P.alphaS = 2e5/1e6;    % W/(mm^2 K); figure-consistent value
    else
        P.L = 100;             % mm; table-literal value
        P.Kp = 5000;           % 1/s; table-literal value
        P.alphaS = 2e-5/1e6;   % W/(mm^2 K); table-literal value
    end
    
    % Steady melt-pool temperature and internal energy used in Eq. (2).
    P.T = P.Tm*(1 + P.mu);
    P.eInternal = P.cS*(P.Tm - P.Ta) + P.hSL + P.cL*P.mu*P.Tm;
    
    % Simulation horizon: eight tracks, as in Figs. 6-15.
    P.nTracks = 8;
    P.tau = P.L/P.v;
    P.tEnd = P.nTracks*P.tau;
    P.dt = 2.5e-6;
    
    % Avoid the A^{-1/2} singularity at exactly zero area.
    P.A0 = 1e-7;      % mm^2 = 0.1 um^2; visually zero on the plots
    P.AFloor = P.A0;
    
    % Noisy measured melt-pool area signal.
    % Internal area units are mm^2. User-facing noise levels are in um^2.
    % Set enabled=false to recover the original clean-area simulations.
    P.areaNoise.enabled = true;           % generate/store A_noisy
    P.areaNoise.useForControl = true;     % true: controllers see A_noisy
    P.areaNoise.sigma_um2 = 100;          % Gaussian noise standard deviation
    P.areaNoise.bias_um2 = 0;             % optional measurement bias
    P.areaNoise.seed = 1;                 % reproducible noise; [] uses current rng
    P.areaNoise.clipNonnegative = true;   % prevent negative measured areas
    P.areaNoise.plotSignal = "true";     % "true", "noisy", or "control"
    
    % Robust SMC constants.
    P.tReach = 0.75*P.tau;
    P.gamma = sqrt(2)*P.Ar/P.tReach;  % Eq. (15), using V(0)=0.5*Ar^2
    P.gammaTilde = 1.0*P.gamma;      % not specified in paper; chosen for Fig. 9 peak
    P.epsilonA = 1.75e-10*1e6;       % Eq. (33)/(34): m^2 -> mm^2
    P.Qsat = 400;                    % W; Sec. 4 saturation used in Figs. 9, 11, 13, 15
    
    % Adaptive gain super-twisting settings.
    % The control law uses only betaHat = betaNom as a nominal model. It does
    % not use betaNom +/- deltaBeta or any known uncertainty bound.
    P.AGSTC.betaHat = P.betaCtrlNom;
    P.AGSTC.kappa0 = 30;            % initial first super-twisting gain
                                      % was 12
                                      % 30 works good
    P.AGSTC.kappaMin = 1;           % lower gain floor
                                      % was 1
    P.AGSTC.kappaMax = Inf;         % numerical safety cap; set Inf to disable
                                      % was 100
    P.AGSTC.epsilonST = 20;         % beta_ST(t) = 2*epsilonST*alpha(t)
                                      % was 20
    P.AGSTC.rhoUp = 1500;           % gain-increase rate when |e| > varpi
    P.AGSTC.rhoDown = 200;          % gain-decrease rate when |e| <= varpi
    P.AGSTC.etaMin = 1500;          % recovery rate if alpha reaches kappaMin
    P.AGSTC.varpi = 1e-3;          % mm^2; detector threshold = 50 um^2
                                      % was 1e-3  
    %P.AGSTC.varpi = 0; 
    P.AGSTC.nu0 = 0;                % integral super-twisting state
                                      % was 0
    P.AGSTC.useSaturation = true;   % compare under the same 0 <= Q <= Qsat limit
    P.AGSTC.useAntiWindup = true;   % freeze nu if saturation would be worsened
    
    % Figs. 6-7 published red curves. Use 1 for literal Eq. (36) after track 1.
    P.fig67FeedbackGainScaleAfterTrack1 = 0;
    
    % Generate the current date and time in the format ddMMyyyy_HHmmss
    timestamp = char(datetime('now', 'Format', 'ddMMyyyy_HHmmss'));
    
    % Construct the new folder name string
    folderName = ['sim_plots_', timestamp];
    
    % Create the full path for the output directory
    P.outDir = fullfile(pwd, folderName);
    
    % Create the directory 
    if ~exist(P.outDir, 'dir')
        mkdir(P.outDir); 
    end

end
