# ------------------------ simulation settings

nb_years = 0.008 # 0.01
_dt = '${fparse nb_years * 3600 * 24 * 365}'

inlet_mph = 0.3 # 0.37 # mh-1
inlet_mps = ${fparse
             inlet_mph / 3600
            } # ms-1

# Mercenier et al 2019: 1.9e-13
initial_II_eps_min = 1e-07
# initial_II_eps_min = 1e-13

# ------------------------

[GlobalParams]
  order = FIRST
  # https://github.com/idaholab/moose/discussions/26157
  # integrate_p_by_parts = false
  integrate_p_by_parts = true
[]

[Mesh]

  [channel]
    type = FileMeshGenerator
    file = generate_iceblock_mesh_out.e
  []
[]

[Functions]
  [viscosity_rampup]
    type = ParsedFunction
    expression = 'initial_II_eps_min * exp(-(t-_dt) * 4e-6)' # 5e-6
    # expression = 'initial_II_eps_min'
    symbol_names = '_dt initial_II_eps_min'
    symbol_values = '${_dt} ${initial_II_eps_min}'
  []
  [influx]
    type = ParsedFunction
    # expression = 'inlet_mps * sin((2*pi / 20000) * y)' # * (z / 433.2)'
    expression = 'inlet_mps'
    symbol_names = 'inlet_mps'
    symbol_values = '${inlet_mps}'
  []
  [ocean_pressure_coupled_force]
    type = ParsedVectorFunction
    expression_x = 'if(z < 0 & x > 19800, 1028 * 9.81 * z, 0)'
  []
[]

[Controls]
  [II_eps_min_control]
    type = RealFunctionControl
    parameter = 'Materials/ice/II_eps_min'
    function = 'viscosity_rampup'
    execute_on = 'initial timestep_begin'
  []
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
    scaling = 1e-6
  []
  [p]
    family = LAGRANGE
  []
[]

[Kernels]
  [mass_ice]
    type = INSADMass
    variable = p
  []
  [mass_stab_ice_ice]
    type = INSADMassPSPG
    variable = p
    rho_name = "rho_ice"
  []
  [momentum_time_ice]
    type = INSADMomentumTimeDerivative
    variable = velocity
  []
  [momentum_advection_ice]
    type = INSADMomentumAdvection
    variable = velocity
  []
  [momentum_viscous_ice]
    type = INSADMomentumViscous
    variable = velocity
    mu_name = "mu_ice"
  []
  [momentum_pressure_ice]
    type = INSADMomentumPressure
    variable = velocity
    pressure = p
  []
  [momentum_supg_ice]
    type = INSADMomentumSUPG
    variable = velocity
    velocity = velocity
  []
  [gravity_ice]
    type = INSADGravityForce
    variable = velocity
    gravity = '0. 0. -9.81'
  []

  [hydrostatic_pressure_ice]
    type = INSADMomentumCoupledForce
    variable = velocity
    vector_function = 'ocean_pressure_coupled_force'
  []
[]

[BCs]

  [no_slip_sides]
    type = ADVectorFunctionDirichletBC
    variable = velocity
    boundary = 'left right bottom'
    # function_x = 0.
    function_y = 0.
    function_z = 0.
    set_x_comp = false
  []

  [inlet]
    type = ADVectorFunctionDirichletBC
    variable = velocity
    boundary = 'back' 
    function_x = influx
    function_y = 0.
    function_z = 0.
  []

  [front_pressure]
    type = INSADHydrostaticPressureBC
    boundary = 'front'
    variable = velocity
    pressure = p
    mu_name = "mu_ice"
  []

  # [freesurface]
  #   type = INSADMomentumNoBCBC
  #   variable = velocity
  #   pressure = p
  #   boundary = 'surface'
  #   mu_name = "mu_ice"
  # []
[]

[Materials]
  [ice]
    type = ADIceMaterialSI
    velocity_x = "vel_x"
    velocity_y = "vel_y"
    velocity_z = "vel_z"
    pressure = "p"
    output_properties = 'mu_ice rho_ice'
    outputs = "out"
  []

  [ins_mat_ice]
    type = INSADTauMaterial
    velocity = velocity
    pressure = p
    rho_name = "rho_ice"
    mu_name = "mu_ice"
  []

[]

# [Preconditioning]
#   active = 'SMP'
#   [FSP]
#     type = FSP
#     # It is the starting point of splitting
#     topsplit = 'up' # 'up' should match the following block name
#     [up]
#       splitting = 'u p' # 'u' and 'p' are the names of subsolvers
#       splitting_type = schur
#       # Splitting type is set as schur, because the pressure part of Stokes-like systems
#       # is not diagonally dominant. CAN NOT use additive, multiplicative and etc.
#       #
#       # Original system:
#       #
#       # | Auu Aup | | u | = | f_u |
#       # | Apu 0   | | p |   | f_p |
#       #
#       # is factorized into
#       #
#       # |I             0 | | Auu  0|  | I  Auu^{-1}*Aup | | u | = | f_u |
#       # |Apu*Auu^{-1}  I | | 0   -S|  | 0  I            | | p |   | f_p |
#       #
#       # where
#       #
#       # S = Apu*Auu^{-1}*Aup
#       #
#       # The preconditioning is accomplished via the following steps
#       #
#       # (1) p* = f_p - Apu*Auu^{-1}f_u,
#       # (2) p = (-S)^{-1} p*
#       # (3) u = Auu^{-1}(f_u-Aup*p)
#       petsc_options = '-pc_fieldsplit_detect_saddle_point'
#       petsc_options_iname = '-pc_fieldsplit_schur_fact_type  -pc_fieldsplit_schur_precondition -ksp_gmres_restart -ksp_rtol -ksp_type'
#       petsc_options_value = 'full                            selfp                             300                1e-4      fgmres'
#     []
#     [u]
#       vars = 'vel_x vel_y vel_z'
#       petsc_options_iname = '-pc_type -pc_hypre_type -ksp_type -ksp_rtol -ksp_gmres_restart -ksp_pc_side'
#       petsc_options_value = 'hypre    boomeramg      gmres    5e-1      300                 right'
#     []
#     [p]
#       vars = 'p'
#       petsc_options_iname = '-ksp_type -ksp_gmres_restart -ksp_rtol -pc_type -ksp_pc_side'
#       petsc_options_value = 'gmres    300                5e-1      jacobi    right'
#     []
#   []
#   [SMP]
#     type = SMP
#     full = true
#     petsc_options_iname = '-pc_type -pc_factor_shift_type'
#     petsc_options_value = 'lu       NONZERO'
#   []
# []

[Executioner]
  type = Transient
  num_steps = 50

  # petsc_options_iname = '-pc_type -pc_factor_shift_type'
  # petsc_options_value = 'lu       NONZERO'
  
  petsc_options = '-pc_svd_monitor'
  petsc_options_iname = '-pc_type'
  petsc_options_value = 'svd'
  
  l_tol = 1e-6

  nl_rel_tol = 1e-05
  nl_abs_tol = 1e-05

  nl_max_its = 100 # 50 # 100
  nl_forced_its = 3
  line_search = none

  dt = '${_dt}'

  steady_state_detection = true
  steady_state_tolerance = 1e-10

  check_aux = true

[]

[Outputs]
  checkpoint = true
  perf_graph = true
  console = true
  [out]
    type = Exodus
  []
[]

