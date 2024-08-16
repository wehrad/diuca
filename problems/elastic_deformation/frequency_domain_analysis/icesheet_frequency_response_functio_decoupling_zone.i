# from moose/modules/solid_mechanics/examples/wave_propagation/cantilever_sweepi.

# choose if bed is coupled or not
bed_coupled = 0

[Mesh]
  [block]
    type = GeneratedMeshGenerator
    elem_type = HEX8
    dim = 3
    xmin = 0
    xmax = 4000.
    nx = 20
    zmin = 0
    zmax = 4000.
    nz = 20
    ymin = 100.
    ymax = 700.
    ny = 10
  []

  [wide_decoupling_zone]
    type = SubdomainBoundingBoxGenerator
    input = 'block'
    block_id = 4
    bottom_left = '1750 99 1750'
    top_right = '2250 161 2250'
  []
  [mesh_combined_interm]
    type = CombinerGenerator
    inputs = 'block wide_decoupling_zone'
  []
  [wide_decoupling_zone_refined]
    type = RefineBlockGenerator
    input = "mesh_combined_interm"
    block = '4'
    refinement = '2'
    enable_neighbor_refinement = true
  []
  [decoupling_bottom]
    type = SideSetsAroundSubdomainGenerator
    input = 'wide_decoupling_zone_refined'
    block = '4'
    new_boundary = 'decoupling_bottom'
    replace = true
    normal = '0 -1 0'
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
        block = '0 4'
    []
    [reaction_realy]
        type = Reaction
        variable = disp_y
        rate = 0# filled by controller
        extra_vector_tags = 'ref'
        block = '0 4'
    []
    [reaction_realz]
        type = Reaction
        variable = disp_z
        rate = 0# filled by controller
        extra_vector_tags = 'ref'
        block = '0 4'
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

  [right_xreal]
    type = NeumannBC
    variable = disp_x
    boundary = 'right'
    value = 1000
  []
  [right_yreal]
    type = NeumannBC
    variable = disp_y
    boundary = 'right'
    value = 1000
  []
  [right_zreal]
    type = NeumannBC
    variable = disp_z
    boundary = 'right'
    value = 1000
  []

  [left_xreal]
    type = NeumannBC
    variable = disp_x
    boundary = 'left'
    value = 1000
  []
  [left_yreal]
    type = NeumannBC
    variable = disp_y
    boundary = 'left'
    value = 1000
  []
  [left_zreal]
    type = NeumannBC
    variable = disp_z
    boundary = 'left'
    value = 1000
  []

  [front_xreal]
    type = NeumannBC
    variable = disp_x
    boundary = 'front'
    value = 1000
  []
  [front_yreal]
    type = NeumannBC
    variable = disp_y
    boundary = 'front'
    value = 1000
  []
  [front_zreal]
    type = NeumannBC
    variable = disp_z
    boundary = 'front'
    value = 1000
  []

  [back_xreal]
    type = NeumannBC
    variable = disp_x
    boundary = 'back'
    value = 1000
  []
  [back_yreal]
    type = NeumannBC
    variable = disp_y
    boundary = 'back'
    value = 1000
  []
  [back_zreal]
    type = NeumannBC
    variable = disp_z
    boundary = 'back'
    value = 1000
  []

  # [bottom_xreal]
  #   type = NeumannBC
  #   variable = disp_x
  #   boundary = 'bottom'
  #   value = 1000
  # []
  # [bottom_yreal]
  #   type = NeumannBC
  #   variable = disp_y
  #   boundary = 'bottom'
  #   value = 1000
  # []
  # [bottom_zreal]
  #   type = NeumannBC
  #   variable = disp_z
  #   boundary = 'bottom'
  #   value = 1000
  # []

[]


[Materials]
  [elastic_tensor_Al]
    type = ComputeIsotropicElasticityTensor
    youngs_modulus = 8.7e9 # Pa
    poissons_ratio = 0.32
  []
  [compute_stress]
    type = ComputeLagrangianLinearElasticStress
  []
[]

[Postprocessors]
  [dispMag]
    type = NodalExtremeValue
    value_type = max
    variable = disp_mag
  []
[]

[Functions]
  [freq2]
    type = ParsedFunction
    symbol_names = density
    symbol_values = 2.7e3 #Al kg/m3
    expression = '-t*t*density'
  []
  [bed_coupling_function]
    type = ParsedFunction
    expression = '${bed_coupled} = 0'
  []
[]

[Controls]
  [func_control]
    type = RealFunctionControl
    parameter = 'Kernels/*/rate'
    function = 'freq2'
    execute_on = 'initial timestep_begin'
  []
  [bed_not_coupled]
    type = ConditionalFunctionEnableControl
    conditional_function = bed_coupling_function
    disable_objects = 'BCs::dirichlet_decoupling_bottom_x BCs::dirichlet_decoupling_bottom_y BCs::dirichlet_decoupling_bottom_z'
    execute_on = 'INITIAL TIMESTEP_BEGIN'
  []
[]

[Executioner]
  type = Transient
  solve_type=LINEAR
  petsc_options_iname = ' -pc_type'
  petsc_options_value = 'lu'
  start_time = 0.01 #starting frequency
  end_time =  2.  #ending frequency
  nl_abs_tol = 1e-6
  [TimeStepper]
    type = ConstantDT
    dt = 0.05  #frequency stepsize
  []
[]

[Outputs]
  csv=true
  exodus=true
[]
