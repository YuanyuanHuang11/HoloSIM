function Iout = SIM_applyWFfluor(Iin,FR,S)
    H = SIM_incoherentOTF(FR, 2*S.NA_SIM/S.SIM_lambda);
    Iout = real(ifft2(fft2(double(Iin)).*fftshift(H)));
end
