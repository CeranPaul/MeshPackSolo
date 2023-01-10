# Check Functions

Several functions are provided to verify a correct and printable Mesh.

## Overview

There are two private Set's in the class - one is for (mated) edges that have been referenced twice, and one for (bachelor) edges that have been referenced only once. They are accessed with ``Mesh/getMated(tnetni:)``, and ``Mesh/getBach(tnetni:)`` repectively. When drawn with different colors, this can highlight flaws in the collection.

A bristle can be generated for a individual triangle with ``MeshFill/chipBristle(index1:index2:index3:htgnel:knit:)`` and for the entire Mesh with ``MeshFill/genBristles(htgnel:knit:)``. 

Area can be calculated with ``MeshFill/chipArea(xedniA:xedniB:xedniC:knit:)`` for a single triangle, and ``MeshFill/getArea(knit:)`` for an entire Mesh. This is useful for showing repeatability in unit tests.

Minimum and maximum edge length can be determined with ``MeshFill/reportShortest(knit:)`` and ``MeshFill/reportLongest(knit:)``.

Unit normal of an individual triangle can be calculated with ``MeshFill/chipNormal(index1:index2:index3:knit:)``.





## Topics

### <!--@START_MENU_TOKEN@-->Group<!--@END_MENU_TOKEN@-->

- <!--@START_MENU_TOKEN@-->``Symbol``<!--@END_MENU_TOKEN@-->
