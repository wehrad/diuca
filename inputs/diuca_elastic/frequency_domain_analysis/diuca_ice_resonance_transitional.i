# This input file is part of the DIUCA MOOSE application
# https://github.com/AdrienWehrle/diuca
# https://github.com/idaholab/moose

# adapted from
# moose/modules/solid_mechanics/examples/wave_propagation/cantilever_sweep.i

# This input file simulates the frequency response of a block of ice
# of side length 5km and thickness 0.6km. The displacement magnitude
# at the surface of the block is stored in a csv file for each
# frequency (see simulation settings).

# --------------------------------- Domain settings

# ice parameters
_youngs_modulus = 1e9 # Pa
_poissons_ratio = 0.32

# --------------------------------- Simulation settings

# Frequency domain to sweep
min_freq = 0.01 # Hz
max_freq = 4 # Hz
step_freq = 0.01 # Hz

# --------------------------------- Simulation

[Mesh]
  [block]
    type = GeneratedMeshGenerator
    elem_type = HEX8
    dim = 3
    xmin = 0
    xmax = 5000.
    nx = 20 # 50
    zmin = 0
    zmax = 5000.
    nz = 20 # 50
    ymin = 0.
    ymax = 600.
    ny = 10 # 6
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
    # bottom_left = '950 -1 2200'
    # top_right = '1550 101 2700'
    bottom_left = '650 -1 1900'
    top_right = '1850 101 3000'
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
    block = '4 5 6 7 8'
    new_boundary = 'decoupling_bottom'
    replace = true
    normal = '0 -1 0'
  []
  [delete_bottom]
    type=BoundaryDeletionGenerator
    input='decoupling_bottom'
    boundary_names='bottom'
  []

  [add_nodesets]
    type = NodeSetsFromSideSetsGenerator
    input = delete_bottom
  []

  final_generator = add_nodesets
[]

[GlobalParams]
  order = FIRST
  family = LAGRANGE
  displacements = 'disp_x disp_y disp_z'
[]

[Problem]
 type = ReferenceResidualProblem
 reference_vector = 'ref'
 extra_tag_vectors = 'ref'
 group_variables = 'disp_x disp_y disp_z'
[]

[Physics]
  [SolidMechanics]
    [QuasiStatic]
      [all]
        strain = SMALL
        add_variables = true
        new_system = true
        formulation = TOTAL
      []
    []
  []
[]

[Kernels]
    #reaction terms
    [reaction_realy]
        type = Reaction
        variable = disp_y
        rate = 0 # filled by controller
        extra_vector_tags = 'ref'
        block = '0'
    []
[]

[AuxVariables]
  [disp_mag]
  []
[]

[AuxKernels]
  [disp_mag]
    type = ParsedAux
    variable = disp_mag
    coupled_variables = 'disp_z disp_x'
    expression = 'sqrt((disp_z^2)+(disp_x^2))'
  []
[]

[BCs]

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

  # vertical shaking at the surface
  [surface_yreal]
    type = NeumannBC
    variable = disp_y
    boundary = 'top'
    value = 1
  []

[]

[Materials]
  [elastic_tensor_ice]
    type = ComputeIsotropicElasticityTensor
    youngs_modulus = '${_youngs_modulus}'
    poissons_ratio = '${_poissons_ratio}'
  []
  [compute_stress]
    type = ComputeLagrangianLinearElasticStress
  []
[]

[Postprocessors]
  [dispMag]
    type = AverageNodalVariableValue
    boundary = 'top'
    variable = disp_mag
  []
[]

[Functions]
  [freq2]
    type = ParsedFunction
    symbol_names = density
    symbol_values = 917 # ice, kg/m3
    expression = '-t*t*density'
  []
[]

[Controls]
  [func_control]
    type = RealFunctionControl
    parameter = 'Kernels/*/rate'
    function = 'freq2'
    execute_on = 'initial timestep_begin'
  []
[]

[Executioner]
  type = Transient
  solve_type=LINEAR
  petsc_options_iname = ' -pc_type'
  petsc_options_value = 'lu'
  start_time = '${min_freq}'
  end_time =  '${max_freq}'
  nl_abs_tol = 1e-6
  [TimeStepper]
    type = ConstantDT
    dt = '${step_freq}'
  []
[]

[Outputs]
  csv=true
  exodus=true
  perf_graph=true
[]
