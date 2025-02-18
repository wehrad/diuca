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

  # [refined]
  #   type = RefineBlockGenerator
  #   input = "convert"
  #   block = "1"
  #   refinement = '0'
  #   enable_neighbor_refinement = true
  #   max_element_volume = 1e6
  # []
  # [coarsened]
  #   type = CoarsenBlockGenerator
  #   input = "refined"
  #   block = "1"
  #   coarsening = '1'
  #   enable_neighbor_refinement = true
  #   # max_element_volume = 1e7
  # []

  # TODO: add layers in z?

  # [triang_4]
  #   type = XYZDelaunayGenerator
  #   boundary = 'convert'
  #   desired_volume = 100000000
  # []
  # final_generator = triang_4

  # [add_bottom]
  #   type = ParsedGenerateNodeset
  #   input = fbcg
  #   expression = 'y = 0 - 0.05 * x'
  #   new_nodeset_name = 'bottom'
  # []
  # [add_top]
  #   type = ParsedGenerateNodeset
  #   input = add_bottom
  #   expression = 'y = thickness - 0.05 * x'
  #   constant_names = 'thickness'
  #   constant_expressions = '${thickness}'
  #   new_nodeset_name = 'top'
  # []
  # [add_left]
  #   type = ParsedGenerateNodeset
  #   input = add_top
  #   expression = 'x = 0'
  #   new_nodeset_name = 'left'
  # []
  # [add_right]
  #   type = ParsedGenerateNodeset
  #   input = add_left
  #   expression = 'x = length'
  #   constant_names = 'length'
  #   constant_expressions = '${length}'
  #   new_nodeset_name = 'right'
  # []

  # [add_bottom]
  #   type = BoundingBoxNodeSetGenerator
  #   input = 'fbcg'
  #   bottom_left = '0 -1 0'
  #   top_right = '500 0 0'
  #   new_boundary = 'bottom'
  # []
  # [add_nodesets]
  #   type = NodeSetsFromSideSetsGenerator
  #   input = fbcg
  # []
  # [create_sideset]
  #   type = SideSetsFromNodeSetsGenerator
  #   input = fbcg
  # []

[]


[Adaptivity]
  [./Markers]
    [./uniform]
      type = UniformMarker
      mark = refine
    [../]
  [../]
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

