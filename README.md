# EV-battery-and-range-plots
R program for plotting EV energy/mile at different speeds, and derived plots

#### V5 release 8-Aug-2024: fix missing linear and quadratic approximations in first plot.
#### V4 release 7-Aug-2024: added charge power and charge time plots; added additional y-axes on right side of some plots.

To run this code:

1. In GitHub, choose the Code dropdown and download the zip file for this project. Unzip it into a convenient directory.
2. Install the most recent version of the R application, which is used to execute R code, available from:
        https://cran.r-project.org/mirrors.html
        (pick a repository in your country, then find and download one for your system)
3. Then, install the free version of RStudio, available from:
        https://posit.co/download/rstudio-desktop/
        (scroll down the page and find and download the one your system)
4. Open file "EV-battery-and-range-plots.Rmd" by double-clicking its icon. It should open in RStudio.
5. Look near line 45 for three variables that are assigned, and edit them to the desired values:
   A. Set RSOURCEPATH to the directories leading to the includeFiles subdirectory inside the directory where you unzipped the files.
   B. Set useMetricInPlots TRUE to make plots using METRIC, FALSE for imperial units.
   C. Set useBWcolors TRUE to make COLORED plots, FALSE to for BLACK-AND-WHITE plots.
6. Run the code by selecting "Run All" from the Run drop-down menu. The first time it is run, it may install some R packages, but if so, this should only occur one time.
7. Scroll down through the .Rmd file to view the plots.
8. The directory where you unzipped the files should have new PDF files of plots.
9. Follow instructions in comments in the code to change it for a different EV. You must be able to measure or provide watt-hours/mile at different speeds.

Contact me by email at ted@tedtoal.net with questions, comments, suggests, bugs, etc.  Or do the usual git stuff and I'll try to watch for pull requests or issue reports.
