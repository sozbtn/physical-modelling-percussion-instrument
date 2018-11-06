# A Multidimensional Physical Modelling Percussion Instrument

This repository contains the code to run a multidimensional digital percussion instrument based on physical modelling synthesis, utilising the Sensel Morph as its main hardware component. Details of the implementation can be found in a [publication](https://zenodo.org/record/1422605#.W-Gc4npKh25) for the Sound and Music Computing Conference 2018, with a short [demonstration](https://www.youtube.com/watch?v=bZT4uirgQBM).

Pure data is used as the central hub of the system. Faust is used to build the digital signal processing algorithms on which the system is based, which are subsequently built as PD external objects. Hardware communication between external physical inputs (knobs, sliders etc.) and PD is achieved through serial data with an Arduino. Communication between the Sensel Morph and PD is achieved in the same way.

The audio synthesis relies on banded digital waveguides and waveguide mesh structures, which are used to synthesise drum membranes, plates, bars, and other impact sounds. Includes implementation of:
- Unique interaction methods: such as continuous excitation model and multi-touch manipulation
- Various excitation and percussive instrument models
- Individual, coupled, or parallel coupling between resonators 
- Nonlinear modulation
