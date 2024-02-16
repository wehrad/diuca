# ------------------------ 

# geometry of ice cube
length = 1.
width = 1.
thickness = 1.

[GlobalParams]
  gravity = '0. 0. 0.'
  # integrate_p_by_parts = true
[]

[Mesh]
  type = GeneratedMesh
  dim = 3
  xmin = 0
  xmax = "${length}"
  ymin = 0
  ymax = "${width}"
  zmin = 0
  zmax = "${thickness}"
  nx = 1
  ny = 1
  nz = 1
  elem_type = HEX20
[]

[Variables]
  [velocity]
    order = SECOND
    family = LAGRANGE_VEC
  []
  [p]
    order = FIRST
    family = LAGRANGE
  []
[]

[AuxVariables]
  [vel_x]
    order = SECOND
    family = LAGRANGE
  []
  [vel_y]
    order = SECOND
    family = LAGRANGE
  []
  [vel_z]
    order = SECOND
    family = LAGRANGE
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
  [vel_z]
    type = VectorVariableComponentAux
    variable = vel_z
    vector_variable = velocity
    component = 'z'
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
  [Pressure]
    [front_pressure]
      boundary = front
      function = applied_pressure
      displacements = 'vel_x vel_y vel_z'
    []
    [back_pressure]
      boundary = back
      function = applied_pressure
      displacements = 'vel_x vel_y vel_z'
    []
  []
[]

[Materials]
  [constant_ice]
    type = ADGenericConstantMaterial
    prop_names = 'rho mu'
    prop_values = '1  1'
  []
  [ins_mat]
    type = INSADTauMaterial
    velocity = velocity
    pressure = p
  []
[]

# [Preconditioning]
#   [SMP_PJFNK]
#     type = SMP
#     full = true
#     solve_type = NEWTON
#   []
# []

[Preconditioning]
  [./SMP]
    type = SMP
    full = true
    solve_type = 'NEWTON'
  [../]
[]

[Executioner]
  type = Steady

  petsc_options_iname = '-pc_type -sub_pc_type -sub_pc_factor_levels'
  petsc_options_value = 'bjacobi  ilu          4'

  nl_rel_tol = 1e-12
  nl_max_its = 6
[]

# [Executioner]

#   type = Steady
#   petsc_options_iname = '-ksp_gmres_restart -pc_type -sub_pc_type -sub_pc_factor_levels'
#   petsc_options_value = '300                bjacobi  ilu          4'
#   line_search = none
#   automatic_scaling = true
  
#   # nl_rel_tol = 1e-12
#   # nl_max_its = 6
#   # l_tol = 1e-6
#   # l_max_its = 300

#   nl_rel_tol = 1e-4
#   nl_max_its = 6
#   l_tol = 1e-4
#   l_max_its = 300
  
# []

[Outputs]
  [out]
    type = Exodus
  []
[]

[Functions]
  [applied_pressure]
    type = ConstantFunction
    value = 1e4
  []
[]
