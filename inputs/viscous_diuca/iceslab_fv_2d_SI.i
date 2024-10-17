# ------------------------

# slope of the bottom boundary (in degrees)
bed_slope = 5.

# change coordinate system to add a slope
gravity_x = '${fparse sin(bed_slope / 180 * pi) * 9.81 }'
gravity_y = '${fparse - cos(bed_slope / 180 * pi) * 9.81}'

#  geometry of the ice slab
length = 1000.
thickness = 100.

# dt associated with rest time associated with the
# geometry (in seconds)
# ice has a high viscosity and hence response times
# of years
nb_years = 0.1
_dt = '${fparse nb_years * 3600 * 24 * 365}'

inlet_mph = 0.01 # mh-1
inlet_mps = '${fparse inlet_mph / 3600}' # ms-1

# ------------------------

# Numerical scheme parameters
velocity_interp_method = 'rc'
advected_interp_method = 'upwind'
vel_scaling = 1e-7

# Material properties
rho = 'rho'
mu = 'mu'

# ------------------------

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

[Mesh]
  type = GeneratedMesh
  dim = 2
  xmin = 0
  xmax = '${length}'
  ymin = 0
  ymax = '${thickness}'
  nx = 10
  ny = 5
  elem_type = QUAD4
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
    gravity = '${gravity_x} ${gravity_y} 0.'
  []
[]

[FVBCs]
  [inlet_x]
    type = INSFVInletVelocityBC
    variable = vel_x
    boundary = 'left'
    functor = '${inlet_mps}'
  []
  [inlet_y]
    type = INSFVInletVelocityBC
    variable = vel_y
    boundary = 'left'
    functor = 0
  []
  [noslip_x]
    type = INSFVNoSlipWallBC
    variable = vel_x
    boundary = 'bottom'
    function = 0
  []
  [noslip_y]
    type = INSFVNoSlipWallBC
    variable = vel_y
    boundary = 'bottom'
    function = 0
  []
  [freeslip_x]
    type = INSFVNaturalFreeSlipBC
    variable = vel_x
    boundary = 'top'
    momentum_component = 'x'
  []
  [freeslip_y]
    type = INSFVNaturalFreeSlipBC
    variable = vel_y
    boundary = 'top'
    momentum_component = 'y'
  []

  [outlet_p]
    type = INSFVOutletPressureBC
    variable = pressure
    boundary = 'right'
    functor = ocean_pressure
  []
[]

# ------------------------

[Functions]
  [ocean_pressure]
    type = ParsedFunction
    expression = '-1028 * 9.81 * ( ((thickness - y) * cos(bed_slope / 180 * pi)) )'
    symbol_names = 'bed_slope thickness'
    symbol_values = '${bed_slope} ${thickness}'
  []
[]

[FunctorMaterials]
  [ice]
    type = FVIceMaterialSI
    velocity_x = "vel_x"
    velocity_y = "vel_y"
    velocity_z = "vel_z"
    pressure = "pressure"
    output_properties = "mu rho"
    outputs = "out"
    II_eps_min = 1e-20
  []
[]

[AuxVariables]
  [vel_z]
    type = MooseVariableFVReal
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
      # petsc_options = '-ksp_monitor -ksp_view -ksp_converged_reason'
      petsc_options_iname = '-pc_fieldsplit_schur_fact_type  -pc_fieldsplit_schur_precondition  -ksp_gmres_restart -ksp_rtol -ksp_type'
      petsc_options_value = 'full                            selfp                              100                1e-4      fgmres'
    []
    [u]
      vars = 'vel_x vel_y'
      # petsc_options_iname = '-pc_type -pc_hypre_type -ksp_type -ksp_rtol -ksp_gmres_restart -ksp_pc_side'
      # petsc_options_value = 'hypre    boomeramg      gmres    5e-5      300                 right'
      # petsc_options = '-ksp_monitor -ksp_converged_reason -ksp_monitor_true_residual -ksp_monitor_singular_value'
      petsc_options_iname = '-pc_type -pc_factor_shift -pc_factor_mat_solver_type -pc_factor_pivot_in_blocks'
      petsc_options_value = 'lu       NONZERO          mumps                      true'
    []
    [p]
      vars = 'pressure'
      # petsc_options_iname = '-ksp_type -ksp_gmres_restart -ksp_rtol -pc_type -ksp_pc_side'
      # petsc_options_value = 'gmres    300                5e-1      jacobi    right'
      # petsc_options = '-ksp_monitor'
      petsc_options_iname = '-pc_type -pc_factor_shift'
      petsc_options_value = 'lu       NONZERO'
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
  num_steps = 10

  petsc_options_iname = '-pc_type -pc_factor_shift'
  petsc_options_value = 'lu       NONZERO'
  # petsc_options = '-pc_svd_monitor'
  # petsc_options_iname = '-pc_type'
  # petsc_options_value = 'svd'
  # petsc_options = '-pc_type fieldsplit -pc_fieldsplit_type schur -pc_fieldsplit_detect_saddle_point'
  # petsc_options = '--ksp_monitor'

  # nl_rel_tol = 1e-08
  # nl_abs_tol = 1e-13
  nl_rel_tol = 1e-07
  nl_abs_tol = 1e-07

  nl_max_its = 100
  nl_forced_its = 2
  # line_search = none

  # The scaling is not working as expected, makes the matrix worse
  # This is probably due to the lack of on-diagonals in pressure
  automatic_scaling = false
  # off_diagonals_in_auto_scaling = true
  # compute_scaling_once = false

  dt = '${_dt}'
  steady_state_detection = true
  steady_state_tolerance = 1e-100
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
