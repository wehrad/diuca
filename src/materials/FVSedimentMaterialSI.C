#include "FVSedimentMaterialSI.h"
#include "MooseMesh.h"
#include "MooseFunctorArguments.h"

registerMooseObject("diucaApp", FVSedimentMaterialSI);

InputParameters
FVSedimentMaterialSI::validParams()
{
  InputParameters params = FunctorMaterial::validParams();

  // Friction coefficient (DruckerPrager model)
  params.addParam<Real>("FrictionCoefficient", 1.0, "Sediment friction coefficient");
  params.declareControllable("FrictionCoefficient");

  // Friction coefficient (Slip model)
  params.addParam<Real>("SlipperinessCoefficient", 1.0, "Sediment slipperiness coefficient");
  params.declareControllable("SlipperinessCoefficient");

  // Sediment layer thickness (Slip model)
  params.addParam<Real>("LayerThickness", 1.0, "Sediment layer thickness"); // m
  params.declareControllable("LayerThickness");

  // Get velocity gradients to compute viscosity based on second invariant
  params.addParam<MooseFunctorName>("velocity_x", "Velocity in x dimension");
  params.addParam<MooseFunctorName>("velocity_y", "Velocity in y dimension");
  params.addParam<MooseFunctorName>("velocity_z", "Velocity in z dimension");

  // Mean pressure
  params.addRequiredCoupledVar("pressure", "Mean stress");

  // Sediment density (https://tc.copernicus.org/articles/14/261/2020/)
  params.addParam<Real>("density", 1850., "Ice density"); // kgm-3
  params.declareControllable("density"); // kgm-3

  // Convergence parameters
  params.addParam<Real>("II_eps_min", 1e-25, "Finite strain rate parameter"); // s-1
  params.declareControllable("II_eps_min"); // s-1

  // Model to simulate sediments
  params.addParam<std::string>("sliding_law", "GudmundssonRaymond", "Model to simulate sediment deformation (DruckerPrager or GudmundssonRaymond)");
  params.declareControllable("sliding_law");

  return params;
}

FVSedimentMaterialSI::FVSedimentMaterialSI(const InputParameters & parameters)
  : FunctorMaterial(parameters),

    // Mesh dimension
    _mesh_dimension(_mesh.dimension()),

    // Ice density
    _rho(getParam<Real>("density")),
    
    // Velocities
    _vel_x(getFunctor<ADReal>("velocity_x")),
    _vel_y(getFunctor<ADReal>("velocity_y")),
    _vel_z(getFunctor<ADReal>("velocity_z")),

    // Friction coefficient (DruckerPrager model)
    _FrictionCoefficient(getParam<Real>("FrictionCoefficient")),

    // Slipperiness coefficient (GudmundssonRaymond model)
    _SlipperinessCoefficient(getParam<Real>("SlipperinessCoefficient")),

    // Sediment layer thickness (GudmundssonRaymond model)
    _LayerThickness(getParam<Real>("LayerThickness")),

    // Pressure
    _pressure(getFunctor<ADReal>("pressure")),

    // Model to simulate sediments
    _sliding_law(getParam<std::string>("sliding_law")),
    
    // Finite strain rate parameter
    _II_eps_min(getParam<Real>("II_eps_min"))
{
  const std::set<ExecFlagType> clearance_schedule(_execute_enum.begin(), _execute_enum.end());

  addFunctorProperty<Real>(
      "rho_sediment", [this](const auto &, const auto &) -> Real { return _rho; }, clearance_schedule);
  
    if (_sliding_law == "GudmundssonRaymond")
    {
      addFunctorProperty<ADReal>(
      "mu_sediment",
      [this](const auto &, const auto &) -> ADReal
      {

	ADReal viscosity = _LayerThickness / _SlipperinessCoefficient;
	// ADReal viscosity = 1e10;
  
	return viscosity;
      },
      clearance_schedule);
    }

    
  if (_sliding_law == "DruckerPrager")
    {
      addFunctorProperty<ADReal>(
      "mu_sediment",
      [this](const auto & r, const auto & t) -> ADReal
      {

	// Get current velocity gradients at quadrature point
	auto gradx = _vel_x.gradient(r, t);
	ADReal u_x = gradx(0);
	ADReal u_y = gradx(1);
	ADReal u_z = gradx(2);
	
	auto grady = _vel_y.gradient(r, t);
	ADReal v_x = grady(0);
	ADReal v_y = grady(1);
	ADReal v_z = grady(2);
	
	auto gradz = _vel_z.gradient(r, t);
	ADReal w_x = gradz(0);
	ADReal w_y = gradz(1);
	ADReal w_z = gradz(2);
	
	ADReal eps_xy = 0.5 * (u_y + v_x);
	ADReal eps_xz = 0.5 * (u_z + w_x);
	ADReal eps_yz = 0.5 * (v_z + w_y);
	
	// Get pressure
	ADReal sig_m = _pressure(r, t);
	
	// Compute effective strain rate (3D)
	ADReal II_eps = 0.5 * (u_x * u_x + v_y * v_y + w_z * w_z +
			       2. * (eps_xy * eps_xy + eps_xz * eps_xz + eps_yz * eps_yz));
	
	// Finite strain rate parameter included to avoid infinite viscosity at low stresses
	if (II_eps < _II_eps_min)
	  II_eps = _II_eps_min;
	
	ADReal eps_e = std::sqrt(II_eps);
	
	// Compute viscosity
	ADReal viscosity = (_FrictionCoefficient * sig_m) / std::abs(eps_e); // Pas
        
	return viscosity;
      },
      clearance_schedule);
    }
}
