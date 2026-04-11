function f = Dm_y(Mat)
% Dm_y - Backward first-order finite difference along y.
% Input:
%   Mat - Input matrix.
% Output:
%   f   - Backward derivative along y.

[m n] = size(Mat);

if nargin == 1
    f = (Mat - Mat([1 1:m-1],1:n));
else error('Usage:  f = Dm_y(Mat)');
end
