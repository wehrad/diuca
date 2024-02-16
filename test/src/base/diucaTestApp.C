//* This file is part of the MOOSE framework
//* https://www.mooseframework.org
//*
//* All rights reserved, see COPYRIGHT for full restrictions
//* https://github.com/idaholab/moose/blob/master/COPYRIGHT
//*
//* Licensed under LGPL 2.1, please see LICENSE for details
//* https://www.gnu.org/licenses/lgpl-2.1.html
#include "diucaTestApp.h"
#include "diucaApp.h"
#include "Moose.h"
#include "AppFactory.h"
#include "MooseSyntax.h"

InputParameters
diucaTestApp::validParams()
{
  InputParameters params = diucaApp::validParams();
  params.set<bool>("use_legacy_material_output") = false;
  return params;
}

diucaTestApp::diucaTestApp(InputParameters parameters) : MooseApp(parameters)
{
  diucaTestApp::registerAll(
      _factory, _action_factory, _syntax, getParam<bool>("allow_test_objects"));
}

diucaTestApp::~diucaTestApp() {}

void
diucaTestApp::registerAll(Factory & f, ActionFactory & af, Syntax & s, bool use_test_objs)
{
  diucaApp::registerAll(f, af, s);
  if (use_test_objs)
  {
    Registry::registerObjectsTo(f, {"diucaTestApp"});
    Registry::registerActionsTo(af, {"diucaTestApp"});
  }
}

void
diucaTestApp::registerApps()
{
  registerApp(diucaApp);
  registerApp(diucaTestApp);
}

/***************************************************************************************************
 *********************** Dynamic Library Entry Points - DO NOT MODIFY ******************************
 **************************************************************************************************/
// External entry point for dynamic application loading
extern "C" void
diucaTestApp__registerAll(Factory & f, ActionFactory & af, Syntax & s)
{
  diucaTestApp::registerAll(f, af, s);
}
extern "C" void
diucaTestApp__registerApps()
{
  diucaTestApp::registerApps();
}
