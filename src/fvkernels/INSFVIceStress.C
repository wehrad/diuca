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
// #include "NS.h"
#include "SystemBase.h"

registerMooseObject("diucaApp", INSFVIceStress);

InputParameters
INSFVIceStress::validParams()
{
  InputParameters params = INSFVFluxKernel::validParams();
  params.addClassDescription(
      "Compute ice stresses following Glen's flow law");
  params.addRequiredParam<MooseFunctorName>("u", "The velocity in the x direction.");
  params.addParam<MooseFunctorName>("v", "The velocity in the y direction.");
  params.addParam<MooseFunctorName>("w", "The velocity in the z direction.");
  params.addRequiredCoupledVar("pressure", "Mean stress");
  MooseEnum momentum_component("x=0 y=1 z=2");
  params.addRequiredParam<MooseEnum>(
      "momentum_component",
      momentum_component,
      "The component of the stress that this kernel applies to.");
  return params;
}

INSFVIceStress::INSFVIceStress(const InputParameters & params)
  : INSFVFluxKernel(params),
    _dim(blocksMaxDimension()),
    _axis_index(getParam<MooseEnum>("momentum_component")),
    _u(getFunctor<ADReal>("u")),
    _v(params.isParamValid("v") ? &getFunctor<ADReal>("v") : nullptr),
    _w(params.isParamValid("w") ? &getFunctor<ADReal>("w") : nullptr),
    _mu(getParam<ADReal>("viscosity")),
{
  
  if (_dim >= 2 && !_v)
    mooseError(
        "In two or more dimensions, the v velocity must be supplied using the 'v' parameter");
  if (_dim >= 3 && !_w)
    mooseError("In three dimensions, the w velocity must be supplied using the 'w' parameter");

}

ADReal
INSFVIceStress::computeStrongResidual()
{

  // only xx, yy or zz stresses at the moment
  
  const auto face = makeCDFace(*_face_info);
  const auto state = determineState();

  const ADReal mu = _mu(face, state);

  if (_index == 0)
    {
      const auto grad_var = _u.gradient(face, state);
    }
  else if (_index == 1)
    {
      const auto grad_var = _v.gradient(face, state);
    }
  else if (_index == 2)
    {     const auto grad_var = _w.gradient(face, state);
    }


  ADReal sigma_index_dev = 2*eta*grad_var(_index);

  return sigma_index_dev;
}

ADReal
INSFVIceStress::computeSegregatedContribution()
{
  return computeStrongResidual(false);
}

// void
// INSFVIceStress::gatherRCData(const FaceInfo & fi)
// {
//   if (skipForBoundary(fi))
//     return;

//   _face_info = &fi;
//   _normal = fi.normal();
//   _face_type = fi.faceType(std::make_pair(_var.number(), _var.sys().number()));

//   addResidualAndJacobian(computeStrongResidual(true) * (fi.faceArea() * fi.faceCoord()));

//   if (_face_type == FaceInfo::VarFaceNeighbors::ELEM ||
//       _face_type == FaceInfo::VarFaceNeighbors::BOTH)
//     _rc_uo.addToA(&fi.elem(), _index, _ae * (fi.faceArea() * fi.faceCoord()));
//   if (_face_type == FaceInfo::VarFaceNeighbors::NEIGHBOR ||
//       _face_type == FaceInfo::VarFaceNeighbors::BOTH)
//     _rc_uo.addToA(fi.neighborPtr(), _index, _an * (fi.faceArea() * fi.faceCoord()));
// }
