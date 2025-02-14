# from moose/modules/solid_mechanics/test/tests/modal_analysis/modal.i
index = 0

# choose if bed is coupled or not
# bed_coupled = 1

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
    bottom_left = '1750 0 1750'
    top_right = '2250 200 2250'
  []
  [mesh_combined_interm]
    type = CombinerGenerator
    inputs = 'block wide_decoupling_zone'
  []
  # [wide_decoupling_zone_refined]
  #   type = RefineBlockGenerator
  #   input = "mesh_combined_interm"
  #   block = '4'
  #   refinement = '3'
  #   enable_neighbor_refinement = true
  # []
  # [decoupling_zone]
  #   type = SubdomainBoundingBoxGenerator
  #   input = 'wide_decoupling_zone_refined'
  #   block_id = 5
  #   bottom_left = '1750 0 1750'
  #   top_right = '2250 100 2250'
  # []
  # [mesh_combined]
  #   type = CombinerGenerator
  #   inputs = 'mesh_combined_interm decoupling_zone'
  # []
  [decoupling_bottom]
    type = SideSetsAroundSubdomainGenerator
    input = 'mesh_combined_interm'
    block = 4 # 5
    new_boundary = 'decoupling_bottom'
    replace = true
    normal = '0 -1 0'
  []

[]

[GlobalParams]
  displacements = 'disp_x disp_y disp_z'
[]

[Variables]
  [disp_x]
  []
  [disp_y]
  []
  [disp_z]
  []
[]

[Kernels]
  [mass_x]
    type = ADCoefReaction
    variable = disp_x
    extra_vector_tags = 'eigen'
    coefficient = -2.7e3
    block = '0 4'
  []
  [mass_y]
    type = ADCoefReaction
    variable = disp_y
    extra_vector_tags = 'eigen'
    coefficient = -2.7e3
    block = '0 4'
  []
  [mass_z]
    type = ADCoefReaction
    variable = disp_z
    extra_vector_tags = 'eigen'
    coefficient = -2.7e3
    block = '0 4'
  []
  [stiffness_x]
    type = StressDivergenceTensors
    variable = disp_x
    component = 0
    block = '0 4'
  []
  [stiffness_y]
    type = StressDivergenceTensors
    variable = disp_y
    component = 1
    block = '0 4'
  []
  [stiffness_z]
    type = StressDivergenceTensors
    variable = disp_z
    component = 2
    block = '0 4'
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
  [dirichlet_bottom_x_e]
    type = EigenDirichletBC
    variable = disp_x
    boundary = 'bottom'
  []
  [dirichlet_bottom_y_e]
    type = EigenDirichletBC
    variable = disp_y
    boundary = 'bottom'
  []
  [dirichlet_bottom_z_e]
    type = EigenDirichletBC
    variable = disp_z
    boundary = 'bottom'
  []

  # [dirichlet_decoupling_bottom_x]
  #   type = DirichletBC
  #   variable = disp_x
  #   value = 0
  #   boundary = 'decoupling_bottom'
  # []
  # [dirichlet_decoupling_bottom_y]
  #   type = DirichletBC
  #   variable = disp_y
  #   value = 0
  #   boundary = 'decoupling_bottom'
  # []
  # [dirichlet_decoupling_bottom_z]
  #   type = DirichletBC
  #   variable = disp_z
  #   value = 0
  #   boundary = 'decoupling_bottom'
  # []
  # [dirichlet_decoupling_bottom_x_e]
  #   type = EigenDirichletBC
  #   variable = disp_x
  #   boundary = 'decoupling_bottom'
  # []
  # [dirichlet_decoupling_bottom_y_e]
  #   type = EigenDirichletBC
  #   variable = disp_y
  #   boundary = 'decoupling_bottom'
  # []
  # [dirichlet_decoupling_bottom_z_e]
  #   type = EigenDirichletBC
  #   variable = disp_z
  #   boundary = 'decoupling_bottom'
  # []

  # [dirichlet_front_x]
  #   type = DirichletBC
  #   variable = disp_x
  #   value = 0
  #   boundary = 'front'
  # []
  # [dirichlet_front_y]
  #   type = DirichletBC
  #   variable = disp_y
  #   value = 0
  #   boundary = 'front'
  # []
  # [dirichlet_front_z]
  #   type = DirichletBC
  #   variable = disp_z
  #   value = 0
  #   boundary = 'front'
  # []
  # [dirichlet_front_x_e]
  #   type = EigenDirichletBC
  #   variable = disp_x
  #   boundary = 'front'
  # []
  # [dirichlet_front_y_e]
  #   type = EigenDirichletBC
  #   variable = disp_y
  #   boundary = 'front'
  # []
  # [dirichlet_front_z_e]
  #   type = EigenDirichletBC
  #   variable = disp_z
  #   boundary = 'front'
  # []

  # [dirichlet_back_x]
  #   type = DirichletBC
  #   variable = disp_x
  #   value = 0
  #   boundary = 'back'
  # []
  # [dirichlet_back_y]
  #   type = DirichletBC
  #   variable = disp_y
  #   value = 0
  #   boundary = 'back'
  # []
  # [dirichlet_back_z]
  #   type = DirichletBC
  #   variable = disp_z
  #   value = 0
  #   boundary = 'back'
  # []
  # [dirichlet_back_x_e]
  #   type = EigenDirichletBC
  #   variable = disp_x
  #   boundary = 'back'
  # []
  # [dirichlet_back_y_e]
  #   type = EigenDirichletBC
  #   variable = disp_y
  #   boundary = 'back'
  # []
  # [dirichlet_back_z_e]
  #   type = EigenDirichletBC
  #   variable = disp_z
  #   boundary = 'back'
  # []
[]

[Materials]
  [elastic_tensor]
    type = ComputeIsotropicElasticityTensor
    youngs_modulus = 8.7e9 # Pa
    poissons_ratio = 0.32
  []
  [compute_stress]
    type = ComputeLinearElasticStress
  []
  [compute_strain]
    type = ComputeSmallStrain
  []
[]

# [Functions]
#   [bed_coupling_function]
#     type = ParsedFunction
#     expression = '${bed_coupled} = 0'
#   []
# []

# [Controls]
#   [bed_not_coupled]
#     type = ConditionalFunctionEnableControl
#     conditional_function = bed_coupling_function
#     disable_objects = 'BCs::dirichlet_decoupling_bottom_x BCs::dirichlet_decoupling_bottom_y
#                        BCs::dirichlet_decoupling_bottom_x_e BCs::dirichlet_decoupling_bottom_y_e'
#     execute_on = 'INITIAL TIMESTEP_BEGIN'
#   []
# []

[Executioner]
  type = Eigenvalue
  solve_type = KRYLOVSCHUR
  which_eigen_pairs = SMALLEST_MAGNITUDE
  n_eigen_pairs = 2
  n_basis_vectors = 5
  petsc_options = '-eps_monitor_all -eps_view'
  petsc_options_iname = '-st_type -eps_target -st_pc_type -st_pc_factor_mat_solver_type'
  petsc_options_value = 'sinvert 0 lu mumps'
  eigen_tol = 1e-8
[]

[VectorPostprocessors]
  [omega_squared]
    type = Eigenvalues
    execute_on = TIMESTEP_END
  []

[]

[Problem]
  type = EigenProblem
  active_eigen_index = ${index}
[]

[Outputs]
  csv = true
  exodus = true
  execute_on = 'timestep_end'
[]

