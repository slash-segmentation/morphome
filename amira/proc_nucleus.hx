# Amira Project 600
# Amira
# Generated by morphOME (https://github.com/slash-segmentation/morphome)

set fname "<FILENAME>"
set pathOut "<PATH_OUT>"
set scale [list <SCALE>]

set scalex [lindex $scale 0]
set scaley [lindex $scale 1]
set scalez [lindex $scale 2]

###
####
# DATA IMPORT
####
###

# Extract the VRML file's basename
set base [file tail $fname]
set base [string trimright $base ".wrl"]

# Load the VRML file into Amira
[load $fname] setLabel $base

# Convert VRML to surface (named "GeometrySurface")
set module "Open Inventor Scene To Surface"
create HxGeometryToSurface $module
$module data connect $base
$module action snap
$module fire

# Remesh the surface. The surface is remeshed using the best isotropic vertex
# placement and 3x the number of input triangles. This is necessary to get a 
# finer sampling of the Shape Index across the surface.
set module "Remesh Surface"
set nTriIn ["GeometrySurface" getNumTriangles]
set nTriOut [expr $nTriIn * 3]
create HxRemeshSurface $module
$module select
$module data connect "GeometrySurface"
$module fire
$module objective setIndex 0 1 
$module interpolateOrigSurface setValue 0
$module desiredSize setValue 1 $nTriOut
$module remeshOptions1 setValue 0 0 
$module remeshOptions1 setValue 1 1 
$module fire
$module remesh snap
$module fire

# Smooth the remeshed surface
set module "Smooth Surface"
create HxSurfaceSmooth $module
$module data connect "GeometrySurface.remeshed"
$module parameters setValue 0 2
$module parameters setValue 1 0.6
$module action snap
$module fire

###
#####
# NUCLEAR CURVATURE 
#####
###

# Compute Shape Index. A curvature module is generated, and the computation 
# method is changed to 'on vertices'. The default parameters are used.
set module "Curvature"
create HxGetCurvature $module
$module data connect "GeometrySurface.smooth"
$module method setValue 1
$module output setValue 10 
$module doIt snap
$module fire

# Compute gradient of the Shape Index scalar field.
set module "Surface Gradient"
create HxComputeSurfaceGradient $module
$module data connect "ShapeIndex"
$module fire

# Convert the gradient vectors from Angstroms to microns
set module "Arithmetic"
create HxArithmetic $module
$module inputA connect "ShapeIndex_Gradient"
$module expr0 setValue "Ax * 10000"
$module expr1 setValue "Ay * 10000"
$module expr2 setValue "Az * 10000"
$module create

###
####
# CONVEX HULL DIFFERENCE
#### 
###

# Convex hull
set module "Convex Hull"
create HxConvexHull $module
"Convex Hull" data connect "GeometrySurface.smooth"
"Convex Hull" action snap
"Convex Hull" fire

# Get surface area and volume of nucleus
set module "Surface Area Volume Nucleus"
create HxSurfaceArea $module
$module data connect "GeometrySurface.smooth"
$module doIt snap
$module fire
set saNucleus ["GeometrySurface.statistics" getValue 2 0]
set vNucleus ["GeometrySurface.statistics" getValue 3 0]

# Get surface area and volume of convex hull
set module "Surface Area Volume Convex Hull"
create HxSurfaceArea $module
$module data connect "GeometrySurface-convexHull"
$module doIt snap
$module fire
set saConvHull ["GeometrySurface-convexHull.statistics" getValue 2 0]
set vConvHull ["GeometrySurface-convexHull.statistics" getValue 3 0]

###
####
# 3D BINARY IMAGE METRICS
####
###

# Convert the surface to a binary volume stack
set module "Scan Surface To Volume"
create HxScanConvertSurface $module
$module data connect "GeometrySurface.smooth"
$module field disconnect
$module fire
set xmin [$module bbox getValue 0]
set xmax [$module bbox getValue 1]
set ymin [$module bbox getValue 2]
set ymax [$module bbox getValue 3]
set zmin [$module bbox getValue 4]
set zmax [$module bbox getValue 5]
set dimx [expr round((double($xmax) / $scalex - double($xmin) / $scalex))]
set dimy [expr round((double($ymax) / $scaley - double($ymin) / $scaley))]
set dimz [expr round((double($zmax) / $scalez - double($zmin) / $scalez))]

###
####
# DATA EXPORT
####
###

# Export files to disk for further analysis
set fname_gradient [file join $pathOut ${base}_gradient.am]
set fname_shapeindex [file join $pathOut ${base}_shapeindex.am]
set fname_surface [file join $pathOut ${base}_surface.surf]
set fname_convhull [file join $pathOut ${base}_convhull.surf]

"Result" exportData "Amira ASCII" $fname_gradient
"ShapeIndex" exportData "Amira ASCII" $fname_shapeindex
"GeometrySurface.smooth" exportData "HxSurface ASCII" $fname_surface
"GeometrySurface-convexHull" exportData "HxSurface ASCII" $fname_convhull

exit
