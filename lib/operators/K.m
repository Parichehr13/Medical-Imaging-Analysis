function f = K(M)
% K - Curvature term for level-set regularization.

f = (Dxx(M).*(Dy(M).^2)-2.*Dy(M).*Dx(M).*(Dx(Dy(M)))+Dyy(M).*(Dx(M).^2) )./(((Dx(M).^2+Dy(M).^2).^(3/2))+1e-6);
