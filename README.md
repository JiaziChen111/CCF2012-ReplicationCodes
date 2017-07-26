# CCF-LSAP-MacroEffects

[![License](https://img.shields.io/badge/license-BSD%203--clause-green.svg)](LICENSE)

These codes reproduce the results in:  
**Chen, H., Cúrdia, V., and Ferrero, A. (2012)**
[The Macroeconomic Effects of Large-Scale Asset Purchase Programs](http://onlinelibrary.wiley.com/doi/10.1111/j.1468-0297.2012.02549.x/abstract) 
*The Economic Journal*, 122, pp. 289-315.


# Requirements

## Matlab (R)
The codes were tested using Matlab (R) R1012a with the following toolboxes
- Symbolic Toolbox
- Statistical Toolbox
- Optimization Toolbox

## LaTeX
LaTeX is used by some tools to compile certain documents.

`epstopdf`, included in most LaTeX releases, is used by some tools.

## Additional Matlab (R) codes needed in Matlab (R) path
- [VC-Tools v1.5.0](https://github.com/vcurdia/VC-Tools/releases/tag/v1.5.0)
  by [Vasco Cúrdia](http://www.frbsf.org/economic-research/economists/vasco-curdia/)
- [VC-BayesianEstimation v1.5.0](https://github.com/vcurdia/VC-BayesianEstimation/releases/tag/v1.5.0)
  by [Vasco Cúrdia](http://www.frbsf.org/economic-research/economists/vasco-curdia/)
- [gensys](http://sims.princeton.edu/yftp/gensys/)
  by [Chris Sims](http://www.princeton.edu/~sims/)
- [optimize](http://dge.repec.org/codes/sims/optimize/)
  by [Chris Sims](http://www.princeton.edu/~sims/)
- [KF](http://sims.princeton.edu/yftp/Times09/KFmatlab/)
  by [Chris Sims](http://www.princeton.edu/~sims/)


# Description of Replication Codes

## Estimation

- RPRatioSetDSGE.m
  Sets up the model for estimation and runs all the steps for estimation
  generating appropriate logs, estimation reports and diagnostics in
  a fully automated mode.

- Data_1975q1_2009q3_BLMVB.mat
  Contains the data, ready to be used in Matlab.

Notice that it may take a long time to run with the current settings  without 
using a parallel computing cluster given that it will take the following steps:

    a. Run 20 posterior numerical mode searches starting at different guess 
       vectors. For each of those it will restart the search up to 30 more 
       times to confirm that it is not a local mode.

    b. Will run three stages of Markov-Chain-Monte-Carlo each for four semarate 
       chains. 
       b.1. First stage uses the negative of the inverse hessian at the 
            posterior peak to form the covariance matrix for MCMC draws, scaled 
            to have a rejection rate between 70 and 80 percent (numerical 
            search). It generates 100,000 draws using a Metropolis algorithm.
       b.2. After the previous stage, the code discards the first quarter of the
            draws for each chain, combines the remain from each chain and 
            computes the covariance matrix, which is then used as the new 
            covariance for the next stage of MCMC. It is again numerically 
	    rescaled to yield a rejection rate between 70 and 80 percent. It 
	    generates 200,000 draws.
       b.3. We repeat step b.2. one more time.

       In each of these stages a full report with diagnostics and some 
       inference is generated. It also produces a reduced set of draws (1000 by
       default) needed to make the simulations for the paper. The last stage one
       is included with the codes:
           RPRatioMCMCDrawsUpdate2Redux.mat

Table 2 in the paper is a slight modification of the first table in the report 
for the last estimation stage.


## Model simulations

- BLMVBSimSetup.m
  Sets up the model for simulations, with some additional variables that were 
  not needed for estimation but are needed for the simulations.

- ModelSimRun.m
  Main script to generate all simulations with the model. 
  It requires BLMVBSimSetup.m to be run first.
  It requires the following files:
    * ModelSimRunFcn.m
      Subfunction to use inside a loop to generate simulations for each draw.
    * RPRatio.mat
      Contains the estimation results (but not the MCMC Draws).
    * RPRatioMCMCDrawsUpdate2Redux.mat
      Contains a reduced sample from the MCMC Draws.
  Offers many options and switches to tweak simulations and plots. 
  To make replication of results simpler below are listed five scripts that are
  similar to ModelSimRun.m but with options and switches set to generate excatly
  the figures in the paper. They need to be run in this order to avoid any 
  missing files:
    * MakeFig1.m
    * MakeFig2.m
    * MakeFig3.m
    * MakeFig4.m
    * MakeFig5.m
  The corresponding figures in pdf format are saved in subdirectories.

