function [phase_out, amplitude, object_wave] = PSI_DemodulatePhaseShift4_LSEC(hologram4, params)
    I0   = double(hologram4(:,:,1));
    I90  = double(hologram4(:,:,2));
    I180 = double(hologram4(:,:,3));
    I270 = double(hologram4(:,:,4));

    [Nx, Ny] = size(I0);

    % Sign convention matched to the HoloSIM_Hinc main-result script.
    % For I(delta)=|O+R*exp(i*delta)|^2 and delta=[0, pi/2, pi, 3pi/2]:
    % (I0-I180) + i*(I90-I270) = 4 * O * conj(R).
    complex_carrier = (I0 - I180) + 1i * (I90 - I270);

    % Remove the known tilted reference phase. If params.fx_ref=0 this is 1.
    [x, y] = meshgrid((-Ny/2:Ny/2-1) * params.dx, (-Nx/2:Nx/2-1) * params.dy);
    ref_phase = 2*pi*params.fx_ref*(x*cos(params.alpha) + y*sin(params.alpha));
    object_wave = complex_carrier .* exp(1i * ref_phase);

    amplitude = abs(object_wave);
    if max(amplitude(:)) > 0
        amplitude = amplitude / max(amplitude(:));
    end

    % For the current Siemens-star sweeps, phase steps are below pi. Use the
    % direct PSI phase and let RunSingleSIMQPMCase remove a background piston.
    % This avoids phase-unwrapping and polynomial-flattening degrees of freedom
    % that can bias phase-step/noise comparisons.
    phase_out = angle(object_wave);
end
