#######################################################################################
# This file contains R definitions and functions relating to plotting data.
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
# 06-Feb-2020   Ted         In plotKmeansThresholds return NULL if len(unique(data)) < k.
# 08-Jan-2020   Ted         Add change log.
#######################################################################################

cat("Including Include_PlotFunctions.R\n")

#######################################################################################
# Arrays and a function for returning a number of *'s based on p-values.
#######################################################################################
# P-value breakpoints for increasing numbers of stars.
breaksStars = c(0.001, 0.01, 0.05, 99)
theStars = c("***", "**", "*", "")
getStars = function(P) { sapply(P, function(p) { if (is.na(p)) return(""); return(theStars[match(TRUE, p <= breaksStars)]) } ) }

#######################################################################################
# If you have the slope of a plotted line and you wish to know the angle corresponding
# to that slope ON THE PLOT, this function computes that. It is not simply atan(slope)
# because the scale of the X and Y axes may differ. THIS WORKS ONLY FOR NON-LOG AXES!
#
# Arguments:
#   m: slope value (dy/dx) for which you want an angle. May be a vector.
#   asDegrees: FALSE to return radians (+/- pi), TRUE for degrees (+/- 180).
#
# Returns: angle(s) corresponding to slope(s) m.
#######################################################################################
slopeToPlotAngle = function(m, asDegrees=TRUE)
    {
    usr = par("usr")
    plotdim = par("pin")
    ymult = (usr[2]-usr[1])/(usr[4]-usr[3]) * plotdim[2]/plotdim[1]
    ang = atan2(m*ymult, 1)
    if (asDegrees)
        ang = ang*180/pi
    return(ang)
    }

#######################################################################################
# Like slopeToPlotAngle, but takes (x, y) points as arguments and returns the slope at
# each adjacent set of points, and it also works when one or both axes are log-scale.
#
# Arguments:
#   x: vector of x-coords of 2 or more points on plot.
#   y: vector of y-coords of 2 or more points on plot, same length as x.
#   asDegrees: FALSE to return radians (+/- pi), TRUE for degrees (+/- 180).
#
# Returns: vector of angles made by lines connecting adjacent (x,y) points on
# the current plot, of length length(x)-1.
#######################################################################################
slopeToPlotAngleXY = function(x, y, asDegrees=TRUE)
    {
    if (length(x) != length(y))
        stop("slopeToPlotAngleXY requires x and y to be the same length")
    if (length(x) < 2)
        stop("slopeToPlotAngleXY requires x and y length to be > 1")
    xlog = par("xlog")
    ylog = par("ylog")
    usr = par("usr")
    plotdim = par("pin")
    if (xlog)
        x = log10(x)
    if (ylog)
        y = log10(y)
    dx = diff(x)
    dy = diff(y)
    m = dy/dx
    ymult = (usr[2]-usr[1])/(usr[4]-usr[3]) * plotdim[2]/plotdim[1]
    ang = atan2(m*ymult, 1)
    if (asDegrees)
        ang = ang*180/pi
    return(ang)
    }

#######################################################################################
# Find slope of line defined by the two non-NA points in (x, y) whose index in x and y is
# defined by arguments 'mode', 'f', and 'fWiden':
#   mode    description
#   ----    -----------
#   'f'     argument f gives fraction of distance from start to end of x at which to find the slope, 0=x[1], 1=x[length(x)]
#   'fx'    argument f gives fraction of distance between x-axis limits at which to find the slope
#   'fy'    argument f gives fraction of distance between y-axis limits at which to find the slope
#   '0'     find slope closest to 0
#   'M+'    find most-positive slope
#   'M-'    find most-negative slope
#   'L+'    find least-positive positive slope
#   'L-'    find least-negative negative slope
# If seekLeft is TRUE, then whenever the position identified by the 'mode' and 'f' arguments lies
# at an NA, the next non-NA position LEFT of that is used, while if seekLeft is FALSE, the next
# non-NA position RIGHT of that is used.
# If fWiden=0, the location identified is at TWO CONSECUTIVE non-NA points in (x, y).
# If fWiden>0 and <1, two points are chosen by expanding outwards by fWiden*length(x) points
# in each direction from the two consecutive points that are found. So for example if fWiden
# is 0.05, then the two points used are -5% and +5% away from the two consecutive non-NA
# points (but expansion never goes beyond an NA). For mode '0' only, fWiden is used to find
# the mean slope over a group of fWiden*length(x) adjacent points, and the smallest slope
# is used.
#
# Return a list with these members:
#   leftX: x-coordinate of first of the two non-NA points.
#   leftY: y-coordinate of first of the two non-NA points.
#   midX: x-coordinate of midpoint of the two non-NA points.
#   midY: y-coordinate of midpoint of the two non-NA points.
#   rightX: x-coordinate of second of the two non-NA points.
#   rightY: y-coordinate of second of the two non-NA points.
#   iLeft: index into x[] and y[] of first of the two non-NA points.
#   iRight: index into x[] and y[] of second of the two non-NA points.
#   slope: slope in degrees (-180..+180) of the line connecting the two points, as the
#       line appears on the plot.
#
# This works for logarithmic axes also.
#######################################################################################
findSlope = function(x, y, mode='f', f = 0.5, seekLeft=TRUE, fWiden=0)
    {
    if (f < 0 || f > 1)
        stop("findSlope requires f to be between 0 and 1")
    if (fWiden < 0 || fWiden > 1)
        stop("findSlope requires fWiden to be between 0 and 1")
    names(x) = NULL
    names(y) = NULL
    slopes = slopeToPlotAngleXY(x, y)
    # Get indicator of which elements of slopes[] have valid non-NA non-Inf slopes.
    indOK = !is.na(slopes) & !is.infinite(slopes)
    if (!any(indOK))
        stop("findSlope needs at least two adjacent points")
    # For mode='f', find valid slope whose position is closest to fraction f of 1:length(slopes).
    N = length(slopes)
    if (mode == 'f')
        {
        i = floor(f*N)
        }
    else if (mode == 'fx')
        {
        Ux = par("usr")[1:2]
        Vx = Ux[1] + f*diff(Ux)
        i = which.min(abs(Vx-x))
        }
    else if (mode == 'fy')
        {
        Uy = par("usr")[3:4]
        Vy = Uy[1] + f*diff(Uy)
        i = which.min(abs(Vy-y))
        }
    # Else for other modes, find best slope.
    else
        {
        idxPos = which(slopes >= 0)
        idxNeg = which(slopes < 0)
        if (mode == "M+")
            i = which.max(slopes)
        else if (mode == "M-")
            i = which.min(slopes)
        else if (mode == "L+")
            i = idxPos[which.min(slopes[idxPos])]
        else if (mode == "L-")
            i = idxNeg[which.max(slopes[idxNeg])]
        else if (mode != "0")
            stop("unknown mode argument: ", mode, " in findSlope")
        else
            {
            # Mode 0 requires special handling because it is possible slope will be 0 when it
            # changes very slowly. We want to find the region whose width is given by fWiden
            # that has the smallest mean slope.
            n = floor(fWiden*N)
            nn = 2*n+1
            meanSlopes = sapply(1:N, function(k)
                {
                if (k <= n)
                    k = n+1
                else if (k > N - n)
                    k = N - n
                return(mean(slopes[k + (-n:n)]))
                })
            i = which.min(abs(meanSlopes))
            }
        }
    # Look left or right if !indOK[i]
    if (is.na(i) || i < 1) i = 1
    if (i > N) i = N
    if (!indOK[i])
        {
        idxOK = which(indOK)
        isLeft = (idxOK < i)
        if (seekLeft)
            i = idxOK[isLeft][which.min(i - idxOK[isLeft])]
        else
            i = idxOK[!isLeft][which.min(idxOK[!isLeft] - i)]
        if (length(i) == 0)
            i = idxOK[which.min(abs(i - idxOK))]
        }
    # Expand outwards from i by fWiden*length(x) in both directions as long as points are adjacent.
    j = i
    n = floor(fWiden*N)
    if (n > 0)
        for (k in 1:n)
            {
            if (i > 1 && indOK[i-1])
                i = i - 1
            if (j < N && indOK[j+1])
                j = j + 1
            }
    j = j+1 # j indexes the right-side point of the point-pair, not the left-side point
    slope = slopeToPlotAngleXY(c(x[i], x[j]), c(y[i], y[j]))
    names(slope) = NULL
    iLeft = i
    iRight = j
    leftX = x[iLeft]
    leftY = y[iLeft]
    midX = mean(x[c(iLeft, iRight)])
    midY = y[round(mean(c(iLeft, iRight)))]
    rightX = x[iRight]
    rightY = y[iRight]
    return(list(leftX=leftX, leftY=leftY, midX=midX, midY=midY, rightX=rightX, rightY=rightY, iLeft=iLeft, iRight=iRight, slope=slope))
    }

#######################################################################################
# Several functions that follow are similar, differing in which R plot function they
# call.  Their purpose is to allow a user-defined function to support many different
# possible attributes for text, points, lines, etc. that the function might plot,
# without requiring an inordinate number of arguments to the function.  Instead, it
# can have list arguments, which become the L.args argument of the functions below,
# so that each such list argument replaces many individual arguments.
#
# The purpose of the L.default argument is so that the calling function can receive
# L.args as one of ITS arguments, but it can provide defaults for those arguments
# with L.default.
#
# The purpose of the ... argument is to provide an easier way for the caller to provide
# defaults if he wants to just specify them as named arguments rather than a list.
#
# The purpose of the L.vectArgs and idxs arguments are to provide an easier way to
# generate multiple vector arguments that are all supposed to be the same length, from
# a larger source such as a data frame that has many more rows than the vector length,
# and only a subset of those rows is to be used for the vector arguments.  The idxs
# vector is used to index into those larger vectors.  Note that a data frame can be
# converted to a list with as.list(df), where each list element is one data frame
# column.  Unfortunately, I wrote the code for the L.vectArgs mechanism long before I
# wrote these comments, and I've forgotten exactly how I used them, and cannot find an
# example (I think it's on my home computer now, was used in Brady lab).
#######################################################################################

#######################################################################################
# Call R function Rfunc with arguments given by ... and list L.args, with defaults from
# list L.default.  The precedence of the arguments is that L.args is highest, then
# L.default, then ... arguments.  If L.vectArgs is not NULL, it provides additional
# arguments that may be vectors of more than one element, and idxs is a vector of
# indexes into each L.vectArgs vector (the L.vectArgs vectors are recycled to length
# max(idxs)), and the L.vectArgs arguments are the highest precedence, higher than
# L.args.  The list of arguments used to call Rfunc is returned.  If Rfunc is NULL,
# it is not called, but the argument list is still returned.  See comments above for
# more information.
#######################################################################################
callRfunc = function(..., Rfunc, L.args=NULL, L.default=NULL, L.vectArgs=NULL, idxs=1)
    {
    # Initialize argument list with ... arguments.
    L = list(...)
    # Fill in any arguments provided by the L.default argument.
    for (arg in names(L.default))
        L[[arg]] = L.default[[arg]]
    # Fill in any arguments provided by the L.args argument.
    for (arg in names(L.args))
        L[[arg]] = L.args[[arg]]
    # Fill in any arguments provided by the L.args argument, using idxs and recycling.
    maxIdx = max(idxs)
    for (arg in names(L.vectArgs))
        L[[arg]] = rep(L.vectArgs[[arg]], length.out=maxIdx)[idxs]
    # Finally, call the Rfunc function.
    if (!is.null(Rfunc))
        do.call(Rfunc, L)
    return(invisible(L))
    }

#######################################################################################
# Plot points at position (x,y) using points() and arguments from list L.args,
# L.default, and  ... arguments.  The precedence of the arguments is that L.args is
# highest, then L.default, then ... arguments.  Additional vector-arguments in list
# L.vectArgs are all indexed by idxs.  This also adjusts x and y by recycling them
# both, since points() does not do that.  See callRfunc for more information.
#######################################################################################
plotPoints = function(x, y, type="p", pch=pchDot, col="black", cex=1, ...,
    L.args=NULL, L.default=NULL, L.vectArgs=NULL, idxs=1)
    {
    L = callRfunc(x=x, y=y, type=type, pch=pch, col=col, cex=cex, ...,
        Rfunc=NULL, L.args=L.args, L.default=L.default, L.vectArgs=L.vectArgs, idxs=idxs)
    N = LCM(c(length(L$x), length(L$y)))
    L$x = rep(L$x, length.out=N)
    L$y = rep(L$y, length.out=N)
    do.call(points, L)
    }

#######################################################################################
# Plot line segments from (x0,y0) to (x1,y1) using segments().  See plotPoints() for
# argument description.
#######################################################################################
plotSegments = function(x0, y0, x1=x0, y1=y0, ...,
    L.args=NULL, L.default=NULL, L.vectArgs=NULL, idxs=1)
    {
    callRfunc(x0=x0, y0=y0, x1=x1, y1=y1, ...,
        Rfunc=segments, L.args=L.args, L.default=L.default, L.vectArgs=L.vectArgs, idxs=idxs)
    }

#######################################################################################
# Plot line segments along points (x,y) using lines().  See plotPoints() for
# argument description.
#######################################################################################
plotLines = function(x, y, ..., L.args=NULL, L.default=NULL, L.vectArgs=NULL, idxs=1)
    {
    callRfunc(x=x, y=y, ...,
        Rfunc=lines, L.args=L.args, L.default=L.default, L.vectArgs=L.vectArgs, idxs=idxs)
    }

#######################################################################################
# Plot a rectangle at position (xleft, ybottom, xright, ytop) using rect().  See
# plotPoints() for argument description.
#######################################################################################
plotRect = function(xleft, ybottom, xright, ytop, ...,
    L.args=NULL, L.default=NULL, L.vectArgs=NULL, idxs=1)
    {
    callRfunc(xleft=xleft, ybottom=ybottom, xright=xright, ytop=ytop, ...,
        Rfunc=rect, L.args=L.args, L.default=L.default, L.vectArgs=L.vectArgs, idxs=idxs)
    }

#######################################################################################
# Plot an axis with the orientation given by 'side' using axis().  See plotPoints() for
# argument description.
#######################################################################################
plotAxis = function(..., L.args=NULL, L.default=NULL, L.vectArgs=NULL, idxs=1)
    {
    callRfunc(..., Rfunc=axis, L.args=L.args, L.default=L.default, L.vectArgs=L.vectArgs, idxs=idxs)
    }

#######################################################################################
# Plot text txt at position (x,y) using text().  See plotPoints() for argument
# description.  The height of the plotted text is returned.
# A problem is that the adj argument is in fractions of string width/height, so if
# different strings are different lengths, a single adjustment factor changes them by
# differing amounts.  To solve this, we accept here an additional argument named
# "delta" that is a vector (dx,dy) of fractions to be multiplied by the plot area
# (width,height) and then added to the (x,y) position of each string.
#######################################################################################
plotText = function(x, y, txt, col="black", cex=1, font=NULL, vfont=NULL,
    adj=NULL, pos=NULL, offset=0.5, ...,
    L.args=NULL, L.default=NULL, L.vectArgs=NULL, idxs=1)
    {
    # If adj and pos are specified (e.g. one by L.args, one by L.default), we want
    # L.args to take precedence regardless of whether it specified adj or pos.  So, if
    # L.args$adj is specified, set L.default$pos NULL.
    if (!is.null(L.args) && !is.null(L.args$adj) && !is.null(L.default))
        L.default$pos = NULL
    # Likewise, if L.vectArgs$adj is specified, set L.default$pos and L.args$pos NULL.
    if (!is.null(L.vectArgs) && !is.null(L.vectArgs$adj))
        {
        if (!is.null(L.default))
            L.default$pos = NULL
        if (!is.null(L.args))
            L.args$pos = NULL
        }
    # Merge the arguments.
    L = callRfunc(x=x, y=y, labels=txt, col=col, cex=cex, font=font, vfont=vfont,
        adj=adj, pos=pos, offset=offset, ...,
        Rfunc=NULL, L.args=L.args, L.default=L.default, L.vectArgs=L.vectArgs, idxs=idxs)
    # Add in the delta values.
    if (!is.null(L$delta))
        {
        usr = par("usr")
        L$x = L$x + L$delta[1]*diff(usr[1:2])
        L$y = L$y + L$delta[2]*diff(usr[3:4])
        L$delta = NULL
        }
    # Call the text() function.
    do.call(text, L)
    # And return string height info.
    return(invisible(strheight(txt, cex=L$cex, font=L$font, vfont=L$vfont)))
    }

#######################################################################################
# Plot text in margin using mtext().  See plotPoints() for argument description.  The
# height of the plotted text is returned.
#######################################################################################
plotMtext = function(text, side=3, line=0, ...,
    L.args=NULL, L.default=NULL, L.vectArgs=NULL, idxs=1)
    {
    # Merge the arguments.
    L = callRfunc(text=text, side=side, line=line, ...,
        Rfunc=NULL, L.args=L.args, L.default=L.default, L.vectArgs=L.vectArgs, idxs=idxs)
    # Call the mtext() function.
    do.call(mtext, L)
    # And return string height info.
    return(invisible(strheight(text, cex=L$cex, font=L$font, vfont=L$vfont)))
    }

#######################################################################################
# Plot a legend at (x,y) with text 'txt' using function legend().  See plotPoints()
# for argument description.
#######################################################################################
plotLegend = function(x, y=NULL, txt, ..., L.args=NULL, L.default=NULL, L.vectArgs=NULL, idxs=1)
    {
    callRfunc(x=x, y=y, legend=txt, ...,
        Rfunc=legend, L.args=L.args, L.default=L.default, L.vectArgs=L.vectArgs, idxs=idxs)
    }

#######################################################################################
# Plot arrows from (x0, y0) to (x1, y1) using arrows().  See plotPoints() for argument
# description.
#######################################################################################
plotArrow = function(x0, y0, x1, y1, ..., L.args=NULL, L.default=NULL, L.vectArgs=NULL, idxs=1)
    {
    callRfunc(x0=x0, y0=y0, x1=x1, y1=y1, ...,
        Rfunc=arrows, L.args=L.args, L.default=L.default, L.vectArgs=L.vectArgs, idxs=idxs)
    }

#######################################################################################
# Like plotArrow, but pairs of vertical arrows are plotted, and defaults are provided
# for x-position and angle of 90 degrees, length 0.025, color black, and lwd 1.  This
# is optimized for plotting error bars on bar plots.
#
# Arguments:
#   y: vector of y-positions of arrow starting points, NA for no arrow.
#   len.arrows.upper: NULL or vector of upper error bar lengths, NA means no arrow.
#   len.arrows.lower: NULL or vector of lower error bar lengths, NA means no arrow.
#   x: vector of x-positions of arrows, NA for no arrow.
#   See plotPoints() for remaining argument descriptions.
#######################################################################################
plotPairedVertArrows = function(y, len.arrows.upper, len.arrows.lower, x=1:length(y), ...,
    L.args=NULL, L.default=NULL, L.vectArgs=NULL, idxs=1)
    {
    # Collapse ... into L.default, L.default values take precedence.  We will
    # provide our own ... when calling plotArrow.
    L = list(...)
    for (arg in names(L.default))
        L[[arg]] = L.default[[arg]]
    L.default = L

    del = diff(par("usr")[3:4])/100
    if (!is.null(len.arrows.upper))
        {
        which.arrows.upper = !is.na(x) & !is.na(y) & !is.na(len.arrows.upper) & (len.arrows.upper > del)
        if (any(which.arrows.upper))
            {
            x.u = x[which.arrows.upper]
            y.u = y[which.arrows.upper]
            len.arrows.upper = len.arrows.upper[which.arrows.upper]
            plotArrow(x.u, y.u, x.u, y.u+len.arrows.upper, code=2, angle=90, length=0.025, col="black", lwd=1,
                L.args=L.args, L.default=L.default, L.vectArgs=L.vectArgs, idxs=idxs)
            }
        }

    if (!is.null(len.arrows.lower))
        {
        which.arrows.lower = !is.na(x) & !is.na(y) & !is.na(len.arrows.lower) & (len.arrows.lower > del)
        if (any(which.arrows.lower))
            {
            x.l = x[which.arrows.lower]
            y.l = y[which.arrows.lower]
            len.arrows.lower = len.arrows.lower[which.arrows.lower]
            plotArrow(x.l, y.l, x.l, y.l-len.arrows.lower, code=2, angle=90, length=0.025, col="black", lwd=1,
                L.args=L.args, L.default=L.default, L.vectArgs=L.vectArgs, idxs=idxs)
            }
        }
    }

#######################################################################################
# Plot error bars.
# Arguments:
#   y.pos: vector of y-positions of error bar centerpoints.  NA means no arrow.
#   barlengths: vector of (one half of) error bar lengths.  An element value of NA means
#       no arrow.
#   x.pos: vector of x-positions of error bar centerpoints.  NA means no arrow.
#   length: length of error bar cap lines.
#   col: color of error bars.
#   lwd: line width of error bars.
#######################################################################################
plotErrorBars = function(y.pos, barlengths, x.pos=1:length(y.pos), length=0.025, col="black", lwd=NULL)
    {
    plotPairedVertArrows(y.pos, barlengths, barlengths, x.pos, length=length, col=col, lwd=lwd)
    }

#######################################################################################
# Plot p-value * brackets in a bar plot.
# Arguments:
#   x.pos.left: vector of left-side of bracket x-positions of bar centers.
#   y.pos.left: vector of left-side of bracket y-positions of bar tops.
#   x.pos.right: vector of right-side of bracket x-positions of bar centers.
#   y.pos.right: vector of right-side of bracket y-positions of bar tops.
#   space.y: amount of y-space above top of bar before start of bracket AS A PERCENT OF
#       the plot height.
#   len.y: length of SMALLER vertical side of bracket AS A PERCENT of the plot height.
#   lwd: line width of bracket.
#   lty: line type of bracket.
#   col: color of bracket.
# Returns: list(x=vector, y=vector) of (x,y) positions of centers of top bracket lines.
# Notes: all arguments are recycled to length of longest one.
#######################################################################################
plotPvalueBrackets = function(x.pos.left, y.pos.left, x.pos.right, y.pos.right,
    space.y=2, len.y=5, lwd=NULL, lty=NULL, col=NULL)
    {
    if (is.null(col))
        col = "black"

    repx = function(x, N)
        {
        if (is.null(x))
            return(NULL)
        return(rep(x, length.out=N))
        }

    N = max(length(x.pos.left), length(y.pos.left), length(x.pos.right), length(y.pos.right),
        length(space.y), length(len.y), length(lwd), length(lty), length(col))
    x.pos.left = repx(x.pos.left, N)
    y.pos.left = repx(y.pos.left, N)
    x.pos.right = repx(x.pos.right, N)
    y.pos.right = repx(y.pos.right, N)
    space.y = repx(space.y, N)
    len.y = repx(len.y, N)
    lwd = repx(lwd, N)
    lty = repx(lty, N)
    col = repx(col, N)

    usr = par("usr")
    yspan = diff(usr[3:4])
    space.y = yspan*space.y/100
    len.y = yspan*len.y/100
    y.pos.left = y.pos.left + space.y
    y.pos.right = y.pos.right + space.y
    y.top = pmax(y.pos.left, y.pos.right) + space.y + len.y

    segments(x.pos.left, y.pos.left, x.pos.left, y.top, col=col, lwd=lwd, lty=lty)
    segments(x.pos.right, y.pos.right, x.pos.right, y.top, col=col, lwd=lwd, lty=lty)
    segments(x.pos.left, y.top, x.pos.right, y.top, col=col, lwd=lwd, lty=lty)

    return(list(x=(x.pos.left+x.pos.right)/2, y=y.top))
    }

#######################################################################################
# Compute the number of intervals to divide range rng into such that there are
# as many as possible but no more than tgtN intervals, an integer number of
# intervals, and such that the size of each interval is 1, 2, or 5 times 10 to
# an integer power.  If the span is not evenly divisible into 2, 5, 10, 20, 50, ...
# intervals, it is ALWAYS evenly divisible into 1 interval.
#
# Arguments:
#   rng: 2-element vector defining range to be divided into intervals.
#   tgtN: desired number of intervals, no more than this.
#   makeGood: TRUE to convert 'rng' to range(pretty.good(rng)) before computing result.
#
# Returns:
#   If makeGood is TRUE, a 3-element vector suitable for use as par(xaxp) or par(yaxp).
#   If makeGood is FALSE, the computed number of intervals is returned.
#######################################################################################
makeMultiple10of_1_2_5 = function(rng, tgtN, makeGood=FALSE)
    {
    if (makeGood)
        rng = range(pretty.good(rng))
    if (rng[1] == rng[2])
        rng[2] = rng[1] + 1
    span = diff(rng)
    tgtIntervalSize = span
    scale = 10^(floor(log10(span/tgtN)))
    Nintervals = 1 # Assume only one interval
    while (tgtIntervalSize >= scale)
        {
        # Test interval sizes scale*c(1, 2, 5)
        numIntervals = span/(scale*c(1, 2, 5))
        i = which(numIntervals <= tgtN & abs(numIntervals-round(numIntervals)) < 0.001)[1]
        if (!is.na(i))
            {
            Nintervals = round(numIntervals[i])
            break
            }
        scale = scale*10
        }

    if (makeGood)
        return(c(rng, Nintervals))
    return(Nintervals)
    }

#######################################################################################
# Plot a barplot of vector x or the row means of matrix x, plus optional outliers if x
# is a matrix.
#
# Arguments:
#   x: vector or matrix of data for which to plot bar plot, one bar per vector element
#       or matrix row.
#   ylim: range of y-axis, vector of two elements, or NULL to auto-choose it.
#   space: bar spacing as a fraction of bar width.
#   xpd: TRUE if bars can go up to top of page.
#   barnames.mtext: if not NULL, names are plotted below each bar, and this is a list of
#       arguments to the mtext() function to use when plotting them.  The default text if
#       not specified here is taken from the names (vector) or row names (matrix) of x.
#   barlabels.text: if not NULL, bar heights are plotted above each bar, and this is a
#       list of arguments to the text() function to use when plotting them.
#   plotType: "b": plot just bars; "l": plot just lines; "bl": plot both bars and lines.
#       If x is a vector, the vector values are plotted, while if x is a matrix, "b"
#       plots bars for the means of the x rows, while "l" plots a line for each x
#       column (on top of the bars if "bl").
#   barDataType: used only when x is a matrix.  The value "m" means the height of the
#       plotted bars is the mean value of each row of x, and the value "1" means to use
#       the first column of x for the bar height.
#   plotMaxOutliers: if x is a matrix and plotType is "b" and if this is >0, up to this
#       many outliers are plotted on top of the bars.
#   sdForOutlier: number of standard deviations that an x column's R^2 Pearson correlation
#       to the mean of all columns must lie beyond that mean of all column R^2's to be
#       called an outlier.
#   attr.lines: list of arguments to the lines() function to use for plotting each line's
#       values as a line graph on top of the bar plot, NULL to not plot.
#   attr.points: list of arguments to the points() function to use for plotting each line's
#       vertexes as points on top of the bar plot, NULL to not plot.
#   attr.legend: list of arguments to the legend() function to use if a legend is to be
#       plotted, or NULL to not plot a legend.  If columns of x are plotted, the default
#       legend text is x column names.
#   xlab: label of x-axis
#   main: plot title.
#   mainAttr.mtext: list of arguments to the mtext() function to use when plotting the title.
#   sub: plot subtitle.
#   subAttr.mtext: list of arguments to the mtext() function to use when plotting the subtitle.
#   xlab: label of x-axis
#   xlabAttr.mtext: list of arguments to the mtext() function to use when plotting xlab.
#   ylab: y-axis label
#   ylabAttr.mtext: list of arguments to the mtext() function to use when plotting ylab.
#   axes: TRUE to draw a y-axis.
#   yaxisAttr.axis: list of arguments to the axis() function to use when plotting the y-axis.
#   yaxisIntervals: approximate number of intervals desired on y-axis.
#
# Returns: bar center x-coordinates.
#
# Useful for debugging: assign L = list( args below ) and then:
#   for (n in names(L)) assignGlobal(n, L[[n]])
#######################################################################################
plotBarPlot = function(x, ylim=NULL, space=0.2, xpd=FALSE,
    barnames.mtext=list(), barlabels.text=NULL,
    plotType="b", barDataType="m", plotMaxOutliers=0, sdForOutlier=2,
    attr.lines=list(), attr.points=list(), attr.legend=NULL,
    main=NULL, mainAttr.mtext=NULL, sub=NULL, subAttr.mtext=NULL,
    xlab="", xlabAttr.mtext=NULL, ylab="", ylabAttr.mtext=NULL,
    axes=TRUE, yaxisAttr.axis=NULL, yaxisIntervals=10)
    {
    #####################################
    # Check some argument values.
    #####################################
    if (is.data.frame(x))
        x = as.matrix(x)
    if (!plotType %in% c("b", "bl", "l"))
        stop("plotBarPlot: unknown plotType value: ", plotType)
    if (!barDataType %in% c("m", "1"))
        stop("plotBarPlot: unknown barDataType value: ", barDataType)

    #####################################
    # Get the main bar values to plot.  May be needed even if bars are not plotted.
    #####################################
    isVector = (is.null(dim(x)) || length(dim(x)) == 1)
    if (isVector)
        x.main = x
    else if (barDataType == "m")
        x.main = apply(x, 1, mean, na.rm=TRUE)
    else
        {
        x.main = x[,1]
        x = x[,-1,drop=FALSE]
        }

    #####################################
    # Compute y-axis limits if not specified.
    #####################################
    if (is.null(ylim))
        ylim = range(pretty.good(c(0, x)))

    #####################################
    # Plot the bars if requested.
    #####################################
    width = 1
    mp = seq(space+width/2, by=space+width, length.out=length(x.main))
    xlim = c(0, max(mp)+width/2)
    if (plotType == "b" || plotType == "bl")
        {
        mp = barplot(x.main, width=1, space=space, xlim=xlim, ylim=ylim, xpd=xpd,
            xlab="", ylab="", main="", sub="", axes=FALSE, axisnames=FALSE)
        }
    else
        {
        plot(NA, type="n", xlim=xlim, ylim=ylim, axes=FALSE, xlab="", ylab="", main="", sub="")
        }

    #####################################
    # Plot bar names if requested.
    #####################################
    if (!is.null(barnames.mtext))
        {
        if (isVector)
            barnames = names(x)
        else
            barnames = rownames(x)
        plotMtext(barnames, side=BOTTOM, at=mp, L.args=barnames.mtext)
        # If there are no bars, plot x-axis with ticks only.
        if (plotType == "l")
            axis(side=BOTTOM, labels=FALSE, at=mp, tcl=0.25)
        }

    #####################################
    # Plot bar labels if requested.
    #####################################
    if (!is.null(barlabels.text))
        {
        # When a bar reaches almost to the top or beyond, plot its label inside the bar.
        x.label = mp
        y.label = x.main
        pastTop = (y.label > ylim[2]-0.05*diff(ylim))
        if (any(!pastTop))
            plotText(x.label[!pastTop], y.label[!pastTop], x.main[!pastTop],
                adj=c(0, 0.5), delta=c(0, 0.005), srt=90, L.args=barlabels.text)
        if (any(pastTop))
            {
            y.label[pastTop] = ylim[2]
            plotText(x.label[pastTop], y.label[pastTop], x.main[pastTop],
                adj=c(1, 0.5), delta=c(0, -0.005), srt=90, L.args=barlabels.text)
            }
        }

    #####################################
    # Plot title and subtitle.
    #####################################
    if (!is.null(main))
        plotMtext(main, side=3, line=1, L.args=mainAttr.mtext)
    if (!is.null(sub))
        plotMtext(sub, side=3, line=0, cex=0.8, L.args=subAttr.mtext)

    #####################################
    # Plot xlab and ylab.
    #####################################
    if (!is.null(xlab))
        plotMtext(xlab, side=BOTTOM, line=3, L.args=xlabAttr.mtext)
    if (!is.null(ylab))
        plotMtext(ylab, side=LEFT, line=2, L.args=ylabAttr.mtext)

    #####################################
    # Draw y-axis.
    #####################################
    if (axes)
        plotAxis(side=LEFT, pos=0, las=2, yaxp=makeMultiple10of_1_2_5(ylim, yaxisIntervals, TRUE),
            L.args=yaxisAttr.axis)

    #####################################
    # Set default legend title, text, and colors to NULL.  We will set them below if lines are plotted.
    #####################################
    legendTitle = NULL
    legendText = NULL
    legendColors = NULL

    #####################################
    # If x is a vector, plot it as a line/points if plotType is "l" or "bl".
    # If x is a matrix, plot its individual columns as lines/points if plotType is "l" or "bl", or plot outliers if plotType is "b".
    #####################################
    if (isVector)
        {
        #####################################
        # Plot x vector.
        #####################################
        if (plotType == "l" || plotType == "bl")
            {
            if (!is.null(attr.lines))
                plotLines(mp, x, col=colorBlind.8[1], lwd=2, L.args=attr.lines)
            if (!is.null(attr.points))
                plotPoints(mp, x, col=colorBlind.8[1], pch=pchDot, L.args=attr.points)
            }
        }
    else
        {
        #####################################
        # x is a matrix.  Assume ALL columns of x (plotType is "l" or "bl") or NO columns of x (plotType is "b").
        #####################################
        plotThese = which(rep(plotType != "b", ncol(x)))

        #####################################
        # If outliers are to be plotted, compute R^2 values and determine which ones to plot.
        #####################################
        if (plotType == "b" && plotMaxOutliers > 0)
            {
            # Compute correlation R^2 of x with x.main.
            R2 = cor.safe(x, x.main)^2

            # Look for outliers.
            numSDs = abs(R2-mean(R2))/sd(R2)
            outlier = which(numSDs >= sdForOutlier)
            if (length(outlier) > 0)
                {
                plotThese = outlier[order(numSDs[outlier], decreasing=TRUE)]
                numOutliers = length(plotThese)
                if (numOutliers > plotMaxOutliers)
                    plotThese = plotThese[1:plotMaxOutliers]

                # Set default legend title.  See epaste() comments.
                S = ""
                if (numOutliers > plotMaxOutliers)
                    S = paste0(", ", plotMaxOutliers, " of ", numOutliers)
                legendTitle = epaste("'Outliers, R'^2*' >= ", sdForOutlier, " stddevs", S, "'")
                }
            }

        #####################################
        # Now plot them.
        #####################################
        N = length(plotThese)
        if (N > 0)
            {
            # Set default legend text.
            legendText = colnames(x)[plotThese]

            # Use color-blind colors.  Use them as default legend colors.
            cols = rep(colorBlind.8, length.out=N)
            legendColors = cols

            # Plot the lines/points.
            for (i in 1:N)
                {
                if (!is.null(attr.lines))
                    plotLines(mp, x[, plotThese[i]], col=cols[i], lwd=2, L.args=attr.lines)
                if (!is.null(attr.points))
                    plotPoints(mp, x[, plotThese[i]], col=cols[i], pch=pchDot, L.args=attr.points)
                }
            }
        }

    #####################################
    # Plot legend if requested.  Don't try to plot it if neither us nor user supplied legend text.
    #####################################
    if (!is.null(attr.legend) && (!is.null(legendText) || !is.null(attr.legend$legend)))
        plotLegend(x="topright", lwd=2, txt=legendText, col=legendColors, title=legendTitle, L.args=attr.legend)

    return(invisible(mp))
    }

#######################################################################################
# Plot histogram of vector x or the row means of matrix x, plus optional outliers if x
# is a matrix.
#
# Arguments:
#   x: vector or matrix of data for which to plot histogram.
#   Nbars: number of bars to show.  makeMultiple10of_1_2_5() can be useful here.
#   xlim: range of x-axis, vector of two elements, or NULL to auto-choose it.
#   ylim: range of y-axis, vector of two elements, or NULL to auto-choose it.
#   space: bar spacing as a fraction of bar width.
#   xpd: TRUE if bars (such as overflow bar) can go up to top of page.
#   barlabels.text: if not NULL, bar heights are plotted above each bar, and this is a
#       list of arguments to the text() function to use when plotting them.
#   overflowBar: FALSE or "" to not add an overflow bar; "+" or TRUE to add one extra
#       bar (Nbars+1) at right side to show counts of values larger than xlim[2]; "-"
#       to use the right-most bar (Nbars) as an overflow bar, meaning that its histogram
#       value will not influence the calculation of ylim when ylim is not specified by
#       the user, and that the overflow bar will be labelled specially.
#   overflow.text: if this isn't NULL, the overflow bar size is plotted beside the bar,
#       and this is a list of arguments to the text() function to use when plotting it.
#   plotType: "b": plot just bars; "l": plot just lines; "bl": plot both bars and lines.
#       If x is a vector, a histogram of the vector values are plotted, while if x is
#       a matrix, "b" plots bars for the histogram specified by barHistType, while "l"
#       plots a line for the histograms of each x column (on top of the bars if "bl").
#   barHistType: used only when x is a matrix.  The value "a" means plotted bars are a
#       histogram of all non-NA entries in x with no scale factor, "as" means the same
#       but dividing the histogram counts by the number of columns in x to normalize it
#       to the value of the column histograms, the value "m" means they are a histogram
#       of the mean value of each row of x, and the value "1" means to use the first
#       column of x for the histogram used for plotting the bars.  See note.
#   plotMaxOutliers: if x is a matrix, then if this is >0, up to this many outliers are
#       plotted as lines.
#   sdForOutlier: number of standard deviations that an x column's R^2 Pearson correlation
#       to the mean of all columns must lie beyond that mean of all column R^2's to be
#       called an outlier.
#   attr.lines: list of arguments to the lines() function to use for plotting each line's
#       values as a line graph on top of the bar plot, NULL to not plot.
#   attr.points: list of arguments to the points() function to use for plotting each line's
#       vertexes as points on top of the bar plot, NULL to not plot.
#   attr.legend: list of arguments to the legend() function to use if a legend is to be
#       plotted, or NULL to not plot a legend.  If columns of x are plotted, the default
#       legend text is x column names.
#   main: plot title.
#   mainAttr.mtext: list of arguments to the mtext() function to use when plotting the title.
#   sub: plot subtitle.
#   subAttr.mtext: list of arguments to the mtext() function to use when plotting the subtitle.
#   xlab: label of x-axis
#   xlabAttr.mtext: list of arguments to the mtext() function to use when plotting xlab.
#   ylab: y-axis label
#   ylabAttr.mtext: list of arguments to the mtext() function to use when plotting ylab.
#   axes: "x" or "y" or "xy" to indicate axes to draw.
#   xaxisAttr.axis: list of arguments to the axis() function to use when plotting the x-axis.
#   yaxisAttr.axis: list of arguments to the axis() function to use when plotting the y-axis.
#   xaxisIntervals: approximate number of intervals desired on x-axis.
#   yaxisIntervals: approximate number of intervals desired on y-axis.
#
# Returns: nothing.
#
# Note: When x is a matrix, plotted lines (plotType is 'bl' or 'l') are always a histogram
# of the columns of x (one line and color per column of x).  The histogram used to plot the
# bars differs depending on the value of barHistType.  If it is 'a' or 'as', all non-NA values
# in the entire x matrix are used to compute the histogram, dividing histogram counts by the
# number of columns in x if 'as'.  If it is 'm' (the default), the mean is taken of each row
# of x, ignoring NA values, and then the histogram is computed from those mean values.  If it
# is '1', the first column of x is used to compute the histogram.  There
# are at least five ways an x matrix can be used to plot the bars:
#   1. barHistType = 'a': all the values in the matrix might be different, and a histogram
#       of all of them is plotted.  Because there are many more values than in a single x
#       column, it doesn't make sense to compare the bar histogram against histograms for
#       each column, so plotType should be 'b'.
#   2. barHistType = 'as': like the previous, but in this case the counts are divided by the
#       number of columns, so it can be legitimate to compare against the histograms for each
#       column.
#   3. barHistType = 'm' and each x row is a vector of POSSIBLY DIFFERENT values.  In that
#       case, a histogram of the mean of each row must be a reasonable thing to compare
#       against the histograms for each column.
#   4. barHistType = 'm' and each x row is a vector consisting of NAs and A SINGLE NUMERIC
#       VALUE repeated at one or more positions on that row.  In this case, the mean of
#       the row is just that single numeric value, which is the only value seen on the row
#       other than NA.  In this case, it is the presence of the NAs that cause the column
#       histograms to differ from the mean-value histogram shown by the bars.
#       For example, the matrix rows might correspond to variants called by numerous variant
#       callers, each caller corresponding to a matrix column.  The numeric value in each
#       row could be anything having to do with that variant (and is NOT determined by the
#       caller; it is the same regardless of caller).  An NA is used if the caller did not
#       call that variant.  This makes it possible to see whether certain values cause a
#       caller to see more or fewer variants.
#   5. barHistType = '1': gives control over exactly which values are used in the histogram
#       for the bars, versus those used in histograms for the lines.
#
# Useful for debugging: assign L = list( args below ) and then:
#   for (n in names(L)) assignGlobal(n, L[[n]])
#######################################################################################
plotHist = function(x, Nbars=50, xlim=NULL, ylim=NULL, space=0.2, xpd=FALSE, barlabels.text=NULL,
    overflowBar="", overflow.text=list(), plotType="b", barHistType="m",
    plotMaxOutliers=0, sdForOutlier=2, attr.lines=list(), attr.points=list(),
    attr.legend=NULL, main=NULL, mainAttr.mtext=NULL, sub=NULL, subAttr.mtext=NULL,
    xlab="", xlabAttr.mtext=NULL, ylab="Count", ylabAttr.mtext=NULL,
    axes="xy", xaxisAttr.axis=NULL, yaxisAttr.axis=NULL, xaxisIntervals=10, yaxisIntervals=10)
    {
    #####################################
    # Check some argument values.
    #####################################
    if (is.data.frame(x))
        x = as.matrix(x)
    if (!plotType %in% c("b", "bl", "l"))
        stop("plotHist: unknown plotType value: ", plotType)
    if (!barHistType %in% c("m", "a", "as", "1"))
        stop("plotHist: unknown barHistType value: ", barHistType)
    if (!is.logical(overflowBar) && !overflowBar %in% c("", "+", "-"))
        stop("plotHist: unknown overflowBar value: ", overflowBar)
    if (is.logical(overflowBar))
        overflowBar = ifelse(overflowBar,"+","")

    #####################################
    # Get the main values to plot.
    #####################################
    isVector = (is.null(dim(x)) || length(dim(x)) == 1)
    if (isVector)
        x.main = x
    else if (barHistType == "m")
        x.main = apply(as.matrix(x), 1, mean, na.rm=TRUE)
    else if (barHistType == "1")
        {
        x.main = x[,1]
        x = x[,-1,drop=FALSE]
        }
    else
        x.main = as.vector(as.matrix(x))
    x.main = x.main[!is.na(x.main)]

    #####################################
    # Compute break positions, then get histogram data.
    #####################################
    Nbreaks = Nbars + 1 + (overflowBar == "+")
    if (is.null(xlim))
        {
        xlim = range(x.main)
        if (xlim[1] > 0 && xlim[1] < xlim[2]/10)
            xlim[1] = 0
        }
    breaks = seq(xlim[1], xlim[2], length.out=Nbars+1)
    if (overflowBar != "")
        breaks[Nbreaks] = max(x.main)
    # Remove values in x.main lying outside xlim (there won't be any if we computed
    # xlim, but if user provided it, there might be).
    x.main = x.main[x.main >= xlim[1]]
    if (overflowBar == "")
        x.main = x.main[x.main <= xlim[2]]
    h = hist(x.main, breaks, plot=FALSE, right=FALSE)
    main.counts = h$counts
    if (barHistType == "as")
        main.counts = round(main.counts / ncol(x))

    #####################################
    # Compute y-axis limits.
    #####################################
    N = length(main.counts)
    if (is.null(ylim))
        {
        countsExceptOverflowBar = main.counts
        if (overflowBar != "")
            countsExceptOverflowBar = countsExceptOverflowBar[-N]
        if (all(countsExceptOverflowBar == 0))
            ylim = 0:1
        else
            ylim = range(pretty.good(c(0, countsExceptOverflowBar)))
        }

    #####################################
    # Plot the bars if requested.
    #####################################
    width = 1
    bar.xspacing = space+width
    # We don't supply xlim here for plotting.  We already ensured that the histogram
    # we generate runs between xlim limits.  We want the bars to be spread across
    # the full plot area, which is what barplot() does by default, assigning x
    # coordinates based on space and width parameters.
    if (plotType == "b" || plotType == "bl")
        {
        mp = barplot(main.counts, width=width, space=space, ylim=ylim, xpd=xpd,
            xlab="", ylab="", main="", axes=FALSE, axisnames=FALSE)
        }
    else
        {
        mp = seq(bar.xspacing/2, by=bar.xspacing, length.out=length(main.counts))
        plot(NA, type="n", xlim=c(0, bar.xspacing*length(mp)), ylim=ylim, axes=FALSE,
            xlab="", ylab="", main="", sub="")
        }

    #####################################
    # Plot bar labels if requested.
    #####################################
    if (!is.null(barlabels.text) || overflowBar != "")
        {
        # Get bar positions.
        if (!is.null(barlabels.text))
            {
            x.label = mp
            y.label = main.counts
            }
        else
            {
            x.label = mp[length(mp)]
            y.label = main.counts[length(main.counts)]
            }
        labels = y.label

        # When a bar reaches almost to the top or beyond, plot its label inside the bar.
        pastTop = (y.label > ylim[2]-0.05*diff(ylim))
        if (any(!pastTop))
            plotText(x.label[!pastTop], y.label[!pastTop], labels[!pastTop],
                adj=c(0, 0.5), delta=c(0, 0.005), srt=90, L.args=barlabels.text)
        if (any(pastTop))
            {
            y.label[pastTop] = ylim[2]
            plotText(x.label[pastTop], y.label[pastTop], labels[pastTop],
                adj=c(1, 0.5), delta=c(0, -0.005), srt=90, L.args=barlabels.text)
            }
        }

    #####################################
    # Plot title and subtitle.
    #####################################
    if (!is.null(main))
        plotMtext(main, side=3, line=1, L.args=mainAttr.mtext)
    if (!is.null(sub))
        plotMtext(sub, side=3, line=0, cex=0.8, L.args=subAttr.mtext)

    #####################################
    # Plot xlab and ylab.
    #####################################
    if (!is.null(xlab))
        plotMtext(xlab, side=BOTTOM, line=3, L.args=xlabAttr.mtext)
    if (!is.null(ylab))
        plotMtext(ylab, side=LEFT, line=2, L.args=ylabAttr.mtext)

    #####################################
    # Draw x-axis.
    #####################################
    if (grepl("x", axes))
        {
        # This is more complex because of the overflow bar.  When it is present,
        # we want the last x-axis label to be centered on it.
        # Start by creating axis tick positions and labels based on a pretty.good()
        # version of xlim, created using makeMultiple10of_1_2_5(, TRUE).
        xaxp = makeMultiple10of_1_2_5(xlim, xaxisIntervals, TRUE)
        numLabels = xaxp[3]+1

        # xaxp defines the labels for us.
        labels.xaxis = seq(xaxp[1], xaxp[2], length.out=numLabels)

        # We need the x-position of those labels.  How do we get that?  The x-positions
        # of the centers of the bars is in mp.  The label values for the bins for each
        # bar are in breaks.  The midpoint between each adjacent pair of breaks is the
        # label value that matches the x-position in mp, and those midpoints are:
        breaks.mp = (breaks[-1]+breaks[-Nbreaks])/2  # Length is Nbars.

        # Therefore, a label value of L is mapped to the x-coordinate:
        #   mp[1] + (L-breaks.mp[1])*(mp[Nbars]-mp[1])/(breaks.mp[Nbars]-breaks.mp[1])
        # If you plug in breaks.mp[1] or breaks.mp[Nbars] for L, you get x-positions
        # mp[1] and mp[Nbars], correct.

        # Compute x-positions of labels.xaxis.
        at.xaxis = mp[1] + (labels.xaxis-breaks.mp[1])*(mp[Nbars]-mp[1])/(breaks.mp[Nbars]-breaks.mp[1])

        # Now, get rid of tick positions and labels of labels lying outside xlim
        # (which they will if pretty.good(xlim) is not equal to xlim).
        rmv = (labels.xaxis < xlim[1] | labels.xaxis > xlim[2])
        at.xaxis = at.xaxis[!rmv]
        labels.xaxis = labels.xaxis[!rmv]
        numLabels = length(at.xaxis)

        # Adjust last label and tick if an overflow bar is present.
        # We want to place the last tick mark right on the center of the final bar
        # and label it with ">= L", where L = the start of the last histogram bin.
        if (overflowBar != "")
            {
            L = breaks.mp[Nbars]
            x.L = mp[Nbars]

            # The last label might be somewhere near L (either a little before or after it),
            # or it might be considerably left of L.  If the latter, add an extra last label.
            if ((L-labels.xaxis[numLabels])/diff(xlim) > 0.05) # 5% of x-space is enough to add a label.
                {
                numLabels = numLabels + 1
                labels.xaxis[numLabels] = NA
                at.xaxis[numLabels] = NA
                }

            # Set the last label to be ">= L" and set its x-coordinate to x.L.
            labels.xaxis[numLabels] = paste0(">=", L)
            at.xaxis[numLabels] = x.L
            }
        plotAxis(side=BOTTOM, at=at.xaxis, labels=labels.xaxis, L.args=xaxisAttr.axis)
        }

    #####################################
    # Draw y-axis.
    #####################################
    if (grepl("y", axes))
        plotAxis(side=LEFT, pos=0, las=2, yaxp=makeMultiple10of_1_2_5(ylim, yaxisIntervals, TRUE),
            L.args=yaxisAttr.axis)

    #####################################
    # Set default legend title, text, and colors to NULL.  We will set them below if lines are plotted.
    #####################################
    legendTitle = NULL
    legendText = NULL
    legendColors = NULL

    #####################################
    # If x is a vector, plot it's histogram as a line/points if plotType is "l" or "bl".
    # If x is a matrix, plot the histograms of its individual columns as lines/points
    # if plotType is "l" or "bl", or plot outliers if plotType is "b".
    #####################################
    if (isVector)
        {
        #####################################
        # Plot histogram of x vector, in main.counts.
        #####################################
        if (plotType == "l" || plotType == "bl")
            {
            if (!is.null(attr.lines))
                plotLines(mp, main.counts, col=colorBlind.8[1], lwd=2, L.args=attr.lines)
            if (!is.null(attr.points))
                plotPoints(mp, main.counts, col=colorBlind.8[1], pch=pchDot, L.args=attr.points)
            }
        }
    else
        {
        #####################################
        # x is a matrix.  Assume that we plot the histograms of ALL columns of x (plotType is "l" or "bl")
        # or NO columns of x (plotType is "b").
        #####################################
        plotThese = which(rep(plotType != "b", ncol(x)))

        #####################################
        # Compute histogram for each column of x, putting it in matrix h.counts.
        #####################################
        h.counts = NULL
        for (i in 1:ncol(x))
            {
            x.col = x[,i]
            x.col = x.col[x.col >= xlim[1]]
            if (overflowBar == "")
                x.col = x.col[x.col <= xlim[2]]
            x.col = x.col[!is.na(x.col)]
            h = hist(x.col, breaks, plot=FALSE, right=FALSE)
            h.counts = cbind(h.counts, h$counts)
            }
        colnames(h.counts) = colnames(x)

        #####################################
        # If outliers are to be plotted, compute R^2 values and determine which ones to plot.
        #####################################
        if (plotType == "b" && plotMaxOutliers > 0)
            {
            # Compute correlation R^2 of h.counts with main.counts.  Exclude overflow bar,
            # whether it is "+" or "-" overflow bar.
            lastRbar = Nbars - (overflowBar == "-")
            R2 = cor.safe(h.counts[1:lastRbar,], main.counts[1:lastRbar])^2

            # Look for outliers.
            numSDs = abs(R2-mean(R2))/sd(R2)
            outlier = which(numSDs >= sdForOutlier)
            if (length(outlier) > 0)
                {
                plotThese = outlier[order(numSDs[outlier], decreasing=TRUE)]
                numOutliers = length(plotThese)
                if (numOutliers > plotMaxOutliers)
                    plotThese = plotThese[1:plotMaxOutliers]

                # Set default legend title.  See epaste() comments.
                S = ""
                if (numOutliers > plotMaxOutliers)
                    S = paste0(", ", plotMaxOutliers, " of ", numOutliers)
                legendTitle = epaste("'Outliers, R'^2*' >= ", sdForOutlier, " stddevs", S, "'")
                }
            }

        #####################################
        # Now plot them.
        #####################################
        N = length(plotThese)
        if (N > 0)
            {
            # Set default legend text.
            legendText = colnames(x)[plotThese]

            # Use color-blind colors.  Use them as default legend colors.
            cols = rep(colorBlind.8, length.out=N)
            legendColors = cols

            # Plot the lines/points.
            lastPoint = Nbars + (overflowBar == "+")
            for (i in 1:N)
                {
                if (!is.null(attr.lines))
                    plotLines(mp[1:lastPoint], h.counts[1:lastPoint, plotThese[i]], col=cols[i], lwd=2,
                        L.args=attr.lines)
                if (!is.null(attr.points))
                    plotPoints(mp[1:lastPoint], h.counts[1:lastPoint, plotThese[i]], col=cols[i], pch=pchDot,
                        L.args=attr.points)
                }
            }
        }

    #####################################
    # Plot legend if requested.  Don't try to plot it if neither us nor user supplied legend text.
    #####################################
    if (!is.null(attr.legend) && (!is.null(legendText) || !is.null(attr.legend$legend)))
        plotLegend(x="topright", lwd=2, txt=legendText, col=legendColors, title=legendTitle, L.args=attr.legend)
    }

#######################################################################################
# Plot a set intersection matrix.  This is described in:
#   Lex, Alexander, and Nils Gehlenborg. "Points of view: Sets and intersections."
#   Nature Methods 11.8 (2014): 779-779.
# and depicted in Fig. 1b there.
#
# Arguments:
#   x: describes the set intersections to plot, one of:
#       (1) a numeric vector with each member giving the size of one set intersection
#           (size doesn't have to be integer).  The vector names are the names of the
#           sets that are contained in that intersection, separated by 'sep'.
#           Ex: (2,1,1) with names ("A","A:B","B")
#       (2) a character vector with one member per set element, containing a string of
#           names of the sets of which that element is a member, separated by the
#           'sep' character.  Ex: c("A","A","A:B","B")
#       (3) a binary or logical data frame or matrix with the set names as column names
#           and with one row per element, and an entry is 1 or TRUE if that element is
#           in that set, 0 or FALSE if not.  Ex: A  B
#                                                1  0
#                                                1  0
#                                                1  1
#                                                0  1
#       (4) like 3 but no two rows are identical, and an additional column is present
#           as the first column, and its name is blank (""), and it contains a COUNT
#           of the number of elements in the set intersection defined by that row.
#                                          Ex:   A  B
#                                             2  1  0
#                                             1  1  1
#                                             1  0  1
#       (5) a character matrix or data frame with two columns.  Column 1 contains set
#           element names and column 2 contains a name of one set (out of possibly many)
#           that that element is in.  Ex: (w, A) (x, A) (y, A) (x, B) (z, B)
#   sets: vector of set names, or NULL to use all unique set names in x.  May contain names not in x.
#       Exactly these sets are plotted, even if others contain some members.
#   sep: character that separates set names in names(x).
#   xlim: x-axis limits.  May be a 1-element vector giving width of the per-set bar area as a
#       fraction of the width of the main bar area, or a 2-element vector where xlim[1] is negative
#       width of per-set bar area and xlim[2] >= number of set intersections to display all main bars.
#   ylim: y-axis limits, May be a 1-element vector giving height of the intersection matrix area as
#       a fraction of the width of the main bar area, or a 2-element vector where ylim[1] is negative
#       height of intersection matrix and ylim[1] >= largest intersection size to display entire bar
#       for all main bars.
#   main: plot title.
#   mainAttr.mtext: list of arguments to the mtext() function to use when plotting the title.
#   sub: plot subtitle.
#   subAttr.mtext: list of arguments to the mtext() function to use when plotting the subtitle.
#   xlab: label of tiny x-axis
#   xlabAttr.text: list of arguments to the text() function to use when plotting xlab.
#   ylab: y-axis label
#   ylabAttr.text: list of arguments to the text() function to use when plotting ylab.
#   axes: "x" or "y" or "xy" to indicate axes to draw.  The x-axis is a tiny x-axis above per-set bar area.
#   xaxisAttr.axis: list of arguments to the axis() function to use when plotting the tiny x-axis.
#   yaxisAttr.axis: list of arguments to the axis() function to use when plotting the y-axis.
#   yaxisIntervals: approximate number of intervals desired on y-axis.
#   mainBarWidth: Main bar width as a fraction of the available space.
#   mainBarHeight: Height of area containing main bars, as a fraction of tallest bar height, used only if
#       ylim is one element.  Use a value greater than 1 to add space above bars.
#   mainBarSpace: Main bar spacing as a fraction of the available space.
#   setBarWidth: Per-set bar width as a fraction of the available space.
#   setBarSpace: Per-set bar spacing as a fraction of the available space.
#   setNameWidth: Width of area containing set names, as a fraction of available width (see ylim[1]).
#   mainBars.rect: list of arguments to the rect() function to use when plotting the main bars.
#   setBars.rect: list of arguments to the rect() function to use when plotting the per-set bars.
#   mainBarLabels.text: if this isn't NULL, intersection size labels are plotted above each bar, and this is a
#       list of arguments to the text() function to use when plotting them.
#   setBarLabels.text: if this isn't NULL, set size labels are plotted above each set bar, and this is a
#       list of arguments to the text() function to use when plotting them.
#   setBarNames.text: list of arguments to the text() function to use when plotting set names beside the set bars.
#   dot.points: list of arguments to the points() function to use when plotting the set intersection matrix dots.
#   dotPresent.points: like dot.points but applies to dots when the set is in the intersection.
#   dotAbsent.points: like dotPresent.points but applies to dots when the set is NOT in the intersection.
#   linePresent.segments: list of arguments to the segments() function to use when plotting the set
#       intersection matrix lines for a set that is in the intersection.
#
# Note: all arguments ending in ".text" can include a "delta" argument which is a 2-element vector (dx,dy) that
#       is multiplied by the plot area (width,height) and then added to the text starting coordinate (x,y) to
#       obtain a revised starting coordinate.  Works better than 'adj' because it's independent of text length.
#
# Note: coordinate (0,0) is fixed at lower-left corner of main bar area.
#
# Examples:
#   plotSetIntersectionMtx(x=makeNamedVector(c("A","A:B","B"), c(2,1,1)),
#       main="Test Plot", sub="Subtitle", mainBarLabels.text=list(), dot.points=list(cex=5))
#   plotSetIntersectionMtx(x=c("A","A","A:B","B"),
#       main="Test Plot", sub="Subtitle", mainBarLabels.text=list(), dot.points=list(cex=5))
#   plotSetIntersectionMtx(x=matrix(c("w","A","x","A","y","A","x","B","z","B"), ncol=2, byrow=TRUE),
#       main="Test Plot", sub="Subtitle", mainBarLabels.text=list(), dot.points=list(cex=5))
#   plotSetIntersectionMtx(x=matrix(c(1,0, 1,0, 1,1, 0,1), ncol=2, byrow=TRUE, dimnames=list(NULL, c("A","B"))),
#       main="Test Plot", sub="Subtitle", mainBarLabels.text=list(), dot.points=list(cex=5))
#   plotSetIntersectionMtx(x=matrix(c(2,1,0, 1,1,1, 1,0,1), ncol=3, byrow=TRUE, dimnames=list(NULL, c("","A","B"))),
#       main="Test Plot", sub="Subtitle", mainBarLabels.text=list(), dot.points=list(cex=5))
#   plotSetIntersectionMtx(
#       x=matrix(c(37,0,0,1,0,0, 31,0,0,0,1,0, 31,0,0,0,0,1, 16,0,0,1,0,1, 14,0,0,0,1,1, 10,0,1,0,0,0,
#           7,1,0,0,1,0, 6,0,1,0,1,0, 6,0,0,1,1,0, 6,1,0,0,1,1, 5,1,0,0,0,1, 5,0,1,0,0,1, 5,0,1,1,0,0,
#           4,0,0,1,1,1, 2,0,1,1,0,1, 2,0,1,1,1,0, 2,1,1,0,1,1, 1,1,0,1,0,0, 1,1,0,0,0,0, 1,1,0,1,0,1,
#           1,1,0,1,1,0, 1,1,0,1,1,1, 0,1,1,1,0,1, 0,1,1,0,1,0, 0,1,1,0,0,1, 0,0,1,0,1,1, 0,1,1,1,1,0,
#           0,1,1,1,0,0, 0,1,1,0,0,0, 0,0,1,1,1,1, 0,1,1,1,1,1, 0,0,0,0,0,0),
#       ncol=6, byrow=TRUE, dimnames=list(NULL, c("", "RB1","PIK3R1","EGFR","TP53","PTEN"))),
#       main="Test Plot", sub="Subtitle", mainBarLabels.text=list(), dot.points=list(cex=2))
#
# Useful for debugging: assign L = list( args below ) and then:
#   for (n in names(L)) assignGlobal(n, L[[n]])
#######################################################################################
plotSetIntersectionMtx = function(x, sets=NULL, sep=":", xlim=0.2, ylim=0.3,
    main=NULL, mainAttr.mtext=NULL, sub=NULL, subAttr.mtext=NULL,
    xlab="Set\nsize", xlabAttr.text=NULL, ylab="Intersection size", ylabAttr.text=NULL,
    axes="xy", xaxisAttr.axis=NULL, yaxisAttr.axis=NULL, yaxisIntervals=10,
    mainBarWidth=0.8, mainBarHeight=1.05, mainBarSpace=0.2, setBarWidth=0.8, setBarSpace=0.2, setNameWidth=0.5,
    mainBars.rect=NULL, setBars.rect=NULL, mainBarLabels.text=NULL, setBarLabels.text=list(), setBarNames.text=NULL,
    dot.points=NULL, dotPresent.points=NULL, dotAbsent.points=NULL, linePresent.segments=NULL)
    {
    err = function(S) stop("plotSetIntersectionMtx: ", S)

    #####################################
    # Turn x into format case (1) (numeric vector with each member giving the size of one set intersection).
    #####################################
    if (is.array(x) && length(dim(x)) == 1)
        x = makeNamedVector(names(x), as.vector(x))
    if (isNonListVector(x))
        {
        # case (1)
        if (is.numeric(x))
            {
            if (is.null(names(x))) err("Case 1 numeric vector x must have names")
            if (any(is.na(x))) err("Case 1 numeric vector must not contain NA")
            if (length(x) == 0) err("Case 1 numeric vector x must have at least one entry")
            if (any(x < 0)) err("Case 1 numeric vector must have non-negative entries")
            }
        # case (2)
        else if (is.character(x))
            {
            if (any(is.na(x))) err("Case 2 character vector must not contain NA")
            if (length(x) == 0) err("Case 2 character vector x must have at least one entry")
            x = table(x)
            }
        else
            {
            err("argument x is an invalid type of vector")
            }
        }
    else if (!is.matrix(x) && !is.data.frame(x))
        err("argument x is of unknown type")
    else if (nrow(x) < 1)
        err("Case 3/4/5 matrix must have at least one row")
    else if (any(is.na(x)))
        err("Case 3/4/5 matrix must not contain NA")
    else if (is.logical(x) || is.integer(x) || is.numeric(x))
        {
        # case (3)
        if (colnames(x)[1] != "")
            {
            if (any(x != 0 & x != 1)) err("Case 3 numeric binary matrix must contain only 0 and 1")
            if (is.null(sets))
                sets = colnames(x)
            x = apply(x, 1, function(V) paste(colnames(x)[as.logical(V)], collapse=sep))
            x = table(x)
            }
        # case (4)
        else
            {
            w = as.numeric(x[,1])
            x = x[,-1]
            if (any(x != 0 & x != 1)) err("Case 4 matrix must contain only 0 and 1 except column 1")
            if (is.null(sets))
                sets = colnames(x)
            x = apply(x, 1, function(V) paste(colnames(x)[as.logical(V)], collapse=sep))
            if (any(duplicated(x))) err("Case 4 matrix must have unique rows, ignoring column 1")
            x = makeNamedVector(x, w)
            }
        }
    else if (is.character(x[1,1]))
        {
        # case (5)
        if (ncol(x) != 2) err("Case 5 character matrix x must have two columns")
        x[,2] = as.character(x[,2])
        x = tapply(x[,2], x[,1], function(S) paste(sort(unique(S)), collapse=sep))
        x = table(x)
        }
    else
        {
        err("argument x is an invalid type of matrix")
        }

    #####################################
    # Get sets present in x, and if they aren't also in 'sets', remove them, or
    # initialize 'sets' if it is NULL.
    #####################################
    sets.x = strsplit(names(x), sep, fixed=TRUE)
    if (is.null(sets))
        sets = unique(unlist(sets.x, use.names=FALSE))
    else
        {
        hasSetNotWanted = sapply(sets.x, function(V) any(!V %in% sets))
        x = x[!hasSetNotWanted]
        if (length(x) == 0)
            err("no set intersections remaining after removing those containing sets in 'sets' argument")
        }

    #####################################
    # Determine which set is in which intersection, and compute total intersection size of each set.
    #####################################
    setInIntersection = sapply(sets, function(S) sapply(sets.x, function(V) S %in% V))
    setSizes = apply(setInIntersection, 2, function(inIntersection) sum(x[inIntersection]))

    #####################################
    # Compute actual xlim and ylim, and limits for main and set bars.
    #####################################
    if (length(xlim) != 2)
        {
        f = xlim[1]
        xlim = c(0, length(x))
        xlim[1] = -f*xlim[2]
        }
    xlimBars = c(0, xlim[2])
    xlimSetNames = c(setNameWidth*xlim[1], 0)
    xlimSetBars = c(xlim[1], xlimSetNames[1])

    if (length(ylim) != 2)
        {
        f = ylim[1]
        ylim = c(0, max(x))
        if (ylim[2] < max(x))
            ylim = range(pretty(1.1*ylim))
        if (ylim[2] < max(x))
            ylim = range(pretty(1.2*ylim))
        ylim[1] = -f*ylim[2]
        ylim[2] = ylim[2]*mainBarHeight
        }
    ylimSetBars = c(ylim[1], 0)

    #####################################
    # Compute pretty labels for the y-axis.
    #####################################
    maxIntersectionSize = max(x)
    yprettyBars = range(pretty(c(0, maxIntersectionSize)))
    if (yprettyBars[2] < maxIntersectionSize)
        yprettyBars = range(pretty(1.1*yprettyBars))
    if (yprettyBars[2] < maxIntersectionSize)
        yprettyBars = range(pretty(1.2*yprettyBars))

    #####################################
    # Compute pretty labels for the tiny x-axis.  Even if the axis is not plotted,
    # the maximum label value is needed to scale the set bars to the correct height.
    #####################################
    maxSetSize = max(setSizes)
    yprettySetBars = range(pretty(c(0, maxSetSize)))
    if (yprettySetBars[2] < maxSetSize)
        yprettySetBars = range(pretty(1.1*yprettySetBars))
    if (yprettySetBars[2] < maxSetSize)
        yprettySetBars = range(pretty(1.2*yprettySetBars))

    #####################################
    # Compute x and y scale factors for the set bars.
    # Multiply set size by 'xscaleSetBars' to get bar height.
    # Multiply bar number fraction by 'yscaleSetBars' to get bar bottom y-position.
    #####################################
    xscaleSetBars = abs(diff(xlimSetBars))/yprettySetBars[2]
    yscaleSetBars = ylimSetBars[1]/length(sets)

    #####################################
    # Start the plot.
    #####################################
    plot(NA, type='n', xlim=xlim, ylim=ylim, xlab="", ylab="", axes=FALSE)

    #####################################
    # Plot title and subtitle.
    #####################################
    if (!is.null(main))
        plotMtext(main, side=3, line=1, L.args=mainAttr.mtext)
    if (!is.null(sub))
        plotMtext(sub, side=3, line=0, cex=0.8, L.args=subAttr.mtext)

    #####################################
    # Draw axes in main bar area.  The x-axis has no labels, just a line.  Since
    # we didn't define an xAxisAttr.axis argument, use yaxisAttr.axis as the defaults
    # for the x-axis, to give the user control of as much as possible.
    #####################################

    plotAxis(L.args=list(side=BOTTOM, pos=0, outer=FALSE, labels=FALSE, tcl=0, xaxp=c(xlimBars, 1)),
        L.default=yaxisAttr.axis)

    if (grepl("y", axes))
        {
        plotAxis(side=LEFT, pos=0, las=2, yaxp=makeMultiple10of_1_2_5(yprettyBars, yaxisIntervals, TRUE),
            L.args=yaxisAttr.axis)
        plotText(0, mean(yprettyBars), ylab, srt=90, adj=c(0.5, -6), L.args=ylabAttr.text)
        }

    if (grepl("x", axes))
        {
        xaxp = c(xlimSetBars, 2)
        at = seq(xaxp[1], xaxp[2], length.out=xaxp[3]+1)
        labels = c(yprettySetBars[2], mean(yprettySetBars), 0)
        plotAxis(side=TOP, pos=0, outer=FALSE, xaxp=xaxp, at=at, labels=labels, L.args=xaxisAttr.axis)
        plotText(mean(xlimSetBars), 0, xlab, adj=c(0.5, -1.5), L.args=xlabAttr.text)
        }

    #####################################
    # Compute the number of main bars and their positions and heights, then draw them.
    #####################################
    Nbars = length(x)
    bar.halfwidth = mainBarWidth/2 # Space for one bar is 1 unit so bar width is 'mainBarWidth', see xlim[2] above.
    bar.space = mainBarSpace
    bar.x = seq(bar.space+bar.halfwidth, by=mainBarWidth+bar.space, length.out=Nbars)
    bar.y = as.numeric(x)
    plotRect(bar.x-bar.halfwidth, 0, bar.x+bar.halfwidth, bar.y, col="black", L.args=mainBars.rect)

    #####################################
    # Plot set intersection sizes above the bars.
    #####################################
    if (!is.null(mainBarLabels.text))
        plotText(bar.x, bar.y, x, srt=90, adj=c(0, 0.5), delta=c(0, 0.005), col="black", L.args=mainBarLabels.text)

    #####################################
    # Compute the number of set bars and their positions and heights, then draw them.
    #####################################
    Nsetbars = length(sets)
    setbar.halfwidth = setBarWidth/2 # Space for one bar is 1 unit so bar width is 'setBarWidth', see xlim[2] above.
    setbar.space = setBarSpace
    setbar.x = xlimSetBars[2] - setSizes*xscaleSetBars
    setbar.y = seq(setbar.space+setbar.halfwidth, by=setBarWidth+setbar.space, length.out=Nsetbars)
    plotRect(setbar.x, yscaleSetBars*(setbar.y-setbar.halfwidth), xlimSetBars[2], yscaleSetBars*(setbar.y+setbar.halfwidth),
        col="blue", L.args=setBars.rect)

    #####################################
    # Plot set sizes above the bars.
    #####################################
    if (!is.null(setBarLabels.text))
        plotText(setbar.x, yscaleSetBars*setbar.y, setSizes, adj=c(1, 0.5), delta=c(-0.005, 0), col="black", L.args=setBarLabels.text)

    #####################################
    # Plot set names to right of set bars.
    #####################################
    plotText(xlimSetBars[2], yscaleSetBars*setbar.y, sets, adj=c(0, 0.5), delta=c(0.005, 0), col="black", L.args=setBarNames.text)

    #####################################
    # Compute positions of the intersection dots and plot them.
    #####################################
    dot.x = bar.x
    dot.y = yscaleSetBars*setbar.y
    names(dot.y) = sets
    for (set in sets)
        {
        p.y = dot.y[set]
        isPresent = setInIntersection[,set]
        if (any(isPresent))
            plotPoints(dot.x[isPresent], p.y, col="black", pch=19, L.args=dotPresent.points, L.default=dot.points)
        if (any(!isPresent))
            plotPoints(dot.x[!isPresent], p.y, col="lightgray", pch=19, L.args=dotAbsent.points, L.default=dot.points)
        }

    #####################################
    # Finally, determine line extents and draw lines connecting intersection dots.
    #####################################
    for (i in 1:nrow(setInIntersection))
        {
        p.x = dot.x[i]
        isPresent = setInIntersection[i,]
        if (sum(isPresent) > 1)
            {
            extents = range(which(isPresent))
            plotSegments(p.x, dot.y[extents[1]], p.x, dot.y[extents[2]], col="black", lwd=2, L.args=linePresent.segments)
            }
        }
    }

#######################################################################################
# Like pretty() but makes sure that the minimum returned value is <= min(x) and the
# maximum returned value is >= max(x).
#######################################################################################
pretty.good = function(x, ...)
    {
    i.min = which.min(x)
    i.max = which.max(x)
    x.min = x[i.min]
    x.max = x[i.max]
    delta = (x.max-x.min)/20
    y = pretty(x, ...)
    while (min(y) > x.min)
        {
        x[i.min] = x[i.min] - delta
        y = pretty(x, ...)
        }
    while (max(y) < x.max)
        {
        x[i.max] = x[i.max] + delta
        y = pretty(x, ...)
        }
    return(y)
    }

#######################################################################################
# Like pretty() but something happened to it so that pretty(c(0,100), 4) no longer
# returns c(0, 25, 50, 75, 100) but rather c(0, 20, 40, 60, 80, 100). This function
# fixes that. It first checks to see if n exactly divides max(x)-min(x) and if so it
# generates the sequence from that. Otherwise, it calls pretty.good().
#######################################################################################
pretty.good2 = function(x, n=5, ...)
    {
    d = max(x) - min(x)
    e = d/n
    if (e == as.integer(e))
        return(seq(min(x), max(x), by=e))
    return(pretty.good(x, n, ...))
    }

#######################################################################################
# Like pretty() without all the extra arguments, except that this finds a
# sequence of "round" values appropriate when the axis is logarithmic.  The
# returned sequence includes powers of 10, and optionally, 2 * powers of 10,
# and 5 * powers of 10.
#
# Arguments:
#   x: an object coercible to numeric().  NA values and values <= 0 are ignored.
#       The limits are set to include these values.
#   include: one of the values "X1", "X12", "X15", or "X125" indicating inclusion
#       of powers of 10 only (X1), 1* and 2* powers of 10 (X12), 1* and 5* (X15),
#       or 1*, 2*, and 5* (X125).
#   P10.StartEnd: TRUE if sequence must start and end with a power of 10, FALSE
#       if it may start or end with 2* or 5* a power of 10 (depending of course
#       on 'include').
#
# Returns: the computed sequence.
#
# Note: see map.log() below also.
#######################################################################################
pretty.log = function(x, include="X125", P10.StartEnd=FALSE)
    {
    x = as.numeric(x)
    x = x[!is.na(x) & x > 0]
    r = range(x)
    if (r[1] == r[2])
        r[1] = r[1]/10

    # Compute first element of the sequence.
    x1 = log10(r[1])
    x1 = myIfElse(x1 < 0, as.integer(x1)-1, as.integer(x1))
    x1 = 10^x1
    # Raise first sequence element by *5 if possible, else *2 if possible.
    cur = "atX1"
    if (!P10.StartEnd && (include %in% c("X15", "X125")) && (x1*5 <= r[1]))
        {
        x1 = x1*5
        cur = "atX5"
        }
    else if (!P10.StartEnd && (include %in% c("X12", "X125")) && (x1*2 <= r[1]))
        {
        x1 = x1*2
        cur = "atX2"
        }

    # Compute last element of the sequence.
    x2 = log10(r[2])
    x2 = myIfElse(x2 < 0, as.integer(x2), as.integer(x2)+1)
    x2 = 10^x2
    # Lower last sequence element by *2/10 if possible, else *5/10 if possible.
    if (!P10.StartEnd && (include %in% c("X12", "X125")) && (x2*2/10 >= r[2]))
        x2 = x2*2/10
    else if (!P10.StartEnd && (include %in% c("X15", "X125")) && (x2*5/10 >= r[2]))
        x2 = x2*5/10

    # Value to assign to 'cur' when moving from one sequence element to the next,
    # depending on value of 'include' argument as well as value of 'cur'.
    nextCur = list(X1=c(atX1="atX1"),
                   X12=c(atX1="atX2", atX2="atX1"),
                   X15=c(atX1="atX5", atX5="atX1"),
                   X125=c(atX1="atX2", atX2="atX5", atX5="atX1"))

    # Value to multiply current sequence member by, to get next sequence member,
    # depending on value of 'include' argument as well as value of 'cur'.
    multFactor = list(X1=c(atX1=10),
                      X12=c(atX1=2, atX2=5),
                      X15=c(atX1=5, atX5=2),
                      X125=c(atX1=2, atX2=5/2, atX5=2))

    # Compute the full sequence.
    seq = x1
    xt = x1
    while (xt < x2)
        {
        xt = xt * multFactor[[include]][cur]
        cur = nextCur[[include]][cur]
        seq = c(seq, xt)
        }
    names(seq) = NULL
    return(seq)
    }

#######################################################################################
# This function's purpose is to provide a way to align two y-axes (left and right
# sides) so that BOTH axes have the same number of ticks and labels (and grid lines
# could hit them).
#
# This makes two calls to pretty(), one with x and the other with y for the "x"
# argument, all other arguments the same. Then, the two resulting sequences are made
# to be the same length in the negative direction and the same length in the positive
# direction by extending the sequences in the positive and/or negative and/or zero
# directions.
#
# This is difficult to describe in comments, easiest to describe with code and a few
# comments.
#
# Return a list with elements Vx and Vy, the two pretty() sequences for x and y resp.
#######################################################################################
pretty2 = function(x, y, nx=5, ny=nx, ...)
    {
    # Note: Vx and Vy are both in ascending order.
    Vx = pretty(x, nx, ...)
    Vy = pretty(y, ny, ...)
    # Find the extension to sequence Vx that includes 0, but if 0 does not lie on a multiple of the
    # sequence spacing or f the sequence extends < 0 AND > 0, return NULL. If 0 is already in the
    # sequence, return numeric(0).
    getExtensionTo0 = function(Vx)
        {
        if (any(Vx == 0))
            return(numeric(0))
        Rx = range(Vx)
        if (Rx[1] < 0 && Rx[2] > 0)
            return(NULL)
        dx = diff(Vx[1:2])
        if (Rx[1] > 0)
            {
            n = Rx[1]/dx
            if (n != as.integer(n))
                return(NULL)
            return(seq(0, Rx[1]-dx, by=dx))
            }
        n = Rx[2]/dx
        if (n != as.integer(n))
            return(NULL)
        return(seq(Rx[2]+dx, 0, by=dx))
        }
    # First, for region around 0, get extension to 0 for both sequences. If NULL for either, no extension is done towards 0.
    Ex = getExtensionTo0(Vx)
    Ey = getExtensionTo0(Vy)
    if (!is.null(Ex) && !is.null(Ey))
        {
        # The one with the longer extension towards 0 gets extended. Extension may be in negative or positive direction.
        Nx = length(Ex)
        Ny = length(Ey)
        if (Nx > Ny)
            {
            if (Vx[1] > 0)
                Vx = c(Ex[(Ny+1):Nx], Vx)
            else
                Vx = c(Vx, Ex[1:(Nx-Ny)])
            }
        else if (Ny > Nx)
            {
            if (Vy[1] > 0)
                Vy = c(Ey[(Nx+1):Ny], Vy)
            else
                Vy = c(Vy, Ey[1:(Ny-Nx)])
            }
        }
    # If length of sequence >= 0 differs, extend shorter one to same length as longer.
    dx = diff(Vx[1:2])
    dy = diff(Vy[1:2])
    Nx = sum(Vx >= 0)
    Ny = sum(Vy >= 0)
    if (Nx > Ny)
        Vy = c(Vy, Vy[Ny]+dy*(1:(Nx-Ny)))
    else if (Ny > Nx)
        Vx = c(Vx, Vx[Nx]+dx*(1:(Ny-Nx)))
    # If length of sequence <= 0 differs, extend shorter one to same length as longer.
    Nx = sum(Vx <= 0)
    Ny = sum(Vy <= 0)
    if (Nx > Ny)
        Vy = c(Vy[1]-dy*((Nx-Ny):1), Vy)
    else if (Ny > Nx)
        Vx = c(Vx[1]-dy*((Ny-Nx):1), Vx)
    return(list(Vx=Vx, Vy=Vy))
    }

#######################################################################################
# Map numbers onto a log axis, where the plot axis is NOT designated as a log-axis
# using the 'log' parameter to plot(), but instead, a regular linear axis is used
# but is LABELLED logarithmically.
#
# Arguments:
#   x: a vector of numbers to be mapped to their appropriate position on the linear
#       axis.  Log base 10 will be taken of these numbers as part of the mapping.
#       The numbers may include NA and 0.  These are skipped during log10().
#   prettys: a vector returned by pretty.log() above.
#   lim: a 2-element vector.  lim[1] is the position on the linear axis to which
#       min(pretties) should be mapped, and lim[2] is the position on the linear
#       axis to which max(pretties) should be mapped.
#   le0: the position on the linear axis to which any value <= 0 should be mapped, if any.
#
# Returns: a vector of same length as x, values are mapped positions of x along the
# linear axis.  NA remains NA, and any value <=0 becomes 'le0'.
#
# Example:
#   ylim = 0:1
#   lim = c(0.05, 0.95)
#   le0 = 0
#   x = 0:8
#   y = c(0, 10^((x[-1]-1)/2))
#   pretties = pretty.log(y, P10.StartEnd=TRUE)
#   y.map = map.log(y, pretties, lim, le0)
#   labels = c(0, pretties)
#   labels.map = map.log(labels, pretties, lim, le0)
#   labels[1] = "(zero)"
#   plot(x, y.map, type="p", pch=20, ylim=ylim, main="10^(x-1) except x=0 -> 0",
#       xlab="x", ylab="y", axes=FALSE)
#   axis(1, at=x, labels=c("(special)", x[-1]))
#   axis(2, at=labels.map, labels=labels, las=2)
#   text(mean(x), lim[2], "Top of plot area", pos=3)
#   text(mean(x), lim[1], "Bottom of plot area", pos=1)
#######################################################################################
map.log = function(x, prettys, lim, le0=lim[1])
    {
    ind1 = is.na(x)
    ind2 = !ind1 & (x <= 0)
    ind3 = !ind1 & !ind2
    x.map = rep(NA, length(x))
    x.map[ind2] = le0
    ps.min = min(prettys)
    ps.max = max(prettys)
    xx = (log10(x[ind3]) - log10(ps.min)) / (log10(ps.max) - log10(ps.min))
    x.map[ind3] = lim[1] + xx*(lim[2]-lim[1])
    return(x.map)
    }

#######################################################################################
# Like barplot but height may be a list of vectors or matrices or lists, for producing
# clusters of bars separated by a space, or stacked bars with variable number of bars
# in each stack.  When the list elements are matrices or lists, this is a combination
# of the two cases, producing clustered stacked bars.  This massages the data into a
# form that barplot() can accept, then calls barplot().  It also provides arguments
# for plotting error bars.
#
# Arguments:
#   height: a list whose elements are vectors, matrices, or sublists, giving the height
#       of bars or sub-bars.  If this is not a list, barplot() is called directly with
#       this argument.
#   width: bar width.
#   space: bar spacing, normally the default is used.  This is a 1- or 2-element vector,
#       but it is automatically expanded to properly set the spacing of bars that are
#       clustered, with the first element giving spacing of bars within the cluster,
#       and the second element giving spacing between clusters.  It defaults to c(0, 1)
#       for the clustered bar plots plotted here.
#   use.sublist.names: make the names that are normally plotted below the bars be
#       equal to the names of each element WITHIN a "height" element.
#   beside: TRUE or FALSE to indicate stacking or clustering of bars.  This is used
#       only if the elements of 'height' are vectors.
#   bar.upper: a list of the same form as 'height', containing the height of the upper
#       error bar (or upper confidence interval bar), or is NULL to not plot these
#       bars.
#   bar.lower: like bar.upper, but for the lower error bars.
#   bar.args: list of arguments to arrows() function used for plotting error bars.
#   grp.lbl.line: if not NULL and height specifies clustered (grouped) bars, then
#       bar cluster (group) labels are plotted under the bars.  The labels are
#       taken from names(height).  Note: use the usual barplot() arguments to
#       adjust the size, etc. of the individual bar labels.
#   grp.lbl.args: optional list of mtext() arguments used to plot cluster (group) labels.
#   retL: FALSE to return vector of bar x-centerline positions, TRUE to return a list
#       with these elements:
#           x: vector of bar centerline x-positions
#           y: vector of bar total heights
#           width: width argument value
#           space: bar spacing vector
#
#   ...: other arguments passed to barplot().
#
# Returns: value returned by barplot() (which is a vector of x-positions of
# centerlines of the bars, which are normally one unit wide), or if retY is TRUE,
# a list with elements x = barplot() return value and y = vector of total bar
# heights (sum of stacked bars if those are used).
#
# Meaning of the element type of the 'height' list:
#
#   vectors:
#       beside=TRUE:
#           each vector element of 'height' corresponds to one cluster of bars, the
#           number of bars in the cluster is equal to the vector length, and the bar
#           heights are given by the vector elements.  Bar labels are usually taken
#           from names of vector elements (if use.sublist.names=TRUE), else the names
#           are empty.
#       beside=FALSE:
#           each vector element of 'height' corresponds to one stacked bar, the
#           number of bars is equal to the number of vectors, and the sub-bar heights
#           within each stacked bar are given by the vector elements.
#   matrices: each matrix element of 'height' corresponds to one cluster of bars, the
#           number of bars in the cluster is equal to the number of matrix columns, and
#           the sub-bar heights within each stacked bar are given by the matrix column
#           elements.
#   lists: similar to matrices: each sublist of 'height' correponds to one cluster of
#           bars, the number of stacked bars in the cluster is equal to the number of
#           vector elements in the sublist, and the sublist elements must be vectors
#           whose elements give the sub-bar heights within each stacked bar.
#
# The 'height' list elements are converted into either a single vector (when the elements
# of 'height' are vectors and beside=TRUE) or a single matrix (stacked bars), and then
# the barplot() function is called to make the actual plot.
#
# For stacked bars, the matrix is given enough rows for the bar with the most sub-bars,
# and unused sub-bars of any bar are set to a height of 0 in the matrix.
#
# The space argument is interpreted as bar spacing, or if it is a 2-element vector,
# as the spacing of bars within clusters (space[1]) and between clusters (space[2]).
#
# Note on colors: the "col" argument to barplot() is defined as a vector of
# colors for the bars or bar components.  When stacked bars are used, apparently
# the length of "col" can only be equal to the number of bars that are stacked,
# it cannot give a separate color for each stack of each bar.  When stacked bars
# are NOT used, it CAN be a vector equal to the number of bars. So what if you
# want each stack of each bar to have its own color?  I don't know how to do this,
# but what you could do is use shading to distinguish stacked bars from one another,
# and use colors to distinguish different bars, or vice-versa.  To do this, supply
# stacked-bar colors with the "col" argument, or provide "density", "angle", and
# "col" vectors for shading the stacked bars, and set rety=TRUE and save the return
# list L:
#   L = barplot.lists(mtx, col=col, [density=density, angle=angle,] retL=TRUE)
# Then, plot the same data a second time with:
#   barplot(L$y, L$width, L$space, add=TRUE, axes=FALSE, axisnames=FALSE,
#       [density=density, angle=angle], col=col)
# providing "density", "angle", and "col" vectors of shading density/angle/color
# for the individual bars (entire bar is colored or shaded one way) when the first
# call ONLY provided color, or using only the "col" argument to specify the bar
# colors when the first call specified shading.
# In this latter case, you must provide the colors WITH ALPHA < 1 ELSE SHADING IS
# OVERWRITTEN for the (entire) bars with the "cols" argument in the second call.
#
# Note on use of both color and shading in a single bar: normally the color applies
# to the color of the shading when shading is used, and to the fill color when it is
# not used.  Therefore, the way to get colored bars that are also shaded is similar
# to the above.  If you plot the filled bars first and then overplot with shading,
# the fill color can be solid.
#   data = list(c(1,9,7,5), c(2,9,9,1,3,4))
#   N = length(unlist(data))
#   L = barplot.lists(data, col=rainbow(N), beside=TRUE, retL=TRUE)
#   barplot(L$y, L$width, L$space, add=TRUE, axes=FALSE, axisnames=FALSE,
#       col=c("gray", "black", "blue")[sample(1:3, N, replace=TRUE)],
#       density=c(20, 10, 30)[sample(1:3, N, replace=TRUE)],
#       angle=c(0, 20, 45, 60)[sample(1:4, N, replace=TRUE)])
#
# But if you still want each stacked bar to be a different color, which I do,
# then maybe it could be done by coloring the bars white, then filling them in
# afterwards.  Only slight problem is that border lines get overwritten.  You
# are actually regenerating all the bars.
#   data = matrix(1:20, nrow=4)
#   cols = data
#   cols[,] = "yellow"
#   cols[2, 1] = "orange"
#   cols[3, 2] = "red"
#   cols[4, 1] = "blue"
#   cols[4, 4] = "green"
#   cols[4, 5] = "pink"
#   xb = barplot.lists(data, col="white")
#   mtx = apply(rbind(rep(0, ncol(data)), data), 2, cumsum)
#   for (col in 1:5)
#       for (row in 1:4)
#           rect(xb[col]-0.5, mtx[row, col], xb[col]+0.5, mtx[row+1, col], border="black", col=cols[row, col], lwd=2)
#######################################################################################
#width=1
#space=NULL
#use.sublist.names=TRUE
#beside=FALSE
#bar.upper=NULL
#bar.lower=NULL
#bar.args=NULL
#grp.lbl.line=NULL
#grp.lbl.args=NULL
#retL=FALSE
barplot.lists = function(height, width=1, space=NULL, use.sublist.names=TRUE,
    beside=FALSE, bar.upper=NULL, bar.lower=NULL, bar.args=NULL,
    grp.lbl.line=NULL, grp.lbl.args=NULL, retL=FALSE, ...)
    {
    # Examine the height argument and process it to produce vector 'height' to
    # use when calling barplot().  Set groupLabels to a vector of labels for
    # the group if bars are clustered, and set NbarsInCluster to a vector of the
    # number of bars in each cluster.
    groupLabels = NULL
    if (is.list(height))
        {
        L = height
        if (length(L) == 0)
            stop("height argument is a 0-length list")
        lens = sapply(L, length)

        if (isNonListVector(L[[1]]) && beside)
            {
            groupLabels = names(L)
            NbarsInCluster = lens
            height = unlist(L, use.names=FALSE)
            names(height) = NULL
            if (use.sublist.names)
                names(height) = unlist(sapply(L, names), use.names=FALSE)
            if (is.null(space))
                space = c(0,1)
            if (length(space) == 2)
                space = unlist(sapply(lens, function(K) c(space[2], rep(space[1], K-1))), use.names=FALSE)
            if (!is.null(bar.upper))
                bar.upper = unlist(bar.upper, use.names=FALSE)
            if (!is.null(bar.lower))
                bar.lower = unlist(bar.lower, use.names=FALSE)
            }
        else if (isNonListVector(L[[1]]))
            {
            Nstacks = max(lens)
            Nbars = length(L)
            barNames = names(L)
            cvtToMatrix1 = function(L, Nstacks, Nbars, barNames=NULL)
                {
                mtx = matrix(0, nrow=Nstacks, ncol=Nbars, dimnames=list(NULL, barNames))
                for (i in 1:Nbars)
                    mtx[1:length(L[[i]]),i] = L[[i]]
                return(mtx)
                }
            height = cvtToMatrix1(height, Nstacks, Nbars, barNames)
            if (!is.null(bar.upper))
                bar.upper = cvtToMatrix1(bar.upper, Nstacks, Nbars, barNames)
            if (!is.null(bar.lower))
                bar.lower = cvtToMatrix1(bar.lower, Nstacks, Nbars, barNames)
            }
        else if (is.matrix(L[[1]]))
            {
            groupLabels = names(L)
            NbarsInCluster = sapply(L, ncol)
            Nstacks = max(sapply(L, nrow))
            Nbars = sum(NbarsInCluster)
            barNames = unlist(sapply(L, colnames), use.names=FALSE)
            cvtToMatrix2 = function(L, Nstacks, Nbars, barNames=NULL)
                {
                mtx = matrix(0, nrow=Nstacks, ncol=Nbars, dimnames=list(NULL, barNames))
                nextBar = 1
                for (i in 1:length(L))
                    {
                    N = ncol(L[[i]])
                    mtx[1:nrow(L[[i]]), nextBar:(nextBar+N-1)] = L[[i]]
                    nextBar = nextBar + N
                    }
                return(mtx)
                }
            height = cvtToMatrix2(height, Nstacks, Nbars, barNames)
            if (!is.null(bar.upper))
                bar.upper = cvtToMatrix2(bar.upper, Nstacks, Nbars, barNames)
            if (!is.null(bar.lower))
                bar.lower = cvtToMatrix2(bar.lower, Nstacks, Nbars, barNames)
            if (is.null(space))
                space = c(0,1)
            if (length(space) == 2)
                space = unlist(sapply(NbarsInCluster, function(K) c(space[2], rep(space[1], K-1))), use.names=FALSE)
            }
        else if (is.list(L[[1]]))
            {
            groupLabels = names(L)
            NbarsInCluster = lens
            Nstacks = max(sapply(L, function(SL) max(sapply(SL, length))))
            Nbars = sum(lens)
            barNames = unlist(sapply(L, names), use.names=FALSE)
            cvtToMatrix3 = function(L, Nstacks, Nbars, barNames=NULL)
                {
                mtx = matrix(0, nrow=Nstacks, ncol=Nbars, dimnames=list(NULL, barNames))
                nextBar = 1
                for (i in 1:length(L))
                    {
                    N = length(L[[i]])
                    for (j in 1:N)
                        {
                        V = L[[i]][[j]]
                        mtx[1:length(V), nextBar] = V
                        nextBar = nextBar + 1
                        }
                    }
                return(mtx)
                }
            height = cvtToMatrix3(height, Nstacks, Nbars, barNames)
            if (!is.null(bar.upper))
                bar.upper = cvtToMatrix3(bar.upper, Nstacks, Nbars, barNames)
            if (!is.null(bar.lower))
                bar.lower = cvtToMatrix3(bar.lower, Nstacks, Nbars, barNames)
            if (is.null(space))
                space = c(0,1)
            if (length(space) == 2)
                space = unlist(sapply(lens, function(K) c(space[2], rep(space[1], K-1))), use.names=FALSE)
            }
        else
            stop("height argument is a list of elements of unsupported type")
        }

    xb = barplot(height, width, space, beside=beside, ...)
    if (is.matrix(xb) && ncol(xb) == 1)
        xb = xb[,1]

    # Add group labels if neither groupLabels nor grp.lbl.line are NULL.
    if (!is.null(groupLabels) && !is.null(grp.lbl.line))
        {
        # Convert NbarsInCluster to a set of indexes of bars, e.g. 1:10, 11:13, 14:20.
        idx2 = cumsum(NbarsInCluster)
        idx1 = c(1, idx2[-length(idx2)]+1)
        # Compute mean of cluster's bar x-positions to get the group label position.
        xgrp = sapply(1:length(idx1), function(i) mean(xb[idx1[i]:idx2[i]]))
        # Plot the bar text.
        plotMtext(groupLabels, side=1, line=grp.lbl.line, at=xgrp, las=2, L.args=grp.lbl.args)
        }

    # If specified, plot error bars.
    if (!is.null(bar.upper) || !is.null(bar.lower))
        plotPairedVertArrows(height, bar.upper, bar.lower, xb, L.args=bar.args)

    # Finished, return the proper value, invisibly.
    if (!retL)
        return(invisible(xb))
    if (!isNonListVector(height))
        height = apply(height, 2, sum)
    return(invisible(list(x=xb, y=height, width=width, space=space)))
    }

#######################################################################################
# When points are plotted with points(), if there are a LOT of them, they make PDF
# files huge and slow to load, and overprint one another to make a blotch.  This
# function discards many points that overlap.
#
# Arguments:
#   x, y: vectors of points
#   f: larger values remove more points, smaller values remove fewer.
#   usr: coordinates of plotting area.
#   dev: device size in pixels.
#
# Returns: xy.coords of thinned-out points
#######################################################################################
thinPoints = function(x, y, f=1, usr=par("usr"), dev=dev.size(units="px"))
    {
    # Number of pixels per rough (arbitrary) plotted point is taken as 5f.
    # Determine number of plotted points across device in each direction.
    nx = round(dev[1]/(5*f))
    ny = round(dev[2]/(5*f))
    # Convert x and y to (0..nx-1, 0..ny-1)
    cx = round((x-usr[1])*(nx/(usr[2]-usr[1])))
    cx[cx < 0] = 0
    cx[cx >= nx] = nx-1
    cy = round((y-usr[1])*(ny/(usr[4]-usr[3])))
    cy[cy < 0] = 0
    cy[cy >= ny] = ny-1
    # Assign each point a number depending on its position.
    pN = cx+cy*nx
    # Remove points with duplicate positions.
    rmv = duplicated(pN)
    x = x[!rmv]
    y = y[!rmv]
    return(xy.coords(x, y))
    }

########################################
# Test xylim[2] to see if x- or y-axis limit is >1000, and if so, divide xylim
# and xy by 1000, repeating until xylim[2] <= 1000.  Works up to xylim[2] in
# trillions.
#
# Return a list with these members:
#   xylim: new scaled value of xylim
#   xy: new scaled value of xy (xy may be a list of vectors, and if so, is properly scaled)
#   label: "" if no scaling done, else " (x1K)", " (x1M)", etc. depending on scaling.
########################################
scaleBy1000 = function(xylim, xy)
    {
    xyscale = 0
    while (xylim[2] > 1000)
        {
        if (is.list(xy))
            xy = sapply(xy, function(V) V/1000, simplify=FALSE)
        else
            xy = xy/1000
        xylim = xylim/1000
        xyscale = xyscale+1
        }
    label = ""
    if (xyscale != 0)
        label = paste(" (x1", c("K", "M", "B", "T")[xyscale], ")", sep="")
    return(list(xylim=xylim, xy=xy, label=label))
    }

########################################
# Test xylim[2], which is presumed to be a PERCENT, to see if x- or y-axis limit
# is <1, and if so, multiply xylim and xy by 10 and repeat one more time.
# Return a list with these members:
#   xylim: new scaled value of xylim
#   xy: new scaled value of xy (xy may be a list of vectors, and if so, is
#       properly scaled)
#   sym: "%" if no scaling done, "%%" if multiply by 10, or "%%%" if multiply
#       by 100.
#   sym2: "%" if no scaling done, "‰" if multiply by 10, or "‱" if multiply
#       by 100.
#   per: "percent" if no scaling done, "permille" if multiply by 10, or "permyriad"
#       if multiply by 100.
#   Per: "Percent" if no scaling done, "Permille" if multiply by 10, or "Permyriad"
#       if multiply by 100.
########################################
scaleYpercentByTenths = function(xylim, xy)
    {
    xyscale = 1
    while (xylim[2] < 1 && xyscale < 3)
        {
        if (is.list(xy))
            xy = sapply(xy, function(V) V*10, simplify=FALSE)
        else
            xy = xy*10
        xylim = xylim*10
        xyscale = xyscale+1
        }
    sym = c("%", "%%", "%%%")[xyscale]
    sym2 = c("%", "‰", "‱")[xyscale]
    per = c("percent", "permille", "permyriad")[xyscale]
    Per = c("Percent", "Permille", "Permyriad")[xyscale]
    return(list(xylim=xylim, xy=xy, sym=sym, sym2=sym2, per=per, Per=Per))
    }

################################################################################
# Plot a regression line.
#
# Arguments:
#   x: x-coords for regression
#   y: y-coords for regression
#   col: color of line
#   ...: other arguments passed to abline()
#
# Returns: return value of lm() called to perform linear regression (invisibly)
################################################################################
plotRegressionLine = function(x, y, col="red", ...)
    {
    r = lm(y ~ x, data=data.frame(x=x, y=y))
    abline(r, col=col, ...)
    return(invisible(r))
    }

################################################################################
# Compute k-means clusters and plot lines showing boundary(s) between clusters.
#
# Arguments:
#   yx: vector of numeric values to cluster via k-means.  Should be either x- or
#       y- coordinate values.
#   k: value of k to use for k-means clustering.  Number of lines plotted is k-1.
#   hv: "h" to plot a horizontal lines for each threshold (yx is y-coords), "v"
#       for vertical (yx is x-coords).
#   line.col: color for the threshold lines, recycled to k-1.
#   line.lwd: width for the threshold lines, recycled to k-1.
#   line.lty: line type for the threshold lines, recycled to k-1.
#   xy: the x- (hv = "h") or y- (hv = "v") coordinate position at which to plot
#       text for each line, recycled to k-1.
#   txt: text to plot for each line, recycled to k-1, "" for none.
#   adj: text() adj argument for adjusting text position around line.
#   f: fraction of distance from maximum value of lower cluster to minimum value
#       of higher cluster, at which to choose the threshold, 0..1.
#   plot: TRUE to plot lines, FALSE only to compute thresholds and return them.
#   ...: other arguments passed to text()
#
# Returns: sorted vector of chosen thresholds, length is k-1.  NULL is returned
#   if length(unique(yx)) < k.
################################################################################
plotKmeansThresholds = function(yx, k, hv="h", line.col="red", line.lwd=1, line.lty=1,
    xy=0, txt="", adj=c(0.5, 0.5), f=0.5, plot=TRUE, ...)
    {
    if (length(unique(yx)) < k)
        return(NULL)
    k.result = kmeans(yx, k)
    ord = order(k.result$centers)
    N = k-1
    line.col = rep(line.col, length.out=N)
    line.lwd = rep(line.lwd, length.out=N)
    line.lty = rep(line.lty, length.out=N)
    xy = rep(xy, length.out=N)
    txt = rep(txt, length.out=N)
    r = rep(NA, length.out=N)
    for (i in 1:N)
        {
        max.lower = max(yx[k.result$cluster == ord[i]])
        min.upper = min(yx[k.result$cluster == ord[i+1]])
        thresh = max.lower + f*(min.upper-max.lower)
        r[i] = thresh
        col = line.col[i]
        lwd = line.lwd[i]
        lty = line.lty[i]
        if (!plot)
            next
        if (hv == "h")
            {
            abline(h=thresh, col=col, lwd=lwd, lty=lty)
            if (txt[i] != "")
                text(xy[i], thresh, txt[i], adj=adj, ...)
            }
        else
            {
            abline(v=thresh, col=col, lwd=lwd, lty=lty)
            if (txt[i] != "")
                text(thresh, xy[i], txt[i], adj=adj, ...)
            }
        }
    return(r)
    }

################################################################################
# Conservative 8-color palette adapted for color blindness, with first color = "black".
#
# Wong, Bang. "Points of view: Color blindness." nature methods 8.6 (2011): 441-441.
################################################################################
colorBlind.8 = c(black="#000000", orange="#E69F00", skyblue="#56B4E9",
    bluegreen="#009E73", yellow="#F0E442", blue="#0072B2", vermillion="#D55E00",
    reddishpurple="#CC79A7")
# plot(NA, xlim=0:1, ylim=0:1, axes=FALSE, xlab="", ylab="")
# rect((0:7)/8, 0, (1:8)/8, 1, border=NA, col=colorBlind.8)

################################################################################
# We sometimes need more than 8 color-blind-friendly colors, but we don't have
# any information on how to get those, if it is even possible.  So, instead,
# just add some more colors to colorBlind.8 that appear distinctive to ME!
################################################################################
colors.16 = c(colorBlind.8, aquamarine="aquamarine", lightsalmon2="lightsalmon2",
    darkorange4="darkorange4", grey100="grey95", darkorchid2="darkorchid2",
    darkblue="darkblue", gray30="gray30", lightskyblue1="lightskyblue1")
#colors.test = c(rbind(colors.16, rep(sample(colors(), 1), length(colors.16))))
#x = barplot(rep(1,length(colors.test)), ylim=c(0,1.25), col=colors.test,
#    space=rep(c(0.4, 0.0), length(colors.16)))
#text(x, 1, c(rbind(names(colors.16), rep(colors.test[2], length(colors.16)))),
#    srt=90, cex=0.7, adj=c(-0.2,0.5))

#######################################################################################
# Change colors to add alpha channel to them.  Alpha channel allows the color to be
# partially transparent.  When alpha=1, the color is solid; when 0, it is fully
# transparent; when 0.5, it is half-transparent.
# Arguments:
#   colors: vector of colors to which to add alpha channel.
#   alpha: vector of alpha channel values to use, recycled to length of "color" vector.
# Returns: vector of colors with alpha added.
#######################################################################################
addAlpha = function(colors, alpha)
    {
    if (alpha < 0)
        alpha = 0
    if (alpha > 1)
        alpha = 1
    alpha = rep(alpha, length.out=length(colors))
    col = col2rgb(colors)
    col = rgb(col["red",], col["green",], col["blue",], alpha*255, maxColorValue=255)
    names(col) = names(colors)
    return(col)
    }

#######################################################################################
# Change colors to add black or white color to them.  When whiteness=1, the color
# becomes solid white; when 0, it becomes solid black; at 0.5 is unchanged from its
# current color.
# Arguments:
#   colors: vector of colors to which to add black or white color.
#   whiteness: vector of whiteness values to use, recycled to length of "color" vector.
# Returns: vector of colors with black or white added.
#######################################################################################
addBlackWhite = function(colors, whiteness)
    {
    whiteness = rep(whiteness, length.out=length(colors))
    col = col2rgb(colors)
    whiter = (whiteness > 0.5)
    blacker = !whiter
    w.w = 2*(whiteness[whiter]-0.5)
    w.b = 2*whiteness[blacker]
    col["red", whiter] = w.w*255 + (1-w.w)*col["red", whiter]
    col["green", whiter] = w.w*255 + (1-w.w)*col["green", whiter]
    col["blue", whiter] = w.w*255 + (1-w.w)*col["blue", whiter]
    col["red", blacker] = w.b*col["red", blacker]
    col["green", blacker] = w.b*col["green", blacker]
    col["blue", blacker] = w.b*col["blue", blacker]
    col = rgb(col["red",], col["green",], col["blue",], maxColorValue=255)
    names(col) = names(colors)
    return(col)
    }

#######################################################################################
# Convert a vector of color names to a vector of "#xxxxxx" color values.  If the color
# name already is of that form, it remains unchanged.
#######################################################################################
makeHtmlColor = function(colors)
    {
    nms = names(colors)
    colors = col2rgb(colors)
    colors = rgb(colors["red",], colors["green",], colors["blue",], maxColorValue=255)
    names(colors) = nms
    return(colors)
    }

#######################################################################################
# Make and return a vector of nice heat map colors composed of shades of one color for
# negative values and shades of another for positive values, and a third color for zero
# values.  The number of minus and plus colors is specified as Nplus and Nminus.
#######################################################################################
makeHeatmapColors = function(zeroColorName, plusColorName, Nplus, minusColorName="black", Nminus=0)
    {
    Ncolors = Nminus+Nplus+1
    plusColor = as.data.frame(t(col2rgb(plusColorName)/255))
    zeroColor = as.data.frame(t(col2rgb(zeroColorName)/255))
    minusColor = as.data.frame(t(col2rgb(minusColorName)/255))
    heatmapColors = c()
    if (Nminus > 0)
        {
        for (i in Nminus:1)
            {
            k = i/Nminus
            col = (k*minusColor + (1-k)*zeroColor)
            heatmapColors = c(heatmapColors, rgb(col$red, col$green, col$blue))
            }
        }
    heatmapColors = c(heatmapColors, rgb(zeroColor$red, zeroColor$green, zeroColor$blue))
    if (Nplus > 0)
        {
        for (i in 1:Nplus)
            {
            k = i/Nplus
            col = (k*plusColor + (1-k)*zeroColor)
            heatmapColors = c(heatmapColors, rgb(col$red, col$green, col$blue))
            }
        }
    return(heatmapColors)
    }

#######################################################################################
# Draw some colors.  The selectionRE argument if not NULL is a regular expression to
# use to select a subset of all colors, or, if (length(selectionRE) > 1, it is taken as
# a vector of colors to draw.  This is useful for choosing colors to use for things.
#######################################################################################
drawColors = function(selectionRE=NULL)
    {
    cols = colors()
    if (!is.null(selectionRE))
        {
        if (length(selectionRE) > 1)
            cols = selectionRE
        else
            cols = cols[grep(selectionRE, cols)] # Select colors with first grep argument in the name
        }
    devsize = dev.size("px")
    plt = par("plt")
    H = devsize[1]*(plt[2]-plt[1])
    V = devsize[2]*(plt[4]-plt[3])
    colWidthEst = 200
    numColumns = 1 + as.integer(H/colWidthEst)
    colWidth = H / numColumns
    colHeightEst = 10
    numRows = 1 + as.integer(V/colHeightEst)
    numRows = 1 + as.integer((length(cols)-1)/numColumns)
    colHeight = V / numRows
    barWidth = colWidth * 0.3
    barThickness = 10
    textCex = 0.7
    plot(NA, type="n", xlim=c(0,H), ylim=c(0,V), axes=FALSE, xlab=NA, ylab=NA, mgp=rep(0,3), mar=rep(0,4), oma=rep(0,4))
    k = 1
    for (j in 1:numColumns)
        {
        for (i in 1:numRows)
            {
            col = cols[k]
            k = k+1
            x = (j-1)*colWidth
            y = V-(i-1)*colHeight
            lines(c(x, x+barWidth), c(y,y), col=col, lwd=barThickness)
            text(x+barWidth, y, col, pos=4, cex=textCex)
            }
        }
    if (k < length(cols))
        text(0, 0, paste0("+", length(cols)-k, " more colors"))
    }

#######################################################################################
# Draw colors and let user click on one to see its name.  Written by Julin Maloof,
# Oct 27, 2010.  Made into function by Ted.  Arguments:
#    console: should colors be printed to the console?
#    plotText: should color names be printed onto the graph?
#######################################################################################
identifyColors = function(console=TRUE, plotText=TRUE)
    {
    #script to identify colors
    #julin maloof Oct 27, 2010

    #need to convert named colors to hex representaion
    colorhex = rgb(t(col2rgb(colors())),max=255)

    #create a matrix of colornames.  This will have the same dimensions as the plot
    colorNames = matrix(colors(),ncol=25)

    #adjust graphic parameters to reduce margin size.  Store original parameters in op
    op = par(mar=c(2,2,4,2))

    #plot an image of all named colors
    image(x=0:27, y=0:25, z=matrix(1:length(colorhex), ncol=25),
        col=colorhex, ylab="", xlab="", xaxt="n", yaxt="n",
        main="Click a color to find its name\n Click in the margin to finish")

    #repeatedly check for mouse click and report color
    repeat
        {
        location = locator(n=1) #get mouse click location

        if (location$x < 0 | #check to see if outide plot area
            location$x > 27 |
            location$y < 0 |
            location$y > 25) break #if outside plot area then quit

        if (console)
            print(colorNames[ceiling(location$x), ceiling(location$y)])

        if (plotText)
            text(location, labels=colorNames[ceiling(location$x), ceiling(location$y)], cex=.75)
        }

    par(op) # restore graphic parameters
    }

#######################################################################################
# Modified version of seqLogo() from the seqLogo package.  This version uses the column
# names of pwm as the axis labels, if such names are present.  It does not assume that
# the base order is ACGT, but uses the order of the pwm row names if present.  If any
# column is all 0, that column is not displayed.
#######################################################################################
seqLogo2 = function (pwm, ic.scale=TRUE, xaxis=TRUE, yaxis=TRUE, xfontsize=15, yfontsize=15)
    {
    # Some functions are private to seqLogo module but we need them.
    pwm2ic = getAnywhere("pwm2ic")$objs[[1]]
    addLetter = getAnywhere("addLetter")$objs[[1]]

    if (class(pwm) == "pwm")
        pwm = pwm@pwm
    else if (class(pwm) == "data.frame")
        pwm = as.matrix(pwm)
    else if (class(pwm) != "matrix")
        stop("pwm must be of class matrix or data.frame")

    if (any(pwm < 0))
        stop("pwm must not contain negative values.")
    colSums = apply(pwm, 2, sum)
    colSums = colSums[colSums != 0]
    if (any(abs(1 - colSums) > 0.01))
        stop("Columns of pwm must add up to 1.0, or be all 0's")

    chars = rownames(pwm)
    if (is.null(chars))
        chars = c("A", "C", "G", "T")
    letters = list(x=NULL, y=NULL, id=NULL, fill=NULL)
    npos = ncol(pwm)
    if (ic.scale)
        {
        ylim = 2
        ylab = "Information content"
        facs = pwm2ic(pwm)
        }
    else
        {
        ylim = 1
        ylab = "Probability"
        facs = rep(1, npos)
        }
    wt = 1
    x.pos = 0
    for (j in 1:npos)
        {
        column = pwm[, j]
        hts1 = 0.95 * facs[j]
        if (!all(column == 0))
            {
            hts = hts1 * column
            letterOrder = order(hts)
            y.pos = 0
            for (i in 1:4)
                {
                letter = chars[letterOrder[i]]
                ht = hts[letterOrder[i]]
                if (ht > 0)
                    letters = addLetter(letters, letter, x.pos, y.pos, ht, wt)
                y.pos = y.pos + ht + 0.01
                }
            }
        x.pos = x.pos + wt
        }
    grid.newpage()
    bottomMargin = ifelse(xaxis, 2 + xfontsize/3.5, 2)
    leftMargin = ifelse(yaxis, 2 + yfontsize/3.5, 2)
    pushViewport(plotViewport(c(bottomMargin, leftMargin, 2, 2)))
    pushViewport(dataViewport(0:ncol(pwm), 0:ylim, name="vp1"))
    grid.polygon(x=unit(letters$x, "native"), y=unit(letters$y,
        "native"), id=letters$id, gp=gpar(fill=letters$fill, col="transparent"))
    if (xaxis)
        {
        xlabs = colnames(pwm)
        if (is.null(xlabs))
            xlabs = 1:ncol(pwm)
        grid.xaxis(at=seq(0.5, ncol(pwm) - 0.5), label=xlabs, gp=gpar(fontsize=xfontsize))
        grid.text("Position", y=unit(-3, "lines"), gp=gpar(fontsize=xfontsize))
        }
    if (yaxis)
        {
        grid.yaxis(gp=gpar(fontsize=yfontsize))
        grid.text(ylab, x=unit(-3, "lines"), rot=90, gp=gpar(fontsize=yfontsize))
        }
    popViewport()
    popViewport()
    par(ask=FALSE)
    }

#######################################################################################
# I've had never-ending trouble with the heatmap() function.  Now the problem is that
# I'm using layout(), and one of my plots within my layout is a heatmap, and the
# heatmap() function itself uses layout()!
#
# Solution: copy the function and modify it here not to use layout().  I'm doing
# a simplified heatmap with no column or row dendrograms, so I can simplify the
# function, to remove layout().
#
# Changes to arguments:
#   1. Some arguments removed, not supported here.
#   2. margins must now be a vector of 4 elements as usual for margins, bottom, left,
#       top, and right.
#   3. add arguments xlim, ylim, xspan, yspan.  Latter two are like former two
#       but give that portion of the (xlim, ylim) region that the heatmap
#       occupies, and they default to being equal to (xlim, ylim).
#   4. To support 3, labels are drawn with text() instead of axis().
#   5. If argument "add" is supplied, it is now used to determine whether to
#       call plot() before calling image(), and is NOT passed to image (which
#       always gets add=TRUE).
#   6. Argument 'col' is now listed explicitly.
#   7. Allow argument "scale" to be a vector of two values that are the values
#       in the same coordinate system as x that correspond to col[1] and
#       col[length(col)].
#   8. Add argument 'border', if not NA, grid lines are drawn in that color.
#   9. Allow labRow and labCol to be NA to suppress labels.
#
# Returns: list of useful parameters from making the heatmap.
#
# Example:
#   x = matrix(runif(500, 0.5, 1.9), nrow=10, dimnames=list(LETTERS[1:10], NULL))
#   cols = makeHeatmapColors("white", "red", 200)
#   hm = heatmapSimple(x, col=cols, scale=c(0, 2), cexCol=0.5, xlim=0:1, ylim=0:1,
#           xspan=c(0.1, 0.9), yspan=c(0.5, 1.0), border="black")
#   labels = pretty(c(0,2), 5)
#   heatmapLegend(0.1, 0.1, 0.4, 0.2, cols, "My X Label", y.xlab=0.03, y.axis=0.09, labels=labels)
#######################################################################################
heatmapSimple = function(x, add.expr, symm=FALSE, revC=FALSE,
    scale=c("row", "column", "none"), na.rm=TRUE, margins=c(5, 5, 5, 5),
    cexRow=NULL, cexCol=NULL, labRow=NULL, labCol=NULL,
    main=NULL, xlab=NULL, ylab=NULL, col=hcl.colors(12, "YlOrRd", rev=TRUE),
    border=NA, xlim=NULL, ylim=NULL, xspan=NULL, yspan=NULL,
    add=FALSE, ...)
    {
    if (symm && missing(scale))
        scale = "none"
    if (is.null(scale))
        scale = "row"
    di = dim(x)
    if (length(di) != 2 || !is.numeric(x))
        stop("'x' must be a numeric matrix")
    nr = di[1L]
    nc = di[2L]
    if (nr <= 1 || nc <= 1)
        stop("'x' must have at least 2 rows and 2 columns")
    if (is.null(cexRow)) cexRow = 1/log10(nr)
    if (is.null(cexCol)) cexCol = 1/log10(nc)
    if (!is.numeric(margins) || length(margins) != 4L)
        stop("'margins' must be a numeric vector of length 4")
    rowInd = 1L:nr
    colInd = 1L:nc
    x = x[rowInd, colInd]
    labRow = if (is.null(labRow))
        {
        if (is.null(rownames(x))) rowInd
        else rownames(x)
        }
    else if (is.na(labRow[1])) NA
    else labRow[rowInd]
    labCol = if (is.null(labCol))
        {
        if (is.null(colnames(x))) colInd
        else colnames(x)
        }
    else if (is.na(labCol[1])) NA
    else labCol[colInd]
    if (scale[1] == "row")
        {
        x = sweep(x, 1L, rowMeans(x, na.rm=na.rm), check.margin=FALSE)
        sx = apply(x, 1L, sd, na.rm=na.rm)
        x = sweep(x, 1L, sx, "/", check.margin=FALSE)
        }
    else if (scale[1] == "column")
        {
        x = sweep(x, 2L, colMeans(x, na.rm=na.rm), check.margin=FALSE)
        sx = apply(x, 2L, sd, na.rm=na.rm)
        x = sweep(x, 2L, sx, "/", check.margin=FALSE)
        }
    else if (is.numeric(scale))
        {
        N = length(col)
        d = diff(scale)[1]
        if (d == 0) stop("scale must be two numbers, second greater than first")
        x = floor((x-scale[1])*N/d)
        x[!is.na(x) & x > N] = N
        x[!is.na(x) & x < 1] = 1
        }
    op = par(mar=margins)
    if (!symm || (scale[1] != "none" && is.character(scale)))
        x = t(x)
    if (revC)
        {
        iy = nr:1
        x = x[, iy]
        }
    else iy = 1L:nr
    if (is.null(xlim))
        xlim = 0.5 + c(0, nc)
    if (is.null(ylim))
        ylim = 0.5 + c(0, nr)
    if (is.null(xspan))
        xspan = xlim
    if (is.null(yspan))
        yspan = ylim
    xwidth = diff(xspan)/nc
    ywidth = diff(yspan)/nr
    xctr = seq(xspan[1]+xwidth/2, by=xwidth, length.out=nc)
    yctr = seq(yspan[1]+ywidth/2, by=ywidth, length.out=nr)
    if (!is.na(labCol[1]))
        xctr = setNames(xctr, labCol)
    if (!is.na(labRow[1]))
        yctr = setNames(yctr, labRow)
    xedges = seq(xspan[1], xspan[2], length.out=nc+1)
    yedges = seq(yspan[1], yspan[2], length.out=nr+1)
    if (!add)
        plot(NA, type="n", xlim=xlim, ylim=ylim, main="", xlab="", ylab="", axes=FALSE)
    image(xctr, yctr, x, add=TRUE, xlim=xspan, ylim=yspan, axes=FALSE, col=col,
        xlab="", ylab="", ...)
    if (!is.na(border))
        {
        segments(xspan[1], yedges, xspan[2], yedges, col=border)
        segments(xedges, yspan[1], xedges, yspan[2], col=border)
        }
    xgap = diff(xlim)/200
    ygap = diff(ylim)/200
    if (!is.na(labCol[1]))
        text(xctr, yspan[1]-ygap, labCol, adj=c(1.0, 0.5), srt=90, cex=cexCol, xpd=NA)
    if (!is.na(labRow[1]))
        text(xspan[2]+xgap, yctr, labRow, adj=c(0.0, 0.5), cex=cexRow, xpd=NA)
    if (!is.null(xlab))
        mtext(xlab, side=1, line=margins[1L] - 1.25)
    if (!is.null(ylab))
        mtext(ylab, side=4, line=margins[4L] - 1.25)
    if (!missing(add.expr))
        eval.parent(substitute(add.expr))
    if (!is.null(main))
        title(main, cex.main=1.5 * op[["cex.main"]])
    par(op)
    return(list(scale=scale, nr=nr, nc=nc, xlim=xlim, ylim=ylim,
        xspan=xspan, yspan=yspan, xwidth=xwidth, ywidth=ywidth,
        xctr=xctr, yctr=yctr, xedges=xedges, yedges=yedges,
        xgap=xgap, ygap=ygap, x=x))
    }

#######################################################################################
# Plot a heatmap color legend for a heatmap that was plotted with heatmapSimple().
#
# Arguments:
#   x1,y1,x2,y2: position of legend heatmap
#   col: vector of colors, same as passed to heatmapSimple().
#   xlab: label under the legend.
#   y.xlab: y-position of xlab, NA for none.
#   y.axis: y-position of x-axis or NA for none.
#   at: x-positions of ticks and labels on x-axis, NULL automatic.
#   labels: tick labels (same size as 'at'), NULL for no labels.
#   cex.xlab: cex factor for xlab.
#   cex.axis: cex factor for x-axis labels.
#
# Returns: nothing
#
# Example: see heatmapSimple().
#######################################################################################
heatmapLegend = function(x1, y1, x2, y2, col, xlab="", y.xlab=NA,
    y.axis=NA, at=NULL, labels=NULL, cex.xlab=0.8, cex.axis=0.8)
    {
    mtx = matrix(rep(1:length(cols), 2), nrow=2, byrow=TRUE)
    heatmapSimple(mtx, add=TRUE, scale="none", col=col, xspan=c(x1,x2), yspan=c(y1,y2),
        labRow=NA, labCol=NA)
    if (xlab != "" && !is.na(y.xlab))
        text(mean(c(x1, x2)), y.xlab, xlab, pos=1, cex=cex.xlab)
    if (!is.na(y.axis))
        {
        if (is.null(at))
            at = seq(x1, x2, length.out=length(labels))
        axis(1, at=at, labels=labels, pos=y.axis, cex.axis=cex.axis, padj=-1)
        }
    }

#######################################################################################
# End of file.
#######################################################################################
Sourced.Include_PlotFunctions = TRUE
cat("  Include_PlotFunctions.R included\n")
