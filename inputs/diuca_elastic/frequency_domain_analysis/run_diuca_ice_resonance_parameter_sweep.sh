#!/usr/bin/env bash

# Young's Modulus range to sweep over
youngs_moduli=$(seq 1.0 .01 1.1)

for youngs_modulus in "${youngs_moduli[@]}"; do

    echo ${fp}
    
    mpiexec -n 6 ../../../diuca-opt\
	    -i diuca_ice_resonance.i\
	    _youngs_modulus=8.7e9\
	    _poissons_ratio=0.32\
	    Outputs/file_base="temp"
done
