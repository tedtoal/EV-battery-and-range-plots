#######################################################################################
# File that is "sourced" or "included" by the root R source code file named
# "Include_RootRsourceFile.R".
#
# ****************** EDIT THIS FILE TO DESIRED PREFERENCES ******************
# Define variables here that equal the directory pathname for directories commonly
# referenced in R files or in the filename variables defined below, so you don't have
# to put the same directory pathname in many different R code files.
#
# License: This file may be freely shared.
# Author: Ted Toal
# Date: Apr 2024
#
# Change log (most recent entry first):
#
# Date          Name        Description
# -----------   ----------- ----------------------------------------------------
# 24-Apr-2024   Ted         Update for use with EV-battery-and-range-plots.
# 08-Jan-2020   Ted         Add change log.
#######################################################################################

cat("Including Include_Customizations.R\n")

#######################################################################################
# Define variables containing paths to important folders by using environment variables
# or ENV_VARS.txt file to define them.  (See getEnvirVar() in Include_RootRsourceFile.R).
# If getEnvirVar() cannot find the specified environment variable, it uses the
# specified default value and issues a warning message.
#######################################################################################

LocalRootDir = getEnvirVar("LOCAL_ROOT", default="~/Documents/Tesla/EV-battery-and-range-plots",
    shortDesc="a path", longDesc="the root path to most data")

#######################################################################################
# Define variables containing paths to important folders located as subfolders of one
# of the above general folders.
#######################################################################################

# Subfolders in LocalRootDir folder.
IncludeDir = file.path(LocalRootDir, "includeFiles")

#######################################################################################
# End of file.
#######################################################################################
Sourced.Include_Customizations = TRUE
cat("  Include_Customizations.R included\n")
