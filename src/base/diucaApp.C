#include "diucaApp.h"
#include "Moose.h"
#include "AppFactory.h"
#include "ModulesApp.h"
#include "MooseSyntax.h"

InputParameters
diucaApp::validParams()
{
  InputParameters params = MooseApp::validParams();
  params.set<bool>("use_legacy_material_output") = false;
  return params;
}

diucaApp::diucaApp(InputParameters parameters) : MooseApp(parameters)
{
  diucaApp::registerAll(_factory, _action_factory, _syntax);
}

diucaApp::~diucaApp() {}

void 
diucaApp::registerAll(Factory & f, ActionFactory & af, Syntax & s)
{
  ModulesApp::registerAllObjects<diucaApp>(f, af, s);
  Registry::registerObjectsTo(f, {"diucaApp"});
  Registry::registerActionsTo(af, {"diucaApp"});

  /* register custom execute flags, action syntax, etc. here */
}

void
diucaApp::registerApps()
{
  registerApp(diucaApp);
}

/***************************************************************************************************
 *********************** Dynamic Library Entry Points - DO NOT MODIFY ******************************
 **************************************************************************************************/
extern "C" void
diucaApp__registerAll(Factory & f, ActionFactory & af, Syntax & s)
{
  diucaApp::registerAll(f, af, s);
}
extern "C" void
diucaApp__registerApps()
{
  diucaApp::registerApps();
}
