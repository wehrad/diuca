#include "ADSedimentMaterial.h"
#include "MooseMesh.h"

registerMooseObject("diucaApp", ADSedimentMaterial);

InputParameters
ADSedimentMaterial::validParams()
{
  InputParameters params = ADMaterial::validParams();

  // Get velocity gradients to compute viscosity based on the effective strain rate
  params.addRequiredCoupledVar("velocity_x", "Velocity in x dimension");
  params.addCoupledVar("velocity_y", "Velocity in y dimension");
  params.addCoupledVar("velocity_z", "Velocity in z dimension");

  // Mean pressure
  params.addRequiredCoupledVar("pressure", "Mean stress");

  // Solid properties
  // https://tc.copernicus.org/articles/14/261/2020/
  params.addParam<ADReal>("density", 1850., "Sediment density");                  // kgm-3
  params.addParam<ADReal>("II_eps_min", 6.17e-6, "Finite strain rate parameter"); // a-1

  // Friction properties
  params.addParam<ADReal>("FrictionCoefficient", 1.0, "Sediment friction coefficient");

  return params;
}

ADSedimentMaterial::ADSedimentMaterial(const InputParameters & parameters)
  : ADMaterial(parameters),

    // Mesh dimension
    _mesh_dimension(_mesh.dimension()),

    // Sediment density
    _rho(getParam<ADReal>("density")),

    // Velocity gradients
    _grad_velocity_x(adCoupledGradient("velocity_x")),
    _grad_velocity_y(_mesh_dimension >= 2 ? adCoupledGradient("velocity_y") : _ad_grad_zero),
    _grad_velocity_z(_mesh_dimension == 3 ? adCoupledGradient("velocity_z") : _ad_grad_zero),

    // Finite strain rate parameter
    _II_eps_min(getParam<ADReal>("II_eps_min")),

    // Mean stress
    _pressure(adCoupledValue("pressure")),

    // Friction properties
    _FrictionCoefficient(getParam<ADReal>("FrictionCoefficient")),

    // Ice properties created by this object
    _density(declareADProperty<Real>("rho")),
    _viscosity(declareADProperty<Real>("mu"))
{
}

void
ADSedimentMaterial::computeQpProperties()
{

  // Constant density
  _density[_qp] = _rho;

  // Get current velocity gradients at quadrature point
  ADReal u_x = _grad_velocity_x[_qp](0);
  ADReal u_y = _grad_velocity_x[_qp](1);
  ADReal u_z = _grad_velocity_x[_qp](2);

  ADReal v_x = _grad_velocity_y[_qp](0);
  ADReal v_y = _grad_velocity_y[_qp](1);
  ADReal v_z = _grad_velocity_y[_qp](2);

  ADReal w_x = _grad_velocity_z[_qp](0);
  ADReal w_y = _grad_velocity_z[_qp](1);
  ADReal w_z = _grad_velocity_z[_qp](2);

  ADReal eps_xy = 0.5 * (u_y + v_x);
  ADReal eps_xz = 0.5 * (u_z + w_x);
  ADReal eps_yz = 0.5 * (v_z + w_y);

  // Get pressure
  ADReal sig_m = _pressure[_qp];

  ADReal eta = _viscosity[_qp];

  // Compute stresses
  ADReal sxx = 2 * eta * u_x + sig_m;
  ADReal syy = 2 * eta * v_y + sig_m;
  ADReal szz = 2 * eta * w_z + sig_m;

  ADReal sxy = eta * (u_y + v_x);
  ADReal sxz = eta * (u_z + w_x);
  ADReal syz = eta * (v_z + w_y);

  // Compute deviatoric stresses
  ADReal sxx_dev = 2 * eta * u_x;
  ADReal syy_dev = 2 * eta * v_y;
  ADReal szz_dev = 2 * eta * w_z;

  // von Mises stress (second invariant)
  ADReal sig_e = std::sqrt(3. / 2. * (sxx_dev * sxx_dev + syy_dev * syy_dev + 2 * sxy * sxy));

  // Compute viscosity
  // _viscosity[_qp] = (_FrictionCoefficient * sig_m) / std::abs(sig_e); // MPaa
  _viscosity[_qp] = 3.;

  // std::cout << "SEDIMENT  " << _viscosity[_qp] << "  " << _pressure[_qp] << std::endl;
}
