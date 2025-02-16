#include "ADSedimentMaterialSI.h"
#include "MooseMesh.h"

registerMooseObject("diucaApp", ADSedimentMaterialSI);

InputParameters
ADSedimentMaterialSI::validParams()
{
  InputParameters params = ADMaterial::validParams();

  params.addParam<ADReal>("density", 917., "Ice density"); // kgm-3

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
    _rho(getParam<ADReal>("density")),

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

  _viscosity[_qp] = _LayerThickness / _SlipperinessCoefficient;
  
  // Constant density
  _density[_qp] = _rho;

}
