function f = Dy(Mat)
% Dy - Centered first-order finite difference along y.
% Input:
%   Mat - Input matrix.
% Output:
%   f   - Centered derivative along y.


[m n] = size(Mat);

if nargin == 1
   f = (Mat([2:m m],1:n) - Mat([1 1:m-1],1:n))/2; 
else error('Usage: Dy = Dy(Mat)');
end
