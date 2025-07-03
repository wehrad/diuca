# ------------------------ domain settings

# sediment rheology
# sliding_law = "GudmundssonRaymond"
sediment_layer_thickness = 50.
slipperiness_coefficient_mmpaa = 1e2
slipperiness_coefficient = '${fparse (slipperiness_coefficient_mmpaa * 1e-6) / (365*24*3600)}' # 

# slipperiness_coefficient_center_mmpaa = 1e5 # 1e5
# slipperiness_coefficient_center = '${fparse (slipperiness_coefficient_center_mmpaa * 1e-6) / (365*24*3600)}' # 

# ------------------------ simulation settings

nb_years = 0.008
_dt = '${fparse nb_years * 3600 * 24 * 365}'

inlet_mph = 0.32 # 0.4 # mh-1 # slower doesn't help
inlet_mps = ${fparse
             inlet_mph / 3600
            } # ms-1

# initial_viscosity = 8e9 # Pas
# rampup_rate = 5e6 # 5e6 # 1e6 # 5e5 # 1e5

# ------------------------

[GlobalParams]
  order = FIRST
  integrate_p_by_parts = true
[]

[Mesh]

  [channel]
    type = FileMeshGenerator
    file = generate_icestream_mesh_out.e
    # file = generate_iceblock_mesh_out.e
  []

  # Create sediment layer by projecting glacier bed by
  # the sediment thickness
  [lowerDblock_sediment]
    type = LowerDBlockFromSidesetGenerator
    # input = "delete_sediment_block"
    input = "channel"
    new_block_name = "block_0"
    sidesets = "bottom"
  []
  [separateMesh_sediment]
    type = BlockToMeshConverterGenerator
    input = lowerDblock_sediment
    target_blocks = "block_0"
  []
  [extrude_sediment]
    type = MeshExtruderGenerator
    input = separateMesh_sediment
    num_layers = 1
    extrusion_vector = '0. 0. -${sediment_layer_thickness}'
    # bottom/top swap is (correct and) due to inverse extrusion
    top_sideset = 'bottom_sediment'
    bottom_sideset = 'top_sediment'
  []
  [stitch_sediment]
    type = StitchedMeshGenerator
    inputs = 'channel extrude_sediment'
    stitch_boundaries_pairs = 'bottom top_sediment'
    clear_stitched_boundary_ids = false
  []

  [add_frontback_leftright_sediment_sidesets]
    type = SideSetsFromNormalsGenerator
    # input = add_bottom_sediment_sideset
    input = stitch_sediment
    included_subdomains = "0"
    normals = '0  1  0
               0 -1  0
               1  0  0
              -1  0  0'
    new_boundary = 'right_sediment left_sediment front_sediment back_sediment'
  []

  [add_nodesets]
    type = NodeSetsFromSideSetsGenerator
    input = add_frontback_leftright_sediment_sidesets
  []

  [final_mesh]
    type = SubdomainBoundingBoxGenerator
    restricted_subdomains="1"
    input = add_nodesets
    block_id = 255
    block_name = deactivated
    bottom_left = '24000 -100 -2000'
    top_right = '26000 11000 150'
  []

  [refined_mesh]
    type = RefineBlockGenerator
    input = "final_mesh"
    block = "255"
    refinement = '1'
    enable_neighbor_refinement = true
    max_element_volume = 1e100
  []

  [final_mesh2]
    type = SubdomainBoundingBoxGenerator
    input = refined_mesh
    # input = final_mesh
    restricted_subdomains="0"
    block_id = 254
    block_name = flood
    bottom_left = '-1000 4000 -1e4'
    top_right = '26000  5700 1e4'
  []

  final_generator = final_mesh2

[]

[Functions]
  # [viscosity_rampup]
  #   type = ParsedFunction
  #   expression = 'initial_viscosity + t * rampup_rate'
  #   # expression = 'A * t^2 + B*t'
  #   # expression = 'initial_II_eps_min'
  #   # symbol_names = 'A B'
  #   # symbol_values = '4.71333237962635 3567351.59817352'
  #   symbol_names = 'initial_viscosity rampup_rate'
  #   symbol_values = '${initial_viscosity} ${rampup_rate}'
  # []
  [viscosity_rampup]
    type = PiecewiseLinear
    # xy_data = '252288. 1.5e12
    #            2522880.  2e13' # 1.2e12 1e13

    xy_data = '252288. 1.5e12
               1261440. 9.72e12
               2522880. 5e13
               3279744. 1e14
               4288896. 2e14'
  []
  [influx]
    type = ParsedFunction
    # expression = 'inlet_mps * sin((2*pi / 20000) * y)' # * (z / 433.2)'
    expression = 'inlet_mps'
    # expression = '(((f0 * y^10 + f1 * y^9 + f2 * y^8 + f3 * y^7 + f4 * y^6 + f5 * y^5 + f6 * y^4 + f7 * y^3 + f8 * y^2 + f9 * y + f10) / 3) + 0.02) / 3600'
    symbol_names = 'inlet_mps'
    symbol_values = '${inlet_mps}'
    # symbol_names = 'f0 f1 f2 f3 f4 f5 f6 f7 f8 f9 f10'
    # symbol_values = '3.15098842e-38 -2.27201938e-33  7.68216888e-29 -1.45500836e-24
    #     1.61004382e-20 -1.03844445e-16  3.73975638e-13 -6.87965221e-10
    #     5.87484523e-07 -1.69968105e-04  5.89693944e-02'
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
    initial_condition = 1e-6
    block = '1 0 255 254'
  []
  [p]
    family = LAGRANGE
    initial_condition = 1e6
    block = '1 0 255 254'
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
  
  # no slip at the sediment base nor on the sides
  [no_slip_sides]
    type = ADVectorFunctionDirichletBC
    variable = velocity
    boundary = 'left right left_sediment right_sediment'
    # function_x = 0.
    function_y = 0.
    # function_z = 0.
    set_x_comp = false
    set_z_comp = false
  []

  [no_slip_sides_sediments]
    type = ADVectorFunctionDirichletBC
    variable = velocity
    boundary = 'bottom_sediment'
    function_x = 0.
    function_y = 0.
    function_z = 0.
  []

  # [no_vertical_ice_sediment_boundary]
  #   type = ADVectorFunctionDirichletBC
  #   variable = velocity
  #   boundary = 'top_sediment'
  #   function_z = 0.
  #   set_x_comp = false
  #   set_y_comp = false
  # []

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

  [front_sediment_pressure]
    type = INSADHydrostaticPressureBC
    boundary = 'front_sediment'
    variable = velocity
    pressure = p
    mu_name = "mu_sediment"
  []

  # [outlet_sediments]
  #   type = ADVectorFunctionDirichletBC
  #   variable = velocity
  #   boundary = 'front_sediment'
  #   function_x = 0.
  #   # set_x_comp = false
  #   function_y = 0.
  #   function_z = 0.
  # []
  
  [freesurface]
    type = INSADMomentumNoBCBC
    variable = velocity
    pressure = p
    boundary = 'surface'
    mu_name = "mu_ice"
  []
[]

[Materials]
  [ice]
    type = ADIceMaterialSI_ru
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
    # SlipperinessCoefficient = ${slipperiness_coefficient_center}
    LayerThickness = ${sediment_layer_thickness}
    output_properties = 'mu_floodedsediment rho_floodedsediment'
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
  num_steps = 50

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

  nl_rel_tol = 1e-04 # in the initial SSA test
  nl_abs_tol = 1e-04

  # nl_rel_tol = 1e-05
  # nl_abs_tol = 1e-05

  nl_max_its = 30

  nl_forced_its = 3

  line_search = none

  dt = '${_dt}'
  steady_state_detection = true
  steady_state_tolerance = 1e-10
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
  checkpoint = true
  perf_graph = true
  console = true
  [out]
    type = Exodus
    # execute_on = 'FINAL'
  []
[]

# [Debug]
#   show_var_residual_norms = true
#   show_material_props = true
# []
