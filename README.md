# Germinal center (GC) Analysis
We use Fiji to identify distinct regions within the  Germinal center (GC) using follicular dendritic cell (FDC) markers: CD23 and CD35.
## Overview
Given an image with four channels, CD23, CD35, Dapi and T cells staining, and an ROI file marking the borders of the entire GC within the image, the macro does the following:
1. Generates an ROI for CD35 and CD23 staining within the fitting ellipse of the GC's ROI
2. DETECT T-CELLS and calculate the number of T cells and their density in CD35 and CD23 ROIs
3. Generate a histogram along the main diagonal of the GC on top of CD35 and CD23 channels
4. Also provide a histogram to the T cells' count along that diagonal


## Generate an ROI for CD35/CD23 
We first blur the CD35/CD23 channel using Fiji's "Gaussian Blur..." operation with sigma = 15. 
We then identify CD35/CD23 regions withing the GC to be the region with intensity threshold above 5000 for CD35 and above 4000 for CD23.
![smoothed cd35](https://github.com/WIS-MICC-CellObservatory/GC-Analysis-/assets/64706090/88fb0738-1763-448a-9a90-95f0c2bfb26f)
Left: CD35 channel. Right: The identified CD35 region within the GC that is contained within the fitting elipse of the user provided GC roi
## User Input
The user can 
![Sharon input](https://github.com/WIS-MICC-CellObservatory/GC-Analysis-/assets/64706090/cab4211d-5ff3-4c58-b9b4-bf331e3da73e)
