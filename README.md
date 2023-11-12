# Germinal center (GC) Analysis
We use Fiji to identify distinct regions within the  Germinal center (GC) using follicular dendritic cell (FDC) markers: CD23 and CD35. We use Stardist to identify T cells there.
## Overview
Given an image with four channels, CD23, CD35, Dapi and T cells staining, and an ROI file marking the borders of the entire GC within the image, the macro does the following:
1. Generates an ROI for CD35 and CD23 staining within the fitting ellipse of the GC's ROI
2. Detect T-CELLS using Stardist
3. Generate a histogram along the main diagonal of the GC on top of CD35 and CD23 channels
## Generate an ROI for CD35/CD23 
We first blur the CD35/CD23 channel using Fiji's "Gaussian Blur..." operation with sigma = 15. 
We then identify CD35/CD23 regions withing the GC to be the region with intensity threshold above 5000 for CD35 and above 4000 for CD23.
![smoothed cd35](https://github.com/WIS-MICC-CellObservatory/GC-Analysis/assets/64706090/518b7bcf-cc2e-4d60-a0c9-a307213eec1b)
Left: CD35 channel. Right: The identified CD35 region within the GC that is contained within the fitting ellipse of the user provided GC’s ROI
## Detect T Cells using Stardist
To detect T cells we first run out-of-the-box Stardist on the T-cells Dapi's channel with the following parameters:
args=['input':'Dapi', 'modelChoice':'Versatile (fluorescent nuclei)', 'normalizeInput':'true', 'percentileBottom':'1.0', 'percentileTop':'99.8', 'probThresh':'0.5', 'nmsThresh':'0.4', 'outputType':'Both', 'nTiles':'1', 'excludeBoundary':'2', 'roiPosition':'Automatic', 'verbose':'false', 'showCsbdeepProgress':'false', 'showProbAndDist':'false'], process=[false]").
![Stardist](https://github.com/WIS-MICC-CellObservatory/GC-Analysis/assets/64706090/9a43ff42-bc8b-405b-9233-9c352e8eb609)
We then filter out identified nuclei with low mean intensity (lower than 3000), or non-regular size (smaller than 10 m^2 or bigger than 100 m^2)
## Generate histograms
To generate the histograms, we define a rectangle along the main diagonal of the GC's Fitting ellipse. The rectangular captures also regions before and after the GC as to capture the CD35/CD23 intensity there too.
![CD35 histogram](https://github.com/WIS-MICC-CellObservatory/GC-Analysis/assets/64706090/ea568070-a44f-4c3f-8b28-638da047b2f5)

The width of the rectangle is set to 20% of the GC fitting ellipse’s minor diagonal. The Length of the rectangular is set to include extra 20% of the GC fitting ellipse’s major diagonal residing before and after the GC region (around 0-100 m and 600-700 m in the image above).
