#pragma once

#include "ADMaterial.h"

/**
 * Material objects inherit from Material and override computeQpProperties.
 *
 * Their job is to declare properties for use by other objects in the
 * calculation such as Kernels and BoundaryConditions.
 */
class ADSedimentMaterialSI : public ADMaterial
{
public:
  static InputParameters validParams();

  ADSedimentMaterialSI(const InputParameters & parameters);

protected:
  /// Necessary override. This is where the values of the properties are computed.
  virtual void computeQpProperties() override;
  const unsigned int _mesh_dimension;

  // density of the fluid
  const Real _rho;

  // sediment layer thickness
  const Real & _LayerThickness;

  // sediment layer friction coefficient
  const Real & _SlipperinessCoefficient;

  // whether to apply the subglacial flood
  const bool & _SubglacialFlood;

  // subglacial flood characteristics
  const Real & _FloodStartPosition;
  const Real & _FloodAmplitude;
  const Real & _FloodPeakTime;
  const Real & _FloodSpreadTime;
  const Real & _FloodSpeed;
  
  /// viscosity of the fluid (mu)
  ADMaterialProperty<Real> & _viscosity;
  /// density of the fluid (rho)
  ADMaterialProperty<Real> & _density;
};
