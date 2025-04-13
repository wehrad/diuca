#!/usr/bin/env bash

# Young's Modulus range to sweep over
# 0.1-9 GPa
#  (Vaughan, 1995; Reeh et al., 2003).
# (Gammon et al., 1983; Schulson & Duval, 2009).
# (e.g., Reeh et al., 2003)
# Gudmundsson, 2011
#  [Lingle et al., 1981, Vaughan, 1995,
# Reeh et al., 2003

# declare -a icebedrock_coupling_states=("0" "1" "2")

# for icebedrock_coupling_state in "${icebedrock_coupling_states[@]}"; do
#     for youngs_modulus in $(seq 0.1e9 1e9 9e9); do
	
# 	echo "s:${icebedrock_coupling_state} E:${youngs_modulus}"
	
# 	mpiexec -n 6 ../../../diuca-opt\
# 		-i diuca_ice_resonance.i\
# 		_youngs_modulus=${youngs_modulus}\
# 		_poissons_ratio=0.32\
# 		icebedrock_coupling_state=${icebedrock_coupling_state}\
# 		Outputs/file_base="diuca_ice_resonance_s${icebedrock_coupling_state}_e${youngs_modulus}"
#     done			
# done

declare -a icebedrock_coupling_states=("0" "1" "2")

youngs_modulus=1e9
_step_freq=0.01

for icebedrock_coupling_state in "${icebedrock_coupling_states[@]}"; do
	
    echo "s:${icebedrock_coupling_state} E:${youngs_modulus}"
	
    mpiexec -n 6 ../../../diuca-opt\
	    -i diuca_ice_resonance.i\
	    _youngs_modulus=${youngs_modulus}\
	    _poissons_ratio=0.32\
	    icebedrock_coupling_state=${icebedrock_coupling_state}\
	    step_freq=${_step_freq}\
	    Outputs/file_base="diuca_ice_resonance_s${icebedrock_coupling_state}_e${youngs_modulus}"

done
