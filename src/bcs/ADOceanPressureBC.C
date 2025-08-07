//* This file is part of the MOOSE framework
//* https://mooseframework.inl.gov
//*
//* All rights reserved, see COPYRIGHT for full restrictions
//* https://github.com/idaholab/moose/blob/master/COPYRIGHT
//*
//* Licensed under LGPL 2.1, please see LICENSE for details
//* https://www.gnu.org/licenses/lgpl-2.1.html

#include "ADOceanPressureBC.h"

registerMooseObject("diucaApp", ADOceanPressureBC);

InputParameters
ADOceanPressureBC::validParams()
{
  InputParameters params = ADIntegratedBC::validParams();
  params.addClassDescription("Imposes the hydrostatic pressure from salt water on a boundary.");
  params.addRequired<Real>("water_density", 1028., "Water density");
  params.addRequired<Real>("g", 9.81, "Gravity acceleration");
  params.addRequired<Real>("water_height", 0., "Water height");
  return params;
}

ADOceanPressureBC::ADOceanPressureBC(const InputParameters & parameters)
  : ADIntegratedBC(parameters)),
    _water_density(getParam<Real>("water_density")),
    _g(getParam<Real>("g")),
    _water_height(getParam<Real>("water_height"))
{
}

Real
ADOceanPressureBC::computeQpResidual()
{

  Real z = _q_point[_qp](2);
  
  ADReal ocean_pressure = _water_density * _g * (_water_height - z);
  
  if (z < 0)
    return _test[_i][_qp] * _normals[_qp] * ocean_pressure;
  else
    return 0.;
}

// Real
// ADOceanPressureBC::computeQpJacobian()
// {
//   return _test[_i][_qp] * _alpha * _phi[_j][_qp] / 2.;
// }
