%% ========================= 
%      MATLAB Simulation 
%  =========================
%  This matlab simulation script reproduces Figs. 6-15 from the below paper
%     [A] Karagiannis et al., "Robust Feedback Control of Melt Pool Area 
%     in Laser Powder Bed Fusion Via Sliding Mode Design," JDSMC, 2026.
%
%  This script also simulates the closed-loop performance of an 
%  adaptive gain super-twisting controller (AGSTC). 
%
%  Written by Donglin Sui
%  Github: https://github.com/Gloogger
%  Email:  lordblackwoods@gmail.com
%
%  Tested on MATLAB r2026a running on Mac M1 Max Tahoe 26.5

%% ========================= 
%        Initialization 
%  =========================
clear
clf
close all
clc

% ---- addpath of auxiliary functions ----
currentFolder    = fileparts(mfilename('fullpath'));
folderUtilPath   = fullfile(currentFolder, 'utils');
folderHelperPath = fullfile(currentFolder, 'helpers');
folderControllerPath = fullfile(currentFolder, 'controllers');
addpath(folderUtilPath);
addpath(folderHelperPath);
addpath(folderControllerPath);

% ---- Define all constants ----
% parameters can be called using
% P.property
P = setParameters();

% Nominal proportional feedback simulation used as the feedforward map.
Pff = P;
Pff.areaNoise.enabled = false;
nominal = simulateBuild(Pff, Pff.betaNom, "prop_feedback");
Qff.t = nominal.t;
Qff.Q = nominal.Q;

%% --------------------------- Case 1 -------------------------------------
% exact beta
% const. known lambda_bar, eta
% no noise

P.areaNoise.enabled = false; % no noise
case1_smc   = simulateBuild(P, P.betaNom, "smc_sat");
case1_agstc = simulateBuild(P, P.betaNom, "AGSTC");
case1_ff    = simulateBuild(P, P.betaNom, "feedforward", Qff);
case1_const = simulateBuild(P, P.betaNom, "constant");

plotCase1(P, case1_smc, case1_agstc, case1_ff, case1_const)

%% --------------------------- Case 2 -------------------------------------
% exact beta
% const. known lambda_bar, eta
% noisy depth measurement
P.areaNoise.enabled = true;
case2_smc   = simulateBuild(P, P.betaNom, "smc_sat");
case2_agstc = simulateBuild(P, P.betaNom, "AGSTC");
case2_ff    = simulateBuild(P, P.betaNom, "feedforward", Qff);
case2_const = simulateBuild(P, P.betaNom, "constant");

fprintf('Area measurement noise: sigma = %.3f um^2, bias = %.3f um^2, useForControl = %d, plotSignal = %s\n', ...
         P.areaNoise.sigma_um2, ...
         P.areaNoise.bias_um2, ...
         P.areaNoise.useForControl, ...
         char(P.areaNoise.plotSignal));
 
plotCase2(P, case2_smc, case2_agstc, case2_ff, case2_const);

printChatteringMetrics(P, 'Case 2', case2_smc, case2_agstc, case2_ff, case2_const);

%% --------------------------- Case 3 -------------------------------------
% Controller uses nominal beta, the plant beta is time-varying
% plant has const. lambda_bar, eta, controller uses nominal values
% noisy depth measurement

% time-varying beta
betaOsc = @(t) P.betaNom + P.deltaBeta*sin(2*pi*t/P.tEnd);

% for case 3 only, 
P3 = P;
P3.etaCtrlNom = 0.7;      % was 0.7

case3_smc     = simulateBuild(P3, betaOsc, "smc_sat");
case3_agstc = simulateBuild(P3, betaOsc, "AGSTC");

% for P-ff
Pff3 = P3;
Pff3.eta = P3.etaCtrlNom;
Pff3.etaCtrlNom = P3.etaCtrlNom;
Pff3.areaNoise.enabled = false;

nominal3 = simulateBuild(Pff3, Pff3.betaNom, "prop_feedback");
Qff3.t = nominal3.t;
Qff3.Q = nominal3.Q;

case3_ff      = simulateBuild(P3, betaOsc, "feedforward", Qff3);

case3_const   = simulateBuild(P3, betaOsc, "constant");

plotCase3(P3, case3_smc, case3_agstc, case3_ff, case3_const);

if P.areaNoise.enabled
    fprintf('Area measurement noise: sigma = %.3f um^2, bias = %.3f um^2, useForControl = %d, plotSignal = %s\n', ...
        P.areaNoise.sigma_um2, P.areaNoise.bias_um2, P.areaNoise.useForControl, char(P.areaNoise.plotSignal));
else
    fprintf('Area measurement noise: disabled\n');
end

printChatteringMetrics(P3, 'Case 3', case3_smc, case3_agstc, case3_ff, case3_const);

%% ------------------------------ functions ------------------------------

function plotCase1(P, smc, agstc, ff, const)
    % Initialize figure and a 2x1 tiled layout
    f = figure('Position', [100, 100, 600, 600]);
                          %[left, bottom, width, height]
    t = tiledlayout(2, 1, 'TileSpacing', 'compact', ...
                          'Padding', 'compact');


    
    % ============================
    % Top Tile: Melt Pool Area 
    % ============================
    ax1 = nexttile;

    plot(agstc.t, areaForPlot(P, agstc)*1e6, 'b-',  'LineWidth', 1.25);
    hold on;
    plot(smc.t,     areaForPlot(P, smc)*1e6,     'k-',  'LineWidth', 1.25); 
    plot(ff.t,      areaForPlot(P, ff)*1e6,      'r-',  'LineWidth', 1.1);
    plot(const.t,   areaForPlot(P, const)*1e6,   'r-.', 'LineWidth', 1.1);
    
    title('(a) Melt-pool area response w. $\beta=\hat{\beta}=10$, $\eta=\hat{\eta}=0.4$', ...
          'Interpreter', 'latex');
    yline(P.Ar_um2, 'k--', 'Reference', 'LabelHorizontalAlignment','left');
    
    ylabel('Melt-pool area (\mum^2)');
    xlabel(t, 'Time (s)'); 
    xlim([0 P.tEnd]); 
    ylim([0 15000]); 
    grid on;
    xticks(0:P.tau:P.tEnd);
    xlabel(t, 'Time (s)'); 
    
    % Remove x-tick labels on the top plot to prevent overlapping text
    %xticklabels(ax1, {}); 
    
    legend({'AGSTC', 'Robust SMC', 'Proportional Feedforward','Constant Input','Reference'}, ...
            'Location','southeast');
    
    % ==============================
    % Bottom Tile: Control Power 
    % ==============================
    ax2 = nexttile;
    
    plot(agstc.t, agstc.Q, 'b-',  'LineWidth', 1.25);
    hold on;
    plot(smc.t,     smc.Q,     'k-',  'LineWidth', 1.25); 
    plot(ff.t,      ff.Q,      'r-',  'LineWidth', 1.1);
    plot(const.t,   const.Q,   'r-.', 'LineWidth', 1.1);
    
    title('(b) Control power', 'Interpreter', 'latex')
    ylabel('Control Power, Q(t) (W)');
    xlim([0 P.tEnd]); 
    ylim([0 P.Qsat+20]); 
    grid on;
    xticks(0:P.tau:P.tEnd); 
    yticks(0:100:P.Qsat);
    
    legend({'AGSTC', 'Robust SMC','Proportional Feedforward','Constant Input'}, ...
            'Location','southeast');
    
    % ==========================================
    % Shared Layout Properties & Saving
    % ==========================================
    % Create a single, centered X-label for the whole figure
    xlabel(t, 'Time (s)'); 
    
    % Sync zooming and panning on the X-axis for both plots
    linkaxes([ax1, ax2], 'x'); 
    
end


function plotCase2(P, smc, agstc, ff, const)
    % Initialize figure and a 2x1 tiled layout
    f = figure('Position', [100, 100, 600, 600]);
    %[left, bottom, width, height]
    t = tiledlayout(2, 1, 'TileSpacing', 'compact', ...
        'Padding', 'compact');
    
    
    
    % ============================
    % Top Tile: Melt Pool Area 
    % ============================
    ax1 = nexttile;
    
    plot(agstc.t, areaForPlot(P, agstc)*1e6, 'b-',  'LineWidth', 1.25);
    hold on;
    plot(smc.t,     areaForPlot(P, smc)*1e6,     'k-',  'LineWidth', 1.25); 
    plot(ff.t,      areaForPlot(P, ff)*1e6,      'r-',  'LineWidth', 1.1);
    plot(const.t,   areaForPlot(P, const)*1e6,   'r-.', 'LineWidth', 1.1);
    
    title('(c) Melt-pool area response w. $\beta=\hat{\beta}=10$, $\eta=\hat{\eta}=0.4$', ...
        'Interpreter', 'latex');
    yline(P.Ar_um2, 'k--', 'Reference', 'LabelHorizontalAlignment','left');
    
    ylabel('Melt-pool area (\mum^2)');
    xlabel(t, 'Time (s)'); 
    xlim([0 P.tEnd]); 
    ylim([0 15000]); 
    grid on;
    xticks(0:P.tau:P.tEnd);
    xlabel(t, 'Time (s)'); 
    
    % Remove x-tick labels on the top plot to prevent overlapping text
    %xticklabels(ax1, {}); 
    
    legend({'AGSTC', 'Robust SMC', 'Proportional Feedforward','Constant Input','Reference'}, ...
        'Location','southeast');
    
    % ==============================
    % Bottom Tile: Control Power 
    % ==============================
    ax2 = nexttile;
    
    plot(agstc.t, agstc.Q, 'b-',  'LineWidth', 1.25);
    hold on;
    plot(smc.t,     smc.Q,     'k-',  'LineWidth', 1.25); 
    plot(ff.t,      ff.Q,      'r-',  'LineWidth', 1.1);
    plot(const.t,   const.Q,   'r-.', 'LineWidth', 1.1);
    
    title('(d) Control power', 'Interpreter', 'latex')

    ylabel('Control Power, Q(t) (W)');
    xlim([0 P.tEnd]); 
    ylim([0 P.Qsat+20]); 
    grid on;
    xticks(0:P.tau:P.tEnd); 
    yticks(0:100:P.Qsat);
    
    legend({'AGSTC', 'Robust SMC','Proportional Feedforward','Constant Input'}, ...
        'Location','southeast');
    
    % ==========================================
    % Shared Layout Properties & Saving
    % ==========================================
    % Create a single, centered X-label for the whole figure
    xlabel(t, 'Time (s)'); 
    
    % Sync zooming and panning on the X-axis for both plots
    linkaxes([ax1, ax2], 'x'); 
    
end

function plotCase3(P, smc, agstc, ff, const)

    % Initialize figure and a 2x1 tiled layout
    f = figure('Position', [100, 100, 600, 600]);
    %[left, bottom, width, height]
    t = tiledlayout(2, 1, 'TileSpacing', 'compact', ...
        'Padding', 'compact');
    
    
    
    % ============================
    % Top Tile: Melt Pool Area 
    % ============================
    ax1 = nexttile;
    
    plot(agstc.t, areaForPlot(P, agstc)*1e6, 'b-',  'LineWidth', 1.25);
    hold on;
    plot(smc.t,     areaForPlot(P, smc)*1e6,     'k-',  'LineWidth', 1.25); 
    plot(ff.t,      areaForPlot(P, ff)*1e6,      'r-',  'LineWidth', 1.1);
    plot(const.t,   areaForPlot(P, const)*1e6,   'r-.', 'LineWidth', 1.1);
    
    title('(e) Melt-pool area response w. $\hat{\beta}=10, \beta(t)=10+4\sin(20\pi t)$, $\eta=0.4, \hat{\eta}=0.7$', 'Interpreter', 'latex');
    yline(P.Ar_um2, 'k--', 'Reference', 'LabelHorizontalAlignment','left');
    
    ylabel('Melt-pool area (\mum^2)');
    xlabel(t, 'Time (s)'); 
    xlim([0 P.tEnd]); 
    ylim([0 14000]); 
    yticks(0:2000:14000);
    grid on;
    xticks(0:P.tau:P.tEnd);
    xlabel(t, 'Time (s)'); 
    
    % Remove x-tick labels on the top plot to prevent overlapping text
    %xticklabels(ax1, {}); 
    
    legend({'AGSTC', 'Robust SMC', 'Proportional Feedforward','Constant Input','Reference'}, ...
        'Location','southeast');
    
    % ==============================
    % Bottom Tile: Control Power 
    % ==============================
    ax2 = nexttile;
    
    plot(agstc.t, agstc.Q, 'b-',  'LineWidth', 1.25);
    hold on;
    plot(smc.t,     smc.Q,     'k-',  'LineWidth', 1.25); 
    plot(ff.t,      ff.Q,      'r-',  'LineWidth', 1.1);
    plot(const.t,   const.Q,   'r-.', 'LineWidth', 1.1);

    title('(f) Control power', 'Interpreter', 'latex')
    
    ylabel('Control Power, Q(t) (W)');
    xlim([0 P.tEnd]); 
    ylim([0 320]); 
    grid on;
    xticks(0:P.tau:P.tEnd); 
    yticks(0:100:300);
    
    legend({'AGSTC', 'Robust SMC','Proportional Feedforward','Constant Input'}, ...
        'Location','southwest');
    
    % ==========================================
    % Shared Layout Properties & Saving
    % ==========================================
    % Create a single, centered X-label for the whole figure
    xlabel(t, 'Time (s)'); 
    
    % Sync zooming and panning on the X-axis for both plots
    linkaxes([ax1, ax2], 'x'); 
    
end




function printChatteringMetrics(P, label, smc, agstc, ff, const)
    names = {'Robust SMC','agstc','Proportional FF','Constant'};
    sims = {smc, agstc, ff, const};
    idx0 = min(numel(smc.t)-1, round(P.tau/P.dt) + 1);

    fprintf('\n%s\n', label);
    fprintf('  %-18s %16s %17s %14s %14s\n', ...
        'controller', 'RMSE_A_true(um2)', 'RMSE_A_noisy(um2)', 'TVQ(W)', 'max|dQ|(W)');
    for kk = 1:numel(sims)
        S = sims{kk};
        qdiff = diff(S.Q(idx0:end));

        eAreaTrue = (S.A(idx0:end) - P.Ar)*1e6;
        rmseAreaTrue = sqrt(mean(eAreaTrue.^2));

        if isfield(S, 'A_noisy')
            eAreaNoisy = (S.A_noisy(idx0:end) - P.Ar)*1e6;
            rmseAreaNoisy = sqrt(mean(eAreaNoisy.^2));
        else
            rmseAreaNoisy = NaN;
        end

        tvq = sum(abs(qdiff));
        maxJump = max(abs(qdiff));
        fprintf('  %-18s %16.3f %17.3f %14.3f %14.3f\n', ...
            names{kk}, rmseAreaTrue, rmseAreaNoisy, tvq, maxJump);
    end
end

