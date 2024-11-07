# ------------------------ simulation settings

nb_years = 0.075
mult = 0.5
_dt = '${fparse nb_years * 3600 * 24 * 365 * mult}'

# Numerical scheme parameters
velocity_interp_method = 'rc'
advected_interp_method = 'upwind'

# velocity scaling
vel_scaling = 1e-6

# Material properties
rho = 'rho_ice'
mu = 'mu_ice'

# Initial finite strain rate for viscosity rampup
initial_II_eps_min = 1e-07

# ------------------------

[Problem]
  type = FEProblem
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
  type = GeneratedMesh
  dim = 2
  xmin = 0
  xmax = 0.333
  ymin = 0
  ymax = 1
  nx = 1
  ny = 3
  elem_type = QUAD9
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
  # [u_gravity]
  #   type = INSFVMomentumGravity
  #   variable = vel_x
  #   rho = ${rho}
  #   momentum_component = 'x'
  #   gravity = '0 -9.81 0'
  # []
 
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
  # [v_buoyant]
  #   type = INSFVMomentumGravity
  #   variable = vel_y
  #   rho = ${rho}
  #   momentum_component = 'y'
  #   gravity = '0 -9.81 0'
  # []

[]

[FVBCs]
  
  [compression_bottom_yy]
    type = INSFVStressMomentumFluxBC
    variable = vel_y
    momentum_component='y'
    boundary = 'bottom'
    value = 1e6
  []
  [compression_bottom_xx]
    type = INSFVStressMomentumFluxBC
    variable = vel_x
    momentum_component='x'
    boundary = 'bottom'
    value = 0.
  []
  [compression_bottom_xy]
    type = INSFVStressMomentumFluxBC
    variable = vel_x
    momentum_component='y'
    boundary = 'bottom'
    value = 0.
  []
  
  [compression_top_yy]
    type = INSFVStressMomentumFluxBC
    variable = vel_y
    momentum_component='y'
    boundary = 'top'
    value = -1e6
  []
  [compression_top_xx]
    type = INSFVStressMomentumFluxBC
    variable = vel_x
    momentum_component='x'
    boundary = 'top'
    value = 0.
  []
  [compression_top_xy]
    type = INSFVStressMomentumFluxBC
    variable = vel_x
    momentum_component='y'
    boundary = 'top'
    value = 0.
  []
  
[]


[Functions]
  [viscosity_rampup]
    type = ParsedFunction
    expression = 'initial_II_eps_min * exp(-(t-_dt) * 1e-6)'
    symbol_names = '_dt initial_II_eps_min'
    symbol_values = '${_dt} ${initial_II_eps_min}'
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

[FunctorMaterials]
  [ice]
    type = FVIceMaterialSI
    block = '0' #  10
    velocity_x = "vel_x"
    velocity_y = "vel_y"
    pressure = "pressure"
    output_properties = 'mu_ice rho_ice eps_xx eps_yy sig_xx sig_yy eps_xy sig_xy'
    outputs = "out"
  []

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
  l_tol = 1e-5

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
