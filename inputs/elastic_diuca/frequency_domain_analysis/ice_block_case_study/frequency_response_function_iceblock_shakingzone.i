# from moose/modules/solid_mechanics/examples/wave_propagation/cantilever_sweep.i

# choose if bed is coupled or not
# bed_coupled = 0

[Mesh]
  [block]
    type = GeneratedMeshGenerator
    elem_type = HEX8
    dim = 3
    xmin = 0
    xmax = 5000.
    nx = 25 # 50
    zmin = 0
    zmax = 5000.
    nz = 25 # 50
    ymin = 0.
    ymax = 600.
    ny = 3 # 6
  []

  [wide_shaking_zone]
    type = SubdomainBoundingBoxGenerator
    input = 'block'
    block_id = 4
    bottom_left = '2200 -1 2200'
    top_right = '2700 101 2700'
  []
  [mesh_combined_interm]
    type = CombinerGenerator
    inputs = 'block wide_shaking_zone'
  []
  # [wide_shaking_zone_refined]
  #   type = RefineBlockGenerator
  #   input = "mesh_combined_interm"
  #   block = '4'
  #   refinement = '1'
  #   enable_neighbor_refinement = true
  # []
  [shaking_bottom]
    type = SideSetsAroundSubdomainGenerator
    # input = 'wide_shaking_zone_refined'
    input = 'mesh_combined_interm'
    block = '4'
    new_boundary = 'shaking_bottom'
    replace = true
    normal = '0 -1 0'
  []

  [delete_bottom]
    type=BoundaryDeletionGenerator
    input='shaking_bottom'
    boundary_names='bottom'
  []

  [add_bottom_back]
    type = ParsedGenerateSideset
    input = 'delete_bottom'
    combinatorial_geometry = '(x < 1750 | x > 2250 | z < 1750 | z > 2250) & (y < 101)'
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
  # [dirichlet_bottom_x]
  #   type = DirichletBC
  #   variable = disp_x
  #   value = 0
  #   boundary = 'bottom'
  # []
  # [dirichlet_bottom_y]
  #   type = DirichletBC
  #   variable = disp_y
  #   value = 0
  #   boundary = 'bottom'
  # []
  # [dirichlet_bottom_z]
  #   type = DirichletBC
  #   variable = disp_z
  #   value = 0
  #   boundary = 'bottom'
  # []

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
    youngs_modulus = 8.7e9 # Pa
    poissons_ratio = 0.32
  []
  [compute_stress]
    type = ComputeLagrangianLinearElasticStress
  []
[]

[Postprocessors]
  # [dispMag]
  #   type = AverageNodalVariableValue
  #   boundary = 'top'
  #   variable = disp_mag
  # []
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
    symbol_values = 917 # ice, kg/m3
    expression = '-t*t*density'
  []
  # [bed_coupling_function]
  #   type = ParsedFunction
  #   expression = '${bed_coupled} = 0'
  # []
[]

[Controls]
  [func_control]
    type = RealFunctionControl
    parameter = 'Kernels/*/rate'
    function = 'freq2'
    execute_on = 'initial timestep_begin'
  []
  # [bed_not_coupled]
  #   type = ConditionalFunctionEnableControl
  #   conditional_function = bed_coupling_function
  #   disable_objects = 'BCs::dirichlet_decoupling_bottom_x BCs::dirichlet_decoupling_bottom_y BCs::dirichlet_decoupling_bottom_z'
  #   execute_on = 'INITIAL TIMESTEP_BEGIN'
  # []
[]

[Executioner]
  type = Transient
  solve_type=LINEAR
  petsc_options_iname = ' -pc_type'
  petsc_options_value = 'lu'
  start_time = 0.1 #starting frequency
  end_time =  6.  #ending frequency
  nl_abs_tol = 1e-6
  [TimeStepper]
    type = ConstantDT
    dt = 0.005  #frequency stepsize
  []
[]

[Outputs]
  csv=true
  exodus=true
  perf_graph=true
[]
