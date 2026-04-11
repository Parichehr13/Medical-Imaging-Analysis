function f = Dm_x(Mat)
% Dm_x - Backward first-order finite difference along x.
% Input:
%   Mat - Input matrix.
% Output:
%   f   - Backward derivative along x.

[m n] = size(Mat);
if nargin == 1
    f = (Mat - Mat(1:m,[1 1:n-1]));
else error('Usage:  f = Dm_x(Mat)');
end
