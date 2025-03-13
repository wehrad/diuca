# This input file is part of the DIUCA MOOSE application
# https://github.com/AdrienWehrle/diuca
# https://github.com/idaholab/moose

# adapted from
# moose/modules/solid_mechanics/examples/wave_propagation/cantilever_sweep.i

# This input file simulates the frequency response of a block of ice
# of side length 5km and thickness 0.6km, for different ice-bedrock
# coupling states. The displacement magnitude at the surface of the
# block is stored in a csv file for each frequency (see simulation
# settings). The frequency response for the different states are
# presented in van Ginkel et al 2025 where more details about model
# setup and research questions can be found too.

# ------------------------------------------------- Domain settings

# Three ice-bedrock coupling states are currently available:
# 0: the ice-bedrock interface is fully coupled (null Dirichlet)
# 1: the ice-bedrock interface is only coupled on four zones of the
# bed (see "add_bottom_back" object).
# 2: the ice-bedrock interface is fully decoupled (no boundary condition).
# The state can be set below by setting it to 0, 1 or 2.
icebedrock_coupling_state = 2

# ice parameters
_youngs_modulus = 1e9 # 8.7e9 # Pa # between 0.8 and 3.5 GPa
_poissons_ratio = 0.32

# ------------------------------------------------- Simulation settings

# Frequency domain to sweep in Hertz (minimum, maximum and step)
min_freq = 0.1
max_freq = 10
step_freq = 0.002 # 0.01

# ------------------------------------------------- Simulation

[Mesh]
  [block]
    type = GeneratedMeshGenerator
    elem_type = HEX8
    dim = 3
    xmin = 0
    xmax = 5000.
    nx = 25
    zmin = 0
    zmax = 5000.
    nz = 25
    ymin = 0.
    ymax = 600.
    ny = 3
  []

  [shaking_zone]
    type = SubdomainBoundingBoxGenerator
    input = 'block'
    block_id = 4
    bottom_left = '2200 -1 2200'
    top_right = '2700 101 2700'
  []
  [decoupling_zone_left]
    type = SubdomainBoundingBoxGenerator
    input = 'shaking_zone'
    block_id = 5
    bottom_left = '2200 -1 950'
    top_right = '2700 101 1550'
  []
  [decoupling_zone_right]
    type = SubdomainBoundingBoxGenerator
    input = 'decoupling_zone_left'
    block_id = 6
    bottom_left = '2200 -1 3450'
    top_right = '2700 101 4050'
  []
  [decoupling_zone_top]
    type = SubdomainBoundingBoxGenerator
    input = 'decoupling_zone_right'
    block_id = 7
    bottom_left = '3450 -1 2200'
    top_right = '4050 101 2700'
  []
  [decoupling_zone_bottom]
    type = SubdomainBoundingBoxGenerator
    input = 'decoupling_zone_top'
    block_id = 8
    bottom_left = '950 -1 2200'
    top_right = '1550 101 2700'
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
    normal = '0 1 0'
  []
  [decoupling_bottom]
    type = SideSetsAroundSubdomainGenerator
    input = 'shaking_bottom'
    block = '5 6 7 8'
    new_boundary = 'decoupling_bottom'
    replace = true
    normal = '0 1 0'
  []
  [delete_bottom]
    type=BoundaryDeletionGenerator
    input='decoupling_bottom'
    boundary_names='bottom'
  []

  [add_bottom_back]
    type = ParsedGenerateSideset
    input = 'delete_bottom'
    combinatorial_geometry = '((x<2200 & z<2200) | (x>2700 & z>2700)) & (y<1)|
                              ((x>2700 & z<2200) | (x<2200 & z>2700)) & (y<1)|
                              ((z<950) | (z>4050)) & (y<1)|
                              ((x<950) | (x>4050)) & (y<1)|
                              (z>1550) & (z<2200) & (y < 1)|
                              (z>2700) & (z<3450) & (y < 1)|
                              (x>2700) & (x<3450) & (y < 1)|
                              (x>1550) & (x<2200) & (y < 1)' 
    included_subdomains = '0'
    normal = '0 -1 0'
    new_sideset_name = 'bottom'
    replace=true
  []

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
    [reaction_realx]
        type = Reaction
        variable = disp_x
        rate = 0# filled by controller
        extra_vector_tags = 'ref'
        block = '0' # 4'
    []
    [reaction_realy]
        type = Reaction
        variable = disp_y
        rate = 0# filled by controller
        extra_vector_tags = 'ref'
        block = '0' # 4'
    []
    [reaction_realz]
        type = Reaction
        variable = disp_z
        rate = 0# filled by controller
        extra_vector_tags = 'ref'
        block = '0' # 4'
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
    coupled_variables = 'disp_x disp_y disp_z'
    expression = 'sqrt(disp_x^2+disp_y^2+disp_z^2)'
  []
[]

[BCs]

  [dirichlet_partialbottom_x]
    type = DirichletBC
    variable = disp_x
    value = 0
    boundary = 'decoupling_bottom'
  []
  [dirichlet_partialbottom_y]
    type = DirichletBC
    variable = disp_y
    value = 0
    boundary = 'decoupling_bottom'
  []
  [dirichlet_partialbottom_z]
    type = DirichletBC
    variable = disp_z
    value = 0
    boundary = 'decoupling_bottom'
  []

  [dirichlet_bottom_x]
    type = DirichletBC
    variable = disp_x
    value = 0
    boundary = 'bottom'
  []
  [dirichlet_bottom_y]
    type = DirichletBC
    variable = disp_y
    value = 0
    boundary = 'bottom'
  []
  [dirichlet_bottom_z]
    type = DirichletBC
    variable = disp_z
    value = 0
    boundary = 'bottom'
  []

  [bottom_xreal]
    type = NeumannBC
    variable = disp_x
    boundary = 'shaking_bottom'
    value = 1
  []
  [bottom_yreal]
    type = NeumannBC
    variable = disp_y
    boundary = 'shaking_bottom'
    value = 1
  []
  [bottom_zreal]
    type = NeumannBC
    variable = disp_z
    boundary = 'shaking_bottom'
    value = 1
  []

[]


[Materials]
  [elastic_tensor_Al]
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
  # no need for state 0 since it's the default state
  [icebedrock_state_1]
    type = ParsedFunction
    expression = '${icebedrock_coupling_state} = 1'
  []
  [icebedrock_state_2]
    type = ParsedFunction
    expression = '${icebedrock_coupling_state} = 2'
  []
[]

[Controls]
  [func_control]
    type = RealFunctionControl
    parameter = 'Kernels/*/rate'
    function = 'freq2'
    execute_on = 'initial timestep_begin'
  []
  [control_icebedrock_state_1]
    type = ConditionalFunctionEnableControl
    conditional_function = icebedrock_state_1
    disable_objects = 'BCs::dirichlet_bottom_x
                       BCs::dirichlet_bottom_y
                       BCs::dirichlet_bottom_z'
    enable_objects = 'BCs::dirichlet_partialbottom_x
                      BCs::dirichlet_partialbottom_y
                      BCs::dirichlet_partialbottom_z'
    execute_on = 'INITIAL TIMESTEP_BEGIN'
    reverse_on_false = False
  []
  [control_icebedrock_state_2]
    type = ConditionalFunctionEnableControl
    conditional_function = icebedrock_state_2
    disable_objects = 'BCs::dirichlet_bottom_x
                       BCs::dirichlet_bottom_y
                       BCs::dirichlet_bottom_z
                       BCs::dirichlet_partialbottom_x
                       BCs::dirichlet_partialbottom_y
                       BCs::dirichlet_partialbottom_z'
    execute_on = 'INITIAL TIMESTEP_BEGIN'
    reverse_on_false = False
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
