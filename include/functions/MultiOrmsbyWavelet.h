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

#pragma once

#include "Function.h"
#include "FunctionInterface.h"

class MultiOrmsbyWavelet;

/**
 * Class for an Ormsby Wavelet function
 */
class MultiOrmsbyWavelet : public Function
{
public:
  static InputParameters validParams();

  MultiOrmsbyWavelet(const InputParameters & parameters);

  virtual Real value(Real t, const Point & p) const override;

private:
  // sinc function
  inline Real sinc(Real x) const;

  // scale factor applied to the wavelet value
  const Real _scale_factor;
};
