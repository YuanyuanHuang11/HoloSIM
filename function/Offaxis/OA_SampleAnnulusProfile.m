function [profile_mean, theta_deg] = OA_SampleAnnulusProfile(img, center_x, center_y, radius_px, ring_halfwidth_px, n_r_avg, n_theta)
    theta = linspace(0, 2*pi, n_theta + 1);
    theta(end) = [];
    theta_deg = theta * 180 / pi;

    if n_r_avg <= 1
        radial_offsets = 0;
    else
        radial_offsets = linspace(-ring_halfwidth_px, ring_halfwidth_px, n_r_avg);
    end

    [XqBase, YqBase] = deal(zeros(numel(radial_offsets), n_theta));
    for kk = 1:numel(radial_offsets)
        rr = radius_px + radial_offsets(kk);
        XqBase(kk, :) = center_x + rr * cos(theta);
        YqBase(kk, :) = center_y + rr * sin(theta);
    end

    [X, Y] = meshgrid(1:size(img,2), 1:size(img,1));
    profiles = nan(size(XqBase));
    for kk = 1:size(XqBase,1)
        profiles(kk, :) = interp2(X, Y, double(img), XqBase(kk,:), YqBase(kk,:), 'linear', NaN);
    end
    profile_mean = mean(profiles, 1, 'omitnan');
end
