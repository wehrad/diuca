length = 20000.
width = 10000.

channel_depth = -800.
channel_width_spread = 1200.
side_elevation = 0.
peak_position = 5000.
surface_slope = 0.02

[Mesh]

  # make the surface by filling between left and right
  # [pcg1]
  #   type = ParsedCurveGenerator
  #   x_formula = 't'
  #   y_formula = '300*sin((2*pi/10000)*t)'
  #   constant_names = 'pi'
  #   constant_expressions = '${fparse pi}'
  #   section_bounding_t_values = '0 ${length}'
  #   nums_segments = 20
  # []
  # [pcg2]
  #   type = ParsedCurveGenerator
  #   x_formula = 't'
  #   y_formula = '(300*sin((2*pi/10000)*t)) + 5000.'
  #   constant_names = 'pi'
  #   constant_expressions = '${fparse pi}'
  #   section_bounding_t_values = '0 ${length}'
  #   nums_segments = 20
  # []
  # [fbcg]
  #   type = FillBetweenCurvesGenerator
  #   input_mesh_1 = pcg1
  #   input_mesh_2 = pcg2
  #   num_layers = 10
  #   bias_parameter = 0.0
  #   begin_side_boundary_id = 0
  # []


  # make the front face on the XY plane
  [pcg1]
    type = ParsedCurveGenerator
    x_formula = 't'
    y_formula = '(channel_depth * exp((-((t - peak_position) ^ 2)) / (2 * channel_width_spread^2))) + side_elevation'
    constant_names = 'channel_depth peak_position channel_width_spread side_elevation'
    constant_expressions = '${channel_depth} ${peak_position} ${channel_width_spread} ${side_elevation}'
    section_bounding_t_values = '0 ${width}'
    nums_segments = 20
  []
  [pcg2]
    type = ParsedCurveGenerator
    x_formula = 't'
    y_formula = '100'
    section_bounding_t_values = '0 ${width}'
    nums_segments = 20
  []
  [fbcg2]
    type = FillBetweenCurvesGenerator
    input_mesh_1 = pcg1
    input_mesh_2 = pcg2
    num_layers = 5
    bias_parameter = 0.0
    begin_side_boundary_id = 0
  []

  # extrude along Z axis
  [make3D]
    type = MeshExtruderGenerator
    extrusion_vector = '0 0 ${length}'
    num_layers = 20
    # bottom_sideset = 'bottom'
    # top_sideset = 'top'
    input = fbcg2
  []

  [add_sinusoidal]
    type = ParsedNodeTransformGenerator
    input = make3D
    x_function = "x + (300*sin((2*pi/10000)*z))"
    # x_function = 'x + z/10'
    # y_function = "(300*sin((2*pi/10000)*x))"
    y_function = 'if(y >= side_elevation, y + ((length - z) * surface_slope), y)'
    z_function = "z"
    constant_names = 'pi side_elevation surface_slope length'
    constant_expressions = '${fparse pi} ${side_elevation} ${surface_slope} ${length}'
  []
  [convert]
    type = ElementsToTetrahedronsConverter
    input = add_sinusoidal
  []
  # final_generator = fbcg2

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

