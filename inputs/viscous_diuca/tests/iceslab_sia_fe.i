# ------------------------

# slope of the bottom boundary (in degrees)
bed_slope = 10.

# change coordinate system to add a slope
gravity_x = '${fparse sin(bed_slope / 180 * pi) * 9.81 }'
gravity_y = '${fparse - cos(bed_slope / 180 * pi) * 9.81}'

#  geometry of the ice slab
# length = 1000.
# thickness = 100.

length = 500.
thickness = 100.

# dt associated with rest time associated with the
# geometry (in seconds)
# ice has a high viscosity and hence response times
# of years
nb_years = 0.01 # 0.1
_dt = '${fparse nb_years * 3600 * 24 * 365}'

# inlet_mph = 0.01 # mh-1
# inlet_mps = ${fparse
#              inlet_mph / 3600
#             } # ms-1

# initial_II_eps_min = 1e-22 constant
# initial_II_eps_min = 1e-07 decay = 2e-6 was the safest
# initial_II_eps_min = 1e-07 decay = 1e-5 aggressive

initial_II_eps_min = 1e-07

# Material properties
rho = 'rho_ice'
mu = 'mu_ice'

# ------------------------

[Functions]
  # [ocean_pressure]
  #   type = ParsedFunction
  #   expression = 'if(z < 0, 1e5 -1028 * 9.81 * z, 1e5)' # -1e5 * 9.81 * z)'
  # []
  [viscosity_rampup]
    type = ParsedFunction
    expression = 'initial_II_eps_min * exp(-(t-_dt) * 5e-6)' # 3e-6 # 2e-6
    # expression = 'initial_II_eps_min'
    symbol_names = '_dt initial_II_eps_min'
    symbol_values = '${_dt} ${initial_II_eps_min}'
  []
  # [influx]
  #   type = ParsedFunction
  #   expression = 'inlet_mps * sin((2*pi / 20000) * y)'
  #   symbol_names = 'inlet_mps'
  #   symbol_values = '${inlet_mps}'
  # []
[]

[Controls]
  [II_eps_min_control]
    type = RealFunctionControl
    parameter = 'Materials/ice/II_eps_min'
    function = 'viscosity_rampup'
    execute_on = 'initial timestep_begin'
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
    nx = 50
    ny = 20
    elem_type = QUAD9
  []
  # [pin_pressure_node]
  #   type = BoundingBoxNodeSetGenerator
  #   input = 'base_mesh'
  #   bottom_left = '-0.0001 -0.00001 0'
  #   top_right = '0.000001 0.000001 0'
  #   new_boundary = 'pressure_pin_node'
  # []
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
    # scaling = 1e-6
    scaling = 1e6
    # initial_condition = 1e-6
  []
  [p]
    scaling = 1e6
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
    rho_name = ${rho}
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
    mu_name = ${mu}
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
    [up_down_velocity]
      primary = left
      secondary = right
      translation = '${length} 0 0'
      variable = 'velocity'
    []
    [up_down_p]
      primary = left
      secondary = right
      translation = '${length} 0 0'
      variable = 'p'
    []
  []

  # we need to pin the pressure to remove the singular value
  #[pin_pressure]
  #  type = DirichletBC
  #  variable = p
  #  boundary = 'pressure_pin_node'
  #  value = 1e5
  #[]

  # [inlet]
  #   type = ADVectorFunctionDirichletBC
  #   variable = velocity
  #   boundary = 'left'
  #   # function_x = "${inlet_mps}"
  #   function_x=0
  #   # function_y = 0.
  # []
  [noslip]
    type = ADVectorFunctionDirichletBC
    variable = velocity
    boundary = 'bottom'
    function_x = 1e-7 # "${inlet_mps}"
    function_y = 0.
    # set_x_comp = False
  []

  # [oulet]
  #   type = ADFunctionDirichletBC
  #   variable = p
  #   boundary = 'right'
  #   function = ocean_pressure
  # []
  # [freesurface]
  #   type = INSADMomentumNoBCBC
  #   variable = velocity
  #   pressure = p
  #   boundary = 'top'
  # []
  
[]

[Materials]
  [ice]
    type = ADIceMaterialSI
    velocity_x = "vel_x"
    velocity_y = "vel_y"
    pressure = "p"
    output_properties = "rho_ice mu_ice"
    outputs = "out"
  []
  [ins_mat]
    type = INSADTauMaterial
    velocity = velocity
    pressure = p
    rho_name = ${rho}
    mu_name = ${mu}
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
      vars = 'p'
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

  # l_tol = 1e-6
  l_tol = 1e-6

  # nl_rel_tol = 1e-04 in the initial SSA test
  # nl_abs_tol = 1e-04

  nl_rel_tol = 1e-05
  nl_abs_tol = 1e-05

  nl_max_its = 100
  nl_forced_its = 3
  line_search = none

  dt = '${_dt}'
  steady_state_detection = true
  steady_state_tolerance = 1e-10
  check_aux = true
 
[]

[Outputs]
  console = true
  [out]
    type = Exodus
  []
[]
