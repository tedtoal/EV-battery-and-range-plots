#######################################################################################
# This file contains R definitions and functions relating to text printing and
# manipulation.
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
# 08-Jan-2020   Ted         Add change log.
#######################################################################################

cat("Including Include_TextFunctions.R\n")

#######################################################################################
# Convert a number of bytes into a human-readable number with the specified number
# of significant digits and specified separator between number and units suffix.
#######################################################################################
numBytes.to.human = function(numBytes, digits=2, sep=" ")
    {
    if (numBytes < 1e3)
        suffix = "bytes"
    else if (numBytes < 1e6)
        {
        numBytes = numBytes / 1e3
        suffix = "KB"
        }
    else if (numBytes < 1e9)
        {
        numBytes = numBytes / 1e6
        suffix = "MB"
        }
    else if (numBytes < 1e12)
        {
        numBytes = numBytes / 1e9
        suffix = "GB"
        }
    else if (numBytes < 1e15)
        {
        numBytes = numBytes / 1e12
        suffix = "TB"
        }
    else if (numBytes < 1e18)
        {
        numBytes = numBytes / 1e15
        suffix = "PB"
        }
    else
        {
        numBytes = numBytes / 1e18
        suffix = "EB"
        }
    numBytes = signif(numBytes, digits=digits)
    return(paste(numBytes, suffix, sep=sep))
    }

#######################################################################################
# Call cat() with the arguments, followed by flush.console() to ensure immediate output
# of the data.  Use this instead of cat() when long computations occur and you want to
# print something just before doing the computation.
#######################################################################################
catnow = function(...)
	{
	cat(...)
	flush.console()
	return(invisible(0))
	}

#######################################################################################
# Set the name of an output log file used by the printLog() function below.  If you
# don't set it, the default log file name is "defaultLogFile.txt".
#######################################################################################
outLogFile = "defaultLogFile.txt"
setDefaultLogFile = function(filename)
	{
	assignGlobal("outLogFile", filename)
	}

#######################################################################################
# Write the arguments to BOTH the console and the log file.  Arguments are like the
# cat() function arguments.  Use "file=filename" to specify a particular log file,
# otherwise the default log file set above is used.  You can also write the same output
# to multiple log files by using a vector of filenames for "file", and using NA in that
# vector causes output to the default log file set above.  To create a new log file and
# delete the old one, make the first call to this function use "append=FALSE".
# Note: output to the console can be suppressed by specifying toConsole=FALSE.  Also,
# if you set file="" (empty string), nothing is written to the log file.
#######################################################################################
printLog = function(..., sep=" ", append=TRUE, file=NA, toConsole=TRUE)
	{
	file[is.na(file)] = outLogFile
	if (toConsole)
	    {
	    cat(..., sep=sep)
	    flush.console()
	    }
	for (aFile in file)
	    if (aFile != "")
    	    cat(..., sep=sep, file=aFile, append=append)
	}

#######################################################################################
# Use this handy function to print out long strings of text, indented by some amount
# with the text reflowed to fit in a smaller space.
#
# Concatenate all unnamed arguments together into a single long string separated by the
# string given by sep, then break up that string into multiple lines, each prefixed by
# the string given by prefix, and each of length no more than len, breaking lines at
# spaces or \n, or if absolutely necessary, at an arbitrary character.  Return the
# resulting strings as a single long string containing \n at the end of each line
# including the last.
#######################################################################################
fillText = function(..., sep=" ", prefix="", len=80)
    {
    strs = unlist(strsplit(paste(..., sep=sep), "\n", fixed=TRUE))
	result = ""
	if (nchar(prefix) >= len || len < 1)
		stop("Invalid prefix or len in fillText()")
	# Loop for each line that is separated by "\n".
    for (str in strs)
    	{
    	line = prefix
    	tokens = unlist(strsplit(str, " ", fixed=TRUE))
    	for (token in tokens)
    		{
    		# Loop constant: there is room for at least one character before reaching len characters
    		# in line.

    		# If line has more than prefix on it, append a space to it before adding token.
    		if (line != prefix)
    			{
    			# If appending a space makes the line length be len, start a new line.
    			if (nchar(line) + 1 < len)
    				line = paste0(line, " ")
    			else
    				{
    				result = paste0(result, line, "\n")
    				line = prefix
    				}
				}
			# Loop outputting token characters to lines, until token is empty.
    		while (token != "")
    			{
				# If token fits leaving at least one character, add it to line.
				if (nchar(line) + nchar(token) + 1 <= len)
					{
					line = paste0(line, token)
					token = ""
					}
				# Else if line is not empty, start a new line.
				else if (line != prefix)
					{
					result = paste0(result, line, "\n")
					line = prefix
					}
				# Else line is currently empty, add as many chars of token as possible to line and
				# start a new line.
				else
					{
					roomFor = len - nchar(line)
					line = paste0(line, substr(token, 1, roomFor))
					token = substr(token, roomFor+1, 1000000L)
					result = paste0(result, line, "\n")
					line = prefix
					}
				}
			}
		# If line is not empty, append it to the results.
		if (line != prefix)
			result = paste0(result, line, "\n")
    	}
    return(result)
    }

#######################################################################################
# Print a small descriptive string followed by a possible-long descriptive string that
# may need to be broken up among multiple lines.  Use this for printing (to the console)
# things like:
#   AT7G01929     blah-blah-blah a long long description
# Here, "AT7G01929" is string1 and the rest is string2.
#
# Print string2 prefixed by string1.  Print string2 starting on the line AFTER string1,
# and fill those lines by using fillText to print string2, with the specified prefix
# string on each line.  If, however, string2 is NA or empty, just print "string1: (NONE)"
# if showNONE is TRUE.  If string2 consists of more than one string, they are collapsed
# into one string, using the specified collapse string as a separator.
#######################################################################################
catDescriptiveString = function(string1, string2, prefix, collapse=", ", showNONE=FALSE)
    {
    string2[is.na(string2) | string2 == "NA"] = ""
    string2 = paste(string2, collapse=collapse)
    if (gsub(collapse, "", string2) == "")
        {
        if (showNONE)
            cat(string1, " (NONE)\n")
        }
    else
        {
        cat(string1, "\n")
        cat(fillText(string2, prefix=prefix))
        }
    }

#######################################################################################
# Show any objects whose size is greater than N.  This is useful when you've made giant
# objects with R and wish to get rid of some unnecessary ones without closing R.
#######################################################################################
showBigObjs = function(N=10000000)
    {
    # This is not as easy as I thought.  We need to look in the local environments of
    # all stack frames on the calling stack, and look in all environments starting at
    # the global environment and moving up the parent list.
    sizes = c()
    frames = sys.frames()
    for (env in frames)
        {
        envSizes = sapply(ls(envir=env), function(x) object.size(try(get(x, envir=env), silent=TRUE)))
        envSizes = envSizes[envSizes >= N]
        sizes = c(sizes, envSizes)
        }
    env = environment()
    while (environmentName(env) != "R_EmptyEnv")
        {
        envSizes = sapply(ls(envir=env), function(x) object.size(try(get(x, envir=env), silent=TRUE)))
        envSizes = envSizes[envSizes >= N]
        sizes = c(sizes, envSizes)
        env = parent.env(env)
        }
    sizes = sort(unlist(sizes))
    print(as.data.frame(sizes))
    }

#######################################################################################
# Vector paste function.  Paste together elements of v, optionally ignoring empty
# strings and optionally pasting only one copy of duplicate strings.
#######################################################################################
vpaste = function(v, sep="", ignoreEmpty=TRUE, oneOfDuplicates=TRUE)
    {
    if (ignoreEmpty)
    	v = v[v != ""]
    if (oneOfDuplicates)
    	v = unique(v)
    return(paste(v, sep="", collapse=sep))
    }

#######################################################################################
# Expression paster.  This lets you make strings for plot labels containing formatted
# text such as subscripts, bold, math notation, etc.  See ?plotmath.  A limitation of
# the functionality described at ?plotmath is easily seen with this example:
#       x = 3.4
#       plot(1:10, main=expression(x^2))
# The plot title contains "x" with a 2 superscript.  What if you want 3.4 with a 2
# superscript?  This function lets you do it, as follows:
#       x = 3.4
#       plot(1:10, main=epaste(x, "^2"))
# To get the functionality where the title is "x" with a 2 superscript, do this:
#       plot(1:10, main=epaste("x^2"))
# If you wanted the title "x^2", do this:
#       plot(1:10, main=epaste("'x^2'"))
# And if you wanted the title "3.4^2", do this:
#       plot(1:10, main=epaste("'", x, "^2'"))
# Often you will need to surround text and characters you want to appear literally
# with quotes (use single since you will be using double quotes in the args to this
# function).  Also, the arguments to this function must form an expression that can
# be parsed, after pasting.  To do that, sometimes you need to include "*" in the
# expression to indicate pasting of expression elements, as in the following example
# (see ?plotmath).  Set the argument "debug" = TRUE to display the intermediate
# string to be parsed as an expression.
# Suppose you want the title "(x=3.4, y=5.6)" with superscript n on each number:
#       x = 3.4
#       y = 5.6
#       n = 3
#       plot(1:10, main=epaste("('x=", x, "'^", n, "*', y=", y, "'^", n, ")"))
# A final example.  Suppose you want R^2 = ###, superscript 2, ### is value of R2:
#       R2 = 0.879
#       plot(1:10, main=epaste("'R'^2*'='*", R2))
#######################################################################################
epaste = function(..., debug=FALSE)
    {
    L = list(..., sep="")
    S = do.call(paste, L)
    if (debug)
        cat0("S=/", S, "/\n")
    return(parse(text=S))
    }

#######################################################################################
# Compute the entropy of a vector whose elements are >= 0 and sum to 1.
# Arguments:
#   P: numeric vector whose entropy is to be computed.
# Returns: computed entropy, in bits.
# Notes: 0 entries in P are not included in the computation.  lim -P*log2(P) as P -> 0
# is 0 since P grows faster than log2(P).
#######################################################################################
entropy.P = function(P)
    {
    if (any(P < 0)) stop("entropy.P: all values must be >= 0")
    if (abs(sum(P) - 1) > 0.00001) stop("entropy.P: values must sum to 1")
    P = P[P != 0]
    H = sum(-P*log2(P))
    return(H)
    }

#######################################################################################
# Compute the entropy of a symbol string.
# Arguments:
#   S: symbol string whose entropy is to be computed.  Upper and lower case letters
#       are considered distinct.
# Returns: computed entropy, in bits.
#######################################################################################
entropy.S = function(S)
    {
    S = strsplit(S, "", fixed=TRUE)
    counts = table(S)
    return(entropy.P(counts/sum(counts)))
    }

#######################################################################################
# Read a FASTA file and extract sequence for each ID, reading nLinesAtOnce lines at a
# time and processing them.
# Return a vector of sequences, with the name being the sequence ID.
#######################################################################################
readFasta = function(filename, nLinesAtOnce=10000)
    {
    seqs = c()
    seqFile = file(filename, "r")
    txt = readLines(seqFile, nLinesAtOnce)
    while (length(txt) > 0 && substring(txt[1], 1, 1) == ">")
        {
        # Find all sequence start lines.
        idLines = which(grepl("^>", txt))
        # If there are at least nLinesAtOnce of text, save text for last sequence,
        # which may be incomplete, and remove it from txt vector.
        lastSeqTxt = c()
        if (length(txt) >= nLinesAtOnce)
            {
            lastSeq = idLines[length(idLines)]
            idLines = idLines[-length(idLines)]
            lastSeqTxt = txt[lastSeq:length(txt)]
            txt = txt[1:(lastSeq-1)]
            }
        # Get rid of "*" stop codon.
        txt = sub("*", "", txt, fixed=TRUE)
        # Get sequence IDs.
        seqIDs = sub("^>([^ \t\r]+)[ \t]?.*$", "\\1", txt[idLines])
        # Concatenate sequence lines for each sequence ID.
        seqFirstTxt = idLines+1
        seqLastTxt = c(idLines[-1]-1, length(txt))
        seqTxt = sapply(1:length(seqFirstTxt), function(i)
            paste(txt[seqFirstTxt[i]:seqLastTxt[i]], collapse=""))
        names(seqTxt) = seqIDs
        # Append these sequences to the seqs vector.
        seqs = c(seqs, seqTxt)
        # Now move on to the next set of text lines.
        txt = c(lastSeqTxt, readLines(seqFile, nLinesAtOnce))
        }
    close(seqFile)
    if (length(txt)!= 0) stop("Unexpected text in fasta file: ", txt);
    return(seqs)
    }

#######################################################################################
# End of file.
#######################################################################################
Sourced.Include_TextFunctions = TRUE
cat("  Include_TextFunctions.R included\n")
