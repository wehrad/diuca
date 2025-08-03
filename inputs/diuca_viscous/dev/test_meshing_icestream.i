# length = 10000.
# thickness = 100.

# channel_depth = -800.
# channel_width_spread = 1200.
# side_elevation = 0.
# peak_position = 5000.

[Mesh]
  [gen]
    type = GeneratedMeshGenerator
    dim = 3
    nx = 5
    ny = 5
    nz = 10
    xmin = -0.5
    ymin = -0.5
    xmax = 0.5
    ymax = 0.5
    zmax = 3
  []
  [node_pos]
    type = ParsedNodeTransformGenerator
    input = gen
    x_function = 'x*cos(z) + y*sin(z)'
    y_function = '-x*sin(z) + y*cos(z)'
    z_function = 'z^0.8'
  []
[]

# [Mesh]

#   # make the surface
#   [pcg1]
#     type = ParsedCurveGenerator
#     x_formula = 't'
#     y_formula = '300*sin((2*pi/10000)*t)'
#     # constant_names = 'length thickness'
#     # constant_expressions = '${length} ${thickness}'
#     constant_names = 'pi'
#     constant_expressions = '${fparse pi}'
#     section_bounding_t_values = '0 ${length}'
#     nums_segments = 20
#   []
#   [pcg2]
#     type = ParsedCurveGenerator
#     x_formula = 't'
#     y_formula = '(300*sin((2*pi/10000)*t)) + 5000.'
#     # constant_names = 'length thickness'
#     # constant_expressions = '${length} ${thickness}'
#     constant_names = 'pi'
#     constant_expressions = '${fparse pi}'
#     section_bounding_t_values = '0 ${length}'
#     nums_segments = 20
#   []
#   [fbcg]
#     type = FillBetweenCurvesGenerator
#     input_mesh_1 = pcg1
#     input_mesh_2 = pcg2
#     num_layers = 10
#     bias_parameter = 0.0
#     begin_side_boundary_id = 0
#   []


#   # make the bed
#   [pcg3]
#     type = ParsedCurveGenerator
#     x_formula = '20000'
#     y_formula = 't'
#     z_formula = '(channel_depth * exp((-((t - peak_position) ^ 2)) / (2 * channel_width_spread^2))) + side_elevation'
#     # constant_names = 'length thickness'
#     # constant_expressions = '${length} ${thickness}'
#     constant_names = 'channel_depth peak_position channel_width_spread side_elevation'
#     constant_expressions = '${channel_depth} ${peak_position} ${channel_width_spread} ${side_elevation}'
#     section_bounding_t_values = '0 5000'
#     nums_segments = 20
#   []
#   [pcg4]
#     type = ParsedCurveGenerator
#     x_formula = '0'
#     y_formula = 't'
#     z_formula = '(channel_depth * exp((-((t - peak_position) ^ 2)) / (2 * channel_width_spread^2))) + side_elevation'
#     # constant_names = 'length thickness'
#     # constant_expressions = '${length} ${thickness}'
#     constant_names = 'channel_depth peak_position channel_width_spread side_elevation'
#     constant_expressions = '${channel_depth} ${peak_position} ${channel_width_spread} ${side_elevation}'
#     section_bounding_t_values = '0 5000'
#     nums_segments = 20
#   []
#   [fbcg2]
#     type = FillBetweenCurvesGenerator
#     input_mesh_1 = pcg3
#     input_mesh_2 = pcg4
#     num_layers = 10
#     bias_parameter = 0.0
#     begin_side_boundary_id = 0
#   []

#   final_generator = fbcg2

#   # [pcg2]
#   #   type = ParsedCurveGenerator
#   #   x_formula = 't'
#   #   y_formula = '(300*sin((2*pi/10000)*t)) + 5000.'
#   #   # constant_names = 'length thickness'
#   #   # constant_expressions = '${length} ${thickness}'
#   #   constant_names = 'pi'
#   #   constant_expressions = '${fparse pi}'
#   #   section_bounding_t_values = '0 ${length}'
#   #   nums_segments = 20
#   # []
#   # [fbcg]
#   #   type = FillBetweenCurvesGenerator
#   #   input_mesh_1 = pcg1
#   #   input_mesh_2 = pcg2
#   #   num_layers = 10
#   #   bias_parameter = 0.0
#   #   begin_side_boundary_id = 0
#   # []


#   # [add_bottom]
#   #   type = ParsedGenerateNodeset
#   #   input = fbcg
#   #   expression = 'y = 0 - 0.05 * x'
#   #   new_nodeset_name = 'bottom'
#   # []
#   # [add_top]
#   #   type = ParsedGenerateNodeset
#   #   input = add_bottom
#   #   expression = 'y = thickness - 0.05 * x'
#   #   constant_names = 'thickness'
#   #   constant_expressions = '${thickness}'
#   #   new_nodeset_name = 'top'
#   # []
#   # [add_left]
#   #   type = ParsedGenerateNodeset
#   #   input = add_top
#   #   expression = 'x = 0'
#   #   new_nodeset_name = 'left'
#   # []
#   # [add_right]
#   #   type = ParsedGenerateNodeset
#   #   input = add_left
#   #   expression = 'x = length'
#   #   constant_names = 'length'
#   #   constant_expressions = '${length}'
#   #   new_nodeset_name = 'right'
# # []

#   # [add_bottom]
#   #   type = BoundingBoxNodeSetGenerator
#   #   input = 'fbcg'
#   #   bottom_left = '0 -1 0'
#   #   top_right = '500 0 0'
#   #   new_boundary = 'bottom'
#   # []
#   # [add_nodesets]
#   #   type = NodeSetsFromSideSetsGenerator
#   #   input = fbcg
#   # []
#   # [create_sideset]
#   #   type = SideSetsFromNodeSetsGenerator
#   #   input = fbcg
#   # []

# []


[Variables]
  [./T]
  [../]
[]

[Kernels]
  [./HeatDiff]
    type = ADMatDiffusion
    variable = T
    diffusivity = diffusivity
  [../]
[]

# [BCs]
#   [zero]
#     type = DirichletBC
#     variable = T
#     boundary = 'bottom left right'
#     value = 0
#   []
#   [./top]
#     type = ADFunctionDirichletBC
#     variable = T
#     boundary = 'top'
#     function = '10*sin(pi*x*0.5)'
#   [../]
# []

[Materials]
  [./k]
    type = ADGenericConstantMaterial
    prop_names = diffusivity
    prop_values = 1
  [../]
[]


[Executioner]
  type = Steady
[]

[Outputs]
  exodus = true
[]

