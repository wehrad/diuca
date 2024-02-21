#pragma once

#include "ADMaterial.h"

/**
 * Material objects inherit from Material and override computeQpProperties.
 *
 * Their job is to declare properties for use by other objects in the
 * calculation such as Kernels and BoundaryConditions.
 */
class ADSedimentMaterial : public ADMaterial
{
public:
  static InputParameters validParams();

  ADSedimentMaterial(const InputParameters & parameters);

protected:
  /// Necessary override. This is where the values of the properties are computed.
  virtual void computeQpProperties() override;
  const unsigned int _mesh_dimension;
  
  // density of the fluid
  const ADReal & _rho;

  // Velocity gradients
  const ADVariableGradient & _grad_velocity_x;
  const ADVariableGradient & _grad_velocity_y;
  const ADVariableGradient & _grad_velocity_z;

  // Effective strain rate parameter
  const ADReal & _II_eps_min;
  const ADVariableValue & _pressure;

  // Friction properties
  const ADReal & _FrictionCoefficient;
  
  /// density of the fluid (rho)
  ADMaterialProperty<Real> & _density; 

  /// viscosity of the fluid (mu)
  ADMaterialProperty<Real> & _viscosity;

  
};
