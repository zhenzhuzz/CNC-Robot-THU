%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Local function: localComputeModalBlock (inline)
%   returns the 2x2 real representation of the product
%   "Psi_L^T * K_xy * Psi_R" for one complex mode
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function Kblock = localComputeModalBlock(Kxy, Rx, Ry, Lx, Ly)
    % Kxy: 2x2 real, representing cutting stiffness in XY.
    % (Rx,Ry): right eigenvector complex components for the mode
    % (Lx,Ly): left eigenvector complex components for the mode
    % We want something like: scalar = [Lx*, Ly*] * Kxy * [Rx; Ry].
    % But to embed in the real 2x2 block, we use real expansions:
    % Let R = (Rx + i Ry) in vector form => we store as [Rr; Ri].
    % Then the 2x2 is built from partial derivatives. 
    % For demonstration, we do a simple approach: compute the complex scalar
    % then convert that single complex scalar to a 2x2 real block.

    % form complex vectors:
    R_vec = [Rx; Ry];  % 2x1
    L_vec = [Lx; Ly];  % 2x1

    % compute the complex scalar:
    alpha = (conj(L_vec))' * (Kxy * R_vec);
    % NOTE: If your definition requires L^T w/o conjugation, adjust as needed.
    % In many treatments, we use L^H = conj transpose. 
    % But the exact step depends on how you define your left/right eigenvectors 
    % and normalization. Adjust consistently with your paper.

    % alpha is a single complex number. The real form is:
    %   [ real(alpha), -imag(alpha);
    %     imag(alpha),  real(alpha) ]
    ar = real(alpha);
    ai = imag(alpha);

    Kblock = [ar, -ai;
              ai,  ar];
end