# ------------------------

# # slope of the bottom boundary (in degrees)
# bed_slope = 10.

# # change coordinate system to add a slope
# gravity_y = '${fparse sin(bed_slope / 180 * pi) * 9.81 }'
# gravity_z = '${fparse - cos(bed_slope / 180 * pi) * 9.81}'

# dt associated with rest time associated with the
# geometry (in seconds)
# ice has a high viscosity and hence response times
# of years
nb_years = 0.01 # 0.1
_dt = '${fparse nb_years * 3600 * 24 * 365}'

inlet_mph = 0.5 # 0.01 # mh-1
inlet_mps = ${fparse
             inlet_mph / 3600
            } # ms-1

# initial_II_eps_min = 1e-22 constant
# initial_II_eps_min = 1e-07 decay = 2e-6 was the safest
# initial_II_eps_min = 1e-07 decay = 1e-5 aggressive

initial_II_eps_min = 1e-07
# initial_II_eps_min = 1e-12

# initial_II_eps_min = 1e-10
# initial_II_eps_min = 1e-17

# ------------------------

[GlobalParams]
  order = FIRST
  # https://github.com/idaholab/moose/discussions/26157
  # integrate_p_by_parts = true
  integrate_p_by_parts = false
[]

[Functions]
  [ocean_pressure]
    type = ParsedFunction
    expression = 'if(z < 0, -1028 * 9.81 * z, 1e5)' # -1e5 * 9.81 * z)'
    # expression = '917 * 9.81 * (100 - z)' # -1e5 * 9.81 * z)'
  []
  [viscosity_rampup]
    type = ParsedFunction
    expression = 'initial_II_eps_min * exp(-(t-_dt) * 2e-6)' # 3e-6 # 2e-6
    # expression = 'initial_II_eps_min'
    symbol_names = '_dt initial_II_eps_min'
    symbol_values = '${_dt} ${initial_II_eps_min}'
  []
  [influx]
    type = ParsedFunction
    expression = 'inlet_mps * sin((2*pi / 20000) * y)' # * (z / 433.2)'
    # expression = 'inlet_mps' # * (z / 433.2)'
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

[Mesh]

  [channel]      
  type = FileMeshGenerator
  file = ../../../meshes/mesh_icestream_sed.e
  []

  # delete sediment block for now (below bedrock)
  [delete_sediment_block]
    type = BlockDeletionGenerator
    input = channel
    block = '3'
  []
  # [frontal_zone]
  #   type = SubdomainBoundingBoxGenerator
  #   input = 'delete_sediment_block'
  #   block_id = 10
  #   bottom_left = '20000 -1000 -3000'
  #   top_right = '19000  15000 3000'
  # []
  # [refined_front]
  #   type = RefineBlockGenerator
  #   input = "frontal_zone"
  #   block = '10'
  #   refinement = '1'
  #   enable_neighbor_refinement = true
  # []
  # [mesh_combined_interm]
  #   type = CombinerGenerator
  #   inputs = 'channel refined_front'
  # []
  # [pin_pressure_node]
  #   type = BoundingBoxNodeSetGenerator
  #   input = 'delete_sediment_block'
  #   bottom_left = '19599.99 -0.00001 99.9999'
  #   top_right = '19600.001 0.000001 100.001'
  #   new_boundary = 'pressure_pin_node'
  # []
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
    # scaling = 1e6
    # initial_condition = 1e-6
  []
  [p]
    # scaling = 1e6
    scaling = 1e-6
    # initial_condition = 1e6
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

  # [inlet]
  #   type = ADVectorFunctionDirichletBC
  #   variable = velocity
  #   boundary = 'left'
  #   # function_x = "${inlet_mps}"
  #   function_x=0
  #   # function_y = 0.
  # []

  [inlet]
    type = ADVectorFunctionDirichletBC
    variable = velocity
    boundary = 'upstream'
    function_x = influx
    function_y = 0.
    function_z = 0.
  []
  
  [no_lateral_sliding]
    type = ADVectorFunctionDirichletBC
    variable = velocity
    boundary = 'left right'
    function_x = 0.
    function_y = 0.
    function_z = 0.
    # set_x_comp = False
  []

  [no_basal_penetration]
    type = ADVectorFunctionDirichletBC
    variable = velocity
    boundary = 'bottom'
    function_z = 0.
    function_x = 1e-6
    # function_y = 0.
    # set_x_comp = False
    set_y_comp = False
  []

  [oulet]
    type = ADFunctionDirichletBC
    variable = p
    boundary = 'downstream'
    function = ocean_pressure
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
    velocity_x = "vel_x"
    velocity_y = "vel_y"
    velocity_z = "vel_z"
    pressure = "p"
    output_properties = "rho mu"
    outputs = "out"
  []
  [ins_mat]
    type = INSADTauMaterial
    velocity = velocity
    pressure = p
  []
[]


[Preconditioning]
  active = 'SMP'
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
  num_steps = 100 # 100

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
  
  nl_rel_tol = 1e-05
  nl_abs_tol = 1e-05

  nl_max_its = 40 # 100
  nl_forced_its = 3
  line_search = none

  dt = '${_dt}'
  steady_state_detection = true
  steady_state_tolerance = 1e-20
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
  [out]
    type = Exodus
  []
[]
