# based on modules/navier_stokes/test/tests/finite_element/ins/RZ_cone/ad_rz_cone_by_parts_steady_stabilized.i

[GlobalParams]
  order = FIRST
  integrate_p_by_parts = true
[]

[Mesh]
  type = GeneratedMesh
  dim = 2
  xmin = 0
  xmax = 1
  ymin = 0
  ymax = 1
  nx = 2
  ny = 2
  elem_type = QUAD9
[]

[AuxVariables]
  [vel_x]
  []
  [vel_y]
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
[]

[Variables]
  [velocity]
    family = LAGRANGE_VEC
  []
  [p]
  []
[]

[Kernels]
  [mass]
    type = INSADMass
    variable = p
  []
  [mass_pspg]
    type = INSADMassPSPG
    variable = p
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
[]

[BCs]
  [inlet]
    type = VectorFunctionDirichletBC
    variable = velocity
    boundary = 'bottom'
    function_x = 0
    function_y = 1. # m.a-1
  []
  [inlet2]
    type = VectorFunctionDirichletBC
    variable = velocity
    boundary = 'top'
    function_x = 0
    function_y = -1. # m.a-1
  []
  [axis]
    type = ADVectorFunctionDirichletBC
    variable = velocity
    boundary = 'left'
    set_y_comp = false
  []
[]

[Materials]
  [const]
    type = ADGenericConstantMaterial
    prop_names = 'rho mu'
    # prop_values = '917. 3.' # kg.m-3 MPa.a
    prop_values = '1. 1.' # kg.m-3 MPa.a
  []
  [ins_mat]
    type = INSADTauMaterial
    velocity = velocity
    pressure = p
  []
[]

[Preconditioning]
  [SMP]
    type = SMP
    full = true
    solve_type = 'NEWTON'
  []
[]

[Executioner]
  type = Steady

  petsc_options_iname = '-pc_type -sub_pc_type -sub_pc_factor_levels'
  petsc_options_value = 'bjacobi  ilu          4'

  nl_rel_tol = 1e-12
  nl_max_its = 6
[]

[Outputs]
  console = true
  [out]
    type = Exodus
  []
[]

# [Postprocessors]
#   [flow_in]
#     type = VolumetricFlowRate
#     vel_x = vel_x
#     vel_y = vel_y
#     boundary = 'bottom'
#     execute_on = 'timestep_end'
#   []
#   [flow_out]
#     type = VolumetricFlowRate
#     vel_x = vel_x
#     vel_y = vel_y
#     boundary = 'top'
#     execute_on = 'timestep_end'
#   []
# []

[Functions]
  [applied_pressure]
    type = ConstantFunction
    value = 1e4
  []
[]
