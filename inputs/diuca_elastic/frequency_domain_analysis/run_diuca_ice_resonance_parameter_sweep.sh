#!/usr/bin/env bash

# Young's Modulus for ice greatly varies, let's sweep across a range
# of 0.1 to 9 GPa

declare -a icebedrock_coupling_states=("0" "1" "2")

for icebedrock_coupling_state in "${icebedrock_coupling_states[@]}"; do
    for youngs_modulus in $(seq 0.1e9 1e9 9e9); do
	
	echo "s:${icebedrock_coupling_state} E:${youngs_modulus}"
	
	mpiexec -n 6 ../../../diuca-opt\
		-i diuca_ice_resonance.i\
		_youngs_modulus=${youngs_modulus}\
		_poissons_ratio=0.32\
		icebedrock_coupling_state=${icebedrock_coupling_state}\
		Outputs/file_base="diuca_ice_resonance_s${icebedrock_coupling_state}_e${youngs_modulus}"
    done			
done
