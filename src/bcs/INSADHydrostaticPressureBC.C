//* This file is part of the MOOSE framework
//* https://mooseframework.inl.gov
//*
//* All rights reserved, see COPYRIGHT for full restrictions
//* https://github.com/idaholab/moose/blob/master/COPYRIGHT
//*
//* Licensed under LGPL 2.1, please see LICENSE for details
//* https://www.gnu.org/licenses/lgpl-2.1.html

#include "INSADHydrostaticPressureBC.h"
#include "MooseMesh.h"
#include "INSADObjectTracker.h"
#include "NS.h"

registerMooseObject("diucaApp", INSADHydrostaticPressureBC);

InputParameters
INSADHydrostaticPressureBC::validParams()
{
  InputParameters params = ADVectorIntegratedBC::validParams();

  params.addClassDescription("This class implements the 'No BC' boundary condition based on the "
                             "'Laplace' form of the viscous stress tensor.");
  params.addRequiredCoupledVar(NS::pressure, "pressure");
  params.addParam<bool>("integrate_p_by_parts",
                        true,
                        "Allows simulations to be run with pressure BC if set to false");
  MooseEnum viscous_form("traction laplace", "laplace");
  params.addParam<MooseEnum>("viscous_form",
                             viscous_form,
                             "The form of the viscous term. Options are 'traction' or 'laplace'");

  // Optional parameters
  params.addParam<MaterialPropertyName>("mu_name", "mu", "The name of the dynamic viscosity");
  params.addParam<Real>("water_density", 1028., "Water density");
  params.addParam<Real>("g", 9.81, "Gravity acceleration");
  params.addParam<Real>("water_level", 0., "Water height");
  return params;
}

INSADHydrostaticPressureBC::INSADHydrostaticPressureBC(const InputParameters & parameters)
  : ADVectorIntegratedBC(parameters),
    _p(adCoupledValue(NS::pressure)),
    _integrate_p_by_parts(getParam<bool>("integrate_p_by_parts")),
    _mu(getADMaterialProperty<Real>("mu_name")),
    _form(getParam<MooseEnum>("viscous_form")),
     _water_density(getParam<Real>("water_density")),
    _g(getParam<Real>("g")),
    _water_level(getParam<Real>("water_level"))
{
  std::set<SubdomainID> connected_blocks;
  for (const auto bnd_id : boundaryIDs())
  {
    const auto & these_blocks = _mesh.getBoundaryConnectedBlocks(bnd_id);
    connected_blocks.insert(these_blocks.begin(), these_blocks.end());
  }
  auto & obj_tracker = const_cast<INSADObjectTracker &>(
      _fe_problem.getUserObject<INSADObjectTracker>("ins_ad_object_tracker"));
  for (const auto block_id : connected_blocks)
  {
    obj_tracker.set("viscous_form", _form, block_id);
    obj_tracker.set("integrate_p_by_parts", _integrate_p_by_parts, block_id);
  }
}

ADReal
INSADHydrostaticPressureBC::computeQpResidual()
{
  // Elevation
  const auto z = _q_point[_qp](2);

  if (z > _water_level)
    return 0;

  // Hydrostatic pressure
  const auto hydrostatic_pressure = _water_density * _g * (_water_level - z);

  mooseAssert(_integrate_by_parts,
              "Remove this assert once you've added an error check in the constructor. An "
              "alternative would be to remove this parameter entirely for this class, but this "
              "could be helpful to catch someone setting GlobalParams/integrate_p_by_parts=false");

  return _test[_i][_qp] * _normals[_qp] * hydrostatic_pressure;
}
