// Modified version of MASTODON's Ormsby Wavelet
// to allow for multiple and recurrent wavelets 
/*************************************************/
/*           DO NOT MODIFY THIS HEADER           */
/*                                               */
/*                     MASTODON                  */
/*                                               */
/*    (c) 2015 Battelle Energy Alliance, LLC     */
/*            ALL RIGHTS RESERVED                */
/*                                               */
/*   Prepared by Battelle Energy Alliance, LLC   */
/*     With the U. S. Department of Energy       */
/*                                               */
/*     See COPYRIGHT for full restrictions       */
/*************************************************/

#include "MultiOrmsbyWavelet.h"

registerMooseObject("diucaApp", MultiOrmsbyWavelet);

InputParameters
MultiOrmsbyWavelet::validParams()
{
  InputParameters params = Function::validParams();
  params.addRequiredParam<Real>("f1", "First frequency for defining the Ormsby wavelet.");
  params.addRequiredParam<Real>("f2", "Second frequency for defining the Ormsby wavelet.");
  params.addRequiredParam<Real>("f3", "Third frequency for defining the Ormsby wavelet.");
  params.addRequiredParam<Real>("f4", "Fourth frequency for defining the Ormsby wavelet.");
  params.addRequiredParam<Real>("ts", "Time of the peak of the Ormsby wavelet.");
  params.addRequiredParam<Real>("nb", "Number of times the wavelet will be repeated with a recurrence time of ts");
  params.addParam<Real>("scale_factor", 1.0, "Amplitude scale factor to be applied to wavelet.");
  params.addClassDescription(
      "Calculates an amplitude normalized Ormsby wavelet with the given input parameters.");
  return params;
}

MultiOrmsbyWavelet::MultiOrmsbyWavelet(const InputParameters & parameters)
  : Function(parameters), _scale_factor(getParam<Real>("scale_factor"))
{
}

Real
MultiOrmsbyWavelet::value(Real t, const Point &) const
{
  Real f1 = getParam<Real>("f1");
  Real f2 = getParam<Real>("f2");
  Real f3 = getParam<Real>("f3");
  Real f4 = getParam<Real>("f4");
  Real ts = getParam<Real>("ts");
  Real nb = getParam<Real>("nb");

  Real c1, c2, c3, c4, c;
  Real total=0.;
  Real ts_shifted;
  
  for(int i=0; i<nb; i++) {

    ts_shifted = ts + ts*i;
    
    c1 = libMesh::pi * f1 * f1 / (f2 - f1) * sinc(libMesh::pi * f1 * (t - ts)) *
      sinc(libMesh::pi * f1 * (t - ts));
    c2 = libMesh::pi * f2 * f2 / (f2 - f1) * sinc(libMesh::pi * f2 * (t - ts)) *
      sinc(libMesh::pi * f2 * (t - ts));
    c3 = libMesh::pi * f3 * f3 / (f3 - f4) * sinc(libMesh::pi * f3 * (t - ts)) *
      sinc(libMesh::pi * f3 * (t - ts));
    c4 = libMesh::pi * f4 * f4 / (f3 - f4) * sinc(libMesh::pi * f4 * (t - ts)) *
      sinc(libMesh::pi * f4 * (t - ts));

    // c is the max value
    c = (libMesh::pi * f4 * f4 / (f3 - f4) - libMesh::pi * f3 * f3 / (f3 - f4)) -
      (libMesh::pi * f2 * f2 / (f2 - f1) - libMesh::pi * f1 * f1 / (f2 - f1));

    total += _scale_factor / c * ((c4 - c3) - (c2 - c1));
  }
  
  return total;
}

// sinc function (tends to 1 as x -> 0)
inline Real
MultiOrmsbyWavelet::sinc(Real x) const
{
  return (x == 0) ? 1.0 : sin(x) / x;
}
