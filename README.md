# astero

MScR Project - Stellar rotation formalisms of γ Doradus stars from gravity-mode period spacings

###################################################################################

This repository contains the files in MESA astero module that are edited and/or created to compute 
frequencies with TAR and 2nd-order perturbative method. 

work_bench_gyre is an example work dir for TAR computation with GYRE.
work_bench_adipls is an example work dir for 2nd Pert. with ADIPLS.
These two particular work directories were used for generating benchmarks in our project, but they 
are also suitable for grid scanning. 

work_gGbA_fine_2 is an example work dir used for GYRE fine grid scanning in our project.

src contains the edited src codes in astero module
[Note that these are NOT the src files inside the work directories]

The src codes are coupled to the edited version of ADIPLS provided in the 'adipls' repository. 


###################################################################################

Instructions for users:

Replace the astero/src with the src in here.
Add the work directories in here to the astero directory.

Replace the mesa-r10398/adipls/adipack.c/adipls with adipls in the 'adipls' repository, 
Recompile the entire MESA to generate the object files.

Copy work_bench_gyre/work_bench_adipls to create a new working directory. cd to the this 
work directory to compute pulsation freqs with TAR/2nd-Pert formalism.  
Compile the work directory to begin. 

For GYRE directories:
edit inlist_astero for model controls
use input file gyre.in for pulsation controls
run the command ./rn, then $GYRE_DIR/bin/gyre ./gyre.in 
alternatively, use the grid scanning tool run_gyre 
run the command ./run_gyre 

For ADIPLS directories:
edit inlist_astero for model controls
use input file inlist_pulse_controls for pulsation controls
run the command ./rn
alternatively, use the grid scanning tool run_adipls 
run the command ./run_adipls 

####################################################################################









