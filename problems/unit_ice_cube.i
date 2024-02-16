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
  [p]
    order = FIRST
    family = LAGRANGE
  []
[]

[Kernels]
  [mass]
    type = INSMass
    variable = p
    u = vel_x
    v = vel_y
    w = vel_z
    pressure = p
  []
  [x_momentum_space]
    type = INSMomentumLaplaceForm
    variable = vel_x
    u = vel_x
    v = vel_y
    w = vel_z
    pressure = p
    component = 0
  []
  [y_momentum_space]
    type = INSMomentumLaplaceForm
    variable = vel_y
    u = vel_x
    v = vel_y
    w = vel_z
    pressure = p
    component = 1
  []
  [z_momentum_space]
    type = INSMomentumLaplaceForm
    variable = vel_z
    u = vel_x
    v = vel_y
    w = vel_z
    pressure = p
    component = 2
  []
[]

[BCs]
  [x_no_slip]
    type = DirichletBC
    variable = vel_x
    boundary = 'back top bottom left right'
    value = 0.0
  []
  [y_no_slip]
    type = DirichletBC
    variable = vel_y
    boundary = 'back top bottom left right'
    value = 0.0
  []
  [z_no_slip]
    type = DirichletBC
    variable = vel_z
    boundary = 'back top bottom left right'
    value = 0.0
  []
[]

[Materials]
  [constant_ice]
    type = GenericConstantMaterial
    block = 0
    prop_names = 'rho mu' 
    prop_values = '917. 3.'
  []
[]

[Preconditioning]
  [SMP_PJFNK]
    type = SMP
    full = true
    solve_type = NEWTON
  []
[]

[Executioner]

  type = Steady
  petsc_options_iname = '-ksp_gmres_restart -pc_type -sub_pc_type -sub_pc_factor_levels'
  petsc_options_value = '300                bjacobi  ilu          4'
  line_search = none
  automatic_scaling = true
  
  # nl_rel_tol = 1e-12
  # nl_max_its = 6
  # l_tol = 1e-6
  # l_max_its = 300

  nl_rel_tol = 1e-4
  nl_max_its = 6
  l_tol = 1e-4
  l_max_its = 300
  
[]

[Outputs]
  [out]
    type = Exodus
  []
[]

[Functions]
  [weight]
    type = ParsedFunction
    value = '917 * 9.81 * 1e-6 * (${thickness}-z)'
  []
[]

[ICs]
  [pressure_weight]
    type = FunctionIC
    variable = p
    function = weight
  []
[]
