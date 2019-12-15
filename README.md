# astero

MScR Project - Stellar rotation formalisms of γ Doradus stars from gravity-mode period spacings

(Updated 14/12/2019)

This repository contains the files in MESA astero module that are edited/created to compute 
frequencies with TAR and 2nd-order perturbative method. 

work_bench_gyre is an example work dir for TAR computation with GYRE.
work_bench_adipls is an example work dir for 2nd-Pert computation with ADIPLS.
These two work directories were used for generating benchmarks in our project, but they 
are also suitable for grid scanning. 

work_gGbA_fine_2 and work_gAbF_fine_2 are example work dir used for fine grid scanning.

src contains the edited src codes in astero module
[Note: these are NOT the src files inside the work directories]

The src codes are only coupled to the edited version of ADIPLS provided in the 'adipls' repository. 
The adipls in the orginal MESA package does not comply with the src in this repo. 


# New features introduced to MESA

The input file inlist_pulse_controls in astero work directories (e.g. work_bench_adipls) allows
users to add rotational effects to the output freqs when calling ADIPLS from MESA. 

The following parameter inputs are required:
- Degree l
- Starting Azimuthal order m (the code then goes m,m+1,m+2,...,l)
- Frequency range (uHz)
- Number of steps in freq scan 
- Uniform angular rotation rate (choose rad/s or critical)
- Order of perturbative method (choose 1st- or 2nd-)
- Output filename 

The final set of pulsation frequencies are stored in the last (10th) column of the output file. The outputs 
for each models includes the mode data for all values of m defined in the input. 
Only extract those for a specific value of m for one mode. 

The outputs are (in order of column number):
- Degree l
- Order n 
- Azimuthal degree m
- Zero-th order frequencies 
- Inertia 
- Beta 
- Splitting term 1 
- Splitting term 2
- Splitting term 3 
- Final set of freqs after combining all splitting terms 

For details on the calculations of splittings, see Burke et al. (2006), Kjeldsen et al. (1998). 
[NOTE: the splitting terms 1/2/3 above are NOT the same as the 1st/2nd/3rd-order pert expansion terms]


# Instructions

Replace your local astero/src with the src in here.
Then add the work directories work_bench_gyre and work_bench_adipls to your astero directory.

Replace the mesa-r10398/adipls/adipack.c/adipls with adipls in the 'adipls' repository. 
Recompile the entire MESA to generate the object files.

Copy work_bench_gyre/work_bench_adipls to create a new working directory for your project. 
cd to this work directory to compute pulsation freqs with TAR/2nd-Pert formalism.  
Compile the work directory to begin. 

---- For GYRE directories ----

Edit inlist_astero for model controls, then run the command ./rn

Take the model in LOGS dir you want to use for computing freqs, and enter it
into GYRE inputs. 
Use input file gyre.in for pulsation controls, 
and then run the command $GYRE_DIR/bin/gyre ./gyre.in 

Alternatively, use the grid scanning tool run_gyre 
by running the command ./run_gyre 

---- For ADIPLS directories ----

Edit inlist_astero for model controls.
Use input file inlist_pulse_controls for pulsation controls,
then run the command ./rn

Alternatively, use the grid scanning tool run_adipls 
by running the command ./run_adipls 







