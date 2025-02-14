# ------------------------ 

# slope of the bottom boundary (in degrees)
bed_slope = 0. # 5

# change coordinate system to add a slope
gravity_x = ${fparse
  	      cos((90 - bed_slope) / 180 * pi) * 9.81 
              }  # * 1e-6
gravity_y = ${fparse
	      - cos(bed_slope / 180 * pi) * 9.81 
              } # * 1e-6

# geometry of the ice slab (converging nb_years=1)
# length = 200
# thickness = 100

#  geometry of the ice slab (converging nb_years=1)
length = 1000
thickness = 100

#  geometry of the ice slab (not converging)
# length = 5000
# thickness = 400

# dt associated with rest time associated with the
# geometry (in seconds)
# ice has a high viscosity and hence response times
# of years
_dt = 0.01

# Initial finite strain rate for viscosity rampup
initial_II_eps_min = 1e-2

# ------------------------

# [GlobalParams]
#   use_displaced_mesh = true
# []

[Functions]
  [viscosity_rampup]
    type = ParsedFunction
    expression = 'initial_II_eps_min * exp(-(t-_dt)) * 1e-1'
    # expression = 'initial_II_eps_min'
    symbol_names = '_dt initial_II_eps_min'
    symbol_values = '${_dt} ${initial_II_eps_min}'
  []
[]

[Controls]
  [II_eps_min_control]
    type = RealFunctionControl
    parameter = 'Materials/ice/II_eps_min'
    function = 'viscosity_rampup'
    execute_on = 'initial timestep_begin'
  []
[]

[Mesh]
  type = GeneratedMesh
  dim = 2
  xmin = 0
  xmax = '${length}'
  ymin = 0
  ymax = '${thickness}'
  nx = 50
  ny = 5
  elem_type = QUAD9  
[]

# [GlobalParams]
#   order = FIRST
#   integrate_p_by_parts = true
# []

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
    order = SECOND
  []
  [p]
  []
[]

[Kernels]
  [mass]
    type = INSADMass
    variable = p
  []
  [momentum_time]
    type = INSADMomentumTimeDerivative
    variable = velocity
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
  [gravity]
    type = INSADGravityForce
    variable = velocity
    gravity = '${gravity_x} ${gravity_y} 0.'
  []
[]

[BCs]

  # [Periodic]
  #   [up_down]
  #     primary = left
  #     secondary = right
  #     translation = '${length} 0 0'
  #     variable = 'velocity'
  #   []
  # []
  
  # [inlet]
  #   type = ADVectorFunctionDirichletBC
  #   variable = velocity
  #   boundary = 'left'
  #   function_x = 0.
  #   function_y = 0.
  # []
  
  [noslip]
    type = ADVectorFunctionDirichletBC
    variable = velocity
    boundary = 'bottom'
    function_x = 0.
    function_y = 0.
  []
  
[]

[Materials]
  [ice]
    type = ADIceMaterial
    velocity_x = "vel_x"
    velocity_y = "vel_y"
    pressure = "p"
    outputs = "out"
    output_properties = "rho mu"
  []
  [ins_mat]
    type = INSADTauMaterial
    velocity = velocity
    pressure = p
  []
[]

# [Preconditioning]
#   [SMP]
#     type = SMP
#     full = true
#     solve_type = 'NEWTON'
#   []
# []

[Preconditioning]
  active = ''
  # [FSP]
  #   type = FSP
  #   # It is the starting point of splitting
  #   topsplit = 'up' # 'up' should match the following block name
  #   [up]
  #     splitting = 'u p' # 'u' and 'p' are the names of subsolvers
  #     splitting_type = schur
  #     # Splitting type is set as schur, because the pressure part of Stokes-like systems
  #     # is not diagonally dominant. CAN NOT use additive, multiplicative and etc.
  #     #
  #     # Original system:
  #     #
  #     # | Auu Aup | | u | = | f_u |
  #     # | Apu 0   | | p |   | f_p |
  #     #
  #     # is factorized into
  #     #
  #     # |I             0 | | Auu  0|  | I  Auu^{-1}*Aup | | u | = | f_u |
  #     # |Apu*Auu^{-1}  I | | 0   -S|  | 0  I            | | p |   | f_p |
  #     #
  #     # where
  #     #
  #     # S = Apu*Auu^{-1}*Aup
  #     #
  #     # The preconditioning is accomplished via the following steps
  #     #
  #     # (1) p* = f_p - Apu*Auu^{-1}f_u,
  #     # (2) p = (-S)^{-1} p*
  #     # (3) u = Auu^{-1}(f_u-Aup*p)
  #     petsc_options = '-pc_fieldsplit_detect_saddle_point'
  #     petsc_options_iname = '-pc_fieldsplit_schur_fact_type  -pc_fieldsplit_schur_precondition -ksp_gmres_restart -ksp_rtol -ksp_type'
  #     petsc_options_value = 'full                            selfp                             300                1e-4      fgmres'
  #   []
  #   [u]
  #     vars = 'vel_x vel_y'
  #     petsc_options_iname = '-pc_type -pc_hypre_type -ksp_type -ksp_rtol -ksp_gmres_restart -ksp_pc_side'
  #     petsc_options_value = 'hypre    boomeramg      gmres    5e-1      300                 right'
  #   []
  #   [p]
  #     vars = 'p'
  #     petsc_options_iname = '-ksp_type -ksp_gmres_restart -ksp_rtol -pc_type -ksp_pc_side'
  #     petsc_options_value = 'gmres    300                5e-1      jacobi    right'
  #   []
  # []
  [SMP]
    type = SMP
    full = true
    petsc_options_iname = '-pc_type -pc_factor_shift_type'
    petsc_options_value = 'lu       NONZERO'
  []
[]

[Executioner]
  type = Transient
  num_steps = 1000

  petsc_options_iname = '-pc_type -pc_factor_shift_type'
  petsc_options_value = 'lu       NONZERO'
  
  # petsc_options = '-pc_svd_monitor'
  # petsc_options_iname = '-pc_type'
  # petsc_options_value = 'svd'
  # petsc_options = '-pc_type fieldsplit -pc_fieldsplit_type schur -pc_fieldsplit_detect_saddle_point'
  # petsc_options = '--ksp_monitor'

  # nl_rel_tol = 1e-08
  # nl_abs_tol = 1e-13
  # nl_rel_tol = 1e-07

  # nl_abs_tol = 2e-06
  nl_abs_tol = 2e-05

  # l_tol = 1e-6
  l_tol = 1e-4

  nl_max_its = 100
  nl_forced_its = 3
  line_search = none

  dt = '${_dt}'
  # steady_state_detection = true
  # steady_state_tolerance = 1e-100
  check_aux = true
 
[]

[Outputs]
  console = true
  [out]
    type = Exodus
  []
[]
