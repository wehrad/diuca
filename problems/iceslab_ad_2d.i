# ------------------------ 

# slope of the bottom boundary (in degrees)
bed_slope = 10 # 5

# change coordinate system to add a slope
gravity_x = ${fparse
  	      cos((90 - bed_slope) / 180 * pi) * 9.81 * 1e-6
              } 
gravity_y = ${fparse
	      - cos(bed_slope / 180 * pi) * 9.81 * 1e-6
              } 

# geometry of the ice slab (converging nb_years=1)
# length = 200
# thickness = 100

#  geometry of the ice slab (converging nb_years=1)
length = 1000
thickness = 200

#  geometry of the ice slab (not converging)
# length = 5000
# thickness = 400

# dt associated with rest time associated with the
# geometry (in seconds)
# ice has a high viscosity and hence response times
# of years
nb_years = 1.
_dt = ${fparse
       nb_years * 3600 * 24 * 365
       }

# ------------------------

[Mesh]
  type = GeneratedMesh
  dim = 2
  xmin = 0
  xmax = '${length}'
  ymin = 0
  ymax = '${thickness}'
  nx = 10
  ny = 5
  elem_type = QUAD9
  
[]

[GlobalParams]
  order = FIRST
  integrate_p_by_parts = true
[]

[AuxVariables]
  [vel_x]
  []
  [vel_y]
  []
[]

[AuxKernels]
  [vel_x]
    type = VectorVariableComponentAux
    variable = vel_x
    vector_variable = velocity
    component = 'x'
  []
  [vel_y]
    type = VectorVariableComponentAux
    variable = vel_y
    vector_variable = velocity
    component = 'y'
  []
[]

[Variables]
  [velocity]
    family = LAGRANGE_VEC
    order = SECOND
  []
  [p]
  []
[]

[Kernels]
  [mass]
    type = INSADMass
    variable = p
  []
  [momentum_time]
    type = INSADMomentumTimeDerivative
    variable = velocity
  []
  [momentum_advection]
    type = INSADMomentumAdvection
    variable = velocity
  []
  [momentum_viscous]
    type = INSADMomentumViscous
    variable = velocity
  []
  [momentum_pressure]
    type = INSADMomentumPressure
    variable = velocity
    pressure = p
  []
  [momentum_supg]
    type = INSADMomentumSUPG
    variable = velocity
    velocity = velocity
  []
  [gravity]
    type = INSADGravityForce
    variable = velocity
    gravity = '${gravity_x} ${gravity_y} 0.'
  []
[]

[BCs]

  [Periodic]
    [up_down]
      primary = left
      secondary = right
      translation = '${length} 0 0'
      variable = 'velocity'
    []
  []
  
  # [inlet]
  #   type = ADVectorFunctionDirichletBC
  #   variable = velocity
  #   boundary = 'left'
  #   function_x = 0.
  #   function_y = 0.
  # []
  [noslip]
    type = ADVectorFunctionDirichletBC
    variable = velocity
    boundary = 'bottom'
    function_x = 0.
    function_y = 0.
  []
[]

[Materials]
  [ice]
    type = ADIceMaterial
    velocity_x = "vel_x"
    velocity_y = "vel_y"
    pressure = "p"
  []
  [ins_mat]
    type = INSADTauMaterial
    velocity = velocity
    pressure = p
  []
[]

[Preconditioning]
  [SMP]
    type = SMP
    full = true
    solve_type = 'NEWTON'
  []
[]

[Executioner]
  type = Transient
  # num_steps = 10

  # petsc_options_iname = '-pc_type -pc_factor_shift -pc_mat_solve_package'
  # petsc_options_value = 'lu       NONZERO mumps'
  petsc_options = '-pc_svd_monitor'
  petsc_options_iname = '-pc_type'
  petsc_options_value = 'svd'

  # nl_rel_tol = 1e-08
  # nl_abs_tol = 1e-13
  nl_rel_tol = 1e-07
  nl_abs_tol = 1e-07
  
  nl_max_its = 40
  line_search = none

  automatic_scaling = true

  dt = "${_dt}"
  # num_steps = 100
  steady_state_detection = true
  steady_state_tolerance = 1e-100
  check_aux = true
  
[]

[Outputs]
  console = true
  [out]
    type = Exodus
  []
[]
