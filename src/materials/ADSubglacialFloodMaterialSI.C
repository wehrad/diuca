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

  params.addParam<Real>("FloodStartPosition", 9000., "X-axis position where the flood starts"); // 25000 - 16000=9000
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


  Real L=25000;

  Real back_viscosity = 1e11;
  Real front_viscosity = 1e9;
  
  Real _eta = back_viscosity - (back_viscosity - front_viscosity) * std::pow(_q_point[_qp](0) / L, 1.0); // 1.5
  _viscosity[_qp] = _eta;
  
  if (_SlipperinessCoefficientVariations == "subglacialflood")
    {
	
      if (_q_point[_qp](0) > _FloodStartPosition)
	{

	  Real front_FloodAmplitude = 0.;
	  Real back_FloodAmplitude = 6e10;

	  // with 0.6 coeff
	  // Real front_FloodAmplitude = 0.;
	  // Real back_FloodAmplitude = 6e10;
	  // 1.0361663336379097 6.328746891099259e-06
	  // 1.0489246879269614 9.284878782788374e-06
	  // 1.0515052017399946 1.0605450823647793e-05
	  // 1.0480440003387066 1.0753219002982968e-05
	  // 1.043846002796823 1.0691744852302947e-05
	  // 1.0396333526455055 1.0555758195222842e-05
	  // 1.0313612976746187 9.101199336437025e-06
	  // 1.0301669868573708 9.339631141835002e-06
	 
	  // with 1.0 coeff
	  // Real front_FloodAmplitude = 5.5e8;
	  // Real back_FloodAmplitude = 5.5e10;
	  // 1.0467069559723705 8.173250442312062e-06
	  // 1.0608893784021227 1.1555525882291632e-05
	  // 1.0705447761169258 1.4525895029983817e-05
	  // 1.0739246830107574 1.6545839241873775e-05
	  // 1.077038207223865 1.878558598222065e-05
	  // 1.0785125102623123 2.0910647682057795e-05
	  // 1.0671093521331194 1.9475456578347476e-05
	  // 1.0821633311388348 2.5437582143994096e-05

	  // with 0.95
	  // Real front_FloodAmplitude = 5.5e8;
	  // Real back_FloodAmplitude = 5.5e10;
	  // 1.0447141227673988 7.824524550527877e-06
	  // 1.0585619845194503 1.1113835378048081e-05
	  // 1.0670754333988408 1.3811521678477076e-05
	  // 1.0684473620623613 1.5319904030557113e-05
	  // 1.0693036156313311 1.6899523979548676e-05
	  // 1.0707905595497627 1.8854020142970577e-05
	  // 1.0599963774864924 1.7411237144393098e-05
	  // 1.071188610768931 2.203983345187903e-05
	  
	  // with 0.9 coeff
	  // Real front_FloodAmplitude = 5.5e8;
	  // Real back_FloodAmplitude = 5.5e10;
	  // 1.0428504661755666 7.498403274876317e-06
	  // 1.0566753881776052 1.075579899420374e-05
	  // 1.0639293032208117 1.3163701113550066e-05
	  // 1.0638578563164618 1.4292679818310482e-05
	  // 1.0638963322397237 1.558097061825223e-05
	  // 1.0643518739812903 1.713917132450775e-05
	  // 1.0541734308119504 1.572139002899961e-05
	  // 1.0622543008668528 1.9273791242003277e-05
	  
	  // with 0.8 coeff
	  // Real front_FloodAmplitude = 5.5e8;
	  // Real back_FloodAmplitude = 5.5e10;
	  // 1.0393510296730533 6.886036865065147e-06
	  // 1.052919589149449 1.0043027177222385e-05
	  // 1.0580447234839891 1.1952005616622344e-05
	  // 1.0570120638124683 1.2760452994452204e-05
	  // 1.0552480808112468 1.3472114809427206e-05
	  // 1.0538520396939168 1.4342695517407644e-05
	  // 1.0449383907589846 1.304133701352623e-05
	  // 1.0485952404692789 1.5044976927184955e-05
	  
	  // with 0.5 coeff
	  // Real front_FloodAmplitude = 5.5e8;
	  // Real back_FloodAmplitude = 5.5e10;
	  // 1.0287156519554794 5.024952068921786e-06
	  // 1.0392710117545703 7.452813687089572e-06
	  // 1.0401303609989214 8.263254112813391e-06
	  // 1.0371389112591503 8.31243950309124e-06
	  // 1.0337556252768234 8.23122998149092e-06
	  // 1.0309171982560328 8.23433918859895e-06
	  // 1.0256211664034416 7.43538564918709e-06
	  // 1.0242781285710192 7.516453888465225e-06
	  
	  // with 0.6 coeff 
	  // Real front_FloodAmplitude = 5.5e8;
	  // Real back_FloodAmplitude = 5.5e10; 
	  // 1.032466584306469 5.681327738424699e-06
	  // 1.0444212432068414 8.430219507419591e-06
	  // 1.046532100185641 9.581438060005928e-06
	  // 1.0438507485490687 9.81468444069135e-06
	  // 1.040535833949127 9.884567949505069e-06
	  // 1.0377333752095879 1.004972726290906e-05
	  // 1.03126606764055 9.073563122787129e-06
	  // 1.0307056090244995 9.50638735085186e-06
	  
	  // Real front_FloodAmplitude = 5.5e8; 8.2 
	  // Real back_FloodAmplitude = 5.5e10; 4.6
	  
	  // constant peak amplitude with no amplitude at the front,
	  // blowing up..
	  // Real front_FloodAmplitude = 0.;
	  // Real back_FloodAmplitude = 6.3e10;

	  // try constant peak value but blows up
	  // Real front_FloodAmplitude = 0.5e9; 
	  // Real back_FloodAmplitude = 6.386e10;
	  
	  // Real front_FloodAmplitude = 0.; 7.0
	  // Real back_FloodAmplitude = 5.5e10; 4.6

	  // Real front_FloodAmplitude = 5e2; 7.0
	  // Real back_FloodAmplitude = 5.5e10; 4.6
	  
	  // Real front_FloodAmplitude = 5e4; 7.0
	  // Real back_FloodAmplitude = 5.5e10; 4.6
	  
	  // Real front_FloodAmplitude = 5e5; 7.0
	  // Real back_FloodAmplitude = 5.5e10; 4.6

	  // Real front_FloodAmplitude = 5e7; 7.1
	  // Real back_FloodAmplitude = 5.5e10; 4.6

	  // Real front_FloodAmplitude = 5e8; 7.2
	  // Real back_FloodAmplitude = 5.5e10; 4.6

  
	  // Real front_FloodAmplitude = 1e8;
	  // Real back_FloodAmplitude = 5e10;
	  
	  Real varying_FloodAmplitude = back_FloodAmplitude - (back_FloodAmplitude - front_FloodAmplitude) * std::pow(((_q_point[_qp](0) - _FloodStartPosition) / (L - _FloodStartPosition)), 0.6);
	    
	  Real x_relative = _q_point[_qp](0) - _FloodStartPosition;
	  Real flood_dt = x_relative / _FloodSpeed;
	  Real flood_t = _t - flood_dt;
	  
	  Real _FloodViscosity = _eta - varying_FloodAmplitude * std::exp((-(std::pow(flood_t - _FloodPeakTime, 2))) / (2 * std::pow(_FloodSpreadTime, 2)));
	  // Real _FloodViscosity = _eta - _eta * _FloodAmplitude * std::exp((-(std::pow(flood_t - _FloodPeakTime, 2))) / (2 * std::pow(_FloodSpreadTime, 2)));
	_viscosity[_qp] = _FloodViscosity;
	
      }
      
      // The subglacial flood is defined as a Gaussian with a shift as a function of X
      // Real _FloodSlipperinessCoefficient = _FloodAmplitude * std::exp((-(std::pow(flood_t - _FloodPeakTime, 2))) / (2 * std::pow(_FloodSpreadTime, 2))) + _SlipperinessCoefficient;	    
      // _viscosity[_qp] = _LayerThickness / _FloodSlipperinessCoefficient;
      
    }
  
  // Constant density
  _density[_qp] = _rho;

}
