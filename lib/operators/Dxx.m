function f = Dxx(Mat)
% Dxx - Second-order finite difference along x.
% Input:
%   Mat - Input matrix.
% Output:
%   f   - Second derivative along x.
 
[m n] = size(Mat);

if nargin == 1
   f = (Mat(1:m,[2:n n]) - 2.*Mat + Mat(1:m,[1 1:n-1])); 
else error('Usage: f = Dxx(Mat)');
end

