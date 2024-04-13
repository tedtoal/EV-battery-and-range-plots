################################################################################
# File to be "sourced" or "included" in each R code file as the very first
# "sourced" file, to define things useful to all other "sourced" files.
#
# To use this file, copy the code in Header_Code.R to the start of your R
# program file. That will cause your program to "source" this file.  Note that
# THIS file sources Include_Customizations.R, so that file should be in the same
# folder as this file, or otherwise locatable by findFile() below.
#
# License: This file may be freely shared.
# Author: Ted Toal
# Date: Apr 2024
#
# Change log (most recent entry first):
#
# Date          Name        Description
# -----------   ----------- ----------------------------------------------------
# 13-Apr-2024   Ted         Adjust license for EV-battery-and-range-plots.
# 13-Feb-2020   Ted         Add verbose argument to findFile and includeFile.
#                           Fix problem in findFile with slow recursive search.
# 08-Jan-2020   Ted         Add change log.
################################################################################

cat("Including Include_RootRsourceFile.R\n")

################################################################################
# Make sure Java memory is high.
################################################################################
options(java.parameters=c("-Djava.awt.headless=true", "-Xmx8000m"))

################################################################################
# Produce errors on partial matches.
# warnPartialMatchArgs=TRUE: NO!  This generates many errors, lots of packages
#   use abbreviated arg names.
################################################################################
#options(warnPartialMatchAttr=TRUE, warnPartialMatchDollar=TRUE)

################################################################################
# Linux does not seem to automatically load this library at startup, as does OSX.
################################################################################
library("methods")

################################################################################
# Get directory path separator (different between Unix/Linux/OSX and Windows).
################################################################################
PATHSEP = .Platform$file.sep

################################################################################
# If sourceDirs doesn't exist, make it empty (Header_Code.R defines it).
################################################################################
if (!exists("sourceDirs"))
    sourceDirs = c()

################################################################################
# This is to cat0() as paste0() is to paste(), i.e. the sep argument defaults to
# "". It does a flush of the console followed by a 1 ms sleep to allow the data
# to actually be printed to the console IF flush=TRUE.
################################################################################
cat0 = function(..., flush=TRUE)
	{
	cat(..., sep="")
	if (flush)
	    {
    	flush.console()
    	Sys.sleep(0.001)
    	}
	return(invisible(0))
	}

################################################################################
# Search for a file in various places and return the path to the first instance
# found.
#
# Arguments:
#   filename: the filename to look for, with or without a path.
#   paths: a vector of zero or more directories to be searched for the file.
#   topleveldir: a directory to be searched RECURSIVELY for the file, or NULL if none.
#   searchOrder: a string of one or more digits specifying where, and the order, to
#       search for the file.  The digits and the corresponding locations are:
#           1: use 'filename' argument as full path to look for file
#           2: look for file in current directory
#           3: look for file in same directory as THIS R file
#           4: look for file in same directory as the script file if it is run using Rscript
#           5: look for file in directories given by 'paths' argument
#           6: look for file in 'topleveldir' argument directory or its subdirectories
#           7: look for file in directories given by RSOURCEPATH environment variable
#           8: look for file in directory given by PROJdir variable, if defined
#   error1: a message to use when calling stop() if file not found, or NULL.
#   error2: a message to use when calling stop() if file is found multiple times under
#       the 'topleveldir' directory, or NULL.
#   globalPathVar: if not NULL, the name of a global vector containing paths (usually
#       the same variable that provides the 'paths' argument), to which to ADD the
#       path of the directory in which the file is found, if it is found in the
#       'topleveldir' directory tree.  This is so that if more files are searched
#       and they are in the same subdirectory, they will be found immediately.
#   verbose: if TRUE, directories being searched are printed.
#
# Returns: full path of file if found, or NULL if not found and error is NULL.
#
# Note: if more than one file with name 'filename' is found under 'topleveldir', an
# error message is issued.
################################################################################
findFile = function(filename, paths="", topleveldir=NULL, searchOrder="12345678",
    error1="File not found", error2="Multiple files found with same name",
    globalPathVar=NULL, verbose=FALSE)
    {
    topleveldir_num = 6 # searchOrder digit for topleveldir
    thisDir = dirname(getSourcedFileName())
    if (thisDir == "")
        thisDir = NA
    sDir = dirname(sub("^--file=", "", grep("^--file=", commandArgs(trailingOnly=FALSE), value=TRUE)[1]))
    if (is.null(topleveldir))
        topleveldir = NA
    if (!exists("PROJdir"))
        PROJdir = NA
    # dirs to search when searchOrder digit is 1..8
    dirs = list(
        fileDir=dirname(filename),                                                                  # 1
        cwd=getwd(),                                                                                # 2
        RfileDir=thisDir,                                                                           # 3
        scriptDir=sDir,                                                                             # 4
        pathsArg=paths,                                                                             # 5
        topLevelDir=topleveldir,                                                                    # 6
        RSOURCEPATH=unlist(strsplit(Sys.getenv("RSOURCEPATH"), ":", fixed=TRUE), use.names=FALSE),  # 7
        PROJdir=PROJdir)                                                                            # 8
    idxs = as.integer(strsplit(searchOrder, "", fixed=TRUE)[[1]])
    if (verbose)
        cat0("Search order: ", paste(idxs, collapse=","), "   dirs list: ", paste(dirs, collapse=","), "\n")
    for (i in idxs)
        {
        locName = names(dirs)[i]
        if (verbose)
            cat0("Searching location ", locName, "\n")
        for (dir1 in dirs[[locName]])
            {
            if (is.na(dir1))
                next
            if (verbose)
                cat0("Searching directory ", dir1)
            if (i != topleveldir_num)
                {
                if (verbose)
                    cat0("\n")
                fn = file.path(dir1, basename(filename));
                if (file.exists(fn))
                    return(fn)
                }
            else
                {
                if (verbose)
                    cat0(" recursively:\n")
                # The following statement has a problem: we want it to stop
                # immediately when it finds one match, but it continues until it
                # has searched ALL subdirectories to find ALL matches.  So, we
                # will have to roll our own recursive search.  Also, we want to
                # do a BREADTH-FIRST search, not a DEPTH-FIRST search.
                ##fn = dir(dir1, pattern=basename(filename), full.names=TRUE, recursive=TRUE)
                dirsSearch = function(dirs, basefilename)
                    {
                    for (dir1 in dirs)
                        {
                        if (verbose)
                            cat0("Searching directory ", dir1, "\n")
                        fn = dir(dir1, pattern=basefilename, full.names=TRUE)
                        if (length(fn) > 0)
                            return(fn)
                        }
                    dirs2 = c()
                    for (dir1 in dirs)
                        dirs2 = c(dirs2, dir(dir1, full.names=TRUE, no..=TRUE))
                    dirs2 = dirs2[dir.exists(dirs2)]
                    if (length(dirs2) > 0)
                        return(dirsSearch(dirs2, basefilename))
                    return(c())
                    }
                fn = dirsSearch(dir1, basename(filename))

                if (length(fn) > 0)
                    {
                    if (length(fn) == 1)
                        {
                        if (!is.null(globalPathVar))
                            {
                            pathDirs = get(globalPathVar)
                            fnDir = dirname(fn)
                            if (!any(fnDir == pathDirs))
                                assignGlobal(globalPathVar, c(pathDirs, fnDir))
                            }
                        return(fn)
                        }
                    if (!is.null(error2))
                        stop(error2, ": ", filename, ", directories: ",
                            paste(names(dirs), ":", unlist(dirs[idxs]), sep="", collapse=","))
                    return(NULL)
                    }
                }
            }
        }
    if (!is.null(error1))
        stop(error1, ": ", filename, ", directories: ",
            paste(names(dirs), ":", unlist(dirs[idxs]), sep="", collapse=","))
    return(NULL)
    }

################################################################################
# Call findFile() to search for an R program file, then source() that file.
#
# Arguments:
#   filename: the filename to look for, with or without a path.
#   topleveldir: a directory to be searched RECURSIVELY for the file, or NULL if
#       none.
#   searchOrder: a string of one or more digits specifying where, and the order,
#       to search for the file.  See findFile() same argument for details.
#   verbose: if TRUE, directories being searched are printed.
#
# Returns: nothing.  The file has been sourced.  If not found, stop() is called.
#
# Note: the directories given by vector 'sourceDirs' (defined by Header_Code.R)
# are included in the directories that are searched for the file.
################################################################################
includeFile = function(filename, topleveldir=NULL, searchOrder="12345678", verbose=FALSE)
    {
    filePath = findFile(filename, sourceDirs, topleveldir, searchOrder,
        globalPathVar="sourceDirs", verbose=verbose)
    cat0("Sourcing file: ", filePath, "\n")
    source(filePath)
    }

################################################################################
# This function is used to get an environment variable value for setting an R
# variable to the value of some important thing such as a directory path.  It
# also attempts to read file ENV_VARS.txt from the same folder this file resides
# in, and that file may contain environment variable definitions in the form
# VAR=VALUE.  If the environment variable isn't found, this issues a warning
# message to the user.
################################################################################
getEnvirVar = function(envirVarName, default, shortDesc, longDesc)
    {
    V = Sys.getenv(envirVarName)
    if (V == "")
        {
        # Get name of file to look for, containing variable assignments.
        ENV_VARS_FILE = findFile("ENV_VARS.txt", sourceDirs, globalPathVar="sourceDirs")
        if (file.exists(ENV_VARS_FILE))
            {
            S = readLines(ENV_VARS_FILE)
            S = strsplit(S, "=", fixed=TRUE)
            VARS = sapply(S, '[', 2)
            names(VARS) = sapply(S, '[', 1)
            if (any(names(VARS) == envirVarName))
                V = VARS[envirVarName]
            }
        }
    if (V == "")
        {
        V = default
        cat0("Couldn't find environment variable ", envirVarName, ", which sets ", longDesc, "\n")
        cat0("Define that environment variable to set ", shortDesc, ".  Or, put define it in file:\n")
        cat0(ENV_VARS_FILE, "\n")
        cat0("in the format VARIABLE=VALUE.  By default the value being used is: ", default, "\n\n")
        }
    return(V)
    }

################################################################################
# Find the name of the file being sourced() at the time this function is called.
#
# Arguments: None
#
# Returns: Name of file being sourced(), or "" if none.
################################################################################
getSourcedFileName = function()
    {
    thisDir = ""
    if (sys.nframe() > 0)
        for (i in -(1:sys.nframe()))
            if (identical(sys.function(i), base::source))
                {
                fn = sys.frame(i)$ofile
                if (length(fn) > 0)
                    {
                    thisDir = normalizePath(sys.frame(i)$ofile)
                    break
                    }
                }
    return(thisDir)
    }

################################################################################
# Require that a variable be defined, and optionally require it to be of a specific
# class.
#
# Arguments:
#   varName: name of variable that must be defined.
#   allowedClasses: vector of one or more names of allowed classes of varName.
#   myFileName: Basic filename of the file that is CALLING this function, for display
#       in error message.
################################################################################
requireDefined = function(varName, allowedClasses=NULL, myFileName)
    {
    if (!exists(varName))
        stop(myFileName, ".R requires that variable '", varName, "' be defined", call.=FALSE)
    if (!is.null(allowedClasses) && !class(get(varName)) %in% allowedClasses)
        stop(myFileName, ".R requires that variable '", varName, "' be of a specific class but it is instead class '",
            class(get(varName)), "'", call.=FALSE)
    }

################################################################################
# This function is used by sourced R files to test if other R files that they
# require have already been sourced, and if not, to stop with an error.  Each R
# source (include) file defines a variable of the form "Sourced_(file name) =
# TRUE" to indicate that it has been sourced.  E.g. THIS file defines
# Sourced.Include_RootRsourceFile = TRUE.
#
# To use this, if you make a new R file and it requires OTHER R files to be
# sourced before sourcing it, call this function in the new R file for each such
# other file. If the user sources your new file without first sourcing those
# other files, an error message is displayed.
#
# Arguments:
#   fileName: Basic filename of the file to be sourced, equal to the (file name)
#       value the "Sourced_(file name)" variable that the file defines to
#       indicate it has been sourced, without ".R".  For example, this basic
#       filename of THIS file is "Include_RootRsourceFile".
#   myFileName: Basic filename of the file that is CALLING this function, for
#       display in error message.
################################################################################
requireSourced = function(fileName, myFileName)
    {
    varName = paste0("Sourced.", fileName)
    if (!exists(varName))
        stop(myFileName, ".R requires that ", fileName, ".R be sourced", call.=FALSE)
    }

################################################################################
# This function is used by sourced R files to test if R PACKAGES that they
# require have already been installed and loaded, and if not, to stop with an
# error.
#
# To use this, if you make a new R file and it requires R packages, call this
# function in the new R file for each such package, to make sure it has been
# installed and loaded. If the user sources your new file without first loading
# those packages, an error message is displayed.
#
# Arguments:
#   package: Package name.
#   myFileName: Basic filename of the file that is calling this function, for
#       display in error message.
################################################################################
requirePackage = function(package, myFileName)
    {
    if (!(package %in% installed.packages()[,"Package"]))
        stop(myFileName, ".R requires that package ", package, " be installed", call.=FALSE)
    else if ( !isNamespaceLoaded(package))
        stop(myFileName, ".R requires that package ", package, " be loaded", call.=FALSE)
    }

################################################################################
# Call assign() using globalenv() for the envir argument, to assign "value" to a
# global variable with specified "name".
#
# When you assign a variable in a function, it disappears after you return from
# the function.  You may just want to return the variable from the function,
# e.g. "return(x)", or you may want it to be assigned globally so you can access
# it later from the R command line, by doing this:   assignGlobal("x", x)
################################################################################
assignGlobal = function(name, value)
    {
    assign(name, value, envir=globalenv())
    }

################################################################################
# Test if a global variable exists.
#   globalVar: global variable name.
# Return TRUE iff the global variable exists.
################################################################################
globalVarExists = function(globalVar)
    {
    return(exists(globalVar))
    }

################################################################################
# Delete global variable.
#   globalVar: global variable name.
################################################################################
deleteGlobalVar = function(globalVar)
    {
    if (exists(globalVar))
        {
        # Sometimes there is an error message about the environment being locked.
        # The following line is an attempt to eliminate that error, but it doesn't work.
        #unlockBinding(globalVar, globalenv())
        rm(list=globalVar, inherits=TRUE)
        }
    }

################################################################################
# Install a package if it isn't already installed.
################################################################################
installPackage = function(pkg, repos = getOption("repos"))
    {
    if (!(pkg %in% installed.packages()[,"Package"]))
        install.packages(pkg)
    }

################################################################################
# Load the specified package, and if it isn't installed, install it.
################################################################################
addThisLibrary = function(pkg, repos = getOption("repos"))
    {
    cat("Getting R package", pkg, "\n")
    if (!require(pkg, character.only=TRUE))
        installPackage(pkg, repos)
    }

################################################################################
# Install a Bioconductor package if it isn't already installed.
################################################################################
installBioPackage = function(pkg)
    {
    if (!(pkg %in% installed.packages()[,"Package"]))
        {
        addThisLibrary("BiocManager")
        BiocManager::install(pkg)
        }
    }

################################################################################
# Load the specified Bioconductor package, and if it isn't installed, install it.
################################################################################
addThisBioLibrary = function(pkg)
    {
    cat("Getting Bioconductor package", pkg, "\n")
    if (!require(pkg, character.only=TRUE))
        installBioPackage(pkg)
    }

################################################################################
# Update Bioconductor packages.
################################################################################
updateBioPackages = function()
    {
    addThisLibrary("BiocManager")
    BiocManager::install()
    }

################################################################################
# Return the full pathname of the file in directory 'dir' whose basename is
# 'base'.
################################################################################
getFullPath = function(dir, base)
    {
    return(file.path(dir, base))
    }

################################################################################
################################################################################
# Unconditionally load the very valuable "assertthat" library.
################################################################################
################################################################################
addThisLibrary("assertthat")

################################################################################
################################################################################
# Include customizations R file.  Set variables for local directory paths there.
################################################################################
################################################################################
includeFile("Include_Customizations.R")

################################################################################
# Load the specified package that exists in a special site-specific subfolder
# where multiple versions of the package may exist.
################################################################################
loadThisLocalPackageVersion = function(pkg, vsn)
    {
    cat("Loading site-specific package", pkg, "version", vsn, "\n")
    pkgDir = getPkgVsnRlibDir(pkg, vsn)
    .libPaths(pkgDir)
    if (!require(pkg, character.only=TRUE))
        stop("Package ", pkg, " version ", vsn, " not found in ", pkgDir)
    }

################################################################################
# End of file.
################################################################################
Sourced.Include_RootRsourceFile = TRUE
cat("  Include_RootRsourceFile.R included\n")
