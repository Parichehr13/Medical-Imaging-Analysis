function f = Dx(Mat)
% Dx - Centered first-order finite difference along x.
% Input:
%   Mat - Input matrix.
% Output:
%   f   - Centered derivative along x.
 
[m n] = size(Mat);

if nargin == 1
    f = (Mat(1:m,[2:n n]) - Mat(1:m,[1 1:n-1]))/2;
else error('Usage: Dx = Dx(Mat)');
end
