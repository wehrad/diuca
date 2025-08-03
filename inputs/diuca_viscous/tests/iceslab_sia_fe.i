# ------------------------

# slope of the bottom boundary (in degrees)
bed_slope = 10.

# change coordinate system to add a slope
gravity_x = '${fparse sin(bed_slope / 180 * pi) * 9.81 }'
gravity_y = '${fparse - cos(bed_slope / 180 * pi) * 9.81}'

length = 500.
thickness = 100.

nb_years = 0.008
_dt = '${fparse nb_years * 3600 * 24 * 365}'

# ------------------------

[GlobalParams]
  order = FIRST
  integrate_p_by_parts = true
[]

# 4288896. 2e14
[Functions]
  [viscosity_rampup]
    type = PiecewiseLinear
    xy_data = '252288. 1.5e12
               1261440. 9.72e12
               2522880. 5e13
               3279744. 1e14
               5550336. 1e15
               6054912. 2e15
               6307200. 5e15
               6559488. 1e16
               6811776. 2e16'
  []
[]

[Controls]
  [viscosity_rampup_control]
    type = RealFunctionControl
    parameter = 'Materials/ice/rampedup_viscosity'
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
    nx = 5
    ny = 75
    elem_type = QUAD8
  []
  # [pin_pressure_node]
  #   type = BoundingBoxNodeSetGenerator
  #   input = 'base_mesh'
  #   bottom_left = '-0.0001 -0.00001 0'
  #   top_right = '0.000001 0.000001 0'
  #   new_boundary = 'pressure_pin_node'
  # []
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
    rho_name = "rho_ice"
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
    mu_name = "mu_ice"
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
    type = ADIceMaterialSI_ru
    velocity_x = "vel_x"
    velocity_y = "vel_y"
    pressure = "p"
    output_properties = 'mu_ice rho_ice
                         sig_xx_dev sig_yy_dev
                         sig_zz_dev sig_xy_dev
                         sig_xz_dev sig_yz_dev'
    outputs = "out"
  []
  [ins_mat]
    type = INSADTauMaterial
    velocity = velocity
    pressure = p
    rho_name = "rho_ice"
    mu_name = "mu_ice"
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
  num_steps = 27

  petsc_options_iname = '-pc_type -pc_factor_shift_type'
  petsc_options_value = 'lu       NONZERO'

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
