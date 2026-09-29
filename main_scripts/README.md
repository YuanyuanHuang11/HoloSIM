# Main Scripts

This folder contains the main MATLAB scripts used for the HoloSIM simulations and reconstructions.

Each script corresponds to a specific simulation, reconstruction configuration, or quantitative analysis used in the HoloSIM study.

## Main Scripts

| Script | Description |
|---|---|
| `HoloSIM_PSI_Siemens.m` | Siemens-star simulation and reconstruction using phase-shifting interferometry (PSI). |
| `HoloSIM_PSI_TwoPoint.m` | Two-point phase-resolution simulation using PSI. |
| `HoloSIM_PSI_LSEC.m` | Reconstruction of the simulated LSEC-like thin-phase phantom using PSI-based HoloSIM. |
| `HoloSIM_PSI_MultiPattern.m` | HoloSIM simulation using multiple structured illumination patterns. |
| `HoloSIM_OffAxis_Siemens.m` | Siemens-star reconstruction using the off-axis HoloSIM configuration. |
| `SparseHoloSIM_PSI_LSEC.m` | Sparse refinement of the PSI-based HoloSIM reconstruction for the LSEC-like phantom. |

## Usage

1. Open MATLAB.
2. Set the HoloSIM repository as the working directory.
3. Add the repository and its subfolders to the MATLAB path:

```matlab
addpath(genpath(pwd));
