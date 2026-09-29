function phi = PSI_demod4Simple(I4)
    phi = angle((double(I4(:,:,1))-double(I4(:,:,3))) + 1i*(double(I4(:,:,2))-double(I4(:,:,4))));
end
