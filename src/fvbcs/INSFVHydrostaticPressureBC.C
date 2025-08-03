//* This file is part of the MOOSE framework
//* https://www.mooseframework.org
//*
//* All rights reserved, see COPYRIGHT for full restrictions
//* https://github.com/idaholab/moose/blob/master/COPYRIGHT
//*
//* Licensed under LGPL 2.1, please see LICENSE for details
//* https://www.gnu.org/licenses/lgpl-2.1.html

#include "INSFVHydrostaticPressureBC.h"
#include "NS.h"

registerMooseObject("diucaApp", INSFVHydrostaticPressureBC);

InputParameters
INSFVHydrostaticPressureBC::validParams()
{
  InputParameters params = INSFVFreeSurfaceBC::validParams();
  params.addClassDescription(
      "Apply hydrostatic pressure on a boundary");
  params.addParam<Real>("water_density", 1028., "Stress to apply");
  params.declareControllable("water_density");
  return params;
}

INSFVHydrostaticPressureBC::INSFVHydrostaticPressureBC(
    const InputParameters & params)
  : INSFVFreeSurfaceBC(params),
    _water_density(getParam<Real>("water_density"))
{
}

void
INSFVHydrostaticPressureBC::gatherRCData(const FaceInfo & fi)
{
  _face_info = &fi;
  _face_type = fi.faceType(std::make_pair(_var.number(), _var.sys().number()));

  Real _elevation = fi.elemCentroid()(2);

  if (_elevation < 0.){
    Real _hydrostatic_pressure = -1028. * 9.81 * _elevation; // positive for compression
    const auto strong_resid = fi.normal()(_index) * _hydrostatic_pressure;
    addResidualAndJacobian(strong_resid * (fi.faceArea() * fi.faceCoord()));
  }
}
