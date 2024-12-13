# ------------------------

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
  type = FileMesh
  # file = mesh_icestream_flat.e
  file = mesh_icestream.e
  second_order = true
[]

[AuxVariables]
  [vel_x]
  []
  [vel_y]
  []
  [vel_z]
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
  [vel_z]
    type = VectorVariableComponentAux
    variable = vel_z
    vector_variable = velocity
    component = 'z'
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
    gravity = '0 0 -9.81'
  []
[]

[BCs]

  # hydrostatic pressure at the glacier front
  [frontpressure]
    type = ADFunctionDirichletBC
    variable = p
    boundary = 'downstream'
    function = ocean_pressure
  []
  [sedimentfrontpressure]
    type = ADFunctionDirichletBC
    variable = p
    boundary = 'downstream_sediment'
    function = ocean_pressure
  []
  
  # ice influx at the back of the glacier
  [inlet]
    type = ADVectorFunctionDirichletBC
    variable = velocity
    boundary = 'upstream'
    function_x = 100.
    function_y = 0.
    function_z = 0.
  []
  [sedimentinlet]
    type = ADVectorFunctionDirichletBC
    variable = velocity
    boundary = 'upstream_sediment'
    function_x = 100.
    function_y = 0.
    function_z = 0.
  []

  # no slip at the glacier base nor on the sides
  [basenoslip]
    type = ADVectorFunctionDirichletBC
    variable = velocity
    boundary = 'sediment'
    function_x = 0.
    function_y = 0.
    function_z = 0.
  []
  [leftnoslip]
    type = ADVectorFunctionDirichletBC
    variable = velocity
    boundary = 'left'
    function_x = 0.
    function_y = 0.
    function_z = 0.
  []
  [leftsedimentnoslip]
    type = ADVectorFunctionDirichletBC
    variable = velocity
    boundary = 'left_sediment'
    function_x = 0.
    function_y = 0.
    function_z = 0.
  []
  [rightnoslip]
    type = ADVectorFunctionDirichletBC
    variable = velocity
    boundary = 'right'
    function_x = 0.
    function_y = 0.
    function_z = 0.
  []
  [rightsedimentnoslip]
    type = ADVectorFunctionDirichletBC
    variable = velocity
    boundary = 'right_sediment'
    function_x = 0.
    function_y = 0.
    function_z = 0.
  []
  

[]

[Materials]
  [ice]
    type = ADIceMaterial
    block = 'eleblock1 eleblock2'
    velocity_x = "vel_x"
    velocity_y = "vel_y"
    velocity_z = "vel_z"
    pressure = "p"
  []
  [base]
    type = ADSedimentMaterial
    block = 'eleblock3'
    velocity_x = "vel_x"
    velocity_y = "vel_y"
    velocity_z = "vel_z"
    pressure = "p"
  []
  [ins_mat]
    type = INSADTauMaterial
    block = 'eleblock1 eleblock2 eleblock3'
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

[Functions]
  [ocean_pressure]
    type = ParsedFunction
    expression = 'if(z < 0, -1028 * 9.81 * z * 1e-6, 0)'
  []
  [weight]
    type = ParsedFunction
    expression = '917 * 9.81 * (100-z)  * 1e-6'
  []
[]

[Outputs]
  console = true
  [out]
    type = Exodus
  []
[]
