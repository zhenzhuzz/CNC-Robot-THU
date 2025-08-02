% Indices for each tooth
teeth = zeros(1, Nt);
for cnt = 1:Nt
    teeth(cnt) = (cnt-1)*steps_rev/Nt + 1;
end

% Initialize geometry array
surf = zeros(steps_axial, steps_rev);

% Initial conditions for structural dynamics
x = 0;
y = 0;
x_dot = 0;
y_dot = 0;

% For single-mode x and y as in the script
p = 0;  % displacement in x-mode
dp = 0; % velocity in x-mode
q = 0;  % displacement in y-mode
dq = 0; % velocity in y-mode
