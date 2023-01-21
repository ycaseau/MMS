// ********************************************************************
// *       MMS : Micro Market Model                                   *
// *       copyright (C) 2012 Yves Caseau                             *
// *       file: simul.cl                                             *
// ********************************************************************


// this file contains a naive simulator (yearly runs)
// we simulate each year of market evolution, using
//    (a) a churn model
//    (b) a sales model
//    (c) a cost model
// This is not a differential model (contrary to CGS)

CSHOW:Company :: unknown               // debug : see a company
ISHOW:integer :: 0                     // debug : see a month
ISTOP:integer :: 0                     // debug : stop at a given month

// ********************************************************************
// *    Part 1: Utility Methods (psi & all)                           *
// *    Part 2: Simulation Loop                                       *
// *    Part 3: Satisfaction                                          *
// *    Part 4: Problem-specific display methods                      *
// ********************************************************************

// ********************************************************************
// *    Part 1: Utility Methods (psi & all)                           *
// ********************************************************************


// === THIS IS THE HEART OF THE CGS MODEL - read document carefully ===========

// psi is the master function that computes the marketshares (lr) from the prices,
// according to a power law whose exponent is alpha
// TODO : retrouver la référence à cette loi
[psi(lv:list[float],alpha:float) : list[float]
  -> let n := length(lv), lr := make_list(n,float,0.0), s := 0.0 in
        (for i in (1 .. n)
           let d := (lv[i] ^ -(alpha)) in
             (s :+ d, lr[i] := d),
         for i in (1 .. n) lr[i] :/ s,
         lr)]


// ********************************************************************
// *    Part 2: Simulation Loop                                       *
// ********************************************************************

// loop runs one simulation loop
[loop(p:Problem) : void
  -> for c in Company c.cursat := 0.0,
     for i in (1 .. NIT) oneLoop(p,i),
     for o in Company o.cursat := satisfaction(o)]        // v0.5 : one overall satistaction computation
        
[oneLoop(p:Problem, i:integer) : void
   ->  //[SHOW] ======= start year ~A ==================== // i,
       pb.year := i,
       getChurn(p),                            // (1) churn & renewal model
       getMarket(p),                           // (2) market KISS model
       for o in Company getEbitda(o),          // (3) financial number crunching
       if (i = ISTOP) error("stop at ISTOP"),
       if (verbose() >= SHOW) for o in Company see(o) ]


// returns the results from a simulation
[runLoop(c:Company) : float
  -> reinit(),
     loop(pb),
     c.cursat ]

[rego()
  -> reinit(),
     loop(pb),
     displayEnd(pb)]

[rego(e:Experiment)
  -> rego(),
     for c in Company
        add(e.result.tResult,c,current(c).ebitda,current(c).share,c.cursat) ]

// (1) ------------------------------------------------------------------------

// returns the perceived price
[pPrice(o:Company) : Price
   -> (o.status[pb.year].price - o.premium * 12.0) ]

// computes the churn for each operator
// put a bound to avoid meaningless states
[getChurn(p:Problem)
  -> let i := p.year, minP := BIGF in
       (for o in Company
           (o.status[i].price := o.start.price * o.tactic.pricing[i],
            minP :min pPrice(o)),
        for o in Company
           (//[SHOW] ~S: price = ~A vs ~A(min) -> ch ratio = ~A // o,pPrice(o),minP,((pPrice(o) / minP) ^ pb.beta),
            o.status[i].churn% := churnRatio(o.churn%,pPrice(o),minP),
            if (o.status[i].price > previous(o).price)
              (//[DEBUG] price ~A -> ~A : fact =~A // o.status[i].price,previous(o).price,churnRatio(0.1,o.status[i].price,previous(o).price),
               o.status[i].churn% := churnRatio(o.status[i].churn%,o.status[i].price,previous(o).price)))) ]

// computes the churn ratio as a function of oldPrice -> newPrice and a default ratio d%
[churnRatio(d%:float,p1:Price,p2:Price) : Percent
  ->  min(0.8, d% * (p1 / p2) ^ pb.beta) ]

// (2) -------------------------------------------------------------------------

LOOKY:integer :: 0
LOOKO:any :: unknown

// computes the total "aquisition brute" market (sigma of churns)
// distribute using PSI
// get the new base (EoY)
[getMarket(p:Problem) : void
   -> let ob := 0.0, nb := 0.0 in
      (//[SHOW] === compute new market //,
       pb.acqNum := 0.0,                 // total "acquisition brutes"
       for o in Company
        let i := pb.year, cs := o.status[i], x := 0.0 in
           (cs.base := previous(o).base,
            ob :+ cs.base,
            x := cs.base * cs.churn%,
            pb.acqNum :+ x,
            cs.base :- x),
      let lr := psi(list{pPrice(o) | o in Company}, pb.alpha) in   // computes marketshare
           (for o in Company
             let cs := o.status[pb.year] in
                (cs.share := lr[o.index],
                 if (LOOKY = pb.year & o = LOOKO)
                    printf("~S market share = ~A from (~A -> ~A)\n",o,cs.share,
                            list{pPrice(o) | o in Company},lr),
                 cs.acqNum := cs.share * pb.acqNum,
                 //[DEBUG] ~S: ~A -> ~A (~A% c) -> ~A(~A% ms) // o,previous(o).base,cs.base,cs.churn%,cs.base + cs.acqNum,lr[o.index],
                 cs.base :+ cs.acqNum,
                 nb :+ cs.base)),
       trace(SHOW,"[~A] ~A  -> ~A aquisitions -> ~A (total base)\n",pb.year,ob,pb.acqNum,nb)) ]

//(3) -----------------------------------------------------------------------

// financial numbers crunching from volumes - computes the Ebitda
//   - compute arpu from price
//   - get sales
//   - get variable costs
//   - deduce ebitda
[getEbitda(o:Company) : void
  -> let cs := current(o),
         avgOldBase := (previous(o).base + (cs.base - cs.acqNum)) / 2.0, // avg # of old customers
         avgBase := avgOldBase + (cs.acqNum / 2.0),                      // avg # of new customers
         oldPrice := previous(o).arpu,
         k := churnRatio(o.fluidity,oldPrice,cs.price),
         migPrice := min(oldPrice,(oldPrice * (1.0 - k) + cs.price * k)) in // price for old customers
      (cs.sales := (avgOldBase * migPrice) +  (cs.acqNum / 2.0 * cs.price),
       //[1] ~S: sales = ~A (~A * ~A + ~A * ~A) [mig = ~A] // o,cs.sales,avgOldBase,migPrice,cs.acqNum / 2.0,cs.price,k,
       cs.arpu := cs.sales / (avgOldBase + cs.acqNum / 2.0),
       cs.expense := o.expenses[pb.year + 1] + avgBase * expected(o.variable,o.expenseTrend,pb.year),
       cs.ebitda := cs.sales -  cs.expense,
       trace(DEBUG,"--- ~S: sales = ~A  ebitda = ~A\n",o,cs.sales,cs.ebitda)) ]



// ********************************************************************
// *    Part 3: Satisfaction                                          *
// ********************************************************************

// v0.2 : introduce a multiplicative version borrowed from RTMS
// note: we have not found a proper way to take hard constraints into account
SATMULT:boolean :: false

// standardized strategy satisfaction
// use a discounted formula (1€ today is better than 1euro in 3 years)
DF:float :: 0.7
[satisfaction(o:Company) : Percent
  -> let d := 0.0,f := 1.0, s := 0.0 in
       (for i in (1 .. NIT)
           (d :+ satisfaction(o,i) * f, s :+ f, f :* DF),
         d / s) ]

// satisfaction for a given year
[satisfaction(o:Company,y:integer) : Percent
  -> satisfaction(o,y,(o.status[y]).ebitda,(o.status[y]).share,(o.status[y]).sales,(o.status[y]).base) ]

// formula for satisfaction - this is the heart of the model !
// the satisfaction formula tells how far the performance (average earning, marketshare, sales, base) compare
// with the expected values that are stored in the strategy
[satisfaction(o:Company,y:integer,avgE:Price,avgM:Percent,avgS:Price,avgB:float) : Percent
  -> if SATMULT satisfaction2(o,y,avgE,avgM,avgS,avgB)
     else satisfaction1(o,y,avgE,avgM,avgS,avgB)]

// v0.1 version : additive (sum of deltas)
// formula for delta = pos(1 - value/target) = 0 if value > target,  what is missing (as a faction) if value < target
// there is a special case for Ebit, since more money is always better (look for pos5 in model.cl)
PENALTY :: 5.0           // going under the minRatio is strongly penalized
[satisfaction1(o:Company,y:integer,avgE:Price,avgM:Percent,avgS:Price,avgB:float) : Percent
  ->  let minE := avgS * o.strategy.minRatio,
          eP := (if (avgE < minE) PENALTY * sqr(avgE - minE) / sqr(expectedEbitda(o,y)) else 0.0),
          eE := pos4(1.0 - (avgE / expectedEbitda(o,y))),
          eB := pos(1.0 - (avgB / expectedBase(o,y))),
          eM := pos(1.0 - (avgM / expectedShare(o,y))) in
       (1.0 - eP - eE - eB - eM) ]

// v0.2 version : multiplicative = product(1 - e_i)
// note: cannot become negative
[satisfaction2(o:Company,y:integer,avgE:Price,avgM:Percent,avgS:Price,avgB:float) : Percent
  ->  let minE := avgS * o.strategy.minRatio,
          eP := (if (avgE < minE) abs(avgE - minE) / (2.0 * (abs(avgE) + expectedEbitda(o,y))) else 0.0),
          eE := pos6(1.0 - (avgE / expectedEbitda(o,y))),
          eB := pos(1.0 - (avgB / expectedBase(o,y))),
          eM := pos(1.0 - (avgM / expectedShare(o,y))) in
       (if (eP > 0.0) (0.5 - eP) else 1.0) * (1 - (eE / 10.0)) * (1 - eB) * (1 - eM) ]


// talkative version
[explain(o:Company) : void
  -> for i in (1 .. NIT) printf("[~A] ~I",i,explain(o,i)) ]

[explain(o:Company,y:integer) : void
   -> explain(o,y,(o.status[y]).ebitda,(o.status[y]).share,(o.status[y]).sales,(o.status[y]).base) ]

[explain(o:Company,y:integer,avgE:Price,avgM:Percent,avgS:Price,avgB:float) : void
  -> let minE := avgS * o.strategy.minRatio,
         eP :=  (if SATMULT (if (avgE < minE) abs(avgE - minE) / (2.0 * (abs(avgE) + expectedEbitda(o,y))) else 0.0)
                 else (if (avgE < minE) PENALTY * sqr(avgE - minE) / sqr(expectedEbitda(o,y)) else 0.0)),
         eE := pos5(1.0 - (avgE / expectedEbitda(o,y))),
         eB := pos(1.0 - (avgB / expectedBase(o,y))),
         eM := pos(1.0 - (avgM / expectedShare(o,y))) in
       (//[5] debug ~S = ~S x ~S // minE, avgS, o.strategy.minRatio,
        printf("~S:~F% [~F1 ~F1 ~F1 ~F1] => [~F%/~F%][~F0/~F0][~F0$/~F0$-~F0$]\n",o,
              (if SATMULT (if (eP > 0.0) (0.5 - eP) else 1.0) * (1 - (eE / 10.0)) * (1 - eB) * (1 - eM)
               else 1.0 - eE - eM - eP - eB),
              eP * 100.0, eE * 100.0, eB * 100.0, eM * 100.0,
              avgM,expectedShare(o,y),
              avgB,expectedBase(o,y),
              avgE,expectedEbitda(o,y),minE,0)) ]

// straightforward for MMS since goals are absolute
// the only special case is for Free (c.strategy.minRatio = 0.0) since growth is
// expected to be linear
[expectedEbitda(c:Company,y:integer) : Price
    ->  if (c.strategy.minRatio = 0.0) c.strategy.ebitda * float!(y) / float!(NIT)
        else c.strategy.ebitda]
[expectedShare(c:Company,y:integer) : Percent -> c.strategy.share]
[expectedBase(c:Company,y:integer) : Percent
    ->  if (c.strategy.minRatio = 0.0) c.strategy.base * float!(y) / float!(NIT)
        else c.strategy.base]



// NEW: global satisfaction works with respect to a global strategy
// formula for satisfaction
GSF:float :: 0.80
[globalSat(o:Company) : Percent
  -> globalSat(o,(o.status[NIT]).ebitda,(o.status[NIT]).share,(o.status[NIT]).sales,(o.status[NIT]).base) ]

[globalSat(o:Company,avgE:Price,avgM:Percent,avgS:Price,avgB:float) : Percent
  ->  let minE := avgS * o.strategy.minRatio,
          eP := (if (avgE < minE) PENALTY * sqr(avgE - minE) / sqr(o.reference.ebitda * GSF) else 0.0),
          eE := pos5(1.0 - (avgE / (o.reference.ebitda * GSF))),
          eB := pos(1.0 - (avgB / (o.reference.base * GSF))),
          eM := pos(1.0 - (avgM / (o.reference.share * GSF))) in
       (1.0 - eE - eM - eP - eB) ]


// new in v0.2 -  try multiplicative satisfaction from        

// ********************************************************************
// *    Part 4: Problem-specific display methods                     *
// ********************************************************************

[displayEnd(p:Problem)
  -> let t := 0.0 in
       (for o in Company
          (t :+ current(o).base,
           printf("=== ~S (~A% -> ~A%)===\n~I",o,f%(o.cursat),f%(satisfaction(o)),
               look(o))),
        printf("total base = ~F2\n",t)) ]


// list all parameters
[see(pb:Problem)
  -> let s := pb.scenario in
    (printf("_ price to volume sentitivity alpha = ~I [~A - ~A]\n",princ(pb.alpha,3),s.alphaMin,s.alphaMax),
     printf("_ price to churn sentitivity beta = ~I [~A - ~A]\n",princ(pb.beta,3),s.betaMin,s.betaMax)) ]


// presents a two lines summary of a company
[see(c:Company) : void
  -> let s := (if (pb.year = 0) c.start else current(c)) in
        printf("~S: ~F1 -> ~F0$ (~F%) arpu@~F1$ \n",c,
            s.base,
            s.ebitda,
            s.share,
            s.arpu) ]

// more detail comparison of current state vs initial
[look(o:Company) : void
  -> printf("ebitda: ~F2$ vs ~F2$,",current(o).ebitda,o.start.ebitda),
     printf(" with base: ~F2 vs ~F2,",current(o).base,o.start.base),
     printf(" share: ~F% vs ~F%;\n",current(o).share,o.start.share),
     printf("expenses: ~F2$ vs ~F2$,",current(o).expense,o.start.expense),
     printf("sales: ~F2 vs ~F2,",current(o).sales,o.start.sales),
     printf("churn: ~F% vs ~F% (price:~F2$ vs ~F2);\n",current(o).churn%,
            o.start.churn%,current(o).price,o.start.price) ]


// 3YP print format =============================================================================
// produce a table for each company
[yp() -> for o in Company yp(o)]

[yp(o:Company) : void
  -> princ("\n"), ypSep(),
     printf("|~S\tebitda\tbase\tchurn\tshare\tsales\texp\tprice\tarpu\t|\n",o),
     ypSep(),
     yp(o.start,pb.startYear),
     for i in (1 .. NIT) yp(o.status[i],pb.startYear + i),
     ypSep()]

[ypSep() : void
  -> printf("+------+-------+-------+-------+-------+-------+-------+-------+--------+\n")]

[yp(s:Status,i:integer)
  -> printf("| ~A\t~F0\t~F2\t~F%\t~F%\t~F0\t~F0\t~F1\t~F1\t|\n",i,
            s.ebitda, s.base, s.churn%, s.share,
            s.sales, s.expense, s.price,s.arpu) ]     // was pF(s.sales / s.base,1)) ]



// satisfaction report (useful for strategy tuning)
[display() -> for o in Company display(o)]

[display(o:Company) : void
  -> printf("~S satisfaction = ~F%\n",o, satisfaction(o)), ypSep(),
     printf("|~S\tsat\tebitda\tbase\tshare\tsales\texp\tprice\tarpu\t|\n",o),
     ypSep(),
     display(o.start,pb.startYear,1.0),
     for i in (1 .. NIT) display(o.status[i],pb.startYear + i,satisfaction(o,i)),
     ypSep()]


[display(s:Status,i:integer,sat%:float)
  -> printf("| ~A\t~F2\t~F0\t~F2\t~F%\t~F0\t~F0\t~F1\t~F1\t|\n",i,
            sat%, s.ebitda, s.base, s.share,
            s.sales, s.expense, s.price, s.arpu) ]
            


[allSat()
 -> printf("===>> ~I\n",
            for c in Company printf("~S:~F% ",c,c.cursat)) ]


