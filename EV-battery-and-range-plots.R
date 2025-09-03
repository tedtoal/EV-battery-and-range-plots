# "EV Battery and Range Plots"

# Plot results of tests of an EV's range, plus many plot variations.

# |:---------------------------------------------------------------------------|
# | Copyright (C) 2024-2025 Ted Toal                                                |
# | This program is free software: you can redistribute it and/or modify it    |
# | under the terms of the GNU General Public License as published by the Free |
# | Software Foundation, either version 3 of the License, or (at your option)  |
# | any later version.                                                         |
# | This program is distributed in the hope that it will be useful, but        |
# | WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY |
# | or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License    |
# | for more details.                                                          |
# | You should have received a copy of the GNU General Public License along    |
# | with this program. If not, see <https://www.gnu.org/licenses/>.            |
# | The author, Ted Toal, can be contacted via email at:                       |
# |     [ted\@tedtoal.net](mailto:ted@tedtoal.net){.email}                     |
# |:---------------------------------------------------------------------------|

# 1. This file is opened and run from the app named RStudio (or the R app if you
#   already have it installed and know how to use it). To install RStudio, first
#   install R, available for free from:
#   <https://cran.r-project.org/mirrors.html> (pick one in your country,
#   then find your system and latest version)

# 2. Then, install the free version of RStudio, available from:
#   <https://posit.co/download/rstudio-desktop/>
#   (scroll down the page and find your system)

# 3. Open this file (EV-battery-and-range-plots.R) in RStudio.

# 4. Look near line 70 for the variable RSOURCEPATH and edit its assignment:
#   A. Set RSOURCEPATH to the directory leading to the includeFiles subdirectory
#    inside the directory where you unzipped these files.

# 5. Then look near line 106 for three more variables and edit their assignments:
#   B. Set plotToQuartz TRUE to plot to the built-in Quartz graphics device in
#       addition to the normal plotting to a PDF file, if you wish to view the
#       plots as you run through the code piece-by-piece (instead of just running
#       all of it at once).
#   C. Set metricInPlots TRUE to make plots using METRIC, FALSE for imperial
#       units, or set to c(FALSE, TRUE) to produce separate PDF files of both.
#   D. Set BWcolors TRUE to make COLORED plots, FALSE to for GRAYSCALE plots, or
#       set to c(FALSE, TRUE) to produce separate PDF files of both.

# 6. Then run the code by selecting "Code", "Run Region", "Run All" in the menus
#   or by selecting and running all the code. The first time it is run, it should
#   install some R packages, but this should only occur one time and not on
#   subsequent runs as long as the packages remain installed.

# 7. After running this and getting no errors, the directory where you unzipped
#   the files should have new PDF files of plots.

# 8. Follow instructions in comments in the code to change it for a different EV.
#   You must be able to measure or provide watt-hours/mile at different speeds.

# THE CODE YOU NEED TO EDIT TO CONTROL THE OUTPUT COLORS AND UNITS (METRIC VERSUS
# IMPERIAL) AND TO CHANGE THE CAR DATA THAT IS PLOTTED ARE IN THE NEXT CODE CHUNKS
# AFTER THE FOLLOWING ONE, SO KEEP LOOKING BELOW!!!

# The first code chunk below contains "includes" of my standard include files.

################################################################################
# Release version number of this software, as documented in README.md.
################################################################################
VERSION = "V10"

################################################################################
# CHANGE THE VALUE OF RSOURCEPATH BELOW TO THE DIRECTORY WHERE THE DOWNLOADED
# INCLUDE FILES WERE PLACED ("includeFiles" subdirectory of your download
# directory) SO THE CODE CAN FIND AND INCLUDE THOSE FILES. Note that the "~"
# character at the start of the path means your user home directory.
################################################################################
RSOURCEPATH = file.path("~", "Documents", "Tesla", "EV-battery-and-range-plots", "includeFiles")

################################################################################
# Standard header code.
################################################################################
# Set hard-coded RSOURCEPATH environment variable to project root directory.
Sys.setenv(RSOURCEPATH=RSOURCEPATH)
# Use RSOURCEPATH paths as one source of directories for include files.
RSOURCEPATH = Sys.getenv("RSOURCEPATH")
if (RSOURCEPATH == "") stop("RSOURCEPATH environment variable is not defined")
# Get environment variable containing paths to R source code and find Include_HeaderCode.R
srcDirs = strsplit(RSOURCEPATH, ":", fixed=TRUE)[[1]]
hdrPaths = file.path(srcDirs, "Include_HeaderCode.R");
path_Include_HeaderCode_R = hdrPaths[file.exists(hdrPaths)][1]
if (is.na(path_Include_HeaderCode_R))
    stop("Include_HeaderCode.R not found in:\n", paste(srcDirs, collapse=":"))
# Include it and RootRsourceFile.R
cat("Including Include_HeaderCode.R from: ", path_Include_HeaderCode_R, "\n")
source(path_Include_HeaderCode_R)
cat("Including Include_RootRsourceFile.R from: ", path_Include_RootRsourceFile_R, "\n")
source(path_Include_RootRsourceFile_R)

################################################################################
# Include other R source code files.
################################################################################
includeFile("Include_UtilityFunctions.R")
includeFile("Include_TextFunctions.R")
includeFile("Include_PlotFunctions.R")

################################################################################
# SET THE FOLLOWING VALUES IN ORDER TO CONTROL THE OUTPUT UNITS AND COLORS!!!
################################################################################

# Set this TRUE to plot to the built-in Quartz device after the plotting function
# for each plot is defined (used if you are debugging and going through the code
# line-by-line).
plotToQuartz = FALSE

# Set this TRUE to produce range/energy plots, FALSE if not.
rangeEnergyPlots = TRUE

# Set this TRUE to produce range-only plots, FALSE if not.
rangeOnlyPlots = TRUE

# Set this TRUE to produce plots using METRIC units, FALSE for imperial units.
# Use c(FALSE, TRUE) to produce BOTH types of plots (in separate PDF files).
metricInPlots = c(FALSE, TRUE)

# Set this TRUE to produce plots with COLORS, FALSE to produce GRAYSCALE plots.
# Use c(FALSE, TRUE) to produce plots using BOTH COLOR AND GRAYSCALE plots (in
# separate PDF files).
BWcolors = c(FALSE, TRUE)

################################################################################
# The rest of this file is run possibly up to four times, using each combination
# of values set for metricInPlots and BWcolors. Each time through this very
# large loop, one PDF file is produced. Each PDF file has a unique name that
# tells whether it is metric or imperial and whether it is in color or grayscale.
################################################################################

for (useMetricInPlots in metricInPlots)
{
for (useBWcolors in BWcolors)
{

################################################################################
# Below is defined the results of measurements that must be made on the vehicle,
# plus vehicle-related data and other things such as the directory and filename
# to be used for PDF file output.
#
# To change this code to a different vehicle, edit the values below and make
# changes as needed. IF ANY VALUE IS ADDED WHOSE UNITS DIFFER BETWEEN IMPERIAL
# AND METRIC UNITS, YOU MUST ADD CODE TO CONVERT THE VALUE. TO DO THIS, SEARCH
# FOR "Convert basicData" to find the code section that does the conversion.
################################################################################

# Below, a list named basicData is defined, containing most of the constants that require changes to plot data for
# a different electric vehicle.

# Set basicDataUnits_metric TRUE if data in basicData and elsewhere is metric and FALSE if imperial. This applies
# to all data in this file including that within basicData, unless comments associated with some variable explicitly
# state otherwise. Note that this value is independent of the setting of useMetricInPlots, i.e. plotting could be
# done in metric while basicData is in imperial units, or vice-versa.
basicDataUnits_metric = FALSE

# Now define list basicData. The first part of it contains measured energy use per unit distance, upon which most of
# the plots created by this program derive in some manner.
basicData = list(
    # Program version.
    version=VERSION,

    # Measured (and estimated, for isEstimate_dir1, isEstimate_dir2, and addForApproximation) energy use per distance at
    # different speeds in both directions on the some road. For units, see basicData_metric and the unitsTable table below.
    # My testing: north and south for several miles each direction on Hwy 84 SSW of Sacramento CA near the deep water channel.
    # Variables are:
    #   addForApproximationNote: string describing why extra data points were added using addForApproximation, if any.
    #   addForApproximation: use F (FALSE) for ALL MEASURED VALUES AT THAT SPEED and use T (TRUE) for any value you want
    #       to ADD to the measured data for use ONLY in the 3rd-order power approximation, because you believe the added
    #       points are good estimates that will improve the approximations.
    #       I added one point: a Tesla FB group comment said he got 400 mi range at 7 mph during hurricane evacuation.
    #       I estimated this was around 160 Wh/mi.
    #   speed: the speeds at which the measurements were taken.
    #   WhPerDist_dir1: measured Wh/unit distance at each speed, in the first direction on the road.
    #   WhPerDist_dir2: same but for the opposite direction on the road.
    #   isEstimate_dir1: use F (FALSE) for all MEASURED WhPerDist_dir1 values and use T (TRUE) for any value you are
    #       estimating, either because you didn't measure the value or because you believe that what you measured was
    #       wrong for some reason. For my data, the dir1 Wh/dist at speed 30, it seemed that something had happened
    #       and the value I had written down (135) was incorrect. (I had a hard time measuring Wh on the Tesla energy app,
    #       estimating the average value of the curve over a couple miles.) I was tempted to change the number to 155 or
    #       more, but in the end I left it as I measured it.
    #   isEstimate_dir2: same as isEstimate_dir1 except for WhPerDist_dir2 values.
    #   isEstimate_note: string describing why data points were estimated in WhPerDist_dir1 or WhPerDist_dir2, if any.
    addForApproximationNote= "Tesla FB group comment: 400 mi range at 7 mph during evacuation",
    addForApproximation=c(   T,   F,   F,   F,   F,   F,   F,   F,   F,   F,   F,   F,   F),
    speed=              c(   7,  25,  30,  35,  40,  45,  50,  55,  60,  65,  70,  75,  80),
    WhPerDist_dir1=     c( 160, 160, 135, 180, 190, 200, 215, 230, 265, 280, 310, 355, 375), # Same dist units as speed
    WhPerDist_dir2=     c( 160, 140, 145, 150, 175, 175, 205, 200, 215, 230, 255, 295, 315), # Same dist units as speed
    isEstimate_dir1=    c(   F,   F,   F,   F,   F,   F,   F,   F,   F,   F,   F,   F,   F),
    isEstimate_dir2=    c(   F,   F,   F,   F,   F,   F,   F,   F,   F,   F,   F,   F,   F),
    isEstimate_note= "",

    # Remaining variables describe the vehicle, test conditions, and other things.
    # Vehicle general description.
    description="2018 Tesla Model 3 LR RWD",
    # Output PDF directory.
    pdfDirectory=file.path("~", "Documents", "Tesla", "EV-battery-and-range-plots"),
    # Output PDF filename for all plots, excluding .pdf.
    pdfAllPlotsFilename="Model3_RangeAndEnergyPlots",
    # Output PDF filename for subset of plots, excluding .pdf.
    pdfSomePlotsFilename="Model3_Range_Plots",
    # Path of .csv file containing a chosen route to be profiled, with a header
    # listing the column names, which must include the columns longitude,
    # latitude, and elevation_m with the first two in decimal degrees and with
    # elevation_m in meters. Other columns are ignored.
    aRoute_csv=file.path("~", "Documents", "Tesla", "EV-battery-and-range-plots",
        "Highway 50, Fallon to Ely, NV.csv"),
    # Description of chosen route to be profiled.
    aRoute_desc="Highway 50, Fallon to Ely, NV",
    # Labels to be plotted along the chosen route to be profiled. This is a list,
    # one element for each label, with each element a sub-list with three
    # elements:
    #   label: the label to plot
    #   dist: distance along the route at which to plot the label
    #   adj: 2-element vector, adj argument to text(), giving label alignment
    #
    aRoute_labels = list(
        list(label="Fallon", dist=0, adj=c(0.5, 1.5)),
        list(label="Salt Wells", dist=14, adj=c(0.5, -0.5)),
        list(label="Jct 839", dist=32, adj=c(0.01, -0.8)),
        list(label="Middlegate\nJct 361", dist=47, adj=c(0, 1.1)),
        list(label="Jct 722", dist=50, adj=c(-0.1, 0.5)),
        list(label="Cold Spgs Stn", dist=53, adj=c(-0.05, 0.5)),
        list(label="Jct 305", dist=109, adj=c(0, 1)),
        list(label="Austin", dist=111, adj=c(1.1, 0)),
        list(label="Jct Grass Vly Rd", dist=116, adj=c(0.03, -1.7)),
        list(label="Jct 376", dist=122, adj=c(1, 1.2)),
        list(label="Petroglyphs", dist=135, adj=c(0.5, -1.1)),
        list(label="Jct 278", dist=177, adj=c(0.5, 1.5)),
        list(label="Eureka", dist=180, adj=c(1.1, 0)),
        list(label="Jct 379", dist=190, adj=c(-0.1, 0)),
        list(label="Jct 892", dist=195, adj=c(0.5, 1.2)),
        list(label="Rd 3", dist=226, adj=c(1, 1.2)),
        list(label="Rd 17", dist=237, adj=c(0, 1.3)),
        list(label="Robinson\nSummit", dist=240, adj=c(1.05, 0)),
        list(label="Egan Crest Trail", dist=249, adj=c(0, -0.3)),
        list(label="Rd 44A", dist=255, adj=c(-0.05, -0.1)),
        list(label="Ely", dist=258, adj=c(1, 1.3))
        ),
    # Temperature at which power consumption was measured.
    # This is an estimate, I forgot to record it, but it should be pretty close.
    temperature=85,
    # Elevation at which power consumption was measured.
    elevation=0,
    # Barometric pressure at which power consumption was measured, adjusted to sea-level (NOT barometer AT sea level).
    # This is an estimate, I forgot to record it, but it should be pretty close.
    barometer=29.92,
    # Wind speed at which power consumption was measured, should be 0.
    wind=0,
    # Rated capacity of battery in EV under test, in kWh.
    batteryRatedCapacity_kWh=75,
    # Health (100% - degradation) of battery in EV under test, in percent.
    batteryHealth_pct=88,
    # Description of how battery health number was obtained.
    batteryHealthDesc="Ran Tesla battery test in hidden service menu.",
    # Vehicle empty weight.
    vehicleEmptyWeight=4000, # Google says 3838 to 4072 lbs
    # Vehicle load such as passengers, used during testing.
    passengerWeight=250, # assume one passenger
    # Estimated efficiency of combined battery, inverter, motor, and drivetrain, in percent.
    # Some research on internet shows that although this changes SOME with power output, that
    # is a small effect that we can ignore. From a You-Tuber who attempted to measure efficiency,
    # I'm coming up with 70% as a reasonable figure. See Are Teslas Really That Efficient? on the
    # "Engineering Explained" You Tube channel.
    energyEfficiency_pct=70,
    # Regen braking efficiency, in percent, from average value obtained from internet searches.
    # It seems reasonable to assume that the efficiency of putting out energy, above, is about
    # equal to the efficiency of recapturing energy (below).
    regenEfficiency_pct=70,
    # Vehicle frontal area in m^2.
    frontalArea_sq_m=2.22,
    # Vehicle coefficient of drag, dimensionless. Searches on internet say 0.23 for Tesla Model 3.
    # This number is not currently used in computations, and instead the coefficient of drag is estimated
    # from the measured data. This number is printed out along with the estimate for comparison purposes
    # only.
    coefDrag=0.23,
    # Vehicle coefficient of rolling resistance, dimensionless. The horizontal friction force resisting
    # rolling is equal to this coefficient times the vehicle weight. Here is a table of typical values
    # obtained from https://www.researchgate.net/publication/351973711_Forward-Looking_Model_Dedicated_
    # to_the_Study_of_Electric_Vehicle_Range_Considering_Drive_Cycles/figures?lo=1
    #   Real-world roads                                                Rolling resistance coefficient
    #   low resistance tubeless tires                                   0.002 - 0.005
    #   truck tire on asphalt                                           0.006 - 0.01
    #   ordinary car tires on concrete, new asphalt, cobbles small new  0.01 - 0.015
    #   car tires on tar or asphalt                                     0.02
    #   car tires on gravel - rolled new                                0.02
    #   car tires on cobbles - large worn                               0.03
    #   car tires on solid sand, gravel loose worn, soil medium hard    0.04 - 0.08
    #   car tires on loose sand                                         0.2 - 0.4
    # Note that it is possible Tesla Model 3 tires are low resistance tires.
    # Here I've chosen a value for coefRolling is commonly found on the internet.
    # This number is not currently used in computations, and instead the coefficient of rolling resistance
    # is estimated from the measured data. This number is printed out along with the estimate for comparison
    # purposes only.
    coefRolling=0.01,
    # Average price paid (on the road) for electricity. Price per kWh varies dramatically at superchargers.
    # Units are currency units per kWh, see table below for currency units.
    # In U.S. price is generally between $.30 and $.40, leaning towards high end.
    avgElecCostPer_kWh=0.37,
    # Average fuel price, in units of units of currency per unit fuel volume, see table below for units.
    # Gasoline in California has been around $5/gallon for quite a while.
    avgFuelCostPerUnitFuel=5.00,
    # Distance at which to compare energy cost at different speeds for electric vs gas vehicles. Used this way
    # without conversion between imperial/metric, i.e. use 100 mi or 100 km
    compareEnergyCost_Dist=100,
    # Number of hours to use to compare energy cost at different speeds for electric vs gas vehicles.
    compareEnergyCost_Hours=1.0,
    # Charge curve description.
    chargeCurveDescription="Data is for maximum charge rate curve for Tesla Model 3 with 75 kWh battery, no degradation",
    # Charge curve citation.
    chargeCurveCitation="(from https://evkx.net/models/tesla/model_3/model_3_long_range/chargingcurve)"
    )

# Set fuelUseMetric TRUE if the values in the following fuelUsageEff variable are metric, FALSE if imperial. Speed
# is in units of km/h or mph, respectively, and fuel efficiency is in units of km/l or mpg respectively.
fuelUseMetric = FALSE

# The fuelUsageEff variable is a list of data that describes a model for the fuel efficiency of a gasoline-powered
# car at different speeds. It is used in plots comparing energy use of gasoline-powered cars and EVs. This list
# has two vectors, which together define a piecewise-linear curve of fuel efficiency vs speed, which is used to
# choose the fuel efficiency at each speed when needed for plots comparing gasoline vehicles to EVs. The first
# vector is speedBreakpoints, which contains the speeds at which the piecewise-linear curve changes slope, with
# the first speed being 0 and the last one being at least max_fineSpeed (defined somewhere below). The second
# vector is fuelEffBreakpoints, which is the same length as speedBreakpoints and contains the fuel efficiency
# at each of the corresponding speeds in speedBreakpoints. The units for speed and fuel efficiency are those
# specified by the setting of fuelUseMetric above.
# The data here was obtained by approximating two speed vs. miles-per-gallon plots obtained from www.mpgforspeed.com.
fuelUsageEff = list(speedBreakpoints=c(0, 5, 25, 55, 120), fuelEffBreakpoints=c(0, 12, 28, 30, 12))

################################################################################
# Charge curve for battery. This is for a Tesla Model 3 with 75 kWh battery,
# obtained from:
#   https://evkx.net/models/tesla/model_3/model_3_long_range/chargingcurve/
# Each set of four numbers is a set of these four values:
#   (SOC percent, Power in kW, Seconds, Total Energy in kWh)
################################################################################
dfChargeCurve = as.data.frame(matrix(c(
    0, 100, 0,	0,          1, 103, 28, 0.8,        2, 108, 54, 1.5,        3, 108, 81, 2.2,        4, 108, 107, 3.0,
    5, 108, 133, 3.8,       6, 230, 150, 4.5,       7, 235, 162, 5.2,       8, 240, 174, 6.0,       9, 245, 186, 6.8,
    10, 249, 198, 7.5,      11, 249, 209, 8.2,      12, 249, 220, 9.0,      13, 249, 232, 9.8,      14, 249, 243, 10.5,
    15, 249, 255, 11.2,     16, 241, 266, 12.0,     17, 238, 278, 12.8,     18, 234, 290, 13.5,     19, 231, 302, 14.2,
    20, 228, 315, 15.0,     21, 224, 327, 15.8,     22, 219, 340, 16.5,     23, 215, 353, 17.2,     24, 208, 367, 18.0,
    25, 207, 380, 18.8,     26, 202, 394, 19.5,     27, 196, 409, 20.2,     28, 191, 423, 21.0,     29, 186, 438, 21.8,
    30, 184, 454, 22.5,     31, 179, 469, 23.2,     32, 175, 485, 24.0,     33, 169, 502, 24.8,     34, 165, 519, 25.5,
    35, 159, 537, 26.2,     36, 156, 555, 27.0,     37, 152, 573, 27.8,     38, 147, 592, 28.5,     39, 143, 612, 29.2,
    40, 140, 632, 30.0,     41, 135, 652, 30.8,     42, 130, 674, 31.5,     43, 125, 696, 32.2,     44, 121, 719, 33.0,
    45, 116, 743, 33.8,     46, 112, 768, 34.5,     47, 108, 794, 35.2,     48, 104, 821, 36.0,     49, 100, 849, 36.8,
    50, 96, 878, 37.5,      51, 92, 908, 38.2,      52, 89, 939, 39.0,      53, 87, 972, 39.8,      54, 85, 1005, 40.5,
    55, 84, 1038, 41.2,     56, 82, 1073, 42.0,     57, 80, 1108, 42.8,     58, 80, 1143, 43.5,     59, 79, 1179, 44.2,
    60, 78, 1215, 45.0,     61, 77, 1252, 45.8,     62, 75, 1289, 46.5,     63, 74, 1327, 47.2,     64, 73, 1366, 48.0,
    65, 71, 1405, 48.8,     66, 69, 1446, 49.5,     67, 67, 1488, 50.2,     68, 64, 1531, 51.0,     69, 64, 1576, 51.8,
    70, 62, 1621, 52.5,     71, 61, 1667, 53.2,     72, 59, 1714, 54.0,     73, 58, 1763, 54.8,     74, 57, 1812, 55.5,
    75, 55, 1863, 56.2,     76, 54, 1915, 57.0,     77, 52, 1969, 57.8,     78, 49, 2025, 58.5,     79, 47, 2084, 59.2,
    80, 45, 2146, 60.0,     81, 43, 2211, 60.8,     82, 42, 2278, 61.5,     83, 40, 2347, 62.2,     84, 39, 2419, 63.0,
    85, 37, 2494, 63.8,     86, 37, 2571, 64.5,     87, 35, 2649, 65.2,     88, 34, 2732, 66.0,     89, 32, 2818, 66.8,
    90, 30, 2910, 67.5,     91, 29, 3006, 68.2,     92, 28, 3106, 69.0,     93, 28, 3207, 69.8,     94, 27, 3311, 70.5,
    95, 26, 3418, 71.2,     96, 26, 3527, 72.0,     97, 25, 3639, 72.8,     98, 22, 3760, 73.5,     99, 18, 3902, 74.2,
    100, 13, 4085, 75.0),
    ncol=4, byrow=TRUE, dimnames=list(NULL, c("SOCpct", "Power", "Seconds", "TotalEnergy"))),
    stringsAsFactors=FALSE)
# Verify that the SOCpct is a simple rounding based on TotalEnergy and 75 kWh (our current battery rated capacity) battery.
# Note: We won't use the SOCpct column in this data, but instead will interpret 100% state-of-charge as representing the
# energy of the DEGRADED battery. We will assume that this charge curve can be scaled directly down to the degraded
# battery capacity.
if (any(dfChargeCurve$SOCpct != round(100*dfChargeCurve$TotalEnergy/basicData$batteryRatedCapacity_kWh)))
    stop("SOC percent not as expected")
# Verify that the maximum battery energy equals our current rated battery capacity.
if (max(dfChargeCurve$TotalEnergy) != basicData$batteryRatedCapacity_kWh)
    stop("Battery charge curve data is for a different battery rated capacity than the basic data table, this will be problematic")

################################################################################
# The imperial and metric units used are:
#   unit                    metric                          imperial
#   ----                    ------                          --------
#   distance                km                              mi
#   dist_long               kilometer                       mile
#   dist_long_plural        kilometers                      miles
#   time                    h                               hr
#   time_long               hour                            hour
#   time_long_plural        hours                           hours
#   speed                   km/h                            mph
#   speed_long              kilometers per hour             miles per  hour
#   power                   kW                              kW
#   power_long              kilowatts                       kilowatts
#   energy                  kWh                             kWh
#   energy_long             kilowatt-hours                  kilowatt-hours
#   energy_use              Wh/km                           Wh/mi   Note: this must use Wh and the same distance units as speed
#   energy_eff              km/kWh                          mi/kWh  Note: this must use kWh and the same distance units as speed
#   battery_pct             %batt                           %batt
#   battery_pct_long        percent battery                 percent battery
#   battery_use             %batt/km                        %batt/mi
#   battery_use_long        percent battery per kilometer   percent battery per mile
#   battery_eff             km/1% batt                      mi/1% batt
#   battery_pwr             %batt/h                         %batt/h
#   battery_pwr_long        percent battery per hour        percent battery per hour
#   temp                    °C                              °F
#   elev                    m                               ft
#   elev_long               meters                          feet
#   pres                    hPA                             inHg
#   weight                  kg                              lb
#   area                    sq. m.                          sq. m.
#   fuel_vol                liter                           gal
#   fuel_eff                km/l                            mpg     Note: this must be in the same distance units as speed
#   currency                €                               $
#   currency_long           euros                           dollars
#   dist_per_cost           km/€                            mi/$
#   dist_per_cost_long      kilometers per euro             miles per dollar
#   cost_per_dist           €/km                            $/mi
#   cost_per_dist_long      euros per kilometer             dollars per mile
#
# unitsTable contains strings to use for different units in the plot output, from the above table, based on the
# setting of useMetricInPlots (NOT on basicDataUnits_metric), so unitsTable is for units that are to appear in PLOTS
# and is NOT necessarily the units used in basicData. For those, see the above commented table, using the column
# associated with basicDataUnits_metric.
################################################################################
unitsTable = list(
    distance=ifelse(useMetricInPlots, "km", "mi"),
    dist_long=ifelse(useMetricInPlots, "kilometer", "mile"),
    dist_long_plural=ifelse(useMetricInPlots, "kilometers", "miles"),
    time=ifelse(useMetricInPlots, "h", "hr"),
    time_long="hour",
    time_long_plural="hours",
    speed=ifelse(useMetricInPlots, "km/h", "mph"),
    speed_long=ifelse(useMetricInPlots, "kilometers per hour", "miles per hour"),
    power="kW",
    power_long="kilowatts",
    energy="kWh",
    energy_long="kilowatt-hours",
    energy_use=ifelse(useMetricInPlots, "Wh/km", "Wh/mi"),
    energy_eff=ifelse(useMetricInPlots, "km/kWh", "mi/kWh"),
    battery_pct="%batt",
    battery_pct_long="percent battery",
    battery_use=ifelse(useMetricInPlots, "%batt/km", "%batt/mi"),
    battery_use_long=ifelse(useMetricInPlots, "percent battery per kilometer", "percent battery per mile"),
    battery_eff=ifelse(useMetricInPlots, "km/1% batt", "mi/1% batt"),
    battery_pwr="%batt/h",
    battery_pwr_long="percent battery per hour",
    temp=ifelse(useMetricInPlots, "°C", "°F"),
    elev=ifelse(useMetricInPlots, "m", "ft"),
    elev_long=ifelse(useMetricInPlots, "meters", "feet"),
    pres=ifelse(useMetricInPlots, "hPA", "inHg"),
    weight=ifelse(useMetricInPlots, "kg", "lb"),
    area="sq. m.",
    fuel_vol=ifelse(useMetricInPlots, "liter", "gal"),
    fuel_eff=ifelse(useMetricInPlots, "km/l", "mpg"),
    currency=ifelse(useMetricInPlots, "€", "$"),
    currency_long=ifelse(useMetricInPlots, "euros", "dollars"),
    dist_per_cost=ifelse(useMetricInPlots, "km/€", "mi/$"),
    dist_per_cost_long=ifelse(useMetricInPlots, "kilometers per euro", "miles per dollar"),
    cost_per_dist=ifelse(useMetricInPlots, "€/km", "$/mi"),
    cost_per_dist_long=ifelse(useMetricInPlots, "euros per kilometer", "dollars per mile"))

################################################################################
# List of strings that can be used in plots. The string name is used by the
# tprintf() function to access the string using so-called "~"-specifiers, see
# tprintf(). Note: these strings can THEMSELVES contain tilde-specifiers, see
# tprintf().
# Currently these are used for describing assumptions at the top of each plot.
# Caution: all names must be unique between here and basicData and unitsTable.
################################################################################
displayStrings=list(
    EVdesc="~description@",
    conditions="Testing: flat road, ~temperature@~temp@, elev ~elevation@ ~elev@, ~barometer@ ~pres@, wind ~wind@ ~speed@",
    battDeg="batt degraded ~batteryDegradation_pct@% for ~batteryCapacity_kWh@kWh capacity",
    SOC100="100% SOC is ~batteryCapacity_kWh@kWh",
    totalWeight="weight ~vehicleWeight@~weight@ (with ~passengerWeight@~weight@ passengers)",
    effFactor="~energyEfficiency_pct@% net energy efficiency upon increased load, ~energyEfficiency_pct@% regen energy recapture efficiency",
    posEffFactor="~energyEfficiency_pct@% net energy efficiency upon increased load",
    coefs="drag coef ~dragCoef@, roll coef ~rollingCoef@",
    basePower="base power ~baselinePower_kW@kW",
    areaFrontal="frontal area ~frontalArea_sq_m@~area@",
    airdens="air density computed using density altitude",
    rolling="rolling coefficient ~coefRolling@",
    electCost="electricity cost ~currency@~avgElecCostPer_kWh@/kWh (charging eff. excl.)",
    fuelCost="fuel cost ~currency@~avgFuelCostPerUnitFuel@/~fuel_vol@",
    fuelDistPerFuelVol="fuel efficiency as shown by dotted line with right-axis scale",
    compEnergyCostDist="~compareEnergyCost_Dist@ ~distance@",
    compEnergyCostHours=ifelse(basicData$compareEnergyCost_Hours == 1, "driving hour", "~compareEnergyCost_Hours@ driving hours"),
    none=""
    )

################################################################################
# List of the air conditions to use when making certain plots, and one of these
# conditions (named "testCond") is the air conditions that were present when the
# vehicle was tested to gather the basicData.
#
# Edit this list if you want to change the air conditions that are plotted, or
# change the values to be in the units specified by basicDataUnits_metric.
#
# The units used here MUST BE the same units used in the basicData table, as
# given by basicDataUnits_metric.
################################################################################

# Different air conditions at which to plot EV power and range (elevation, temperature, barometer adjusted to sea level),
# including a line color and a brief description for the plot legend. The inner list name is arbitrary except that one must
# be named "testCond" and its conditions must match the EV test conditions.
# Units here MUST MATCH units used for basicData (as given by basicDataUnits_metric).
elev = basicData$elevation
temperature = basicData$temperature
pres = basicData$barometer
airConditionsToPlot = list(
    testCond=list(elev=elev, temp=temperature, pres=pres, desc="Test Conditions", col="black"),
    hotDay=list(elev=0, temp=100, pres=29.92, desc="Hot Day", col=ifelse(useBWcolors, "gray70", "red")),
    freezingDay=list(elev=0, temp=0, pres=29.92, desc="Freezing Day", col=ifelse(useBWcolors, "gray25", "blue")),
    coolDay=list(elev=0, temp=50, pres=29.92, desc="Cool Day", col=ifelse(useBWcolors, "gray50", "skyblue")),
    highElev=list(elev=6000, temp=50, pres=29.92, desc="High Elevation", col=ifelse(useBWcolors, "gray80", "orange")),
    lowPres=list(elev=0, temp=50, pres=29.60, desc="Low Pressure", col=ifelse(useBWcolors, "gray40", "brown")),
    highPres=list(elev=0, temp=50, pres=30.20, desc="High Pressure", col=ifelse(useBWcolors, "gray85", "pink"))
    )

################################################################################
# List of devices on the car that consume power, and their minimum, maximum, and
# typical power consumption in watts.
#
# For devices that use very small amounts of power, less than a watt as far as
# can be determined, use 0, 0, 0 for the power. If the device uses only "a few
# watts", use 5 watts. For devices that are usually not in use, for the typical
# value assume they ARE in use.
#
# Edit this list if you want to add or remove devices or change the power usage.
#
# Each set of four values is of the form:
#   (Device name, minimum power, typical power, maximum power)
# The matrix is of type character, but the power columns are changed from
# character to integer in the data frame below.
################################################################################

dfPoweredDevices = as.data.frame(matrix(c(
    "Inverter", 0, 0, 0,
    "Bluetooth", 0, 0, 0,
    "Braking", 0, 0, 0,
    "Server communication", 0, 5, 5,
    "Battery mgmt system", 0, 5, 5,
    "Turn signals", 0, 10, 10,
    "Motor control", 5, 10, 20,
    "High beams", 0, 30, 30,
    "Cameras", 40, 50, 50,
    "One seat heater", 0, 57, 57,
    "One USB port", 0, 15, 65,
    "Steering", 0, 50, 100,
    "Computer", 57, 100, 100,
    "Steering wheel heater", 0, 95, 95,
    "Head and tail lights", 0, 100, 100,
    "Wipers", 0, 100, 100,
    "Power socket", 0, 15, 144,
    "Display screen", 200, 250, 250,
    "Sentry mode", 0, 250, 300,
    "Cabin fan", 0, 100, 500,
    "Sound", 0, 200, 960,
    "Heat pump", 0, 1000, 3000,
    "Resistive cabin heater", 0, 2000, 4000,
    "AC compressor", 0, 1000, 6000,
    "Battery conditioning", 0, 7500, 7500),
    ncol=4, byrow=TRUE, dimnames=list(NULL, c("name", "minPower", "typPower", "maxPower"))),
    stringsAsFactors=FALSE)

dfPoweredDevices$minPower = as.integer(dfPoweredDevices$minPower)
dfPoweredDevices$typPower = as.integer(dfPoweredDevices$typPower)
dfPoweredDevices$maxPower = as.integer(dfPoweredDevices$maxPower)

################################################################################
# Physical constants and one-line functions for manipulating physical values.
# It should not be necessary to change these.
################################################################################

# Temperature unit conversions.
degC_to_degF = function(Tc) round(9*Tc/5+32, 1)
degF_to_degC = function(Tf) round((Tf-32)*5/9, 1)
degC_to_degK = function(Tc) Tc+273.15
degK_to_degC = function(Tk) Tk-273.15

# Physical constants.

# Gravity acceleration at earth's surface.
gravAccel = 9.8 # m/s^2

# Molar mass of dry air.
M_dryAir = 0.0289652 # kg/mol

# Ideal gas constant.
Rgas = 8.31446 # J/mol-°K

# Specific gas constant for dry air.
Rspec = Rgas/M_dryAir # m^2/s^2-°K

# Conversion costants.
kmph_per_mph = 1.60934 # 1 mph is this many km/h
mps_per_mph = 0.447 # 1 mph is this many m/s
mps_per_kmph = mps_per_mph/kmph_per_mph
km_per_mi = kmph_per_mph # 1 mile is this many km
m_per_ft = 0.3048 # 1 foot is this many meters
hPa_per_inHg = 33.86389 # 1 inch Hg is this many hPa
kg_per_lb = 0.453592 # 1 pound mass is this many kg
N_per_lb = 4.44822 # 1 pound force is this many N
N_per_kg = N_per_lb/kg_per_lb # 1 kg mass produces this many N of force at earth's surface
J_per_kWh = 3600000 # this many Joules per kWh
l_per_gal = 3.78541 # 1 gallon is this many liters
kmpl_per_mpg = km_per_mi / l_per_gal # 1 mpg is this many km/l

# Standard atmospheric pressure and temperature.
pres_std_hPa = 1013.25 # hPa = 100 N/m^2
pres_std_inHg = 29.92 # inches of mercury (mercury expands with heat so this depends on temperature, but this is standard?)
Tc_std = 15 # °C
Tk_std = degC_to_degK(Tc_std)

# Sea level air density as a function of temperature, at standard pressure, from ideal gas law.
rho_Tc = function(Tc) round(100*pres_std_hPa*M_dryAir/Rgas/degC_to_degK(Tc), 4) # kg/m^3

# Sea level air density at standard temperature and pressure.
rho_std = rho_Tc(Tc_std)

# Temperature lapse rate with altitude.
tempLapse_degC_per_m = 0.0065 # °K/m = °C/m
tempLapse_degC_per_ft = tempLapse_degC_per_m * m_per_ft

# Altitude change corresponding to a 1°C temperature change, used in equation for density altitude.
# This is NOT the same as 1/tempLapse. Read up on density altitude.
altLapse_m_per_degC = Rspec / (gravAccel - Rspec*tempLapse_degC_per_m) # m/°K = m/°C
altLapse_ft_per_degC = altLapse_m_per_degC/m_per_ft

# Altitude change corresponding to a 1 inHg barometer change, used in equation for pressure altitude.
altLapse_ft_per_inHg = 914

################################################################################
# Constant definitions for plot colors and line styles. Change these if you wish.
################################################################################

# Choose colors on dist_per_cost graph page to give good black/white contrast when printed.
col_raw_data = "gray"
col_derived_data = "black"
col_est_data = ifelse(useBWcolors, "gray80", "red")
col_change_data = ifelse(useBWcolors, "gray50", "blue")
col_power_total = ifelse(useBWcolors, "gray50", "blue")
col_power_baseline = ifelse(useBWcolors, "gray55", "darkgreen")
col_power_rolling = "black"
col_power_drag = ifelse(useBWcolors, "gray90", "darkred")
col_range = "black"
col_speed = ifelse(useBWcolors, "gray50", "blue")
col_elect = ifelse(useBWcolors, "gray50", "blue")
col_fuel = ifelse(useBWcolors, "gray80", "red")
col_dist_per_fuel = ifelse(useBWcolors, "gray55", "darkgreen")
col_linear = ifelse(useBWcolors, "gray80", "red")
col_nonlinear = ifelse(useBWcolors, "gray55", "blue")
col_charge_time = ifelse(useBWcolors, "gray55", "blue")
col_charging_power = "black"
col_charge_batteryEnergy = ifelse(useBWcolors, "gray55", "blue")
col_grid = "darkgray"
col_warning = ifelse(useBWcolors, "gray80", "red")

# Line widths.
lwd_raw_data = 2
lwd_derived_data = 2
lwd_derived_data_many = 1
lwd_elect = 2
lwd_fuel = 2
lwd_dist_per_fuel = 2
lwd_linear = 1
lwd_nonlinear = 1
lwd_grid = 0.5

# Line styles.
lty_raw_data_bottom = "dashed"
lty_raw_data_top = "dotted"
lty_derived_data = "solid"
lty_power_total = "solid"
lty_power_drag = "twodash"
lty_power_rolling = "dashed"
lty_power_baseline = "dotted"
lty_dist = "solid"
lty_time = "dashed"
lty_dist_per_fuel = "dotted"
lty_linear = "dotdash"
lty_nonlinear = "twodash"
lty_grid = "solid"

# Point symbol.
pch_triangle = 17
pch_bullet = 20
pch_raw_data = pch_bullet
pch_derived_data = pch_bullet
pch_est_data = pch_triangle
pch_change_data = pch_est_data
pch_elect = pch_bullet

################################################################################
# Add to basicData some values derived from other values in basicData.
#
# No changes should be needed here, and probably no changes for the
# remainder of the file, although in some cases you may find that you want
# to tweak some things below, so read through the code.
################################################################################

# Total vehicle weight including load such as passengers.
basicData$vehicleWeight = basicData$vehicleEmptyWeight + basicData$passengerWeight

# Net battery capacity after subtracting degradation of battery, in kWh.
basicData$batteryCapacity_kWh = round(basicData$batteryRatedCapacity_kWh*basicData$batteryHealth_pct/100)

# Battery degradation in percent.
basicData$batteryDegradation_pct = 100 - basicData$batteryHealth_pct

################################################################################
# Make three new versions of the basicData list: one in imperial units, one in
# metric units, and one in the units being used for plotting.
################################################################################

# Convert basicData to imperial units. Round results so they will look good printed. Note that currency units are NOT
# converted, they are never needed in any form other than the units they are specified in within basicData.
basicData_imperial = basicData
if (basicDataUnits_metric)
    {
    basicData_imperial$speed = round(basicData$speed/kmph_per_mph)
    basicData_imperial$WhPerDist_dir1 = round(basicData$WhPerDist_dir1*km_per_mi)
    basicData_imperial$WhPerDist_dir2 = round(basicData$WhPerDist_dir2*km_per_mi)
    basicData_imperial$temperature = round(degC_to_degF(basicData$temperature))
    for (i in 1:length(basicData_imperial$aRoute_labels))
        basicData_imperial$aRoute_labels[[i]]$dist = round(basicData_imperial$aRoute_labels[[i]]$dist/km_per_mi)
    basicData_imperial$elevation = round(basicData$elevation/m_per_ft)
    basicData_imperial$barometer = round(basicData$barometer/hPa_per_inHg, 2)
    basicData_imperial$vehicleEmptyWeight = round(basicData$vehicleEmptyWeight/kg_per_lb)
    basicData_imperial$passengerWeight = round(basicData$passengerWeight/kg_per_lb)
    basicData_imperial$avgFuelCostPerUnitFuel = round(basicData$avgFuelCostPerUnitFuel*l_per_gal, 2)
    basicData_imperial$vehicleWeight = round(basicData$vehicleWeight/kg_per_lb)
    # No conversion of compareEnergyCost_Dist
    }

# Convert basicData to metric units. Round results so they will look good printed. Note that currency units are NOT
# converted, they are never needed in any form other than the units they are specified in within basicData.
basicData_metric = basicData
if (!basicDataUnits_metric)
    {
    basicData_metric$speed = round(basicData$speed*kmph_per_mph)
    basicData_metric$WhPerDist_dir1 = round(basicData$WhPerDist_dir1/km_per_mi)
    basicData_metric$WhPerDist_dir2 = round(basicData$WhPerDist_dir2/km_per_mi)
    basicData_metric$temperature = round(degF_to_degC(basicData$temperature))
    for (i in 1:length(basicData_metric$aRoute_labels))
        basicData_metric$aRoute_labels[[i]]$dist = round(basicData_metric$aRoute_labels[[i]]$dist*km_per_mi)
    basicData_metric$elevation = round(basicData$elevation*m_per_ft)
    basicData_metric$barometer = round(basicData$barometer*hPa_per_inHg)
    basicData_metric$vehicleEmptyWeight = round(basicData$vehicleEmptyWeight*kg_per_lb)
    basicData_metric$passengerWeight = round(basicData$passengerWeight*kg_per_lb)
    basicData_metric$avgFuelCostPerUnitFuel = round(basicData$avgFuelCostPerUnitFuel/l_per_gal, 2)
    basicData_metric$vehicleWeight = round(basicData$vehicleWeight*kg_per_lb)
    # No conversion of compareEnergyCost_Dist
    }

# Set basicData_plot to basicData in the units to be plotted as given by useMetricInPlots.
basicData_plot = basicData_imperial
if (useMetricInPlots)
    basicData_plot = basicData_metric

################################################################################
# Convert the values in the fuelUsageEff list from the units specified by
# fuelUseMetric to the units specified by useMetricInPlots. Then, a function is
# defined that uses the piecewise-linear curve defined in fuelUsageEff to
# generate gasoline vehicle fuel efficiency from speed.
################################################################################

# Convert fuelUsageEff list to the units specified by useMetricInPlots, storing result in fuelUseSpeed and fuelUseEff.
fuelUseSpeed = fuelUsageEff$speedBreakpoints
fuelUseEff = fuelUsageEff$fuelEffBreakpoints
if (fuelUseMetric && !useMetricInPlots)
    {
    fuelUseSpeed = round(fuelUseSpeed / kmph_per_mph)
    fuelUseEff = round(fuelUseEff / kmpl_per_mpg)
    }
if (!fuelUseMetric && useMetricInPlots)
    {
    fuelUseSpeed = round(fuelUseSpeed * kmph_per_mph)
    fuelUseEff = round(fuelUseEff * kmpl_per_mpg)
    }

# Convert speed to fuel efficiency for a gas vehicle, using the piecewise-linear curve defined in fuelUseSpeed and fuelUseEff.
# Round to 1 digit after decimal point. All units are as specified by useMetricInPlots.
Speed_to_fuelDistPerfuelVolUnit = function(Speed)
    {
    ii = findInterval(Speed, fuelUseSpeed, all.inside=TRUE)
    eff = round(fuelUseEff[ii]+(Speed-fuelUseSpeed[ii])*(fuelUseEff[ii+1]-fuelUseEff[ii])/(fuelUseSpeed[ii+1]-fuelUseSpeed[ii]), 2)
    return(eff)
    }

################################################################################
# Read a .csv file containing points along a route to be profiled into data
# frame dfRoute. Add dist_km column that gives distance from previous point,
# 0 at first point, computed using Pythagorean relation for 3D points given by
# the other three columns. Then add cumdist_km column that gives cumulative
# distance.
################################################################################

dfRoute = read.csv(basicData_plot$aRoute_csv, stringsAsFactors=FALSE)
N = nrow(dfRoute)
if (N < 2) stop("Route file has fewer than two points for the route")
needCols = c("latitude", "longitude", "elevation_m")
ind = (needCols %in% colnames(dfRoute))
if (!all(ind))
    stop("Route file is missing required column(s) ", paste(needCols[!ind], collapse=", "))
# To convert latitude degrees to km, multiply latitude by 111.32.
# To convert longitude degrees to km, multiply longitude by 111.32 x cos(latitude).
# We want to compute the km change in latitude, longitude, and elevation from
# point to point, which we do using diff() and the conversion from degrees to km.
delLat = diff(dfRoute$latitude)
delLong = diff(dfRoute$longitude)
delElev = diff(dfRoute$elevation_m)
meanLat = (dfRoute$latitude[1:(N-1)] + dfRoute$latitude[2:N])/2
lat_degTo_km = 111.32
long_degTo_km = lat_degTo_km*cos(meanLat*pi/180)
dfRoute$dist_km = 0
dfRoute$dist_km[2:N] = sqrt((delLat*lat_degTo_km)^2 + (delLong*long_degTo_km)^2 + (delElev/1000)^2)
dfRoute$cumdist_km = cumsum(dfRoute$dist_km)
rm(delLat, delLong, delElev, meanLat, lat_degTo_km, long_degTo_km)

################################################################################
# Convert the values in dfRoute columns elevation_m, dist_km, and cumdist_km
# from metric units to new columns elevation, delta_elev, dist, and cumdist in
# the units specified by useMetricInPlots.
################################################################################

dfRoute$elevation = dfRoute$elevation_m
dfRoute$delta_elev = c(0, diff(dfRoute$elevation))
dfRoute$dist = dfRoute$dist_km
dfRoute$cumdist = dfRoute$cumdist_km
if (!useMetricInPlots)
    {
    dfRoute$elevation = dfRoute$elevation_m / m_per_ft
    dfRoute$delta_elev = dfRoute$delta_elev / m_per_ft
    dfRoute$dist = dfRoute$dist_km / km_per_mi
    dfRoute$cumdist = dfRoute$cumdist_km / km_per_mi
    }

################################################################################
# Functions for various power, energy use and range computations. We just keep
# adding functions here as needed.
################################################################################

# Define a scale factor to go from kWh to battery percent (or, for example, from kWh/distance to battery percent/distance or
# from kWh/hour (same as kW) to battery percent/hour).
scale_kWh_to_BatteryPct = 100/basicData_plot$batteryCapacity_kWh

# Same as above except for use with Wh instead of kWh.
scale_Wh_to_BatteryPct = scale_kWh_to_BatteryPct/1000

# Convert Wh to battery percent (or Wh/distance to battery percent/distance, or Wh/hour (same as W) to battery percent/hour),
# rounded to 2 digits after decimal point. Wh can be a vector.
Wh_to_batteryPct = function(Wh) round(Wh*scale_Wh_to_BatteryPct, 2)

# Convert Wh/distance to distance/kWh, rounded to 2 digits after decimal point. WhPerDist can be a vector.
WhPerDist_to_DistPer_kWh = function(WhPerDist) round(1000/WhPerDist, 2)

# Convert speed and Wh/distance to power in kW, rounded to 2 digits after decimal point.
# Speed and WhPerDist can be same-sized vectors.
Speed_WhPerDist_to_kW = function(Speed, WhPerDist) round(Speed*WhPerDist/1000, 2)

# Convert speed and power in kW to Wh/distance, rounded to nearest integer.
# Speed and kW can be same-sized vectors.
Speed_kW_to_WhPerDist = function(Speed, kW) round(1000*kW/Speed)

# Convert kW and speed to battery percent/distance, rounded to 3 digits after decimal point.
# kW and Speed can be vectors.
kW_Speed_to_batteryPctPerDist = function(kW, Speed) round(scale_kWh_to_BatteryPct*kW/Speed, 3)

# Convert Wh/distance to range using degraded battery capacity, rounded to nearest integer.
# WhPerDist can be a vector.
WhPerDist_to_Range = function(WhPerDist) round(basicData_plot$batteryCapacity_kWh*1000/WhPerDist)

# Convert kW and speed to range, rounded to in integer.
# kW and Speed can be vectors.
kW_Speed_to_Range = function(kW, Speed) round(100*Speed/(kW*scale_kWh_to_BatteryPct))

# Define a scale factor to go from distance per battery 1% to range. This is 100 because if you
# can go X miles per 1% battery, you can go 100X miles per 100% battery and miles per 100%
# battery is the range by definition.
scale_DistPerBatteryPct_to_Range = 100

# Convert distance/battery percent to range. DistPerBatteryPct can be a vector.
DistPerBatteryPct_to_Range = function(DistPerBatteryPct) round(DistPerBatteryPct*scale_DistPerBatteryPct_to_Range)

# Define a scale factor to go from distance/kWh to range, rounded to nearest integer.
# This is simply the battery capacity in kWh.
scale_DistPer_kWh_to_Range = basicData_plot$batteryCapacity_kWh

# Convert distance/kWh to range, rounded to nearest integer. DistPer_kWh can be a vector.
DistPer_kWh_to_Range = function(DistPer_kWh) round(DistPer_kWh*scale_DistPer_kWh_to_Range)

# Convert Wh/distance to distance/currency unit, rounded to 2 digits after decimal point.
# WhPerDist can e a vector.
WhPerDist_to_ElecDistPerCurrencyUnit = function(WhPerDist) round(1000/(basicData_plot$avgElecCostPer_kWh*WhPerDist), 2)

# Convert speed to distance/currency unit for a gas vehicle, rounded to 2 digits after decimal point.
# Speed can be a vector. See assumptions for Speed_to_fuelDistPerfuelVolUnit().
Speed_to_FuelDistPerCurrencyUnit = function(Speed) round(Speed_to_fuelDistPerfuelVolUnit(Speed)/basicData_plot$avgFuelCostPerUnitFuel, 2)

# Convert Wh/distance to electricity cost/distance, rounded to 3 digits after decimal point.
# WhPerDist can be a vector. This is just the inverse of WhPerDist_to_ElecDistPerCurrencyUnit().
WhPerDist_to_ElectCostPerDist = function(WhPerDist) round(basicData_plot$avgElecCostPer_kWh*WhPerDist/1000, 3)

# Convert speed to fuel cost/distance, rounded to 3 digits after decimal point. This is just
# 1/Speed_to_FuelDistPerCurrencyUnit. See assumptions for Speed_to_fuelDistPerfuelVolUnit(). Speed can be a vector.
Speed_to_FuelCostPerDist = function(Speed) round(basicData_plot$avgFuelCostPerUnitFuel/Speed_to_fuelDistPerfuelVolUnit(Speed), 3)

# Convert Wh/distance and speed to electricity cost/time, rounded to 3 digits after decimal point.
# WhPerDist and Speed can be vectors.
WhPerDist_Speed_to_ElectCostPerTime = function(WhPerDist, Speed) round(WhPerDist_to_ElectCostPerDist(WhPerDist)*Speed, 3)

# Convert speed to fuel cost/time for a gas vehicle, rounded to 3 digits after decimal point. See assumptions for
# Speed_to_fuelDistPerfuelVolUnit(). Speed can be a vector.
Speed_to_FuelCostPerTime = function(Speed) round(Speed_to_FuelCostPerDist(Speed)*Speed, 3)

# Convert Wh/distance to electricity cost for a given distance, rounded to 2 digits after decimal point.
# WhPerDist can be a vector.
WhPerDist_to_ElectCostForDist = function(WhPerDist, distance=basicData_plot$compareEnergyCost_Dist)
    round(distance*WhPerDist_to_ElectCostPerDist(WhPerDist), 2)

# Convert speed to fuel cost for a given distance for a gas vehicle, rounded to 2 digits after decimal point. See
# assumptions for Speed_to_fuelDistPerfuelVolUnit(). Speed can be a vector.
Speed_to_FuelCostForDist = function(Speed, distance=basicData_plot$compareEnergyCost_Dist)
    round(distance*Speed_to_FuelCostPerDist(Speed), 2)

# Convert Wh/distance and speed to electricity cost for a given driving time, rounded to 2 digits after decimal point.
# WhPerDist and Speed can be vectors.
WhPerDist_Speed_to_ElectCostForTime = function(WhPerDist, Speed, time=basicData_plot$compareEnergyCost_Hours)
    round(time*WhPerDist_Speed_to_ElectCostPerTime(WhPerDist, Speed), 2)

# Compute Speed to fuel cost for a given driving time, rounded to 2 digits after decimal point. See assumptions for
# Speed_to_fuelDistPerfuelVolUnit(). Speed can be a vector.
Speed_to_FuelCostForTime = function(Speed, time=basicData_plot$compareEnergyCost_Hours) round(time*Speed_to_FuelCostPerTime(Speed), 2)

################################################################################
# Definitions related to air density.
################################################################################

# Pressure altitude (equivalent altitude at std temp/pres of a locale with given elevation and sea-level-adjusted barometer)
PAft_in_ft_inHg = function(elevation_ft, barometer_inHg)
                        round(elevation_ft + altLapse_ft_per_inHg*(pres_std_inHg-barometer_inHg))

# ISA temperature deviation as a function of pressure altitude. This would be the temperature that would be expected at some
# elevation because of altitude lapse rate if sea level pressure is standard pressure, all other things being equal.
tempISAdegC_in_PAft = function(presAltitude_ft) round(Tc_std - tempLapse_degC_per_ft*presAltitude_ft, 2)

# Density altitude (equivalent altitude at std temp/pres of a locale with given elevation, temperature, and
# sea-level-adjusted barometer)
DAft_in_ft_degF_inHg = function(elevation_ft, temp_degF, barometer_inHg, verbose=FALSE)
    {
    temp_degC = degF_to_degC(temp_degF)
    presAltitude_ft = PAft_in_ft_inHg(elevation_ft, barometer_inHg)
    if (verbose)
        cat("At", elevation_ft, "ft altitude with barometer", barometer_inHg, "inHg, pressure altitude is",
            presAltitude_ft, "feet\n")
    Tisa = tempISAdegC_in_PAft(presAltitude_ft)
    if (verbose)
        cat("At that pressure altitude, ISA temperature deviation is", Tisa, "°C\n")
    densAltitude_ft = round(presAltitude_ft + altLapse_ft_per_degC*(temp_degC - tempISAdegC_in_PAft(presAltitude_ft)))
    if (verbose)
        cat("And with those values and an outside temperature of", temp_degC, "°C, density altitude is",
            densAltitude_ft, "feet\n")
    return(densAltitude_ft)
    }

# Air density as a function of density altitude in feet, kg/m^3.
DAft_to_rhoMetric = function(densAltitude_ft) rho_std*(Tk_std-tempLapse_degC_per_ft*densAltitude_ft)/Tk_std

################################################################################
# Definitions for the tested vehicle, derived from basicData values.
################################################################################

# Density altitude and metric air density at the vehicle test conditions.
DA_ft_test = DAft_in_ft_degF_inHg(basicData_imperial$elevation, basicData_imperial$temperature, basicData_imperial$barometer)
rho_test = DAft_to_rhoMetric(DA_ft_test)

# Convert vehicle weight to newtons for use in several places later in the code.
vehicleWeight_N = basicData_metric$vehicleWeight * N_per_kg

# Convert energy efficiency and regen efficiency from percent into fraction.
fEnergyEfficiency = basicData_plot$energyEfficiency_pct/100
fRegenEfficiency = basicData_plot$regenEfficiency_pct/100

################################################################################
# Definitions related to rolling resistance.
################################################################################

# Compute the power required to overcome rolling resistance, given the speeds,
# coefficient of rolling resistance, vehicle weight in newtons, and vehicle
# energy efficiency. The returned power is in kW and it includes the additional
# energy required due to losses in energy conversion. The returned power is in
# kW and is rounded to 6 digits, which proved necessary to get a smooth curve
# for estimated speed at which maximum range occurs.
# Note: The speeds argument can be a vector of length > 1.
rollingPower_kW = function(speeds_plotUnits, coefRolling, weight_N, energyEff)
    {
    speeds_mps = speeds_plotUnits * ifelse(useMetricInPlots, mps_per_kmph, mps_per_mph)
    kW = round(coefRolling * weight_N * speeds_mps / energyEff / 1000, 6)
    return(kW)
    }

################################################################################
# Definitions related to drag.
################################################################################

# Compute the power required to overcome air drag, given the vehicle speed, air
# speed, coefficient of drag, air density, vehicle front area, vehicle energy
# efficiency, and vehicle regen efficiency. The returned power is in kW and it
# includes the additional energy required due to losses in energy conversion, or
# if airspeed is negative, the returned NEGATIVE power (power is generated, not
# consumed) is REDUCED by the energy regeneration efficiency. The returned power
# is in kW and is rounded to 6 digits, which proved necessary to get a smooth
# curve for estimated speed at which maximum range occurs.
# The speed arguments can be vectors of length > 1 as long as their lengths are
# equal.
dragPower_kW = function(vehicleSpeeds_plotUnits, airSpeeds_plotUnits, dragCoef,
    rho, frontalArea_sq_m, energyEff, regenEff)
    {
    cvt_mps = ifelse(useMetricInPlots, mps_per_kmph, mps_per_mph)
    vehicleSpeeds_mps = vehicleSpeeds_plotUnits * cvt_mps
    airSpeeds_mps = airSpeeds_plotUnits * cvt_mps
    # Drag force in Newtons at a given air speed, air density, frontal area, and
    # drag coefficient. When airspeed is negative, this isn't right because there
    # is going to be a different drag coefficient when the air hits the car from
    # behind. But I don't know that coefficient, so this will underestimate drag
    # force in that case. This computes a NEGATIVE force when airspeed is negative.
    dragForce_N = dragCoef * rho * frontalArea_sq_m * airSpeeds_mps^2 * sign(airSpeeds_mps) / 2
    # Get vector (possibly > 1) of conversion efficiency values to use.
    eff = myIfElse(airSpeeds_mps >= 0, 1/energyEff, regenEff)
    # Compute power required at vehicle speed to overcome the drag.
    kW = round(dragForce_N * vehicleSpeeds_mps * eff / 1000, 6)
    return(kW)
    }

################################################################################
# Definitions related to grade.
################################################################################

# Convert speed, flat road range, and road grade into range, all in current plot
# units, for the vehicle being tested. Subtract the range lost due to the power
# required to lift the vehicle up a grade from the flat-road range, given a speed.
# The arguments can be vectors of length > 1, but any that are > 1 must be the same
# length.
# Return the modified range(s). For negative grades (downhill), the range increases
# due to regen. A negative range means the battery charges to add additional range.
# Note that when grade = 0 the return value should equal flatRange but may be
# slightly different due to arithmetic precision limitations.
rangeAtGrade_TestVehicle_at_speeds_grades = function(speeds_plotUnits, flatRanges_plotUnits, grades)
    {
    # Convert to consistent units we need.
    speeds_mps = speeds_plotUnits * ifelse(useMetricInPlots, mps_per_kmph, mps_per_mph)
    speeds_m_per_hr = speeds_mps * 3600
    plotDistUnits_to_m = 1000 * ifelse(useMetricInPlots, 1, km_per_mi)
    flatRanges_m = flatRanges_plotUnits * plotDistUnits_to_m
    battCap_Wh = 1000*basicData_plot$batteryCapacity_kWh
    # Compute watts required to go these flat ranges at these speeds on a flat road.
    wattsFlatRoad = battCap_Wh * speeds_m_per_hr / flatRanges_m
    # Convert speeds and grades into speeds in the vertical direction. Approximate,
    # assumes small grades and hypotenuse about the same as x-distance.
    vertSpeeds = speeds_mps*grades/100
    # Convert a number of Newtons of force (the weight of the tested vehicle)
    # and vertical speeds to the number of watts out of (positive grade) or into
    # (negative grade) battery as a result of the power required to go up the
    # grade (positive grade) or the power recaptured going down the grade
    # (negative grade). If positive, car motor and powertrain efficiency is
    # factored in (more power required because of energy loss due to
    # inefficiency), and if negative, regen braking efficiency is factored in
    # (less power recaptured because of loss due to inefficiency).
    wattsLifting = vehicleWeight_N*vertSpeeds
    ind = (grades >= 0)
    wattsLifting[ind] = wattsLifting[ind] / fEnergyEfficiency
    wattsLifting[!ind] = wattsLifting[!ind] * fRegenEfficiency
    # Add the flat road and lifting power to get total power required.
    wattsTotal = wattsFlatRoad + wattsLifting
    # Compute the ranges.
    ranges_m = speeds_m_per_hr * battCap_Wh / wattsTotal
    ranges_plotUnits = ranges_m / plotDistUnits_to_m
    return(ranges_plotUnits)
    }

# Compute total route length, travel time at given speeds, and cumulative
# up/down and net elevation changes and required energy for chosen route.
# Return list with these elements:
#   routeLength: total route length in plot units
#   travelTime_h: total route travel time in hours for each speeds_plotUnits value
#   liftElev: cumulative positive change in elevation along route
#   dropElev: cumulative negative change in elevation along route (negative)
#   netElev: net change in elevation along the route (negative for drop)
#   lift_kWh: required energy to lift car by liftElev in kWh
#   drop_kWh: regen energy from dropping car by dropElev (negative) in kWh
#   net_kWh: net energy required to lift car by netElev (negative for drop) in kWh
#   lift_battPct: required energy to lift car by liftElev in battery percent
#   drop_battPct: regen energy from dropping car by dropElev (negative) in battery percent
#   net_battPct: net energy required to lift car by netElev (negative for drop) in battery percent
computeRouteLengthAndGradeData = function(speeds_plotUnits)
    {
    L = list()
    # Get the total route length and compute the time required to traverse the
    # entire route at each different speed, in hours.
    L$routeLength = round(dfRoute$cumdist[nrow(dfRoute)], 1)
    L$travelTime_h = setNames(round(L$routeLength / speeds_plotUnits, 2), as.character(speeds_plotUnits))

    # Compute the cumulative and net elevation changes along the route, and from
    # that, compute the energy required to lift or lower the vehicle by that
    # amount. The lift and lower energy must take into account the efficiency of
    # providing energy for lifting (fEnergyEfficiency) and for recapturing
    # energy from lowering (fRegenEfficiency).
    ind = (dfRoute$delta_elev >= 0)
    L$liftElev = round(sum(dfRoute$delta_elev[ind]))
    L$dropElev = round(sum(dfRoute$delta_elev[!ind]))
    L$netElev = L$liftElev + L$dropElev
    cvt_to_m = ifelse(useMetricInPlots, 1, m_per_ft)
    L$lift_kWh = round(L$liftElev * (cvt_to_m * vehicleWeight_N / fEnergyEfficiency / J_per_kWh), 1)
    # Note: lower_kwH is negative.
    L$drop_kWh = round(L$dropElev * (cvt_to_m * vehicleWeight_N * fRegenEfficiency / J_per_kWh), 1)
    L$net_kWh = L$lift_kWh + L$drop_kWh
    L$lift_battPct = round(L$lift_kWh * scale_kWh_to_BatteryPct, 1)
    L$drop_battPct = round(L$drop_kWh * scale_kWh_to_BatteryPct, 1)
    L$net_battPct = round(L$net_kWh * scale_kWh_to_BatteryPct, 1)
    return(L)
    }

################################################################################
# General-purpose function definitions.
################################################################################

# Similar to sprintf() except this interprets "~"-specifiers rather than "%"-specifiers. A "~"-specifier is of one of these
# forms:   ~WORD@  or  ~WORD`  or ~WORD^  or  ~~  or ~@  or  ~`  or  ~^
# where WORD is either the name of an element in one of these lists:
#   unitsTable
#   basicData_plot
#   displayStrings
#   coefEstimates
# Those lists are checked in the order above for WORD (it must be found in one of them or it is an error), and the corresponding
# string whose name is WORD is used to replace the "~"-specifier in the string.
# The character ending the specifier has the following effects:
#   @   the string is substituted as-is
#   `   the first character of the string is Capitalized for substitution
#   ^   the entire string is CAPITALIZED for substitution
# To insert any of the special "~"-specifier characters into the string, use a tilde preceding the character:
#   Use ~~ to insert ~
#   Use ~@ to insert @
#   Use ~` to insert `
#   Use ~^ to insert ^
# If and only if WORD is found in the displayStrings list, the replacement string is used in a recursive call to this function,
# which means that the displayStrings list may contain strings that themselves have "~"-specifiers in them.
#
# There are one or more arguments, each a character vector of one or more strings that are to undergo "~"-specifier replacement.
# Finally, ALL strings of all arguments are concatenated together and a single long string is returned.
#
# Note that any argument that is not of type character is coerced to type character using as.character() and then inserted into
# the return string without undergoing "~"-specifier replacement.
tprintf = function(...)
    {
    L = list(...)
    resS = ""
    for (i in 1:length(L))
        {
        # If the argument is not character type, just append it to the result.
        if (!is.character(L[[i]]))
            resS = paste0(resS, L[[i]], collapse="")
        else
            {
            # Else loop for each element of character vector L[[i]].
            for (S in L[[i]])
                {
                # If the string has no "~" characters, just append it to the result.
                if (!grepl("~", S, fixed=TRUE))
                    resS = paste0(resS, S)
                else
                    {
                    ch = strsplit(S, "")[[1]]
                    # The easiest way to do this is to just go through the characters one-by-one from the start.
                    out = c()
                    while (length(ch) > 0)
                        {
                        C = ch[1]
                        ch = ch[-1]
                        if (C != "~")
                            out = c(out, C)
                        else if (length(ch) == 0)
                            stop("tprintf expected each ~ character to be (eventually) followed by @, `, ^, or ~, but S is:\n", S)
                        else
                            {
                            C = ch[1]
                            ch = ch[-1]
                            if (C %in% c("~", "@", "`", "^"))
                                out = c(out, C)
                            else
                                {
                                word = c()
                                while (! (C %in% c("@", "`", "^")))
                                    {
                                    word = c(word, C)
                                    if (length(ch) == 0)
                                        stop("tprintf expected each ~WORD specifier to be followed by @, `, or ^,but S is:\n", S)
                                    C = ch[1]
                                    ch = ch[-1]
                                    }
                                # Got a ~WORD-specifier, search for WORD and substitute the string.
                                word = paste0(word, collapse="")
                                #cat0("word = ", word, "\n")
                                if (word %in% names(unitsTable))
                                    rplc = unitsTable[[word]]
                                else if (word %in% names(basicData_plot))
                                    rplc = as.character(basicData_plot[[word]])
                                else if (word %in% names(displayStrings))
                                    rplc = tprintf(displayStrings[[word]]) # Use recursive call.
                                else if (word %in% names(coefEstimates))
                                    rplc = as.character(coefEstimates[[word]])
                                else
                                    stop("tprintf doesn't find WORD '", word, "' in basicData_plot, displayStrings, unitsTable, or coefEstimates")
                                if (C == "^")
                                    rplc = toupper(rplc)
                                #cat0("rplc = ", rplc, "\n")
                                rplc = strsplit(rplc, "")[[1]]
                                if (C == "`")
                                    rplc[1] = toupper(rplc[1])
                                out = c(out, rplc)
                                }
                            }
                        }
                    resS = paste0(resS, paste(out, collapse=""))
                    }
                }
            }
        }
    return(resS)
    }

# Assemble a string composed of individual strings that are specified as arguments.
# Arguments:
#   ...         One or more character vectors or lists of length 1 or more, of strings to be assembled into one long string:
#               - Each character vector argument is first passed to tprintf() to replace "~"-specifiers in it and to
#                   concatenate the individual strings of the vector. This produces one string for each character vector
#                   argument.
#               - Those strings are then assembled into a single long string, with optional "bullet" strings preceding
#                   each one and an optional suffix string ("suffix" argument) following each one.
#               - If any one line within the output string grows longer than a specified width (lineWidth argument), a
#                   "\n" is inserted into the string to indicate the start of a new line. No line in final string is
#                   longer than lineWidth unless a single string is longer (because any one string resulting from
#                   tprintf() processing of one argument is never broken across lines with "\n").
#               - The argument strings can contain "\n" and "\t" characters. A "\n" becomes part of the output string
#                   and is recognized and starts a new line, resetting the line length counter for automatic insertion
#                   of "\n" when maximum line length is exceeded.
#               - A "\t" (tab) character causes spaces to be inserted to space over to the next column. The lineLength
#                   length is divided into the columns specified by an argument (colPcts), so tab characters space over
#                   to the start of the next column, or to the start of the next line if already in the last column of
#                   the line.
#   heading     A string that is inserted at the START of the assembled string. It can contain "\t" and "\n" characters.
#               Set it to "" if no heading string is desired.
#   bullets     A character vector containing the strings to use preceding each string from one argument. These
#               strings are used one-at-a-time in order, and if the end is reached, they are recycled again, and
#               therefore you can use a single string such as "* ". The default provides LETTERED strings such as
#               "A: <a string>".
#   suffix      A single character string added as a suffix to each string assembled from the arguments EXCEPT the last
#               argument. The default "\t" causes the next string to start in the next column. If columns are not used,
#               use something like "; " for this argument.
#   lineWidth   The desired maximum width of any one line, in inches. A "\n" character is inserted after an argument
#               string (concatenated vector) if otherwise the line length would exceed this, provided that there are
#               already characters on the line. If a line is empty, the next argument string is inserted into the line
#               even if it is longer than lineWidth.
#   colPcts     Vector of column starting point in percent of total width, in increasing order from 0% for first column
#               to <100% for the last column, for the purpose of spacing strings over when "\t" characters are encountered.
#               The number of columns is length(colPcts).
#   cex         Character expansion factor that will be used for plotting the string, used to measure string length.
#   font        Font that will be used for plotting the string, used to measure string length.
#   vfont       Vfont that will be used for plotting the string, used to measure string length.
#
# Returns: A single long string assembled by processing the argument strings as described above.
# Note: If any element of an argument vector or list is not of type character, it is converted using as.character().
makeStringList = function(..., heading="Assumptions: ", bullets=paste0(LETTERS, ": "), suffix="\t",
    lineWidth=6.5, colPcts=c(0,50), cex=NULL, font=NULL, vfont=NULL)
    {
    LA = list(...)
    nextBullet = 1
    Ncolumns = length(colPcts)
    cols = round(colPcts*lineWidth/100)
    res = list(S = "", len = 0)

    # Get the width of a thin space.
    thinSpace = " "
    spaceWidth = strwidth(thinSpace, "in", cex, font, vfont)

    # This function expands string S by processing "\t" and "\n" characters in it and then appending the result
    # to res$S.
    # Argument res is a list with elements:
    #   S (the string to which the expanded argument S is to be appended)
    #   len (the length of the current line in res$S as reported by strwidth())
    # The res list is returned with its elements updated after appending the expanded S string.
    expandTabs = function(res, S)
        {
        # Locate all '\t' and '\n' characters in S, then append substring between them to res$S, then process the "\t" or
        # "\n".
        pos = gregexpr("[\t\n]", S)[[1]]
        # Append -1 if first element is not -1 (= not found), we use -1 to mean end of all \t and \n reached.
        if (pos[1] != -1)
            pos = c(pos, -1)
        # Process S from starting position (Spos=1) to its end.
        Spos = 1
        for (p in pos)
            {
            # If next part of S starting at Spos is not \t or \n, append it to res$S.
            if (p == -1 || p > Spos)
                {
                last = ifelse(p == -1, 1000000L, p-1)
                sub = substring(S, Spos, last)
                Spos = p
                len = strwidth(sub, "in", cex, font, vfont)
                # If appending would overflow lineWidth and current line is not empty, start a new line.
                if (res$len > 0 && res$len+len > lineWidth)
                    {
                    res$S = paste0(res$S, "\n")
                    res$len = 0
                    }
                res$S = paste0(res$S, sub)
                res$len = res$len + len
                }
            # Either we are finished with S or \t or \n is next. Process \t or \n.
            if (Spos != -1)
                {
                ch = substring(S, Spos, Spos)
                Spos = Spos + 1
                # \n advances to next line, and we also do this with \t when we are already at or past the last column, or if there is only 1 column.
                if (ch == "\n" || Ncolumns == 1 || res$len >= cols[Ncolumns])
                    {
                    res$S = paste0(res$S, "\n")
                    res$len = 0
                    }
                else
                    {
                    # Otherwise, \t advances to start of next column.
                    for (i in Ncolumns:1)
                        if (res$len >= cols[i])
                            break
                    lineLenNextCol = cols[i+1]
                    Nspaces = round((lineLenNextCol - res$len) / spaceWidth)
                    res$S = paste0(res$S, paste0(rep(thinSpace, Nspaces), collapse=""))
                    res$len = res$len + Nspaces * spaceWidth
                    }
                }
            }
        return(res)
        }

    # First append the heading to res$S.
    res = expandTabs(res, heading)

    # Loop for each argument, process it with tprintf, and append it to res$S.
    for (i in 1:length(LA))
        {
        # Note: LS can be a vector or list. We convert it into a character vector VS by converting all elements to character.
        LS = LA[[i]]
        VS = character(0)
        for (j in 1:length(LS))
            VS = c(VS, as.character(LS[[j]]))
        # Process the result with tprintf(). A single string S is returned.
        S = tprintf(VS)
        if (S == "\n")
            {
            res$S = paste0(res$S, "\n")
            res$len = 0
            }
        else if (S != "")
            {
            # Prepend bullet string. Append the suffix string unless this is the last argument.
            S = paste0(bullets[nextBullet], S)
            nextBullet = ifelse(nextBullet == length(bullets), 1, nextBullet+1)
            if (i < length(LA))
                S = paste0(S, suffix)
            # Expand the string and append it to res$S.
            res = expandTabs(res, S)
            }
        }
    return(res$S)
    }

# Convert a floating point value to a character string using C %.12f notation,
# then remove the single leading 0 before the decimal point, if any, and remove
# all trailing 0's.
#
# Arguments:
#   f: floating point value to convert.
#
# Returns: string conversion of f.
getFloatStringNoLeadTrailZeroes = function(f)
    {
    S = sprintf("%.12f", f)
    S = sub("0?(.*?)0*$", "\\1", S)
    return(S)
    }

# List legend_args contains members txt, col, lwd, lty, and pch, which are
# arguments for the legend() function. Optionally add to these ONE or TWO more
# elements for the two notes:
#   basicData_plot$addForApproximationNote
#   basicData_plot$isEstimate_note
# Only add if these note strings are NOT the empty string.
addLegendArgsForDataPointNotes = function(legend_args)
    {
    if (basicData_plot$addForApproximationNote != "")
        {
        legend_args$txt = c(legend_args$txt, basicData_plot$addForApproximationNote)
        legend_args$col = c(legend_args$col, col_est_data)
        legend_args$lwd = c(legend_args$lwd, NA)
        legend_args$lty = c(legend_args$lty, NA)
        legend_args$pch = c(legend_args$pch, pch_est_data)
        }
    if (basicData_plot$isEstimate_note != "")
        {
        legend_args$txt = c(legend_args$txt, basicData_plot$isEstimate_note)
        legend_args$col = c(legend_args$col, col_change_data)
        legend_args$lwd = c(legend_args$lwd, NA)
        legend_args$lty = c(legend_args$lty, NA)
        legend_args$pch = c(legend_args$pch, pch_change_data)
        }
    return(legend_args)
    }

################################################################################
# Create a data frame containing the measured speed and wh/mi data, using the
# units used for plotting.
################################################################################

# Data frame dAll contains ALL data, including estimated data added for approximation.

dAll = data.frame(speed=basicData_plot$speed,
        WhPerDist_dir1=basicData_plot$WhPerDist_dir1,
        WhPerDist_dir2=basicData_plot$WhPerDist_dir2,
        isEstimate_dir1=basicData_plot$isEstimate_dir1,
        isEstimate_dir2=basicData_plot$isEstimate_dir2,
        addForApproximation=basicData_plot$addForApproximation,
        stringsAsFactors=FALSE)

################################################################################
# Compute a bunch of values in dAll derived from the measured values.
################################################################################

# Average the two directions to get the energy per unit distance value we will use for most plots.
dAll$WhPerDist = (dAll$WhPerDist_dir1 + dAll$WhPerDist_dir2)/2

# Compute the percent of the battery used per unit distance.
dAll$batteryPctPerDist = Wh_to_batteryPct(dAll$WhPerDist)
dAll$batteryPctPerDist_dir1 = Wh_to_batteryPct(dAll$WhPerDist_dir1)
dAll$batteryPctPerDist_dir2 = Wh_to_batteryPct(dAll$WhPerDist_dir2)

# Compute the distance per 1% battery used.
dAll$distPerBattery1pct = round(1/Wh_to_batteryPct(dAll$WhPerDist), 2)

# Compute the distance per kWh.
dAll$distPer_kWh = WhPerDist_to_DistPer_kWh(dAll$WhPerDist)

# Compute power used.
dAll$kw = Speed_WhPerDist_to_kW(dAll$speed, dAll$WhPerDist)

# Compute range using degraded battery capacity.
dAll$range = WhPerDist_to_Range(dAll$WhPerDist)

# Compute the percent of the battery used per hour. Note that 1 kW = 1000 W = 1000 Wh / hour
dAll$batteryPctPerHour = Wh_to_batteryPct(1000*dAll$kw)

# Compute electricity distance travelled per unit of currency and its inverse.
dAll$electDistPerCost = WhPerDist_to_ElecDistPerCurrencyUnit(dAll$WhPerDist)
dAll$electCostPerDist = WhPerDist_to_ElectCostPerDist(dAll$WhPerDist)

# Compute fuel efficiency of equivalent fuel vehicle at the same set of speeds.
dAll$distPerUnitFuel = Speed_to_fuelDistPerfuelVolUnit(dAll$speed)

# Compute fuel distance travelled per unit of currency and its inverse.
dAll$fuelDistPerCost = Speed_to_FuelDistPerCurrencyUnit(dAll$speed)
dAll$fuelCostPerDist = Speed_to_FuelCostPerDist(dAll$speed)

# Compute electricity and equivalent gasoline cost per compareEnergyCost_Dist distance.
dAll$electCostForFixedDist = WhPerDist_to_ElectCostForDist(dAll$WhPerDist)
dAll$fuelCostForFixedDist = Speed_to_FuelCostForDist(dAll$speed)

# Compute electricity and equivalent gasoline cost per compareEnergyCost_Hours hours.
dAll$electCostForFixedTime = WhPerDist_Speed_to_ElectCostForTime(dAll$WhPerDist, dAll$speed)
dAll$fuelCostForFixedTime = Speed_to_FuelCostForTime(dAll$speed)

################################################################################
# Copy the dAll data frame into two more data frames, one used for plotting
# measured values and the other for computing polynomial approximations.
################################################################################

# Copy and remove the data added for approximation. Data frame dt is used to make plots of MEASURED data.
dt = dAll[!dAll$addForApproximation,]

# Copy data for approximation. Data frame dta is used to compute polynomial approximations to the measured data.
dta = dAll

################################################################################
# Define speed ranges for plotting on x-axis.
#
# Vector fineSpeeds contains a range of speeds at which to compute various
# functions of speed at a fine speed scale, much finer of a scale than the
# speeds at which measurements of energy consumption were made. These speeds
# are used to predict various values using polynomial approximations, so that
# they can be plotted on a much wider speed scale than the measurement speeds.
################################################################################

# Set variables for upper and lower limits, then create a vector of the speeds.
# Note that a speed of 0 is not included because this will cause divide-by-zero
# in some equations (but do we care??). However, we do need to define xmin_fineSpeed
# to include 0 for the actual plot xlim parameter. Also define number of axis ticks
# when fineSpeeds is plotted.
xmin_fineSpeed = ifelse(useMetricInPlots, 0, 0)
min_fineSpeed = ifelse(useMetricInPlots, 1, 1)
max_fineSpeed = ifelse(useMetricInPlots, 200, 120)
fineSpeeds = seq(min_fineSpeed, max_fineSpeed, by=0.1)
nTicks_fineSpeed = (max_fineSpeed-xmin_fineSpeed)/ifelse(useMetricInPlots, 10, 5)

################################################################################
# Define distance ranges for plotting on x-axis when the fineSpeeds vector is
# used for the speeds.
#
# Vector fineDists contains a range of distances at which to compute various
# functions of distance at the fine speed scale given by fineSpeeds. These
# distances are used to predict various values using polynomial approximations.
################################################################################

maxDist_fineSpeed = ifelse(useMetricInPlots, 700, 400)
nTicksDist_fineSpeed = ifelse(useMetricInPlots, maxDist_fineSpeed/50, maxDist_fineSpeed/25)
fineDists = seq(0, maxDist_fineSpeed, by=5)

################################################################################
# Below, numerous approximations are computed for various parameters that are
# subsequently plotted. There are two linear approximations (power and range)
# which use the actual measured data in dt to fit a line. Power is also
# approximated much more accurately (very accurately) using a 3rd-order
# polynomial in speed, with the coefficient for speed^2 being 0 (see comments
# later for explanation). That approximation uses the measured data plus
# additional points (added at very low speeds to produce a better approximation
# curve) in dta.
#
# From the 3rd-order power approximation, the coefficients of rolling resistance
# and drag are derived, see the comments for details.
#
# From the 3rd-order power approximation and the coefficients of rolling
# resistance and drag, the approximations for baseline, rolling, and drag power
# are estimated, see the comments for details.
#
# The total power approximation is then simply the sum of the baseline, rolling,
# and drag power approximations.
#
# Most other approximations are based on that total power approximation, because
# their values can be derived from a simple equation as long as the power at
# each speed is known.
#
# The coefficients are stored in list apx (=approximation), which contains
# sublists, one for each parameter approximation. The sublist name indicates
# the parameter and what it depends on, and sometimes indicates the type of
# approximation. For example, apx$Speed_Range is the approximation to range
# using the accurate 3rd-order approximation, while apx$Speed_Range_linear is
# the linear approximation for range, and apx$Speed_BatteryPctPerHour is the
# approximation for battery consumption in %/hr as a function of speed, based
# on the power given by apx$Speed_TotalPower.
#
# Within each parameter approximation sublist are additional values which may
# or may not be present depending on the approximation:
#
#   name        description
#   ---------   ----------------------------------------------------------------
#   note        text string providing information about the approximation, or an
#                   empty string if none.
#   text        string representation of the approximation formula
#   textplus    like "text" but is followed by an additional description of the
#                   variables in the expression.
#   expr          R expression object for the formula
#   compute       R function that computes the parameter values from a vector
#                   of the independent values (usually a vector of speeds).
#   I, M, etc.  Approximations that have estimated coefficients store the
#                   coefficient values in the sublist as single-letter members.
#
# The roundToAccuracy() function is used to round coefficients to values
# that are easier to read and remember and work with in your head while
# still close enough to the actual coefficient value to do a good job, but
# using it means you need to look at the plotted approximation curves to
# see if they actually are good approximations.
################################################################################

# Store all approximations in apx list.
apx = list()

################################################################################
# Speed_TotalPower_013: polynomial approximation for power in kw as a function
# of speed.
#
# This approximation is also derived using power computed from the measured data
# with this equation:
#       kW = speed*WhPerDist/1000
# In this case, dta rather than dt is used, so that the extra data points added
# to the data produce a better polynomial curve at low speeds.
#
# The polynomial used here is a 3rd-order polynomial, except that we force the
# coefficient of "speed^2" to be 0. The reason is that we expect the total
# vehicle power to be of the form:
#   baseline_power + rolling_power_coef * speed + drag_power_coef * speed^3
# (the _013 in the name is from the powers of "speed" in this equation)
#
# The polynomial coefficients are apx$Speed_TotalPower_013$A (speed^3
# coefficient), $B (speed coefficient), and $C (intercept coefficient).
#
# By computing an approximation of the form: A*speed^3 + B*speed + C, we can
# equate the coefficient A with the drag power term, B with the rolling power
# term, and C with the baseline power.
#
# This approximation fits the measured computed curve quite accurately.
#
# This is currently the only approximation on which indirect approximations for
# other parameters are based.
################################################################################

fit = lm(kw ~ speed + I(speed^3), data=dta)
coef = fit$coefficients
# Convert to form: coefA*speed^3+coefB*speed+coefC where we round each of the
# coefs to reduce the number of significant digits but retain enough digits so
# they are within 1% of the original value.
coefs = list()
coefs$A = roundToAccuracy(coef[3], pctAccuracy=1)
coefs$B = roundToAccuracy(coef[2], pctAccuracy=1)
coefs$C = roundToAccuracy(coef[1], pctAccuracy=1)
if (coefs$A < 0) stop("Expected coefs$A to be >=0")
if (coefs$B < 0) stop("Expected coefs$B to be >=0")
if (coefs$C < 0) stop("Expected coefs$C to be >=0")
coefA = getFloatStringNoLeadTrailZeroes(coefs$A)
coefB = getFloatStringNoLeadTrailZeroes(coefs$B)
coefC = getFloatStringNoLeadTrailZeroes(coefs$C)
coefs$note = ""
coefs$text = paste0("Total Power ~~ ", coefA, "S^3 + ", coefB, "S + ", coefC)
coefs$textplus = paste0("3rd-order approx for ", coefs$text, "  (S = speed)")
coefs$expr = epaste("'Total Power ~~ ", coefA, "'*S^3*+'", coefB, "'*S*+'", coefC, "'")
coefs$compute = function(speeds)
    {
    kW = (apx$Speed_TotalPower_013$A*speeds^2+apx$Speed_TotalPower_013$B)*speeds+apx$Speed_TotalPower_013$C
    kW = setNames(kW, as.character(speeds))
    return(kW)
    }
apx$Speed_TotalPower_013 = coefs

################################################################################
# TotalPower_RollingCoef: rolling resistance coefficient approximation.
#
# Compute an approximation to the rolling resistance coefficient using the
# total power approximation. The equation used here to compute was derived (with
# algebra) after setting the power computations in rollingPower_kW() (with the
# weight_N and energyEff arguments set for the test vehicle) equal to
# speeds_plotUnits times the total power third-order approximation's "speed"
# coefficient, which is apx$Speed_TotalPower_013$B.
#
# The rolling coefficient is estimated using the "B" (speed) coefficient of the
# apx$Speed_Power_013 third-order approximation of power as a function of speed.
# The reason this can be done is that we expect the total vehicle power to be of
# the form:
#   drag_power_coef*C1*speed^3) + rolling_power_coef*C2*speed + baseline_power
# and since the apx$Speed_Power_013 approximation is of the form:
#   A*speed^3 + B*speed + C
# We can equate rolling_power_coef = B/C2.
#
# Note: we round the rolling coefficient to two significant digits.
################################################################################

coefs = list()
coefs$coefRolling = signif(
    1000 * apx$Speed_TotalPower_013$B * fEnergyEfficiency / vehicleWeight_N /
    ifelse(useMetricInPlots, mps_per_kmph, mps_per_mph), 2)
coefs$note = "Note: the rolling coefficient is computed from the speed^1 coefficient in the 3rd-order power approx"
coefs$text = "Rolling Coef ~~ 1000 x speed_coef x convert_mps_to_xxph x eff / vehicleWeight_N"
coefs$textplus = paste0("Est. ", coefs$text)
apx$TotalPower_RollingCoef = coefs

################################################################################
# TotalPower_DragCoef: drag coefficient approximation.
#
# Compute an approximation to the drag coefficient using the total power
# approximation. The equation used here to compute was derived (with algebra)
# after setting the power computations from dragPower_kW() (with the rho,
# frontalArea_sq_m, energyEff, regenEff arguments set for the test vehicle)
# equal to speeds_plotUnits cubed times the total power approximation's "speed
# cubed" coefficient, which is apx$Speed_TotalPower_013$A.
#
# The drag coefficient is estimated using the "A" (speed cubed) coefficient of
# the apx$Speed_Power_013 third-order approximation of power as a function of
# speed. The reason this can be done is explained in the comments above for
# TotalPower_RollingCoef. We can equate drag_power_coef in those comments to
# A/C1.
#
# Note: we round the drag coefficient to two significant digits.
################################################################################

coefs = list()
coefs$coefDrag = signif(
    1000 * apx$Speed_TotalPower_013$A * 2 * fEnergyEfficiency / rho_test /
    basicData_plot$frontalArea_sq_m /
    ifelse(useMetricInPlots, mps_per_kmph, mps_per_mph)^3, 2)
coefs$note = "Note: the drag coefficient is computed from the speed^3 coefficient in the 3rd-order power approx"
coefs$text = "Drag Coef ~~ 1000 x speed_cubed_coef x convert_mps_to_xxph^3 x 2 x eff / air_density / frontal_area"
coefs$textplus = paste0("Est. ", coefs$text)
apx$TotalPower_DragCoef = coefs

################################################################################
# Speed_BaselinePower: baseline power approximation, constant.
#
# Compute approximation to baseline power as a function of speed, using the
# constant-term's coefficient from the 3rd-order power approximation above.
#
# The baseline power is estimated using the "C" (constant-term) coefficient of
# the apx$Speed_Power_013 third-order approximation of power as a function of
# speed. The reason this can be done is explained in the comments above for
# TotalPower_RollingCoef. We can equate baseline_power in those comments
# directly to "C".
#
# Note: the baseline power is rounded to 3 digits after the decimal point, so to
# an integer number of watts.
################################################################################

coefs = list()
coefs$baselinePower = round(apx$Speed_TotalPower_013$C, 3)
coefs$note = "Note: baseline power is taken to be the y-intercept term in 3rd-order power approx."
coefs$text = "Baseline Power ~~ constant_term_coef"
coefs$textplus = paste0("Est. ", coefs$text)
coefs$expr = epaste("'Power ~~ ", apx$Speed_TotalPower_013$C, "'")
coefs$compute = function(speeds)
    {
    kW = rep(apx$Speed_BaselinePower$baselinePower, length(speeds))
    kW = setNames(kW, as.character(speeds))
    return(kW)
    }
apx$Speed_BaselinePower = coefs

################################################################################
# Speed_RollingPower: rolling power approximation.
#
# Compute approximation to the rolling power as a function of speed, using the
# estimated rolling coefficient from above.
################################################################################

coefs = list()
coefs$note = "Note: rolling power is computed using the rolling coef estimated from 3rd-order power approx"
coefs$text = "Rolling Power = S x coefRolling x vehicleWeight_N / eff / 1000"
coefs$textplus = paste0(coefs$text, "  (S=speed, mps)")
coefs$compute = function(speeds)
    {
    kW = rollingPower_kW(speeds, apx$TotalPower_RollingCoef$coefRolling, vehicleWeight_N, fEnergyEfficiency)
    kW = setNames(kW, as.character(speeds))
    return(kW)
    }
apx$Speed_RollingPower = coefs

################################################################################
# Speed_DragPower: air drag power approximation.
#
# Compute approximation to the drag power as a function of vehicle and air
# speeds and air density, using the estimated drag coefficient from above.
################################################################################

coefs = list()
coefs$note = "Note: drag power is computed using the drag coef estimated from 3rd-order power approx"
coefs$text = "Drag Power = SC x SA^2 x coefDrag x airDens x area x (SA>=0? 1/eff : -regenEff) / 2000"
coefs$textplus = paste0(coefs$text, "  (SC=car, SA=air speeds, mps)")
coefs$compute = function(vehicleSpeeds, airSpeeds=vehicleSpeeds, rho=rho_test)
    {
    kW = dragPower_kW(vehicleSpeeds, airSpeeds, apx$TotalPower_DragCoef$coefDrag,
        rho, basicData_plot$frontalArea_sq_m, fEnergyEfficiency, fRegenEfficiency)
    kW = setNames(kW, as.character(vehicleSpeeds))
    return(kW)
    }
apx$Speed_DragPower = coefs

################################################################################
# Speed_TotalPower: total power approximation using estimates of the drag and
# rolling coefficients and baseline power.
#
# Compute approximation to total drag power as a function of vehicle and air
# speeds and air density, by SUMMING the baseline, rolling, and drag power
# estimates from above.
################################################################################

coefs = list()
coefs$note = "Note: total power is computed by summing baseline, rolling, and drag power"
coefs$text = "Est. Total Power P = baseline+rolling+drag power"
coefs$textplus = coefs$text
coefs$compute = function(vehicleSpeeds, airSpeeds=vehicleSpeeds, rho=rho_test)
    {
    kW = apx$Speed_BaselinePower$compute(vehicleSpeeds) +
         apx$Speed_RollingPower$compute(vehicleSpeeds) +
         apx$Speed_DragPower$compute(vehicleSpeeds, airSpeeds, rho)
    kW = setNames(kW, as.character(vehicleSpeeds))
    return(kW)
    }
apx$Speed_TotalPower = coefs

################################################################################
# Speed_BatteryPctPerHour: energy per hour approximations.
#
# Computes approximations to battery %/hr as a function of speed. There are four
# approximations:
#   Speed_BatteryPctPerHour_total: total batt %/hr, 3rd-order curve
#   Speed_BatteryPctPerHour_baseline: baseline batt %/hr, constant
#   Speed_BatteryPctPerHour_rolling: rolling batt %/hr, proportional to speed
#   Speed_BatteryPctPerHour_drag: drag batt %/hr, proportional to speed^3
# These use, respectively, the above power approximations Speed_TotalPower,
# Speed_BaselinePower, Speed_RollingPower, and Speed_DragPower.
#
# Power in kilowatts is converted to estimated % battery per hour by applying
# the following equation:
#   batteryPctPerHour = Wh_to_batteryPct(1000*kW)
#                     = kW*scale_kWh_to_BatteryPct
#                     = 100*kW/batteryCapacity_kWh
# (Note that 1 kW = 1 kWh/hour)
################################################################################

# total
coefs = list()
coefs$note = "Note: total batt %/hr approx is est. total power (P) divided by batt cap"
coefs$text = paste0(tprintf("~battery_pwr@ = 100P/"), basicData_plot$batteryCapacity_kWh)
coefs$textplus = paste0(coefs$text, "  (100% x total power P / batt cap)")
coefs$expr = epaste(tprintf("'~battery_pwr@ = 100P'/"), basicData_plot$batteryCapacity_kWh)
coefs$compute = function(speeds)
    setNames(100*apx$Speed_TotalPower$compute(speeds)/basicData_plot$batteryCapacity_kWh, as.character(speeds))
apx$Speed_BatteryPctPerHour_total = coefs

# baseline
coefs = list()
coefs$note = "Note: baseline batt %/hr approx is est. baseline power (B) divided by batt cap"
coefs$text = paste0(tprintf("~battery_pwr@ = 100B/"), basicData_plot$batteryCapacity_kWh)
coefs$textplus = paste0(coefs$text, "  (100% x baseline power approx B / batt cap)")
coefs$expr = epaste(tprintf("'~battery_pwr@ = 100B'/"), basicData_plot$batteryCapacity_kWh)
coefs$compute = function(speeds)
    setNames(100*apx$Speed_BaselinePower$compute(speeds)/basicData_plot$batteryCapacity_kWh, as.character(speeds))
apx$Speed_BatteryPctPerHour_baseline = coefs

# rolling
coefs = list()
coefs$note = "Note: rolling batt %/hr approx is est. rolling power (R) divided by batt cap"
coefs$text = paste0(tprintf("~battery_pwr@ = 100R/"), basicData_plot$batteryCapacity_kWh)
coefs$textplus = paste0(coefs$text, "  (100% x rolling power approx R / batt cap)")
coefs$expr = epaste(tprintf("'~battery_pwr@ = 100R'/"), basicData_plot$batteryCapacity_kWh)
coefs$compute = function(speeds)
    setNames(100*apx$Speed_RollingPower$compute(speeds)/basicData_plot$batteryCapacity_kWh, as.character(speeds))
apx$Speed_BatteryPctPerHour_rolling = coefs

# drag
coefs = list()
coefs$note = "Note: drag batt %/hr approx is est. drag power (D) divided by batt capacity"
coefs$text = paste0(tprintf("~battery_pwr@ = 100D/"), basicData_plot$batteryCapacity_kWh)
coefs$textplus = paste0(coefs$text, "  (100% x drag power approx D / batt cap)")
coefs$expr = epaste(tprintf("'~battery_pwr@ = 100D'/"), basicData_plot$batteryCapacity_kWh)
coefs$compute = function(speeds)
    setNames(100*apx$Speed_DragPower$compute(speeds)/basicData_plot$batteryCapacity_kWh, as.character(speeds))
apx$Speed_BatteryPctPerHour_drag = coefs

################################################################################
# Speed_Range: range approximation using Speed_TotalPower approximation above.
#
# Compute an accurate approximation to range as a function of speed, using
# battery capacity, speed, and the Speed_TotalPower approximation above.
#
# This equation is used to estimate range:
#   range = basicData_plot$batteryCapacity_kWh*speed/totalPower
################################################################################

coefs = list()
coefs$note = "Note: this uses the 3rd-order approx. for total power (P), battery capacity, and speed (S)"
coefs$text = paste0("Range = ", basicData_plot$batteryCapacity_kWh, "S/P")
coefs$textplus = paste0(coefs$text, "  (batt cap x speed / total power P)")
coefs$expr = epaste("'Range = '*", basicData_plot$batteryCapacity_kWh, "*'S'/'P'")
coefs$compute = function(speeds)
    setNames(basicData_plot$batteryCapacity_kWh*speeds/apx$Speed_TotalPower$compute(speeds), as.character(speeds))
apx$Speed_Range = coefs

################################################################################
# Speed_Range_linear: linear range approximation.
#
# Computes a linear approximation to range as a function of speed, using
# battery capacity, measured speed and energy per distance.
#
# This equation is used to estimate range:
#   range = basicData_plot$batteryCapacity_kWh*1000/WhPerDist)
# WhPerDist is a function of speed, measured at each speed.
# dt rather than dta is used, the extra data points added to the data are not
# used here.
################################################################################

fit = lm(range ~ speed, data=dt)
coef = fit$coefficients
coefs = list()
coefs$I = roundToAccuracy(coef[1], pctAccuracy=5)
coefs$M = roundToAccuracy(coef[2], pctAccuracy=5)
coefMsign = ifelse(coefs$M < 0, "-", "+")
coefMabs = abs(coefs$M)
coefs$note = ""
coefs$text = paste0("Range ~~ ", coefs$I, coefMsign, coefMabs, "S")
coefs$expr = epaste("'Range ~~ '*", coefs$I, coefMsign, coefMabs, "*'S'")
coefs$compute = function(speeds)
    {
    kW = apx$Speed_Range_linear$I + speeds*apx$Speed_Range_linear$M
    kW = setNames(kW, as.character(speeds))
    return(kW)
    }
apx$Speed_Range_linear = coefs

################################################################################
# Speed_BatteryPctPerDist: energy per distance approximation.
#
# Computes an approximation to battery % per unit distance as a function of
# speed, using speed and the Speed_TotalPower approximation above.
#
# This equation is used to estimate % battery per distance:
#   batteryPctPerDist = kW_Speed_to_batteryPctPerDist(kW, speed)
#                     = 100*kW/(basicData_plot$batteryCapacity_kWh*Speed)
################################################################################

coefs = list()
coefs$note = "Note: this uses the 3rd-order approx. for total power (P), battery capacity, and speed (S)"
coefs$text = paste0(tprintf("~battery_use@ = 100P/"), basicData_plot$batteryCapacity_kWh, "S")
coefs$textplus = paste0(coefs$text, "  (100% x total power P / batt cap / speed S)")
coefs$expr = epaste(tprintf("'~battery_use@ = 100P'/"), basicData_plot$batteryCapacity_kWh, "*'S'")
coefs$compute = function(speeds)
    setNames(100*apx$Speed_TotalPower$compute(speeds)/(basicData_plot$batteryCapacity_kWh*speeds), as.character(speeds))
apx$Speed_BatteryPctPerDist = coefs

################################################################################
# Speed_DistPerUnitCost: distance per unit cost approximation.
#
# Computes an approximation to distance per unit price as a function of speed,
# using speed, electricity cost, and the Speed_TotalPower approximation above.
#
# This equation is used to estimate distance per unit cost:
#   dist per unit cost = Speed/(avgElecCostPer_kWh*kW)
################################################################################

coefs = list()
coefs$note = "Note: this uses speed (S), elect cost, and the 3rd-order approx. for total power (P)"
coefs$text = paste0(tprintf("~dist_per_cost@ = S/"), basicData_plot$avgElecCostPer_kWh, "P")
coefs$textplus = paste0(coefs$text, "  (speed S / elect cost / total power P)")
coefs$expr = epaste(tprintf("'~dist_per_cost@ = '*'S'/"), basicData_plot$avgElecCostPer_kWh, "*'P'")
coefs$compute = function(speeds)
    setNames(speeds/(basicData_plot$avgElecCostPer_kWh*apx$Speed_TotalPower$compute(speeds)), as.character(speeds))
apx$Speed_DistPerUnitCost = coefs

################################################################################
# Speed_CostPerUnitDist: cost per unit distance approximation.
#
# Computes an approximation to cost per unit distance as a function of speed,
# using speed, electricity cost, and the Speed_TotalPower approximation above.
#
# This equation is used to estimate cost per unit distance:
#   cost per unit dist = avgElecCostPer_kWh*kW/Speed
################################################################################

coefs = list()
coefs$note = "Note: this uses elect cost, the 3rd-order approx. for total power (P), and speed (S)"
coefs$text = paste0(tprintf("~cost_per_dist@ = "), basicData_plot$avgElecCostPer_kWh, "P/S")
coefs$textplus = paste0(coefs$text, "  (elect cost x total power P / speed S)")
coefs$expr = epaste(tprintf("'~dist_per_cost@ = '*"), basicData_plot$avgElecCostPer_kWh, "*'P'/'S'")
coefs$compute = function(speeds)
    setNames(basicData_plot$avgElecCostPer_kWh*apx$Speed_TotalPower$compute(speeds)/speeds, as.character(speeds))
apx$Speed_CostPerUnitDist = coefs

################################################################################
# Speed_CostForFixedDist: cost for fixed distance approximation.
#
# Computes an approximation to cost for fixed distance as a function of speed,
# using speed, electricity cost, and the Speed_TotalPower approximation above.
#
# This equation is used to estimate cost for fixed distance:
#   cost for fixed dist = compareEnergyCost_Dist*avgElecCostPer_kWh*kW/Speed
################################################################################

coefs = list()
coefs$note = "Note: this uses elect cost, 3rd-order approx. for total power (P), and speed (S)"
coefs$text = paste0(tprintf("~currency@ to go ~compEnergyCostDist@ = "),
    basicData_plot$compareEnergyCost_Dist, "x", basicData_plot$avgElecCostPer_kWh, "P/S")
coefs$textplus = paste0(coefs$text, "  (", basicData_plot$compareEnergyCost_Dist, " x elect cost x total power P / speed S)")
coefs$expr = epaste(tprintf("'~currency@/~compEnergyCostDist@ = '*"),
    basicData_plot$compareEnergyCost_Dist, "*x*", basicData_plot$avgElecCostPer_kWh, "*'P'/'S'")
coefs$compute = function(speeds)
    setNames(basicData_plot$compareEnergyCost_Dist*basicData_plot$avgElecCostPer_kWh*apx$Speed_TotalPower$compute(speeds)/speeds,
    as.character(speeds))
apx$Speed_CostForFixedDist = coefs

################################################################################
# Place the estimates of the baseline power and drag and rolling coefficients
# into list coefEstimates:
#   coefEstimates$baselinePower_kW: baseline power in kW
#   coefEstimates$rollingCoef: coefficient of rolling resistance
#   coefEstimates$dragCoef: coefficient of drag
# Note that these names are different than the two coefficients in basicData
# named "coefRolling" and "coefDrag", so that both sets of coefficients can be
# referred to in tprintf-style %-specifiers, since tprintf looks in both
# basicData and coefEstimates for %-specifier words.
################################################################################

coefEstimates = list()

# Baseline power in kW.
coefEstimates$baselinePower_kW = apx$Speed_BaselinePower$baselinePower
message("useMetricInPlots=", useMetricInPlots,
    ": Est. baseline power: ", coefEstimates$baselinePower_kW, " kW")

# Coefficient of rolling resistance.
coefEstimates$rollingCoef = apx$TotalPower_RollingCoef$coefRolling
message("useMetricInPlots=", useMetricInPlots,
    ": Est. coef. of rolling resistance: ", coefEstimates$rollingCoef,
    "  Compare to expected value: ", basicData_plot$coefRolling)

# Coefficient of drag.
coefEstimates$dragCoef = apx$TotalPower_DragCoef$coefDrag
message("useMetricInPlots=", useMetricInPlots,
    ": Est. coef. of drag: ", coefEstimates$dragCoef,
    "  Compare to expected value: ", basicData_plot$coefDrag)

################################################################################
# Compute drag, rolling, baseline, and total power at all fineSpeeds vehicle
# speeds, at test conditions with 0 wind, using the estimated rolling and drag
# coefficients and estimated baseline power.
################################################################################

baselinePower_fineSpeeds = apx$Speed_BaselinePower$compute(fineSpeeds)
rollingPower_fineSpeeds = apx$Speed_RollingPower$compute(fineSpeeds)
dragPower_fineSpeeds = apx$Speed_DragPower$compute(fineSpeeds)
totalPower_fineSpeeds = apx$Speed_TotalPower$compute(fineSpeeds)

################################################################################
# Create data frame dt_fineSpeeds, which is similar to dt except its speeds are
# the vector fineSpeeds, and other entries are computed from that and the
# approximation for total power from above.
################################################################################

dt_fineSpeeds = data.frame(
    speed=fineSpeeds,
    batteryPctPerDist=apx$Speed_BatteryPctPerDist$compute(fineSpeeds),
    batteryPctPerHour_total=apx$Speed_BatteryPctPerHour_total$compute(fineSpeeds),
    batteryPctPerHour_baseline=apx$Speed_BatteryPctPerHour_baseline$compute(fineSpeeds),
    batteryPctPerHour_rolling=apx$Speed_BatteryPctPerHour_rolling$compute(fineSpeeds),
    batteryPctPerHour_drag=apx$Speed_BatteryPctPerHour_drag$compute(fineSpeeds),
    range=apx$Speed_Range$compute(fineSpeeds),
    range_linear=apx$Speed_Range_linear$compute(fineSpeeds),
    electDistPerCost=apx$Speed_DistPerUnitCost$compute(fineSpeeds),
    electCostPerDist=apx$Speed_CostPerUnitDist$compute(fineSpeeds),
    distPerUnitFuel=Speed_to_fuelDistPerfuelVolUnit(fineSpeeds),
    fuelDistPerCost=Speed_to_FuelDistPerCurrencyUnit(fineSpeeds),
    fuelCostPerDist=Speed_to_FuelCostPerDist(fineSpeeds),
    electCostForFixedDist=apx$Speed_CostForFixedDist$compute(fineSpeeds),
    electCostForFixedTime=WhPerDist_Speed_to_ElectCostForTime(
        Speed_kW_to_WhPerDist(fineSpeeds, totalPower_fineSpeeds), fineSpeeds),
    fuelCostForFixedDist=Speed_to_FuelCostForDist(fineSpeeds),
    fuelCostForFixedTime=Speed_to_FuelCostForTime(fineSpeeds),
    stringsAsFactors=FALSE)

# Choose a subset of the speeds from dt_fineSpeeds$speed to be plotted each as a separate line on some of the battery plots.
# If all the speeds were plotted, there would be too many lines and the plot would be too busy. Here we just choose those that
# are evenly divisible by 10, or if fewer than 5 are, choose those separated by at least 10 mph or 15 km/h. Don't go under
# 30 mph or 50 km/h. Above 100 mph or 160 km/h, take those evenly divisible by 20, not 10.
ind = (dt_fineSpeeds$speed %% 10 == 0) & (dt_fineSpeeds$speed >= ifelse(useMetricInPlots, 50, 30))
ind = ind & (dt_fineSpeeds$speed <= ifelse(useMetricInPlots, 160, 100) | dt_fineSpeeds$speed %% 20 == 0)
if (sum(ind) < 5)
    {
    D = diff(dt_fineSpeeds$speed)
    minD = ifelse(useMetricInPlots, 15, 10)
    ind = TRUE # Always use first (lowest) speed
    while (length(D) > 0)
        {
        if (D[1] >= minD)
            ind = c(ind, TRUE) # Use next speed, difference to last one chosen is at least minD
        else
            {
            ind = c(ind, FALSE) # Don't use next speed, difference to last one is < minD
            if (length(D) > 1)
                D[2] = D[2] + D[1] # Accumulate difference into next speed's differeence from last
            }
        D = D[-1] # Advance to next difference/next speed.
        }
    }
if (sum(ind) < 5)
    ind = rep(TRUE, length(dt_fineSpeeds$speed))
speeds_batteryPlots = dt_fineSpeeds$speed[ind]
# Also save the indexes into df_fineSpeeds$speed of each of the speeds in speeds_batteryPlots.
idxs_speeds_batteryPlots = which(ind)

################################################################################
# Axis limits for plotting SOC (state-of-charge), a percent value.
################################################################################

# SOC axis limit and number of ticks.
maxSOCpct_axis = 100
nTicksSOCpct_axis = 20

# Scale factor to go from degraded battery energy to state-of-charge percent, so that one
# curve can use two different y-axes for the two units of energy.
scaleBatteryEnergy_to_SOCpct = 100/basicData_plot$batteryCapacity_kWh

################################################################################
# Axis limits and number of ticks for charge curve variables.
################################################################################

# UNDEGRADED battery capacity of charging curve battery.
chargeCurve_batteryCapacity_kWh = max(dfChargeCurve$TotalEnergy)

# Charge curve maximum charging power.
chargeCurve_maxChargingPower_kW = max(dfChargeCurve$Power)

# Compute charging time in minutes.
dfChargeCurve$Minutes = round(dfChargeCurve$Seconds/60, 2)

# Charge curve total charging time in minutes.
chargeCurve_chargeTime_minutes = max(dfChargeCurve$Minutes)

# Define a scale factor to go from UNDEGRADED battery energy in kWh to state-of-charge percent.
scale_kWh_to_BatteryPct_charging = 100/chargeCurve_batteryCapacity_kWh

# Define axis upper limit constant when dfChargeCurve$Minutes is plotted. Round it up to next-highest
# multiple of 10, it will work better for upper axis limit. Also define number of tick marks.
maxChargeMinutes_charging = 10*ceiling(chargeCurve_chargeTime_minutes/10)
nTicksChargeMinutes_charging = maxChargeMinutes_charging/5

# Define axis limit constants when dfChargeCurve$Power is plotted.
maxChargingPower_kW_charging = 50*ceiling(chargeCurve_maxChargingPower_kW/50)
nTicksChargingPower_kW_charging = maxChargingPower_kW_charging/25

# Define a scale factor to go from a y-axis at limit maxChargingPower_kW_charging to one at limit maxChargeMinutes_charging.
axisScale_kW_to_chargeTime_minutes = maxChargeMinutes_charging/maxChargingPower_kW_charging

# Define a scale factor to go from a y-axis at limit maxChargingPower_kW_charging to one at limit maxSOCpct_axis.
axisScale_kW_to_BatteryPct = maxSOCpct_axis/maxChargingPower_kW_charging

# Define axis limit constants when battery %/hour is plotted. It is the same as dfChargeCurve$Power
# but scaled differently.
maxChargingPower_battPctPerHr_charging = 100*ceiling(chargeCurve_maxChargingPower_kW*scale_kWh_to_BatteryPct_charging/100)
nTicksChargingPower_battPctPerHr_charging = maxChargingPower_battPctPerHr_charging/50

# Define a scale factor to go from a y-axis at limit maxChargingPower_battPctPerHr_charging to one at limit maxSOCpct_axis.
axisScale_battPctPerHr_to_SOCaxis = maxSOCpct_axis/maxChargingPower_battPctPerHr_charging

# Define axis limit constants when dfChargeCurve$TotalEnergy is plotted.
maxBatteryEnergy_charging = 5*ceiling(chargeCurve_batteryCapacity_kWh/5)
nTicksBatteryEnergy_charging = maxBatteryEnergy_charging/5

################################################################################
# Axis limits of some plots when using the fineSpeeds vector for speeds.
#
# For axis limits, rather than basing them on the speeds I measured the vehicle at,
# I use a broader set of speeds (fineSpeeds vector), so I can plot the polynomial
# approximation curves over a wider speed range (and wider y-axis range) than when
# only plotting the measured data. I use the approximations above to generate
# approximation curves that are plotted across the full range of values.
#
# Currently I set many of these to constant values, and probably I should move these
# into basicData so they are visible for setting when configuring this file for a
# new car. However, I may later change these to compute the largest value that
# occurs and set the axis limit based on that.
################################################################################

# Limits for plotting % battery per unit distance with fineSpeeds.
maxBatteryPctPerDist_fineSpeed = 1.0
nTicksBatteryPctPerDist_fineSpeed = maxBatteryPctPerDist_fineSpeed*10

# Limits for plotting Watt-hours per mile with fineSpeeds.
maxWhPerDist_fineSpeed = 100*ceiling(maxBatteryPctPerDist_fineSpeed/scale_Wh_to_BatteryPct/100)
nTicksWhPerDist_fineSpeed = maxWhPerDist_fineSpeed/100

# Limits for plotting % battery per hour with fineSpeeds.
maxBatteryPctPerHour_fineSpeed = 100
nTicksBatteryPctPerHour_fineSpeed = 10

# Limits for plotting range with fineSpeeds.
maxRange_fineSpeed = ifelse(useMetricInPlots, 900, 500)
nTicksRange_fineSpeed = maxRange_fineSpeed/50

# Limits for plotting DistPerBattery1pct with fineSpeeds.
maxDistPerBattery1pct_fineSpeed = round(maxRange_fineSpeed/scale_DistPerBatteryPct_to_Range)
nTicksDistPerBattery1pct_fineSpeed = 2*maxDistPerBattery1pct_fineSpeed

# Limits for plotting DistPer_kWh with fineSpeeds.
maxDistPer_kWh_fineSpeed = round(maxRange_fineSpeed/scale_DistPer_kWh_to_Range)
nTicksDistPer_kWh_fineSpeed = 2*maxDistPer_kWh_fineSpeed

# Limits for plotting kW (power) with fineSpeeds.
max_kW_fineSpeed = 10*ceiling(apx$Speed_TotalPower$compute(max_fineSpeed)/10)
nTicks_kW_fineSpeed = max_kW_fineSpeed/5

# Limits for plotting battery energy on one y-axis when corresponding state-of-charge in percent is
# plotted on ANOTHER y-axis. Battery energy maxes out at the specified DEGRADED capacity. We interpret
# 100% state-of-charge as battery at DEGRADED CAPACITY. Note that this means that the grid lines for
# the state-of-charge y-axis will generally NOT line up with the tick marks on the battery energy y-axis.
# We can't do anything about this.
maxBatteryEnergy_fineSpeed = 25*ceiling(basicData_plot$batteryCapacity_kWh/25)
nTicksBatteryEnergy_fineSpeed = maxBatteryEnergy_fineSpeed/5

# Limits for plotting distance per electricity OR FUEL cost on the FIRST axis and distance per unit of fuel
# on the SECOND axis, defined in a way that aligns the grid labels and ticks.
# Also define a scale factor to go from SECOND axis to FIRST axis, for translating values to the first axis
# units for plotting.
L = pretty2(c(0, dt_fineSpeeds$electDistPerCost, dt_fineSpeeds$fuelDistPerCost), c(0, dt_fineSpeeds$distPerUnitFuel), 5)
maxDistPerCost_fineSpeed = max(L$Vx)
nTicksDistPerCost_fineSpeed = length(L$Vx)-1
maxDistPerUnitFuel_fineSpeed_1 = max(L$Vy)
nTicksDistPerUnitFuel_fineSpeed_1 = length(L$Vy)-1
scaleDistPerUnitFuel_to_DistPerCost_fineSpeed = maxDistPerCost_fineSpeed/maxDistPerUnitFuel_fineSpeed_1

# The next five definitions are similar to the five immediately above.

# Limits for plotting electricity OR FUEL cost per distance on the FIRST axis and distance per unit of fuel on
# the SECOND axis, defined in a way that aligns the grid labels and ticks, and again a scale factor for the axes.
# Here we multiply dt_fineSpeeds$fuelCostPerDist by 0.3 because it currently has a very high tail at low speeds,
# which makes the left y-axis limit way too high. I hate these manual adjustments for nicer graphs, but what else
# can I do?
L = pretty2(c(0, dt_fineSpeeds$electCostPerDist, 0.3*dt_fineSpeeds$fuelCostPerDist), c(0, dt_fineSpeeds$distPerUnitFuel), 10)
maxCostPerDist_fineSpeed = max(L$Vx)
nTicksCostPerDist_fineSpeed = length(L$Vx)-1
maxDistPerUnitFuel_fineSpeed_2 = max(L$Vy)
nTicksDistPerUnitFuel_fineSpeed_2 = length(L$Vy)-1
scaleDistPerUnitFuel_to_CostPerDist_fineSpeed = maxCostPerDist_fineSpeed/maxDistPerUnitFuel_fineSpeed_2

# The next five definitions are AGAIN similar to the five immediately above.

# Limits for plotting electricity OR FUEL cost per fixed distance or time on the FIRST axis and distance per unit of fuel on
# the SECOND axis, defined in a way that aligns the grid labels and ticks, and again a scale factor for the axes.
# Here we multiply dt_fineSpeeds$fuelCostForFixedDist by 0.3 because it currently has a very high tail at low speeds,
# which makes the left y-axis limit way too high.
L = pretty2(c(0, dt_fineSpeeds$electCostForFixedDist, dt_fineSpeeds$electCostForFixedTime,
    0.3*dt_fineSpeeds$fuelCostForFixedDist, dt_fineSpeeds$fuelCostForFixedTime), c(0, dt_fineSpeeds$distPerUnitFuel), 10)
maxCostForDistHours_fineSpeed = max(L$Vx)
nTicksCostForDistHours_fineSpeed = length(L$Vx)-1
maxDistPerUnitFuel_fineSpeed_3 = max(L$Vy)
nTicksDistPerUnitFuel_fineSpeed_3 = length(L$Vy)-1
scaleDistPerUnitFuel_to_CostForDistHours_fineSpeed = maxCostForDistHours_fineSpeed/maxDistPerUnitFuel_fineSpeed_3

# Limits for plotting log range on the FIRST axis and distance per battery 1% on the SECOND axis, when plotting as
# a function of ROAD GRADE. Define this in a way that aligns the grid labels and ticks. We want the maximum range
# to be quite large. Also define axpRange_Grade_log as the yaxp value to use, see par(axp) help. If the ratio of
# max to min is only about 10, it makes sense to use the first form of axp with c(min, max, -# intervals), where
# -9 works well if ratio is exactly 10.
minRange_Grade_log = 50
maxRange_Grade_log = ifelse(useMetricInPlots, 12000, 7500)
axpRange_Grade_log = c(1, ifelse(useMetricInPlots, 4, 3), 3)
minDistPerBatteryPct_Grade_log = minRange_Grade_log/scale_DistPerBatteryPct_to_Range
maxDistPerBatteryPct_Grade_log = maxRange_Grade_log/scale_DistPerBatteryPct_to_Range
# Set an upper limit SOMEWHAT BELOW the maximum range on the axis BUT AT 1 or 2 or 5 times A POWER OF 10 for nice plotting of
# huge downhill grade values, see plot.
maxPlottedRange_Grade_log = ifelse(useMetricInPlots, 10000, 5000)

# Limits for plotting range on the FIRST axis and distance per battery 1% on the SECOND axis, when plotting as
# a function of ELEVATION CHANGE, which has a much smaller range and does not require log plotting.
maxRange_ElevChg_fineSpeed = ifelse(useMetricInPlots, 900, 600)
nTicksRange_ElevChg_fineSpeed = maxRange_ElevChg_fineSpeed/50
maxDistPerBatteryPct_ElevChg_fineSpeed = maxRange_ElevChg_fineSpeed/scale_DistPerBatteryPct_to_Range
nTicksDistPerBatteryPct_ElevChg_fineSpeed = maxDistPerBatteryPct_ElevChg_fineSpeed

# Limits for plotting range on the FIRST axis and speed on the SECOND axis, when plotting as a
# function of BASELINE POWER.
maxRange_BaselinePower_fineSpeed = ifelse(useMetricInPlots, 1100, 700)
nTicksRange_BaselinePower_fineSpeed = maxRange_BaselinePower_fineSpeed/100
maxSpeed_BaselinePower_fineSpeed = ifelse(useMetricInPlots, 120, 75)
nTicksSpeed_BaselinePower_fineSpeed = maxSpeed_BaselinePower_fineSpeed/5
scale_Speed_to_Range_BaselinePower = maxRange_BaselinePower_fineSpeed/maxSpeed_BaselinePower_fineSpeed

# Choose a set of wind speeds for which to plot drag curves. Create a vector of the speeds.
peakWindSpeed = ifelse(useMetricInPlots, 40, 25)
windSpeeds = seq(-peakWindSpeed, +peakWindSpeed, by=ifelse(useMetricInPlots, 10, 5))

# Limits for plotting % battery per unit distance with fineSpeeds and windSpeeds.
maxBatteryPctPerDist_windSpeed = 2.0
nTicksBatteryPctPerDist_windSpeed = maxBatteryPctPerDist_windSpeed*10

# Limits for plotting Watt-hours per mile with fineSpeeds and windSpeeds.
maxWhPerDist_windSpeed = floor(maxBatteryPctPerDist_windSpeed/scale_Wh_to_BatteryPct/100)*100
nTicksWhPerDist_windSpeed = maxWhPerDist_windSpeed/100

# Limits for plotting range with fineSpeeds and windSpeeds.
maxRange_windSpeed = ifelse(useMetricInPlots, 1200, 600)
nTicksRange_windSpeed = maxRange_windSpeed/50

# Limits for plotting distance per battery 1% with fineSpeeds and windSpeeds.
maxDistPerBattery1pct_windSpeed = round(maxRange_windSpeed/scale_DistPerBatteryPct_to_Range)
nTicksDistPerBattery1pct_windSpeed = 2*maxDistPerBattery1pct_windSpeed

# Limits for plotting DistPer_kWh with fineSpeeds and windSpeeds.
maxDistPer_kWh_windSpeed = round(maxRange_windSpeed/scale_DistPer_kWh_to_Range)
nTicksDistPer_kWh_windSpeed = 2*maxDistPer_kWh_windSpeed

################################################################################
################################################################################
# Beginning of plots.
################################################################################
################################################################################

################################################################################
# Note about use of title() in plots:
# One wants to be able to control the distance of the title above the plot frame
# INDEPENDENTLY OF the amount of margin space ABOVE the title. When the title is
# drawn using the main= argument of plot(), its vertical position is CENTERED in
# the top margin, so that there is no independent control, but rather, increasing
# the top margin increases both the position of the title above the plot AND the
# margin space above the title. The way around this is to use title() to plot the
# title, which allows its position to be independently controlled using the
# line= argument.
################################################################################

################################################################################
# Plot power as a function of speed.
################################################################################

# CT = battery charge used per unit time, P = power (energy per unit time), S = speed
plotCT_PvsS = function(isPDF=FALSE)
    {
    xlim = c(0, max_fineSpeed)
    xaxp = c(xlim, nTicks_fineSpeed)
    ylim_left = c(0, maxBatteryPctPerHour_fineSpeed)
    yaxp_left = c(ylim_left, nTicksBatteryPctPerHour_fineSpeed)
    ylim_right = c(0, max_kW_fineSpeed)
    yaxp_right = c(ylim_right, nTicks_kW_fineSpeed)

    svpar = par(mai=par("mai")+c(0, 0.1, 1, 0.6), mgp=c(2.5, 0.75, 0))

    plot(NA, type='n', xlim=xlim, xaxp=xaxp, ylim=ylim_left, yaxp=yaxp_left, las=2, main="",
        xlab=tprintf("Speed on flat road (~speed@)"),
        ylab=tprintf("Battery consumption (~battery_pwr@)"))
    title("Power consumption and estimates of rolling and drag coefficients", line=7.2, cex.main=1.1)
    cex = 0.75
    mtext(paste0("This shows points computed from raw data and a 3rd-order approximation.\n",
        makeStringList("~EVdesc@", "~conditions@", "~battDeg@", "~SOC100@",
            apx$Speed_TotalPower_013$textplus,
            apx$TotalPower_RollingCoef$textplus,
            apx$TotalPower_DragCoef$textplus,
            apx$Speed_BaselinePower$textplus,
            apx$Speed_TotalPower$textplus,
            apx$Speed_RollingPower$textplus,
            apx$Speed_DragPower$textplus,
            cex=cex)),
        side=3, line=0.3, adj=0, cex=cex)

    # Right-side y-axis.
    labels = pretty.good2(ylim_right, yaxp_right[3])
    at = labels * scale_kWh_to_BatteryPct
    axis(side=4, at=at, labels=labels, las=2)
    mtext(tprintf("Power consumption (~power@)"), side=4, line=2.5)

    par(xaxp=xaxp)
    par(yaxp=yaxp_left)
    grid(lwd=lwd_grid, lty=lty_grid, col=col_grid)

    lines(dt$speed, dt$batteryPctPerHour, lwd=lwd_derived_data, lty=lty_derived_data, col=col_derived_data)
    ind = dt$isEstimate_dir1 | dt$isEstimate_dir2
    points(dt$speed[!ind], dt$batteryPctPerHour[!ind], pch=pch_derived_data, col=col_derived_data)
    if (any(ind))
        points(dt$speed[ind], dt$batteryPctPerHour[ind], pch=pch_change_data, col=col_change_data)
    ind = dta$addForApproximation
    if (any(ind))
        points(dta$speed[ind], dta$batteryPctPerHour[ind], pch=pch_est_data, col=col_est_data)
    lines(dt_fineSpeeds$speed, dt_fineSpeeds$batteryPctPerHour_total, lwd=lwd_nonlinear, lty=lty_power_total, col=col_power_total)
    lines(dt_fineSpeeds$speed, dt_fineSpeeds$batteryPctPerHour_drag, lwd=lwd_nonlinear, lty=lty_power_drag, col=col_power_drag)
    lines(dt_fineSpeeds$speed, dt_fineSpeeds$batteryPctPerHour_rolling, lwd=lwd_nonlinear, lty=lty_power_rolling, col=col_power_rolling)
    lines(dt_fineSpeeds$speed, dt_fineSpeeds$batteryPctPerHour_baseline, lwd=lwd_nonlinear, lty=lty_power_baseline, col=col_power_baseline)

    L = findSlope(dt_fineSpeeds$speed, dt_fineSpeeds$batteryPctPerHour_drag, mode="fx", f=0.74)
    text(L$midX, L$midY, tprintf("Est. drag coef: ~dragCoef@,  web: ~coefDrag@"), adj=c(0, 1.2), cex=0.7)
    L = findSlope(dt_fineSpeeds$speed, dt_fineSpeeds$batteryPctPerHour_rolling, mode="fx", f=1)
    text(L$rightX, L$rightY, tprintf("Est. rolling resist. coef: ~rollingCoef@,  web: ~coefRolling@"), adj=c(0.9, -0.2), cex=0.7)
    L = findSlope(dt_fineSpeeds$speed, dt_fineSpeeds$batteryPctPerHour_baseline, mode="fx", f=0.6)
    text(L$midX, L$midY, tprintf("Est. baseline power (climate off): ~baselinePower_kW@ kW"), adj=c(0, -0.2), cex=0.7)

    legend_args = list(
        txt=c(
            tprintf("Power = Speed x ~energy_use@ (as measured)   ", apx$Speed_BatteryPctPerHour_total$text),
            "3rd-order approximation for Total Power",
            "Drag portion of Total Power",
            "Rolling resistance portion of Total Power",
            "Baseline portion of Total Power"),
        col=c(col_derived_data, col_power_total, col_power_drag, col_power_rolling, col_power_baseline),
        lwd=c(lwd_derived_data, lwd_nonlinear, lwd_nonlinear, lwd_nonlinear, lwd_nonlinear),
        lty=c(lty_derived_data, lty_power_total, lty_power_drag, lty_power_rolling, lty_power_baseline),
        pch=c(pch_derived_data, NA, NA, NA, NA))
    legend_args = addLegendArgsForDataPointNotes(legend_args)
    legend("topleft", legend_args$txt, col=legend_args$col,
        lwd=legend_args$lwd, lty=legend_args$lty, pch=legend_args$pch, seg.len=4, cex=0.7)
    }

if (plotToQuartz) plotCT_PvsS()

################################################################################
# Plot estimated range based on battery with degradation at different speeds.
# Add TWO right-side y-axes to show distance per battery percent and distance
# per kWh. All of these are proportional to one another.
################################################################################

# R = range, DC = distance per consumed battery percent, DE = distance per unit energy, S = speed
plotR_DC_DEvsS = function(isPDF=FALSE)
    {
    xlim = c(0, max_fineSpeed)
    xaxp = c(xlim, nTicks_fineSpeed)
    ylim_left = c(0, maxRange_fineSpeed)
    yaxp_left = c(ylim_left, nTicksRange_fineSpeed)
    ylim_right_1 = c(0, maxDistPerBattery1pct_fineSpeed)
    yaxp_right_1 = c(ylim_right_1, nTicksDistPerBattery1pct_fineSpeed)
    ylim_right_2 = c(0, maxDistPer_kWh_fineSpeed)
    yaxp_right_2 = c(ylim_right_2, nTicksDistPer_kWh_fineSpeed)

    svpar = par(mai=par("mai")+c(0, 0.1, 0, 1.0), mgp=c(2.75, 0.75, 0))

    plot(NA, type='n', xlim=xlim, xaxp=xaxp, ylim=ylim_left, yaxp=yaxp_left, las=2, main="",
        xlab=tprintf("Speed on flat road (~speed@)"),
        ylab=tprintf("Range of full battery (~dist_long_plural@)"))
    title(tprintf("Estimated range at various speeds"), line=3.75, cex.main=1.1)
    cex = 0.75
    mtext(paste0("This shows points computed from raw data, and includes linear and derived approximations.\n",
        makeStringList("~EVdesc@", "~conditions@", "~battDeg@", "~SOC100@",
        apx$Speed_TotalPower$textplus, cex=cex)),
        side=3, line=0.4, adj=0, cex=cex)

    # Right-side y-axis 1.
    labels = pretty.good2(ylim_right_1, yaxp_right_1[3])
    at = labels * scale_DistPerBatteryPct_to_Range
    axis(side=4, at=at, labels=labels, las=2, cex.axis=0.8)
    mtext(tprintf("~battery_eff@"), side=4, line=1.75, cex=0.8)

    # Right-side y-axis 2.
    at = pretty.good2(ylim_left, yaxp_left[3])
    axis(side=4, line=4, at=at, labels=FALSE, col.ticks="darkgray", tcl=1)
    labels = pretty.good2(ylim_right_2, yaxp_right_2[3])
    at = labels * scale_DistPer_kWh_to_Range
    axis(side=4, line=4, at=at, labels=labels, las=2, cex.axis=0.8)
    mtext(tprintf("~energy_eff@"), side=4, line=5.75, cex=0.8)

    par(xaxp=xaxp)
    par(yaxp=yaxp_left)
    grid(lwd=lwd_grid, lty=lty_grid, col=col_grid)

    lines(dt$speed, dt$range, lwd=lwd_derived_data, lty=lty_derived_data, col=col_derived_data)
    ind = dt$isEstimate_dir1 | dt$isEstimate_dir2
    points(dt$speed[!ind], dt$range[!ind], pch=pch_derived_data, col=col_derived_data)
    if (any(ind))
        points(dt$speed[ind], dt$range[ind], pch=pch_change_data, col=col_change_data)
    ind = dta$addForApproximation
    if (any(ind))
        points(dta$speed[ind], dta$range[ind], pch=pch_est_data, col=col_est_data)

    lines(dt_fineSpeeds$speed, dt_fineSpeeds$range, lwd=lwd_nonlinear, lty=lty_nonlinear, col=col_nonlinear)
    lines(dt_fineSpeeds$speed, dt_fineSpeeds$range_linear, lwd=lwd_linear, lty=lty_linear, col=col_linear)

    legend_args = list(
        txt=c(
            tprintf("Range = batteryCapacity_Wh / ~energy_use@    ~battery_eff@=Range/100    ~energy_eff@=1000 / ~energy_use@"),
            tprintf("Fine approx: ", apx$Speed_Range$textplus),
            tprintf("Linear approx: ", apx$Speed_Range_linear$text)),
        col=c(col_derived_data, col_nonlinear, col_linear),
        lwd=c(lwd_derived_data, lwd_nonlinear, lwd_linear),
        lty=c(lty_derived_data, lty_nonlinear, lty_linear),
        pch=c(pch_derived_data, NA, NA))
    legend_args = addLegendArgsForDataPointNotes(legend_args)
    legend("bottomleft", legend_args$txt, col=legend_args$col,
        lwd=legend_args$lwd, lty=legend_args$lty, pch=legend_args$pch, seg.len=4, cex=0.5)
    }

if (plotToQuartz) plotR_DC_DEvsS()

################################################################################
# Plot % battery per unit distance and watt-hours per unit distance at different speeds.
################################################################################

# CD = battery charge used per unit distance, ED = energy per unit distance, S = speed
plotCD_EDvsS = function(isPDF=FALSE)
    {
    xlim = c(0, max_fineSpeed)
    xaxp = c(xlim, nTicks_fineSpeed)
    ylim_left = c(0, maxBatteryPctPerDist_fineSpeed)
    yaxp_left = c(ylim_left, nTicksBatteryPctPerDist_fineSpeed)
    ylim_right = c(0, maxWhPerDist_fineSpeed)
    yaxp_right = c(ylim_right, nTicksWhPerDist_fineSpeed)

    svpar = par(mai=par("mai")+c(0, 0.1, 0.25, 0.6), mgp=c(2.5, 0.75, 0))

    plot(NA, type='n', xlim=xlim, xaxp=xaxp, ylim=ylim_left, yaxp=yaxp_left, las=2, main="",
        xlab=tprintf("Speed on flat road (~speed@)"),
        ylab=tprintf("Battery drain (~battery_use@)"))
    title(tprintf("Energy used per ~dist_long@ at various speeds"), line=3.75, cex.main=1.1)
    cex = 0.75
    mtext(paste0("This shows raw (measured) data and an approximation curve.\n",
        makeStringList("~EVdesc@", "~conditions@", "~battDeg@", "~SOC100@",
        apx$Speed_TotalPower$textplus, cex=cex)),
        side=3, line=0.4, adj=0, cex=cex)

    # Right-side y-axis.
    labels = pretty.good2(ylim_right, yaxp_right[3])
    at = labels * scale_Wh_to_BatteryPct
    axis(side=4, at=at, labels=labels, las=2)
    mtext(tprintf("Energy drain (~energy_use@)"), side=4, line=2.5)

    par(xaxp=xaxp)
    par(yaxp=yaxp_left)
    grid(lwd=lwd_grid, lty=lty_grid, col=col_grid)

    lines(dt$speed, dt$batteryPctPerDist, lwd=lwd_derived_data, lty=lty_derived_data, col=col_derived_data)
    points(dt$speed, dt$batteryPctPerDist, pch=pch_derived_data, col=col_derived_data)
    lines(dt$speed, dt$batteryPctPerDist_dir1, lwd=lwd_raw_data, lty=lty_raw_data_top, col=col_raw_data)
    ind = dt$isEstimate_dir1
    points(dt$speed[!ind], dt$batteryPctPerDist_dir1[!ind], pch=pch_raw_data, col=col_raw_data)
    if (any(ind))
        points(dt$speed[ind], dt$batteryPctPerDist_dir1[ind], pch=pch_change_data, col=col_change_data)
    lines(dt$speed, dt$batteryPctPerDist_dir2, lwd=lwd_raw_data, lty=lty_raw_data_bottom, col=col_raw_data)
    ind = dt$isEstimate_dir2
    points(dt$speed[!ind], dt$batteryPctPerDist_dir2[!ind], pch=pch_raw_data, col=col_raw_data)
    if (any(ind))
        points(dt$speed[ind], dt$batteryPctPerDist_dir2[ind], pch=pch_change_data, col=col_change_data)
    ind = dta$addForApproximation
    if (any(ind))
        points(dta$speed[ind], dta$batteryPctPerDist[ind], pch=pch_est_data, col=col_est_data)

    lines(dt_fineSpeeds$speed, dt_fineSpeeds$batteryPctPerDist, lwd=lwd_nonlinear, lty=lty_nonlinear, col=col_nonlinear)

    legend_args = list(
        txt=c(
            tprintf("~energy_use@ measured going one way"),
            tprintf("Average ~energy_use@    (~battery_use@ = 100  ~energy_use@ / batteryCapacity_Wh)"),
            tprintf("~energy_use@ measured going back the opposite way"),
            paste0("Fine approx: ", apx$Speed_BatteryPctPerDist$textplus)),
        col=c(col_raw_data, col_derived_data, col_raw_data, col_nonlinear),
        lwd=c(lwd_raw_data, lwd_derived_data, lwd_raw_data, lwd_nonlinear),
        lty=c(lty_raw_data_top, lty_derived_data, lty_raw_data_bottom, lty_nonlinear),
        pch=c(pch_raw_data, pch_derived_data, pch_raw_data, NA))
    legend_args = addLegendArgsForDataPointNotes(legend_args)
    legend("top", legend_args$txt, col=legend_args$col,
        lwd=legend_args$lwd, lty=legend_args$lty, pch=legend_args$pch, seg.len=4, cex=0.6)
    }

if (plotToQuartz) plotCD_EDvsS()

################################################################################
# Plot Howard Johnson's dist_per_cost (distance per unit currency).
################################################################################

# DPM = distance per money, S = speed
plotDPMvsS = function(isPDF=FALSE)
    {
    xlim = c(0, max_fineSpeed)
    xaxp = c(xlim, nTicks_fineSpeed)
    ylim_left = c(0, maxDistPerCost_fineSpeed)
    yaxp_left = c(ylim_left, nTicksDistPerCost_fineSpeed)
    ylim_right = c(0, maxDistPerUnitFuel_fineSpeed_1)
    yaxp_right = c(ylim_right, nTicksDistPerUnitFuel_fineSpeed_1)

    svpar = par(mai=par("mai")+c(0, 0.1, 0.5, 0.6), mgp=c(2.5, 0.75, 0))

    plot(NA, type='n', xlim=xlim, xaxp=xaxp, ylim=ylim_left, yaxp=yaxp_left, las=2, main="",
        xlab=tprintf("Speed on flat road (~speed@)"),
        ylab=tprintf("~dist_per_cost_long` (~dist_per_cost@)"))
    title(tprintf("~dist_per_cost_long` at various speeds compared to fuel vehicle"), line=4.25, cex.main=1.1)
    cex = 0.75
    mtext(makeStringList("~EVdesc@", "~conditions@", "~battDeg@", "~SOC100@",
        "~electCost@", "~fuelCost@", "~fuelDistPerFuelVol@",
        apx$Speed_TotalPower$textplus, cex=cex),
        side=3, line=0.3, adj=0, cex=cex)

    # Right-side y-axis.
    labels = pretty.good2(ylim_right, yaxp_right[3])
    at = labels * scaleDistPerUnitFuel_to_DistPerCost_fineSpeed
    axis(side=4, at=at, labels=labels, las=2)
    mtext(tprintf("Fuel consumption (~fuel_eff@)"), side=4, line=2.5)

    par(xaxp=xaxp)
    par(yaxp=yaxp_left)
    grid(lwd=lwd_grid, lty=lty_grid, col=col_grid)

    # Electricity and fuel dist_per_cost at speeds.
    points(dt$speed, dt$electDistPerCost, pch=pch_elect, col=col_derived_data)
    lines(dt_fineSpeeds$speed, dt_fineSpeeds$electDistPerCost, lty=lty_dist, lwd=lwd_elect, col=col_elect)
    lines(dt_fineSpeeds$speed, dt_fineSpeeds$fuelDistPerCost, lty=lty_dist, lwd=lwd_fuel, col=col_fuel)

    # Plotting DistPerUnitFuel means translating from the desired right-side y-axis to the left-side y-axis
    # used in plotting.
    DistPerUnitFuel = dt_fineSpeeds$distPerUnitFuel * scaleDistPerUnitFuel_to_DistPerCost_fineSpeed
    lines(dt_fineSpeeds$speed, DistPerUnitFuel, col=col_dist_per_fuel, lty=lty_dist_per_fuel, lwd=lwd_dist_per_fuel)

    # Legend.
    legend("bottom",
        legend=c(
            tprintf("Elect measured ~dist_per_cost@ = 1000/(avgElecCostPer_kWh * ~energy_use@)"),
            tprintf("Elect est ", apx$Speed_DistPerUnitCost$text, ", S=Speed, P=total power approx."),
            tprintf("Fuel est ~fuel_eff@ (right-side axis)"),
            tprintf("Fuel est ~dist_per_cost@")),
        col=c(col_derived_data, col_elect, col_dist_per_fuel, col_fuel),
        lwd=c(NA, lwd_elect, lwd_dist_per_fuel, lwd_fuel),
        lty=c(NA, lty_dist, lty_dist_per_fuel, lty_dist),
        pch=c(pch_derived_data, NA, NA, NA),
        seg.len=4, cex=0.55)

    par(svpar)
    }

if (plotToQuartz) plotDPMvsS()

################################################################################
# Plot inverse of previous left-side y-axis.
################################################################################

# MPD = money per distance, S = speed
plotMPDvsS = function(isPDF=FALSE)
    {
    xlim = c(0, max_fineSpeed)
    xaxp = c(xlim, nTicks_fineSpeed)
    ylim_left = c(0, maxCostPerDist_fineSpeed)
    yaxp_left = c(ylim_left, nTicksCostPerDist_fineSpeed)
    ylim_right = c(0, maxDistPerUnitFuel_fineSpeed_2)
    yaxp_right = c(ylim_right, nTicksDistPerUnitFuel_fineSpeed_2)

    svpar = par(mai=par("mai")+c(0, 0.1, 0.5, 0.6), mgp=c(2.5, 0.75, 0))

    plot(NA, type='n', xlim=xlim, xaxp=xaxp, ylim=ylim_left, yaxt='n', las=2, main="",
        xlab=tprintf("Speed on flat road (~speed@)"),
        ylab="")
    title(tprintf("~cost_per_dist_long` at various speeds compared to fuel vehicle"), line=4.25, cex.main=1.1)
    cex = 0.75
    mtext(makeStringList("~EVdesc@", "~conditions@", "~battDeg@", "~SOC100@",
        "~electCost@", "~fuelCost@", "~fuelDistPerFuelVol@",
        apx$Speed_TotalPower$textplus, cex=cex, colPcts=c(0, 45)),
        side=3, line=0.3, adj=0, cex=cex)

    # Left-side y-axis.
    at = pretty.good2(ylim_left, yaxp_left[3])
    labels = sprintf(tprintf("~currency@%4.2f"), at)
    axis(side=2, at=at, labels=labels, las=2)
    mtext(tprintf("~cost_per_dist_long` (~cost_per_dist@)"), side=2, line=3.5)

    # Right-side y-axis.
    labels = pretty.good2(ylim_right, yaxp_right[3])
    at = labels * scaleDistPerUnitFuel_to_CostPerDist_fineSpeed
    axis(side=4, at=at, labels=labels, las=2)
    mtext(tprintf("Fuel consumption (~fuel_eff@)"), side=4, line=2.5)

    par(xaxp=xaxp)
    par(yaxp=yaxp_left)
    grid(lwd=lwd_grid, lty=lty_grid, col=col_grid)

    # Electricity and fuel dist_per_cost at speeds.
    points(dt$speed, dt$electCostPerDist, pch=pch_elect, col=col_derived_data)
    lines(dt_fineSpeeds$speed, dt_fineSpeeds$electCostPerDist, col=col_elect, lty=lty_dist, lwd=lwd_elect)
    lines(dt_fineSpeeds$speed, dt_fineSpeeds$fuelCostPerDist, col=col_fuel, lty=lty_dist, lwd=lwd_fuel)

    # Plotting DistPerUnitFuel means translating from the desired right-side y-axis to the left-side y-axis
    # used in plotting.
    DistPerUnitFuel = dt_fineSpeeds$distPerUnitFuel * scaleDistPerUnitFuel_to_CostPerDist_fineSpeed
    lines(dt_fineSpeeds$speed, DistPerUnitFuel, col=col_dist_per_fuel, lty=lty_dist_per_fuel, lwd=lwd_dist_per_fuel)

    # Legend.
    legend("topright",
        legend=c(
            tprintf("Fuel est ~fuel_eff@ (right-side axis)"),
            tprintf("Fuel est ~dist_per_cost@"),
            tprintf("Elect measured ~cost_per_dist@ = avgElecCostPer_kWh * ~energy_use@ / 1000"),
            tprintf("Elect est ", apx$Speed_CostPerUnitDist$text, ", S=Speed, P=total power approx.")),
        col=c(col_dist_per_fuel, col_fuel, col_derived_data, col_elect),
        lwd=c(lwd_dist_per_fuel, lwd_fuel, NA, lwd_elect),
        lty=c(lty_dist_per_fuel, lty_dist, NA, lty_dist),
        pch=c(NA, NA, pch_elect, NA),
        seg.len=4, cex=ifelse(isPDF, 0.6, 0.7))

    par(svpar)
    }

if (plotToQuartz) plotMPDvsS()

################################################################################
# Plot cost per big distance and per hour of driving, at different speeds,
# assuming a kWh price and a gasoline price and mileage.
################################################################################

# M = money, S = speed
plotMvsS = function(isPDF=FALSE)
    {
    xlim = c(0, max_fineSpeed)
    xaxp = c(xlim, nTicks_fineSpeed)
    ylim_left = c(0, maxCostForDistHours_fineSpeed)
    yaxp_left = c(ylim_left, nTicksCostForDistHours_fineSpeed)
    ylim_right = c(0, maxDistPerUnitFuel_fineSpeed_3)
    yaxp_right = c(ylim_right, nTicksDistPerUnitFuel_fineSpeed_3)

    svpar = par(mai=par("mai")+c(0, 0.1, 0.5, 0.6), mgp=c(2.5, 0.75, 0))

    plot(NA, type='n', xlim=xlim, xaxp=xaxp, ylim=ylim_left, yaxt='n', las=2, main="",
        xlab=tprintf("Speed on flat road (~speed@)"),
        ylab="")
    title(tprintf("Cost in ~currency_long@ per ~compEnergyCostDist@ or ~compEnergyCostHours@",
        " at various speeds compared to fuel vehicle"),
        line=4.25, cex.main=1.1)
    cex = 0.75
    mtext(makeStringList("~EVdesc@", "~conditions@", "~battDeg@", "~SOC100@",
        "~electCost@", "~fuelCost@", "~fuelDistPerFuelVol@",
        apx$Speed_TotalPower$textplus, cex=cex),
        side=3, line=0.3, adj=0, cex=cex)

    # Left-side y-axis.
    at = pretty.good2(ylim_left, yaxp_left[3])
    labels = sprintf(tprintf("~currency@%2.0f"), at)
    axis(side=2, at=at, labels=labels, las=2)
    mtext(tprintf("Cost (~currency@)"), side=2, line=3.25)

    # Right-side y-axis.
    labels = pretty.good2(ylim_right, yaxp_right[3])
    at = labels * scaleDistPerUnitFuel_to_CostForDistHours_fineSpeed
    axis(side=4, at=at, labels=labels, las=2)
    mtext(tprintf("Fuel consumption (~fuel_eff@)"), side=4, line=2.5)

    par(xaxp=xaxp)
    par(yaxp=yaxp_left)
    grid(lwd=lwd_grid, lty=lty_grid, col=col_grid)

    # Electricity and fuel costs at speeds for distance driven and time driven.
    points(dt$speed, dt$electCostForFixedDist, pch=pch_elect, col=col_derived_data)
    lines(dt_fineSpeeds$speed, dt_fineSpeeds$electCostForFixedDist, col=col_elect, lty=lty_dist, lwd=lwd_elect)
    lines(dt_fineSpeeds$speed, dt_fineSpeeds$fuelCostForFixedDist, col=col_fuel, lty=lty_dist, lwd=lwd_fuel)
    points(dt$speed, dt$electCostForFixedTime, pch=pch_elect, col=col_derived_data)
    lines(dt_fineSpeeds$speed, dt_fineSpeeds$electCostForFixedTime, col=col_elect, lty=lty_time, lwd=lwd_elect)
    lines(dt_fineSpeeds$speed, dt_fineSpeeds$fuelCostForFixedTime, col=col_fuel, lty=lty_time, lwd=lwd_fuel)

    # Plotting DistPerUnitFuel means translating from the desired right-side y-axis to the left-side y-axis
    # used in plotting.
    DistPerUnitFuel = round(dt_fineSpeeds$distPerUnitFuel * scaleDistPerUnitFuel_to_CostForDistHours_fineSpeed, 3)
    lines(dt_fineSpeeds$speed, DistPerUnitFuel, col=col_dist_per_fuel, lty=lty_dist_per_fuel, lwd=lwd_dist_per_fuel)

    # Legend.
    legend("topright",
        legend=c(
            tprintf("Fuel est ~fuel_eff@ (right-side axis)"),
            tprintf("Fuel est ~currency@ to go ~compEnergyCostDist@"),
            tprintf("Fuel est ~currency@ per ~compEnergyCostHours@"),
            tprintf("Elect est ", apx$Speed_CostForFixedDist$text, ", S=Speed, P=total power approx."),
            tprintf("Elect est ~currency@ per ~compEnergyCostHours@")),
        col=c(col_dist_per_fuel, col_fuel, col_fuel, col_derived_data, col_elect),
        lty=c(lty_dist_per_fuel, lty_dist, lty_time, lty_dist, lty_time),
        lwd=c(lwd_dist_per_fuel, lwd_fuel, lwd_fuel, lwd_elect, lwd_elect),
        pch=c(NA, NA, NA, pch_derived_data, pch_elect), seg.len=4, cex=0.6)

    if (!isPDF)
        par(svpar)
    }

if (plotToQuartz) plotMvsS()

################################################################################
# I want to be able to quickly answer the question: If I drive at X mph
# and have Y % charge available, how far can I go? Those three parameters
# can be plotted six different ways. The question might be worded
# differently: If I have X miles to drive and drive at Y mph, what %
# charge will I use? There are three different questions that can be
# asked. The third is: If I have X % charge available and I want to drive
# Y miles, how fast can I go? Any of the six graphs can answer any of the
# three questions, depending on how you use the graph. I want to figure
# out which question is most likely, and which plot is most useful. Time
# is also of importance, and it can be determined from any two of speed,
# distance travelled, and % charge used. So, there can be two sets of
# curves plotted, using two different colors for the curve sets. The
# curves allow you to see at a glance how one parameter (Y-axis) changes
# as another (X-axis) is changed. So, we need to decide which parameter
# will be X-axis, which will be Y-axis, and which two will be the sets of
# curves, out of these four parameters: - Distance travelled D - Total
# elapsed time T - Speed S - Percent charge used C
#
# If the X-axis is assigned to parameter x, Y-axis to parameter y, and the
# curve sets to parameters p1 and p2, then we require functions of this
# sort to compute the plotted curves: y = f1(x, p1) y = f2(x, p2) We know
# functions f() and g() that let us compute: D = f(S, C) T = g(S, C) We
# see that we don't have the necessary two different functions f1() and
# f2() whose second argument is a different parameter. An alternative is
# to use two Y-axes, on the left and right sides. In that case, the two
# sets of plotted curves would both use the same parameter to distinguish
# between each curve in the set. Then we COULD use our f() and g()
# functions. C could be assigned to the X-axis, D to the left-side Y-axis,
# and T to the right-side Y-axis, leaving S as the parameter that varies
# between each curve in each curve set. I don't really like that solution
# because I don't want to have two axes and I'd rather have the two sets
# of curves use different parameters to distinguish the curves. Ideally
# I'd like one set of curves to use D and the other to use T, so that S
# and C are on the X- and Y-axes respectively. But to do that we would
# need to invert f() and g(): C = f'(S, D) C = g'(S, T) Unfortunately, the
# curves are not quite monotonic, see the points at 25, 30, and 35 mph in
# the first plot above. But, if we delete the 25 mph point, it IS
# monotonic, and the 25 mph point indicates that energy consumption goes
# UP if you slow down too much, so it is safe to ignore that point anyway.
# So we can do the function inversion. But there is still a problem. We
# want the D and T values of the curves to be round numbers, not the
# oddball numbers they happen to be in the data. Here's how we can deal
# with the oddball numbers. The value of C directly scales the values of D
# and T. So, we use speed S from table for each S (X-axis), get the D and
# T for each S, then we can compute f'() and g'() as follows: For D: 1.
# From the table we have distance and speed values d and S, where d is an
# oddball value, and this is for C = 100% 2. For an arbitrary C, the
# corresponding D is D = d*C/100 3. Likewise, for an arbitrary
# (non-oddball) value of D, the corresponding C is C = 100*D/d For T: 1.
# From the table we have time and speed values t and S, where t is an
# oddball value, and this is for C = 100% 2. For an arbitrary C, the
# corresponding T is T = t*C/100 3. Likewise, for an arbitrary
# (non-oddball) value of T, the corresponding C is C = 100*T/t
#
# After making a plot with two separate sets of curves using two colors, I
# decided it was too crowded, so I changed it to make two separate plots.
#
# D is in the range 191 to 440 miles, and if C = 5% the lower end becomes
# about 9 miles. A nice set of D values for plotting would be seq(25, 400,
# by=25) = 18 curves.
#
# This was enhanced to show battery energy on the right y-axis, since it is
# directly proportional to state-of-charge.
################################################################################

# D = distance, S = speed, C = battery percent charge used, E = battery energy
plotDvsSCE = function(isPDF=FALSE)
    {
    # Choose a nice set of distances for the multi-line battery plot with one line for each distance, then compute a battery
    # percent used for each speed and distance. We want the shortest to be a trip of maybe 25 miles or 50 km and the maximum
    # to be maybe about 80% of maxRange_fineSpeed rounded to a multiple of the shortest distance, and we want the spacing between
    # them to be the same as the shortest distance.
    minDist = ifelse(useMetricInPlots, 50, 25)
    maxDist = ifelse(useMetricInPlots, 700, 425)
    dists = seq(minDist, maxDist, length.out=maxDist/minDist)
    mtxBatteryPct = matrix(NA, nrow=length(dt_fineSpeeds$speed), ncol=length(dists),
        dimnames=list(as.character(dt_fineSpeeds$speed), as.character(dists)))
    for (dist in dists)
        mtxBatteryPct[, as.character(dist)] = round(dist*dt_fineSpeeds$batteryPctPerDist, 3)
    mtxBatteryPct[mtxBatteryPct > 100] = NA
    # Eliminate any column of mtxBatteryPct that has fewer than 2 non-NA's.
    ind = apply(mtxBatteryPct, 2, function(V) sum(!is.na(V)) >= 2)
    mtxBatteryPct = mtxBatteryPct[, ind]

    xlim = c(0, max_fineSpeed)
    xaxp = c(xlim, nTicks_fineSpeed)
    ylim_left = c(0, maxSOCpct_axis)
    yaxp_left = c(ylim_left, nTicksSOCpct_axis)
    ylim_right = c(0, maxBatteryEnergy_fineSpeed)
    yaxp_right = c(ylim_right, nTicksBatteryEnergy_fineSpeed)

    svpar = par(mai=par("mai")+c(0, 0.1, 0.2, 0.6), mgp=c(2.5, 0.75, 0))

    plot(NA, type='n', xlim=xlim, xaxp=xaxp, ylim=ylim_left, yaxp=yaxp_left, las=2, main="",
        xlab=tprintf("Speed on flat road (~speed@)"),
        ylab=tprintf("Battery used (%)"))
    title(tprintf("Energy used at various speeds and distances"), line=3.0, cex.main=1.1)
    cex = 0.75
    mtext(makeStringList("~battDeg@", "~SOC100@",
        c("Fine approx: ", apx$Speed_BatteryPctPerDist$text),
        apx$Speed_TotalPower$textplus, cex=cex, colPcts=c(0, 54)),
        side=3, line=0.3, adj=0, cex=cex)

    # Right-side y-axis.
    labels = pretty.good2(ylim_right, yaxp_right[3])
    at = labels * scaleBatteryEnergy_to_SOCpct
    axis(side=4, at=at, labels=labels, las=2)
    mtext(tprintf("Energy consumption (~energy@)"), side=4, line=2.5)

    par(xaxp=xaxp)
    par(yaxp=yaxp_left)
    grid(lwd=lwd_grid, lty=lty_grid, col=col_grid)

    for (dist in colnames(mtxBatteryPct))
        {
        lines(dt_fineSpeeds$speed, mtxBatteryPct[,dist], lwd=lwd_derived_data_many, col=col_derived_data)
        L = findSlope(dt_fineSpeeds$speed, mtxBatteryPct[,dist], mode="0")
        text(L$midX, L$midY, epaste(dist, tprintf("*' ~distance@'")),
            srt=L$slope, adj=c(0.5, -0.4), cex=0.7)
        }
    par(svpar)
    }

if (plotToQuartz) plotDvsSCE()

################################################################################
# Now the same thing except plot elapsed time curves instead of distance curves.
#
# T is in the range 2.5 to 17.5 hours, and if C = 5% the lower end becomes
# about 1/8 hour. A nice set of T values for plotting would be seq(1, 16)
# = 16 curves. Actually, I don't like that. We want at least 30 minutes
# resolution. And 16 hours is way too much. How about seq(0.5, 10, by=0.5)
# = 20 curves. But after looking at it, we want 15-minute resolution below
# 3 hours, and only 1 hour resolution above 5 hours. Use c(seq(0.25, 3,
# by=0.25), seq(3.5, 5, by=0.5), seq(6, 10, by=1)) = 21 curves.
################################################################################

# T = hour, S = speed, C = battery use in percent, E = battery energy use
plotTvsSCE = function(isPDF=FALSE)
    {
    # Choose a nice set of elapsed hours for multi-line battery plot with one line for each elapsed hours, then compute
    # a matrix of battery pecgeth used for each speed and elapsed hours. These have irregular spacing because it looks
    # better on the plot.
    elapsedHours = c(seq(0.25, 3, by=0.25), seq(3.5, 5, by=0.5), seq(6, 10, by=1))
    mtxBatteryPct = matrix(NA, nrow=length(dt_fineSpeeds$speed), ncol=length(elapsedHours),
        dimnames=list(as.character(dt_fineSpeeds$speed), as.character(elapsedHours)))
    for (hours in elapsedHours)
        mtxBatteryPct[, as.character(hours)] = round(hours*dt_fineSpeeds$batteryPctPerHour_total, 3)
    mtxBatteryPct[mtxBatteryPct > 100] = NA
    # Eliminate any column that has fewer than 2 non-NA's.
    ind = apply(mtxBatteryPct, 2, function(V) sum(!is.na(V)) >= 2)
    mtxBatteryPct = mtxBatteryPct[, ind]

    xlim = c(0, max_fineSpeed)
    xaxp = c(xlim, nTicks_fineSpeed)
    ylim_left = c(0, maxSOCpct_axis)
    yaxp_left = c(ylim_left, nTicksSOCpct_axis)
    ylim_right = c(0, maxBatteryEnergy_fineSpeed)
    yaxp_right = c(ylim_right, nTicksBatteryEnergy_fineSpeed)

    svpar = par(mai=par("mai")+c(0, 0.1, 0.2, 0.6), mgp=c(2.5, 0.75, 0))

    plot(NA, type='n', xlim=xlim, xaxp=xaxp, ylim=ylim_left, yaxp=yaxp_left, las=2, main="",
        xlab=tprintf("Speed on flat road (~speed@)"),
        ylab=tprintf("Battery used (%)"))
    title(tprintf("Energy used at various speeds and times"), line=3.0, cex.main=1.1)
    cex = 0.75
    mtext(makeStringList("~battDeg@", "~SOC100@",
        c("Fine approx: ", apx$Speed_BatteryPctPerHour_total$text),
        apx$Speed_TotalPower$textplus, cex=cex, colPcts=c(0, 54)),
        side=3, line=0.3, adj=0, cex=cex)

    # Right-side y-axis.
    labels = pretty.good2(ylim_right, yaxp_right[3])
    at = labels * scaleBatteryEnergy_to_SOCpct
    axis(side=4, at=at, labels=labels, las=2)
    mtext(tprintf("Energy consumption (~energy@)"), side=4, line=2.5)

    par(xaxp=xaxp)
    par(yaxp=yaxp_left)
    grid(lwd=lwd_grid, lty=lty_grid, col=col_grid)

    for (hours in colnames(mtxBatteryPct))
        {
        lines(dt_fineSpeeds$speed, mtxBatteryPct[,hours], lwd=lwd_derived_data_many, col=col_derived_data)
        L = findSlope(dt_fineSpeeds$speed, mtxBatteryPct[,hours], mode='f', f=1)
        text(L$midX, L$midY, epaste(hours, "*' hrs'"), srt=L$slope, adj=c(1, -0.1), cex=0.7)
        }
    par(svpar)
    }

if (plotToQuartz) plotTvsSCE()

################################################################################
# Plot the previous in a different way, swapping the X-axis and curve parameters.
################################################################################

# S = speed, D = distance, C = battery use in percent, E = battery energy use, E = battery energy use
plotSvsDCE = function(isPDF=FALSE)
    {
    # Even though these are straight lines we are plotting, nevertheless compute them at many points so we can
    # search those points for a good place to put the speed label, and so they will extend to the limit of 100%.
    mtxBattery = matrix(NA, nrow=length(speeds_batteryPlots), ncol=length(fineDists),
        dimnames=list(as.character(speeds_batteryPlots), as.character(fineDists)))
    for (dist in fineDists)
        mtxBattery[, as.character(dist)] = round(dist*dt_fineSpeeds$batteryPctPerDist[idxs_speeds_batteryPlots], 3)
    # Speeds below a certain point start to increase battery charge used over a slightly larger speed, so
    # the curves will lie on top of higher-speed curves. Discard rows of mtxBattery if last entry is not larger
    # than last entry of preceding row.
    ind = c(mtxBattery[-1, ncol(mtxBattery)] > mtxBattery[-nrow(mtxBattery), ncol(mtxBattery)], TRUE)
    mtxBattery = mtxBattery[ind,]
    mtxBattery[mtxBattery > 100] = NA

    xlim = c(0, maxDist_fineSpeed)
    xaxp = c(xlim, nTicksDist_fineSpeed)
    ylim_left = c(0, maxSOCpct_axis)
    yaxp_left = c(ylim_left, nTicksSOCpct_axis)
    ylim_right = c(0, maxBatteryEnergy_fineSpeed)
    yaxp_right = c(ylim_right, nTicksBatteryEnergy_fineSpeed)

    svpar = par(mai=par("mai")+c(0, 0.1, 0.2, 0.6), mgp=c(2.5, 0.75, 0))

    plot(NA, type='n', xlim=xlim, xaxp=xaxp, ylim=ylim_left, yaxp=yaxp_left, las=2, main="",
        xlab=tprintf("Distance travelled (~dist_long_plural@)"),
        ylab=tprintf("Battery used (%)"))
    title(tprintf("Energy used at various distances and speeds"), line=3.0, cex.main=1.1)
    cex = 0.75
    mtext(makeStringList("~battDeg@", "~SOC100@",
        c("Fine approx: ", apx$Speed_BatteryPctPerDist$text),
        apx$Speed_TotalPower$textplus, cex=cex, colPcts=c(0, 54)),
        side=3, line=0.3, adj=0, cex=cex)

    # Right-side y-axis.
    labels = pretty.good2(ylim_right, yaxp_right[3])
    at = labels * scaleBatteryEnergy_to_SOCpct
    axis(side=4, at=at, labels=labels, las=2)
    mtext(tprintf("Energy consumption (~energy@)"), side=4, line=2.5)

    par(xaxp=xaxp)
    par(yaxp=yaxp_left)
    grid(lwd=lwd_grid, lty=lty_grid, col=col_grid)

    for (speed in rownames(mtxBattery))
        {
        lines(fineDists, mtxBattery[speed,], lwd=lwd_derived_data_many)
        L = findSlope(fineDists, mtxBattery[speed,], mode='f', f=1)
        text(L$midX, L$midY, epaste(speed, tprintf("*' ~speed@'")), srt=L$slope, adj=c(1, 0), cex=0.7)
        }
    par(svpar)
    }

if (plotToQuartz) plotSvsDCE()

################################################################################
# Now the same thing except X-axis is elapsed hours instead of distance.
################################################################################

# S = speed, T = hour, C = consumption, E = battery energy use
plotSvsTCE = function(isPDF=FALSE)
    {
    # Choose a nice x-axis upper limit for hours on the x-axis. Also choose a nice number of tick marks and grid
    # lines.
    maxHours = 9
    nTicks_x = maxHours

    # Even though these are straight lines we are plotting, nevertheless compute them at many points so we can
    # search those points for a good place to put the speed label, and so they will extend to the limit of 100%.
    fineHours = seq(0, maxHours, by=0.01)
    mtxBattery = matrix(NA, nrow=length(speeds_batteryPlots), ncol=length(fineHours),
        dimnames=list(as.character(speeds_batteryPlots), as.character(fineHours)))
    for (hours in fineHours)
        mtxBattery[, as.character(hours)] = round(hours*dt_fineSpeeds$batteryPctPerHour_total[idxs_speeds_batteryPlots], 3)
    mtxBattery[mtxBattery > 100] = NA

    xlim = c(0, maxHours)
    xaxp = c(xlim, nTicks_x)
    ylim_left = c(0, maxSOCpct_axis)
    yaxp_left = c(ylim_left, nTicksSOCpct_axis)
    ylim_right = c(0, maxBatteryEnergy_fineSpeed)
    yaxp_right = c(ylim_right, nTicksBatteryEnergy_fineSpeed)

    svpar = par(mai=par("mai")+c(0, 0.1, 0.2, 0.6), mgp=c(2.5, 0.75, 0))

    plot(NA, type='n', xlim=xlim, xaxp=xaxp, ylim=ylim_left, yaxp=yaxp_left, las=2, main="",
        xlab=tprintf("Elapsed time (~time_long_plural@)"),
        ylab=tprintf("Battery used (%)"))
    title(tprintf("Energy used at various times and speeds"), line=3.0, cex.main=1.1)
    cex = 0.75
    mtext(makeStringList("~battDeg@", "~SOC100@",
        c("Fine approx: ", apx$Speed_BatteryPctPerHour_total$text),
        apx$Speed_TotalPower$textplus, cex=cex, colPcts=c(0, 54)),
        side=3, line=0.3, adj=0, cex=cex)

    # Right-side y-axis.
    labels = pretty.good2(ylim_right, yaxp_right[3])
    at = labels * scaleBatteryEnergy_to_SOCpct
    axis(side=4, at=at, labels=labels, las=2)
    mtext(tprintf("Energy consumption (~energy@)"), side=4, line=2.5)

    par(xaxp=xaxp)
    par(yaxp=yaxp_left)
    grid(lwd=lwd_grid, lty=lty_grid, col=col_grid)

    for (speed in rownames(mtxBattery))
        {
        lines(fineHours, mtxBattery[speed,], lwd=lwd_derived_data_many)
        L = findSlope(fineHours, mtxBattery[speed,], mode='f', f=1)
        text(L$midX, L$midY, epaste(speed, tprintf("*' ~speed@'")), srt=L$slope, adj=c(1, 0), cex=0.7)
        }
    par(svpar)
    }

if (plotToQuartz) plotSvsTCE()

################################################################################
# Plot range as a function of speed for different levels of baseline power
# consumption.
################################################################################

# R = range, S = speed, BP = baseline power
plotR_S_BP = function(isPDF=FALSE)
    {
    # Choose the set of baseline power values (in kW) for which to plot curves.
    # Do not include 0, as the range is then infinite.
    baselinePowers = c(0.1, 0.5, 1, 2, 5, 10, 20)

    xlim = c(0, max_fineSpeed)
    xaxp = c(xlim, nTicks_fineSpeed)
    ylim = c(0, maxRange_BaselinePower_fineSpeed)
    yaxp = c(ylim, nTicksRange_BaselinePower_fineSpeed)

    svpar = par(mai=par("mai")+c(0, 0.1, 1, 0.5), mgp=c(2.5, 0.75, 0))

    plot(NA, type='n', xlim=xlim, xaxp=xaxp, ylim=ylim, yaxp=yaxp, las=2, main="",
        xlab=tprintf("Speed on flat road (~speed@)"),
        ylab=tprintf("Range of full battery (~distance@)"))
    title(tprintf("Estimated range at various speeds and baseline power levels"), line=6, cex.main=1.1)
    cex = 0.75
    mtext(makeStringList("~EVdesc@", "~conditions@", "~totalWeight@", "~coefs@",
        "~battDeg@", "~airdens@", "~effFactor@",
        "range = batt. cap. x speed / total power", "total power = baseline+rolling+drag power",
        apx$Speed_RollingPower$textplus, apx$Speed_DragPower$textplus,
        cex=cex),
        side=3, line=0.3, adj=0, cex=cex)

    par(xaxp=xaxp)
    par(yaxp=yaxp)
    grid(lwd=lwd_grid, lty=lty_grid, col=col_grid)

    # Plot a curve for each baseline power level.
    for (baselinePower in baselinePowers)
        {
        totalPower = baselinePower + rollingPower_fineSpeeds + dragPower_fineSpeeds
        ranges = basicData_plot$batteryCapacity_kWh*fineSpeeds/totalPower
        lines(fineSpeeds, ranges, lwd=1, col=col_range)
        L = findSlope(fineSpeeds, ranges, mode="0")
        text(L$midX, L$midY, paste0("BP = ", baselinePower, " kW"), adj=c(0.5, -0.3), cex=0.7)
        }

    legend("topright", "BP = baseline power level")
    par(svpar)
    }

if (plotToQuartz) plotR_S_BP()

################################################################################
# Plot maximum range and the speed at which it is achieved, for different levels
# of baseline power consumption.
################################################################################

# R = range, S = speed, BP = baseline power
plotRS_BP = function(isPDF=FALSE)
    {
    # Choose a nice x-axis upper limit for baseline power (in kW) on the x-axis.
    # Also choose a nice number of tick marks and grid lines.
    maxBaselinePower = 20
    nTicks_x = maxBaselinePower
    scale_speed_to_baseline_power = maxBaselinePower/max_fineSpeed

    # Choose the set of baseline power values (in kW) at which to compute
    # maximum range and speed at which it is obtained. Do not include 0, as the
    # range is then infinite.
    baselinePowers = seq(0.1, maxBaselinePower, by=0.1)

    # Compute maximum range and speed at which it is achieved, for different
    # levels of baseline power. Get total power by adding the baseline power
    # to the rolling and drag power as computed from the rolling and drag
    # coefficients.
    maxRange = speedAtMaxRange = setNames(rep(NA, length(baselinePowers)), as.character(baselinePowers))
    for (baselinePower in baselinePowers)
        {
        totalPower = baselinePower + rollingPower_fineSpeeds + dragPower_fineSpeeds
        ranges = basicData_plot$batteryCapacity_kWh*fineSpeeds/totalPower
        idx = which.max(ranges)
        maxRange[as.character(baselinePower)] = ranges[idx]
        speedAtMaxRange[as.character(baselinePower)] = fineSpeeds[idx]
        }

    xlim = c(0, maxBaselinePower)
    xaxp = c(xlim, nTicks_x)
    ylim_left = c(0, maxRange_BaselinePower_fineSpeed)
    yaxp_left = c(ylim_left, nTicksRange_BaselinePower_fineSpeed)
    ylim_right = c(0, maxSpeed_BaselinePower_fineSpeed)
    yaxp_right = c(ylim_right, nTicksSpeed_BaselinePower_fineSpeed)

    svpar = par(mai=par("mai")+c(0, 0.1, 1, 0.5), mgp=c(2.5, 0.75, 0))

    plot(NA, type='n', xlim=xlim, xaxp=xaxp, ylim=ylim_left, yaxp=yaxp_left, las=2, main="",
        xlab=tprintf("Baseline Power (kW)"),
        ylab=tprintf("Maximum range of full battery (~distance@)"))
    title(tprintf("Estimated maximum range at speed with changing baseline power level"), line=6, cex.main=1.1)
    cex = 0.75
    mtext(makeStringList("~EVdesc@", "~conditions@", "~totalWeight@", "~coefs@",
        "~battDeg@", "~airdens@", "~effFactor@",
        "range = batt. cap. x speed / total power", "total power = baseline+rolling+drag power",
        apx$Speed_RollingPower$textplus, apx$Speed_DragPower$textplus,
        cex=cex),
        side=3, line=0.3, adj=0, cex=cex)

    # Right-side y-axis.
    labels = pretty.good2(ylim_right, yaxp_right[3])
    at = labels * scale_Speed_to_Range_BaselinePower
    axis(side=4, at=at, labels=labels, las=2, cex.axis=0.8)
    mtext(tprintf("Speed at Maximum Range ~speed@"), side=4, line=1.75, cex=0.8)

    par(xaxp=xaxp)
    par(yaxp=yaxp_left)
    grid(lwd=lwd_grid, lty=lty_grid, col=col_grid)

    lines(baselinePowers, maxRange, lwd=2, col=col_range)
    lines(baselinePowers, speedAtMaxRange*scale_Speed_to_Range_BaselinePower, lwd=2, col=col_speed)

    legend("top", c("Maximum range (left y-axis)", "Speed of max range (right y-axis)"),
        col=c(col_range, col_speed), lwd=c(2, 2), seg.len=4, cex=0.8)
    par(svpar)
    }

if (plotToQuartz) plotRS_BP()

################################################################################
# Make a bar plot showing estimated power consumption by car accessories.
################################################################################

# P = power, ACCESS = accessories
plotP_ACCESS = function(isPDF=FALSE)
    {

    #"name", "minPower", "typPower", "maxPower"
    svpar = par(mai=par("mai")+c(1, 0.5, 0, 0), mgp=c(4, 1, 0))

    offset = dfPoweredDevices$minPower
    height = dfPoweredDevices$maxPower - offset
    height[height < 1] = 1
    ylim = c(1, 10^ceiling(log10(max(dfPoweredDevices$maxPower))))
    yaxp = c(ylim, 3)
    xb = barplot(height, offset=offset, ylim=ylim, yaxp=yaxp, log="y", las=2,
        main="", xlab="", ylab="Power Range (min to max, watts)")
    for (i in 1:length(xb))
        segments(xb[i]-0.5, dfPoweredDevices$typPower[i], xb[i]+0.5, dfPoweredDevices$typPower[i], lwd=2)
    mtext(dfPoweredDevices$name, side=1, line=0.2, las=2, at=xb, adj=1, padj=0.5, cex=0.8)
    title(tprintf("Estimated power consumption by accessories"), line=1.5, cex.main=1.1)
    mtext(tprintf("~EVdesc@"), side=3, line=0.3, adj=0.5, cex=0.9)
    # Draw horizontal grid lines. grid() fails, does only powers of 10.
    y = 10^(log10(ylim[1]):log10(ylim[2]))
    y = sort(c(y, 2*y, 5*y))
    y = y[y <= ylim[2]]
    x = par("usr")[1:2]
    for (yt in y)
        segments(x[1], yt, x[2], yt, lwd=lwd_grid, lty=lty_grid, col=col_grid)
    legend("topleft", "Typical usage when device is used", lwd=2, seg.len=1.2)

    par(svpar)
    }

if (plotToQuartz) plotP_ACCESS()

################################################################################
# Plot separate curves for drag power consumption vs speed at different
# temperatures/elevations. Also plot curves for rolling resistance power
# consumption and baseline power consumption.
################################################################################

# P = power, S = speed, AIR = air density
plotCT_PvsS_AIR = function(isPDF=FALSE)
    {
    airConditionsAndSpeeds = list()

    # Compute power required to overcome drag under different conditions, and also convert air condition units from the
    # ones they are expressed in to the ones being used to plot.
    for (cond in names(airConditionsToPlot))
        {
        L = list()
        airCondition = airConditionsToPlot[[cond]]
        elev_ft = airCondition$elev * ifelse(basicDataUnits_metric, 1/m_per_ft, 1)
        L$elev = elev_ft * ifelse(useMetricInPlots, m_per_ft, 1)
        temp_degF = ifelse(basicDataUnits_metric, degC_to_degF(airCondition$temp), airCondition$temp)
        L$temp = ifelse(useMetricInPlots, degF_to_degC(temp_degF), temp_degF)
        pres_inHg = airCondition$pres * ifelse(basicDataUnits_metric, 1/hPa_per_inHg, 1)
        # Convert pressure to a string now because we prefer to show two digits after dp in imperial and none in metric
        L$pres = ifelse(useMetricInPlots, sprintf("%5.0f", round(pres_inHg*hPa_per_inHg)), sprintf("%5.2f", pres_inHg))
        DA_ft = DAft_in_ft_degF_inHg(elev_ft, temp_degF, pres_inHg)
        rho = DAft_to_rhoMetric(DA_ft)
        L$power = apx$Speed_DragPower$compute(fineSpeeds, fineSpeeds, rho)
        airConditionsAndSpeeds[[cond]] = L
        }

    # Get percent that is drag at 100 km/h
    curUnits_100kmph = round(ifelse(useMetricInPlots, 100, 100/kmph_per_mph), 1)
    curUnits_100kmph = as.character(curUnits_100kmph)
    pct = round(100*airConditionsAndSpeeds$testCond$power[curUnits_100kmph]/totalPower_fineSpeeds[curUnits_100kmph])

    xlim = c(0, max_fineSpeed)
    xaxp = c(xlim, nTicks_fineSpeed)
    ylim_left = c(0, maxBatteryPctPerHour_fineSpeed)
    yaxp_left = c(ylim_left, nTicksBatteryPctPerHour_fineSpeed)
    ylim_right = c(0, max_kW_fineSpeed)
    yaxp_right = c(ylim_right, nTicks_kW_fineSpeed)

    svpar = par(mai=par("mai")+c(0, 0.1, 0.45, 0.6), mgp=c(2.5, 0.75, 0))

    plot(NA, type='n', xlim=xlim, xaxp=xaxp, ylim=ylim_left, yaxp=yaxp_left, las=2, main="",
        xlab=tprintf("Speed on flat road (~speed@)"),
        ylab=tprintf("Battery consumption (~battery_pwr@)"))
    title(tprintf("Drag battery/power consumption at various speeds"), line=5.0, cex.main=1.1)

    cex = 0.75
    mtext(makeStringList("~EVdesc@", "~conditions@", "~totalWeight@",
        "~coefs@, ~basePower@", "~areaFrontal@", "~airdens@", "~battDeg@", "~SOC100@",
        "~energyEfficiency_pct@% energy eff factor applied to compute drag, rolling, and baseline power",
        c(apx$Speed_TotalPower$textplus, " (test cond)"), cex=cex),
        side=3, line=0.2, adj=0, cex=cex)

    # Right-side y-axis.
    labels = pretty.good2(ylim_right, yaxp_right[3])
    at = labels * scale_kWh_to_BatteryPct
    axis(side=4, at=at, labels=labels, las=2)
    mtext(tprintf("Power consumption (~power@)"), side=4, line=2.5)

    par(xaxp=xaxp)
    par(yaxp=yaxp_left)
    grid(lwd=lwd_grid, lty=lty_grid, col=col_grid)

    lines(fineSpeeds, totalPower_fineSpeeds, lwd=2, lty=lty_power_total, col=col_power_total)
    lines(fineSpeeds, rollingPower_fineSpeeds, lwd=2, lty=lty_power_rolling, col=col_power_rolling)
    lines(fineSpeeds, baselinePower_fineSpeeds, lwd=2, lty=lty_power_baseline, col=col_power_baseline)

    for (cond in names(airConditionsToPlot))
        {
        drag_kW = airConditionsAndSpeeds[[cond]]$power
        col = airConditionsToPlot[[cond]]$col
        lines(fineSpeeds, drag_kW, col=col, lwd=1, lty="solid")
        }

    # Make the legend.
    txt = c(
        "Total Power under test conditions",
        "Rolling resistance portion of Total Power",
        "Baseline portion of Total Power",
        "Drag portion of Total Power:")
    col = c(col_power_total, col_power_rolling, col_power_baseline, "black")
    lwd = c(2, 2, 2, NA)
    lty = c(lty_power_total, lty_power_rolling, lty_power_baseline, NA)
    for (cond in names(airConditionsToPlot))
        {
        airCondition = airConditionsToPlot[[cond]]
        L = airConditionsAndSpeeds[[cond]]
        txt = c(txt, sprintf("%-15s  %4.0f %s  %3.0f %s  %s %s",
            airCondition$desc, L$elev, unitsTable$elev, L$temp, unitsTable$temp, L$pres, unitsTable$pres))
        col = c(col, airCondition$col)
        lwd = c(lwd, 1)
        lty = c(lty, "solid")
        }
    family = par("family")
    par(family="mono")
    N = length(airConditionsAndSpeeds)
    legend("topleft", txt, col=col, lwd=lwd, lty=lty, cex=ifelse(isPDF, 0.6, 0.75))
    par(family=family)
    par(svpar)
    }

if (plotToQuartz) plotCT_PvsS_AIR()

################################################################################
# Plot range vs speed at different grades uphill and downhill.
################################################################################

# R = range, S = speed, G = grade
plotRvsSG = function(isPDF=FALSE)
    {
    # Road grades to plot.
    grades = c(-7:3, 5, 7) # percent. I-80 over California's Sierra Nevada is 3% to 6%. ADA requires max 8.33% grade.

    # Estimate flat-road range using apx$Speed_Range.
    flatRanges = apx$Speed_Range$compute(fineSpeeds)

    # Make matrix of ranges, columns = grades, rows = fineSpeeds
    mtxRange = matrix(NA, nrow=length(fineSpeeds), ncol=length(grades), dimnames=list(as.character(fineSpeeds),
        as.character(grades)))
    for (grade in grades)
        mtxRange[, as.character(grade)] =
            round(rangeAtGrade_TestVehicle_at_speeds_grades(fineSpeeds, flatRanges, grade), 3)

    # But how will we deal with negative ranges? Let's suppress all of them. Change them to NA. Also change any
    # > maxPlottedRange_Grade_log to NA.
    mtxRange[mtxRange < 0 | mtxRange > maxPlottedRange_Grade_log] = NA

    xlim = c(0, max_fineSpeed)
    xaxp = c(xlim, nTicks_fineSpeed)
    ylim_left = c(minRange_Grade_log, maxRange_Grade_log)
    yaxp_left = axpRange_Grade_log
    ylim_right = c(minDistPerBatteryPct_Grade_log, maxDistPerBatteryPct_Grade_log)
    yaxp_right = yaxp_left

    svpar = par(mai=par("mai")+c(0, 0.1, 0.85, 0.5), mgp=c(2.5, 0.75, 0))

    plot(NA, type='n', xlim=xlim, xaxp=xaxp, ylim=ylim_left, yaxp=yaxp_left, ylog=TRUE, log="y", las=2, cex.axis=0.8, main="",
        xlab=tprintf("Speed (~speed@)"),
        ylab=tprintf("Range of full battery (~dist_long_plural@)"))
    title(tprintf("Estimated range on uphill and downhill grades at various speeds"), line=6.0, cex.main=1.1)
    cex = 0.75
    mtext(makeStringList("~EVdesc@", "~conditions@", "~totalWeight@",
        "~battDeg@", "~SOC100@", "~effFactor@",
        "Range = Speed x batteryCapacity_kWh / (Flat Road Power + Lift Power)",
        "Lift Power = vehicleWeight_kg x N_per_kg x Speed_kmps x fracGrade x energyEfficiencyFactor",
        c("Flat Road Power = ", apx$Speed_TotalPower$textplus), cex=cex),
        side=3, line=0.3, adj=0, cex=cex)

    # Right-side y-axis.
    at = axTicks(side=2, log=TRUE, axp=yaxp_left)
    labels = as.character(at/scale_DistPerBatteryPct_to_Range)
    axis(side=4, at=at, labels=labels, las=2, cex.axis=0.8)
    mtext(tprintf("~battery_eff@"), side=4, line=1.75, cex=0.8)

    par(xaxp=xaxp)
    par(yaxp=yaxp_left)
    grid(lwd=lwd_grid, lty=lty_grid, col=col_grid, equilogs=FALSE)

    for (grade in grades)
        {
        ranges = mtxRange[, as.character(grade)]
        lines(fineSpeeds, ranges, lwd=2)
        G = grade
        S = paste0(G, "% grade up")
        if (G == 0)
            S = "flat road"
        else if (G < 0)
            S = paste0(-G, "% grade down")
        L = findSlope(fineSpeeds, ranges, mode='0')
        adj = c(0.5, -0.4)
        if (abs(L$slope) > 1)
            {
            L = findSlope(fineSpeeds, ranges, mode='M-', fWiden=0.05)
            adj = c(0, 2.0)
            }
        text(L$leftX, L$leftY, S, srt=L$slope, adj=adj, cex=0.7)
        }
    text(min_fineSpeed, maxPlottedRange_Grade_log, "Above here rapidly approaches the point where there is a net CHARGING of the battery",
        adj=c(0,-0.3), cex=0.7, col=col_warning)
    segments(min_fineSpeed, maxPlottedRange_Grade_log, max_fineSpeed, maxPlottedRange_Grade_log, lwd=2, col=col_warning)
    par(svpar)
    }

if (plotToQuartz) plotRvsSG()

################################################################################
# Plot range vs speed at different elevation changes uphill and downhill.
################################################################################

# R = range, S = speed, V = elevation change
plotRvsSV = function(isPDF=FALSE)
    {
    # Elevation changes to plot, in current plot elevation units, with conversion factor to m.
    elevChgs = myIfElse(useMetricInPlots, c(-3000, -1500, 0, 1500, 3000), c(-8000, -4000, 0, 4000, 8000))
    plotElevUnits_to_m = ifelse(useMetricInPlots, 1, m_per_ft)

    # Make matrix of ranges, columns = elevation changes, rows = fineSpeeds
    mtxRange = matrix(NA, nrow=length(fineSpeeds), ncol=length(elevChgs), dimnames=list(as.character(fineSpeeds),
        as.character(elevChgs)))

    # Compute range at each speed and elevation change.
    #   Ranges = fineSpeeds * (batteryCapacity_kWh - liftEnergy) / totalPower_fineSpeeds
    for (elevChg in elevChgs)
        {
        # Efficiency factor is < 1 when going down (elevChg < 0) and is > 1 when going up (greater energy required going up
        # due to loss of efficiency).
        eff_factor = ifelse(elevChg >= 0, 1/fEnergyEfficiency, fRegenEfficiency)
        liftEnergy_kWh = basicData_metric$vehicleWeight * N_per_kg * elevChg * plotElevUnits_to_m * eff_factor / J_per_kWh
        mtxRange[, as.character(elevChg)] = round(fineSpeeds * (basicData_plot$batteryCapacity_kWh - liftEnergy_kWh) / totalPower_fineSpeeds)
        }

    xlim = c(0, max_fineSpeed)
    xaxp = c(xlim, nTicks_fineSpeed)
    ylim_left = c(0, maxRange_ElevChg_fineSpeed)
    yaxp_left = c(ylim_left, nTicksRange_ElevChg_fineSpeed)
    ylim_right = c(0, maxDistPerBatteryPct_ElevChg_fineSpeed)
    yaxp_right = c(ylim_right, nTicksDistPerBatteryPct_ElevChg_fineSpeed)

    svpar = par(mai=par("mai")+c(0, 0.1, 0.85, 0.5), mgp=c(2.5, 0.75, 0))

    plot(NA, type='n', xlim=xlim, xaxp=xaxp, ylim=ylim_left, yaxp=yaxp_left, las=2, cex.axis=0.8, main="",
        xlab=tprintf("Speed (~speed@)"),
        ylab=tprintf("Range of full battery (~dist_long_plural@)"))
    title(tprintf("Estimated range with uphill and downhill elevation changes at various speeds"), line=6.0, cex.main=1.1)
    cex = 0.75
    mtext(makeStringList("~EVdesc@", "~conditions@", "~totalWeight@",
        "~battDeg@", "~SOC100@", "~effFactor@",
        "Range = Speed x (batteryCapacity_kWh - Lift Energy) / Flat Road Power",
        "Lift Energy = vehicleWeight_kg x N_per_kg x ElevChg_m x kWh_per_Nm x energyEfficiencyFactor",
        c("Flat Road Power = ", apx$Speed_TotalPower$textplus), cex=cex),
        side=3, line=0.3, adj=0, cex=cex)

    # Right-side y-axis.
    labels = pretty.good2(ylim_right, yaxp_right[3])
    at = labels * scale_DistPerBatteryPct_to_Range
    axis(side=4, at=at, labels=labels, las=2)
    mtext(tprintf("~battery_eff@"), side=4, line=1.75, cex=0.8)

    par(xaxp=xaxp)
    par(yaxp=yaxp_left)
    grid(lwd=lwd_grid, lty=lty_grid, col=col_grid, equilogs=FALSE)

    for (elevChg in elevChgs)
        {
        ranges = mtxRange[, as.character(elevChg)]
        lines(fineSpeeds, ranges, lwd=2)
        S = tprintf(elevChg, "~elev@ up")
        if (elevChg == 0)
            S = "flat"
        else if (elevChg < 0)
            S = tprintf(-elevChg, "~elev@ down")
        L = findSlope(fineSpeeds, ranges, mode='0', fWiden=0.05)
        adj = c(0.5, -0.2)
        text(L$midX, L$midY, S, srt=L$slope, adj=adj, cex=0.6)
        }
    par(svpar)
    }

if (plotToQuartz) plotRvsSV()

################################################################################
# Plot power vs speed at different wind speeds as wind affects drag.
################################################################################

# P = power, S = speed, WIND = wind speed
plotCT_PvsS_WIND = function(isPDF=FALSE)
    {
    # Compute total power required at different wind speeds, by adding computed drag to baseline power.
    mtx = matrix(NA, nrow=length(windSpeeds), ncol=length(fineSpeeds),
        dimnames=list(as.character(windSpeeds), as.character(fineSpeeds)))
    for (windSpeed in windSpeeds)
        {
        airSpeeds = fineSpeeds + windSpeed
        totalPower_kW = apx$Speed_TotalPower$compute(fineSpeeds, airSpeeds)
        battPctPrHr = scale_kWh_to_BatteryPct*totalPower_kW
        battPctPrHr[battPctPrHr > 100] = NA
        mtx[as.character(windSpeed),] = battPctPrHr
        }

    xlim = c(0, max_fineSpeed)
    xaxp = c(xlim, nTicks_fineSpeed)
    ylim_left = c(0, maxBatteryPctPerHour_fineSpeed)
    yaxp_left = c(ylim_left, nTicksBatteryPctPerHour_fineSpeed)
    ylim_right = c(0, max_kW_fineSpeed)
    yaxp_right = c(ylim_right, nTicks_kW_fineSpeed)

    svpar = par(mai=par("mai")+c(0, 0.1, 0.5, 0.6), mgp=c(2.5, 0.75, 0))

    plot(NA, type='n', xlim=xlim, xaxp=xaxp, ylim=ylim_left, yaxp=yaxp_left, las=2, main="",
        xlab=tprintf("Speed on flat road (~speed@)"),
        ylab=tprintf("Battery consumption (~battery_pwr@)"))
    title(tprintf("Power consumption at various car and wind speeds"), line=4.5, cex.main=1.1)
    cex = 0.75
    mtext(makeStringList("~EVdesc@", "~conditions@", "~totalWeight@",
        "~coefs@, ~basePower@", "~battDeg@", "~airdens@", "~effFactor@",
        c(apx$Speed_TotalPower$textplus, " (flat road)"), cex=cex),
        side=3, line=0.3, adj=0, cex=cex)

    # Right-side y-axis.
    labels = pretty.good2(ylim_right, yaxp_right[3])
    at = labels * scale_kWh_to_BatteryPct
    axis(side=4, at=at, labels=labels, las=2)
    mtext(tprintf("Power consumption (~power@)"), side=4, line=2.5)

    par(xaxp=xaxp)
    par(yaxp=yaxp_left)
    grid(lwd=lwd_grid, lty=lty_grid, col=col_grid)

    for (windSpeed in windSpeeds)
        {
        battPctPerHr = mtx[as.character(windSpeed),]
        lines(fineSpeeds, battPctPerHr, lwd=1)
        L = findSlope(fineSpeeds, battPctPerHr, mode='f', f=1)
        text(L$rightX*1.015, L$rightY, windSpeed, srt=L$slope, adj=c(0.25, -0.5), cex=ifelse(isPDF, 0.5, 0.6))
        if (windSpeed == windSpeeds[1])
            text(L$leftX, L$leftY, "tailwinds", srt=L$slope, adj=c(1.1, 1.2), cex=0.8)
        else if (windSpeed == windSpeeds[length(windSpeeds)])
            {
            text(L$leftX, L$leftY, "headwinds", srt=L$slope, adj=c(1.15, -0.5), cex=0.8)
            text(L$rightX, L$rightY, tprintf("~speed@"), adj=c(1.2, -0.2), cex=0.8)
            }
        }
    par(svpar)
    }

if (plotToQuartz) plotCT_PvsS_WIND()

################################################################################
# Plot energy consumption per unit distance vs speed at different wind speeds,
# as wind affects drag.
################################################################################

# CD = battery charge used per unit distance, ED = energy consumption per unit distance, S = speed, WIND = wind speed
plotCD_EDvsS_WIND = function(isPDF=FALSE)
    {
    # Compute energy consumption required at different wind speeds, by adding computed drag to baseline power then dividing by speed.
    # We convert Wh/distance to Battery %/distance, which is the plot's y-limits (left y-axis).
    mtx = matrix(NA, nrow=length(windSpeeds), ncol=length(fineSpeeds),
        dimnames=list(as.character(windSpeeds), as.character(fineSpeeds)))
    for (windSpeed in windSpeeds)
        {
        airSpeeds = fineSpeeds + windSpeed
        totalPower_kW = apx$Speed_TotalPower$compute(fineSpeeds, airSpeeds)
        mtx[as.character(windSpeed),] = scale_kWh_to_BatteryPct*totalPower_kW/fineSpeeds
        }

    xlim = c(0, max_fineSpeed)
    xaxp = c(xlim, nTicks_fineSpeed)
    ylim_left = c(0, maxBatteryPctPerDist_windSpeed)
    yaxp_left = c(ylim_left, nTicksBatteryPctPerDist_windSpeed)
    ylim_right = c(0, maxWhPerDist_windSpeed)
    yaxp_right = c(ylim_right, nTicksWhPerDist_windSpeed)

    svpar = par(mai=par("mai")+c(0, 0.1, 0.5, 0.6), mgp=c(2.5, 0.75, 0))

    plot(NA, type='n', xlim=xlim, xaxp=xaxp, ylim=ylim_left, yaxp=yaxp_left, las=2, main="",
        xlab=tprintf("Speed on flat road (~speed@)"),
        ylab=tprintf("Battery drain (~battery_use@)"))
    title(tprintf("Energy used per ~dist_long@ at various car and wind speeds"), line=4.25, cex.main=1.1)
    cex = 0.75
    mtext(makeStringList("~EVdesc@", "~conditions@", "~totalWeight@",
        "~coefs@, ~basePower@", "~battDeg@", "~airdens@", "~effFactor@",
        c(apx$Speed_TotalPower$textplus, " (flat road)"), cex=cex),
        side=3, line=0.3, adj=0, cex=cex)

    # Right-side y-axis.
    labels = pretty.good2(ylim_right, yaxp_right[3])
    at = labels * scale_Wh_to_BatteryPct
    axis(side=4, at=at, labels=labels, las=2)
    mtext(tprintf("Energy drain (~energy_use@)"), side=4, line=3)

    par(xaxp=xaxp)
    par(yaxp=yaxp_left)
    grid(lwd=lwd_grid, lty=lty_grid, col=col_grid)

    for (windSpeed in windSpeeds)
        {
        pctBatt = mtx[as.character(windSpeed),]
        lines(fineSpeeds, pctBatt, lwd=1)
        L = findSlope(fineSpeeds, pctBatt, mode='f', f=1)
        text(L$rightX*1.015, L$rightY, windSpeed, srt=L$slope, adj=c(0.5, 0), cex=ifelse(isPDF, 0.5, 0.6))
        if (windSpeed == windSpeeds[1])
            {
            text(L$leftX, L$leftY, "tailwinds", srt=L$slope, adj=c(1, 1.2), cex=0.8)
            text(L$rightX, L$rightY, tprintf("~speed@"), adj=c(0.3, 3), cex=0.8)
            }
        else if (windSpeed == windSpeeds[length(windSpeeds)])
            text(L$leftX, L$leftY, "headwinds", srt=L$slope, adj=c(1, -0.5), cex=0.8)
        }
    par(svpar)
    }

if (plotToQuartz) plotCD_EDvsS_WIND()

################################################################################
# Plot range vs speed at different wind speeds as wind affects drag.
################################################################################

# R = range, DC = distance per consumed battery percent, DE = distance per unit energy, S = speed, WIND = wind speed
plotR_DC_DEvsS_WIND = function(isPDF=FALSE)
    {
    # Compute range at different wind speeds. Get power at each speed by adding computed drag to baseline power.
    mtx = matrix(NA, nrow=length(windSpeeds), ncol=length(fineSpeeds), dimnames=list(as.character(windSpeeds),
        as.character(fineSpeeds)))
    for (windSpeed in windSpeeds)
        {
        airSpeeds = fineSpeeds + windSpeed
        totalPower_kW = apx$Speed_TotalPower$compute(fineSpeeds, airSpeeds)
        mtx[as.character(windSpeed),] = round(basicData_plot$batteryCapacity_kWh*fineSpeeds/totalPower_kW, 3)
        }

    xlim = c(0, max_fineSpeed)
    xaxp = c(xlim, nTicks_fineSpeed)
    ylim_left = c(0, maxRange_windSpeed)
    yaxp_left = c(ylim_left, nTicksRange_windSpeed)
    ylim_right_1 = c(0, maxDistPerBattery1pct_windSpeed)
    yaxp_right_1 = c(ylim_right_1, nTicksDistPerBattery1pct_windSpeed)
    ylim_right_2 = c(0, maxDistPer_kWh_windSpeed)
    yaxp_right_2 = c(ylim_right_2, nTicksDistPer_kWh_windSpeed)

    svpar = par(mai=par("mai")+c(0, 0.1, 0.55, 1.2), mgp=c(2.5, 0.75, 0))

    plot(NA, type='n', xlim=xlim, xaxp=xaxp, ylim=ylim_left, yaxp=yaxp_left, las=2, main="",
        xlab=tprintf("Speed on flat road (~speed@)"),
        ylab=tprintf("Range of full battery (~dist_long_plural@)"))
    title(tprintf("Estimated range at various car and wind speeds"), line=4.5, cex.main=1.1)
    cex = 0.75
    mtext(makeStringList("~EVdesc@", "~conditions@", "~totalWeight@",
        "~coefs@, ~basePower@", "~battDeg@", "~airdens@", "~effFactor@",
        c(apx$Speed_TotalPower$textplus, " (flat road)"), cex=cex),
        side=3, line=0.3, adj=0, cex=cex)

    # Right-side y-axis 1.
    labels = pretty.good2(ylim_right_1, yaxp_right_1[3])
    at = labels * scale_DistPerBatteryPct_to_Range
    axis(side=4, at=at, labels=labels, las=2, cex.axis=0.8)
    mtext(tprintf("~battery_eff@"), side=4, line=1.75, cex=0.8)

    # Right-side y-axis 2.
    at = pretty.good2(ylim_left, yaxp_left[3])
    axis(side=4, line=4, at=at, labels=FALSE, col.ticks="darkgray", tcl=1)
    labels = pretty.good2(ylim_right_2, yaxp_right_2[3])
    at = labels * scale_DistPer_kWh_to_Range
    axis(side=4, line=4, at=at, labels=labels, las=2, cex.axis=0.8)
    mtext(tprintf("~energy_eff@"), side=4, line=5.75, cex=0.8)

    par(xaxp=xaxp)
    par(yaxp=yaxp_left)
    grid(lwd=lwd_grid, lty=lty_grid, col=col_grid)

    for (windSpeed in windSpeeds)
        {
        rng = mtx[as.character(windSpeed),]
        lines(fineSpeeds, rng, lwd=1)
        L = findSlope(fineSpeeds, rng, mode='M-', fWiden=0.05)
        if (windSpeed == 0)
            S = "No wind"
        else if (windSpeed > 0)
            S = tprintf(windSpeed, " ~speed@ headwind")
        else
            S = tprintf(-windSpeed, " ~speed@ tailwind")
        text(L$midX, L$midY, S, srt=L$slope, adj=c(0.5, -0.2), cex=ifelse(isPDF, 0.65, 0.75))
        }
    par(svpar)
    }

if (plotToQuartz) plotR_DC_DEvsS_WIND()

################################################################################
# Plot an elevation profile of a chosen route.
################################################################################

# Route = chosen route
plot_RouteElevProfile = function(isPDF=FALSE)
    {
    xat = pretty.good(c(0, dfRoute$cumdist), 10)
    xlim = range(xat)
    xaxp = c(xlim, length(xat)-1)

    yat = pretty.good(c(0, dfRoute$elevation), 10)
    ylim = range(yat)
    yaxp = c(ylim, length(yat)-1)

    svpar = par(mai=par("mai")+c(0.4, 0.4, 0, 0), mgp=c(2.75, 0.75, 0))

    plot(NA, type='n', xlim=xlim, xaxp=xaxp, ylim=ylim, yaxp=yaxp, las=2, main="",
        xlab=tprintf("Distance along route (~distance@)"),
        ylab=tprintf("Road elevation (~elev@)"))
    title(tprintf("Elevation profile of ~aRoute_desc@"), line=1, cex.main=1.1)

    par(xaxp=xaxp)
    par(yaxp=yaxp)
    grid(lwd=lwd_grid, lty=lty_grid, col=col_grid)

    lines(dfRoute$cumdist, dfRoute$elevation)
    for (L in basicData_plot$aRoute_labels)
        {
        i = findInterval(L$dist, dfRoute$cumdist)
        if (i < 1) i = 1
        if (i > nrow(dfRoute)) i = nrow(dfRoute)
        text(L$dist, dfRoute$elevation[i], L$label, adj=L$adj, cex=0.5)
        points(L$dist, dfRoute$elevation[i], pch=pchDot, cex=0.5, col="red")
        }

    # Get and plot route length and elevation change numbers.
    Lgrade = computeRouteLengthAndGradeData(fineSpeeds)
    y = floor(min(dfRoute$elevation)/1000)*1000*0.8
    dy = y/7
    text(0, y, tprintf("Total route length: ", Lgrade$routeLength, " ~distance@"), pos=4, cex=0.7)
    y = y - dy
    text(0, y, tprintf("Cumulative elevation gain: ", Lgrade$liftElev, " ~elev@"), pos=4, cex=0.7)
    y = y - dy
    text(0, y, tprintf("Cumulative elevation loss: ", Lgrade$dropElev, " ~elev@"), pos=4, cex=0.7)
    y = y - dy
    text(0, y, tprintf("Net elevation gain: ", Lgrade$netElev, " ~elev@"), pos=4, cex=0.7)
    y = y - dy
    text(0, y, tprintf("Energy used for elevation gain: ", Lgrade$lift_kWh, " ~energy@",
        " (", Lgrade$lift_battPct, " ~battery_pct@)"), pos=4, cex=0.7)
    y = y - dy
    text(0, y, tprintf("Energy used for elevation loss: ", Lgrade$drop_kWh, " ~energy@",
        " (", Lgrade$drop_battPct, " ~battery_pct@)"), pos=4, cex=0.7)
    y = y - dy
    text(0, y, tprintf("Net energy used for elevation change: ", Lgrade$net_kWh, " ~energy@",
        " (", Lgrade$net_battPct, " ~battery_pct@)"), pos=4, cex=0.7)

    par(svpar)
    }

if (plotToQuartz) plot_RouteElevProfile()

################################################################################
# Plot amount of energy (and battery) used at each car speed and different wind
# speeds to travel the chosen route whose elevation profile was in the previous
# plot.
################################################################################

# Route = chosen route, Energy = battery energy in Kwh and %, S = speed, WIND = wind speed
plot_RouteEnergy_vsS_WIND = function(isPDF=FALSE)
    {
    # Compute energy used for chosen route at different car and wind speeds and
    # store it in mtx. First create mtx.
    mtx = matrix(NA, nrow=length(fineSpeeds), ncol=length(windSpeeds),
        dimnames=list(as.character(fineSpeeds), as.character(windSpeeds)))

    # Get route length and elevation change numbers. and compute the energy
    # required to lift or lower the vehicle by the elevation change for each
    # segment along the route, and sum the energy of all segments to get the
    # total energy used to overcome grades. The lift and lower energy must take
    # into account the efficiency of providing energy for lifting
    # (fEnergyEfficiency) and for recapturing energy from lowering
    # (fRegenEfficiency).
    Lgrade = computeRouteLengthAndGradeData(fineSpeeds)

    # Now, for each car/wind speed combo, compute the power. Then, the energy
    # used for the entire route is the power times the route traversal time at
    # that speed. Add the "grade" energy to the route energy obtained at each
    # car/wind speed to get the final total energy required to traverse the
    # chosen route at that car and wind speed.
    # We convert Wh to Battery %, which is the plot's y-limits (left y-axis).
    for (windSpeed in windSpeeds)
        {
        airSpeeds = fineSpeeds + windSpeed
        totalPower_kW = apx$Speed_TotalPower$compute(fineSpeeds, airSpeeds)
        flatEnergy_kWh = totalPower_kW * Lgrade$travelTime_h
        totalEnergy_kWh = flatEnergy_kWh + Lgrade$net_kWh
        mtx[, as.character(windSpeed)] = scale_kWh_to_BatteryPct*totalEnergy_kWh
        }

    xlim = c(0, max_fineSpeed)
    xaxp = c(xlim, nTicks_fineSpeed)
    ylim_left = c(0, 50*ceiling(max(mtx)/50))
    yaxp_left = c(ylim_left, ylim_left[2]/50)
    yat_right = pretty.good(ylim_left/scale_kWh_to_BatteryPct)
    yat_right = yat_right[yat_right <= ylim_left[2]/scale_kWh_to_BatteryPct]
    ylim_right = range(yat_right)
    yaxp_right = c(ylim_right, ylim_right[2]/50)

    svpar = par(mai=par("mai")+c(0, 0.1, 1, 0.6), mgp=c(2.75, 0.75, 0))

    plot(NA, type='n', xlim=xlim, xaxp=xaxp, ylim=ylim_left, yaxp=yaxp_left, las=2, main="",
        xlab=tprintf("Speed on flat road (~speed@)"),
        ylab=tprintf("Battery used for entire route (~battery_pct@)"))
    title(tprintf("Energy used to travel route at various car and wind speeds"), line=6, cex.main=1.1)
    cex = 0.75
    mtext(makeStringList("~EVdesc@", "~conditions@", "~totalWeight@",
        "~coefs@ ~basePower@", "~areaFrontal@", "~battDeg@", "~effFactor@",
        c(apx$Speed_TotalPower$textplus, " (flat road)"),
        "Lift Energy = vehicleWeight_kg x N_per_kg x elev_change_m x energyEfficiencyFactor",
        "Route Energy = Flat Road Power x travel_time + Lift Energy",
        cex=cex), side=3, line=0.3, adj=0, cex=cex)

    # Right-side y-axis.
    labels = pretty.good2(ylim_right, yaxp_right[3])
    at = labels * scale_kWh_to_BatteryPct
    axis(side=4, at=at, labels=labels, las=2)
    mtext(tprintf("Energy used for entire route (~energy@)"), side=4, line=3)

    par(xaxp=xaxp)
    par(yaxp=yaxp_left)
    grid(lwd=lwd_grid, lty=lty_grid, col=col_grid)

    for (windSpeed in windSpeeds)
        {
        pctBatt = mtx[, as.character(windSpeed)]
        lines(fineSpeeds, pctBatt, lwd=1)
        L = findSlope(fineSpeeds, pctBatt, mode='f', f=1, fWiden=0.01)
        text(L$rightX*1.015, L$rightY, windSpeed, srt=L$slope, adj=c(0.5, 0), cex=ifelse(isPDF, 0.5, 0.6))
        if (windSpeed == windSpeeds[1])
            {
            text(L$leftX, L$leftY, "tailwinds", srt=L$slope, adj=c(1, 1.2), cex=0.8)
            text(L$rightX, L$rightY, tprintf("~speed@"), adj=c(0.3, 3), cex=0.8)
            }
        else if (windSpeed == windSpeeds[length(windSpeeds)])
            text(L$leftX, L$leftY, "headwinds", srt=L$slope, adj=c(1, -0.5), cex=0.8)
        }

    par(svpar)
    }

if (plotToQuartz) plot_RouteEnergy_vsS_WIND()

################################################################################
# Plot amount of energy (and battery) used at each car speed as one progresses
# along the chosen route whose elevation profile was in the previous plot.
################################################################################

# Route = chosen route, Energy = battery energy in Kwh and %, S = speed,
# PROGRESS = route progress
plot_RouteEnergy_vsS_PROGRESS = function(isPDF=FALSE)
    {
    # Compute energy used for chosen route at different car speeds and points
    # along the route and store it in mtx. First create mtx.
    mtx = matrix(NA, nrow=nrow(dfRoute), ncol=length(speeds_batteryPlots),
        dimnames=list(as.character(dfRoute$dist), as.character(speeds_batteryPlots)))

    # Compute the energy required to lift or lower the vehicle by the elevation
    # change for each segment along the route, and sum the energy of all
    # segments to get the total energy used to overcome grades. The lift and
    # lower energy must take into account the efficiency of providing energy for
    # lifting (fEnergyEfficiency) and for recapturing energy from lowering
    # (fRegenEfficiency).
    grade_kWh = dfRoute$delta_elev
    ind = (grade_kWh >= 0)
    cvt_to_m = ifelse(useMetricInPlots, 1, m_per_ft)
    grade_kWh[ind] = grade_kWh[ind] * (cvt_to_m * vehicleWeight_N / fEnergyEfficiency / J_per_kWh)
    grade_kWh[!ind] = grade_kWh[!ind] * (cvt_to_m * vehicleWeight_N * fRegenEfficiency / J_per_kWh)

    # For each car speed, compute the power. Then, the energy used for the route
    # segment is the power at that speed times the segment traversal time at
    # that speed. Add the "grade" energy to the route energy obtained at each
    # segment to get the final energy required to traverse the route segment at
    # that car speed. Compute the cumulative sums of the segment energies and
    # convert Wh to Battery %, which is the plot's y-limits (left y-axis).
    totalPower_kW = apx$Speed_TotalPower$compute(speeds_batteryPlots, speeds_batteryPlots)
    for (speed in speeds_batteryPlots)
        {
        flatEnergy_kWh = totalPower_kW[as.character(speed)] * dfRoute$dist / speed
        totalEnergy_kWh = flatEnergy_kWh + grade_kWh
        mtx[, as.character(speed)] = scale_kWh_to_BatteryPct * cumsum(totalEnergy_kWh)
        }

    xat = pretty.good(c(0, dfRoute$cumdist), 10)
    xlim = range(xat)
    xaxp = c(xlim, length(xat)-1)
    ylim_left = c(0, 50*ceiling(max(mtx)/50))
    yaxp_left = c(ylim_left, ylim_left[2]/25)
    yat_right = pretty.good(ylim_left/scale_kWh_to_BatteryPct)
    yat_right = yat_right[yat_right <= ylim_left[2]/scale_kWh_to_BatteryPct]
    ylim_right = range(yat_right)
    yaxp_right = c(ylim_right, ylim_right[2]/50)

    svpar = par(mai=par("mai")+c(0, 0.1, 0.5, 0.6), mgp=c(2.75, 0.75, 0))

    plot(NA, type='n', xlim=xlim, xaxp=xaxp, ylim=ylim_left, yaxp=yaxp_left, las=2, main="",
        xlab=tprintf("Progress along route (~distance@)"),
        ylab=tprintf("Cumulative battery used along route (~battery_pct@)"))
    title(tprintf("Energy usage along travel route at various car speeds"), line=6, cex.main=1.1)
    cex = 0.75
    mtext(makeStringList("~EVdesc@", "~conditions@", "~totalWeight@",
        "~coefs@ ~basePower@", "~areaFrontal@", "~battDeg@", "~effFactor@",
        c(apx$Speed_TotalPower$textplus, " (flat road)"),
        "Segment Lift Energy = vehicleWeight_kg x N_per_kg x segment_elev_change_m x energyEfficiencyFactor",
        "Route Segment Energy = Flat Road Power x segment_travel_time + Segment Lift Energy",
        cex=cex), side=3, line=0.3, adj=0, cex=cex)

    # Right-side y-axis.
    labels = pretty.good2(ylim_right, yaxp_right[3])
    at = labels * scale_kWh_to_BatteryPct
    axis(side=4, at=at, labels=labels, las=2)
    mtext(tprintf("Cumulative energy used along route (~energy@)"), side=4, line=3)

    par(xaxp=xaxp)
    par(yaxp=yaxp_left)
    grid(lwd=lwd_grid, lty=lty_grid, col=col_grid)

    cex = 0.5
    h = strheight("8", cex=cex) # Height of each text line
    N = nrow(dfRoute)
    y = mtx[N, 1]
    # If bottom two are crowded, move bottom one down. Try to move it down as
    # much as it needs, but do not move it down more than h/2.
    d = h - (mtx[N, 2] - y)
    if (d > h/2)
        d = h/2
    y = y - d
    for (i in 1:ncol(mtx))
        {
        speed = colnames(mtx)[i]
        lines(dfRoute$cumdist, mtx[,speed], lwd=lwd_derived_data_many)
        text(dfRoute$cumdist[N], y, epaste(speed, tprintf("*' ~speed@'")), adj=c(0, 0.5), cex=cex)
        # Next y position must be at least h above previous one, but if that is
        # less than position of next label, set y to next label position.
        y = y + h
        if (i < ncol(mtx) && y < mtx[N, i+1])
            y = mtx[N, i+1]
        }
    text(0, ylim_left[2], "Assumes no wind", adj=c(0, 1))
    par(svpar)
    }

if (plotToQuartz) plot_RouteEnergy_vsS_PROGRESS()

################################################################################
# Plot charging time and charging power as a function of SOC (state-of-charge).
################################################################################

# CT = charging time, CP = charging power, SOC = state-of-charge
plotCT_CPvsSOC = function(isPDF=FALSE)
    {
    xlim = c(0, 100)
    xaxp = c(xlim, 20)
    ylim_left = c(0, maxChargeMinutes_charging)
    yaxp_left = c(ylim_left, nTicksChargeMinutes_charging)
    ylim_right = c(0, maxChargingPower_kW_charging)
    yaxp_right = c(ylim_right, nTicksChargingPower_kW_charging)

    svpar = par(mai=par("mai")+c(0, 0.1, 0.2, 0.6), mgp=c(2.5, 0.75, 0))

    plot(NA, type='n', xlim=xlim, xaxp=xaxp, ylim=ylim_left, yaxp=yaxp_left, las=2, yaxt="n", main="", ylab="",
        xlab=tprintf("State-of-Charge (SOC, %)"))
    title(tprintf("Time to charge from 0% to 100% state-of-charge"), line=3, cex.main=1.1)
    mtext(tprintf(
        "~chargeCurveDescription@",
        "\n",
        "~chargeCurveCitation@",
        "\n",
        "(Assume charging is done at the maximum possible rate equal to the charging power shown on the right axis)"
        ),
        side=3, line=0.25, cex=0.8)

    # Left-side y-axis.
    labels = pretty.good2(ylim_left, yaxp_left[3])
    at = labels
    axis(side=2, at=at, labels=labels, las=2, col.axis=col_charge_time, col=col_charge_time)
    mtext(tprintf("Charging time (minutes)"), side=2, line=2.5, col=col_charge_time)

    # Right-side y-axis.
    labels = pretty.good2(ylim_right, yaxp_right[3])
    at = labels * axisScale_kW_to_chargeTime_minutes
    axis(side=4, at=at, labels=labels, las=2, col.axis=col_charging_power, col=col_charging_power)
    mtext(tprintf("Charging power (~power@)"), side=4, line=2.5, col=col_charging_power)

    par(xaxp=xaxp)
    par(yaxp=yaxp_left)
    grid(lwd=lwd_grid, lty=lty_grid, col=col_grid)

    lines(dfChargeCurve$SOCpct, dfChargeCurve$Minutes, lwd=2, col=col_charge_time)
    lines(dfChargeCurve$SOCpct, dfChargeCurve$Power*axisScale_kW_to_chargeTime_minutes, lwd=2, col=col_charging_power)

    legend("top", c("Charging time (left axis)", "Charging power (max. possible, right axis)"),
        col=c(col_charge_time, col_charging_power), lwd=2, cex=0.8)

    par(svpar)
    }

if (plotToQuartz) plotCT_CPvsSOC()

################################################################################
# Plot state-of-charge and charging power as a function of charging time.
################################################################################

# SOC = state-of-charge, BE = battery energy, CP = charging power, CR = charge rate, CT = charging time
plotSOC_BE_CP_CR_vsCT = function(isPDF=FALSE)
    {
    xlim = c(0, maxChargeMinutes_charging)
    xaxp = c(xlim, nTicksChargeMinutes_charging)
    ylim_left_1 = c(0, maxSOCpct_axis)
    yaxp_left_1 = c(ylim_left_1, nTicksSOCpct_axis)
    ylim_left_2 = c(0, maxBatteryEnergy_charging)
    yaxp_left_2 = c(ylim_left_2, nTicksBatteryEnergy_charging)
    ylim_right_1 = c(0, maxChargingPower_battPctPerHr_charging)
    yaxp_right_1 = c(ylim_right_1, nTicksChargingPower_battPctPerHr_charging)
    ylim_right_2 = c(0, maxChargingPower_kW_charging)
    yaxp_right_2 = c(ylim_right_2, nTicksChargingPower_kW_charging)

    svpar = par(mai=par("mai")+c(0, 0.7, 0.2, 1.1), mgp=c(2, 0.75, 0))

    plot(NA, type='n', xlim=xlim, xaxp=xaxp, ylim=ylim_left_1, yaxp=yaxp_left_1, las=2, yaxt="n", main="", ylab="",
        xlab=tprintf("Charge time (minutes)"))
    title(tprintf("Battery energy and charging power as time passes when charging from 0% to 100% state-of-charge"), line=3, cex.main=0.9)
    mtext(tprintf(
        "~chargeCurveDescription@",
        "\n",
        "~chargeCurveCitation@",
        "\n",
        "(Assume charging is done at the maximum possible rate equal to the charging power shown on the right axis)"
        ),
        side=3, line=0.25, cex=0.8)

    # Left-side y-axis 1.
    labels = pretty.good2(ylim_left_1, yaxp_left_1[3])
    at = labels
    axis(side=2, at=at, labels=labels, las=2, cex.axis=0.8, col.axis=col_charge_batteryEnergy, col=col_charge_batteryEnergy)
    mtext(tprintf("State-of-Charge (SOC, %)"), side=2, line=1.75, cex=0.8, col=col_charge_batteryEnergy)

    # Left-side y-axis 2.
    # Add light-gray grid extension lines.
    at = pretty.good2(ylim_left_1, yaxp_left_1[3])
    axis(side=2, line=4, at=at, labels=FALSE, col.ticks="darkgray", tcl=1)
    # Then add axis.
    labels = pretty.good2(ylim_left_2, yaxp_left_2[3])
    at = labels * scale_kWh_to_BatteryPct_charging
    axis(side=2, line=4, at=at, labels=labels, las=2, cex.axis=0.8, col.axis=col_charge_batteryEnergy, col=col_charge_batteryEnergy)
    mtext(tprintf("Battery energy (~energy@)"), side=2, line=5.75, cex=0.8, col=col_charge_batteryEnergy)

    # Right-side y-axis 1.
    labels = pretty.good2(ylim_right_1, yaxp_right_1[3])
    at = labels * axisScale_battPctPerHr_to_SOCaxis
    axis(side=4, at=at, labels=labels, las=2, cex.axis=0.8, col.axis=col_charging_power, col=col_charging_power)
    mtext(tprintf("Charge rate (~battery_pwr@)"), side=4, line=1.75, cex=0.8, col=col_charging_power)

    # Right-side y-axis 2.
    # Add light-gray grid extension lines.
    at = pretty.good2(ylim_left_1, yaxp_left_1[3])
    axis(side=4, line=4, at=at, labels=FALSE, col.ticks="darkgray", tcl=1)
    # Then add axis.
    labels = pretty.good2(ylim_right_2, yaxp_right_2[3])
    at = labels * axisScale_kW_to_BatteryPct
    axis(side=4, line=4, at=at, labels=labels, las=2, cex.axis=0.8, col.axis=col_charging_power, col=col_charging_power)
    mtext(tprintf("Charging power (~power@)"), side=4, line=5.75, cex=0.8, col=col_charging_power)

    par(xaxp=xaxp)
    par(yaxp=yaxp_left_1)
    grid(lwd=lwd_grid, lty=lty_grid, col=col_grid)

    lines(dfChargeCurve$Minutes, dfChargeCurve$TotalEnergy*scale_kWh_to_BatteryPct_charging, lwd=2, col=col_charge_batteryEnergy)
    lines(dfChargeCurve$Minutes, dfChargeCurve$Power*axisScale_kW_to_BatteryPct, lwd=2, col=col_charging_power)

    legend("bottom", c("Battery SOC and energy (left axes)", "Charging power and rate (max. possible, right axes)"),
        col=c(col_charge_batteryEnergy, col_charging_power), lwd=2, cex=0.75)

    par(svpar)
    }

if (plotToQuartz) plotSOC_BE_CP_CR_vsCT()

################################################################################
################################################################################
# End of plot functions.
################################################################################
################################################################################

################################################################################
# Make a text page at start of PDF file to tell reader my email address and
# announce GNU license.
################################################################################

plotText = function(txt, justify="center", cex=1)
    {
    x = switch(justify,
        "left" = 0,
        "center" = 0.5,
        "right" = 1)
    adjx = switch(justify,
        "left" = 0,
        "center" = 0.5,
        "right" = 1)
    svpar = par(mai=par("mai")+c(0, -0.5, 0, -0.1))
    plot(NA, type='n', xlim=0:1, ylim=0:1, axes=FALSE, main="", xlab="", ylab="")
    text(x, 0.5, txt, adj=c(adjx, 0.5), cex=cex)
    par(svpar)
    }

plotHeader = function(cex=1)
    {
    plotText(paste(
        paste0("Program version: ", basicData_plot$version, "\n"),
        "\n",
        paste0("These plotted curves show, from various perspectives, the battery range of a\n",
        basicData_plot$description), ".\n",
        "\n",
        "The data for these was obtained by driving the car back and forth on a fairly flat road\n",
        "multiple times, at different speeds, and recording the energy usage per distance as shown\n",
        "by the car in watt-hours per unit distance travelled. This data is shown on one of the plots.\n",
        "Also, certain data was found on the internet, such as vehicle weight.\n",
        "\n",
        "Many plots show curves for a much wider range of speeds than those used in the testing\n",
        "described above. This was done by fitting a 3rd-order polynomial to the power curve obtained\n",
        "from the testing. From that polynomial power curve, the coefficients of rolling resistance\n",
        "and drag, and the baseline power. From those, the rolling power and drag power were estimated\n",
        "for speeds from near 0 to quite fast. The total power is then the sum of the baseline power,\n",
        "rolling power and drag power. Finally, that total power estimate at different speeds is used\n",
        "to compute the curves for most of the plots.\n",
        "\n",
        "Some plots take into account battery degradation. This was obtained for the car described\n",
        "above as follows: ", basicData_plot$batteryHealthDesc, "\n",
        "\n",
        "If you would like curves plotted for another car and can provide the necessary energy data,\n",
        "contact me and we'll see if we can arrange it.\n",
        "\n",
        "If you have questions or concerns about any of the plots, you can contact me on various\n",
        "online groups or at ted@tedtoal.net\n",
        "\n",
        "The R code used to produce these plots is available on GitHub at:\n",
        "   https://github.com/tedtoal/EV-battery-and-range-plots\n",
        "\n",
        "-----------\n",
        "Copyright (C) 2024-2025  Ted Toal\n",
        "\n",
        "The program that produces these plots is free software: you can redistribute it and/or\n",
        "modify it under the terms of the GNU General Public License as published by the Free\n",
        "Software Foundation, either version 3 of the License, or (at your option) any later\n",
        "version.\n",
        "\n",
        "The program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;\n",
        "without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR\n",
        "PURPOSE. See the GNU General Public License for more details.\n",
        "\n",
        "You should have received a copy of the GNU General Public License along with this program.\n",
        "If not, see <https://www.gnu.org/licenses/>.\n",
        "\n",
        "The author, Ted Toal, can be contacted via email at ted@tedtoal.net\n",
        "-----------\n",
        sep=""), justify="left", cex=cex)
    }

if (plotToQuartz) plotHeader()

################################################################################
# Plot ALL of the above plots to a PDF file, multiple plots per page.
#
# In some cases I have changed the order of plots from the order they appear
# above.
################################################################################

if (rangeEnergyPlots)
    {
    fn = file.path(basicData_plot$pdfDirectory,
        paste0(basicData_plot$pdfAllPlotsFilename, ifelse(useMetricInPlots, "_metric", "_imperial"),
            ifelse(useBWcolors, "_gray", "_colors"), ".pdf"))
    cairo_pdf(fn, width=8.5, height=11, bg="white", onefile=TRUE)
    plotHeader(cex=0.8)
    plotText("(Intentionally blank)")
    par(omi=par("omi")+c(0.3, 0.2, 0, 0.2), mai=c(0.75, 0.75, 1.0, 0.25))

    # Something is wrong with mgi restoration, functions save the returned par() value when changing mgi and restore it when
    # finished, but it doesn't restore, for PDF plots only. By saving par() values before calling each page-full of plot functions
    # and then restoring the values before moving on to the next page, this fixes the problem. One way you see that is that mtext()
    # line number for below-title text can be the same now for both regular and PDF plotting.

    par(mfrow=c(2,1))
    svpar = getParSettable()
    plotCT_PvsS(TRUE)
    plotR_DC_DEvsS(TRUE)
    par(svpar)
    plotCD_EDvsS(TRUE)
    plotDPMvsS(TRUE)
    par(svpar)
    plotMPDvsS(TRUE)
    plotMvsS(TRUE)
    par(svpar)
    plotDvsSCE(TRUE)
    plotTvsSCE(TRUE)
    par(svpar)
    plotSvsDCE(TRUE)
    plotSvsTCE(TRUE)
    par(svpar)
    plotR_S_BP(TRUE)
    plotRS_BP(TRUE)
    par(svpar)
    plotP_ACCESS(TRUE)
    plotCT_PvsS_AIR(TRUE)
    par(svpar)
    plotRvsSG(TRUE)
    plotRvsSV(TRUE)
    par(svpar)
    plotCT_PvsS_WIND(TRUE)
    plotCD_EDvsS_WIND(TRUE)
    par(svpar)
    plotR_DC_DEvsS_WIND(TRUE)
    plot_RouteElevProfile(TRUE)
    par(svpar)
    plot_RouteEnergy_vsS_WIND(TRUE)
    plot_RouteEnergy_vsS_PROGRESS(TRUE)
    par(svpar)
    plotCT_CPvsSOC(TRUE)
    plotSOC_BE_CP_CR_vsCT(TRUE)
    dev.off()
    }

################################################################################
# Plot only the range plots to a PDF file, multiple plots per page.
################################################################################

if (rangeOnlyPlots)
    {
    fn = file.path(basicData_plot$pdfDirectory,
        paste0(basicData_plot$pdfSomePlotsFilename, ifelse(useMetricInPlots, "_metric", "_imperial"),
            ifelse(useBWcolors, "_gray", "_colors"), ".pdf"))
    cairo_pdf(fn, width=8.5, height=11, bg="white", onefile=TRUE)
    plotHeader(cex=0.8)
    plotText("(Intentionally blank)")
    par(omi=par("omi")+c(0.3, 0.2, 0, 0.2), mai=c(0.75, 0.75, 1.0, 0.25))
    par(mfrow=c(2,1))
    svpar = getParSettable()
    plotMvsS(TRUE)
    plotR_DC_DEvsS(TRUE)
    par(svpar)
    plotDPMvsS(TRUE)
    plotMPDvsS(TRUE)
    par(svpar)
    plotRvsSG(TRUE)
    plotRvsSV(TRUE)
    par(svpar)
    plotCD_EDvsS_WIND(TRUE)
    plotR_DC_DEvsS_WIND(TRUE)
    par(svpar)
    plotDvsSCE(TRUE)
    plotTvsSCE(TRUE)
    par(svpar)
    plotSvsDCE(TRUE)
    plotSvsTCE(TRUE)
    par(svpar)
    dev.off()
    }

################################################################################
# End of the two "for" loops that loop for useMetricInPlots and useBWcolors.
################################################################################

}
}

################################################################################
################################################################################
# End of file.
################################################################################
################################################################################
