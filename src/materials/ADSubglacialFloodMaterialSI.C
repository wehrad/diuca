#include "ADSubglacialFloodMaterialSI.h"
#include "MooseMesh.h"

registerMooseObject("diucaApp", ADSubglacialFloodMaterialSI);

InputParameters
ADSubglacialFloodMaterialSI::validParams()
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

    params.addParam<Real>("FloodStartPosition", 10000, "X-axis position where the flood starts");
  params.declareControllable("FloodStartPosition");
  params.addParam<Real>("FloodAmplitude", 1e-10, "Amplitude of variations in slipperiness coefficient");
  params.declareControllable("FloodAmplitude");
  params.addParam<Real>("FloodPeakTime", 3600*24, "Timing of flood peak in seconds");
  params.declareControllable("FloodPeakTime");
  params.addParam<Real>("FloodSpreadTime", 3600*3, "Flood spread (as std of a gaussian)");
  params.declareControllable("FloodSpreadTime");
  params.addParam<Real>("FloodSpeed", 0.83, "Propagation speed of the flood peak in m.s-1");
  params.declareControllable("FloodSpeed");

  
  return params;
}

ADSubglacialFloodMaterialSI::ADSubglacialFloodMaterialSI(const InputParameters & parameters)
  : ADMaterial(parameters),

    // Mesh dimension
    _mesh_dimension(_mesh.dimension()),

    // Ice density
    _rho(getParam<ADReal>("density")),

    _LayerThickness(getParam<Real>("LayerThickness")),

    _SlipperinessCoefficient(getParam<Real>("SlipperinessCoefficient")),

    _SlipperinessCoefficientVariations(getParam<std::string>("SlipperinessCoefficientVariations")),

    _FloodStartPosition(getParam<Real>("FloodStartPosition")),
    _FloodAmplitude(getParam<Real>("FloodAmplitude")),
    _FloodPeakTime(getParam<Real>("FloodPeakTime")),
    _FloodSpreadTime(getParam<Real>("FloodSpreadTime")),
    _FloodSpeed(getParam<Real>("FloodSpeed")),
    
    // Ice properties created by this object
    _viscosity(declareADProperty<Real>("mu_floodedsediment")),
    _density(declareADProperty<Real>("rho_floodedsediment"))
{
}

void
ADSubglacialFloodMaterialSI::computeQpProperties()
{

  if (_SlipperinessCoefficientVariations == "constant")
    {

      Real L=25000;

      Real back_viscosity = 1e11;
      Real front_viscosity = 1e9;
      
      Real viscosity_rate = (back_viscosity - front_viscosity) / L;

      Real increasing_C = _LayerThickness / (back_viscosity - viscosity_rate * _q_point[_qp](0));

      _viscosity[_qp] = _LayerThickness / increasing_C;

      // _viscosity[_qp] = _LayerThickness / _SlipperinessCoefficient;
    }
  else if (_SlipperinessCoefficientVariations == "subglacilflood")
    {
      Real x_relative = _q_point[_qp](0) - _FloodStartPosition;
      Real flood_dt = x_relative / _FloodSpeed;
      Real flood_t = _t - flood_dt;

      // The subglacial flood is defined as a Gaussian with a shift as a function of X
      Real _FloodSlipperinessCoefficient = _FloodAmplitude * std::exp((-(std::pow(flood_t - _FloodPeakTime, 2))) / (2 * std::pow(_FloodSpreadTime, 2))) + _SlipperinessCoefficient;
	    
      _viscosity[_qp] = _LayerThickness / _FloodSlipperinessCoefficient;
    }
  
  // Constant density
  _density[_qp] = _rho;

}
