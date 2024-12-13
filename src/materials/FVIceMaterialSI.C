#include "FVIceMaterialSI.h"
#include "MooseMesh.h"

registerMooseObject("diucaApp", FVIceMaterialSI);

InputParameters
FVIceMaterialSI::validParams()
{
  InputParameters params = FunctorMaterial::validParams();

  // Get velocity gradients to compute viscosity based on the effective strain rate
  // params.addRequiredCoupledVar("velocity_x", "Velocity in x dimension");
  // params.addCoupledVar("velocity_y", "Velocity in y dimension");
  // params.addCoupledVar("velocity_z", "Velocity in z dimension");

  params.addParam<MooseFunctorName>("velocity_x", "Velocity in x dimension");
  params.addParam<MooseFunctorName>("velocity_y", "Velocity in y dimension");
  params.addParam<MooseFunctorName>("velocity_z", "Velocity in z dimension");

  // Mean pressure
  params.addParam<MooseFunctorName>("pressure", "Mean stress");

  // params.addRequiredCoupledVar("pressure", "Mean stress");

  // Fluid properties
  params.addParam<Real>(
      "AGlen", 2.378234398782344e-24, "Fluidity parameter in Glen's flow law"); // Pa-3s-1

  params.addParam<Real>("nGlen", 3., "Glen exponent");     //
  params.addParam<Real>("density", 917., "Ice density"); // kgm-3

  // Convergence parameters
  params.addParam<Real>("II_eps_min", 1e-25, "Finite strain rate parameter"); // s-1
  params.declareControllable("II_eps_min"); // s-1

  return params;
}

FVIceMaterialSI::FVIceMaterialSI(const InputParameters & parameters)
  : FunctorMaterial(parameters),

    // Mesh dimension
    _mesh_dimension(_mesh.dimension()),

    // Glen parameters
    _AGlen(getParam<Real>("AGlen")),
    _nGlen(getParam<Real>("nGlen")),

    // Ice density
    _rho(getParam<Real>("density")),

    // Velocities
    _vel_x(getFunctor<ADReal>("velocity_x")),
    _vel_y(_mesh.dimension() >= 2 ? &getFunctor<ADReal>("velocity_y") : nullptr),
    _vel_z(_mesh.dimension() == 3 ? &getFunctor<ADReal>("velocity_z") : nullptr),

    // Pressure
    _pressure(getFunctor<ADReal>("pressure")),

    // Finite strain rate parameter
    _II_eps_min(getParam<Real>("II_eps_min"))
{
  const std::set<ExecFlagType> clearance_schedule(_execute_enum.begin(), _execute_enum.end());

  _console << "Maximum allowed viscosity : "
           << (0.5 * std::pow(_AGlen, -1. / _nGlen) *
               std::pow(_II_eps_min, -(1. - 1. / _nGlen) / 2.))
           << std::endl;

  
  addFunctorProperty<ADReal>(
			     "rho_ice", [this](const auto &, const auto &) -> ADReal { return _rho; });

  const auto & eps_x = addFunctorProperty<ADRealVectorValue>(
      "eps_x",
      [this](const auto & r, const auto & t) -> ADRealVectorValue
      {

        // Get current x velocity gradients at quadrature point
        auto gradx = _vel_x.gradient(r, t);
        ADReal u_x = gradx(0);
        ADReal u_y = gradx(1);
        ADReal u_z = gradx(2);

        return ADRealVectorValue(u_x, u_y, u_z);
      });

  const auto & eps_y = addFunctorProperty<ADRealVectorValue>(
      "eps_y",
      [this](const auto & r, const auto & t) -> ADRealVectorValue
      {

	// Get current y velocity gradients at quadrature point
	auto grady = _vel_y ? _vel_y->gradient(r, t) : ADReal(0);
        ADReal v_x = grady(0);
        ADReal v_y = grady(1);
        ADReal v_z = grady(2);

        return ADRealVectorValue(v_x, v_y, v_z);
      });

  const auto & eps_z = addFunctorProperty<ADRealVectorValue>(
      "eps_z",
      [this](const auto & r, const auto & t) -> ADRealVectorValue
      {

	// Get current z velocity gradients at quadrature point
	auto gradz = _vel_z ? _vel_z->gradient(r, t) : ADReal(0);
	ADReal w_x = gradz(0);
        ADReal w_y = gradz(1);
        ADReal w_z = gradz(2);

        return ADRealVectorValue(w_x, w_y, w_z);
      });

  const auto & eps_xy = addFunctorProperty<ADReal>(
      "eps_xy",
      [this, &eps_x, &eps_y](const auto & r, const auto & t) -> ADReal
      {
	ADReal eps_xy = 0.5 * (eps_x(r, t)(1) + eps_y(r, t)(0));
        return eps_xy;
      });

  const auto & eps_xz = addFunctorProperty<ADReal>(
      "eps_xz",
      [this, &eps_x, &eps_z](const auto & r, const auto & t) -> ADReal
      {
	ADReal eps_xz = 0.5 * (eps_x(r, t)(2) + eps_z(r, t)(0));
        return eps_xz;
      });

  const auto & eps_yz = addFunctorProperty<ADReal>(
      "eps_yz",
      [this, &eps_y, &eps_z](const auto & r, const auto & t) -> ADReal
      {
	ADReal eps_yz = 0.5 * (eps_y(r, t)(2) + eps_z(r, t)(1));		
        return eps_yz;
      });

  const auto & eps_xx = addFunctorProperty<ADReal>(
      "eps_xx",
      [this, &eps_x](const auto & r, const auto & t) -> ADReal
      {

	ADReal eps_xx = eps_x(r, t)(0);
	
        return eps_xx;
      });

  const auto & eps_yy = addFunctorProperty<ADReal>(
      "eps_yy",
      [this, &eps_y](const auto & r, const auto & t) -> ADReal
      {

	ADReal eps_yy = eps_y(r, t)(1);
	
        return eps_yy;
      });

  const auto & eps_zz = addFunctorProperty<ADReal>(
      "eps_zz",
      [this, &eps_z](const auto & r, const auto & t) -> ADReal
      {

	ADReal eps_zz = eps_z(r, t)(2);
	
        return eps_zz;
      });

  const auto & viscosity = addFunctorProperty<ADReal>(
      "mu_ice",
      [this, &eps_x, &eps_y, &eps_z, &eps_xy, &eps_xz, &eps_yz](const auto & r, const auto & t) -> ADReal
      {
        // Wrap term with Glen's fluidity parameter for clarity
        ADReal ApGlen = std::pow(_AGlen, -1. / _nGlen);

	// Get current velocity gradients at quadrature point
	ADReal u_x = eps_x(r, t)(0);
	ADReal u_y = eps_x(r, t)(1);
	ADReal u_z = eps_x(r, t)(2);
	
	ADReal v_x = eps_y(r, t)(0);
	ADReal v_y = eps_y(r, t)(1);
	ADReal v_z = eps_y(r, t)(2);
	
	ADReal w_x = eps_z(r, t)(0);
	ADReal w_y = eps_z(r, t)(1);
	ADReal w_z = eps_z(r, t)(2);
	
        // Compute effective strain rate
        ADReal II_eps = 0.5 * (u_x * u_x + v_y * v_y + w_z * w_z +
                               2. * (eps_xy(r, t) * eps_xy(r, t)
				     + eps_xz(r, t) * eps_xz(r, t)
				     + eps_yz(r, t) * eps_yz(r, t)));

        // Finite strain rate parameter included to avoid infinite viscosity at low stresses
        if (II_eps < _II_eps_min)
          II_eps = _II_eps_min;

	// std::cout <<  << std::endl;
	
        // Compute viscosity
        ADReal mu = (0.5 * ApGlen * std::pow(II_eps, -(1. - 1. / _nGlen) / 2.)); // Pas
       
        return std::max(mu, 3.153600e09);
      },
     clearance_schedule);
  
  const auto & sig_x = addFunctorProperty<ADRealVectorValue>(
      "sig_x",
      [this, &eps_x, &eps_xy, &eps_xz, &viscosity](const auto & r, const auto & t) -> ADRealVectorValue
      {

	// Compute x-related stresses
        ADReal sig_xx = 2. * viscosity(r, t) * eps_x(r, t)(0) + _pressure(r, t);
	ADReal sig_xy = 2. * viscosity(r, t) * eps_xy(r, t); 
	ADReal sig_xz = 2. * viscosity(r, t) * eps_xz(r, t);

        return ADRealVectorValue(sig_xx, sig_xy, sig_xz);
      });

  const auto & sig_y = addFunctorProperty<ADRealVectorValue>(
      "sig_y",
      [this, &eps_y, &eps_xy, &eps_yz, &viscosity](const auto & r, const auto & t) -> ADRealVectorValue
      {

	// Compute y-related stresses
	ADReal sig_yy;
	if (_mesh.dimension() >= 2){
	  sig_yy = 2. * viscosity(r, t) * eps_y(r, t)(1) + _pressure(r, t);
	}
	else{
	  sig_yy = 0.;
	}
	ADReal sig_yx = 2. * viscosity(r, t) * eps_xy(r, t);
	ADReal sig_yz = 2. * viscosity(r, t) * eps_yz(r, t);
 
        return ADRealVectorValue(sig_yy, sig_yx, sig_yz);
      });

  const auto & sig_z = addFunctorProperty<ADRealVectorValue>(
      "sig_z",
      [this, &eps_z, &eps_xz, &eps_yz, &viscosity](const auto & r, const auto & t) -> ADRealVectorValue
      {

	// Compute z-related stresses
	ADReal sig_zz;
	if (_mesh.dimension() == 3){
	  sig_zz = 2. * viscosity(r, t) * eps_z(r, t)(2) + _pressure(r, t);
	}
	else {
	  sig_zz = 0.;
	}
	ADReal sig_zx = 2. * viscosity(r, t) * eps_xz(r, t);
	ADReal sig_zy = 2. * viscosity(r, t) * eps_yz(r, t);

        return ADRealVectorValue(sig_zz, sig_zx, sig_zy);
      });


  const auto & sig_xx = addFunctorProperty<ADReal>(
      "sig_xx",
      [this, &sig_x](const auto & r, const auto & t) -> ADReal
      {

	ADReal _sig_xx = sig_x(r, t)(0);
	
        return _sig_xx;
      });

  const auto & sig_yy = addFunctorProperty<ADReal>(
      "sig_yy",
      [this, &sig_y](const auto & r, const auto & t) -> ADReal
      {

	ADReal _sig_yy = sig_y(r, t)(0);
	
        return _sig_yy;
      });

  const auto & sig_zz = addFunctorProperty<ADReal>(
      "sig_zz",
      [this, &sig_z](const auto & r, const auto & t) -> ADReal
      {

	ADReal _sig_zz = sig_z(r, t)(0);
	
        return _sig_zz;
      });

  const auto & sig_xy = addFunctorProperty<ADReal>(
      "sig_xy",
      [this, &sig_x](const auto & r, const auto & t) -> ADReal
      {

	ADReal _sig_xy = sig_x(r, t)(1);
	
        return _sig_xy;
      });

  const auto & sig_xz = addFunctorProperty<ADReal>(
      "sig_xz",
      [this, &sig_x](const auto & r, const auto & t) -> ADReal
      {

	ADReal _sig_xz = sig_x(r, t)(2);
	
        return _sig_xz;
      });

  const auto & sig_yz = addFunctorProperty<ADReal>(
      "sig_yz",
      [this, &sig_y](const auto & r, const auto & t) -> ADReal
      {

	ADReal _sig_yz = sig_y(r, t)(2);
	
        return _sig_yz;
      });

}
