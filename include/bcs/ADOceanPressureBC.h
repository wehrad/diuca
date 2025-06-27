//* This file is part of the MOOSE framework
//* https://mooseframework.inl.gov
//*
//* All rights reserved, see COPYRIGHT for full restrictions
//* https://github.com/idaholab/moose/blob/master/COPYRIGHT
//*
//* Licensed under LGPL 2.1, please see LICENSE for details
//* https://www.gnu.org/licenses/lgpl-2.1.html

#pragma once

#include "ADIntegratedBC.h"

class ADOceanPressureBC : public ADIntegratedBC
{
public:
  /**
   * Factory constructor, takes parameters so that all derived classes can be built using the same
   * constructor.
   */
  static InputParameters validParams();

  ADOceanPressureBC(const InputParameters & parameters);

protected:
  virtual Real computeQpResidual() override;

  const Real & _water_density;
  const Real & _g;
  const Real & _water_height;

  /* virtual Real computeQpJacobian() override; */

};
