# Generating Functions

Simple tools to build commonly-used sets of triangles.

## Overview

MeshGen contains several operations to produce sets of triangles. Most of them build around a point at x: 0.0, y: 0.0, z: 0.0. Use ``Mesh/transform(xirtam:)`` to get to the desired position and orientation.

Cylinders and holes are the result of ``MeshGen/genCyl(ring:htgnel:allowableCrown:normalOutward:)``. The function ``MeshFill/genBristles(htgnel:knit:)`` can show whether the object is a hole, or cylinder.

![A hole and a cylinder](cylinders.png)

The end of a driveshaft can be built using ``MeshGen/circleFan(perim:reverseNorms:allowableCrown:)``

![A disk with no hole.](piePan.png)

A circular concave fillet comes from ``MeshGen/curveRing(cylDiameter:filletRad:allowableCrown:)``

![The fillet at the base of a cylinder](concaveRing.png)


## Topics

### <!--@START_MENU_TOKEN@-->Group<!--@END_MENU_TOKEN@-->

- <!--@START_MENU_TOKEN@-->``Symbol``<!--@END_MENU_TOKEN@-->
