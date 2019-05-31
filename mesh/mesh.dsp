// Nonlinear Waveguide Mesh
// Autor: der Pablo 
// JOS. https://ccrma.stanford.edu/~rmichon/publications/doc/DAFx11-Nonl-Allpass.pdf
// Sources http://www.music.mcgill.ca/~gary/618/reading.html

// Reference videos:
// - Cymbal https://www.youtube.com/watch?v=6dLZ3hJbLqE

// Limitations:
// Effect of wave dispersion due to discretization of propagation in two directions. Limitations to a low frequency range. 
// Again, see Stephan Bilbao youtube video. 

// Objective: evolving spectra due to nonlinear coupling between modes --> mesh (wave propagation) + nl apf (coupling bw modes, energy conserving)
// TO DO: sound of plate on chromaphone
//        excitation postion
//        what mesh parameters are important (chromaphone, thesis). what determines snare drum from metal plate (material)
//        how does dispersion error sound? stephan bilbao youtube maybe 

// NL allpass investigation
// see if it sounds natural with N=2 and low frequency lowpass
// coefficient modulation: lowpass input signal-> slower modulation (pitch) highpass? saturation? 
//                         LFO triggered? --> could be good for generating FM sidebands
//                         read paper (last section) for further ideas/understanding of coupling  

// Filter investigation:
// lowpass (buttworth) sounds good at order II
// elliptic has a little bit of resonance for higher frequencies but at very low frequencies (607 Hz) has nice 
// resonances and causes Allpass to modulate harmonics. Which is nice for congas. 
// also much more stable than others.


import("filter.lib"); // for mesh_square()
import("misceffect.lib");
import("signal.lib");
import("instrument.lib");

N=8;  // must be power of 2, and mesh order = 4*N is number of feedback loops = number of LP + NLAP branches
NA=4; // allpass order (any positive integer)

volume = hslider("h:Basic_Parameters/volume [1][tooltip:Volume (value between 0 and 1)]",1,0,1,0.01); 
gate = button("h:Basic_Parameters/gate [1][tooltip:noteOn = 1, noteOff = 0]");
gain = hslider("h:Basic_Parameters/gain [1][tooltip:Gain (value between 0 and 1)]",1,0,1,0.01); 
touchLength = hslider("v:Physical_Parameters/Touch_Length
[2][tooltip:A value between 0 and 1]",0.15,0,1,0.01)*2;
//model parameters
lpgain = hslider("v:Physical_Parameters/Lp_Gain
[3][tooltip:A value between 0 and 1]",0.99999999999,0.980,0.99999999999,0.000000000001);
lpQ = hslider("v:Physical_Parameters/Lp_Q
[3][tooltip:A value between 0 and 1]",0.1,0.05,0.7,0.001);
lpFreq = hslider("v:Physical_Parameters/Lp_Freq
[4][tooltip:A value between 0 and 1]",20000,40,20000,100);
gain_g = hslider("h:Basic_Parameters/gain_g [1][tooltip:Gain_g (value between 0 and 10)]",1,0,2*3.14159,0.01); 
fine_gain_g = hslider("h:Basic_Parameters/fine_gain_g [1][tooltip:Gain_g (value between 0 and 10)]",0,0,1,0.001); 

//mesh

modulation = gain_g + fine_gain_g;
nlmesh(N,NA,x)=mesh_square(N)~(lpbank(4*N) : apbank(4*N,x))
with {
  coeffs(x)=par(i,NA,x); // e.g.
  apbranch(i,x) = allpassnn(NA,coeffs(modulation),x);
  lpbranch(i) = resonlp(lpFreq,lpQ,-lpgain); // resonlp(fc,Q,gain) 
  apbank(M,x) = bus(M)
    : par(i,M-1,apbranch(i)),
                apbranch(M-1) + x;
  lpbank(M) = bus(M)
    : par(i,M,lpbranch(i));
};

//process = _,asympT60(gain,0,touchLength,gate) :>+: (nlmesh(N,NA)) :>+ :_ * pow(volume,2) <: _,_;
process = nlmesh(N,NA);