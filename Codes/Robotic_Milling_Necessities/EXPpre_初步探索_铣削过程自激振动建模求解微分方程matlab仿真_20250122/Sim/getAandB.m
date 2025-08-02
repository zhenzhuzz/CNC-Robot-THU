%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Helper function: getAandB.m    (inline here)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [A_mat, B_mat] = getAandB(t, ap, lambda14p, lambda14m, lambda15p, lambda15m, ...
                                   Psi14R_x, Psi14R_y, Psi14L_x, Psi14L_y, ...
                                   Psi15R_x, Psi15R_y, Psi15L_x, Psi15L_y, ...
                                   directionalFactor, Kt, Kr)
    % This function returns the 4x4 real representation of A(t) and B(t)
    % for the 2 complex modes #14, #15 at the given time t,
    % given the nominal parameters and the current depth of cut ap.

    % 1) The diagonal "Lambda" portion (unforced part):
    % We'll store as a block 4x4 in real form. Each complex eigenvalue => 2x2 block.
    
    % Construct 2x2 block for mode 14 (real representation):
    Re14 = real(lambda14p);
    Im14 = imag(lambda14p);
    % For a pair (lambda14p, lambda14m):
    % Real form is [ Re   -Im
    %               Im    Re  ]
    A_block14 = [ Re14, -Im14;
                  Im14,  Re14];
    
    % Construct 2x2 block for mode 15:
    Re15 = real(lambda15p);
    Im15 = imag(lambda15p);
    A_block15 = [ Re15, -Im15;
                  Im15,  Re15];

    % So the no-delay matrix (Lambda) in real form is block diagonal:
    A_lambda = blkdiag(A_block14, A_block15);

    % 2) The time-varying cutting portion in modal coordinates:
    %    A(t) = Lambda + Psi_L^T * K(t) * Psi_R
    %    B(t) =          - Psi_L^T * K(t) * Psi_R
    %
    % We'll define a 2x2 "K_xy(t)" in physical XY from Kt, Kr, etc.
    % Then transform to the 2-mode space. But we must carefully do a real form version
    % of "Psi_L^T * K_xy * Psi_R." For brevity, we treat each mode’s shape as {x,y}.

    % For demonstration, let’s define a simple scalar directionFactor(t) * (Kt or Kr).
    dFac = directionalFactor(t);
    % A typical 2x2 directional matrix might be:
    %   K_xy = [ Kxx(t), Kxy(t);
    %            Kyx(t), Kyy(t) ];
    % We'll define a small example: 
    K_xy = dFac * [ Kt,  0;
                    0 ,  Kr ];
    % Then multiply by ap to scale by depth of cut:
    K_xy = ap * K_xy;  % total cutting stiffness in physical XY

    % Project from XY => modal => XY:
    % If we had "Phi_R = [ Psi14R_x, Psi15R_x; Psi14R_y, Psi15R_y ]" as a 2x2,
    % and "Phi_L = [ Psi14L_x, Psi15L_x; Psi14L_y, Psi15L_y ]", for the complex modes,
    % then: K_modal = Phi_L^T * K_xy * Phi_R.
    % But we must do real expansions. Below is only an illustrative approach.
    % The user must carefully keep real form expansions of left & right vectors.

    % For brevity in this snippet, let's treat each mode individually:
    %    K14 = <Psi14L, K_xy * Psi14R>
    % We'll create a function to do:  (psiL_x^*, psiL_y^*) * K_xy * (psiR_x, psiR_y)^T
    %   (where ^* is complex conjugate if needed).
    % Then we embed that result in the 2x2 block for the real form coupling.

    K_block14 = localComputeModalBlock(K_xy, Psi14R_x, Psi14R_y, Psi14L_x, Psi14L_y);
    K_block15 = localComputeModalBlock(K_xy, Psi15R_x, Psi15R_y, Psi15L_x, Psi15L_y);

    % Now we have each mode's 2x2 (in real form) from the cutting force. Combine them:
    A_cut = blkdiag(K_block14, K_block15);
    B_cut = -A_cut;  % B(t) = - (Psi_L^T K(t) Psi_R) in the same real-block sense

    A_mat = A_lambda + A_cut;
    B_mat = B_cut;
end