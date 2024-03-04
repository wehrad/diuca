# ------------------------

# a large gravity-loaded glacier in conactt with the ocean
# (hydrostatic pressure at the glacier front, i.e. downstream
# boundary) sitting on top of a bedrock trough.

# A slip surface is being decoupled at timestep t resulting in the
# propagation of an elastic deformation for the trigger zone to get to
# a new steady state.

# ------------------------

[Mesh]
  [channel]      
  type = FileMeshGenerator
  file = mesh_icestream.e
  []

  [slip_zone_large]
    type = SubdomainBoundingBoxGenerator
    input = 'channel'
    block_id = 4
    bottom_left = '10900 5000 -2200'
    top_right = '10600 5350 -1800'
  []
  [mesh_combined_interm]
    type = CombinerGenerator
    inputs = 'channel slip_zone_large'
  []
  [slip_zone_large_refined]
    type = RefineBlockGenerator
    input = "mesh_combined_interm"
    block = '4'
    refinement = '3'
    enable_neighbor_refinement = true
  []
  [slip_zone]
    type = SubdomainBoundingBoxGenerator
    input = 'slip_zone_large_refined'
    block_id = 5
    bottom_left = '10800 5100 -2100'
    top_right = '10700 5200 -2000'
  []
  [mesh_combined]
    type = CombinerGenerator
    inputs = 'mesh_combined_interm slip_zone'
  []
  [slip_side]
    type = SideSetsAroundSubdomainGenerator
    input = 'mesh_combined'
    block = 5
    new_boundary = 'slip_side'
    replace = true
    normal = '0 0 1'
  []
[]

[GlobalParams]
  displacements = 'disp_x disp_y disp_z'
[]

[Variables]
  [disp_x]
    order = FIRST
    family = LAGRANGE
  []
  [disp_y]
    order = FIRST
    family = LAGRANGE
  []
  [disp_z]
    order = FIRST
    family = LAGRANGE
  []
[]

[AuxVariables]
  [vel_x]
  []
  [accel_x]
  []
  [vel_y]
  []
  [accel_y]
  []
  [vel_z]
  []
  [accel_z]
  []
  [stress_xx]
    order = CONSTANT
    family = MONOMIAL
  []
  [stress_xy]
    order = CONSTANT
    family = MONOMIAL
  []
  [stress_xz]
    order = CONSTANT
    family = MONOMIAL
  []
  [stress_yx]
    order = CONSTANT
    family = MONOMIAL
  []
  [stress_yy]
    order = CONSTANT
    family = MONOMIAL
  []
  [stress_yz]
    order = CONSTANT
    family = MONOMIAL
  []
  [stress_zx]
    order = CONSTANT
    family = MONOMIAL
  []
  [stress_zy]
    order = CONSTANT
    family = MONOMIAL
  []
  [stress_zz]
    order = CONSTANT
    family = MONOMIAL
  []
[]

[Functions]
  [weight]
    type = ParsedFunction
    value = '-8829*(1000-z)'    # initial stress that should result from the weight force
  []
  [upstream_dirichlet]
    type = ParsedFunction
    value = '0'
  []
  [ocean_pressure]
    type = ParsedFunction
    value = '8829*(1000-z)'   
  []
[]

[Kernels]
  [gravity_x]
    type = Gravity
    variable = disp_x
    value= 0.
  []
  [gravity_y]
    type = Gravity
    variable = disp_y
    value = 0.
  []
  [gravity_z]
    type = Gravity
    variable = disp_z
    value = -9.81
  []
  [DynamicTensorMechanics]
    stiffness_damping_coefficient = 0.02
    mass_damping_coefficient = 0.02
    displacements = 'disp_x disp_y disp_z'
    static_initialization = true
  []
  [inertia_x]
    type = InertialForce
    variable = disp_x
    velocity = vel_x
    acceleration = accel_x
    beta = 0.25
    gamma = 0.5
  []
  [inertia_y]
    type = InertialForce
    variable = disp_y
    velocity = vel_y
    acceleration = accel_y
    beta = 0.25
    gamma = 0.5
  []
  [inertia_z]
    type = InertialForce
    variable = disp_z
    velocity = vel_z
    acceleration = accel_z
    beta = 0.25
    gamma = 0.5
  []
[]

[AuxKernels]
  [accel_x]
    type = NewmarkAccelAux
    variable = accel_x
    displacement = disp_x
    velocity = vel_x
    beta = 0.25
    execute_on = timestep_end
  []
  [vel_x]
    type = NewmarkVelAux
    variable = vel_x
    acceleration = accel_x
    gamma = 0.5
    execute_on = timestep_end
  []
  [accel_y]
    type = NewmarkAccelAux
    variable = accel_y
    displacement = disp_y
    velocity = vel_y
    beta = 0.25
    execute_on = timestep_end
  []
  [vel_y]
    type = NewmarkVelAux
    variable = vel_y
    acceleration = accel_y
    gamma = 0.5
    execute_on = timestep_end
  []
  [accel_z]
    type = NewmarkAccelAux
    variable = accel_z
    displacement = disp_z
    velocity = vel_z
    beta = 0.25
    execute_on = timestep_end
  []
  [vel_z]
    type = NewmarkVelAux
    variable = vel_z
    acceleration = accel_z
    gamma = 0.5
    execute_on = timestep_end
  []
  [stress_xx]
    type = RankTwoAux
    rank_two_tensor = stress
    variable = stress_xx
    index_i = 0
    index_j = 0
  []
  [stress_xy]
    type = RankTwoAux
    rank_two_tensor = stress
    variable = stress_xy
    index_i = 0
    index_j = 1
  []
  [stress_xz]
    type = RankTwoAux
    rank_two_tensor = stress
    variable = stress_xz
    index_i = 0
    index_j = 2
  []
  [stress_yx]
    type = RankTwoAux
    rank_two_tensor = stress
    variable = stress_yx
    index_i = 1
    index_j = 0
  []
  [stress_yy]
    type = RankTwoAux
    rank_two_tensor = stress
    variable = stress_yy
    index_i = 1
    index_j = 1
  []
  [stress_yz]
    type = RankTwoAux
    rank_two_tensor = stress
    variable = stress_yz
    index_i = 1
    index_j = 2
  []
  [stress_zx]
    type = RankTwoAux
    rank_two_tensor = stress
    variable = stress_zx
    index_i = 2
    index_j = 0
  []
  [stress_zy]
    type = RankTwoAux
    rank_two_tensor = stress
    variable = stress_zy
    index_i = 2
    index_j = 1
  []
  [stress_zz]
    type = RankTwoAux
    rank_two_tensor = stress
    variable = stress_zz
    index_i = 2
    index_j = 2
  []
[]

[Materials]
  [ice_elasticity]
    type = ComputeIsotropicElasticityTensor
    youngs_modulus = 8.7e9 # Pa
    poissons_ratio = 0.31
  []
  [strain]
    type = ComputeIncrementalSmallStrain
    displacements = 'disp_x disp_y disp_z'
  []
  [density]
    type = GenericConstantMaterial
    prop_names = density
    prop_values = 917 # kgm-3
  []
  [stress]
    type = ComputeFiniteStrainElasticStress
  []
  [strain_from_initial_stress]
    type = ComputeEigenstrainFromInitialStress
    initial_stress = '0 0 0  0 0 0  0 0 weight'
    eigenstrain_name = ini_stress
  []
  [von_mises]
    type = RankTwoInvariant
    invariant = 'VonMisesStress'
    property_name = von_mises
    rank_two_tensor = stress
    outputs = exodus
  []
[]

[BCs]

  [upstream_dirichlet_x]
    type = DirichletBC                                               
    boundary = 'upstream'
    variable = disp_x
    value    = 0.0
  []
  [upstream_dirichlet_x_sediment]
    type = DirichletBC                                               
    boundary = 'upstream_sediment'
    variable = disp_x
    value    = 0.0
  []  
  [upstream_dirichlet_y]
    type = DirichletBC                                               
    boundary = 'upstream'
    variable = disp_y
    value    = 0.0
  []
  [upstream_dirichlet_y_sediment]
    type = DirichletBC                                               
    boundary = 'upstream_sediment'
    variable = disp_y
    value    = 0.0
  []
  [upstream_dirichlet_z]
    type = DirichletBC                                               
    boundary = 'upstream'
    variable = disp_z
    value    = 0.0
  []
  [upstream_dirichlet_z_sediment]
    type = DirichletBC                                               
    boundary = 'upstream_sediment'
    variable = disp_z
    value    = 0.0
  []

  [downstream_dirichlet_x]
    type = DirichletBC                                               
    boundary = 'downstream'
    variable = disp_x
    value    = 0.0
  []
  [downstream_dirichlet_x_sediment]
    type = DirichletBC                                               
    boundary = 'downstream_sediment'
    variable = disp_x
    value    = 0.0
  []
  [downstream_dirichlet_y]
    type = DirichletBC                                               
    boundary = 'downstream'
    variable = disp_y
    value    = 0.0
  []
  [downstream_dirichlet_y_sediment]
    type = DirichletBC                                               
    boundary = 'downstream_sediment'
    variable = disp_y
    value    = 0.0
  []
  [downstream_dirichlet_z]
    type = DirichletBC                                               
    boundary = 'downstream'
    variable = disp_z
    value    = 0.0
  []
  [downstream_dirichlet_z_sediment]
    type = DirichletBC                                               
    boundary = 'downstream_sediment'
    variable = disp_z
    value    = 0.0
  []

  [anchor_bottom_x]
    type = DirichletBC
    variable = disp_x
    boundary = 'sediment'
    value = 0.0
  []  
  [anchor_botom_y]
    type = DirichletBC
    variable = disp_y
    boundary = 'sediment'
    value = 0.0
  []
  [anchor_bottom_z]
    type = DirichletBC
    variable = disp_z
    boundary = 'sediment'
    value = 0.0
  []

  [anchor_sides_x]
    type = DirichletBC
    variable = disp_x
    boundary = 'left right'
    value = 0.0
  []
  [anchor_sides_y]
    type = DirichletBC
    variable = disp_y
    boundary = 'left right'
    value = 0.
  []
  [anchor_sides_z]
    type = DirichletBC
    variable = disp_z
    boundary = 'left right'
    value = 0.0
  []

  [anchor_bottom_x_slip]
    type = DirichletBC
    variable = disp_x
    boundary = 'slip_side'
    value = 0.0
  []  
  [anchor_botom_y_slip]
    type = DirichletBC
    variable = disp_y
    boundary = 'slip_side'
    value = 0.0
  []
  [anchor_bottom_z_slip]
    type = DirichletBC
    variable = disp_z
    boundary = 'slip_side'
    value = 0.0
  []
[]

[Controls]

  [inertia_switch]
    type = TimePeriod
    start_time = 0.0
    end_time = 0.03
    disable_objects = '*/inertia_x */inertia_y */inertia_z
                       */vel_x */vel_y */vel_z
                       */accel_x */accel_y */accel_z'
    set_sync_times = true
    execute_on = 'timestep_begin timestep_end'
  []

  [bed_release]
    type = TimePeriod
    start_time = 0.1
    end_time = 20
    disable_objects = 'BCs::anchor_bottom_x_slip'
    set_sync_times = true
    execute_on = 'timestep_begin timestep_end'
  []

[]

[Preconditioning]
  [andy]
    type = SMP
    full = true
  []
[]

[Executioner]
  type = Transient
  petsc_options = '-ksp_snes_ew'
  petsc_options_iname = '-pc_type -pc_factor_mat_solver_package'
  petsc_options_value = 'lu       superlu_dist'
  solve_type = 'NEWTON'
  nl_rel_tol = 1e-7
  nl_abs_tol = 1e-12
  dt = 0.01
  end_time = 20.
  timestep_tolerance = 1e-6
  automatic_scaling = true
  [TimeIntegrator]
    type = NewmarkBeta
    beta = 0.25
    gamma = 0.5
    inactive_tsteps = 2
  []
[]

[Postprocessors]
  [disp_x_surface]
    type = NodalVariableValue
    nodeid = 9912
    variable = disp_x
  []
  [disp_y_surface]
    type = NodalVariableValue
    nodeid = 9912
    variable = disp_y
  []
  [disp_z_surface]
    type = NodalVariableValue
    nodeid = 9912
    variable = disp_z
  []
  [vel_x_surface]
    type = NodalVariableValue
    nodeid = 9912
    variable = vel_x
  []
  [vel_y_surface]
    type = NodalVariableValue
    nodeid = 9912
    variable = vel_y
  []
  [vel_z_surface]
    type = NodalVariableValue
    nodeid = 9912
    variable = vel_z
  []
[]

[Outputs]
  exodus = true  
  perf_graph = true
  csv = true
[]
