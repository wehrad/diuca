# a large glacier flowing towards the ocean (hydrostatic pressure at
# the glacier front, i.e. downstream boundary) in the influence of the
# driving stress (surface slope), over a flat bed.
# The mesh includes a sediment block which is the last layer of
# elements before the bottom boundary (where zero velocity is
# applied): the viscosity of the sediment layer is modulating basal
# sliding through a friction coefficient.
# An influx of ice is applied at the top of the domain (upstream
# boundary) to take into account the ice coming from the inner part of
# the ice sheet.

# ------------------------ domain settings

# sediment rheology
# sliding_law = "GudmundssonRaymond"
sediment_layer_thickness = 50.
slipperiness_coefficient_mmpaa = 3e3 # 3e4 # 3e3 # 9.512937595129376e-11
slipperiness_coefficient = '${fparse (slipperiness_coefficient_mmpaa * 1e-6) / (365*24*3600)}' # 

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
nb_years = 0.01 # 0.1
_dt = '${fparse nb_years * 3600 * 24 * 365}'

inlet_mph = 0.75 # 0.01 # mh-1
inlet_mps = ${fparse
             inlet_mph / 3600
            } # ms-1

initial_II_eps_min = 1e-07

# ------------------------

[GlobalParams]
  order = FIRST
  # https://github.com/idaholab/moose/discussions/26157
  # integrate_p_by_parts = true
  integrate_p_by_parts = false
[]

[Mesh]

  [channel]
    type = FileMeshGenerator
    file = ../../../meshes/mesh_icestream_sed.e
  []

  [delete_sediment_block]
    type = BlockDeletionGenerator
    input = channel
    block = '3'
  []

  # Create sediment layer by projecting glacier bed by
  # the sediment thickness
  [lowerDblock_sediment]
    type = LowerDBlockFromSidesetGenerator
    input = "delete_sediment_block"
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
    top_sideset = 'top_sediment'
    bottom_sideset = 'bottom_sediment'
  []
  [stitch_sediment]
    type = StitchedMeshGenerator
    inputs = 'delete_sediment_block extrude_sediment'
    stitch_boundaries_pairs = 'bottom bottom_sediment'
  []

  [add_sediment_lateral_sides]
    type = ParsedGenerateSideset
    combinatorial_geometry = 'y > 9999.99 | y < 0.01'
    included_subdomains = 0
    new_sideset_name = 'left_right_sediment'
    input = 'stitch_sediment'
    replace = True
  []

  [add_sediment_upstream_side]
    type = ParsedGenerateSideset
    combinatorial_geometry = 'x < 0.01'
    included_subdomains = 0
    new_sideset_name = 'upstream_sediment'
    input = 'add_sediment_lateral_sides'
    replace = True
  []
  [add_sediment_downstream_side]
    type = ParsedGenerateSideset
    combinatorial_geometry = 'x > 19599.99'
    included_subdomains = 0
    new_sideset_name = 'downstream_sediment'
    input = 'add_sediment_upstream_side'
    replace = True
  []

  [add_nodesets]
    type = NodeSetsFromSideSetsGenerator
    input = 'add_sediment_downstream_side'
  []

  [final_mesh]
    type = SubdomainBoundingBoxGenerator
    restricted_subdomains="eleblock1 eleblock2"
    input = add_nodesets
    block_id = 255
    block_name = deactivated
    bottom_left = '18500 -100 -100'
    top_right = '22000 11000 150'
  []

  [refined_mesh]
    type = RefineBlockGenerator
    input = "final_mesh"
    block = "255"
    refinement = '1'
    enable_neighbor_refinement = true
    max_element_volume = 1e100
  []

  final_generator = refined_mesh


[]

[Functions]
  [ocean_pressure]
    type = ParsedFunction
    expression = 'if(z < 0, -1028 * 9.81 * z, 1e5)' # -1e5 * 9.81 * z)'
    # expression = '917 * 9.81 * (100 - z)' # -1e5 * 9.81 * z)'
  []
  [viscosity_rampup]
    type = ParsedFunction
    expression = 'initial_II_eps_min * exp(-(t-_dt) * 5e-6)' # 3e-6 # 2e-6
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
    block = 'eleblock1 eleblock2 0 255'
  []
  [vel_y]
    type = VectorVariableComponentAux
    variable = vel_y
    vector_variable = velocity
    component = 'y'
    block = 'eleblock1 eleblock2 0 255'
  []
  [vel_z]
    type = VectorVariableComponentAux
    variable = vel_z
    vector_variable = velocity
    component = 'z'
    block = 'eleblock1 eleblock2 0 255'
  []
[]

[Variables]
  [velocity]
    family = LAGRANGE_VEC
    # order = SECOND
    scaling = 1e-6
    # scaling = 1e6
    # initial_condition = 1e-6
    block = 'eleblock1 eleblock2 0 255'
  []
  [p]
    # scaling = 1e6
    family = LAGRANGE
    # scaling = 1e-6
    # initial_condition = 1e6
    block = 'eleblock1 eleblock2 0 255'
  []
[]

[Kernels]
  [mass_ice]
    type = INSADMass
    block = 'eleblock1 eleblock2 255'
    variable = p
  []
  [mass_stab_ice_ice]
    type = INSADMassPSPG
    block = 'eleblock1 eleblock2 255'
    variable = p
    rho_name = "rho_ice"
  []
  [momentum_time_ice]
    type = INSADMomentumTimeDerivative
    block = 'eleblock1 eleblock2 255'
    variable = velocity
  []
  [momentum_advection_ice]
    type = INSADMomentumAdvection
    block = 'eleblock1 eleblock2 255'
    variable = velocity
  []
  [momentum_viscous_ice]
    type = INSADMomentumViscous
    block = 'eleblock1 eleblock2 255'
    variable = velocity
    mu_name = "mu_ice"
  []
  [momentum_pressure_ice]
    type = INSADMomentumPressure
    block = 'eleblock1 eleblock2 255'
    variable = velocity
    pressure = p
  []
  [momentum_supg_ice]
    type = INSADMomentumSUPG
    block = 'eleblock1 eleblock2 255'
    variable = velocity
    velocity = velocity
  []
  [gravity_ice]
    type = INSADGravityForce
    block = 'eleblock1 eleblock2 255'
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
    boundary = 'left right left_right_sediment top_sediment'
    function_x = 0.
    function_y = 0.
    function_z = 0.
  []

  [inlet]
    type = ADVectorFunctionDirichletBC
    variable = velocity
    boundary = 'upstream' # upstream_sediment not much diff. either
    function_x = influx
    function_y = 0.
    function_z = 0.
  []
  
  [oulet]
    type = ADFunctionDirichletBC
    variable = p
    boundary = 'downstream' # downstream_sediment doesn't make much of a diff.
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
    block = 'eleblock1 eleblock2 255'
    velocity_x = "vel_x"
    velocity_y = "vel_y"
    velocity_z = "vel_z"
    pressure = "p"
    output_properties = 'mu_ice rho_ice'
    outputs = "out"
  []
  [sediment]
    type = ADSedimentMaterialSI2
    block = '0'
    # velocity_x = "vel_x"
    # velocity_y = "vel_y"
    # velocity_z = "vel_z"
    # pressure = "p"
    # density  = 1850.
    # sliding_law = ${sliding_law}
    SlipperinessCoefficient = ${slipperiness_coefficient}
    LayerThickness = ${sediment_layer_thickness}
    output_properties = 'mu_sediment rho_sediment'
    outputs = "out"
  []

  [ins_mat_ice]
    type = INSADTauMaterial
    block = 'eleblock1 eleblock2 255'
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
  num_steps = 28

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
    execute_on = 'FINAL'
  []
[]

# [Debug]
#   show_var_residual_norms = true
#   show_material_props = true
# []
