# ------------------------

[Mesh]
  type = FileMesh
  # file = mesh_icestream_flat.e
  file = mesh_icestream.e
  second_order = true
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
    scaling = 1e-8
    initial_condition = 1e-8
  []
  [p]
  []
[]

[Kernels]
  [mass]
    type = INSADMass
    variable = p
  []
  [mass_stab]
    type = INSADMassPSPG
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

  # ice and sediment influx
  [inlet]
    type = ADVectorFunctionDirichletBC
    variable = velocity
    boundary = 'upstream upstream_sediment'
    function_x = "${inlet_mps}"
    function_y = 0.
    function_z = 0.
  []

  # no slip at the glacier base nor on the sides
  [noslip]
    type = ADVectorFunctionDirichletBC
    variable = velocity
    boundary = 'sediment left left_sediment right right_sediment'
    function_x = 0.
    function_y = 0.
    function_z = 0.
  []

  # ocean pressure at the glacier front
  [outlet_p]
    type = ADFunctionDirichletBC
    variable = p
    boundary = 'downstream downstream_sediment'
    function = ocean_pressure
  []
  
[]

[Materials]
  [ice]
    type = ADIceMaterialSI
    velocity_x = "vel_x"
    velocity_y = "vel_y"
    pressure = "p"
    output_properties = "mu"
    outputs = "out"
  []
  [ins_mat]
    type = INSADTauMaterial
    velocity = velocity
    pressure = p
  []
[]

[Functions]
  [ocean_pressure]
    type = ParsedFunction
    expression = 'if(z < 0, -1028 * 9.81 * z * 1e-6, 0)'
  []
[]

[Preconditioning]
  [SMP]
    type = SMP
    full = true
    solve_type = 'NEWTON'
    # petsc_options = '-pc_svd_monitor'
    # petsc_options_iname = '-pc_type'
    # petsc_options_value = 'svd'
    petsc_options_iname = '-pc_type -pc_factor_shift -pc_mat_solve_package'
    petsc_options_value = 'lu       NONZERO mumps'
  []
[]

[Executioner]
  type = Transient
  # num_steps = 10

  # nl_rel_tol = 1e-08
  # nl_abs_tol = 1e-13
  nl_rel_tol = 1e-07
  nl_abs_tol = 1e-07

  nl_max_its = 100
  line_search = none

  # The scaling is not working as expected, makes the matrix worse
  # This is probably due to the lack of on-diagonals in pressure
  automatic_scaling = false

  dt = "${_dt}"
  steady_state_detection = true
  steady_state_tolerance = 1e-100
[]

[Outputs]
  console = true
  [out]
    type = Exodus
  []
[]
