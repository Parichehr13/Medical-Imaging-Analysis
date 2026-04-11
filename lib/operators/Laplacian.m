function f = laplacian(Mat)
% Laplacian - Sum of second derivatives along x and y.
[m n] = size(Mat);
f = Dxx(Mat)+Dyy(Mat); 
