function f = Dp_y(Mat)
% Dp_y - Forward first-order finite difference along y.
% Input:
%   Mat - Input matrix.
% Output:
%   f   - Forward derivative along y.

[m n] = size(Mat);

if nargin == 1
    f = (Mat([2:m m],1:n) - Mat);
else error('Usage:  f = Dp_y(Mat)');
end
