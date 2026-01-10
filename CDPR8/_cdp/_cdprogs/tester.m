%Instrument file for trumpet
global temperature bore vpos vdl vbl custominstrument
custominstrument=0;
temperature=20;%temperature in C
%valve values, assumes that valve is constant cylinder where cross section
%in and out of valves is same as point on instrument
vpos=[600,630,690];%position of valve in mm
vdl=[20,20,20];%default tube length mm
vbl=[200,200,200];%bypass tube length mm (will add default length to either side of bypass tubes)
%bore in axial position (mm) and diameter(mm) pairs [x,d]
%bore=dlmread('SmithWatkinsTrumpet_KellyScrmouthpieceBORE.txt');
bore=[0,18;
38,5.1;
58,5.9;
4442.1,66.69;
4516.1,190;
];