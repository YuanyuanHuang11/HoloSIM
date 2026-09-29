function Uz = NF_propagateField(U0,Hs)
    Uz = ifft2(fft2(U0).*fftshift(Hs));
end
