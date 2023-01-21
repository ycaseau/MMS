// ********************************************************************
// *       CSS : Game theory simulation of mobile operators           *
// *       copyright (C) 2007-2010 Yves Caseau                        *
// *       file: gtes.cl                                             *
// ********************************************************************


// this file contains the GTES methods applied to the CGS problem

// ********************************************************************
// *    Part 1: Learning (Local moves)                                *
// *    Part 2: Optimization Loop (optimize)                          *
// *    Part 3: ExtendedNash Equilibrium (Controlled Convergence)     *
// *    Part 4: GTES Experiments (MonteCarlo Simulation)              *
// *    Part 5: Display methods                                       *
// ********************************************************************


// ********************************************************************
// *    Part 1: Learning (Local moves)                                *
// ********************************************************************

OPTI:integer :: 5        // trace parameter for optimization functions
NUM1:integer :: 6        // number of dichotomic steps (to be tuned)
NUM2:integer :: 3        // number of single moves exporation rounds
NUM3:integer :: 200      // number of random draws for 2opt

//  ------------- local move space -------------------------------------

// very simple here
NOPT:integer :: (NIT - 1)           // the last year must be left in automatic mode
TAG :: integer                      // tactic fields are indexed through tags

// read/write accessors - works for any value of NIT = 1,2 or 3
[read(x:Tactic,i:TAG) : float
  -> x.pricing[i] ]

// this is where we propagate the trends (note that they are bounded)
[write(x:Tactic,i:TAG,v:float) : void
  -> x.pricing[i] := v,
     if (i = NOPT) x.pricing[i + 1] := v]             // one more year

// nice for debug
[label(i:TAG) : string -> "price_" /+ string!(i)]

// cute debug
[whatif(c:Company,i:TAG,v:float) -> whatif(c,i,v,false) ]
[whatif(c:Company,i:TAG,v:float,talk?:boolean)
  -> let x := c.tactic, v2 := read(x,i) , s2 := c.cursat in
      (write(x,i,v),
       runLoop(c),
       //[0] whatif ~A(~S) = ~A -> sat = ~A vs ~A->~A // label(i),c,v,c.cursat,v2,s2,
       if talk? (display(c), explain(c)),
       write(x,i,v2)) ]


// local opt main loop (Hill-climbing) -----------------------------------------------
OPTMODE:integer :: 0               // v0.6: 0 = both is absolutely necessary !
                                   // 1 = optimize only, 2 = optimize2 only

// optimise the tactic a company
// notice that we keep the results obtained in the previous status, to measure the
// convergence of the results, or their absence !
// v6: we removed the test to see if a basic tactic worked better ...
[optimize(c:Company)
  -> let v1 := runLoop(c) in              // used to reset cursat
        (for i in (1 .. NUM2)
               for p in (1 .. NOPT) (if (OPTMODE != 1) optimize2(c,p),
                                     if (OPTMODE != 2) optimize(c,p)),
         trace(TALK,"--- end optimize(~S) -> ~A% [from ~A% - d=~A]\n",c,f%(c.cursat), f%(v1), f%(deplacement(c)))) ]

// first approach : relative steps (=> does not cross the 0 boundary, keeps the sign) ----------

// optimize a given slot in a set of two dichotomic steps
[optimize(c:Company,p:TAG)
  -> for i in (1 .. NUM1) optimize(c,p,float!(2 ^ (i - 1))),
     trace(OPTI,"best ~A for ~S is ~A => ~A\n",
           label(p),c,read(c.tactic,p), c.cursat) ]

// try to add / retract a (multiplying) increment
[optimize(c:Company,p:TAG,r:float)
   -> //[OPTI] ..... start optimize(~S) : ~A @ ~A // c,label(p),r,
      let vp := read(c.tactic,p), vr := c.cursat, val := 0.0,
          v1 := vp / (1.0 +  (1.0 / r)), v2 := vp * (1.0 + (1.0 / r)) in
        (write(c.tactic,p,v1),
         val := runLoop(c),
         //[OPTI] try ~A (vs.~A) for ~A(~S) -> ~A (vs. ~A)// v1,vp,label(p),c,val,vr,
         if (val > vr) (vp := v1, vr := val),
         write(c.tactic,p,v2),
         val := runLoop(c),
         //[OPTI] try ~A for ~A(~S) -> ~A // v2,label(p),c,val,
         if (val > vr) (vp := v2, vr := val),
         write(c.tactic,p,vp),
         c.cursat := vr) ]


// absolute variant --------------------------------------------------------------------

// optimize a given slot in a set of two dichotomic steps
[optimize2(c:Company,p:TAG)
  -> for i in (1 .. NUM1) optimize2(c,p,float!(2 ^ (i - 1))),
     trace(OPTI,"[2] best ~A for ~S is ~A => ~A\n",
           label(p),c,read(c.tactic,p), c.cursat) ]

SEED:float :: 0.1
[optimize2(c:Company,p:TAG,r:float)
   -> //[OPTI] ..... start optimize2(~S) : ~A @ ~A // c,label(p),r,
      let vp := read(c.tactic,p), vr := c.cursat, val := 0.0,
          v1 := vp +  (SEED / r), v2 := vp - (SEED / r) in
        (write(c.tactic,p,v1),
         val := runLoop(c),
         //[OPTI] try ~A (vs.~A) for ~S(~S) -> ~A (vs. ~A)// v1,vp,label(p),c,val,vr,
         if (val > vr) (vp := v1, vr := val),
         write(c.tactic,p,v2),
         val := runLoop(c),
         //[OPTI] try ~A for ~S(~S) -> ~A // v2,label(p),c,val,
         if (val > vr) (vp := v2, vr := val),
         write(c.tactic,p,vp),
         c.cursat := vr) ]


// ------------------------------- 2-opt (copied from RTMS) ----------------------------------------------
OPTI2:integer :: 1

// randomized 2-opt, borrowed from SOCC, but smarter:once the first random move is made, try to fix it with optimize
// tries more complex moves which are sometimes necessary
// n is the number of loops
[twoOpt(c:Company)
  -> // optimize(c),                      // first run a single pass
     let vr := c.cursat, val := 0.0 in
        (let p1 := random(1,NOPT),
             p2 := random(1,NOPT),
             v1 := read(c.tactic,p1), v2 := read(c.tactic,p2) in
           (if (p1 = p2) nil
            else let v1new := v1 * (1.0 + ((if random(true) 1.0 else -1.0) / float!(2 ^ random(1,5)))) in
             (write(c.tactic,p1,v1new),
              //[OPTI2] === shift: ~S(~S) = ~A vs ~A // label(p1),c,read(c.tactic,p1),v1),
              if (read(c.tactic,p1) != v1) optimize(c,p2),
              val := c.cursat,
              trace(OPTI2,"=== try2opt [~A vs ~A] with ~S(~A<-~A) x ~S(~A<-~A)\n",
                    val,vr,label(p1),read(c.tactic,p1),v1,label(p2),read(c.tactic,p2),v2),
           if (val <= vr) (c.cursat := vr, write(c.tactic,p1,v1), write(c.tactic,p2,v2))
           else (vr := val,
                 trace(OPTI2,"*** improve ~A with ~S:~A x ~S:~A -> ~A\n",
                       val,label(p1),read(c.tactic,p1),label(p2),read(c.tactic,p2), val))))) ]


[twoOptimize(c:Company)
  -> for i in (1 .. NUM3) twoOpt(c),
     trace(OPTI2,"=== end TwoOpt(~S) with sat =~F%\n",c,c.cursat)]

// ********************************************************************
// *    Part 2: Optimization Loop (optimize)                          *
// ********************************************************************


// ----------------------------- main function -------------------------

ISTOP:integer :: 0          // stop after X cycles of optimization
IGSTOP:integer :: 0         // stop after Y cycles of g-optimization
MOPT:integer :: 0           // trace the meta-optimization loop - global level
MOPT2:integer :: 0           // trace the meta-optimization loop - fine level

LCAT :: list("chaos", "war", "fight", "stable")      // from worse to better
CHAOS :: 1   // used to understand chaos
WAR :: 2
FIGHT :: 3
STABLE :: 4

// new in v0.6: (3) overall optimization strategy ---------------------------------------------------


// DEBUG : logs for making nice pictures
TRACEON:boolean :: false        // default
TRACEG:list<integer> :: list<integer>()
TRACED:list<float> :: list<float>()
         
// sequential optimize loop  (old code)
[soptimize(e:Experiment,i:integer,n:integer)
  -> let stat? := (2 * i > n) in
         (//[MOPT] ============ optimize loop [~A,~S] ======================= // i,stat?,
          for c in Company copyTo(c.tactic,c.prevTactic),
          pb.cycleDist := 0.0,
          for c in Company
             (optimize(c),
              runLoop(c),   // one last run ... to get real stable numbers
              pb.cycleDist :+ deplacement(c),
              if stat? (storeTrend(e,c), for c in Company storeStat(e,c)),
              trace(MOPT,"[soptimize] sat levels: ~A\n", list{list(c,c.cursat) | c in Company})),
          trace(MOPT,"[soptimize] total $: ~A, total distance: ~A \n", totalEbitda(),pb.cycleDist),
          // DEBUG : logs for making nice pictures
          if TRACEON (TRACEG :add integer!(totalEbitda()),
                      TRACED :add (pb.cycleDist / size(Company))),
          if (i = ISTOP) error("stop")) ]


// debug method for tuning + reproduce old strategy (good for comparisons !)
[soptimize(e:Experiment) : void
  -> for i in (1 .. e.scenario.nIter) soptimize(e,i,e.scenario.nIter)]

// store a data sample in the stat database
[storeStat(e:Experiment,c:Company) : void
 -> storeStat(e,c,e.result.tResult),                // result for this monteCarlo run
    storeStat(e,c,e.result.gResult) ]               // global result for all runs

// creates a measure that records all the relevant values (sat, ebit, arpu, etc.) for company c
[storeStat(e:Experiment,c:Company,x:TResult) : void
 -> let sat := c.cursat, eb := current(c).ebitda, sha := current(c).share,
        ap := current(c).arpu, cat := label(c) in
     (add(x,c,eb,sha,sat),
      addArpu(x,c,ap),
      addLabel(x,c,cat)) ]

// category : this is a key method - translate a quantitative (and false) results
// into a qualitative evaluation
// 1: winner, 2: looser 3: death  - let's try a simple schema
SAT_THRESHOLD:float :: 0.5                 // varies according to the model & situation
[label(c:Company) : integer
  -> let csat := satisfaction(c,NIT) in         // use last year's satisfaction
       (if (csat > SAT_THRESHOLD & current(c).ebitda > 0.0) 1
        else if (current(c).ebitda < 0.0) 3
        else 2) ]


// this method is called each time a company's tactic is optimized
// used to compute the trend in satisfaction ->
[storeTrend(e:Experiment,c:Company) : void
 -> let sat := c.cursat, totE := totalEbitda(), dTac := deplacement(c) in
     (//[5] == Nash iteration convergence: totE = ~A, dTac = ~A // totE, dTac,
      if (c = CSHOW) trace(0,"sat: ~A -> dTac = ~A \n",sat,dTac),
      addLog(e,totE),                           // create a log of total satisfatction numbers
      addTrend(e.result.tResult,dTac,totE)) ]

[totalEbitda() : Price
  -> sum(list<float>{c.status[pb.year].ebitda | c in Company}) ]


// new in v0.6 : (1) parallel evaluation -----------------------------------------------------

// parallel optimize loop
// TODO : add stats
[poptimize(e:Experiment,i:integer,n:integer)
  -> let stat? := (2 * i > n) in
         (//[MOPT] ============ parallel-optimize loop [~A,~S] ======================= // i,stat?,
          pb.cycleDist := 0.0,
          for c in Company
             (copyTo(c.tactic,c.prevTactic),
              optimize(c),
              copyTo(c.tactic,c.nextTactic),
              copyTo(c.prevTactic,c.tactic)),
          for c in Company
              (copyTo(c.nextTactic,c.tactic),      // all moves in parallel
               pb.cycleDist :+ deplacement(c)),
          reinit(),    // one last run ...
          loop(pb),    // to get real stable numbers
          if TRACEON (TRACEG :add integer!(totalEbitda()),
                      TRACED :add (pb.cycleDist / size(Company))),
          if stat?
             (for c in Company storeTrend(e,c),              // store moves-related stats (deltas)
              for c in Company storeStat(e,c)),              // store satisfaction related stats
          trace(MOPT,"[poptimize] sat levels: ~A\n", list{list(c,c.cursat) | c in Company}),
          trace(MOPT,"[poptimize] total $: ~A, total distance: ~A \n", totalEbitda(),pb.cycleDist),
          if (i = ISTOP) error("stop")) ]


// debug method for tuning + reproduce old strategy (good for comparisons !)
[poptimize(e:Experiment) : void
  -> for i in (1 .. e.scenario.nIter) poptimize(e,i,e.scenario.nIter),
     display() ]


// ********************************************************************
// *    Part 4: GTES Experiments (MonteCarlo Simulation)              *
// ********************************************************************

// this needs to be tuned more carefully - i.e. with a better use of
// optimization methods - 3opt & GenOpt
// new in v0.6 - categories are defined through a linear regression
// TODO : tune the numerical values !!!!
//  interesting: stability is actually easier to get ...
[categorize(e:Experiment) : integer
  -> let l := linearRegression(e.listX,e.listY),
         slope := l[1] * length(e.listX), constv := l[2], dev := l[3] in
        (//[0] >>> limit = ~A <<<< LR = ~A  // constv + slope * length(e.listX),l,
         //[0] >>> dev = ~A (vs 0.05), slope = ~A // dev / abs(constv),slope / abs(constv),
         if (dev < 0.05 * abs(constv) &  abs(slope) < 0.01 * abs(constv)) STABLE    // slope is flat
         else if (dev < 0.1 * abs(constv) & slope < -0.02 * abs(constv))  WAR
         else CHAOS)]

// run an experiment
RUNLOOP:integer :: 1                         // look at CGS v0.6 to add new variants
[run(e:Experiment) : void
 -> time_set(),
    init(e),
    for i in (1 .. e.scenario.nTest)   // number of monte-carlo simulation
        (//[TALK] start Test case ~A at ~As ===== // i, time_read() / 1000,
         loop(pb),
         resetLog(e),   // starts a fresh log that will be used to categorized
         if (RUNLOOP = 1) soptimize(e)
         else error("the stuff in CGS is not implemented in MMS :)"),
         //[0] ######  end of test case ~A -> ~A (~As) ####### // i, LCAT[categorize(e)], time_read() / 1000,
         //[5] [Monte-Carlo] sat levels: ~A [dist log : ~A] // list{list(c,c.cursat) | c in Company},e.listZ,
         storeStat(e,i),
         if (verbose() >= 1) display(e.result.tResult),
         if (i != e.scenario.nTest) reinit(e,true)),
    //[0] =================== end of experiment ~S @ ~As ======================= // e,time_read() / 1000,
    //[1] === log of Ebit: ~A // e.listY,
    display(e.result),
    summary(e,time_read()),
    trace(0,"result file generated in ~A\n",
            Id(*where*) /+ "\\data\\" /+ string!(name(e)) /+ "-" /+
            string!(name(e.scenario))) ]

// quadratic residue = linear regression error (sum of squares of distance)
[LRdist(e:Experiment) : float -> linearRegression(e.listX,e.listY)[3] ]

// store the Test data sample in the TResult stat database
[storeStat(e:Experiment,i:integer) : void
 -> let cat := categorize(e), mE := mean(e.result.tResult.totalE), dE := stdev%(e.result.tResult.totalE),
        mD := mean(e.result.tResult.tacticD),
        residue := LRdist(e) in
      (//[0] === Test case ~A: category is ~A (~A), ~A$[~A%] - mean D:~A]// i,cat,LCAT[cat],integer!(mE),f%(dE),mD,
      addCategory(e.result,cat),
      addAverages(e.result,mE,dE,mD,residue),
      for c in Company
        (add(c.global,globalSat(c)),
         for i in (1 .. NIT) add(c.ebitdas[i],c.status[i].ebitda)),
      if (cat = STABLE)
        (for c in Company storeStat(e,c,e.result.cResult))) ]


// display the summary for a full experiment
summary(e:Experiment,runTime:integer) : void
  -> let p := fopen(Id(*where*) /+ "\\data\\" /+ string!(name(e)) /+ "-" /+
                    string!(name(e.scenario)),"w") in
       (use_as_output(p),
        display(e,runTime),
        display(e.result),
        fclose(p))

// log a result in a log file - reusable pattern
logResult(pr:property,v:float,e:Experiment) : void
  -> let p := fopen(Id(*where*) /+ "\\data\\log","a") in
       (use_as_output(p),
        printf("[~A:~S=~A on ~S",
                substring(date!(0),1,19),pr,v,e),
        printf(" sat=~F%,churn=~F%,price=~A]\n",
            sum(list{c.cursat | c in Company}) / 3.0,
            sum(list{current(c).churn% | c in Company}) / 3.0,
            sum(list{current(c).arpu | c in Company}) / 3.0),
        fclose(p))

// ********************************************************************
// *    Part 5: Display methods                                       *
// ********************************************************************

// same thing that may be seen
display(e:Experiment,t:integer) : void
  -> (printf("=== Experiment ~S [~A s] ==== (runloop=~A)\n", e,t / 1000,RUNLOOP),
      printf("   done on ~A   version ~A\n",date!(1),Version),
      printf("   scenario = ~S x ~A Tests [~A iterations]\n",
              e.scenario,e.scenario.nTest, e.scenario.nIter),
      printf("   strategies = ~A \n\n",e.strategies))

// display
[display(x:TResult) : void
  -> // TODO print the Test results stats ?
      for c in Company
        printf("------------ ~S [~A] -------------\n~I~I~I",c,
              integer!((x.measures[c.index]).ebitda.Reader/num_value),
              displayProfile(x.wins[c.index], x.looses[c.index], x.deaths[c.index]),
              display(x.measures[c.index]),
              displayGlobal(c)) ]


// display profile
[displayProfile(x:measure,y:measure,z:measure) : void
   -> printf("wins ~F%, looses ~F%, dies ~F% (~F%)\n",
               mean(x), mean(y), mean(z), stdev(z)) ]

// key values
[display(x:Result) : void
  -> printf("ebitda: ~F2 M$ [dev: ~F%] ",mean(x.ebitda),stdev%(x.ebitda)),
     printf("share: ~F% [dev: ~F%]\n",mean(x.share),stdev%(x.share)),
     printf("arpu: ~F2$ [dev: ~F%] ",mean(x.arpu),stdev%(x.arpu)),
     printf("=> strategy success: ~F% [%dev: ~F%]\n",mean(x.success), stdev%(x.success)) ]

// display the ebitda statistics and the overall global satisfaction
[displayGlobal(c:Company) : void
  -> printf("trajectory: ~A, global sat: ~F%\n",list{mean(c.ebitdas[i]) | i in (1 .. NIT)},mean(c.global)) ]


// full version of display : include meta stats
[display(x:EResult) : void
  -> printf("==== experiment avg total Ebit ~F1, total deplacement ~F2 === \n",mean(x.totalE), mean(x.totalD)),
     printf("==== deviation of Ebit (1) convergence: ~F%  (2) sampling: ~F% \n",mean(x.devE), stdev%(x.totalE)),
     display(x.gResult),
     printf("==== stable ~F%, WARS ~F%, CHAOS ~F% ======\n",
            mean(x.stable), mean(x.war), mean(x.chaos)),
     printf("************ stable results *******************************************\n"),
     display(x.cResult) ]


// ------------------------- our reusable trick -------------------------

[ld1() : void -> load(Id(*src* / "mmsv" /+ string!(Version) / "test1")) ]
[ld2() : void -> load(Id(*src* /+ "\\mmsv" /+ string!(Version) /+ "\\test2")) ]

// we load a file of interpreted code which contains the program description
(#if (compiler.active? = false | compiler.loading? = true) ld1() 
 else nil)


