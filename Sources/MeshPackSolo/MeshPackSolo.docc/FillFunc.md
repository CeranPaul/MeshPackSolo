# Fill Functions

Utility functions to fill a small area with triangles.

## Overview

A ladder of two chains of points can be connected with ``MeshFill/fillChains(port:stbd:)``.

![A ladder getting filled](ladder.png)

Circular rings can be built with ``MeshFill/twistedRings(alpha:beta:)``. It is expected that both rings progress in the same direction. The start points of the two rings can have different clockings.

![A circular ring.](SaturnRing.png)

Meshes can be combined with ``MeshFill/absorb(freshKnit:baseKnit:)``.

## Topics

### <!--@START_MENU_TOKEN@-->Group<!--@END_MENU_TOKEN@-->

- <!--@START_MENU_TOKEN@-->``Symbol``<!--@END_MENU_TOKEN@-->
