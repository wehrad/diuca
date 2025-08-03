[Mesh]
  [extrude]
    type = AdvancedExtruderGenerator
    input = fmg
    heights = '1 2 3'
    num_layers = '1 2 3'
    direction = '0 0 1'
    elem_integer_names_to_swap = 'element_extra_integer_1 element_extra_integer_2'
    elem_integers_swaps = '1 4 2 8;
                           2 7;
                           1 6 |
                           1 8 2 4;
                           2 5;
                           1 6'
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

