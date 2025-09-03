# EV-battery-and-range-plots.R
R program for plotting EV energy/mile at different speeds, and various related plots

#### V10 release : Fix bug with metric: if basicData is metric, Wh/km was incorrectly computed on raw measured energy data.
                   Add plots for route: Fallon to Ely NV.
#### V9 release 31-Oct-2024: Estimated drag and rolling coefs and used those for most plots (big change). Added plots showing how baseline power changes range.
#### V8 release 1-Oct-2024: Fix bugs in wind plots: incorrect vehicle speed, incorrect regen efficiency.
#### V7 release 29-Sep-2024: switch the .Rmd code file over to a pure .R code file, still run using RStudio. Changes to charging plots.
#### V6 release 28-Sep-2024: many changes including new plots, addition of energy efficiency, some bug fixes, reorganization to improve code.
#### V5 release 8-Aug-2024: fix missing linear and quadratic approximations in first plot.
#### V4 release 7-Aug-2024: added charge power and charge time plots; added additional y-axes on right side of some plots.

To run this code:

1. In GitHub, choose the Code dropdown and download the zip file for this project. Unzip it into a convenient directory.
2. Install the most recent version of the R application, which is used to execute R code, available freely from:
        https://cran.r-project.org/mirrors.html
        (pick a repository in your country, then find and download one for your system)
3. Then, install the free version of RStudio, available from:
        https://posit.co/download/rstudio-desktop/
        (scroll down the page and find and download the one your system)
4. Open file "EV-battery-and-range-plots.R" in RStudio by double-clicking its icon or right-clicking and choosing "RStudio".
5. Look near line 70 for variable RSOURCEPATH, and edit it to set it to the path to the includeFiles subdirectory inside the directory where you unzipped the files.
6. Look near line 106 for three variables, and edit it to set them to the desired values:
   B. Set plotToQuartz TRUE to plot to the built-in Quartz graphics device in addition to the normal plotting to a PDF file, if you wish to view the plots as you run through the code piece-by-piece (instead of just running all of it at once).
   C. Set metricInPlots TRUE to make plots using METRIC, FALSE for imperial units, or c(FALSE, TRUE) to make separate PDF files for both types of units.
   D. Set BWcolors TRUE to make COLORED plots, FALSE to for GRAYSCALE plots, or c(FALSE, TRUE) to make separate PDF files for both color and grayscale.
6. Run the code by selecting "Run All" from the Run drop-down menu. The first time it is run, it will install some R packages, but this should only occur one time once installed.
7. The directory where you unzipped the files should have new PDF files of plots.
8. Follow instructions in comments in the code to change it for a different EV. You must be able to measure or provide watt-hours/mile at different speeds.

Contact me by email at ted@tedtoal.net with questions, comments, suggests, bugs, etc.  Or do the usual git stuff and I'll try to watch for pull requests or issue reports.
