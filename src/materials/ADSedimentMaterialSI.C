#include "ADSedimentMaterialSI.h"
#include "MooseMesh.h"

registerMooseObject("diucaApp", ADSedimentMaterialSI);

InputParameters
ADSedimentMaterialSI::validParams()
{
  InputParameters params = ADMaterial::validParams();

  params.addParam<Real>("density", 917., "Ice density"); // kgm-3

  // Sediment layer thickness (Slip model)
  params.addParam<Real>("LayerThickness", 1.0, "Sediment layer thickness"); // m
  params.declareControllable("LayerThickness");

  // Friction coefficient (Slip model)
  params.addParam<Real>("SlipperinessCoefficient", 1.0, "Sediment slipperiness coefficient");
  params.declareControllable("SlipperinessCoefficient");
  
  return params;
}

ADSedimentMaterialSI::ADSedimentMaterialSI(const InputParameters & parameters)
  : ADMaterial(parameters),

    // Mesh dimension
    _mesh_dimension(_mesh.dimension()),

    // Ice density
    _rho(getParam<Real>("density")),

    _LayerThickness(getParam<Real>("LayerThickness")),

    _SlipperinessCoefficient(getParam<Real>("SlipperinessCoefficient")),
    
    // Ice properties created by this object
    _viscosity(declareADProperty<Real>("mu_sediment")),
    _density(declareADProperty<Real>("rho_sediment"))
{
}

void
ADSedimentMaterialSI::computeQpProperties()
{

  Real L=25000;
  Real W=10000;

  Real eta_back_center=1e10;
  
  Real eta_front_center=1e10;

  Real eta_sides=5e11;
  Real sigma_y=1500;
  
  Real eta_center = eta_back_center + (eta_front_center - eta_back_center) * (_q_point[_qp](0) / L);

  Real y0 = W / 2;
  Real gaussian_damping = std::exp(-(std::pow(_q_point[_qp](1) - y0, 2)) / (2 * std::pow(sigma_y, 2)));

  Real _eta = eta_sides + (eta_center - eta_sides) * gaussian_damping;
  
  _viscosity[_qp] = _eta;
  // _viscosity[_qp] = _LayerThickness / _SlipperinessCoefficient;
  
  // Constant density
  _density[_qp] = _rho;

}
