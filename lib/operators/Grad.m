function f = Grad(Mat)
% Grad - Gradient magnitude computed from centered derivatives.
[m n] = size(Mat);
f = sqrt(Dx(Mat).^2+Dy(Mat).^2); 
