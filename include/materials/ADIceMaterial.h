#pragma once

#include "ADMaterial.h"

/**
 * Material objects inherit from Material and override computeQpProperties.
 *
 * Their job is to declare properties for use by other objects in the
 * calculation such as Kernels and BoundaryConditions.
 */
class ADIceMaterial : public ADMaterial
{
public:
  static InputParameters validParams();

  ADIceMaterial(const InputParameters & parameters);

protected:
  /// Necessary override. This is where the values of the properties are computed.
  virtual void computeQpProperties() override;
  const unsigned int _mesh_dimension;
  
  /// density of the fluid (rho)
  ADMaterialProperty<Real> & _density; 

  /// viscosity of the fluid (mu)
  ADMaterialProperty<Real> & _viscosity;

  // velocity gradients
  const VariableGradient & _grad_velocity_x;
  const VariableGradient & _grad_velocity_y;
  const VariableGradient & _grad_velocity_z;
  const VariableValue & _pressure;

  // Glen parameters
  const ADReal & _AGlen;
  const ADReal & _nGlen;

  // density of the fluid
  const ADReal & _rho;

  // Finite strain rate parameter
  const ADReal & _II_eps_min;

};
