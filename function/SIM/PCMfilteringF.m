function [fDof,fDp2,fDm2,npDo,npDp,npDm,Mm,DoubleMatSize,fixedParams]...
    = PCMfilteringF(fDo,fDp,fDm,OTFo,OBJparaA,kA,fixedParams)

% AIM: obtaining Wiener Filtered estimates of noisy frequency components
% INPUT VARIABLES
%   fDo,fDp,fDm: noisy estimates of separated frequency components
%   OTFo: system OTF
%   OBJparaA: object power parameters
%   kA: illumination vector
% OUTPUT VARIABLES
%   fDof,fDp2,fDm2: Wiener Filtered estimates of fDo,fDp,fDm
%   npDo,npDp,npDm: avg. noise power in fDo,fDp,fDm
%   Mm: illumination modulation factor
%   DoubleMatSize: parameter for doubling FT size if necessary

calibrate = nargin < 7 || isempty(fixedParams);
if ~calibrate
    assert(isequal(size(fDo),size(fixedParams.Wo)), 'Cached Wiener dimensions differ.');
end
w = size(OTFo,1);
wo = w/2;
x = linspace(0,w-1,w);
y = linspace(0,w-1,w);
[X,Y] = meshgrid(x,y);
Cv = (X-wo) + 1i*(Y-wo);
Ro = abs(Cv);

% OTF cut-off frequency
Kotf = OTFedgeF(OTFo);

% object power parameters
Aobj = OBJparaA(1);
Bobj = OBJparaA(2);

% Wiener Filtering central frequency component
SFo = 1;
co = 1.0; 
if calibrate
    [fDof,npDo] = WoFilterCenter(fDo,OTFo,co,OBJparaA,SFo);
else
    fDof = fDo .* fixedParams.Wo;
    npDo = fixedParams.npDo;
end

% modulation factor determination
if calibrate
    Mm = ModulationFactor(fDp,kA,OBJparaA,OTFo);
else
    Mm = fixedParams.Mm;
end

%% Duplex power (default)
kv = kA(2) + 1i*kA(1); % vector along illumination direction
Rp = abs(Cv-kv);
Rm = abs(Cv+kv);
OBJp = Aobj*(Rp.^Bobj);
OBJm = Aobj*(Rm.^Bobj);
k3 = round(kA);
OBJp(wo+1+k3(1),wo+1+k3(2)) = 0.25*OBJp(wo+2+k3(1),wo+1+k3(2))...
	+ 0.25*OBJp(wo+1+k3(1),wo+2+k3(2))...
	+ 0.25*OBJp(wo+0+k3(1),wo+1+k3(2))...
	+ 0.25*OBJp(wo+1+k3(1),wo+0+k3(2));
OBJm(wo+1-k3(1),wo+1-k3(2)) = 0.25*OBJm(wo+2-k3(1),wo+1-k3(2))...
	+ 0.25*OBJm(wo+1-k3(1),wo+2-k3(2))...
	+ 0.25*OBJm(wo+0-k3(1),wo+1-k3(2))...
	+ 0.25*OBJm(wo+1-k3(1),wo+0-k3(2));

% Filtering side lobes (off-center frequency components)
SFo = Mm;
if calibrate
    [fDpf,npDp] = WoFilterSideLobe(fDp,OTFo,co,OBJm,SFo);
    [fDmf,npDm] = WoFilterSideLobe(fDm,OTFo,co,OBJp,SFo);
    if nargout >= 9
    % Cache the actual pointwise Wiener multipliers before padding/shifting.
    fixedParams.Wo = cacheMultiplier(fDof,fDo);
    fixedParams.Wp = cacheMultiplier(fDpf,fDp);
    fixedParams.Wm = cacheMultiplier(fDmf,fDm);
    fixedParams.npDo = npDo;
    fixedParams.npDp = npDp;
    fixedParams.npDm = npDm;
    fixedParams.Mm = Mm;
    end
else
    fDpf = fDp .* fixedParams.Wp;
    fDmf = fDm .* fixedParams.Wm;
    npDp = fixedParams.npDp;
    npDm = fixedParams.npDm;
end

%% doubling Fourier domain size if necessary
DoubleMatSize = 0;
if ( 2*Kotf > wo )
	DoubleMatSize = 1; % 1 for doubling fourier domain size, 0 for keeping it unchanged
end
if ( DoubleMatSize>0 )
    t = 2*w;
    to = t/2;
    u = linspace(0,t-1,t);
    v = linspace(0,t-1,t);
    [U,V] = meshgrid(u,v);
    fDoTemp = zeros(2*w,2*w);
    fDpTemp = zeros(2*w,2*w);
    fDmTemp = zeros(2*w,2*w);
    OTFtemp = zeros(2*w,2*w);
    fDoTemp(wo+1:w+wo,wo+1:w+wo) = fDof;
    fDpTemp(wo+1:w+wo,wo+1:w+wo) = fDpf;
    fDmTemp(wo+1:w+wo,wo+1:w+wo) = fDmf;
    OTFtemp(wo+1:w+wo,wo+1:w+wo) = OTFo;
    clear fDof fDpf fDmf OTFo w wo x y X Y
    fDof = fDoTemp;
    fDpf = fDpTemp;
    fDmf = fDmTemp;
    OTFo = OTFtemp;
    clear fDoTemp fDpTemp fDmTemp OTFtemp
else
    t = w;
    to = t/2;
    u = linspace(0,t-1,t);
    v = linspace(0,t-1,t);
    [U,V] = meshgrid(u,v);
end

% Shifting the off-center frequency components to their correct location
fDp1 = fft2(ifft2(fDpf).*exp( +1i.*2*pi*(kA(2)/t.*(U-to) + kA(1)/t.*(V-to)) ));
fDm1 = fft2(ifft2(fDmf).*exp( -1i.*2*pi*(kA(2)/t.*(U-to) + kA(1)/t.*(V-to)) ));

%% Shift induced phase error correction
Cv = (U-to) + 1i*(V-to);
Ro = abs(Cv);
Rp = abs(Cv-kv);
k2 = sqrt(kA*kA');

% frequency range over which corrective phase is determined
Zmask = (Ro < 0.8*k2).*(Rp < 0.8*k2);

% corrective phase
if calibrate
    Angle0 = angle( sum(sum( fDof.*conj(fDp1).*Zmask )) );
    fixedParams.Angle0 = Angle0;
else
    Angle0 = fixedParams.Angle0;
end

% phase correction
fDp2 = exp(+1i*Angle0).*fDp1;
fDm2 = exp(-1i*Angle0).*fDm1;





end

function W = cacheMultiplier(filtered,raw)
% No inverse mixing model: retain each Wiener coefficient at its own bin.
% An exactly zero calibration bin cannot identify a multiplier; keep it zero.
    W = zeros(size(raw),'like',filtered);
    valid = raw ~= 0;
    W(valid) = filtered(valid)./raw(valid);
    assert(all(isfinite(W(:))), 'Nonfinite cached Wiener coefficient.');
    assert(all(abs(filtered(~valid)) <= eps), ...
        'Wiener helper is not pointwise: nonzero output at zero input.');
end
