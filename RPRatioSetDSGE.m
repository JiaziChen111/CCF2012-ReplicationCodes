% SetDSGE
%
% This file sets the DSGE environment
%
% Mandatory structure:
%
% 1) Set file names for the data input and the output
%      FileName.Output (string)
%      FileName.Data (string)    
%
% 2) Set parameters list and priors: Params
%    lists all parameters in a vertical array, with 4 or 5 elements per column:
%      1st: (string) name of parameter
%      2nd: (string) name of distribution
%           Valid names: 'N','B','G','IG1','IG2'
%      3rd: (double) mean of prior
%      4th: (double) SE of freedom of prior. If prior dist is igam then
%           either specify the se or set it to inf, in which case the
%           codes will assume degrees of freedom equal to 2 and extract
%           the other parameter from the mean.
%      5th: (string, optional) Pretty representation of variable name, to
%           be used in plot titles and tables. If included, it needs to be
%           included in all. If ommited, the original names are used.
%
% 3) Set list of observation variables: Obs
%    This must be a cell array of strings.
%
% 4) Set list of State space variables: States
%    This must be a cell array of strings.
%
% 5) Set list of iid shocks: Shocks
%    This must be a cell array of strings.
%    NOTE: Shocks need to be iid and with unit variance.
%
% 6) Generate symbolic variables: GenSymVars
%    Script to automate all required transformations.
%    NOTE: this must be called prior to specify any auxiliary calculations
%          or the equations in the model.
%    NOTE: in the equations below if constants show up then they should be
%          multiplied by 'one', which is defined as a symbolic variable to 
%          be used later to identify those constants.
%    Convention: x_t refers to x(t)
%                x_tF refers to x(t+1)
%                x_tL refers to x(t-1)
%                x_ss refers to steady state of x(t)
%
% 7) Construct any necessary auxiliary definitions [OPTIONAL]
%    In this section introduce any calibrated parameters and/or parameter
%    transformations to be called on the equations.
%    NOTE: This section should be called after generating symbolic
%          variables and before setting the equations.
%
% 8) Set observation equations: ObsEq
%    Symbolic column array.
%    NOTE: Cannot contain any lags or leads. If needed augment state space
%          representation.
%
% 9) Set state Equations: StateEq
%    Symbolic column array.
%    Each state equation equations can contain lags and leads, but not both 
%    simultaneous in the same equation. If leads and lags in the same 
%    equation, then create artificial variables for the lagged variables.
%
% The above 9 steps will set up the model. At this point either list the
% other scripts to estimate and manipulate the DSGE or simply call them
% separately. Refer to section "See also" for a list of all scripts and
% functions that can be called.
% 
% Optional Settings:
%
%   UseParallel (logical)
%   If set to true, it uses parallel computing in several stages of the
%   estimation, most remarkably on the posterior maximization and on the
%   MCMC part.
%
%   ListPathDependencies (cell)
%   List of path directories to be used in the parallel computing.
%
%   DataVarName
%   Name of the variable in the datafile. Needs to be specified if 
%   datafile contains multiple variables. Otherwise it does not have to 
%   be specified.
%   
% See also:
% SetDSGE, GenSymVars, DataAnalysis, PriorAnalysis, GenPost, MaxPost, 
% MakeTableMaxPost, MCMC, MCMCSearchScaleFactor, MakePlotsMCMCConv, 
% MCMCInference, MakeTableMCMCInference, MakePlotsMCMCTrace, 
% MakePlotsMCMCPriorPost, MCMCConv, MakeTableMCMCConv, MCMCVD
%
% ..............................................................................
%
% Created: July 7, 2011 by Vasco Curdia
% Updated: April 14, 2014 by Vasco Curdia
%
% Copyright 2011-2014 by Vasco Curdia

%% -----------------------------------------------------------------------------

%% Preamble
clear all
tic
ttic = toc();

%% Settings
FileName.Output = 'RPRatio';

%% Parallel options
UseParallel = 1;
nMaxWorkers = 4;
if UseParallel,matlabpool('open',nMaxWorkers),end

%% Allow for running only some of the blocks of actions
% Possible Actions:
%   Actions = {'All'};
%   Actions = {'Setup','MaxPost','MCMC'};
Actions = {'All'};

%% -----------------------------------------------------------------------------

%% Load framework if already set
if ~any(ismember({'All','Setup'},Actions))
    save NewSettings ttic Actions UseParallel nMaxWorkers
    load(FileName.Output)
    load NewSettings
    delete NewSettings.mat
else
    
%% Setup

%% Data
FileName.Data = 'Data_1975q1_2009q3_BLMVB';
DateLabels.Start = '1987q3';
DateLabels.End = '2009q3';
DateLabels.TrainSampleStart = '1975q1';
DateLabels.XTickLabels = {'1990q1','1995q1','2000q1','2005q1'};
TimeIdx =  TimeIdxCreate(DateLabels.Start,DateLabels.End);
DateLabels.XTick = find(ismember(TimeIdx,DateLabels.XTickLabels));
nPreSample = find(ismember(TimeIdxCreate(DateLabels.TrainSampleStart,DateLabels.End),DateLabels.Start))-1;


%% Estimated parameters
Params = {...
    % Model parameters
    'gammaa', 'G', 2.5, 0.5,'400\gamma';
    'pia', 'G', 2, 0.5,'400\pi';
    'DiscF', 'G', 1, 0.25,'400(\beta_u^{-1}-1)';
    'zetaa', 'G', 0.75, 0.25,'400\zeta';
    'BLMVB', 'G', 1, 0.2,'B^{LMV}/B';
    'd2S', 'G', 4, 1,'S^{\prime\prime}';
    'd2a', 'G', 0.2, 0.1,'a^{\prime\prime}';
    'h', 'B', 0.6, 0.1,'h';
    'sigmau', 'G', 2, 1,'\sigma_u';
    'sigmar', 'G', 2, 1,'\sigma_r';
    'dzetap', 'G', 1.5, 1, '100\zeta^\prime';
    'omegau', 'B', 0.7, 0.2, '\omega_u';
    'Xiur', 'G', 1, 0.5, '\Xi^u/\Xi^r';
    'Cur', 'G', 1, 0.5, 'C^u/C^r';
    'chiwu', 'B', 0.6, 0.2, '\chi_{wu}';
    'nu', 'G', 2, 0.5,'\nu';
    'zetaw', 'B', 0.5, 0.1,'\zeta_w';
    'zetap', 'B', 0.5, 0.1,'\zeta_p';
    'phiT', 'G', 1.5, 0.5, '\phi_T';
    'rhor', 'B', 0.7, 0.1,'\rho_r';
    'phipi', 'G', 1.75, 0.5,'\phi_\pi';
    'phiy', 'G', 0.4, 0.2,'\phi_y';
    % Statistical Parameters
    'rhoz','B',0.4,0.2,'\rho_z';
    'rhomu', 'B', 0.75, 0.1,'\rho_\mu';
    'rhob', 'B', 0.75, 0.1,'\rho_b';
    'rhophi', 'B', 0.75, 0.1,'\rho_\phi';
    'rhoB', 'B', 0.8, 0.1,'\rho_B';
    'rhozeta', 'B', 0.8, 0.1,'\rho_\zeta';
    'rhog', 'B', 0.75, 0.1,'\rho_g';
    'sigmaz','IG1',0.5,2,'\sigma_z';
    'sigmalambdaf', 'IG1', 0.5, 2,'\sigma_{\lambda_f}';
    'sigmamu', 'IG1', 0.5, 2,'\sigma_\mu';
    'sigmab', 'IG1', 0.5, 2,'\sigma_b';
    'sigmaphi', 'IG1', 0.5, 2,'\sigma_\phi';
    'sigmaB', 'IG1', 0.5, 2,'\sigma_B';
    'sigmaT', 'IG1', 0.5, 2,'\sigma_T';
    'sigmam', 'IG1', 0.25, 2,'\sigma_m';
    'sigmazeta', 'IG1', 0.25, 2,'\sigma_\zeta';
    'sigmag', 'IG1', 0.5, 2,'\sigma_g';
    };
    
%% Observation variables
ObsVar = {'Obsdy';'ObsL';'Obsdw';'Obspi';'Obsr';'ObsrL';'ObsBLMVB'};

%% State space variables
StateVar = {...
    % Endogenous Variables
    'pi';'wz';'u';'Kzbar';'L';'Yz';'Iz';'q';'r';'rL';'zeta';'dY';'dY4';
    'Czu';'Czr';'Bz';'BLz';'Tz';'dw';'BLMVz';'BTotMVz';
    'Xiu';'Xir';'Xpnu';'Xpnr';'Xpdu';'Xpdr';'Xwnu';'Xwnr';'Xwdu';'Xwdr';
    % Exogenous Variables
    'z';'lambdaf';'mu';'phi';'b';'XiB';'XiT';'Xim';'Xizeta';'g';
    % Artificial Variables
    'IzL';'CzuL';'CzrL';'dYL1';'dYL2';
    };
    
%% Shocks
ShockVar = {'ez';'elambdaf';'emu';'ephi';'eb';'eBL';'eT';'em';'ezeta';'eg'};

%% create symbolic variables
GenSymVars

%% Auxiliary definitions, steady state and fixed parameters

% Calibrated parameters
alpha = 0.33;
lambdaf = 0.15;
lambdaw = 0.15;
rholambdaf = 0;
delta = 0.025;
Gz_ss = 0.2;

% transformed parameters
gamma = gammaa/400;
pi_ss = pia/400;
zeta_ss = zetaa/400;
betau = 1/(DiscF/400+1);
BondDuration = 30; %8*4;
dzeta = dzetap/100;

% steady state values and ratios
Pi_ss = 1+pi_ss;
R_ss = 1/betau*exp(gamma)*Pi_ss;
RL_ss = R_ss*(1+zeta_ss);
kappa = RL_ss*(1-1/BondDuration);
kappaEH = R_ss*(1-1/BondDuration);
BLB = (RL_ss-kappa)*BLMVB;
Bz_ss = 0.25*4/(1+BLB); % 0.25 of annual GDP...
BLMVz_ss = BLMVB*Bz_ss;
BLz_ss = BLB*Bz_ss;
betar = betau/(1+zeta_ss);
wztilde = (1+lambdaf)^(-1/(1-alpha))*alpha^(alpha/(1-alpha))*(1-alpha);
Kztilde = alpha/(1+lambdaf);
Ltilde = ((1+lambdaf)/alpha)^(alpha/(1-alpha));
betabar = (omegau*betau*Xiur+(1-omegau)*betar)/(omegau*Xiur+(1-omegau));
rk_ss = 1/betabar*exp(gamma)-(1-delta);
wz_ss = wztilde*rk_ss^(-alpha/(1-alpha));
Kz_ss = Kztilde/rk_ss;
Kzbar_ss = exp(gamma)*Kz_ss;
L_ss = Ltilde*rk_ss^(alpha/(1-alpha));
Iz_ss = (exp(gamma)-(1-delta))*Kz_ss;
Cz_ss = 1-Iz_ss-Gz_ss;
Czr_ss = Cz_ss/(omegau*Cur+1-omegau);
Czu_ss = Cur*Czr_ss;
chipu = omegau/(omegau+(1-omegau)*(1-betau*zetap)/(1-betar*zetap)/Xiur);
qu = (betabar/betar-1)/zeta_ss;
Tz_ss = Gz_ss-(1-1/betau+(1-1/betar)/(RL_ss-kappa)*BLB)*Bz_ss;

% return on capital
rk_t = d2a/rk_ss*u_t;
rk_tF = d2a/rk_ss*u_tF;
rk_tL = d2a/rk_ss*u_tL;

% marginal cost
mc_t = alpha*rk_t+(1-alpha)*wz_t;
mc_tF = alpha*rk_tF+(1-alpha)*wz_tF;
mc_tL = alpha*rk_tL+(1-alpha)*wz_tL;

% effective capital
Kz_t = u_t+Kzbar_tL-z_t;
Kz_tF = u_tF+Kzbar_t-z_tF;

%% Observational Equations
ObsEq = [...
    100*(gamma*one+dY_t)-Obsdy_t;
    100*L_t-ObsL_t;
    100*(gamma*one+dw_t)-Obsdw_t;
    100*(log(Pi_ss)*one+pi_t)-Obspi_t;
    100*(log(R_ss)*one+r_t)-Obsr_t;
    100*(log(RL_ss)*one+rL_t)-ObsrL_t;
    BLMVB*(one+BLMVz_t-Bz_t)-ObsBLMVB_t;
    ];

%% State Equations
StateEq = [...
    % Intermediate Goods Producers
    wz_t-rk_t+L_t-Kz_t;
    alpha*Kz_t+(1-alpha)*L_t-Yz_t;
    % price setting
    (1-betau*zetap)*(Xiu_t+Yz_t+lambdaf_t+mc_t)+...
        betau*zetap*((1+lambdaf)/lambdaf*pi_tF+Xpnu_tF)-Xpnu_t;
    (1-betar*zetap)*(Xir_t+Yz_t+lambdaf_t+mc_t)+...
        betar*zetap*((1+lambdaf)/lambdaf*pi_tF+Xpnr_tF)-Xpnr_t;
    (1-betau*zetap)*(Xiu_t+Yz_t)+betau*zetap*(1/lambdaf*pi_tF+Xpdu_tF)-Xpdu_t;
    (1-betar*zetap)*(Xir_t+Yz_t)+betar*zetap*(1/lambdaf*pi_tF+Xpdr_tF)-Xpdr_t;
    (1-zetap)/zetap*(chipu*(Xpnu_t-Xpdu_t)+(1-chipu)*(Xpnr_t-Xpdr_t))-pi_t;
    % Capital Producers
    (1-delta)*exp(-gamma)*(Kzbar_tL-z_t)+...
        (1-(1-delta)*exp(-gamma))*(mu_t+Iz_t)-Kzbar_t;
    betabar*exp(-gamma)*(rk_ss*rk_tF+(1-delta)*q_tF)-z_tF+...
        qu*((1+zeta_ss)/(1+qu*zeta_ss)*Xiu_tF-Xiu_t)+...
        (1-qu)*(1/(1+qu*zeta_ss)*Xir_tF-Xir_t)-q_t;
    q_t+mu_t-exp(2*gamma)*d2S*(z_t+Iz_t-IzL_t)+...
        betabar*exp(2*gamma)*d2S*(z_tF+Iz_tF-Iz_t);
    Iz_tL-IzL_t;
    % Households
    1/(1-betau*h)*(b_t-sigmau/(1-h)*(Czu_t-h*CzuL_t))-...
        betau*h/(1-betau*h)*(b_tF-sigmau/(1-h)*(Czu_tF-h*Czu_t))-Xiu_t;
    Czu_tL-CzuL_t;
    1/(1-betar*h)*(b_t-sigmar/(1-h)*(Czr_t-h*CzrL_t))-...
        betar*h/(1-betar*h)*(b_tF-sigmar/(1-h)*(Czr_tF-h*Czr_t))-Xir_t;
    Czr_tL-CzrL_t;
    r_t+Xiu_tF-z_tF-pi_tF-Xiu_t;
    RL_ss/(RL_ss-kappa)*rL_t+Xiu_tF-z_tF-pi_tF-kappa/(RL_ss-kappa)*rL_tF-...
        zeta_t-Xiu_t;
    RL_ss/(RL_ss-kappa)*rL_t+Xir_tF-z_tF-pi_tF-kappa/(RL_ss-kappa)*rL_tF-Xir_t;
    % Wage Setting
    (1-zetaw*betau)*(b_t+phi_t+(1+nu)*L_t+(1+lambdaw)/lambdaw*(1+nu)*wz_t)+...
        zetaw*betau*((1+lambdaw)/lambdaw*(1+nu)*(pi_tF+z_tF)+Xwnu_tF)-Xwnu_t;
    (1-zetaw*betar)*(b_t+phi_t+(1+nu)*L_t+(1+lambdaw)/lambdaw*(1+nu)*wz_t)+...
        zetaw*betar*((1+lambdaw)/lambdaw*(1+nu)*(pi_tF+z_tF)+Xwnr_tF)-Xwnr_t;
    (1-zetaw*betau)*(Xiu_t+L_t+(1+lambdaw)/lambdaw*wz_t)+...
        zetaw*betau*(1/lambdaw*(pi_tF+z_tF)+Xwdu_tF)-Xwdu_t;
    (1-zetaw*betar)*(Xir_t+L_t+(1+lambdaw)/lambdaw*wz_t)+...
        zetaw*betar*(1/lambdaw*(pi_tF+z_tF)+Xwdr_tF)-Xwdr_t;
    (1-zetaw)/(1+(1+lambdaw)/lambdaw*nu)*(chiwu*(Xwnu_t-Xwdu_t)+...
        (1-chiwu)*(Xwnr_t-Xwdr_t))+zetaw*(wz_tL-pi_t-z_t)-wz_t;
    wz_t-wz_tL+z_t-dw_t;
    % Government debt
    1/betau*(Bz_tL+r_tL)+BLB/(RL_ss-kappa)/betar*BLz_tL+...
        (1-exp(-gamma)/Pi_ss*kappa)*RL_ss/(RL_ss-kappa)^2*BLB*rL_t+...
        Gz_ss/Bz_ss*g_t-1/Bz_ss*Tz_t-...
        (1/betau+BLB/(RL_ss-kappa)/betar)*(z_t+pi_t)-...
        Bz_t-BLB/(RL_ss-kappa)*BLz_t;
    Bz_t+BLB/(RL_ss-kappa)*BLz_t-BLB*RL_ss/(RL_ss-kappa)^2*rL_t-...
        (1+BLB/(RL_ss-kappa))*BTotMVz_t;
    BLB/(RL_ss-kappa)*BLz_t-BLB*RL_ss/(RL_ss-kappa)^2*rL_t-...
        BLB/(RL_ss-kappa)*BLMVz_t;
    % Term premium and resources constraint
    dzeta/2*(BLMVz_t-Bz_t)+Xizeta_t-zeta_t;
    % Aggregate resources constraint
    omegau*Czu_ss*Czu_t+(1-omegau)*Czr_ss*Czr_t+Iz_ss*Iz_t+Gz_ss*g_t+...
        exp(-gamma)*rk_ss*Kzbar_ss*u_t-Yz_t;
    % Exogenous Processes
    rhoz*z_tL+sigmaz/100*ez_t-z_t;
    rholambdaf*lambdaf_tL+sigmalambdaf*10/100*elambdaf_t-lambdaf_t;
    rhomu*mu_tL+sigmamu/100*emu_t-mu_t;
    rhophi*phi_tL+sigmaphi*100/100*ephi_t-phi_t;
    rhob*b_tL+sigmab/100*eb_t-b_t;
    sigmaB*10/100*eBL_t-XiB_t;
    sigmaT*10/100*eT_t-XiT_t;
    sigmam/100*em_t-Xim_t;
    rhog*g_tL+sigmag/100*eg_t-g_t;
    % Artificial variables needed
    Yz_t-Yz_tL+z_t-dY_t;
    dY_tL-dYL1_t;
    dYL1_tL-dYL2_t;
    dY_t+dYL1_t+dYL2_t+dYL2_tL-dY4_t;
    % LOM of zeta
    rhozeta*Xizeta_tL+sigmazeta/100*ezeta_t-Xizeta_t;
    % Long term debt policy
    rhoB*BLMVz_tL+XiB_t-BLMVz_t;
    % Fiscal policy rule
    phiT*BLMVz_tL+XiT_t-1/(Tz_ss-Gz_ss)*(Tz_t-Gz_ss*g_t);
    % Monetary policy
    rhor*r_tL+(1-rhor)*(phipi*pi_t+phiy*dY4_t)+Xim_t-r_t;
    ];

%% Data
DataAnalysis

%% Priors
PriorAnalysis

%% Generate posterior function
KFinit.sig = eye(nStateVar);
MakeMats
GenPost

%% end Setup Action if
TimeElapsed.Setup = toc();
fprintf('\n%s\n\n',vctoc([],TimeElapsed.Setup))
save(FileName.Output)
end

%% -----------------------------------------------------------------------------

%% MaxPost
if any(ismember({'All','MaxPost'},Actions))
    nMax = 20;
    MinParams.H0 = diag([Params(:).priorse].^2);
    MinParams.crit = 1e-8;
    MinParams.nit = 1000;
    MinParams.Ritmax = 30;
    MinParams.Ritmin = 10;
    MinParams.RH0 = 1;
    MinParams.Rscaledown = 0.5;
    MaxPost
    save(FileName.Output)
    save([FileName.Output,'MaxPost'])
end

%% MCMC
if any(ismember({'All','MCMC'},Actions))
    nChains = 4;
    nDrawsSearch = 2000;
    dscale = [0.2,0.05,0.01,0.001];
    BurnIn = 0.25;
    nThinning = 1;
%     nDraws = 100000;
    for nUpdate=0:2
        fprintf('\n*****************')
        fprintf('\n* MCMC Update %.0f *',nUpdate)
        fprintf('\n*****************')
        if nUpdate==0
            nDraws = 100000;
        elseif nUpdate==1
            nDraws = 200000;
        elseif nUpdate==2
            nDraws = 200000;
        end
        MCMCOptions.ScaleJumpFactor = 2.4;
        MCMCSearchScaleFactor
        save(sprintf('%sMCMCUpdate%.0f_SSF',FileName.Output,nUpdate))
        MCMC
        save(sprintf('%sMCMCUpdate%.0f',FileName.Output,nUpdate))
        delete(sprintf('%sMCMCUpdate%.0f_SSF.mat',FileName.Output,nUpdate))
        MCMCAnalysis
        MakeMCMCDrawsRedux
        save(FileName.Output)
        save(sprintf('%sMCMCUpdate%.0f',FileName.Output,nUpdate))
    end
end

%% -----------------------------------------------------------------------------

%% Close matlabpool
if UseParallel,matlabpool close,end

%% elapsed time
fprintf('\n%s\n\n',vctoc(ttic))

%% Save environment
save(FileName.Output)

%% -----------------------------------------------------------------------------
