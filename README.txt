// +-------------------------------------------------------------------------+
// |     Micro Market Simulation (GTES)                                      |
// |     readme                                                              |
// |     Copyright (C) Yves Caseau, 2012                                     |
// +-------------------------------------------------------------------------+

VERSION : V0.2

1. Project Description 
======================

This is a super simplified version of CGS that has nothing to do with telephony
and may be shown in a book (bk16) or in a talk

Each actor is a company with
  - a customer base
  - an ARPU
  - a structural churn
  - an attractiveness ( both a premium / generosity) measured as a delta-price
  - fixed costs + variables costs
  - a migration fluidity 

The system schema is simple
  - churn is computed as structural * price factor
  - Pdm is computed as a function of (price + premium) 

Tactic is simply a price vector (arpu = price - no migration involved)
Strategy is a combination of market share (LT) and revenue (ST)


we implement a full GTES similar to CGS and produce trajectories and 
strategy matrices



2. Version Description:  (V0.1)
======================

This is the first version, the goal is to be done in a month, to produce two slides
for CSDM

v0.2:
- restart the experiment in 2014, to produce a test case about Free, and to produce new slides for Compiegne


3. Installation:
===============

this is a standard module, look at init.cl in wk.

	
4. Claire files
===============

log.cl:            as usual, the log file => where to look firt to read about the current state
model.cl           data model: companies, experiments & scenarios, initialization + utilities
simul.cl           simulation of the 36 months = loop + tactic automatas + learning
	
5. Related doc
==============
overall description may be found at http://organisationarchitecture.blogspot.com/

6. Data
=======

This project uses scenario files (look at oai to use a similar approach)


7.Test and run
==============

As usual, the test file is test*.cl (currently test1.cl)
The test file contains the configuration
  - description of the companies
  - definition of the experiments
  - go* methods which simply run go(E)

