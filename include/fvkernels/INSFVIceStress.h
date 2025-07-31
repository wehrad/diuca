//* This file is part of the MOOSE framework
//* https://www.mooseframework.org
//*
//* All rights reserved, see COPYRIGHT for full restrictions
//* https://github.com/idaholab/moose/blob/master/COPYRIGHT
//*
//* Licensed under LGPL 2.1, please see LICENSE for details
//* https://www.gnu.org/licenses/lgpl-2.1.html
// modified from MOOSE INSFVIceStress
#pragma once

#include "INSFVFluxKernel.h"
#include "INSFVMomentumResidualObject.h"

// Forward declare variable class
class INSFVVelocityVariable;

class INSFVIceStress : public INSFVFluxKernel
{
public:
  static InputParameters validParams();

  INSFVIceStress(const InputParameters & params);

  using INSFVFluxKernel::gatherRCData;
  void gatherRCData(const FaceInfo &) override final;

protected:
  /// The dimension of the simulation
  // const unsigned int _dim;

  /// index x|y|z
  const unsigned int _axis_index;

  /// x-related stresses
  const Moose::Functor<ADRealVectorValue> & _sig_x;

  /// y-related stresses
  const Moose::Functor<ADRealVectorValue> & _sig_y;

  /// z-related stresses
  const Moose::Functor<ADRealVectorValue> & _sig_z;
};
