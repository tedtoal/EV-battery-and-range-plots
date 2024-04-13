################################################################################
# This is a standard R code file to be included in every R code file as the
# FIRST file to be included.
#
# Read instructions in file stdhdr.R
#
# License: This file may be freely shared.
# Author: Ted Toal
# Date: Apr 2024
#
# Change log (most recent entry first):
#
# Date          Name        Description
# -----------   ----------- ----------------------------------------------------
# 13-Apr-2024   Ted         Change for use with EV-battery-and-range-plots.
# 12-Mar-2021   Ted         Create this file by copying Header_Code.R.
################################################################################

cat("Including Include_HeaderCode.R\n")

################################################################################
# Get directory in which this R script file is located, available when the file
# is executed using the "Rscript" command, NA if the R file was not run that way.
################################################################################

sDir = dirname(sub("^--file=", "", grep("^--file=", commandArgs(trailingOnly=FALSE), value=TRUE)[1]))

################################################################################
# Set "sourceDirs" to a vector of directory paths where the file
# "Include_RootRsourceFile.R" might be found.  "sourceDirs" is also useful in
# user code for sourcing files, e.g. source(findFile("MyFile.R", sourceDirs))
################################################################################

# Here we use (1) current working directory; (2) the sDir directory defined above.
sourceDirs = c(getwd(), sDir[!is.na(sDir)])

# If no element of directory vector sourceDirs contains the pattern
# "common[-_]repositories/rscripts/libraries$", get all files in all
# subdirectories exactly three levels below directory S, then search them
# for the pattern, append matching ones to sourceDirs, and return sourceDirs.
getLibrariesPaths = function(sourceDirs, S)
    {
    RE = file.path("common[-_]repositories", "rscripts", "libraries$")
    if (!any(grepl(RE, sourceDirs)))
        {
        S = unlist(sapply(S, function(s) file.path(s, dir(s)), simplify=FALSE), use.names=FALSE) # expecting common-repositories
        S = unlist(sapply(S, function(s) file.path(s, dir(s)), simplify=FALSE), use.names=FALSE) # expecting rscripts
        S = unlist(sapply(S, function(s) file.path(s, dir(s)), simplify=FALSE), use.names=FALSE) # expecting libraries
        sourceDirs = c(sourceDirs, S[grepl(RE, S)])
        }
    return(sourceDirs)
    }

# (4) if sDir above contains "common[-_]repositories", look in there for directory
# "rscripts/libraries", and if it exists, use it.
RE = "^(.*common[-_]repositories).*$"
if (grepl(RE, sDir))
    sourceDirs = getLibrariesPaths(sourceDirs, sub(RE, "\\1", sDir))

# (5) any directory in ":"-separated list of directories in the environment
# variable "RSOURCEPATH", which the user can set as R file search paths.
sourceDirs = c(sourceDirs, strsplit(Sys.getenv("RSOURCEPATH"), ":", fixed=TRUE)[[1]])

# (6) any directory sub-path "common[-_]repositories/rscripts/libraries" found
# within the following directories given by environment variables.
sourceDirs = getLibrariesPaths(sourceDirs, Sys.getenv("SOFTWARE_ROOT"))
sourceDirs = getLibrariesPaths(sourceDirs, file.path(Sys.getenv("LOCAL_ROOT"), "PACKAGES"))

# Only unique directories.
sourceDirs = unique(sourceDirs)

################################################################################
# Search for Include_RootRsourceFile.R
################################################################################

findFilename = "Include_RootRsourceFile.R"
hdrPaths = file.path(sourceDirs, findFilename);
found = file.exists(hdrPaths)
if (!any(found))
    stop(findFilename, " not found in any of:\n", paste(sourceDirs, collapse=":"))
path_Include_RootRsourceFile_R = hdrPaths[found][1]

################################################################################
# End of file.
################################################################################
Sourced.Include_HeaderCode = TRUE
cat("  Include_HeaderCode.R included\n")
