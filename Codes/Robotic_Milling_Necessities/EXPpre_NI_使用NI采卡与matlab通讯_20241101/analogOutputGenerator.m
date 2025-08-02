function analogOutputGenerator
% ANALOGOUTPUTGENERATOR  Opens the Analog Output Generator App of the Data
% Acquisition Toolbox.

% Copyright 2018-2022 The MathWorks, Inc.

% Check whether the application is called from a desktop platform
import matlab.internal.lang.capability.Capability;
Capability.require(Capability.LocalClient);

pluginClass = 'matlab.hwmgr.plugins.DAQPlugin';
appletClass = 'daqaoapplet.applet.DAQAOApplet';

matlab.hwmgr.internal.launchApplet(appletClass, pluginClass);
end
