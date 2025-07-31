#pragma once

#include "FunctorMaterial.h"

/**
 * Material objects inherit from Material and override computeQpProperties.
 *
 * Their job is to declare properties for use by other objects in the
 * calculation such as Kernels and BoundaryConditions.
 */
class FVSedimentMaterialSI : public FunctorMaterial
{
public:
  static InputParameters validParams();

  FVSedimentMaterialSI(const InputParameters & parameters);

protected:
  const unsigned int _mesh_dimension;

  // density of the fluid
  const Real & _rho;

  // velocity
  const Moose::Functor<ADReal> & _vel_x;
  const Moose::Functor<ADReal> & _vel_y;
  const Moose::Functor<ADReal> & _vel_z;

  // Friction coefficient (DruckerPrager model)
  const Real & _FrictionCoefficient;

  // Slipperiness coefficient (Slip model)
  const Real & _SlipperinessCoefficient;

  // Layer thickness (Slip model)
  const Real & _LayerThickness;

  // pressure
  const Moose::Functor<ADReal> & _pressure;

  // Sediment sliding law
  const std::string & _sliding_law;

  // Finite strain rate parameter
  const Real & _II_eps_min;
};
