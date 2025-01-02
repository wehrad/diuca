# ------------------------

# slope of the bottom boundary (in degrees)
# bed_slope = 10.

#  geometry of the ice slab
# length = 1000.
# thickness = 100.

length = 500.
thickness = 100.

# dt associated with rest time associated with the
# geometry (in seconds)
# ice has a high viscosity and hence response times
# of years
nb_years = 0.01
_dt = '${fparse nb_years * 3600 * 24 * 365}'

# inlet_mph = 0.1 # mh-1
# inlet_mps = '${fparse inlet_mph / 3600}' # ms-1

# ------------------------

# Numerical scheme parameters
velocity_interp_method = 'rc'
advected_interp_method = 'upwind'

# velocity scaling
vel_scaling = 1e-7 

# Material properties
rho = 'rho_ice'
mu = 'mu_ice'

# Initial finite strain rate for viscosity rampup
initial_II_eps_min = 1e-07 # 1e-07

# ------------------------



[Functions]
  [viscosity_rampup]
    type = ParsedFunction
    expression = 'initial_II_eps_min * exp(-(t-_dt) * 5e-6)'
    symbol_names = '_dt initial_II_eps_min'
    symbol_values = '${_dt} ${initial_II_eps_min}'
  []
  [transform_x]
    type = ParsedFunction
    expression = 'x - length'
    symbol_names = 'length'
    symbol_values = '${length}'
  []
[]


[Controls]
  [II_eps_min_control]
    type = RealFunctionControl
    parameter = 'FunctorMaterials/ice/II_eps_min'
    function = 'viscosity_rampup'
    execute_on = 'initial timestep_begin'
  []
[]

[GlobalParams]
  rhie_chow_user_object = 'rc'
[]

[UserObjects]
  [rc]
    type = INSFVRhieChowInterpolator
    u = vel_x
    v = vel_y
    pressure = pressure
  []
[]

[Mesh]
  [pcg1]
    type = ParsedCurveGenerator
    x_formula = 't'
    y_formula = 'thickness - 0.05 * t'
    constant_names = 'length thickness'
    constant_expressions = '${length} ${thickness}'
    section_bounding_t_values = '0 ${length}'
    nums_segments = 50
  []
  [pcg2]
    type = ParsedCurveGenerator
    x_formula = 't'
    y_formula = '0 - 0.05 * t'
    constant_names = 'length thickness'
    constant_expressions = '${length} ${thickness}'
    section_bounding_t_values = '0 ${length}'
    nums_segments = 50
  []
  [fbcg]
    type = FillBetweenCurvesGenerator
    input_mesh_1 = pcg1
    input_mesh_2 = pcg2
    num_layers = 20
    bias_parameter = 0.0
    begin_side_boundary_id = 0
    use_quad_elements = true
  []

  [add_bottom]
    type = ParsedGenerateNodeset
    input = fbcg
    expression = 'y = 0 - 0.05 * x'
    new_nodeset_name = 'bottom'
  []
  [add_top]
    type = ParsedGenerateNodeset
    input = add_bottom
    expression = 'y = thickness - 0.05 * x'
    constant_names = 'thickness'
    constant_expressions = '${thickness}'
    new_nodeset_name = 'top'
  []
  [add_left]
    type = ParsedGenerateNodeset
    input = add_top
    expression = 'x = 0'
    new_nodeset_name = 'left'
  []
  [add_right]
    type = ParsedGenerateNodeset
    input = add_left
    expression = 'x = length'
    constant_names = 'length'
    constant_expressions = '${length}'
    new_nodeset_name = 'right'
  []

  construct_side_list_from_node_list=true
[]


[Variables]
  [vel_x]
    type = INSFVVelocityVariable
    two_term_boundary_expansion = true
    scaling = ${vel_scaling}
  []
  [vel_y]
    type = INSFVVelocityVariable
    two_term_boundary_expansion = true
    scaling = ${vel_scaling}
  []
  [pressure]
    type = INSFVPressureVariable
    two_term_boundary_expansion = true
    # scaling = ${vel_scaling}
  []
[]

[FVKernels]
  [mass]
    type = INSFVMassAdvection
    variable = pressure
    advected_interp_method = ${advected_interp_method}
    velocity_interp_method = ${velocity_interp_method}
    rho = ${rho}
  []

  [u_time]
    type = INSFVMomentumTimeDerivative
    variable = vel_x
    rho = ${rho}
    momentum_component = 'x'
  []
  [u_advection]
    type = INSFVMomentumAdvection
    variable = vel_x
    advected_interp_method = ${advected_interp_method}
    velocity_interp_method = ${velocity_interp_method}
    rho = ${rho}
    momentum_component = 'x'
  []
  [u_viscosity]
    type = INSFVMomentumDiffusion
    variable = vel_x
    mu = ${mu}
    momentum_component = 'x'
  []
  [u_pressure]
    type = INSFVMomentumPressure
    variable = vel_x
    pressure = pressure
    momentum_component = 'x'
  []
  [u_gravity]
    type = INSFVMomentumGravity
    variable = vel_x
    momentum_component = 'x'
    rho = ${rho}
    gravity = '0. -9.81 0.'
  []

  [v_time]
    type = INSFVMomentumTimeDerivative
    variable = vel_y
    rho = ${rho}
    momentum_component = 'y'
  []
  [v_advection]
    type = INSFVMomentumAdvection
    variable = vel_y
    advected_interp_method = ${advected_interp_method}
    velocity_interp_method = ${velocity_interp_method}
    rho = ${rho}
    momentum_component = 'y'
  []
  [v_viscosity]
    type = INSFVMomentumDiffusion
    variable = vel_y
    mu = ${mu}
    momentum_component = 'y'
  []
  [v_pressure]
    type = INSFVMomentumPressure
    variable = vel_y
    pressure = pressure
    momentum_component = 'y'
  []
  [v_gravity]
    type = INSFVMomentumGravity
    variable = vel_y
    momentum_component = 'y'
    rho = ${rho}
    gravity = '0. -9.81 0.'
  []

[]

[FVBCs]
  # [periodic_vel_x]
  #   type = FVADFunctorDirichletBC
  #   variable = vel_x
  #   boundary = 'right'
  #   functor = transformed_vel_x
  # []
  # [periodic_vel_y]
  #   type = FVADFunctorDirichletBC
  #   variable = vel_y
  #   boundary = 'right'
  #   functor = transformed_vel_y
  # []
  # [periodic_pressure]
  #   type = FVADFunctorDirichletBC
  #   variable = pressure
  #   boundary = 'right'
  #   functor = transformed_pressure
  # []

  [noslip_x]
    type = INSFVNoSlipWallBC
    variable = vel_x
    boundary = 'bottom'
    function = 0
  []

  [noslip_y]
    type = INSFVNoSlipWallBC
    variable = vel_y
    boundary = 'bottom' # bottom
    function = 0
  []
  
  # [freeslip_x]
  #   type = INSFVNaturalFreeSlipBC
  #   variable = vel_x
  #   boundary = 'top'
  #   momentum_component = 'x'
  # []
  # [freeslip_y]
  #   type = INSFVNaturalFreeSlipBC
  #   variable = vel_y
  #   boundary = 'top'
  #   momentum_component = 'y'
  # []

  # [outlet_p]
  #   type = INSFVOutletPressureBC
  #   variable = pressure
  #   boundary = 'right'
  #   functor = ocean_pressure
  # []

[]

[FunctorMaterials]
  [ice]
    type = FVIceMaterialSI
    velocity_x = "vel_x"
    velocity_y = "vel_y"
    pressure = "pressure"
    output_properties = 'mu_ice rho_ice eps_xx eps_yy sig_xx sig_yy eps_xy sig_xy'
    outputs = "out"
  []
  [translate_vel_x]
    type = ADFunctorTransformFunctorMaterial
    prop_names = 'transformed_vel_x'
    prop_values = 'vel_x'
    x_functor = 'transform_x'
  []
  [translate_vel_y]
    type = ADFunctorTransformFunctorMaterial
    prop_names = 'transformed_vel_y'
    prop_values = 'vel_y'
    x_functor = 'transform_x'
  []
  # [translate_pressure]
  #   type = ADFunctorTransformFunctorMaterial
  #   prop_names = 'transformed_pressure'
  #   prop_values = 'pressure'
  #   x_functor = 'transform_x'
  # []
[]

[Preconditioning]
  active = ''
  [FSP]
    type = FSP
    # It is the starting point of splitting
    topsplit = 'up' # 'up' should match the following block name
    [up]
      splitting = 'u p' # 'u' and 'p' are the names of subsolvers
      splitting_type = schur
      # Splitting type is set as schur, because the pressure part of Stokes-like systems
      # is not diagonally dominant. CAN NOT use additive, multiplicative and etc.
      #
      # Original system:
      #
      # | Auu Aup | | u | = | f_u |
      # | Apu 0   | | p |   | f_p |
      #
      # is factorized into
      #
      # |I             0 | | Auu  0|  | I  Auu^{-1}*Aup | | u | = | f_u |
      # |Apu*Auu^{-1}  I | | 0   -S|  | 0  I            | | p |   | f_p |
      #
      # where
      #
      # S = Apu*Auu^{-1}*Aup
      #
      # The preconditioning is accomplished via the following steps
      #
      # (1) p* = f_p - Apu*Auu^{-1}f_u,
      # (2) p = (-S)^{-1} p*
      # (3) u = Auu^{-1}(f_u-Aup*p)
      petsc_options = '-pc_fieldsplit_detect_saddle_point'
      petsc_options_iname = '-pc_fieldsplit_schur_fact_type  -pc_fieldsplit_schur_precondition -ksp_gmres_restart -ksp_rtol -ksp_type'
      petsc_options_value = 'full                            selfp                             300                1e-4      fgmres'
    []
    [u]
      vars = 'vel_x vel_y'
      petsc_options_iname = '-pc_type -pc_hypre_type -ksp_type -ksp_rtol -ksp_gmres_restart -ksp_pc_side'
      petsc_options_value = 'hypre    boomeramg      gmres    5e-1      300                 right'
    []
    [p]
      vars = 'pressure'
      petsc_options_iname = '-ksp_type -ksp_gmres_restart -ksp_rtol -pc_type -ksp_pc_side'
      petsc_options_value = 'gmres    300                5e-1      jacobi    right'
    []
  []
  [SMP]
    type = SMP
    full = true
    petsc_options_iname = '-pc_type -pc_factor_shift_type'
    petsc_options_value = 'lu       NONZERO'
  []
[]

[Executioner]
  type = Transient
  num_steps = 100

  petsc_options_iname = '-pc_type -pc_factor_shift_type'
  petsc_options_value = 'lu       NONZERO'
  
  # petsc_options = '-pc_svd_monitor'
  # petsc_options_iname = '-pc_type'
  # petsc_options_value = 'svd'
  # petsc_options = '-pc_type fieldsplit -pc_fieldsplit_type schur -pc_fieldsplit_detect_saddle_point'
  # petsc_options = '--ksp_monitor'

  # nl_rel_tol = 1e-08
  # nl_abs_tol = 1e-13
  # nl_rel_tol = 1e-07

  # nl_abs_tol = 2e-06
  nl_abs_tol = 2e-05

  # l_tol = 1e-6
  l_tol = 1e-4

  nl_max_its = 100
  nl_forced_its = 3
  line_search = none

  dt = '${_dt}'
  # steady_state_detection = true
  # steady_state_tolerance = 1e-100
  check_aux = true
 
[]

[Outputs]
  console = true
  [out]
    type = Exodus
  []
[]

[Debug]
  show_var_residual_norms = true
[]
