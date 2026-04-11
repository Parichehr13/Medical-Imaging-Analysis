function nccval= NCC(I1, I2)
% NCC - Compute normalized cross-correlation between two images.
    mean1 = mean(mean(I1));
    mean2 = mean(mean(I2));
    numerator = sum(sum((I1-mean1).*(I2-mean2)));  
    denominator = sqrt(sum(sum((I1-mean1).^2)).*sum(sum((I2-mean2).^2)));

    nccval = numerator/denominator;
end
