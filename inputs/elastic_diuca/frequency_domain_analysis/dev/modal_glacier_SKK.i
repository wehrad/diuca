# from moose/modules/solid_mechanics/test/tests/modal_analysis/modal.i

# activate eigen index
index = 0

# choose if bed is coupled or not
bed_coupled = 0

[Mesh]
  [channel]      
    type = FileMeshGenerator
    file = ../../../meshes/mesh_icestream_wtsed.e
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
  []
  [mass_y]
    type = ADCoefReaction
    variable = disp_y
    extra_vector_tags = 'eigen'
    coefficient = -2.7e3
  []
  [mass_z]
    type = ADCoefReaction
    variable = disp_z
    extra_vector_tags = 'eigen'
    coefficient = -2.7e3
  []
  [stiffness_x]
    type = StressDivergenceTensors
    variable = disp_x
    component = 0
  []
  [stiffness_y]
    type = StressDivergenceTensors
    variable = disp_y
    component = 1
  []
  [stiffness_z]
    type = StressDivergenceTensors
    variable = disp_z
    component = 2
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

[Functions]
  [bed_coupling_function]
    type = ParsedFunction
    expression = '${bed_coupled} = 0'
  []
[]

# [Controls]
#   [bed_not_coupled]
#     type = ConditionalFunctionEnableControl
#     conditional_function = bed_coupling_function
#     disable_objects = 'BCs::dirichlet_bottom_x BCs::dirichlet_bottom_y
#                        BCs::dirichlet_bottom_x_e BCs::dirichlet_bottom_y_e'
#     execute_on = 'INITIAL TIMESTEP_BEGIN'
#   []
# []

[Executioner]
  type = Eigenvalue
  solve_type = KRYLOVSCHUR
  which_eigen_pairs = SMALLEST_MAGNITUDE
  n_eigen_pairs = 10
  n_basis_vectors = 5
  petsc_options = '-eps_monitor_all -eps_view'
  petsc_options_iname = '-st_type -eps_target -st_pc_type -st_pc_factor_mat_solver_type'
  petsc_options_value = 'sinvert 0 lu mumps'
  # eigen_tol = 1e-8
  eigen_tol = 1e-6
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
  # perf_graph = true
  execute_on = 'timestep_end'
[]

