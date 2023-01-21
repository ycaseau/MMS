

                +--------------------------------------+
                | MMS (GTES) Project log file          |
                +--------------------------------------+



// ============================= v0.1 ===================================================================
// 4/11/2012
start project :-)
From readme:
This is a super simplified version of CGS that has nothing to do with telephony
and may be shown in a book (bk16) or in a talk
; ss



Each actor is a company with
  - a customer base
  - an ARPU
  - a structural churn
  - an attractiveness ( both a premium / generosity) measured as a delta-price
  - fixed costs + variables costs

The system schema is simple
  - churn is computed as structural * price factor
  - Pdm is computed as a function of (price + premium)

Tactic is simply a price vector (arpu = price - no migration involved)
Strategy is a combination of market share (LT) and revenue (ST)

we implement a full GTES similar to CGS and produce trajectories and 
strategy matrices

next steps:

- full clean-up of CGS files ! + write new test files using Free as a test case :)

(a) Model
-> keep only what is necessary for simul -> 3 phase, trivial model :)


(b)  trouver des chiffres

http://www.pcinpact.com/news/70659-orange-615-000-abonnes-free-mobile.htm
http://www.iliad.fr/en/finances/2012/Slideshow_S1_2012_310812.pdf
http://www.pcinpact.com/news/70921-abonnes-bilan-fai-operateurs-mobiles.htm

(c) simul  (3 or 5 years)


//5/11/2012
try to load - done :)
go0() : first test

// 6/11/2012
move to Dropbox source
(a)  2011 PdM  -> OK  (tuned premium)
     ajouter le share dans le init (plus facile de comparer :)) -> cf 3YP

(b)  2012 total acq  -> cf ARCEP -> environ 10M de ventes brutes en 2011, un x2 sur S1, donc entre
     16-18M pour 2012
     pr�vision BT pour PNB: 7.6 -> 14, mais attention PP decroit et Entreprise flat
     churn BT � 28%

(c) v�rifier PdM 2012 : Free � 35-40%
    on pourrait faire deux tests:
      (c1) sans r�action -> cf. le d�but
      (c2) avec r�action -> cf pr�visions de chaque op�rateur
- done

// 10/11/2012 (home PC)
- tune to probable Free (2.6+1+0.7+0.8 -Xmas has little impact -> 5.3)
- tune satisfaction
- add gtes.cl (but only the simple stuff for the CSDM experiments)


// 11/11/2012 (laptop)
Next steps: play the scenario where Orange cuts price by half the first year
(1) there is a problem with the variable expense
    attention: Bytel is clearly too expensive on the variable (fancy mobile + generous => more interco)
    but the fixed is not that different
    partially solved by lowering fixed exp for Orange

// 13/11/2012
the way we setup strategy (percentage) does not work
it is better to use fixed numbers ...
also, the importance on market share is too strong

// 14/11/2012
- fixed the migration (price dependent -> churnRate)
- go(op) pour chaque op, jusqu a ce que la tactique optimis�e ait du sens
    Note: twoOpt aurait du sens ici !
    cela se fait surtout en ajustant la strat�gie


// 15/11/2012
- tuning de strat�gie avec des versions pour les 5 op�rateurs
- nash() -> OK
  attention, convergence des tactique mais un �quilibre qui se d�place lentement


// 17/11/2012

lancer une petite version simple de nash() et mesurer la convergence

E1, E2, E3 : trois niveaux de strat�gie

SC1, SC2, SC3 : trois sc�narios de couts

voir quelle strat�gie pourrait laisser les prix � plus de 300� - done :)


//18/11/2012

implement a mode "minRatio = 0" for Free: expect
   - constant marketshare
   - linear growth of Ebitda
   - linear growth of base

GTES complet

  (a) randomiser alpha et beta � la main pour sentir  (courbe CSDM)
  (b) run complet de optimize(e)
  (c) lancer run(e) (Monte-Carlo) - cf. go3
 -> done !!!


// 25/11/2012

-> look at go(E2,Sc1) : why chaos ?
   no nash equilibrium : rotation around attractors -> try poptimize  (cf. RAIRO, why we introduce garded Nash)

-> passer � 50, lancer des script pour les tables CSDM

-> faire les tableur excel (a) sur un papier (quelle courbe) (b) sous Excel


// 2/12/2012 : last WE !

- ajouter une satisfaction de r�f�rence (par rapport aux chiffres 2012 pour les 3 ops, et par rapport � ?? pour Free)
- sortir les trajectoires moyennes d'EBITDA
- corriger la satisfaction de Free

// 9/12/2012 : close for CDSM

// 23/9/2014:  reopen !
- first step is to move to CLAIRE 3.4 !
- second step to to load & compile
- open v0.2 on laptop


// CSDM PITCH -----------------------------------------------------------------------------------------------------------------

message: meme un systeme aussi simple r�serve des surprises (cf. erreurs � Bytel)

Ce qu on apprend:

- quoi qu'on fasse cela part en guerre
- il n'y pas la place pour 4 � ces niveaux de prix

- il y a une bataille de couts fixes/ point mort
- si Free n  a pas besoin de construire un r�seau, il n est pas le maillon faible

a faire: d�finir le prix d equilibre p(X)
  equilibre =  cost(X) / X

Bytel -> deux axes:
  - plus de g�n�rosit� -> augmenter le premium
  - reduire les couts

Note: montrer le taux de chaos -> besoin de m�thodes plus sophistiqu�es

// SLIDE CDSDM  model
- dessin
- equation du mod�le = alpha, beta
- mod�le d entreprise = cost (fixed, variable) + premium  + tactique (prix) + strategie


// SLIDES CSDM  results (2)

(a) 4 histoire : avant (sans Free) + E1 + E2 + E3

(b) variations
   - sur les conditions alpha  Sc1a+,  Sc1a-
   - sur les conditions beta   Sc1b+,  Sc1b-
   - sur le r�seau de Free    Sc2
   - sur les couts  Sc3


Il ne reste plus qu a d�finir le format de r�sultat = courbes + variations + qualification war/stable/chaos


// CAVEAT  (� mettre dans la slide mod�le)

- closed market
- uniform market (real life = segmented)
- naive model

still interesting since
- results with a more sophisticated model are more moderate but same structure
- allows to learn about churn and cycles
- show the reactive behaviour one against another


// v0.2 ================================ fresh for business case =================================



5/1/2014 : reopen & recompile
15/1/2014 : play with Nash loop : create go1 (Instrumented Nash)


Design parameters to test before the UTC talk
    (1)  SMULT : satisfaction multiplicative formula
    (2)  popt versus sopt
    (3)  introduction of twoOpt (from RTMS)
    (4)  NUM2 & nIter  (inner loop & outer loop)

Outcome :
    (1) categorization
    (2) trace of sigma(ebit) et convergence


CONCLUSION:
  (a) we have not found the proper multiplicative formula that takes hard constraint into account
      => keep to additive formula ! (larger range)
  (b) we have a nice list of 2 experiments : E1, E2, E3 with stable Nash !



TODO

(1) aller au bout des points fixes !
     - faire des tests sur NUM2 & nIter
     - tester PNASH et NASH2 (cf. test1.cl)

(2) scenario pour business case, expos� UTC Compi�gne


// v0.3 ================================ move to CLAIRE 4 =================================

// changes  (interesting to log to add the change section to the CLAIRE4 doc)
- ephemeral_object : should be added as an alias (to improve portability)
-  "slot override for p=index"