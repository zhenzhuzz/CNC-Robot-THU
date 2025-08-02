function createParamsBus()
% CREATEPARAMSBUS Creates a bus object for the 'params' structure from initMillingParameters()

    % Predeclare an array of BusElement objects, one per field in 'params'
    elems(1) = Simulink.BusElement;  % Ks
    elems(2) = Simulink.BusElement;  % beta
    elems(3) = Simulink.BusElement;  % kt
    elems(4) = Simulink.BusElement;  % kn
    elems(5) = Simulink.BusElement;  % C
    elems(6) = Simulink.BusElement;  % kx
    elems(7) = Simulink.BusElement;  % zetax
    elems(8) = Simulink.BusElement;  % wnx
    elems(9) = Simulink.BusElement;  % mx
    elems(10) = Simulink.BusElement; % cx
    elems(11) = Simulink.BusElement; % ky
    elems(12) = Simulink.BusElement; % zetay
    elems(13) = Simulink.BusElement; % wny
    elems(14) = Simulink.BusElement; % my
    elems(15) = Simulink.BusElement; % cy
    elems(16) = Simulink.BusElement; % Nt
    elems(17) = Simulink.BusElement; % d
    elems(18) = Simulink.BusElement; % gamma
    elems(19) = Simulink.BusElement; % phis
    elems(20) = Simulink.BusElement; % phie
    elems(21) = Simulink.BusElement; % omega
    elems(22) = Simulink.BusElement; % b
    elems(23) = Simulink.BusElement; % ft
    elems(24) = Simulink.BusElement; % v
    elems(25) = Simulink.BusElement; % dt
    elems(26) = Simulink.BusElement; % dphi
    elems(27) = Simulink.BusElement; % steps_axial
    elems(28) = Simulink.BusElement; % rev
    elems(29) = Simulink.BusElement; % steps_rev
    elems(30) = Simulink.BusElement; % totalSteps
    elems(31) = Simulink.BusElement; % phi (array)

    % Assign names
    elems(1).Name  = 'Ks';
    elems(2).Name  = 'beta'; 
    elems(3).Name  = 'kt';
    elems(4).Name  = 'kn';
    elems(5).Name  = 'C';
    elems(6).Name  = 'kx';
    elems(7).Name  = 'zetax';
    elems(8).Name  = 'wnx';
    elems(9).Name  = 'mx';
    elems(10).Name = 'cx';
    elems(11).Name = 'ky';
    elems(12).Name = 'zetay';
    elems(13).Name = 'wny';
    elems(14).Name = 'my';
    elems(15).Name = 'cy';
    elems(16).Name = 'Nt';
    elems(17).Name = 'd';
    elems(18).Name = 'gamma';
    elems(19).Name = 'phis';
    elems(20).Name = 'phie';
    elems(21).Name = 'omega';
    elems(22).Name = 'b';
    elems(23).Name = 'ft';
    elems(24).Name = 'v';
    elems(25).Name = 'dt';
    elems(26).Name = 'dphi';
    elems(27).Name = 'steps_axial';
    elems(28).Name = 'rev';
    elems(29).Name = 'steps_rev';
    elems(30).Name = 'totalSteps';

    % 'phi' is an array and marked variable-size
    elems(31).Name       = 'phi';
    elems(31).DimensionsMode = 'Variable';  % Mark as variable-size
function createParamsBus()
% CREATEPARAMSBUS Creates a bus object for the 'params' structure from initMillingParameters()

    % Predeclare an array of BusElement objects, one per field in 'params'
    elems(1) = Simulink.BusElement;  % Ks
    elems(2) = Simulink.BusElement;  % beta
    elems(3) = Simulink.BusElement;  % kt
    elems(4) = Simulink.BusElement;  % kn
    elems(5) = Simulink.BusElement;  % C
    elems(6) = Simulink.BusElement;  % kx
    elems(7) = Simulink.BusElement;  % zetax
    elems(8) = Simulink.BusElement;  % wnx
    elems(9) = Simulink.BusElement;  % mx
    elems(10) = Simulink.BusElement; % cx
    elems(11) = Simulink.BusElement; % ky
    elems(12) = Simulink.BusElement; % zetay
    elems(13) = Simulink.BusElement; % wny
    elems(14) = Simulink.BusElement; % my
    elems(15) = Simulink.BusElement; % cy
    elems(16) = Simulink.BusElement; % Nt
    elems(17) = Simulink.BusElement; % d
    elems(18) = Simulink.BusElement; % gamma
    elems(19) = Simulink.BusElement; % phis
    elems(20) = Simulink.BusElement; % phie
    elems(21) = Simulink.BusElement; % omega
    elems(22) = Simulink.BusElement; % b
    elems(23) = Simulink.BusElement; % ft
    elems(24) = Simulink.BusElement; % v
    elems(25) = Simulink.BusElement; % dt
    elems(26) = Simulink.BusElement; % dphi
    elems(27) = Simulink.BusElement; % steps_axial
    elems(28) = Simulink.BusElement; % rev
    elems(29) = Simulink.BusElement; % steps_rev
    elems(30) = Simulink.BusElement; % totalSteps
    elems(31) = Simulink.BusElement; % phi (array)

    % Assign names
    elems(1).Name  = 'Ks';
    elems(2).Name  = 'beta'; 
    elems(3).Name  = 'kt';
    elems(4).Name  = 'kn';
    elems(5).Name  = 'C';
    elems(6).Name  = 'kx';
    elems(7).Name  = 'zetax';
    elems(8).Name  = 'wnx';
    elems(9).Name  = 'mx';
    elems(10).Name = 'cx';
    elems(11).Name = 'ky';
    elems(12).Name = 'zetay';
    elems(13).Name = 'wny';
    elems(14).Name = 'my';
    elems(15).Name = 'cy';
    elems(16).Name = 'Nt';
    elems(17).Name = 'd';
    elems(18).Name = 'gamma';
    elems(19).Name = 'phis';
    elems(20).Name = 'phie';
    elems(21).Name = 'omega';
    elems(22).Name = 'b';
    elems(23).Name = 'ft';
    elems(24).Name = 'v';
    elems(25).Name = 'dt';
    elems(26).Name = 'dphi';
    elems(27).Name = 'steps_axial';
    elems(28).Name = 'rev';
    elems(29).Name = 'steps_rev';
    elems(30).Name = 'totalSteps';
    elems(31).Name = 'phi';

    % Create a Simulink.Bus object and assign the elements
    ParamsBus = Simulink.Bus;
    ParamsBus.Elements = elems;

    % Place the bus object in the base workspace
    assignin('base','ParamsBus', ParamsBus);

end

    % Create a Simulink.Bus object and assign the elements
    ParamsBus = Simulink.Bus;
    ParamsBus.Elements = elems;

    % Place the bus object in the base workspace
    assignin('base','ParamsBus', ParamsBus);

end
