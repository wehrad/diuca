#pragma once

#include "ADMaterial.h"

/**
 * Material objects inherit from Material and override computeQpProperties.
 *
 * Their job is to declare properties for use by other objects in the
 * calculation such as Kernels and BoundaryConditions.
 */
class ADSedimentMaterialSI2 : public ADMaterial
{
public:
  static InputParameters validParams();

  ADSedimentMaterialSI2(const InputParameters & parameters);

protected:
  /// Necessary override. This is where the values of the properties are computed.
  virtual void computeQpProperties() override;
  const unsigned int _mesh_dimension;

  // density of the fluid
  const ADReal & _rho;

  // sediment layer thickness
  const Real & _LayerThickness;

  // sediment layer friction coefficient
  const Real & _SlipperinessCoefficient;

  /// viscosity of the fluid (mu)
  ADMaterialProperty<Real> & _viscosity;
  /// density of the fluid (rho)
  ADMaterialProperty<Real> & _density;
};
