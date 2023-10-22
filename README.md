# Germinal center (GC) Analysis
We use Fiji to identify distinct regions within the  Germinal center (GC) using follicular dendritic cell (FDC) markers: CD23 and CD35.
## Overview
Given an image with four channels, CD23, CD35, Dapi and T cells staining, and an ROI file marking the borders of the entire GC within the image, the macro does the following:
1. Generates a fitting ellipse for the GC's ROI
2. Generates an ROI for CD35 and CD23 staining within the ellipse
3. Draws a line along the main diagonal of the elipse
4. Generate a histogram of the line on top of CD35 and CD23 channels
5. DETECT T-CELLS and provide a histogram to their count along the GC diagonal
6. Calculate the number of T cells and their density in CD35 and CD23 ROIs
## Generate a fitting elipse

## User Input
The user can 
![Sharon input](https://github.com/WIS-MICC-CellObservatory/GC-Analysis-/assets/64706090/cab4211d-5ff3-4c58-b9b4-bf331e3da73e)
