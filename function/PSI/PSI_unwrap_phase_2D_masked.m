function phi = PSI_unwrap_phase_2D_masked(wrapped, mask)
    [M, N] = size(wrapped);
    wrap_func = @(x) angle(exp(1i * x));
    dx = zeros(M, N); dx(:, 1:N-1) = wrap_func(wrapped(:, 2:N) - wrapped(:, 1:N-1));
    dy = zeros(M, N); dy(1:M-1, :) = wrap_func(wrapped(2:M, :) - wrapped(1:M-1, :));
    mask_dilated = imdilate(mask, strel('disk', 3));
    dx(~mask_dilated) = 0; dy(~mask_dilated) = 0;
    
    rho = zeros(M, N);
    rho(:, 2:N)   = rho(:, 2:N)   + dx(:, 1:N-1);
    rho(:, 1:N-1) = rho(:, 1:N-1) - dx(:, 1:N-1);
    rho(2:M, :)   = rho(2:M, :)   + dy(1:M-1, :);
    rho(1:M-1, :) = rho(1:M-1, :) - dy(1:M-1, :);
    
    [u, v] = meshgrid(0:N-1, 0:M-1);
    denom = 2 * (cos(pi*u/N) + cos(pi*v/M) - 2);
    denom(1,1) = 1; 
    phi_hat = dct2(rho) ./ denom;
    phi_hat(1,1) = 0; 
    phi = idct2(phi_hat);
end
