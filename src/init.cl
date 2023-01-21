(printf("--- load init Micro Market Simulation --- \n"))

*src* :: "/Users/ycaseau/Dropbox/src"
*where* :: "/Users/ycaseau/proj/MMS"

(debug(),
 verbose() := 2,
 safety(compiler) := 5)                        // ensure safe compiling + remove warnings


// module - Yves's version of January 2012 -> lab workbench for Marketing's hypotheses
// KISS model ! keep the same structure as CGS, hence it may be used as a tutorial to CGS :)
m1 :: module(part_of = claire,
              source = *src* / "mmsv0.1",
              uses = list(Reader),
              made_of = list("model","simul","gtes"))


// module - Yves's version of October 2014 -> lab workbench for Marketing's hypotheses
// KISS model ! keep the same structure as CGS, hence it may be used as a tutorial to CGS :)
m2 :: module(part_of = claire,
              source = *src* / "mmsv0.2",
              uses = list(Reader),
              made_of = list("model","simul","gtes"))

// 2022 : move to CLAIRE4
m3 :: module(part_of = claire,
              source = *src* / "mmsv0.3",
              uses = list(Reader),
              made_of = list("model","simul","gtes"))


