clear
clc
clf
close all

kback = zeros([1,9]);

% Averages values for overall heat transfer coefficient of the back wall of the oven across all nine runs
for masteri = 1:9
    clearvars -except masteri kback Uback

% Set up the Import Options and import the data
    opts = delimitedTextImportOptions("NumVariables", 71);
    
    % Specify range and delimiter
    opts.DataLines = [2, Inf];
    opts.Delimiter = ",";
    
    % Specify column names and types
    opts.VariableNames = ["VarName1", "P0", "P0Time", "P1", "P1Time", "P2", "P2Time", "T0", "T0Time", "T1", "T1Time", "T10", "T10Time", "T11", "T11Time", "T12", "T12Time", "T13", "T13Time", "T14", "T14Time", "T15", "T15Time", "T16", "T16Time", "T17", "T17Time", "T18", "T18Time", "T19", "T19Time", "T2", "T2Time", "T20", "T20Time", "T21", "T21Time", "T22", "T22Time", "T23", "T23Time", "T24", "T24Time", "T25", "T25Time", "T26", "T26Time", "T27", "T27Time", "T28", "T28Time", "T29", "T29Time", "T3", "T3Time", "T30", "T30Time", "T31", "T31Time", "T4", "T4Time", "T5", "T5Time", "T6", "T6Time", "T7", "T7Time", "T8", "T8Time", "T9", "T9Time"];
    opts.VariableTypes = ["double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double"];
    
    % Specify file level properties
    opts.ExtraColumnsRule = "ignore";
    opts.EmptyLineRule = "read";
    
    % Specify variable properties
    opts = setvaropts(opts, ["T10", "T11", "T12", "T13", "T14", "T15", "T17", "T18", "T19", "T20", "T21", "T22", "T23", "T24", "T25", "T26", "T27", "T28", "T29", "T30", "T31", "T8", "T9"], "TrimNonNumeric", true);
    opts = setvaropts(opts, ["T10", "T11", "T12", "T13", "T14", "T15", "T17", "T18", "T19", "T20", "T21", "T22", "T23", "T24", "T25", "T26", "T27", "T28", "T29", "T30", "T31", "T8", "T9"], "ThousandsSeparator", ",");

    runnumber = num2str(masteri);
    
    % Steady state timings 
    sststart = [3019.11,2995.53,3031.19,2873.32,2910.39,2717,3399.63,3524.82,3530.70];
    sstend = [3925.22,4047.23,4062.08,3980.12,4017.31,3817.14,4430.54,4552.79,4554.82];

    % Import the data
    datatable = readtable(strcat('H:\CET IIB RP\Data\','Run',runnumber,'.csv'), opts);
    dataarray = table2array(datatable);
    
    % Clear temporary variables
    clear opts

    % Format energy data and calculates power
    energy = dataarray(:,[3,2]);
    power = gradient(dataarray(:,2));

    % Format temperature data
    ovenoutT = dataarray(:,[11,10,33,32,55,54,61,60,63,62,65,64,67,66,69,68,71,70,13,12,15,14,17,16,19,18,21,20,23,22]);
    ovenoutT(all(isnan(ovenoutT),2),:) = [];
    ovenloc = cell(1,13);
    for i = 1:13
        ovenloc{:,i} = ovenoutT(:,[2*i-1,2*i]);
    end
    for i = 1:13
        holdovenloci = ovenloc{:,i};
        sststartindex = find(holdovenloci(:,1) > sststart(str2double(runnumber)),1,'first');
        sstendindex = find(holdovenloci(:,1) > sstend(str2double(runnumber)),1,'first') - 1;
        ssovenloc(:,i) = mean(holdovenloci(sststartindex:sstendindex,2));
    end

    % Index steady state period
    sststartindexp = find(energy(:,1) > sststart(str2double(runnumber)),1,'first');
    sstendindexp = find(energy(:,1) > sstend(str2double(runnumber)),1,'first') - 1;

    % Calculate input power
    sspower = (energy(sstendindexp,2)-energy(sststartindexp,2))*3600000./(sstend(str2double(runnumber))-sststart(str2double(runnumber)));

    % Solve for overall heat transfer coefficient of the back wall of the oven
    ovenwallw = [0.420,0.465,0.420,0.465,0.465,0.465];
    ovenwallh = [0.325,0.420,0.325,0.420,0.325,0.325];
    ovenwallarea = ovenwallw .* ovenwallh;
    ovenwallthickn = [0.030,0.040,0.030,0.065,0.100,0.025];

    d6in = 3.83*10^-3;
    d6mid = 17.02*10^-3;
    d6out = 3.86*10^-3;
    L = 0.325;
    kair = (0.00031417*(273.15+ssovenloc(7))^0.7786)/(1-0.7116/(273.15+ssovenloc(7)) + 2121.7/(273.15+ssovenloc(7))^2);
    g = 9.81;
    rhoair = 28.97*101325/(8.3145*10^3*(273.15+ssovenloc(7)));
    beta = 1/(273.15+ssovenloc(7));
    Pr = 0.71;
    nu = 1.46*10^-5;
    DeltaT = mean(ssovenloc([7,13])) - mean(ssovenloc([6,7]));
    kglass = 1.4;
    kwool = 0.1163;
    ksteel = 13.4;
    dsteel = 0.005;
    kother = ovenwallthickn(1:4)./(2*dsteel/ksteel + (ovenwallthickn(1:4)-2*dsteel)./kwool);

    Ra = L^3*g*rhoair^2*beta*Pr*DeltaT/nu^2;
    m = (L/d6mid)^0.45;
    Nu = (1 + (0.0605*Ra^0.33)^m)^(1/m);
    hgap = Nu*kair/d6mid;
    Ugap = 1/(d6in/kglass + 1/hgap + d6out/kglass);
    kgap = Ugap*(d6in+d6mid+d6out);

    syms kbackhold

    ovenwallk = [kother,kbackhold,kgap];
    tempin = ssovenloc(1:6);
    tempout = ssovenloc(8:13);
    heatflux = ovenwallarea .* ovenwallk .* (tempout-tempin) ./ ovenwallthickn;
    heat = sum(heatflux);

    eqn = sspower-heat == 0;

    kback(masteri) = eval(solve(eqn));
    Uback(masteri) = kback(masteri)./0.1;
end

% Saves value for overall heat transfer coefficient of the back wall of the oven
save(strcat('/Users/codykwok/Desktop/CET IIB RP/kback.mat'),'kback','kbackraw')