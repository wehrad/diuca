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

  // Spatiotemporal variations to apply to basal slipperiness
  params.addParam<std::string>("SlipperinessCoefficientVariations", "constant", "Spatiotemporal variations in basal slipperiness");
  params.declareControllable("SlipperinessCoefficientVariations");

  params.addParam<Real>("FloodAmplitude", 1.0, "Sediment slipperiness coefficient");
  params.declareControllable("FloodAmplitude");
  params.addParam<Real>("FloodPeakTime", 1.0, "Sediment slipperiness coefficient");
  params.declareControllable("FloodPeakTime");
  params.addParam<Real>("FloodSpreadTime", 1.0, "Sediment slipperiness coefficient");
  params.declareControllable("FloodSpreadTime");
  params.addParam<Real>("FloodSpeed", 1.0, "Sediment slipperiness coefficient");
  params.declareControllable("FloodSpeed");

  
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

    _SlipperinessCoefficientVariations(getParam<std::string>("SlipperinessCoefficientVariations")),

    _FloodAmplitude(getParam<Real>("FloodAmplitude")),
    _FloodPeakTime(getParam<Real>("FloodPeakTime")),
    _FloodSpreadTime(getParam<Real>("FloodSpreadTime")),
    _FloodSpeed(getParam<Real>("FloodSpeed")),
    
    // Ice properties created by this object
    _viscosity(declareADProperty<Real>("mu_sediment")),
    _density(declareADProperty<Real>("rho_sediment"))
{
}

void
ADSedimentMaterialSI::computeQpProperties()
{

  ADReal viscosity_baseline = _LayerThickness / _SlipperinessCoefficient;
  
  if (_SlipperinessCoefficientVariations == "constant")
    {
      _viscosity[_qp] = viscosity_baseline;
    }
  else if (_SlipperinessCoefficientVariations == "subglacialflood")
    {
      Real time_offset =_q_point[_qp](0) / _FloodSpeed;
      _viscosity[_qp] = viscosity_baseline;
    }
  
  // Constant density
  _density[_qp] = _rho;

}
