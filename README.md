# EV-battery-and-range-plots
R program for plotting EV energy/mile at different speeds, and derived plots

To run this code:

1. In GitHub, choose the Code dropdown and download the zip file for this project. Unzip it into a convenient directory.
2. Install the most recent version of the R application, which is used to execute R code, available from:
        https://cran.r-project.org/mirrors.html
        (pick a repository in your country, then find and download one for your system)
3. Then, install the free version of RStudio, available from:
        https://posit.co/download/rstudio-desktop/
        (scroll down the page and find and download the one your system)
4. Open file "EV-battery-and-range-plots.Rmd" by double-clicking its icon. It should open in RStudio.
5. Look near the top of the file for three variables that are assigned, and edit them to the desired values:
   A. Set the components of RSOURCEPATH to the directories giving the path to the includeFiles subdirectory inside the directory where you unzipped the files.
   B. Set useMetricInPlots TRUE to produce plots using METRIC units, FALSE for imperial units.
   C. Set useBWcolors TRUE to produce plots with COLORS, FALSE to produce black and white plots.
6. Run the code by selecting "Run All" from the Run drop-down menu. The first time it is run, it may install some R packages, but if so, this should only occur one time.
7. Scroll down through the file to view the plots. Check the directory where you unzipped the files for new PDF files containing plots.
8. Follow instructions in comments in the code to change it for a different EV. You must be able to measure watt-hours/mile at different speeds.
