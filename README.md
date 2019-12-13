# astero

This repository contains the files in MESA astero module that are edited and/or created to compute 
frequencies with TAR and 2nd-order perturbative method. 

work_bench_gyre is an example work dir for TAR computation with GYRE.
work_bench_adipls is an example work dir for 2nd Pert. with ADIPLS.
[Note that the src files in these work directories are also edited]
work_gGbA_fine_2 is an example work dir for grid scanning with GYRE.
src are the edited src codes in astero module

The src codes in work_bench_adipls and astero are coupled to the edited version of ADIPLS provided 
in the other repository. Replacing all files in the corresponding MESA astero and adipls modules are 
required for the codes to function. 

##################################################################################################
Instructions:

Replace the astero/src with the src in here
Add the work directories in here to the astero directory

Replace the mesa-r10398/adipls/adipack.c/adipls with the adipls in the 'adipls repo' 
Recompile the entire MESA

Change into the GYRE/ADIPLS work directories to compute pulsation freqs with TAR/2nd-Pert formalism  
compile the work directory 

For GYRE directories:
edit inlist_astero for model ctrl
use input file gyre.in for pulsation ctrl
run the command ./rn then $GYRE_DIR/bin/gyre ./gyre.in 
alternatively, use the grid scanning tool run_gyre
run the command ./run_gyre 

For ADIPLS directories:
edit inlist_astero for model cntrl
use input file inlist_pulse_controls for pulsation ctrl
run the command ./rn
alternatively, use the grid scanning tool run_adipls 
run the command ./run_adipls 

##################################################################################################









