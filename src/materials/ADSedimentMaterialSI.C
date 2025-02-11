#include "ADSedimentMaterialSI.h"
#include "MooseMesh.h"

registerMooseObject("diucaApp", ADSedimentMaterialSI);

InputParameters
ADSedimentMaterialSI::validParams()
{
  InputParameters params = ADMaterial::validParams();

  // Friction coefficient (DruckerPrager model)
  // params.addParam<Real>("FrictionCoefficient", 1.0, "Sediment friction coefficient");
  // params.declareControllable("FrictionCoefficient");

  // Friction coefficient (Slip model)
  params.addParam<Real>("SlipperinessCoefficient", 1.0, "Sediment slipperiness coefficient");
  params.declareControllable("SlipperinessCoefficient");

  // Sediment layer thickness (Slip model)
  params.addParam<Real>("LayerThickness", 1.0, "Sediment layer thickness"); // m
  params.declareControllable("LayerThickness");

  // Get velocity gradients to compute viscosity based on the effective strain rate
  // params.addRequiredCoupledVar("velocity_x", "Velocity in x dimension");
  // params.addCoupledVar("velocity_y", "Velocity in y dimension");
  // params.addCoupledVar("velocity_z", "Velocity in z dimension");

  // Mean pressure
  // params.addRequiredCoupledVar("pressure", "Mean stress");

  // Sediment density (https://tc.copernicus.org/articles/14/261/2020/)
  params.addParam<Real>("density", 1850., "Sediment density"); // kgm-3
  params.declareControllable("density"); // kgm-3

  // Convergence parameters
  params.addParam<Real>("II_eps_min", 1e-25, "Finite strain rate parameter"); // s-1
  params.declareControllable("II_eps_min"); // s-1

  // Model to simulate sediments
  params.addParam<std::string>("sliding_law", "GudmundssonRaymond", "Model to simulate sediment deformation (DruckerPrager or GudmundssonRaymond)");
  params.declareControllable("sliding_law");

  return params;
}

ADSedimentMaterialSI::ADSedimentMaterialSI(const InputParameters & parameters)
  : ADMaterial(parameters),

    // Mesh dimension
    _mesh_dimension(_mesh.dimension()),

    // Sediment density
    _rho(getParam<Real>("density")),

    // Velocity gradients
    // _grad_velocity_x(adCoupledGradient("velocity_x")),
    // _grad_velocity_y(_mesh_dimension >= 2 ? adCoupledGradient("velocity_y") : _ad_grad_zero),
    // _grad_velocity_z(_mesh_dimension == 3 ? adCoupledGradient("velocity_z") : _ad_grad_zero),

    // Friction coefficient (DruckerPrager model)
    // _FrictionCoefficient(getParam<Real>("FrictionCoefficient")),

    // Slipperiness coefficient (GudmundssonRaymond model)
    _SlipperinessCoefficient(getParam<Real>("SlipperinessCoefficient")),

    // Sediment layer thickness (GudmundssonRaymond model)
    _LayerThickness(getParam<Real>("LayerThickness")),

    // Model to simulate sediments
    _sliding_law(getParam<std::string>("sliding_law")),

    // Finite strain rate parameter
    _II_eps_min(getParam<Real>("II_eps_min")),

    // Mean stress
    // _pressure(adCoupledValue("pressure")),

    // Ice properties created by this object
    _density(declareADProperty<Real>("rho_sediment")),
    _viscosity(declareADProperty<Real>("mu_sediment"))
{
}

void
ADSedimentMaterialSI::computeQpProperties()
{

  // Constant density
  _density[_qp] = _rho;

  if (_sliding_law == "GudmundssonRaymond")
    {
      _viscosity[_qp] = _LayerThickness / _SlipperinessCoefficient;
      // ADReal viscosity = 1e10;
      // std::cout << "SEDIMENT  " << _viscosity[_qp] << "  " << _pressure[_qp] << std::endl;
    }

  // std::cout << "SEDIMENT  " << _viscosity[_qp] << "  " << _pressure[_qp] << std::endl;
  // Viscosity at previous timestep
  // ADReal eta = _viscosity[_qp];
  
  // if (_sliding_law == "DruckerPrager")
  //   {
  //     // Get current velocity gradients at quadrature point
  //     ADReal u_x = _grad_velocity_x[_qp](0);
  //     ADReal u_y = _grad_velocity_x[_qp](1);
  //     ADReal u_z = _grad_velocity_x[_qp](2);

  //     ADReal v_x = _grad_velocity_y[_qp](0);
  //     ADReal v_y = _grad_velocity_y[_qp](1);
  //     ADReal v_z = _grad_velocity_y[_qp](2);
  //     ADReal w_x = _grad_velocity_z[_qp](0);
  //     ADReal w_y = _grad_velocity_z[_qp](1);
  //     ADReal w_z = _grad_velocity_z[_qp](2);

  //     ADReal eps_xy = 0.5 * (u_y + v_x);
  //     ADReal eps_xz = 0.5 * (u_z + w_x);
  //     ADReal eps_yz = 0.5 * (v_z + w_y);

  //     // Get pressure
  //     ADReal sig_m = _pressure[_qp];

  //     // Compute stresses
  //     ADReal sxx = 2 * eta * u_x + sig_m;
  //     ADReal syy = 2 * eta * v_y + sig_m;
  //     ADReal szz = 2 * eta * w_z + sig_m;

  //     ADReal sxy = eta * (u_y + v_x);
  //     ADReal sxz = eta * (u_z + w_x);
  //     ADReal syz = eta * (v_z + w_y);

  //     // Compute deviatoric stresses
  //     ADReal sxx_dev = 2 * eta * u_x;
  //     ADReal syy_dev = 2 * eta * v_y;
  //     ADReal szz_dev = 2 * eta * w_z;

  //     // von Mises stress (second invariant)
  //     ADReal sig_e = std::sqrt(3. / 2. * (sxx_dev * sxx_dev + syy_dev * syy_dev + 2 * sxy * sxy));
      
  //     // Compute viscosity
  //     _viscosity[_qp] = (_FrictionCoefficient * sig_m) / std::abs(sig_e);
  //     // _viscosity[_qp] = 3.;
  //   }

}
