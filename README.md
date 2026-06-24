# Low-Light Image Enhancement via Homomorphic Filtering

**EE 152 Final Project**
Authors: Ditto Bhadra & Emilio Rivas

## Overview

Low-light images suffer from low brightness, poor contrast, uneven illumination, and amplified noise. This project implements a **homomorphic filtering** pipeline that models an image as the product of an illumination component and a reflectance component, and selectively suppresses illumination while boosting reflectance in the frequency domain.

The homomorphic method is benchmarked against two common baselines:
- **Histogram Equalization (+ median filtering)** to denoise the result
- **Gamma Correction**

Since low-light datasets (we use a subset of [ExDark](https://github.com/cs-chan/ExDark)) don't include bright ground-truth images, all comparisons use **no-reference image quality metrics**: NIQE, BRISQUE, Entropy, and Tenengrad.

## Repository Contents

| File | Purpose |
|---|---|
| `Final_project_152_main.m` | Driver script — loads images, runs all three enhancement methods, evaluates metrics, saves outputs/plots/CSVs |
| `homomorphic_enhance_.m` | Core homomorphic filtering algorithm (log → FFT → Butterworth-style filter → IFFT → exp → normalize) |
| `eval_metrics_.m` | Computes NIQE, BRISQUE, Entropy, and Tenengrad for a grayscale image, with graceful fallback to `NaN` if NIQE/BRISQUE are unavailable |
| `quick_plots_.m` | Generates a 2×4 figure comparing Original/Homomorphic/HistEq/Gamma images and their intensity histograms |
| `Ditto_Bhadra_and_Emilio_Rivas_EE_152_Final_Project_Report.pdf` | Full written report: background, method derivation, related work, parameter study, results, and conclusions |

## Method Summary

1. Convert image to floating point and take the log: `g = ln(f + ε)`
2. Compute the 2D FFT: `G = F{g}`
3. Apply a Butterworth-style homomorphic filter:

   ```
   H(u,v) = (γH − γL) · [1 / (1 + (D0 / D(u,v))^(2n))] + γL
   ```

   where `γL < 1` suppresses illumination, `γH > 1` boosts reflectance, `D(u,v)` is distance from the frequency center, `D0` is the cutoff, and `n` is the filter order.
4. Multiply: `S = H · G`
5. Inverse FFT, exponentiate, and normalize to `[0,1]`.

Best-performing parameters found in the report's parameter study:

| Parameter | Value |
|---|---|
| `gammaL` | 0.6 |
| `gammaH` | 0.5 |
| `D0` | 250 |
| `order (n)` | 1 |

> Note: the report's narrative says `γH > 1` "enhances reflectance," but the optimal value reported is `γH = 0.5`. Worth double-checking against your parameter sweep before presenting this number — it may be a typo for a value >1, or the sweep may genuinely have favored a lower setting for this dataset.

## Requirements

- **MATLAB** with the **Image Processing Toolbox** (provides `rgb2gray`, `histeq`, `imadjust`, `medfilt2`, `entropy`, `fspecial`/`imfilter`, and the no-reference quality metrics `niqe` and `brisque`)
- `niqe` requires MATLAB R2017a+; `brisque` requires R2018a+. If unavailable, `eval_metrics.m` will catch the error and return `NaN` for those fields instead of crashing.

## Setup

1. **Rename function files to match their function names.** MATLAB requires the filename to exactly match the function name inside it. The uploaded files have a trailing underscore that needs to be removed before running:

   | Current filename | Rename to |
   |---|---|
   | `eval_metrics_.m` | `eval_metrics.m` |
   | `homomorphic_enhance_.m` | `homomorphic_enhance.m` |
   | `quick_plots_.m` | `quick_plots.m` |

   Keep all files in the same folder (or on the MATLAB path).

2. **Update the input image path.** In `Final_project_152_main.m`, change:

   ```matlab
   inDir = "C:\Users\Milog\Downloads\ExDark\ExDark\People";
   ```

   to point at your local copy of the ExDark images you want to test.

3. Run the script:

   ```matlab
   Final_project_152_main
   ```

## Outputs

Running the main script creates a `results/` folder (relative to the script) containing:

- `*_homo.png`, `*_he_med.png`, `*_gamma.png` — enhanced images for each method, per input file
- `*_methods.png` — side-by-side comparison figure (images + histograms) for each input file
- `metrics_homomorphic.csv`, `metrics_histEq_med.csv`, `metrics_gamma.csv` — per-image NIQE/BRISQUE/Entropy/Tenengrad scores for each method
- Console printout of mean metrics across all images for each method

## Results Summary

| Method | NIQE ↓ | BRISQUE ↓ | Entropy ↑ | Tenengrad ↑ |
|---|---|---|---|---|
| Homomorphic | improved vs. original; competitive vs. baselines | moderate | high | strong |
| HistEq | significantly worse (high noise) | poor | very high | unstable |
| HistEq + Median | improved BRISQUE but reduced sharpness | good | moderate | low |
| Gamma | reasonable performance | moderate | high | lower than homomorphic |

**Takeaway:** Homomorphic filtering gave the best overall trade-off between brightness, noise suppression, and detail preservation. Histogram equalization boosted contrast aggressively but amplified noise; median filtering helped denoise at the cost of sharpness. Gamma correction was consistent but couldn't adapt to spatially varying illumination.

## Future Work

- Extend to multi-scale/Retinex-style filtering
- Improve color image handling (currently processes each RGB channel independently)
- Explore learning-based low-light enhancement for comparison

## References

- R. C. Gonzalez and R. E. Woods, *Digital Image Processing*, 4th ed., Pearson, 2018.
- D. J. Jobson, Z. U. Rahman, and G. A. Woodell, "A Multiscale Retinex for Bridging the Gap Between Color Images and the Human Observation of Scenes," *IEEE Transactions on Image Processing*, vol. 6, no. 7, 1997.
- A. Mittal et al., "Making a 'Completely Blind' Image Quality Analyzer," *IEEE Signal Processing Letters*, vol. 20, no. 3, 2013.
- ExDark Dataset — https://github.com/cs-chan/ExDark
