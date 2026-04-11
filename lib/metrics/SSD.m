function ssdval = SSD(I1, I2)
% SSD - Compute sum of squared differences between two images.
    ssdval = sum(sum((I1-I2).^2));
end
