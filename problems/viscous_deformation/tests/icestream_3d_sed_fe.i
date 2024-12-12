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
sliding_law = "GudmundssonRaymond"
sediment_layer_thickness = 50.
slipperiness_coefficient_mmpaa = 3e3 # 3e4 # 3e3 # 9.512937595129376e-11
slipperiness_coefficient = '${fparse (slipperiness_coefficient_mmpaa * 1e-6) / (365*24*3600)}' # 

# ------------------------ simulation settings

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

# Material properties
rho = 'rho_combined'
mu = 'mu_combined'

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
    file = ../../../meshes/mesh_icestream_4xd_sed.e
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




  # [frontal_zone]
  #   type = SubdomainBoundingBoxGenerator
  #   input = 'channel'
  #   block_id = "10"
  #   bottom_left = '20000 -1000 -3000'
  #   top_right = '19000 15000 3000'
  #   restricted_subdomains = 'eleblock1 eleblock2'
  # []
  # [refined_front]
  #   type = RefineBlockGenerator
  #   input = "add_sediment_downstream_side"
  #   block = "0"
  #   refinement = '1'
  #   enable_neighbor_refinement = true
  #   max_element_volume = 1e100
  # []

  # [fast_zone]
  #   type = SubdomainBoundingBoxGenerator
  #   input = 'add_sediment_downstream_side'
  #   block_id = "10"
  #   bottom_left = '20000 3749.99 -200.' # 99.99'
  #   top_right = '13000  6700.99 434'
  #   restricted_subdomains = 'eleblock2'
  # []
  # [refined_fastzone]
  #   type = RefineBlockGenerator
  #   input = "fast_zone"
  #   block = "10"
  #   refinement = '1'
  #   enable_neighbor_refinement = false
  #   max_element_volume = 1e100
  # []

  # [refined_surface]
  #   type = RefineSidesetGenerator
  #   input = "add_sediment_downstream_side"
  #   boundaries = "surface"
  #   refinement = '1'
  #   enable_neighbor_refinement = false
  #   boundary_side = "primary"
  # []




  [add_nodesets]
    type = NodeSetsFromSideSetsGenerator
    input = 'add_sediment_downstream_side'
  []




  # [refined_sediments]
  #   type = RefineBlockGenerator
  #   input = "add_nodesets"
  #   block = "0"
  #   refinement = '1'
  #   enable_neighbor_refinement = true
  #   max_element_volume = 1e100
  # []

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
    # order = SECOND
    scaling = 1e-6
    # scaling = 1e6
    # initial_condition = 1e-6
  []
  [p]
    # scaling = 1e6
    family = LAGRANGE
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
    gravity = '0. 0. -3' #9.81
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
  [no_slip]
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
    boundary = 'upstream upstream_sediment'
    function_x = influx
    function_y = 0.
    function_z = 0.
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
    block = 'eleblock1 eleblock2' #  10
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
    velocity_x = "vel_x"
    velocity_y = "vel_y"
    velocity_z = "vel_z"
    pressure = "p"
    density  = 1850.
    sliding_law = ${sliding_law}
    SlipperinessCoefficient = ${slipperiness_coefficient}
    LayerThickness = ${sediment_layer_thickness}
    output_properties = 'mu_sediment rho_sediment'
    outputs = "out"
  []

  [mu_combined]
    type = ADPiecewiseByBlockFunctorMaterial
    prop_name = 'mu_combined'
    subdomain_to_prop_value = 'eleblock1 mu_ice
                               eleblock2 mu_ice
                               0 mu_sediment' #                                10  mu_ice
  []
  [rho_combined]
    type = ADPiecewiseByBlockFunctorMaterial
    prop_name = 'rho_combined'
    subdomain_to_prop_value = 'eleblock1 rho_ice
                               eleblock2 rho_ice
                               0 rho_sediment'  #                                10  rho_ice
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
  num_steps = 10 # 100

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

  [Adaptivity]
    interval = 1
    refine_fraction = 0.5
    coarsen_fraction = 0.3
    max_h_level = 10
    cycles_per_step = 2
  []

[]

[Outputs]
  console = true
  [out]
    type = Exodus
  []
[]
