
import("stdfaust.lib");
import("instruments.lib");


//==================== GUI SPECIFICATION ================

freq = nentry("h:Basic_Parameters/freq [1][unit:Hz] [tooltip:Tone frequency]",100,20,20000,1);
gain = nentry("h:Basic_Parameters/gain [1][tooltip:Gain (value between 0 and 1)]",1,0,1,0.01); 
gate = button("h:Basic_Parameters/gate [1][tooltip:noteOn = 1, noteOff = 0]");
preset = nentry("h:Basic_Parameters/v:Physical_Parameters/Preset [1][tooltip:0->BigTom]", 0, 0, nPresets-1, 1) : si.smoo;
//preset = 0;
detune = vslider("h:Basic_Parameters/detune [1][unit:dB] [tooltip:detune]",1,0.5,1.2,0.0001) : si.smoo;
damping = vslider("h:Basic_Parameters/damping [1][tooltip:damping (value between 1 and 10)]",1,1,5,0.01);

select = nentry("h:Physical_and_Nonlinearity/v:Physical_Parameters/Excitation_Selector
[2][tooltip:0=Bow; 1=Strike]",1,0,1,1);
integrationConstant = hslider("h:Physical_and_Nonlinearity/v:Physical_Parameters/Integration_Constant
[2][tooltip:A value between 0 and 1]",0,0,1,0.01);
baseGain = hslider("h:Physical_and_Nonlinearity/v:Physical_Parameters/Base_Gain
[2][tooltip:A value between 0 and 1]",1,0,1,0.01);
bowPressure = hslider("h:Physical_and_Nonlinearity/v:Physical_Parameters/Bow_Pressure
[2][tooltip:Bow pressure on the instrument (Value between 0 and 1)]",0.2,0,1,0.01);
bowPosition = hslider("h:Physical_and_Nonlinearity/v:Physical_Parameters/Bow_Position
[2][tooltip:Bow position on the instrument (Value between 0 and 1)]",0,0,1,0.01);

typeModulation = nentry("h:Physical_and_Nonlinearity/v:Nonlinear_Filter_Parameters/Modulation_Type 
[3][tooltip: 0=theta is modulated by the incoming signal; 1=theta is modulated by the averaged incoming signal;
2=theta is modulated by the squared incoming signal; 3=theta is modulated by a sine wave of frequency freqMod;
4=theta is modulated by a sine wave of frequency freq;]",0,0,4,1);
nonLinearity = hslider("h:Physical_and_Nonlinearity/v:Nonlinear_Filter_Parameters/Nonlinearity 
[3][tooltip:Nonlinearity factor (value between 0 and 1)]",0,0,1,0.01);
frequencyMod = hslider("h:Physical_and_Nonlinearity/v:Nonlinear_Filter_Parameters/Modulation_Frequency 
[3][unit:Hz][tooltip:Frequency of the sine wave for the modulation of theta (works if Modulation Type=3)]",220,20,1000,0.1);
nonLinAttack = hslider("h:Physical_and_Nonlinearity/v:Nonlinear_Filter_Parameters/Nonlinearity_Attack
[3][unit:s][Attack duration of the nonlinearity]",0.1,0,2,0.01);
a = hslider("h:Physical_and_Nonlinearity/v:Physical_Parameters/a
[3][tooltip:attack]",0.002,0.001,0.01,0.001);
d = hslider("h:Physical_and_Nonlinearity/v:Physical_Parameters/d
[3][tooltip:decay]",0.005,0.001,0.01,0.001);

//==================== MODAL PARAMETERS ================

nPresets = 2;		  // number of presets

// big tom drum
nMode(0) = 16;        // number of modes in preset 0
modes(0,0) = 1.0;     // modes ratios to fundamental
modes(0,1) = 1.8064;
modes(0,2) = 2.2997;
modes(0,3) = 2.6556;
modes(0,4) = 2.9554;
modes(0,5) =  3.0749;
modes(0,6) =  3.5227;
modes(0,7) = 4.0321;
modes(0,8) =  4.2016;
modes(0,9) = 4.9170;
modes(0,10) =  5.3809;
modes(0,11) = 6.2952;
modes(0,12) = 7.1936;
modes(0,13) = 9.1436;
modes(0,14) = 10.1516;
modes(0,15) = 11.6771;

modes(1,0) = 1.0;     // modes ratios to fundamental
modes(1,1) = 1.148;
modes(1,2) = 1.998;
modes(1,3) = 2.138;
modes(1,4) = 2.299;
modes(1,5) =   2.451;
modes(1,6) =  2.660;
modes(1,7) = 2.985;
modes(1,8) =  3.442;
modes(1,9) = 4.013;
modes(1,10) =  4.598;
modes(1,11) = 4.855;
modes(1,12) = 5.557;
modes(1,13) = 7.482;
modes(1,14) = 10.1516;
modes(1,15) = 18.734;


// feedback gains
f_gain_fader(x) = hgroup("Feedback Gains", vslider("h:Basic_Parameters/feedback_gain_%x [%3x][tooltip: FB Gain %x] [style:knob] [size: 1]",pow(0.999,x),0,0.99999999999,0.001)) : si.smoo;
f_gain(x) = -1/(f_gain_fader(x) + 0.95925)^3 + 1.13293; // better "log-like" curve

// forward gains
d_gain_fader(x) = hgroup("Direct Gains",vslider("h:Basic_Parameters/direct_gain_%x [%4x] [tooltip: Direct Gain %x] [style:knob]",0.8,0,1,0.001)) : si.smoo;

// mode fader
mode_fader(x) = hgroup("Modes", vslider("h:Basic_Parameters/mode_%x [%5x][tooltip: Mode %x] [style:knob]",1,0.5,1.5,0.001)) : si.smoo;
mode(x) = modes(preset,x)*(mode_fader(x));

//==================== SIGNAL PROCESSING ================

//----------------------- Nonlinear filter ----------------------------
//nonlinearities are created by the nonlinear passive allpass ladder filter declared in filter.lib

//nonlinear filter order
nlfOrder = 6; 

//nonLinearModultor is declared in instrument.lib, it adapts allpassnn from filter.lib 
//for using it with waveguide instruments
NLFM =  nonLinearModulator((nonLinearity : si.smoo),1,freq,typeModulation,(frequencyMod : si.smoo),nlfOrder);

//----------------------- Synthesis parameters computing and functions declaration ----------------------------

//the number of modes depends on the preset being used
nModes = 16; // nMode(preset);

//bow table parameters
tableOffset = 0;
tableSlope = 10 - (9*bowPressure);

delayLengthBase = (ma.SR/freq)*detune;

//delay lengths in number of samples
delayLength(x) = delayLengthBase/mode(x);

//delay lines
delayLine(x) = de.delay(4096,delayLength(x));

//Filter bank: bandpass filters (declared in instrument.lib)
radius = 1 - ma.PI*32/ma.SR;
bandPassFilter(x) = bandPass(freq*mode(x), radius);

//Delay lines feedback for bow table lookup control
baseGainApp = 0.8999999999999999 + (0.1*baseGain);
velocityInputApp = integrationConstant;
velocityInput = velocityInputApp + _*baseGainApp,par(i,(nModes-1),(_*baseGainApp)) :> +;

//Bow velocity is controled by an ADSR envelope
maxVelocity = 0.03 + 0.1;
bowVelocity = maxVelocity*en.adsr(a,d,90,0.01,gate);

//stereoizer is declared in instrument.lib and implement a stereo spacialisation in function of 
//the frequency period in number of samples 
stereo = stereoizer(delayLengthBase);

//----------------------- Algorithm implementation ----------------------------

//Bow table lookup (bow is decalred in instrument.lib)
bowing = bowVelocity - velocityInput <: *(bow(tableOffset,tableSlope)): /(nModes/2);

//One resonance
//resonance(x) = + : delayLine(x) : *(f_gain(x)/damping) : bandPassFilter(x);        // + (excitation(preset,x)*select) :

resonance(x) = + : bandPassFilter(x) : delayLine(x);
partial(x) = _ * (d_gain_fader(x)) : (resonance(x)~  * (f_gain(x)/damping));

process = (bowing*((select-1)*-1)+(_/nModes*select) <:
		  par(i,nModes,(partial(i))))~par(i,nModes,_) :> + : *(nModes) :
		  NLFM; // : stereo : instrReverb : fi.dcblockerat(60); *(nModes-(nModes-1)*select) :
		
/*
		//Bowed Excitation
		(bowing*((select-1)*-1) <:
		//nModes resonances with nModes feedbacks for bow table look-up 
		par(i,nModes,(resonance(i)~_)))~par(i,nModes,_) :> + : 
		//Signal Scaling and stereo
		*(4) : NLFM : stereo : instrReverb;
*/
