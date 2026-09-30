# HoloSIM

HoloSIM is a computational framework for label-free super-resolution
quantitative phase microscopy by combining holographic recording with
structured illumination microscopy (SIM).

## Principle

1. Holographic recording
2. Near-field transfer
3. SIM readout
4. Phase retrieval
5. Sparse reconstruction

## Examples

Examples for:
- Siemens-star simulation
- Two-point resolution simulation
- LSEC phantom simulation
- PSI reconstruction
- Off-axis reconstruction

## Main Scripts

| Script | Description |
|---|---|
| `HoloSIM_PSI_Siemens.m` | Siemens-star simulation and reconstruction using phase-shifting interferometry (PSI). |
| `HoloSIM_PSI_TwoPoint.m` | Two-point phase-resolution simulation using PSI. |
| `HoloSIM_PSI_LSEC.m` | Reconstruction of the simulated LSEC-like thin-phase phantom using PSI-based HoloSIM. |
| `HoloSIM_PSI_MultiPattern.m` | HoloSIM simulation using multiple structured illumination patterns. |
| `HoloSIM_OffAxis_Siemens.m` | Siemens-star reconstruction using the off-axis HoloSIM configuration. |
| `SparseHoloSIM_PSI_LSEC.m` | Sparse refinement of the PSI-based HoloSIM reconstruction for the LSEC-like phantom. |

## Requirements

The simulations and reconstruction algorithms were implemented in MATLAB.

Recommended environment:

- MATLAB

## Usage

1. Clone or download this repository.
2. Open MATLAB.
3. Add the repository and its subfolders to the MATLAB path

## Main Parameters

- Wavelength: 488 nm
- Detection NA: 1.2
- Simulation pixel size: 32.5 nm
- etc.

## Citation

If you use this code, please cite:

[Paper information will be added after publication.]

## License

See [LICENSE.txt](LICENSE.txt).

## Contact

For questions regarding the code, please open an issue in this repository.
