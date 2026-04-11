function f = Dyy(Mat)
% Dyy - Second-order finite difference along y.
% Input:
%   Mat - Input matrix.
% Output:
%   f   - Second derivative along y.
 
[m n] = size(Mat);

if nargin == 1
    f = (Mat([2:m m],1:n) - 2.* Mat + Mat([1 1:m-1],1:n));
else error('Usage: f = Dyy(Mat)');
end
