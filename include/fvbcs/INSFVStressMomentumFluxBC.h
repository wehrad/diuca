//* This file is part of the MOOSE framework
//* https://www.mooseframework.org
//*
//* All rights reserved, see COPYRIGHT for full restrictions
//* https://github.com/idaholab/moose/blob/master/COPYRIGHT
//*
//* Licensed under LGPL 2.1, please see LICENSE for details
//* https://www.gnu.org/licenses/lgpl-2.1.html

#pragma once

#include "INSFVFluxBC.h"
#include "INSFVFreeSurfaceBC.h"

/**
 * A class that imparts a stress on the momentum equation
 */
class INSFVStressMomentumFluxBC : public INSFVFreeSurfaceBC
{
public:
  static InputParameters validParams();
  INSFVStressMomentumFluxBC(const InputParameters & params);

  using INSFVFluxBC::gatherRCData;
  void gatherRCData(const FaceInfo & fi) override;

protected:
  // stress to be applied
  const Real & _sig;

};
