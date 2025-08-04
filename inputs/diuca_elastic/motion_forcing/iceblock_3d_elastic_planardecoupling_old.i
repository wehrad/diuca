# This input file is part of the DIUCA MOOSE application
# https://github.com/AdrienWehrle/diuca
# https://github.com/idaholab/moose

# adapted from
# moose/modules/solid_mechanics/examples/wave_propagation/cantilever_sweep.i

# This input file simulates the frequency response of a block of ice
# of side length 5km and thickness 550m. The displacement magnitude
# at the surface of the block is stored in a csv file for each
# frequency (see simulation settings).

# --------------------------------- Domain settings

# ice parameters
# _youngs_modulus = 1e9 # Pa
# _poissons_ratio = 0.32

# --------------------------------- Simulation settings

# Frequency domain to sweep
# min_freq = 0.01 # Hz
# max_freq = 4 # Hz
# step_freq = 0.005 # Hz

# --------------------------------- Simulation

[Mesh]
  [block]
    type = GeneratedMeshGenerator
    elem_type = HEX8
    dim = 3
    xmin = 0
    xmax = 5000.
    nx = 40
    zmin = 0
    zmax = 5000.
    nz = 40
    ymin = 0.
    ymax = 550.
    ny = 5
  []

  [shaking_zone]
    type = SubdomainBoundingBoxGenerator
    input = 'block'
    block_id = 4
    bottom_left = '2200 -1 2200'
    top_right = '2700 101 2700'
    # bottom_left = '1900 -1 1900'
    # top_right = '3000 101 3000'
  []
  [decoupling_zone_left]
    type = SubdomainBoundingBoxGenerator
    input = 'shaking_zone'
    block_id = 5
    bottom_left = '2200 -1 950'
    top_right = '2700 101 1550'
    # bottom_left = '1900 -1 650'
    # top_right = '3000 101 1850'
  []
  [decoupling_zone_right]
    type = SubdomainBoundingBoxGenerator
    input = 'decoupling_zone_left'
    block_id = 6
    bottom_left = '2200 -1 3450'
    top_right = '2700 101 4050'
    # bottom_left = '1900 -1 3150'
    # top_right = '3000 101 4350'
  []
  [decoupling_zone_top]
    type = SubdomainBoundingBoxGenerator
    input = 'decoupling_zone_right'
    block_id = 7
    bottom_left = '3450 -1 2200'
    top_right = '4050 101 2700'
    # bottom_left = '3150 -1 1900'
    # top_right = '4350 101 3000'
  []
  [decoupling_zone_bottom]
    type = SubdomainBoundingBoxGenerator
    input = 'decoupling_zone_top'
    block_id = 8
    bottom_left = '950 -1 2200'
    top_right = '1550 101 2700'
    # bottom_left = '650 -1 1900'
    # top_right = '1850 101 3000'
  []
  [mesh_combined_interm]
    type = CombinerGenerator
    inputs = 'block decoupling_zone_bottom'
  []
  [shaking_bottom]
    type = SideSetsAroundSubdomainGenerator
    input = 'mesh_combined_interm'
    block = '4'
    new_boundary = 'shaking_bottom'
    replace = true
    normal = '0 -1 0'
  []
  [decoupling_bottom]
    type = SideSetsAroundSubdomainGenerator
    input = 'shaking_bottom'
    block = '5 6 7 8'
    new_boundary = 'decoupling_bottom'
    replace = true
    normal = '0 -1 0'
  []
  # [delete_bottom]
  #   type=BoundaryDeletionGenerator
  #   input='decoupling_bottom'
  #   boundary_names='bottom'
  # []

  [add_nodesets]
    type = NodeSetsFromSideSetsGenerator
    # input = delete_bottom
    input = decoupling_bottom
  []

  final_generator = add_nodesets
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
[]

# f1 = 0.15   # taper-in starts
# f2 = 0.25   # flat band begins
# f3 = 1.0    # flat band ends
# f4 = 1.2    # taper-out ends

[Functions]
  # [weight]
  #   type = ParsedFunction
  #   value = '-9.81*900*(550-z)'    # initial stress that should result from the weight force
  # []
  [ormsby]
    type = MultiOrmsbyWavelet
    # f1 = 0.3   # taper-in start
    # f2 = 0.6   # start of flat passband
    # f3 = 1.1   # end of flat passband
    # f4 = 1.5   # taper-out end
    f1 = 0.15   # taper-in starts
    f2 = 0.25   # flat band begins
    f3 = 1.0    # flat band ends
    f4 = 1.2    # taper-out ends
    ts = 10.
    nb = 3.
    # scale_factor = 0.5
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
    value = 0. # -9.81
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
[]

[Materials]
  [ice_elasticity]
    type = ComputeIsotropicElasticityTensor
    youngs_modulus = 5e9 # 6e9 # 7e9 # 8e9 # 5e9 # 8.7e9 #Pa
    poissons_ratio = 0.31
  []
  [strain]
    type = ComputeIncrementalSmallStrain
    displacements = 'disp_x disp_y disp_z'
  []
  [density]
    type = GenericConstantMaterial
    prop_names = density
    prop_values = 917 #kg/m3
  []
  [stress]
    type = ComputeFiniteStrainElasticStress
  []
  # [strain_from_initial_stress]
  #   type = ComputeEigenstrainFromInitialStress
  #   initial_stress = '0 0 0  0 0 0  0 0 weight'
  #   eigenstrain_name = ini_stress
  # []
[]

[BCs]
  # fixed bottom in all three dimensions
  # [dirichlet_decoupling_bottom_x]
  #   type = DirichletBC
  #   variable = disp_x
  #   value = 0
  #   boundary = 'decoupling_bottom bottom'
  # []
  # [dirichlet_decoupling_bottom_y]
  #   type = DirichletBC
  #   variable = disp_y
  #   value = 0
  #   boundary = 'decoupling_bottom bottom'
  # []
  # [dirichlet_decoupling_bottom_z]
  #   type = DirichletBC
  #   variable = disp_z
  #   value = 0
  #   boundary = 'decoupling_bottom bottom'
  # []

  # fixed bottom pinning points in all three dimensions
  [dirichlet_decoupling_bottom_x]
    type = DirichletBC
    variable = disp_x
    value = 0
    boundary = 'decoupling_bottom'
  []
  [dirichlet_decoupling_bottom_y]
    type = DirichletBC
    variable = disp_y
    value = 0
    boundary = 'decoupling_bottom'
  []
  [dirichlet_decoupling_bottom_z]
    type = DirichletBC
    variable = disp_z
    value = 0
    boundary = 'decoupling_bottom'
  []

  # fixed vertical sides in all three dimensions
  [dirichlet_side_x]
    type = DirichletBC
    variable = disp_x
    value = 0
    boundary = 'left right back front'
  []
  [dirichlet_side_z]
    type = DirichletBC
    variable = disp_z
    value = 0
    boundary = 'left right back front'
  []
  [dirichlet_side_y]
    type = DirichletBC
    variable = disp_y
    value = 0
    boundary = 'left right back front'
  []

  [shake_bottom_z]
    type = PresetAcceleration
    acceleration = accel_y
    velocity = vel_y
    variable = disp_y
    beta = 0.25
    boundary = 'shaking_bottom'
    function = 'ormsby'
  []
[]

# [Controls]

#   [inertia_switch]
#     type = TimePeriod
#     start_time = 0.0
#     end_time = 0.1
#     disable_objects = '*/inertia_x */inertia_y */inertia_z
#                        */vel_x */vel_y */vel_z
#                        */accel_x */accel_y */accel_z'
#     set_sync_times = true
#     execute_on = 'timestep_begin timestep_end'
#   []

# []

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
  dt = 0.05
  end_time = 40.
  timestep_tolerance = 1e-6
  automatic_scaling = true
  [TimeIntegrator]
    type = NewmarkBeta
    beta = 0.25
    gamma = 0.5
    inactive_tsteps = 2
  []
[]

[Outputs]
  exodus = true  
  perf_graph = true
[]
