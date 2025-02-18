# This input files creates an ice stream mesh with sinusoidal
# alongflow geometry, a gaussian-like acrossflow geometry, and surface
# slope.

# The front geometry is first created in the XY geometry before it's extructed along the glacier length, and nodes transformed to include the sinusoid.
length = 20000.
width = 10000.

channel_depth = -900.
channel_width_spread = 1200.
side_elevation = 0.001
peak_position = 5000.
surface_slope = 0.02
front_elevation = 100.

nb_elements_alongflow = 10
nb_elements_acrossflow = 10
nb_elements_depth = 5

[Mesh]

  # make the front face on the XY plane with the acrossflow trough (pcg1/y_formula)
  # and the front elevation (pcg2/y_formula)
  [pcg1]
    type = ParsedCurveGenerator
    x_formula = 't'
    y_formula = '(channel_depth * exp((-((t - peak_position) ^ 2)) / (2 * channel_width_spread^2))) + side_elevation'
    constant_names = 'channel_depth peak_position channel_width_spread side_elevation'
    constant_expressions = '${channel_depth} ${peak_position} ${channel_width_spread} ${side_elevation}'
    section_bounding_t_values = '0 ${width}'
    nums_segments = '${nb_elements_acrossflow}'
  []
  [pcg2]
    type = ParsedCurveGenerator
    x_formula = 't'
    y_formula = '${front_elevation}'
    section_bounding_t_values = '0 ${width}'
    nums_segments = '${nb_elements_acrossflow}'
  []
  [fbcg2]
    type = FillBetweenCurvesGenerator
    input_mesh_1 = pcg1
    input_mesh_2 = pcg2
    num_layers = '${nb_elements_depth}'
    bias_parameter = 0.0
    begin_side_boundary_id = 0
  []

  # extrude along Z axis, along the glacier length
  [make3D]
    type = MeshExtruderGenerator
    extrusion_vector = '0 0 ${length}'
    num_layers = '${nb_elements_alongflow}'
    input = fbcg2
  []

  # add alongflow sinusoid (x_function) and surface slope (y_function)
  [add_sinusoidal]
    type = ParsedNodeTransformGenerator
    input = make3D
    x_function = "x + (300*sin((2*pi/10000)*z))"
    y_function = 'if(y > side_elevation, y + (((length - z) * surface_slope) * ((y - side_elevation) / front_elevation)), y)'
    z_function = "z"
    constant_names = 'pi side_elevation surface_slope length front_elevation'
    constant_expressions = '${fparse pi} ${side_elevation} ${surface_slope} ${length} ${front_elevation}'
  []

  # convert the modified elements to tetrahedrons
  [convert]
    type = ElementsToTetrahedronsConverter
    input = add_sinusoidal
  []

  # rotate for X, Y and Z to be alongflow, acrossflow and depth respectively
  [rotate]
    type = TransformGenerator
    input = convert
    transform = ROTATE
    vector_value = '0 90 90'
  []

  # now add the side sets
  [add_sidesets]
    type = SideSetsFromNormalsGenerator
    input = rotate
    normals = '0  0 -1
               0  1  0
               0 -1  0
               1  0  0
              -1  0  0
               0  0  1'
    fixed_normal = false
    new_boundary = 'bottom right left front back surface'
    normal_tol=0.5 # very high to include e.g. a steep bed 
  []


  # and the node sets
  [add_nodesets]
    type = NodeSetsFromSideSetsGenerator
    input = add_sidesets
  []

[]

[Executioner]
  type = Steady
[]

[Postprocessors]
  [volume]
    type = VolumePostprocessor
  []
[]

[Problem]
  solve = false
[]

[Outputs]
  exodus = true
[]
