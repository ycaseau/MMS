// ********************************************************************
// *       MMS : Micro Market Simulation                              *
// *       copyright (C) 2012-2022 Yves Caseau                        *
// *       file: model.cl                                             *
// ********************************************************************

// this file contains the data model for the simulation project

// ********************************************************************
// *    Part 1: Company Classes                                       *
// *    Part 2: System & Simulation classes                           *
// *    Part 3: Simulation & Results                                  *
// *    Part 4: Data creation                                         *
// *    Part 5: Utility functions                                     *
// ********************************************************************

Version :: 0.3                       // moved to CLAIRE4 i n 2022

TALK:integer :: 1
SHOW:integer :: 2
DEBUG:integer :: 2

NIT:integer :: 10                // 3 year plan simulations - start with one for debug

BIGF :: 1e30

// add to CLAIRE4 (to make portabulity easier)
ephemeral_object <: object

// ********************************************************************
// *    Part 1: Company Classes                             *
// ********************************************************************

// Type aliases
Percent :: float
Price :: float                 // euros or millions of euros
Time :: integer                // time is measured in weeks/100 (100 = 1.week)

f%(x:integer) : float -> (float!(x) / 100.0)
f%(x:float) : integer -> integer!(x * 100.0)

// Foward
Strategy <: thing
Tactic <: ephemeral_object
Status <: ephemeral_object

// a Company
// note that variable cost is assumed to be constant (a gross simplification) which means that
// we only use the "expenses" (fixed cost) list to play what-if with cost reduction
Company <: thing(
   index:integer = 0,           // each company has an index -> list[] access
   // problem data model slots (given as part of the description problem)
   expenses:list<Price>,        // fixed yearly expenses (N + 1 since e[1] : start year)
   variable:Price,              // per subscriber expenses
   expenseTrend:Percent,        // variable expense reduction trend
   fluidity:Percent,            // migrations is represented by a percentage of customers
   churn%:Percent,              // yearly churn rate (default rate)
   premium:Price,
   // subcomponents
   strategy:Strategy,           // goals
   reference:Strategy,          // stable ref point for goals
   tactic:Tactic,               // how the company react to deltas (reality - goals)
   startTactic:Tactic,          // original tactic (when GTES starts)
   prevTactic:Tactic,           // copy of previous tactic within an optim cycle (useful to measure distance)
   nextTactic:Tactic,           // original tactic
   start:Status,                // reference point when the simulation start  (year 0 - cf previous(o))
   status:list<Status>,         // current status for each year of the simulation
   // slots that are computed
   ebitdas:list<measure>,       // (avg) ebitda trajectory
   global:measure,              // global satisfaction, measure against a stable reference
   cursat:float,                // average satisfaction with current tactic
   index:integer = 0)           // internal index


// the status of a company
// this is a set of slots for which we keep the original value and the
// current ones
Status <: ephemeral_object(
  ebitda:float,       // monthly ebitda
  expense:Price,      // total yearly expenses
  churn%:Percent,     // yearly churn rate
  base:float,         // subscriber base
  sales:Price,        // monthly income from outgoing traffic
  arpu:Price,         // average arpu
  price:Price,        // sell price
  acqNum:float,       // number of acquisitions (new customers)
  share:Percent)      // market share


// A strategy defines the growth that is expected for EBITDA and market share, using absolute targets
// this is different from CGS (look at a mature market)
Strategy <: thing(
   ebitda:Percent,             // yearly growth (expected evolution)
   share:Percent,              // Market share
   base:float,                 // expected customer base (millions)
   minRatio:Percent)           // absolute min acceptable value for Ebitda/sales ratio


// a Tactic defines how the company plays its bets according to three dimensions:
// - ARPU : reduction (%) of the "average offer"
Tactic <: ephemeral_object(
    pricing:list<Percent>)             // list per year (NIT)


// ********************************************************************
// *    Part 2: System & Simulation classes                           *
// ********************************************************************

Scenario <: thing

// a market is defined with two parameters
//  - price to volume sensitivity (alpha)
//  - price sensitivity for churn (beta)
// when we do full GTES, we'll Monte-Carlo those !

// common object
Problem <: thing(
   // global variables - used by the simulator
   startYear:integer = 0,       // reference: "zero year"
   year:integer = 1,            // 1 to 36
   scenario:Scenario,           //
   acqNum:float,                // total market
   nLoop:integer = 1,           // # of average case
   cycleDist:float = 0.0,       // sum of deplacements (tactic delta) for one optim cycle
   // elasticity constants - famous six - cf. Word document
   alpha:float,            // price to share elasticity (pi^alpha / sigma(pi^alpha)
   beta:float)             // same parameter for churn


pb :: Problem()

// a scenario sets the macro-economy parameters that need to be explored
Scenario <: thing(
   nIter:integer = 5,              // numbre of Optimization iterations
   nTest:integer = 1,              // numbre of monte-carlo testcases
   costs:set[tuple(Company,list<Price>)],      // fixed cost stucture test-cases
   // range of variation for elasticity parameters
   alphaMin:float = 0.0,        // min value for alpha (price2Volume elasticity)
   alphaMax:float = 1.0,
   betaMin:float = 0.0,               // min value for beta (
   betaMax:float = 1.0)


// ********************************************************************
// *    Part 3: Simulation & Results                                  *
// ********************************************************************

/* what we measure for one run
Measure <: ephemeral_object(
  sum:float = 0.0,
  square:float = 0.0,           // used for standard deviation
  num:float = 0.0)          // number of experiments

// simple methods add, mean, stdev
[add(x:Measure, f:float) : void -> x.num :+ 1.0, x.sum :+ f, x.square :+ f * f ]
[mean(x:Measure) : float -> if (x.num = 0.0) 0.0 else x.sum / x.num]
[stdev(x:Measure) : float
   -> let y := ((x.square / x.num) - ((x.sum / x.num) ^ 2.0)) in
         (if (y > 0.0) sqrt(y) else 0.0) ]
[stdev%(x:Measure) : Percent -> stdev(x) / mean(x) ]
[reset(x:Measure) : void -> x.square := 0.0, x.num := 0.0, x.sum := 0.0 ] */


// what we measure for one run and one company
Result <: ephemeral_object(
  success:measure,        // satisfaction w.r.t. strategy (key metric)
  ebitda:measure,
  share:measure,
  arpu:measure)           // average

// add a measure to a Result (for a company)
[add(x:Result,e:Price,sh:Percent,suc:Percent) : void
  -> add(x.ebitda,e),
     //[DEBUG] --- add ebitda measure: ~A // e,
     add(x.share,sh), add(x.success,suc) ]
[addArpu(x:Result,ap:Price) : void
  -> add(x.arpu,ap) ]
[reset(x:Result) : void
  ->  reset(x.arpu),
      reset(x.ebitda), reset(x.share), reset(x.success) ]
[makeResult() : Result
  -> Result(ebitda = measure(), share = measure(), success = measure(), arpu = measure()) ]


// what we measure for each testcase :
// (1) a list of results
// (2) we add a qualitative approach = count categories (wins, looses, death)
TResult <: ephemeral_object(
  measures:list<Result>,              // samples for each company
  totalE:measure,                     // record the totalEbit to detect fight using linear Regression
  tacticD:measure,                    // measures the distance in tactical moves (should get close to 0)
  wins:list<measure>,                 // list of 0/1 : boolean vars for wins (category(c)) => vector by company
  looses:list<measure>,               // v0.6 : call this labels
  deaths:list<measure>)               // see findLabel(c) for semantic of win/loose/death


// add a sample in the measure database
[add(x:TResult,c:Company,e:Price,sh:Percent,suc:Percent) : void
  -> add(x.measures[c.index],e,sh,suc) ]
[addArpu(x:TResult,c:Company,ap:Price) : void
  -> addArpu(x.measures[c.index],ap) ]

[addTrend(x:TResult,dTac:Percent,totE:Price) : void
  -> add(x.tacticD,dTac),
     add(x.totalE,totE) ]

// company label (1 to 3 : wins/looses/dies)
[addLabel(x:TResult,c:Company,y:(1 .. 3)) : void
  -> add(x.wins[c.index], (if (y = 1) 1.0 else 0.0)),
     add(x.looses[c.index], (if (y = 2) 1.0 else 0.0)),
     add(x.deaths[c.index], (if (y = 3) 1.0 else 0.0)) ]

[reset(x:TResult) : void
    -> for y in x.measures reset(y),
       for y in x.wins reset(y),
       for y in x.looses reset(y),
       for y in x.measures reset(y) ]

[makeTResult() : TResult
  -> TResult(measures = list<Result>{makeResult() | c in Company},
             tacticD = measure(), totalE = measure(),
             wins = list<measure>{measure() | c in Company},
             looses = list<measure>{measure() | c in Company},
             deaths = list<measure>{measure() | c in Company}) ]

// what we measure for one experience is
//  (1) global aggregated stat
//  (2) count meta categories (stable, unstable(chaos), unstable(war))
//  (3) store results for stable
EResult <: ephemeral_object(
  gResult:TResult,                // combined stat (raw numbers)
  tResult:TResult,                // Test result (one by monteCarlo run)
  cResult:TResult,                // clean result (average of stable tests)
  totalE:measure,                 // total EBITDA (average, TODO = obtained by linear regression)
  devE:measure,                   // stdev of total EBITDA
  LRdev:measure,                  // quadratic residue from LR
  totalD:measure,                 // target deplacement (average, TODO = obtained by linear regression)
  stable:measure,                 // category record (same as labels: binay variables => average is a %)
  war:measure,                    // see category(e) in simul.cl for semantics
  fight:measure,                  // new in v0.6 :
  chaos:measure)

// category
[addCategory(x:EResult,y:(1 .. 4)) : void
  -> add(x.fight, (if (y = 3) 1.0 else 0.0)),
     add(x.stable, (if (y = 4) 1.0 else 0.0)),
     add(x.war, (if (y = 2) 1.0 else 0.0)),
     add(x.chaos, (if (y = 1) 1.0 else 0.0)) ]

// add the averages of ebitda et deplacement
[addAverages(x:EResult,mE:float,dE:float,mD:float,res:float) : void
   -> add(x.totalE,mE), add(x.devE,dE),
      add(x.totalD,mD), add(x.LRdev,res) ]

[makeEResult() : EResult
  -> EResult(gResult = makeTResult(),
             tResult = makeTResult(),
             cResult = makeTResult(),
             totalE = measure(), totalD = measure(), devE = measure(), LRdev = measure(),
             stable = measure(), fight = measure(), war = measure(), chaos = measure()) ]

// an experiment takes a set of a strategy, a given scenario, optimizes the
// tactics and returns the average Tresult
Experiment <: thing(
  scenario:Scenario,
  category:integer = 0,                      // set by the algorithm
  result:EResult,                            // global result
  listX:list<float>,                         // record runs
  listY:list<float>,                         // record total Ebitda
  listZ:list<float>,                         // record deplacements
  index:float,                               // index = number of value in listX/listY
  strategies:set[tuple(Company,Strategy)],   // set of (company,stategies) to be assigned for this exp.
  sTactics:set[tuple(Company,Tactic)])        // same for starting tactics (new in v0.5)


// ********************************************************************
// *    Part 4: Data creation                                         *
// ********************************************************************

// initialization
[init(o:Company,y:integer,s:Status) : void
  -> o.expenses := extendTo(o.expenses,NIT + 1),
     if (pb.startYear = 0) pb.startYear := y
     else if (y != pb.startYear) error("wrong year: ~A",y),
     o.index := size(Company),
     if (s.base > 0.0)
       (// default case with a history - cf. test.1 file
        s.expense := s.sales - s.ebitda,  // total expenses = fixed + variable
        s.arpu := s.sales / s.base,
        s.price := s.arpu,
        o.variable := (s.expense - o.expenses[1]) / s.base)     // attention expenses[1] = start year
     else (s.arpu := 0.0),             // assumes that we start with a stable state
     o.start := s,
     o.global := measure(),
     o.ebitdas := list<measure>{measure() | i in (1 .. NIT)},
     o.status := list<Status>{copy(s) | i in (1 .. NIT)}]

// trend-based : we provide with the 3 % trends ...
[makeTactic(t1:Percent,t2:Percent,t3:Percent) : Tactic
   ->  Tactic( pricing = extendTo(list<Percent>(t1,t2,t3),NIT)) ]      // list per year (NIT)


// useful : allows to change NIT (extrapolation of all data)
[extendTo(l:list,k:integer) : type[l]
   -> let n := length(l) in (for i in (n + 1 .. k) l :add l[n], l) ]

// useful to implement trends over a few years (new customer, etc.)
// linear interpolation : i is the number of years
[expected(v:float,rate:float,i:integer) : float
  -> v * ((1.0 +  rate) ^ float!(i)) ]

// deep copy
[makeTactic(x:Tactic) : Tactic
   ->  Tactic( pricing = list<Percent>{x.pricing[y] | y in (1 .. NIT)}) ]

[copyTo(x:Tactic,y:Tactic) : void
   -> for i in (1 .. NIT) y.pricing[i] := x.pricing[i]]

[yearExp(x:float) : float  -> ((1.0 + x) ^ 12.0) - 1.0 ]


// initialize an experiment
[init(e:Experiment) : void
  -> pb.scenario := e.scenario,
     e.result := makeEResult(),
     init(pb.scenario),               // Monte-Carlo init ... TODO eventually (easier debug this way)
     e.listX := list<float>(),
     e.listY := list<float>(),
     e.listZ := list<float>(),
     e.index := 0.0,
     for x in e.strategies x[1].strategy := x[2],
     for x in e.sTactics x[1].tactic := x[2],
     for c in Company
          (c.start.share := (c.start.base / sum(list{c.start.base | c in Company})),
           c.startTactic := makeTactic(c.tactic),  // necessary for GTES (Monte-carlo multiple runs) -> used in reinit
           c.prevTactic := makeTactic(c.tactic),   // necessary for GTES -> used in reinit
           c.nextTactic := makeTactic(c.tactic)),
      let lc := list{o in Company | o.start.base > 0.0},
          lr := psi(list<float>{(o.start.arpu - 12.0 * o.premium) | o in lc},pb.alpha) in
        (//[TALK] model check: init shares = ~A // lr,
         for i in (1 .. length(lc)) lc[i].start.share := lr[i]) ]

// manage the listX, listY log
[resetLog(e:Experiment) : void
  -> e.index := 0.0,
     shrink(e.listX,0),
     shrink(e.listY,0),
     shrink(e.listZ,0) ]

// record cycle-level data for the optimize loop : total Ebitda and Cycle-Distance, to evaluate connvence
[addLog(e:Experiment,totE:float) : void
  -> e.index :+ 1.0,
     e.listX :add e.index,
     e.listY :add totE,
     e.listZ :add pb.cycleDist ]

// initialize a scenario : Monte-Carlo simulation
// is called for each sequence of the experience called a Test
[init(s:Scenario)
  -> //[0] ==== Monte-Carlo Instanciation of ~S ================================== // s,
     pb.alpha := randomIn(s.alphaMin,s.alphaMax),
     pb.beta := randomIn(s.betaMin,s.betaMax),
     if unknown?(scenario,pb) pb.scenario := s,
     see(pb),
     for l in s.costs
         let o := l[1] in
           (o.expenses := extendTo(l[2],NIT + 1),   // overide cost structure
            if (o.start.base > 0.0)  o.variable := (o.start.expense - o.expenses[1]) / o.start.base) ]

[reinit()
 ->  for c in Company
       (c.status[1] := copy(c.start)) ]
   
[reinit(e:Experiment,random?:boolean) : void
   -> if random? init(e.scenario),
      reset(e.result.tResult),
      for c in Company copyTo(c.startTactic,c.tactic) ]  // original tactic - restart optim at the same point !

// easy access to status
[current(o:Company) : Status => (o.status[pb.year]) ]
[previous(o:Company) : Status -> if (pb.year > 1) o.status[pb.year - 1] else o.start ]

//  distance between two tactics normalized
[distance(x:Tactic,y:Tactic) : float
  -> let d := 0.0 in
        (for i in (1 .. NIT) d :+ sqr(x.pricing[i] - y.pricing[i]),
         d) ]

//  euclidian norm (squared)
[norm(x:Tactic) : float
  -> let d := 0.0 in
        (for i in (1 .. NIT) d :+ sqr(x.pricing[i]),
         d) ]

// measures the deplacement : distance between two successive tactics in an optimization step
// v6: normalized :)
[deplacement(c:Company) : Percent
  -> let v1 := distance(c.prevTactic,c.tactic) in
       (if (v1 = 0.0) 0.0 else (v1 / max(norm(c.prevTactic),norm(c.tactic)))) ]

// ********************************************************************
// *    Part 5: Utility functions                                     *
// ********************************************************************

sum(s:list) : float
 => let d := 0.0 in (for y in s d :+ y, d)


== :: operation(precedence = precedence(=))
==(x:float,y:float) : boolean
  -> (abs(x - y) < (abs(x) + abs(y) + 1.0) * 1e-2)

// three small functions that are used to represent satisfaction
// pos5 is a concave function so that satisfaction weight less than dissatisfaction
// pos is called with a number that varies from -INT to 1.0, hence returns a number less than 1.0
pos(x:float) : float -> (if (x > 0.0) x else 0.0)
pos5(x:float) : float -> (if (x > 0.1) (x - 0.09)  else if (x > 0.0) x / 10.0 else x / 100.0)
pos4(x:float) : float -> (if (x > 0.0) x else (x / 100.0))

// v2: pos6 returns something between 0 (for x = -inf) and 10
pos6(x:float) : float -> min(10.0,pos4(x))




// divide each member by the sum so that the list becomes a % distribution list
normalize(l:list<float>) : list<float>
  -> let x := sum(l) in list<float>{ (y / x) | y in l}


// utility functions -------------------------------------------------

/* the pF is my ugly duckling :) -------------------------------------------
// float print is now standard in v3.4.42 but this is still a cuter print ...
[pF(x:float,i:integer) : void        // prinf i numbers
  -> if (x < 0.0) (princ("-"), pF(-(x),i))
     else let frac := x - float!(integer!(x + 1e-10)) + 1e-10 in
         printf("~A.~I", integer!(x + 1e-10),
                pF(integer!(frac * (10.0 ^ float!(i))),i)) ]

// print the first i digits of an integer
[pF(x:integer,i:integer) : void
  -> if (i > 0) let f := 10 ^ (i - 1), d := x / f in
                   (princ(d), if (i > 1) pF(x mod f, i - 1)) ]

[p%(x:float) -> pF(x * 100.0,2), princ("%")]
[pF(x:float) -> pF(x,1)] */

list%(l:listargs) : list<Percent>  -> list<Percent>{ f%(x) | x in l}
listP(l:listargs) : list<Price>  -> list<Price>{float!(x) | x in l}

// -----------------------------------------------------------------------


// random extensions
 
[randomIn(a:float,b:float) : float
   -> printf("call randomIn ~A,~A \n",a,b),
      a + float!(random(integer!((b - a) * 1000.0))) / 1000.0 ]

[randomChoice?(x:Percent) : boolean
  -> random(1000) < integer!(x * 1000.0) ]

// ======= linear regression ==============================================  v0.6

// <start>  code fragment, origine = CGS, version = 1.0, date = Avril 2010

// input = lists of Xi and Yi, returns a triplet (slope, constant factor, deviation)
[linearRegression(lx:list<float>,ly:list<float>) : list<float>
  -> let sx := 0.0, sy := 0.0, ssx := 0.0, n := length(lx), sxy := 0.0,
         a := 0.0, b := 0.0, sv := 0.0, av_x := 0.0, av_y := 0.0, av_xy := 0.0 in
       (assert(length(ly) = n),
        for i in (1 .. n)
          let x := lx[i], y := ly[i] in
             (sx :+ x, ssx :+ (x * x), sy :+ y, sxy :+ (x * y)),
        av_x := sx / n, av_y := sy / n, av_xy := sxy / n,
        a :=  (av_xy - av_x * av_y) / ((ssx / n) - av_x * av_x),
        b := av_y - a * av_x,
        for i in (1 .. n)
          let x := lx[i], y := ly[i], v := sqr(y - (a * x + b)) in (sv :+ v),
        sv :/ (n - 2),             // ref: Wikipedia on linear regression
        list<float>(a,b,sqrt(sv))) ]

[testReg()
 -> let l := linearRegression(list<float>(1.0,2.0,3.0), list<float>(0.0,0.0,0.0)) in
        assert(l[1] == 0.0 & l[2] == 0.0 & l[3] == 0.0),
    let l := linearRegression(list<float>(1.0,2.0,3.0), list<float>(0.0,1.0,2.0)) in
        assert(l[1] == 1.0 & l[2] == -1.0 & l[3] == 0.0),
    let l := linearRegression(list<float>(1.0,2.0,3.0), list<float>(3.0,5.0,7.0)) in
        assert(l[1] == 2.0 & l[2] == 1.0) ]

// <end>



