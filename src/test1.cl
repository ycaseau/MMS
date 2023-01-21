// ********************************************************************
// *       MMS : Micro Market Simulation                              *
// *       copyright (C) 2012 Yves Caseau                             *
// *       file: test1.cl                                              *
// ********************************************************************

// This is a crude abstraction of the battle of teh four mobile players in 2012 - 2014

(printf("=== TEST1 file ...  2012 data ===\n"))


// Step 1: describe the companies  ------------------------------------

XX:any := unknown

// Bytel is managing to get a decent market share with a high arpu (generosity premium because network is
// less full)
Bytel :: Company( expenses = list<float>(1500.0,1500.0,1400.0,1300.0), expenseTrend = -0.03,
                  churn% = 0.20, fluidity = 0.5, premium = 3.0)
(init(Bytel,2011,Status(base = 11.3,  sales = 5700.0, ebitda = 1200.0)),
 XX := Strategy(ebitda = 1200.0, share = 0.18, base = 11.0),
 Bytel.reference := Strategy(ebitda = 1200.0, share = 0.18, base = 11.0))


// Orange is the reference operator (premium = 0)
Orange :: Company(expenses = list<float>(3000.0,3000.0,3000.0,3000.0), expenseTrend = -0.03,
                  churn% = 0.15, fluidity = 0.3)
(init(Orange,2011,Status(base = 27.0, sales = 10800.0, ebitda = 3920.0)),
 Orange.reference := Strategy(ebitda = 3900.0, share = 0.33, base = 27.0))


// SFR - (IT & network operations are more expensive)
SFR :: Company(expenses = list<float>(2000.0,1900.0,1700.0,1600.0), expenseTrend = -0.05,
               churn% = 0.20, fluidity = 0.4, premium = -2.0)
(init(SFR,2011,Status( base = 21.0, sales = 8400.0 , ebitda = 3520.0)),
 SFR.reference := Strategy(ebitda = 3500.0, share = 0.28, base = 21.0))

// in this model we add MVNO
// average of Virgin and Lebara :)
MVNO :: Company(expenses = list<float>(300.0,300.0,300.0,300.0), expenseTrend = -0.05,
                churn% = 0.25, fluidity = 0.6, premium = -30.0)
(init(MVNO,2011,Status( base = 7.0, sales = 1000.0, ebitda = 100.0)),
 MVNO.reference := Strategy(ebitda = 100.0, share = 0.1, base = 7.0))

// Free starts in 2012 (hence the init status is different)
// the premium reflect the absence of distribution network  (iso prix SFR => 10%)
// attention : the tuning of premium(Free) - done with E0c is sensitive to alpha
Free :: Company(expenses = list<float>(0.0,300.0,400.0,450.0),
                churn% = 0.20, fluidity = 0.6, premium = -10.0,
                variable = 150.0)                 // 15�/mois
(init(Free,2011,Status( base = 0.0, price = 280.0)),             // 15�/mo ABPU + 8� incoming calls
 Free.reference := Strategy(ebitda = 800.0, share = 0.18, base = 10.0))

// These tactics are used for the clean test = no change => no change :)
T0b :: makeTactic(0.9,0.85,0.8)
T0o :: makeTactic(0.9,0.88,0.85)   // 0.9 -> 0.2
T0s :: makeTactic(0.95,0.85,0.8)
T0f :: makeTactic(1.0,1.0,1.0)
T0m :: makeTactic(0.95,0.9,0.85)

T0 :: makeTactic(1.0,1.0,1.0)

T1f :: makeTactic(4.0,4.0,4.0)           // debug & test vector : very high => check that other premium are balanced
T2f :: makeTactic(1.5,1.5,1.5)           // debug & test vector : same as other => adjust premium for MS

// step 2: describe starting global situation ------------------------------

NITER :: 10
NTEST :: 50
Sc1 :: Scenario(nIter = NITER, nTest = NTEST,
                // cost structures
                costs = {},                       // default
                // MonteCarlo Tuning
                alphaMin = 3.5, alphaMax = 3.5,
                betaMin = 1.0, betaMax = 1.5)

// variants to see the effect of alpha
Sc1a+ :: Scenario(nIter = NITER, nTest = NTEST, costs = {},                       // default
                  alphaMin = 2.5, alphaMax = 3.0,
                  betaMin = 1.0, betaMax = 1.5)

Sc1a- :: Scenario(nIter = NITER, nTest = NTEST, costs = {},                       // default
                  alphaMin = 2.0, alphaMax = 2.5,
                  betaMin = 1.0, betaMax = 1.5)

// variants to see the effect of beta
Sc1b- :: Scenario(nIter = NITER, nTest = NTEST, costs = {},                       // default
                  alphaMin = 2.0, alphaMax = 3.0,
                  betaMin = 1.0, betaMax = 1.2)

Sc1b+ :: Scenario(nIter = NITER, nTest = NTEST, costs = {},                       // default
                  alphaMin = 2.0, alphaMax = 3.0,
                  betaMin = 1.2, betaMax = 1.5)


// Scenario 2: Free has to build a network - 2M� sur 5 ans ->
Sc2 :: Scenario(nIter = NITER, nTest = NTEST,
                // cost structures
                costs = {tuple(Free,list<float>(0.0,350.0,800.0,850.0,900.0))},
                // MonteCarlo Tuning
                alphaMin = 2.0, alphaMax = 3.0,
                betaMin = 1.0, betaMax = 1.5)


// Scenario 3: Bouygues Telecom sets its variable costs similar to ORG & SFR, then works out
// a strong reduction plan
Sc3 :: Scenario(nIter = NITER, nTest = NTEST,
                // cost structures
                costs = {tuple(Bytel,list<float>(2100.0,1900.0,1800.0,1700.0))},
                // MonteCarlo Tuning
                alphaMin = 2.0, alphaMax = 2.0,
                betaMin = 1.0, betaMax = 1.5)


// Manual tuning - beta -> total market, alpha -> market share
(pb.alpha := 3.5, pb.beta := 1.2)

// Sc0 is a scenario that sets alpha and beta to a precise value
Sc0 :: Scenario(nIter = NITER, nTest = 1,
                // cost structures
                costs = {},                       // default
                // MonteCarlo Tuning
                alphaMin = 2.0, alphaMax = 2.0,
                betaMin = 1.2, betaMax = 1.2)

// alpha � 2.0 -> Free a 5.4 (go),  2.5 -> 5, 3.0 -> 6.5
// beta � 1.0 -> bytel churn � 25%, 1.8 -> 35%

// step 3: describe strategy ----------------------------------------------

// we only use reasonably aggressive strategies
// first : not agressive - allows some loss because of Free
// second : totally soft -> defend base
// third : agressive

/// each player has its stragegy, ... and variants
// Bytel
SB :: Strategy( ebitda = 900.0, share = 0.17, base = 11.0, minRatio = f%(15))
SB2 :: Strategy( ebitda = 700.0, share = 0.15, base = 10.0, minRatio = f%(10))
SB3 :: Strategy( ebitda = 1100.0, share = 0.20, base = 12.0, minRatio = f%(15))

// Orange
SO :: Strategy( ebitda = 3500.0, share = 0.30, base = 27.0, minRatio = f%(30))
SO2 :: Strategy( ebitda = 3000.0, share = 0.20, base = 25.0, minRatio = f%(20))
SO3 :: Strategy( ebitda = 3700.0, share = 0.27, base = 28.0, minRatio = f%(30))

// SFR
SR :: Strategy( ebitda = 3000.0, share = 0.27, base = 21.0, minRatio = f%(25))
SR2 :: Strategy( ebitda = 2500.0, share = 0.18, base = 19.0, minRatio = f%(20))
SR3 :: Strategy( ebitda = 3200.0, share = 0.22, base = 22.0, minRatio = f%(30))

// MVNOS
SM :: Strategy( ebitda = 100.0, share = f%(10), base = 6.0, minRatio = f%(10))
SM2 :: Strategy( ebitda = 10.0, share = f%(15), base = 5.0, minRatio = f%(10))
SM3 :: Strategy( ebitda = 10.0, share = f%(15), base = 6.0, minRatio = f%(10))

// perceived Free strategy  (S4b is more aggressive)
// minRatio = 0% is a marker for linear growth
SF :: Strategy( ebitda = 500.0, share = f%(20),  base = 12.0, minRatio = f%(0))
SF2 :: Strategy( ebitda = 500.0, share = f%(15), base = 10.0, minRatio = f%(0))
SF3 :: Strategy( ebitda = 500.0, share = f%(30), base = 15.0, minRatio = f%(0))


// special for illustration : no reaction
// attention : cannot do whatif with the sameT0 !
E0 :: Experiment(scenario = Sc1,
                 strategies = {tuple(Bytel,SB),tuple(SFR,SR),tuple(Orange,SO),tuple(Free,SF), tuple(MVNO,SM)},
                 sTactics = {tuple(Bytel,T0),tuple(Orange,T0),tuple(SFR,T0),tuple(Free,makeTactic(T0)),tuple(MVNO,T0)})

// two variants : no Free & average Free (adjust premiums)
E0b :: Experiment(scenario = Sc1,
                 strategies = {tuple(Bytel,SB),tuple(SFR,SR),tuple(Orange,SO),tuple(Free,SF), tuple(MVNO,SM)},
                 sTactics = {tuple(Bytel,T0),tuple(Orange,T0),tuple(SFR,T0),tuple(Free,T1f),tuple(MVNO,T0)})

E0c :: Experiment(scenario = Sc1,
                 strategies = {tuple(Bytel,SB),tuple(SFR,SR),tuple(Orange,SO),tuple(Free,SF), tuple(MVNO,SM)},
                 sTactics = {tuple(Bytel,T0),tuple(Orange,T0),tuple(SFR,T0),tuple(Free,T2f),tuple(MVNO,T0)})


// test - default strategies
// Free is dumb => it does not work
E1 :: Experiment(scenario = Sc1,
                 strategies = {tuple(Bytel,SB),tuple(SFR,SR),tuple(Orange,SO),tuple(Free,SF), tuple(MVNO,SM)},
                 sTactics = {tuple(Bytel,T0b),tuple(Orange,T0o),tuple(SFR,T0s),tuple(Free,T0f),tuple(MVNO,T0m)})

// variant with no reactions (calibration)
E1b :: Experiment(scenario = Sc1,
                  strategies = {tuple(Bytel,SB),tuple(SFR,SR),tuple(Orange,SO),tuple(Free,SF), tuple(MVNO,SM)},
                  sTactics = {tuple(Bytel,T0f),tuple(Orange,T0f),tuple(SFR,T0f),tuple(Free,T0f),tuple(MVNO,T0f)})

// each players goes with a soft strategy (base)
E2 :: Experiment(scenario = Sc1,
                 strategies = {tuple(Bytel,SB2),tuple(SFR,SR2),tuple(Orange,SO2),tuple(Free,SF2), tuple(MVNO,SM2)},
                 sTactics = {tuple(Bytel,T0b),tuple(Orange,T0o),tuple(SFR,T0s),tuple(Free,T0f),tuple(MVNO,T0m)})

// each players goes with a hard strategy
E3 :: Experiment(scenario = Sc1,
                 strategies = {tuple(Bytel,SB3),tuple(SFR,SR3),tuple(Orange,SO3),tuple(Free,SF3), tuple(MVNO,SM3)},
                 sTactics = {tuple(Bytel,T0b),tuple(Orange,T0o),tuple(SFR,T0s),tuple(Free,T0f),tuple(MVNO,T0m)})


// base test - run for 3 years - level0 (show the simple model) --------------------------------------
// meant to run at show level
[go0(e:Experiment) : void
  ->  NIT := 4, NOPT := 3,
     verbose() := 1, TALK := 1, SHOW := 1, DEBUG := 5,
     init(e),
     trace(0,"=== Init market shares : ~A\n",
            psi(list<float>{(o.start.arpu - 12.0 * o.premium) | o in (Company but Free)},pb.alpha)),
     loop(pb),
     display()]

[go0() -> go0(E1) ]

// TO RUN
// go0(E0b) & go0(E0c)

// level 1 experiment : local opt for tatic adjustment  -----------------------------------------------
[go(e:Experiment)
  -> NIT := 4, NOPT := 3,
     verbose() := 0, TALK := 1, SHOW := 2, DEBUG := 5, OPTI := 1,
     init(e),
     loop(pb),
     display() ]

[go() -> go(E1) ]

[go(e:Experiment,s:Scenario)
  -> e.scenario := s,
     go(e)]

[go(c:Company) -> verbose() := 0, optimize(c),runLoop(c),display(c),explain(c)]

[go(c:Company,s:Strategy) -> c.strategy := s, go(c)]

// quick test to see if twoOpt help
[go2(c:Company)
  -> let v := c.cursat in
       (twoOptimize(c),
        if (c.cursat > v) trace(0,"Two opt improvement for ~S: ~A->~A\n",c,v,c.cursat)) ]

// cute whatif to fine tune satisfaction !
// if go(C) gives something strange, go(c,label,value) does a whatif + explain
[go(c:Company,i:TAG,v:float) -> whatif(c,i,v,true) ]

// level 2 experiment : simple nash equilibrium search  ------------------------------------------------
PNASH:boolean :: false
NASH2:boolean :: false

[nash(e:Experiment) : void
  -> MOPT := 0,
     for i in (1 .. e.scenario.nIter)
         (if PNASH poptimize(e,i,e.scenario.nIter)
          else soptimize(e,i,e.scenario.nIter),
          if NASH2 for c in Company go2(c)),
     trace(0,"================== RESULT of NASH Loop (~A x ~S) ====================== \n",e.scenario.nIter,SATMULT),
     trace(0,"===> category = ~A \n",LCAT[categorize(e)]),
     for c in Company
        (add(c.global,globalSat(c)),
         for i in (1 .. NIT) add(c.ebitdas[i],c.status[i].ebitda)),
     // display all satisfactions for companies
     display() ]

[nash() -> nash(E0)]

[go2(e:Experiment,s:Scenario)
  -> e.scenario := s,
     go(e),
     nash(e)]

[go2() -> go2(E1,Sc1)]



// this is a special tuning version of go2 : additional parameters and additional output
// in : number of loops, satisfaction formula, NUM2 (number of 1opt loop)
// out: convergence factor, final EBITDA, traces
[go1(e:Experiment,s:Scenario,n:integer,sm:boolean)
   -> e.scenario := s,
      s.nIter := n,
      SATMULT := sm,
      go(e),
      TRACEON := true,        // logs the ebitda and the convergence
      nash(e),
      trace(0,"log of convergence : ~A \n",TRACED),
      trace(0,"log of results : ~A \n",TRACEG) ]

[go1(n:integer,sm:boolean) -> go1(E1,Sc1,n,sm) ]


// level3 experiment : GTES (with randomization)  -------------------------------------------------------

[go3(e:Experiment,s:Scenario)
  -> e.scenario := s,
     NIT := 4, NOPT := 3,
     verbose() := 0,
     run(e)]

[go3() -> go3(E1,Sc1)]

// level4 experiment: "fixed point" = 10 years ----------------------------------------------------------
[go4(e:Experiment) : void
  ->  NIT := 10, NOPT := 9,
     verbose() := 0, TALK := 1, SHOW := 2, DEBUG := 5, OPTI := 1,
     init(e),
     loop(pb),
     display() ]

[go4() -> go4(E0)]


// interesting function - equilibrium price
[p(c:Company,b:float) : Price
  -> c.variable + c.expenses[1] / (12.0 * b) ]


// check the satisfaction equation
[ftest(x:float,v:float) : float
  -> 1.0 - pos5(1.0 - x / v) ]

