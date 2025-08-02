function createStatesBus
    % Example: create a bus for 'states' with 10 fields.

    %--- 1) Create an empty array of bus elements
    elems(1) = Simulink.BusElement;  % Preallocate
    elems(2) = Simulink.BusElement;
    elems(3) = Simulink.BusElement;
    elems(4) = Simulink.BusElement;
    elems(5) = Simulink.BusElement;
    elems(6) = Simulink.BusElement;
    elems(7) = Simulink.BusElement;
    elems(8) = Simulink.BusElement;
    elems(9) = Simulink.BusElement;
    elems(10) = Simulink.BusElement;

    %--- 2) Name each element to match 'states' fields
    elems(1).Name = 'teeth';  % 1D array
    elems(2).Name = 'surf';   % 2D array
    elems(3).Name = 'x';
    elems(4).Name = 'y';
    elems(5).Name = 'x_dot';
    elems(6).Name = 'y_dot';
    elems(7).Name = 'p';
    elems(8).Name = 'dp';
    elems(9).Name = 'q';
    elems(10).Name = 'dq';

    %--- 3) Create the bus
    StatesBus = Simulink.Bus;
    StatesBus.Elements = elems;

    %--- 4) Assign the bus to a variable in the base workspace
    assignin('base','StatesBus',StatesBus);
end
