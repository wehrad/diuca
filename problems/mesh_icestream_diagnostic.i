[Mesh]
  [channel]
    type = FileMeshGenerator
    file = mesh_icestream.e
  []
  [diag]
    type = MeshDiagnosticsGenerator
    input = channel
    examine_element_overlap = WARNING
    examine_element_types = WARNING
    examine_element_volumes = WARNING
    examine_non_conformality = WARNING
    examine_nonplanar_sides = INFO
    examine_sidesets_orientation = WARNING
    search_for_adaptivity_nonconformality = WARNING
    check_local_jacobian = WARNING
  []
[]

[Outputs]
  exodus = true
[]
