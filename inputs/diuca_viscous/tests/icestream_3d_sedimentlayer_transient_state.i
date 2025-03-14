# ------------------------ domain settings

# sediment rheology
# sliding_law = "GudmundssonRaymond"
sediment_layer_thickness = 50.
slipperiness_coefficient_mmpaa = 3e3 # 3e3
slipperiness_coefficient = '${fparse (slipperiness_coefficient_mmpaa * 1e-6) / (365*24*3600)}' # 

slipperiness_coefficient_center_mmpaa = 3e5
slipperiness_coefficient_center = '${fparse (slipperiness_coefficient_center_mmpaa * 1e-6) / (365*24*3600)}' # 

# ------------------------ simulation settings


# dt associated with rest time associated with the
# geometry (in seconds)
# ice has a high viscosity and hence response times
# of years
# nb_years = 0.075
# # mult = 1
# # mult = 0.5
# mult = 0.5
# _dt = '${fparse nb_years * 3600 * 24 * 365 * mult}'
nb_years = 0.008 # 0.01
_dt = '${fparse nb_years * 3600 * 24 * 365}'

inlet_mph = 0.4 # 0.7 # mh-1
inlet_mps = ${fparse
             inlet_mph / 3600
            } # ms-1

# initial_file = 'icestream_3d_newsed_fe_steady_out.e'
initial_file = 'icestream_3d_newsed_fe_steady_out_cp/0017-mesh.cpa.gz'
initial_II_eps_min = 1.10477e-18

# ------------------------

[GlobalParams]
  order = FIRST
  # https://github.com/idaholab/moose/discussions/26157
  # integrate_p_by_parts = true
  integrate_p_by_parts = false
[]

[Problem]
  #Note that the suffix is left off in the parameter below.
  restart_file_base = icestream_3d_newsed_fe_steady_out_cp/LATEST  # You may also use a specific number here
[]

[Mesh]
  file = ${initial_file}
[]

[Functions]
  [ocean_pressure]
    type = ParsedFunction
    expression = 'if(z < 0, -1028 * 9.81 * z, 1e5)' # -1e5 * 9.81 * z)'
    # expression = '917 * 9.81 * (100 - z)' # -1e5 * 9.81 * z)'
  []
  [viscosity_rampup]
    type = ParsedFunction
    expression = 'initial_II_eps_min'
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
    initial_from_file_var = vel_x
  []
  [vel_y]
    initial_from_file_var = vel_y
  []
  [vel_z]
    initial_from_file_var = vel_z
  []
[]

[AuxKernels]
  [vel_x]
    type = VectorVariableComponentAux
    variable = vel_x
    vector_variable = velocity
    component = 'x'
    block = '1 0 255 254'
  []
  [vel_y]
    type = VectorVariableComponentAux
    variable = vel_y
    vector_variable = velocity
    component = 'y'
    block = '1 0 255 254'
  []
  [vel_z]
    type = VectorVariableComponentAux
    variable = vel_z
    vector_variable = velocity
    component = 'z'
    block = '1 0 255 254'
  []
[]

[Variables]
  [velocity]
    family = LAGRANGE_VEC
    scaling = 1e-6
    block = '1 0 255 254'
    # initial_from_file_var = "velocity_x velocity_y velocity_z"
  []
  [p]
    family = LAGRANGE
    block = '1 0 255 254'
    initial_from_file_var = p
  []
[]

[Kernels]
  [mass_ice]
    type = INSADMass
    block = '1 255'
    variable = p
  []
  [mass_stab_ice_ice]
    type = INSADMassPSPG
    block = '1 255'
    variable = p
    rho_name = "rho_ice"
  []
  [momentum_time_ice]
    type = INSADMomentumTimeDerivative
    block = '1 255'
    variable = velocity
  []
  [momentum_advection_ice]
    type = INSADMomentumAdvection
    block = '1 255'
    variable = velocity
  []
  [momentum_viscous_ice]
    type = INSADMomentumViscous
    block = '1 255'
    variable = velocity
    mu_name = "mu_ice"
  []
  [momentum_pressure_ice]
    type = INSADMomentumPressure
    block = '1 255'
    variable = velocity
    pressure = p
  []
  [momentum_supg_ice]
    type = INSADMomentumSUPG
    block = '1 255'
    variable = velocity
    velocity = velocity
  []
  [gravity_ice]
    type = INSADGravityForce
    block = '1 255'
    variable = velocity
    gravity = '0. 0. -9.81'
  []

  [mass_sediment]
    type = INSADMass
    block = '0'
    variable = p
  []
  [mass_stab_sediment_sediment]
    type = INSADMassPSPG
    block = '0'
    variable = p
    rho_name = "rho_sediment"
  []
  [momentum_time_sediment]
    type = INSADMomentumTimeDerivative
    block = '0'
    variable = velocity
  []
  [momentum_advection_sediment]
    type = INSADMomentumAdvection
    block = '0'
    variable = velocity
  []
  [momentum_viscous_sediment]
    type = INSADMomentumViscous
    block = '0'
    variable = velocity
    mu_name = "mu_sediment"
  []
  [momentum_pressure_sediment]
    type = INSADMomentumPressure
    block = '0'
    variable = velocity
    pressure = p
  []
  [momentum_supg_sediment]
    type = INSADMomentumSUPG
    block = '0'
    variable = velocity
    velocity = velocity
  []
  [gravity_sediment]
    type = INSADGravityForce
    block = '0'
    variable = velocity
    gravity = '0. 0. -9.81'
  []

  [mass_floodedsediment]
    type = INSADMass
    block = '254'
    variable = p
  []
  [mass_stab_floodedsediment_floodedsediment]
    type = INSADMassPSPG
    block = '254'
    variable = p
    rho_name = "rho_floodedsediment"
  []
  [momentum_time_floodedsediment]
    type = INSADMomentumTimeDerivative
    block = '254'
    variable = velocity
  []
  [momentum_advection_floodedsediment]
    type = INSADMomentumAdvection
    block = '254'
    variable = velocity
  []
  [momentum_viscous_floodedsediment]
    type = INSADMomentumViscous
    block = '254'
    variable = velocity
    mu_name = "mu_floodedsediment"
  []
  [momentum_pressure_floodedsediment]
    type = INSADMomentumPressure
    block = '254'
    variable = velocity
    pressure = p
  []
  [momentum_supg_floodedsediment]
    type = INSADMomentumSUPG
    block = '254'
    variable = velocity
    velocity = velocity
  []
  [gravity_floodedsediment]
    type = INSADGravityForce
    block = '254'
    variable = velocity
    gravity = '0. 0. -9.81'
  []
[]

[BCs]

  # we need to pin the pressure to remove the singular value
  # [pin_pressure]
  #  type = DirichletBC
  #  variable = p
  #  boundary = 'pressure_pin_node'
  #  value = 1e5
  # []
  
  # no slip at the sediment base nor on the sides
  [no_slip_sides]
    type = ADVectorFunctionDirichletBC
    variable = velocity
    boundary = 'left right'
    # function_x = 0.
    function_y = 0.
    # function_z = 0.
    set_x_comp = false
    set_z_comp = false
  []

  [no_slip_sides_sediments]
    type = ADVectorFunctionDirichletBC
    variable = velocity
    boundary = 'left_sediment right_sediment bottom_sediment'
    function_x = 0.
    function_y = 0.
    function_z = 0.
  []

  [inlet]
    type = ADVectorFunctionDirichletBC
    variable = velocity
    boundary = 'back' # back_sediment not much diff. either
    function_x = influx
    function_y = 0.
    function_z = 0.
  []
  
  [oulet]
    type = ADFunctionDirichletBC
    variable = p
    boundary = 'front' # front_sediment doesn't make much of a diff.
    function = ocean_pressure
  []

  [outlet_sediment]
    type = ADVectorFunctionDirichletBC
    variable = velocity
    boundary = 'front_sediment'
    function_z = 0.
    set_x_comp = False
    set_y_comp = False
  []

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
    block = '1 255'
    velocity_x = "vel_x"
    velocity_y = "vel_y"
    velocity_z = "vel_z"
    pressure = "p"
    output_properties = 'mu_ice rho_ice'
    outputs = "out"
  []
  [sediment]
    type = ADSedimentMaterialSI
    block = '0'
    SlipperinessCoefficient = ${slipperiness_coefficient}
    LayerThickness = ${sediment_layer_thickness}
    output_properties = 'mu_sediment rho_sediment'
    outputs = "out"
  []
  [floodedsediment]
    type = ADSubglacialFloodMaterialSI
    block = '254'
    SlipperinessCoefficientVariations = "subglacialflood"
    SlipperinessCoefficient = ${slipperiness_coefficient_center}
    FloodAmplitude = 1e-8
    LayerThickness = ${sediment_layer_thickness}
    output_properties = 'mu_floodedsediment rho_floodedediment'
    outputs = "out"
  []

  [ins_mat_ice]
    type = INSADTauMaterial
    block = '1 255'
    velocity = velocity
    pressure = p
    rho_name = "rho_ice"
    mu_name = "mu_ice"
  []
  [ins_mat_sediment]
    type = INSADTauMaterial
    block = '0'
    velocity = velocity
    pressure = p
    rho_name = "rho_sediment"
    mu_name = "mu_sediment"
  []
  [ins_mat_floodedsediment]
    type = INSADTauMaterial
    block = '254'
    velocity = velocity
    pressure = p
    rho_name = "rho_floodedsediment"
    mu_name = "mu_floodedsediment"
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
      vars = 'vel_x vel_y vel_z'
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
  num_steps = 60
  start_time = 0
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
  l_tol = 1e-5

  # nl_rel_tol = 1e-04 in the initial SSA test
  # nl_abs_tol = 1e-04

  nl_rel_tol = 1e-05
  nl_abs_tol = 1e-05

  nl_max_its = 100
  # nl_forced_its = 3
  line_search = none

  dt = '${_dt}'
  # steady_state_detection = true
  # steady_state_tolerance = 1e-10
  check_aux = true

  # [Adaptivity]
  #   interval = 1
  #   refine_fraction = 0.5
  #   coarsen_fraction = 0.3
  #   max_h_level = 10
  #   cycles_per_step = 2
  # []

[]

[Outputs]
  console = true
  perf_graph = true
  [out]
    type = Exodus
  []
[]

# [Debug]
#   show_var_residual_norms = true
#   show_material_props = true
# []
