function f = Dp_x(Mat)
% Dp_x - Forward first-order finite difference along x.
% Input:
%   Mat - Input matrix.
% Output:
%   f   - Forward derivative along x.

[m n] = size(Mat);

if nargin == 1
    f = (Mat(1:m,[2:n n]) - Mat);
else error('Usage:  f = Dp_x(Mat)');
end



    
