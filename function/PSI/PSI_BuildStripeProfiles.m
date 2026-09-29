function stripe_profiles = PSI_BuildStripeProfiles(GT_ref, GT_phi, phase_QPM, phase_HoloSIM, params)
    max_fov = (params.N/2) * params.dx;
    xvec_m = GT_ref.x(1,:);
    yvec_m = GT_ref.y(:,1);

    % Vertical grating bars occupy x=[-0.2,0]*max_fov, y=[0.2,0.6]*max_fov.
    y_v = 0.40 * max_fov;
    x_center_v = -0.10 * max_fov;
    x_half_v = 0.17 * max_fov;
    [~, iy_v] = min(abs(yvec_m - y_v));
    idx_v = xvec_m >= (x_center_v - x_half_v) & xvec_m <= (x_center_v + x_half_v);

    stripe_profiles.vertical_grating.name = 'vertical grating';
    stripe_profiles.vertical_grating.axis_nm = (xvec_m(idx_v) - x_center_v) * 1e9;
    stripe_profiles.vertical_grating.GT = GT_phi(iy_v, idx_v);
    stripe_profiles.vertical_grating.HoloSIM = phase_HoloSIM(iy_v, idx_v);
    stripe_profiles.vertical_grating.QPM = phase_QPM(iy_v, idx_v);
    stripe_profiles.vertical_grating.position_nm = yvec_m(iy_v) * 1e9;

    % Horizontal grating bars occupy x=[0.1,0.3]*max_fov, y=[0.2,0.6]*max_fov.
    x_h = 0.20 * max_fov;
    y_center_h = 0.40 * max_fov;
    y_half_h = 0.25 * max_fov;
    [~, ix_h] = min(abs(xvec_m - x_h));
    idx_h = yvec_m >= (y_center_h - y_half_h) & yvec_m <= (y_center_h + y_half_h);

    stripe_profiles.horizontal_grating.name = 'horizontal grating';
    stripe_profiles.horizontal_grating.axis_nm = (yvec_m(idx_h) - y_center_h) * 1e9;
    stripe_profiles.horizontal_grating.GT = GT_phi(idx_h, ix_h).';
    stripe_profiles.horizontal_grating.HoloSIM = phase_HoloSIM(idx_h, ix_h).';
    stripe_profiles.horizontal_grating.QPM = phase_QPM(idx_h, ix_h).';
    stripe_profiles.horizontal_grating.position_nm = xvec_m(ix_h) * 1e9;
end
