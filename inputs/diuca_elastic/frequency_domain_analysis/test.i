# ------------------------------------------------- ice parameters
_youngs_modulus = 1e9 # 1e9 # Pa
_poissons_ratio = 0.32

# ------------------------------------------------- Simulation settings

# Frequency domain to sweep in Hz (minimum, maximum and step)
min_freq = 0.1
max_freq = 4
step_freq = 0.01

# ------------------------------------------------- Simulation

[Mesh]
  [block]
    type = GeneratedMeshGenerator
    elem_type = HEX8
    dim = 3
    xmin = 0
    xmax = 5000.
    nx = 20
    zmin = 0
    zmax = 5000.
    nz = 20
    ymin = 0.
    ymax = 600.
    ny = 10
    subdomain_ids="1"
  []

  # Create sediment layer by projecting glacier bed by
  # the sediment thickness
  [lowerDblock_sediment]
    type = LowerDBlockFromSidesetGenerator
    input = "block"
    new_block_name = "block_5"
    sidesets = "bottom"
  []
  [separateMesh_sediment]
    type = BlockToMeshConverterGenerator
    input = lowerDblock_sediment
    target_blocks = "block_5"
  []
  [extrude_sediment]
    type = MeshExtruderGenerator
    input = separateMesh_sediment
    num_layers = 2
    extrusion_vector = '0. -500 0.'
    # bottom/top swap is (correct and) due to inverse extrusion
    top_sideset = 'bottom_bedrock'
  []
  [stitch_sediment]
    type = StitchedMeshGenerator
    inputs = 'block extrude_sediment'
    stitch_boundaries_pairs = 'bottom bottom_bedrock'
  []

  # final_generator = stitch_sediment
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
        # block="0 1"
      []
    []
  []
[]

[Kernels]
    #reaction terms
    [reaction_realy]
        type = Reaction
        variable = disp_y
        rate = 0# filled by controller
        extra_vector_tags = 'ref'
        block = '1' # 4'
    []
    #reaction terms
    # [reaction_realx]
    #     type = Reaction
    #     variable = disp_x
    #     rate = 0# filled by controller
    #     extra_vector_tags = 'ref'
    #     block = '0' # 4'
    # []
    #reaction terms
    # [reaction_realz]
    #     type = Reaction
    #     variable = disp_z
    #     rate = 0# filled by controller
    #     extra_vector_tags = 'ref'
    #     block = '0' # 4'
    # []
[]

[AuxVariables]
  [disp_mag]
  []
[]

[AuxKernels]
  [disp_mag]
    type = ParsedAux
    variable = disp_mag
    # coupled_variables = 'disp_x disp_z'
    coupled_variables = 'disp_x disp_z disp_y'
    expression = 'sqrt(disp_x^2+disp_z^2+disp_y^2)'
    # expression = 'abs(disp_y)'
  []
[]

[BCs]

  # [dirichlet_bottom_x]
  #   type = DirichletBC
  #   variable = disp_x
  #   value = 0
  #   boundary = 'bottom'
  # []
  # [dirichlet_bottom_z]
  #   type = DirichletBC
  #   variable = disp_z
  #   value = 0
  #   boundary = 'bottom'
  # []
  # [dirichlet_bottom_y]
  #   type = DirichletBC
  #   variable = disp_y
  #   value = 0
  #   boundary = 'bottom'
  # []

  # [dirichlet_bottom_bedrock_x]
    type = DirichletBC
    variable = disp_x
    value = 0
    boundary = 'bottom_bedrock'
  []
  [dirichlet_bottom_bedrock_z]
    type = DirichletBC
    variable = disp_z
    value = 0
    boundary = 'bottom_bedrock'
  []
  [dirichlet_bottom_bedrock_y]
    type = DirichletBC
    variable = disp_y
    value = 0
    boundary = 'bottom_bedrock'
  []
  
  # [dirichlet_bottom_y]
  #   type = DirichletBC
  #   variable = disp_y
  #   value = 0
  #   boundary = 'bottom'
  # []

  [surface_yreal]
    type = NeumannBC
    variable = disp_y
    boundary = 'top'
    value = 1000
  []
  
  # [surface_xreal]
  #   type = NeumannBC
  #   variable = disp_x
  #   boundary = 'top'
  #   value = 1000
  # []
  # [surface_zreal]
  #   type = NeumannBC
  #   variable = disp_z
  #   boundary = 'top left right back front'
  #   value = 1000
  # []
[]


[Materials]
  [elastic_tensor_ice]
    block = "1"
    type = ComputeIsotropicElasticityTensor
    youngs_modulus = '${_youngs_modulus}'
    poissons_ratio = '${_poissons_ratio}'
  []
  [compute_stress_ice]
    block = "1"
    type = ComputeLagrangianLinearElasticStress
  []
  [elastic_tensor_bedrock]
    block = "0"
    type = ComputeIsotropicElasticityTensor
    youngs_modulus = 1e9 # 70e9
    poissons_ratio = 0.25
  []
  [compute_stress_bedrock]
    block = "0"
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

# [Postprocessors]
#   [dispMag]
#     type = NodalExtremeValue
#     value_type = max
#     variable = disp_mag
#   []
# []

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
  console = true
[]
