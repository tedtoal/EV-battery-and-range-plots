################################################################################
# This file illustrates how an R code file should be formatted in order to use
# any of Ted's include files in R code.
#
# License: This file may be freely shared.
# Author: Ted Toal
# Date: Apr 2024
#
# Set up computer and format R code as follows:
#
# 1. Define several global system environment variables on your computer, giving
#   the full path to various key folders.  In the following examples I used
#   username "tedtoal" as the example, but change it to the appropriate username
#   for you:
#
#       LOCAL_ROOT=/Users/tedtoal/Documents/Tesla/EV-battery-and-range-plots
#       RSOURCEPATH=/Users/tedtoal/Documents/Tesla/EV-battery-and-range-plots
#
#   RSOURCEPATH above points to one or more directories containing R include
#       files and in particular containing Include_HeaderCode.R.  Unlike any
#       others above, it can contain more than one path, separated by ":",
#       although only one is used above.
#
#   To define a global environment variable on most unix machines, just add
#   "export <VARNAME>=<VALUE>" commands to ~/.bash_profile (or whatever shell
#   profile file you use).
#
#   However, for MacOS, doing that does NOT set the variables for apps started
#   by clicking on their icons (the usual way; an alternative is to start them
#   with the "open" command from Terminal, but you probably want to set up so
#   you can open things like RStudio with a mouse click on the icon, and still
#   have this R code work properly). Setting up a global environment variable on
#   MacOS so that it is available to mouse-click-opened apps is complicated and
#   the method seems to change with each new release of MacOS, so it will not be
#   described here.
#
# 2. Copy the standard header text below, from the comment block through to the
#   end of the file, to the START of each top-level (non-sourced) R file.
#
# 3. Only if you were unable to (or don't want to) set global environment
#   variables AND the R code you are working with is for YOUR USE ONLY and not
#   to be executed by OTHER PEOPLE, you can modify the standard header text that
#   you paste into your R file by replacing the "RSOURCEPATH =" statement with
#   these two statements, changing "YOUR HARD-CODED PATH(S) GO HERE" to the
#   paths for the above environment variables on your computer:
#       RSOURCEPATH = "YOUR HARD-CODED PATH(S) GO HERE"
#       Sys.setenv(RSOURCEPATH=RSOURCEPATH)
#
# 4. Subsequently, to source files or add libraries within a top-level R file,
#   use:
#
#   includeFile("<filename>" [, "<dir>"])   to include (source) a file
#   addThisLibrary("<filename>")            to install/add a CRAN library
#   addThisBioLibrary("<filename>")         to install/add a Bioconductor lib
#
# Author: Ted Toal, 13-Apr-2024
#
# Change log (most recent entry first):
#
# Date          Name        Description
# -----------   ----------- ----------------------------------------------------
# 13-Apr-2024   Ted         Changes for use in EV-battery-and-range-plots.
# 13-Apr-2021   Ted         Further tweaks to comments above.
#                           Change "YOUR HARD-CODED PATHS GO HERE"
# 12-Mar-2021   Ted         Create this file.
################################################################################


################################################################################
# Standard header code.
################################################################################
# If environment.txt exists, read it and assign env vars.
if (file.exists("~/environment.txt"))
    for (V in strsplit(readLines("~/environment.txt"), "=", fixed=TRUE))
        {
        S = system(paste0("bash -c '", V[1], '="', V[2], '"; echo $', V[1], "'"), intern=TRUE)
        do.call(Sys.setenv, setNames(as.list(S), V[1]))
        }
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
# Add required packages.
################################################################################

# (for example)
addThisLibrary("readbitmap")

################################################################################
# Include other R source code files.
################################################################################

includeFile("Include_UtilityFunctions.R")
includeFile("Include_TextFunctions.R")
includeFile("Include_PlotFunctions.R")
