# ------------------------

# slope of the bottom boundary (in degrees)
bed_slope = 10.

# change coordinate system to add a slope
gravity_x = '${fparse sin(bed_slope / 180 * pi) * 9.81}'
gravity_y = '${fparse - cos(bed_slope / 180 * pi) * 9.81}'

#  geometry of the ice slab
# length = 1000.
# thickness = 100.

length = 1000.
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
advected_interp_method = 'upwind' #upwind

# velocity scaling
vel_scaling = 1e-07

# Material properties
rho = 'rho_ice'
mu = 'mu_ice'

# Initial finite strain rate for viscosity rampup
initial_II_eps_min = 1e-15

# ------------------------

[Functions]
  [pressure_pin]
    type = ParsedFunction
    expression = '917*9.81*sin(100-y)' # 1e5' # ''
  []
  [viscosity_rampup]
    type = ParsedFunction
    expression = 'initial_II_eps_min * exp(-(t-_dt) * 5e-6)'
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
  [base_mesh]
    type = GeneratedMeshGenerator
    dim = 2
    xmin = 0
    xmax = '${length}'
    ymin = 0
    ymax = '${thickness}'
    nx = 80 # 60
    ny = 60 # 60
    elem_type = QUAD9
  []
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
    gravity = '${gravity_x} ${gravity_y} 0.'
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
    gravity = '${gravity_x} ${gravity_y} 0.'
  []

[]


[FVBCs]

  [free_slip_x]
    type = INSFVNaturalFreeSlipBC
    variable = vel_x
    momentum_component = 'x'
    boundary = 'top'
  []
  [free_slip_y]
    type = INSFVNaturalFreeSlipBC
    variable = vel_y
    momentum_component = 'y'
    boundary = 'top'
  []

  [noslip_x]
    type = INSFVNoSlipWallBC
    variable = vel_x
    boundary = 'bottom'
    function = 0.
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

  [outlet_p]
    type = INSFVOutletPressureBC
    variable = pressure
    boundary = 'right'
    functor = pressure_pin
  []
  [inlet_p]
    type = INSFVOutletPressureBC
    variable = pressure
    boundary = 'left'
    functor = pressure_pin
  []
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
[]

[Preconditioning]
  active = 'FSP'
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

  nl_abs_tol = 2e-05
  l_tol = 1e-4

  nl_max_its = 100
  nl_forced_its = 3
  line_search = none

  # l_tol = 1e-6
  # nl_rel_tol = 1e-05
  # nl_abs_tol = 1e-05

  steady_state_detection = true
  steady_state_tolerance = 1e-10

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
