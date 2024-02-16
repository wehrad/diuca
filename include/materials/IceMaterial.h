#pragma once

#include "Material.h"

/**
 * Material objects inherit from Material and override computeQpProperties.
 *
 * Their job is to declare properties for use by other objects in the
 * calculation such as Kernels and BoundaryConditions.
 */
class IceMaterial : public Material
{
public:
  static InputParameters validParams();

  IceMaterial(const InputParameters & parameters);

protected:
  /// Necessary override. This is where the values of the properties are computed.
  virtual void computeQpProperties() override;
  
  /// density of the fluid (rho)
  MaterialProperty<Real> & _density; 

  /// viscosity of the fluid (mu)
  MaterialProperty<Real> & _viscosity;

  // velocity gradients
  const VariableGradient & _grad_velocity_x;
  const VariableGradient & _grad_velocity_y;
  const VariableGradient & _grad_velocity_z;
  const VariableValue & _pressure;

  // Glen parameters
  const Real & _AGlen;
  const Real & _nGlen;

  // density of the fluid
  const Real & _rho;

  // Finite strain rate parameter
  const Real & _II_eps_min;

};
