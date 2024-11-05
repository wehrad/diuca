//* This file is part of the MOOSE framework
//* https://www.mooseframework.org
//*
//* All rights reserved, see COPYRIGHT for full restrictions
//* https://github.com/idaholab/moose/blob/master/COPYRIGHT
//*
//* Licensed under LGPL 2.1, please see LICENSE for details
//* https://www.gnu.org/licenses/lgpl-2.1.html
// modified from MOOSE INSFVMixingLengthReynoldsStress

#include "INSFVIceStress.h"
#include "INSFVVelocityVariable.h"
#include "SystemBase.h"

registerMooseObject("diucaApp", INSFVIceStress);

InputParameters
INSFVIceStress::validParams()
{
  InputParameters params = INSFVFluxKernel::validParams();
  params.addClassDescription(
      "Compute ice stresses following Glen's flow law");
  params.addParam<MooseFunctorName>("sig_x", "x-related stresses");
  params.addParam<MooseFunctorName>("sig_y", "x-related stresses");
  params.addParam<MooseFunctorName>("sig_z", "x-related stresses");
  MooseEnum momentum_component("x=0 y=1 z=2");
  params.addRequiredParam<MooseEnum>(
      "momentum_component",
      momentum_component,
      "The component of the stress that this kernel applies to.");
  return params;
}

INSFVIceStress::INSFVIceStress(const InputParameters & params)
  : INSFVFluxKernel(params),
    // _dim(blocksMaxDimension()),
    _axis_index(getParam<MooseEnum>("momentum_component")),
    _sig_x(getFunctor<ADRealVectorValue>("sig_x")),
    _sig_y(getFunctor<ADRealVectorValue>("sig_y")),
    _sig_z(getFunctor<ADRealVectorValue>("sig_z"))
{

}

void
INSFVIceStress::gatherRCData(const FaceInfo & fi)
{
  if (skipForBoundary(fi))
    return;

  _face_info = &fi;
  _normal = fi.normal();
  _face_type = fi.faceType(std::make_pair(_var.number(), _var.sys().number()));

  const auto face = makeCDFace(*_face_info);
  const auto state = determineState();
  
  if (_index == 0)
    {
      addResidualAndJacobian(_sig_x(face, state)(0) * (fi.faceArea() * fi.faceCoord())); // xx
      addResidualAndJacobian(_sig_x(face, state)(1) * (fi.faceArea() * fi.faceCoord())); // xy
      addResidualAndJacobian(_sig_x(face, state)(2) * (fi.faceArea() * fi.faceCoord())); // xz
    }
  else if (_index == 1)
    {
      addResidualAndJacobian(_sig_y(face, state)(0) * (fi.faceArea() * fi.faceCoord())); // yy
      addResidualAndJacobian(_sig_y(face, state)(2) * (fi.faceArea() * fi.faceCoord())); // yz
    }
  else if (_index == 2)
    {
      addResidualAndJacobian(_sig_z(face, state)(0) * (fi.faceArea() * fi.faceCoord())); // zz
    }

}
