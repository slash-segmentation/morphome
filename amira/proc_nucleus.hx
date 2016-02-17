# Amira

set fname "<FILENAME>"

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

# Export files to disk
set fname_gradient ${base}_gradient.am
set fname_shapeindex ${base}_shapeindex.am
set fname_surface ${base}_surface.surf

"Result" exportData "Amira ASCII" $fname_gradient
"ShapeIndex" exportData "Amira ASCII" $fname_shapeindex
"GeometrySurface.smooth" exportData "HxSurface ASCII" $fname_surface
