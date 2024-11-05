//* This file is part of the MOOSE framework
//* https://www.mooseframework.org
//*
//* All rights reserved, see COPYRIGHT for full restrictions
//* https://github.com/idaholab/moose/blob/master/COPYRIGHT
//*
//* Licensed under LGPL 2.1, please see LICENSE for details
//* https://www.gnu.org/licenses/lgpl-2.1.html

#include "INSFVStressMomentumFluxBC.h"
#include "NS.h"

registerMooseObject("diucaApp", INSFVStressMomentumFluxBC);

InputParameters
INSFVStressMomentumFluxBC::validParams()
{
  InputParameters params = INSFVFreeSurfaceBC::validParams();
  params.addClassDescription(
      "Imparts a stress on the momentum equation");
  // params.addParam<MaterialPropertyName>("rc_pressure", "rc_pressure", "The recoil pressure");
  params.addParam<ADReal>("value", 0., "Stress to apply");
  params.declareControllable("value");
  
  return params;
}

INSFVStressMomentumFluxBC::INSFVStressMomentumFluxBC(
    const InputParameters & params)
  : INSFVFreeSurfaceBC(params),
    _sig(getParam<ADReal>("value"))
{
}

void
INSFVStressMomentumFluxBC::gatherRCData(const FaceInfo & fi)
{
  _face_info = &fi;
  _face_type = fi.faceType(std::make_pair(_var.number(), _var.sys().number()));
  const auto strong_resid =
      fi.normal()(_index) * _sig;
  addResidualAndJacobian(strong_resid * (fi.faceArea() * fi.faceCoord()));
}
