sediment_layer_thickness = 50.

[Mesh]

  [channel]
    type = FileMeshGenerator
    # file = ../../../meshes/mesh_icestream_sed.e
    file = generate_icestream_mesh_out.e
  []

  # [delete_sediment_block]
  #   type = BlockDeletionGenerator
  #   input = channel
  #   block = '3'
  # []

  # Create sediment layer by projecting glacier bed by
  # the sediment thickness
  [lowerDblock_sediment]
    type = LowerDBlockFromSidesetGenerator
    # input = "delete_sediment_block"
    input = "channel"
    new_block_name = "block_0"
    sidesets = "bottom"
  []
  [separateMesh_sediment]
    type = BlockToMeshConverterGenerator
    input = lowerDblock_sediment
    target_blocks = "block_0"
  []
  [extrude_sediment]
    type = MeshExtruderGenerator
    input = separateMesh_sediment
    num_layers = 1
    extrusion_vector = '0. 0. -${sediment_layer_thickness}'
    # bottom/top swap is (correct and) due to inverse extrusion
    top_sideset = 'top_sediment'
    bottom_sideset = 'bottom_sediment'
  []
  [stitch_sediment]
    type = StitchedMeshGenerator
    inputs = 'channel extrude_sediment'
    stitch_boundaries_pairs = 'bottom bottom_sediment'
  []

  [add_sediment_lateral_sides]
    type = ParsedGenerateSideset
    combinatorial_geometry = 'y > 9999.99 | y < 0.01'
    included_subdomains = 0
    new_sideset_name = 'left_right_sediment'
    input = 'stitch_sediment'
    replace = True
  []

  [add_sediment_upstream_side]
    type = ParsedGenerateSideset
    combinatorial_geometry = 'x < 0.01'
    included_subdomains = 0
    new_sideset_name = 'upstream_sediment'
    input = 'add_sediment_lateral_sides'
    replace = True
  []
  [add_sediment_downstream_side]
    type = ParsedGenerateSideset
    combinatorial_geometry = 'x > 19599.99'
    included_subdomains = 0
    new_sideset_name = 'downstream_sediment'
    input = 'add_sediment_upstream_side'
    replace = True
  []

  [add_nodesets]
    type = NodeSetsFromSideSetsGenerator
    input = 'add_sediment_downstream_side'
  []

  [final_mesh]
    type = SubdomainBoundingBoxGenerator
    restricted_subdomains="1"
    input = add_nodesets
    block_id = 255
    block_name = deactivated
    bottom_left = '18500 -100 -100'
    top_right = '22000 11000 150'
  []

  [refined_mesh]
    type = RefineBlockGenerator
    input = "final_mesh"
    block = "255"
    refinement = '1'
    enable_neighbor_refinement = true
    max_element_volume = 1e100
  []

  [final_mesh2]
    type = SubdomainBoundingBoxGenerator
    input = refined_mesh
    restricted_subdomains="0"
    block_id = 254
    block_name = flood
    bottom_left = '10000 4900 -1e4'
    top_right = '22000  5700 1e4'
  []

  final_generator = final_mesh2


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
