# based on modules/navier_stokes/test/tests/finite_element/ins/RZ_cone/ad_rz_cone_by_parts_steady_stabilized.i

[GlobalParams]
  order = FIRST
  integrate_p_by_parts = true
[]

[Mesh]
  type = GeneratedMesh
  dim = 2
  xmin = 0
  xmax = 1
  ymin = 0
  ymax = 1
  nx = 1
  ny = 1
  elem_type = QUAD9
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
  # Not needed as v and are p not equal order (check)
  # [mass_pspg]
  #   type = INSADMassPSPG
  #   variable = p
  # []

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
[]

[BCs]
  # Classic NS setup
  # [inlet]
  #   type = VectorFunctionDirichletBC
  #   variable = velocity
  #   boundary = 'bottom'
  #   function_x = 0
  #   function_y = 1.
  # []
  # [outlet]
  #   type = DirichletBC
  #   variable = p
  #   boundary = right
  #   value = 0
  # []
  # [inlet2]
  #   type = VectorFunctionDirichletBC
  #   variable = velocity
  #   boundary = 'top'
  #   function_x = 0
  #   function_y = -1.
  # []
  # [axis]
  #   type = ADVectorFunctionDirichletBC
  #   variable = velocity
  #   boundary = 'left'
  #   function_x = 0.
  #   function_y = 0.
  #   # set_y_comp = false
  #   # set_x_comp = false
  # []

  # Pressure on top and bottom
  # Seems more like a mechanics setup to me
  [outlet]
    type = DirichletBC
    variable = p
    boundary = 'top bottom'
    value = 10. # MPa
  []
  [axis]
    type = ADVectorFunctionDirichletBC
    variable = velocity
    boundary = 'left'
    function_x = 0.
    function_y = 0.
    # set_y_comp = false
    # set_x_comp = false
  []
[]

[Materials]
  # [constant_ice]
  #   type = ADGenericConstantMaterial
  #   prop_names = 'rho mu'
  #   prop_values = '0.917 0.3' # kg.m-3 MPa.a
  # []
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

# [Executioner]
#   type = Transient
#   num_steps = 10

#   # petsc_options_iname = '-pc_type -pc_factor_shift -pc_mat_solve_package'
#   # petsc_options_value = 'lu       NONZERO mumps'
#   petsc_options = '-pc_svd_monitor'
#   petsc_options_iname = '-pc_type'
#   petsc_options_value = 'svd'

#   nl_rel_tol = 1e-08
#   nl_abs_tol = 1e-13
#   nl_max_its = 40
#   line_search = none

#   automatic_scaling = true
# []

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

  # dt = "${_dt}"
  dt = 0.1 # years
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
