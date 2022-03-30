clear
clc

% Bubble flowmeter data
time160 = [3.81 3.88 3.94 3.84 3.81 3.94 3.87 3.75 3.82 3.88];
time200 = [4.12 4.16 4.22 4.13 4.15 4.28 4.25 4.12 4.12 4.15];
time240 = [4.66 4.85 4.75 4.72 4.75 4.82 4.78 4.63 4.65 4.69];
bubdia = mean([20.20 20.17 20.34 20.33 20.37])*10^(-3);
bublength = 1.550;

% Mass flowrate calculation for Tsp = 160degC
massflowrate160data = 1.225*pi*bubdia^2/4 * bublength./time160;
massflowrate160 = mean(massflowrate160data);
massflowrate160std = std(massflowrate160data);
speed160 = massflowrate160data/(pi*0.01^2*1.29);

% Mass flowrate calculation for Tsp = 200degC
massflowrate200data = 1.225*pi*bubdia^2/4 * bublength./time200;
massflowrate200 = mean(massflowrate200data);
massflowrate200std = std(massflowrate200data);
speed200 = massflowrate200data/(pi*0.01^2*1.29);

% Mass flowrate calculation for Tsp = 240degC
massflowrate240data = 1.225*pi*bubdia^2/4 * bublength./time240;
massflowrate240 = mean(massflowrate240data);
massflowrate240std = std(massflowrate240data);
speed240 = massflowrate240data/(pi*0.01^2*1.29);