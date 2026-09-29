function [S1aTnoisy, S2aTnoisy, S3aTnoisy, ...
    S1bTnoisy, S2bTnoisy, S3bTnoisy, ...
    S1cTnoisy, S2cTnoisy, S3cTnoisy, ...
    DIoTnoisy, DIoT, phaseErrors] = SIMimagesF(k2,...
    DIo,PSFo,OTFo,ModFac,NoiseLevel,UsePSF,phaseErrors)

% AIM: to generate raw sim images
% INPUT VARIABLES
%   k2: illumination frequency
%   DIo: specimen image
%   PSFo: system PSF
%   OTFo: system OTF
%   UsePSF: 1 (to blur SIM images by convloving with PSF)
%           0 (to blur SIM images by truncating its fourier content beyond OTF)
%   NoiseLevel: percentage noise level for generating gaussian noise
% OUTPUT VARIABLES
%   [S1aTnoisy S2aTnoisy S3aTnoisy
%    S1bTnoisy S2bTnoisy S3bTnoisy
%    S1cTnoisy S2cTnoisy S3cTnoisy]: nine raw sim images
%   DIoTnoisy: noisy wide field image
%   DIoT: noise-free wide field image

w = size(DIo,1);
wo = w/2;
x = linspace(0,w-1,w);
y = linspace(0,w-1,w);
[X,Y] = meshgrid(x,y);

%% illunination phase shifts along the three directions
beta=0;
p0Ao = 0*pi/3+beta;
p0Ap = 2*pi/3+beta;
p0Am = 4*pi/3+beta;
p0Bo = 0*pi/3+beta;
p0Bp = 2*pi/3+beta;
p0Bm = 4*pi/3+beta;
p0Co = 0*pi/3+beta;
p0Cp =2*pi/3+beta;
p0Cm = 4*pi/3+beta;

%% Illuminating patterns
alpha =0;
% orientation direction of illumination patterns
thetaA = 0*pi/3 + alpha;
thetaB = 1*pi/3 + alpha;
thetaC = 2*pi/3 + alpha;
% illumination frequency vectors
k2a = (k2/w).*[cos(thetaA) sin(thetaA)];
k2b = (k2/w).*[cos(thetaB) sin(thetaB)];
k2c = (k2/w).*[cos(thetaC) sin(thetaC)];
% -------------------------------------------------------
% mean illumination intensity
mA = 0.5;
mB = 0.5;
mC = 0.5;
% amplitude of illumination intensity above mean
aA = 0.5*ModFac;
aB = 0.5*ModFac;
aC = 0.5*ModFac;

% random phase shift errors
if nargin < 8 || isempty(phaseErrors)
    phaseErrors = 0.1*(0.5-rand(9,1))*pi/18;
else
    assert(isequal(size(phaseErrors),[9 1]) && all(isfinite(phaseErrors)), ...
        'phaseErrors must be a finite 9-by-1 vector.');
end
NN = phaseErrors;

% illunination phase shifts with random errors
psAo = p0Ao + NN(1,1);
psAp = p0Ap + NN(2,1);
psAm = p0Am + NN(3,1);
psBo = p0Bo + NN(4,1);
psBp = p0Bp + NN(5,1);
psBm = p0Bm + NN(6,1);
psCo = p0Co + NN(7,1);
psCp = p0Cp + NN(8,1);
psCm = p0Cm + NN(9,1);

% illunination patterns
sAo = mA + aA*cos(2*pi*(k2a(1,1).*(X-wo)+k2a(1,2).*(Y-wo))+psAo); % illuminated signal (0 phase)
sAp = mA + aA*cos(2*pi*(k2a(1,1).*(X-wo)+k2a(1,2).*(Y-wo))+psAp); % illuminated signal (+ phase)
sAm = mA + aA*cos(2*pi*(k2a(1,1).*(X-wo)+k2a(1,2).*(Y-wo))+psAm); % illuminated signal (- phase)
sBo = mB + aB*cos(2*pi*(k2b(1,1).*(X-wo)+k2b(1,2).*(Y-wo))+psBo); % illuminated signal (0 phase)
sBp = mB + aB*cos(2*pi*(k2b(1,1).*(X-wo)+k2b(1,2).*(Y-wo))+psBp); % illuminated signal (+ phase)
sBm = mB + aB*cos(2*pi*(k2b(1,1).*(X-wo)+k2b(1,2).*(Y-wo))+psBm); % illuminated signal (- phase)
sCo = mC + aC*cos(2*pi*(k2c(1,1).*(X-wo)+k2c(1,2).*(Y-wo))+psCo); % illuminated signal (0 phase)
sCp = mC + aC*cos(2*pi*(k2c(1,1).*(X-wo)+k2c(1,2).*(Y-wo))+psCp); % illuminated signal (+ phase)
sCm = mC + aC*cos(2*pi*(k2c(1,1).*(X-wo)+k2c(1,2).*(Y-wo))+psCm); % illuminated signal (- phase)

%% superposed Objects
s1a = DIo.*sAo; % superposed signal (0 phase)
s2a = DIo.*sAp; % superposed signal (+ phase)
s3a = DIo.*sAm; % superposed signal (- phase)
s1b = DIo.*sBo;
s2b = DIo.*sBp;
s3b = DIo.*sBm;
s1c = DIo.*sCo;
s2c = DIo.*sCp;
s3c = DIo.*sCm;
% outfocus =zeros(512,512); % selecting central 512x512 of image
% outfocuss = double( imread('53.tif'));
% Ipsf=Generate_PSF(32.5*10^-9,488*10^-9,1.4,32,100*10^-9);
% Ipsf=Ipsf./sum(Ipsf(:));
% % outfocuss=conv2(outfocuss,Ipsf2,'same');
% outfocuss=0.25*outfocuss./max(outfocuss(:));
% outfocus(193:192+128,193:192+128)=outfocuss;
% outfocuss1a=outfocus.*sAo;
% outfocuss1b=outfocus.*sAp;
% outfocuss1c=outfocus.*sAm;
% outfocuss2a=outfocus.*sBo;
% outfocuss2b=outfocus.*sBp;
% outfocuss2c=outfocus.*sBm;
% outfocuss3a=outfocus.*sCo;
% outfocuss3b=outfocus.*sBp;
% outfocuss3c=outfocus.*sBm;
% 
% outfocuss1a=conv2(outfocuss1a,Ipsf,'same');
% outfocuss1b=conv2(outfocuss1b,Ipsf,'same');
% outfocuss1c=conv2(outfocuss1c,Ipsf,'same');
% 
% outfocuss2a=conv2(outfocuss2a,Ipsf,'same');
% outfocuss2b=conv2(outfocuss2b,Ipsf,'same');
% outfocuss2c=conv2(outfocuss2c,Ipsf,'same');
% 
% outfocuss3a=conv2(outfocuss3a,Ipsf,'same');
% outfocuss3b=conv2(outfocuss3b,Ipsf,'same');
% outfocuss3c=conv2(outfocuss3c,Ipsf,'same');
%% superposed (noise-free) Images
PSFsum = sum(sum(PSFo));
if ( UsePSF == 1 )
    DIoT = conv2(DIo,PSFo,'same')./PSFsum;
    S1aT = conv2(s1a,PSFo,'same')./PSFsum;
    S2aT = conv2(s2a,PSFo,'same')./PSFsum;
    S3aT = conv2(s3a,PSFo,'same')./PSFsum;
    S1bT = conv2(s1b,PSFo,'same')./PSFsum;
    S2bT = conv2(s2b,PSFo,'same')./PSFsum;
    S3bT = conv2(s3b,PSFo,'same')./PSFsum;
    S1cT = conv2(s1c,PSFo,'same')./PSFsum;
    S2cT = conv2(s2c,PSFo,'same')./PSFsum;
    S3cT = conv2(s3c,PSFo,'same')./PSFsum;
else
    %     size(OTFo)
    DIoT = ifft2( fft2(DIo).*fftshift(OTFo) );
    S1aT = ifft2( fft2(s1a).*fftshift(OTFo) );
    S2aT = ifft2( fft2(s2a).*fftshift(OTFo) );
    S3aT = ifft2( fft2(s3a).*fftshift(OTFo) );
    S1bT = ifft2( fft2(s1b).*fftshift(OTFo) );
    S2bT = ifft2( fft2(s2b).*fftshift(OTFo) );
    S3bT = ifft2( fft2(s3b).*fftshift(OTFo) );
    S1cT = ifft2( fft2(s1c).*fftshift(OTFo) );
    S2cT = ifft2( fft2(s2c).*fftshift(OTFo) );
    S3cT = ifft2( fft2(s3c).*fftshift(OTFo) );
    
    DIoT = real(DIoT);
%     max(S1aT(:))
%     max(outfocuss1a(:))
%%%临时注释
    % S1aT = real(S1aT)+outfocuss1a;
    % S2aT = real(S2aT)+outfocuss2a;
    % S3aT = real(S3aT)+outfocuss3a;
    % S1bT = real(S1bT)+outfocuss1b;
    % S2bT = real(S2bT)+outfocuss2b;
    % S3bT = real(S3bT)+outfocuss3b;
    % S1cT = real(S1cT)+outfocuss1c;
    % S2cT = real(S2cT)+outfocuss2c;
    % S3cT = real(S3cT)+outfocuss3c;

    S1aT = real(S1aT);
    S2aT = real(S2aT);
    S3aT = real(S3aT);
    S1bT = real(S1bT);
    S2bT = real(S2bT);
    S3bT = real(S3bT);
    S1cT = real(S1cT);
    S2cT = real(S2cT);
    S3cT = real(S3cT);
end

%% Gaussian noise generation
aNoise = NoiseLevel/100; % corresponds to 10% noise
% SNR = 1/aNoise
% SNRdb = 20*log10(1/aNoise)
nDIoT = random('norm', 0, aNoise*std2(DIoT), w , w);
nS1aT = random('norm', 0, aNoise*std2(S1aT), w , w);
nS2aT = random('norm', 0, aNoise*std2(S2aT), w , w);
nS3aT = random('norm', 0, aNoise*std2(S3aT), w , w);
nS1bT = random('norm', 0, aNoise*std2(S2bT), w , w);
nS2bT = random('norm', 0, aNoise*std2(S2bT), w , w);
nS3bT = random('norm', 0, aNoise*std2(S2bT), w , w);
nS1cT = random('norm', 0, aNoise*std2(S3cT), w , w);
nS2cT = random('norm', 0, aNoise*std2(S3cT), w , w);
nS3cT = random('norm', 0, aNoise*std2(S3cT), w , w);
% no=max(nS1aT(:))
% no=mean(nS1aT(:))
% no=max(S1aT(:))
%% noise added raw SIM images
NoiseFrac = 1; %may be set to 0 to avoid noise addition

% 
% DIoT =imnoise(DIoT,'poisson');
% S1aT =imnoise(S1aT,'poisson');
% S2aT =imnoise(S2aT,'poisson');
% S3aT =imnoise(S3aT,'poisson');
% S1bT =imnoise(S1bT,'poisson');
% S2bT =imnoise(S2bT,'poisson');
% S3bT =imnoise(S3bT,'poisson');
% S1cT =imnoise(S1cT,'poisson');
% S2cT =imnoise(S2cT,'poisson');
% S3cT =imnoise(S3cT,'poisson');


DIoTnoisy = DIoT + NoiseFrac*nDIoT;
S1aTnoisy = S1aT + NoiseFrac*nS1aT;
S2aTnoisy = S2aT + NoiseFrac*nS2aT;
S3aTnoisy = S3aT + NoiseFrac*nS3aT;
S1bTnoisy = S1bT + NoiseFrac*nS1bT;
S2bTnoisy = S2bT + NoiseFrac*nS2bT;
S3bTnoisy = S3bT + NoiseFrac*nS3bT;
S1cTnoisy = S1cT + NoiseFrac*nS1cT;
S2cTnoisy = S2cT + NoiseFrac*nS2cT;
S3cTnoisy = S3cT + NoiseFrac*nS3cT;
