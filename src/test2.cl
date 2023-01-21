// ********************************************************************
// *       MMS : Micro Market Simulation                              *
// *       copyright (C) 2012 Yves Caseau                             *
// *       file: test2.cl                                              *
// ********************************************************************

// This is a crude abstraction of the battle of teh four mobile players in 2012 - 2014

(printf("=== TEST2 file ...  2012 data ===\n"))


// Step 1: describe the companies  ------------------------------------


// Bytel is managing to get a decent market share with a high arpu (generosity premium because network is
// less full)
Bytel :: Company( expenses = list<float>(1500.0,1500.0,1500.0,1500.0), expenseTrend = -0.00,
                  churn% = 0.20, fluidity = 0.5, premium = 3.0)
(init(Bytel,2011,Status(base = 11.3,  sales = 5700.0, ebitda = 1200.0)),
 Bytel.reference := Strategy(ebitda = 1200.0, share = 0.18, base = 11.0))


// Orange is the reference operator (premium = 0)
Orange :: Company(expenses = list<float>(3000.0,3000.0,3000.0,3000.0), expenseTrend = -0.00,
                  churn% = 0.15, fluidity = 0.3)
(init(Orange,2011,Status(base = 27.0, sales = 10800.0, ebitda = 3920.0)),
 Orange.reference := Strategy(ebitda = 3900.0, share = 0.33, base = 27.0))


// SFR - (IT & network operations are more expensive)
SFR :: Company(expenses = list<float>(2000.0,1900.0,1900.0,1900.0), expenseTrend = -0.00,
               churn% = 0.20, fluidity = 0.4, premium = -2.0)
(init(SFR,2011,Status( base = 21.0, sales = 8400.0 , ebitda = 3520.0)),
 SFR.reference := Strategy(ebitda = 3500.0, share = 0.28, base = 21.0))

// in this model we add MVNO
// average of Virgin and Lebara :)
MVNO :: Company(expenses = list<float>(300.0,300.0,300.0,300.0), expenseTrend = -0.00,
                churn% = 0.25, fluidity = 0.6, premium = -30.0)
(init(MVNO,2011,Status( base = 7.0, sales = 1000.0, ebitda = 100.0)),
 MVNO.reference := Strategy(ebitda = 100.0, share = 0.1, base = 7.0))


// These tactics are used for the clean test = no change => no change :)
T0b :: makeTactic(1.0,1.0,1.0)
T0o :: makeTactic(1.0,1.0,1.0)   // 0.9 -> 0.2
T0s :: makeTactic(1.0,1.0,1.0)
T0m :: makeTactic(0.95,0.9,0.85)

T0 :: makeTactic(1.0,1.0,1.0)

// step 2: describe starting global situation ------------------------------

NITER :: 6
NTEST :: 50
Sc1 :: Scenario(nIter = NITER, nTest = NTEST,
                // cost structures
                costs = {},                       // default
                // MonteCarlo Tuning
                alphaMin = 2.0, alphaMax = 3.0,
                betaMin = 1.0, betaMax = 1.5)


// step 3: describe strategy ----------------------------------------------

// we only use reasonably aggressive strategies

/// each player has its stragegy, ... and variants
// Bytel
SB :: Strategy( ebitda = 700.0, share = 0.15, base = 9.0, minRatio = f%(15))
SB2 :: Strategy( ebitda = 500.0, share = 0.13, base = 8.0, minRatio = f%(10))
SB3 :: Strategy( ebitda = 900.0, share = 0.17, base = 9.0, minRatio = f%(15))

// Orange
SO :: Strategy( ebitda = 3000.0, share = 0.25, base = 25.0, minRatio = f%(30))
SO2 :: Strategy( ebitda = 2200.0, share = 0.20, base = 23.0, minRatio = f%(20))
SO3 :: Strategy( ebitda = 3500.0, share = 0.27, base = 25.0, minRatio = f%(30))

// SFR
SR :: Strategy( ebitda = 2500.0, share = 0.20, base = 18.0, minRatio = f%(25))
SR2 :: Strategy( ebitda = 2000.0, share = 0.18, base = 16.0, minRatio = f%(20))
SR3 :: Strategy( ebitda = 3000.0, share = 0.22, base = 18.0, minRatio = f%(30))

// MVNOS
SM :: Strategy( ebitda = 100.0, share = f%(10), base = 6.0, minRatio = f%(10))
SM2 :: Strategy( ebitda = 10.0, share = f%(15), base = 5.0, minRatio = f%(10))
SM3 :: Strategy( ebitda = 10.0, share = f%(15), base = 6.0, minRatio = f%(10))



// each players goes with a hard strategy
F1 :: Experiment(scenario = Sc1,
                 strategies = {tuple(Bytel,SB),tuple(SFR,SR),tuple(Orange,SO), tuple(MVNO,SM)},
                 sTactics = {tuple(Bytel,T0b),tuple(Orange,T0o),tuple(SFR,T0s), tuple(MVNO,T0m)})



