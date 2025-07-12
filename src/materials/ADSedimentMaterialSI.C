#include "ADSedimentMaterialSI.h"
#include "MooseMesh.h"

registerMooseObject("diucaApp", ADSedimentMaterialSI);

InputParameters
ADSedimentMaterialSI::validParams()
{
  InputParameters params = ADMaterial::validParams();

  params.addParam<Real>("density", 917., "Sediment density"); // kgm-3

  // Sediment layer thickness (Slip model)
  params.addParam<Real>("LayerThickness", 1.0, "Sediment layer thickness"); // m
  params.declareControllable("LayerThickness");

  // Friction coefficient (Slip model)
  params.addParam<Real>("SlipperinessCoefficient", 1.0, "Sediment slipperiness coefficient");
  params.declareControllable("SlipperinessCoefficient");

  // Required characteristics of a subglacial flood
  params.addParam<bool>("SubglacialFlood", false, "Apply a subglacial flood");
  params.declareControllable("SubglacialFlood");
  params.addParam<Real>("FloodStartPosition", 9000., "X-axis position where the flood starts");
  params.declareControllable("FloodStartPosition");
  params.addParam<Real>("FloodLateralSpread", 2000., "Y-axis flood spread around center line");
  params.declareControllable("FloodLateralSpread");
  params.addParam<Real>("FloodAmplitude", 1e-10, "Amplitude of variations in slipperiness coefficient");
  params.declareControllable("FloodAmplitude");
  params.addParam<Real>("FloodPeakTime", 3600*10, "Timing of flood peak in seconds");
  params.declareControllable("FloodPeakTime");
  params.addParam<Real>("FloodSpreadTime", 3600*3, "Flood spread (as std of a gaussian)");
  params.declareControllable("FloodSpreadTime");
  params.addParam<Real>("FloodSpeed", 0.83, "Propagation speed of the flood peak in m.s-1");
  params.declareControllable("FloodSpeed");

  return params;
}

ADSedimentMaterialSI::ADSedimentMaterialSI(const InputParameters & parameters)
  : ADMaterial(parameters),

    // Mesh dimension
    _mesh_dimension(_mesh.dimension()),

    // Sediment density
    _rho(getParam<Real>("density")),

    // Sediment layer characteristics
    _LayerThickness(getParam<Real>("LayerThickness")),
    _SlipperinessCoefficient(getParam<Real>("SlipperinessCoefficient")),
    
    // Subglacial flood characteristics
    _SubglacialFlood(getParam<bool>("SubglacialFlood")),
    _FloodStartPosition(getParam<Real>("FloodStartPosition")),
    _FloodLateralSpread(getParam<Real>("FloodLateralSpread")),
    _FloodAmplitude(getParam<Real>("FloodAmplitude")),
    _FloodPeakTime(getParam<Real>("FloodPeakTime")),
    _FloodSpreadTime(getParam<Real>("FloodSpreadTime")),
    _FloodSpeed(getParam<Real>("FloodSpeed")),

    // Sediment properties created by this object
    _viscosity(declareADProperty<Real>("mu_sediment")),
    _density(declareADProperty<Real>("rho_sediment"))

{
}

void
ADSedimentMaterialSI::computeQpProperties()
{

  Real L=25000;
  Real W=10000;

  // Real eta_back_center=5e10;
  // Real eta_front_center=5e10;
  // Real eta_sides=6e12;

  // Real eta_back_center=1e11;
  // Real eta_front_center=1e10;
  // Real eta_sides=5e12;

  Real eta_back_center=1e11;
  Real eta_front_center=1e10;
  Real eta_sides=1e13;

  Real sigma_y=1500;
  Real eta_center = eta_back_center + (eta_front_center - eta_back_center) * (_q_point[_qp](0) / L);
  Real y0 = W / 2;
  Real gaussian_damping = std::exp(-(std::pow(_q_point[_qp](1) - y0, 2)) / (2 * std::pow(sigma_y, 2)));
  Real _eta = eta_sides + (eta_center - eta_sides) * gaussian_damping;
      
  if (_SubglacialFlood == true){

    if (_q_point[_qp](0) >= _FloodStartPosition){
      if (_q_point[_qp](1) <= (W/2) + (_FloodLateralSpread/2)){
	  if (_q_point[_qp](1) >= (W/2) - (_FloodLateralSpread/2)){
        
	    Real front_FloodAmplitude = 4e10;
	    Real back_FloodAmplitude = 4e10;
	    
	    Real varying_FloodAmplitude = back_FloodAmplitude - (back_FloodAmplitude - front_FloodAmplitude) * std::pow(((_q_point[_qp](0) - _FloodStartPosition) / (L - _FloodStartPosition)), 0.6);
	    
	    Real x_relative = _q_point[_qp](0) - _FloodStartPosition;
	    Real flood_dt = x_relative / _FloodSpeed;
	    Real flood_t = _t - flood_dt;
	    
	    std::cout << _eta << " ";
	    
	    _eta -= varying_FloodAmplitude * std::exp((-(std::pow(flood_t - _FloodPeakTime, 2))) / (2 * std::pow(_FloodSpreadTime, 2)));
	
	  }
      }
    }
  }
    
  _viscosity[_qp] = _eta;
  // _viscosity[_qp] = _LayerThickness / _SlipperinessCoefficient;

  // Constant density (not used for the linear sliding law here)
  _density[_qp] = _rho;

}
