clear
clc
clf
close all

for runnumber = 31:31 % Input run number between 31-39, can input multiple or individual runs
    
    clearvars -except runnumber DATA AVERAGEDATA
    
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
    
    runnumber = num2str(runnumber);
    
    batstart = [4219.84,4510.28,4205.13,4841.95,4560.52,4276.78,4601.68,4170.3,4172.41];
    batend = [11353.4,11679,11395.9,11948.6,11690.5,11421.5,11023.8,11159.4,11563.7];
    
    % Import the data
    datatable = readtable(strcat('H:\CET IIB RP\Data\','Run',runnumber,'.csv'), opts);
    dataarray = table2array(datatable);
    load('H:\CET IIB RP\kback.mat','kback')
    cuwater = [2.680-0.522,2.428-0.348,2.716-0.349,2.693-0.596,2.662-0.607,2.720-0.532,2.533-0.409,2.737-0.562,2.570-0.401];
    PCwaterstart = [0.600,0.550,0.500,0.500,0.450,0.380,0.600,0.600,0.600];
    PCwaterfinish = [0.176,0.121,0.069,0.193,0.144,0.055,0.086,0.051,0.048];
    
    % Clear temporary variables
    clear opts

    % Format energy data and calculates power
    energy = dataarray(:,[3,2]);
    power = gradient(dataarray(:,2));

    % Format temperature data
    roomtemp = dataarray(:,[9,8]);
    temperatures = dataarray(:,[11,10,33,32,55,54,61,60,63,62,65,64,67,66,69,68,71,70,13,12,15,14,17,16,19,18,21,20,23,22,25,24,27,26,29,28,31,30,35,34,37,36,39,38,41,40,43,42,45,44,47,46,49,48,51,50,53,52,57,56,59,58]);
    temperatures(all(isnan(temperatures),2),:) = [];
    ovenloc = cell(1,31);
    for i = 1:31
        ovenloc{:,i} = temperatures(:,[2*i-1,2*i]);
    end
    for i = 1:31
        holdovenloci = ovenloc{:,i};
        batstartindex = find(holdovenloci(:,1) > batstart(str2double(runnumber)-20),1,'first');
        batendindex = find(holdovenloci(:,1) > batend(str2double(runnumber)-20),1,'first') - 1;
        batovenloc(:,i) = mean(holdovenloci([batstartindex:batendindex],2));
    end
    for i = 1:31
        holdovenloci = ovenloc{i};
        batstartindex = find(holdovenloci(:,1) > batstart(str2double(runnumber)-20),1,'first');
        batendindex = find(holdovenloci(:,1) > batend(str2double(runnumber)-20),1,'first') - 1;
        cutovenloc{i} = holdovenloci([batstartindex:batendindex],:);
    end
    for i = 1:length(cutovenloc)
        holdlength(i) = length(cutovenloc{i});
    end
    holdlengthcutovenloc = min(holdlength);
    for i = 1:length(cutovenloc)
        holdcutovenloc = cutovenloc{i};
        cutovenloc{i} = holdcutovenloc(1:holdlengthcutovenloc,:);
    end
    
    % Index batch calculation period, Format energy and temperature data within this period
    batstartindex = find(roomtemp(:,1) > batstart(str2double(runnumber)-20),1,'first');
    batendindex = find(roomtemp(:,1) > batend(str2double(runnumber)-20),1,'first') - 1;
    batovenloc(:,32) = mean(roomtemp(batstartindex:batendindex,2));
    batstartindexp = find(energy(:,1) > batstart(str2double(runnumber)-20),1,'first');
    batendindexp = find(energy(:,1) > batend(str2double(runnumber)-20),1,'first') - 1;
    batpower = (energy(batendindexp,2)-energy(batstartindexp,2))*3600000./(batend(str2double(runnumber)-20)-batstart(str2double(runnumber)-20));
    batenergy = (energy(batendindexp,2)-energy(batstartindexp,2))*3600000;
    
    % Bubble flowmeter data
    time160 = mean([3.81 3.88 3.94 3.84 3.81 3.94 3.87 3.75 3.82 3.88]);
    time200 = mean([4.12 4.16 4.22 4.13 4.15 4.28 4.25 4.12 4.12 4.15]);
    time240 = mean([4.66 4.85 4.75 4.72 4.75 4.82 4.78 4.63 4.65 4.69]);
    bubdia = mean([20.20 20.17 20.34 20.33 20.37])*10^(-3);
    bublength = 1.550;
    airdensity = 101325/(287.05*(273.15+batovenloc(16)));
    
    % Bubble floweter flowrate allocation
    if str2double(runnumber) == 34||35||36
        massflowratehotair = airdensity*pi*bubdia^2/4 * bublength/time160; 
    elseif str2double(runnumber) == 31||32||33
        massflowratehotair = airdensity*pi*bubdia^2/4 * bublength/time200;
    elseif str2double(runnumber) == 37||38||39
        massflowratehotair = airdensity*pi*bubdia^2/4 * bublength/time240;
    else
    end
    
    runnumber = str2double(runnumber);
    
    % Calculate energy balance and discrepancies
    airoutenergy = batchotairout(cutovenloc,massflowratehotair);
    cuwaterenergy = heatsinkwater(cutovenloc,cuwater(runnumber-20));
    cuumaterialenergy = cumaterialheat(cutovenloc);
    ovencookingenergy = heatpseudochicken(cutovenloc,PCwaterstart(runnumber-20),PCwaterfinish(runnumber-20));
    heatlossovenouts = batheatlossoven(cutovenloc,kback);
    heatlosscuouts = batheatlosscu(cutovenloc);
    tubingloss = batheatlobatubing(cutovenloc);
    totalenergy = airoutenergy+cuwaterenergy+cuumaterialenergy+ovencookingenergy+heatlossovenouts+heatlosscuouts+tubingloss;
    discrepancy = (totalenergy-batenergy)/batenergy*100;
    efficiency = ovencookingenergy / totalenergy;
    extraefficiency = cuwaterenergy / totalenergy;
    totalefficiency = efficiency + extraefficiency;
    table(runnumber,batend(runnumber-20)-batstart(runnumber-20),batenergy,totalenergy,round(discrepancy,2),heatlossovenouts,tubingloss,heatlosscuouts+cuumaterialenergy,airoutenergy,ovencookingenergy,cuwaterenergy,'VariableNames',{'Runnumber','Elapsed Time (s)','Measured Energy (J)','Calculated Energy (J)','Energy Discrepancy (%)','Oven Loss (J)','Tubing Loss (J)','Cooler Unit Loss (J)','Air Out Loss (J)','Oven Cooking Energy (J)','Cooler Unit Recovered Energy (J)'})

end

% Function to calculate energy lost through oven
    function batheat = batheatlossoven(temps,kback)
    ovenwallw = [0.420,0.465,0.420,0.465,0.465,0.465];
    ovenwallh = [0.325,0.420,0.325,0.420,0.325,0.325];
    ovenwallarea = ovenwallw .* ovenwallh;
    ovenwallthickn = [0.030,0.040,0.030,0.065,0.100,0.025];
    
    d6in = 3.83*10^-3;
    d6mid = 17.02*10^-3;
    d6out = 3.86*10^-3;
    L = 0.325;
    datahold6 = temps{6};
    datahold6 = datahold6(all(~isnan(datahold6),2),:);
    temp6 = (datahold6(floor((1+end)/2),2));
    datahold7 = temps{7};
    datahold7 = datahold7(all(~isnan(datahold7),2),:);
    temp7 = (datahold7(floor((1+end)/2),2));
    datahold13 = temps{13};
    datahold13 = datahold13(all(~isnan(datahold13),2),:);
    temp13 = (datahold13(floor((1+end)/2),2));
    kair = (0.00031417*(273.15+temp7)^0.7786)/(1-0.7116/(273.15+temp7) + 2121.7/(273.15+temp7)^2);
    g = 9.81;
    rhoair = 28.97*101325/(8.3145*10^3*(273.15+temp7));
    beta = 1/(273.15+temp7);
    Pr = 0.71;
    nu = 1.46*10^-5;
    DeltaT = mean([temp7,temp13]) - mean([temp7,temp6]);
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
    
    ovenwallk = [kother,kback,kgap];
    
    for index = 1:6
        tempout = temps{index};
        tempin = temps{index+7};
        tempdiff = tempin(:,2)-tempout(:,2);
        timemean = mean([tempin(:,1),tempout(:,1)],2);
        datahold = [timemean,tempdiff];
        datahold = datahold(all(~isnan(datahold),2),:);
        tempdiffintegral(index) = trapz(datahold(:,1),datahold(:,2));
    end
    
    batheatflux = ovenwallarea .* ovenwallk .* tempdiffintegral ./ ovenwallthickn;
    batheat = sum(batheatflux);
end

% Function to calculate energy lost through cooler unit
function batheat = batheatlosscu(temps)
    cuwallw = [0.350,0.150,0.350,0.150,0.150,0.150];
    cuwallh = [0.075,0.350,0.075,0.350,0.075,0.075];
    cuwallarea = cuwallw .* cuwallh;
    cuinslationthickn = [0.035,0.01,0.035,0.01,0.15,0.01];
    cuinsulationk = 0.04;
    
    for index = 1:6
        tempout = temps{31};
        tempin = temps{index+20};
        tempdiff = tempin(:,2)-tempout(:,2);
        timemean = mean([tempin(:,1),tempout(:,1)],2);
        datahold = [timemean,tempdiff];
        datahold = datahold(all(~isnan(datahold),2),:);
        tempdiffintegral(index) = trapz(datahold(:,1),datahold(:,2));
    end
    
    batheatflux = cuwallarea .* cuinsulationk .* tempdiffintegral ./ cuinslationthickn;
    batheat = sum(batheatflux);
end

% Function to calculate energy lost through tubing
function batheat = batheatlobatubing(temps)
    tempoutlet = temps{15};
    tempmiddle = temps{19};
    tempinlet =  temps{17};
    tempout = temps{20};
    tempgrad = [trapz(tempoutlet(:,1),tempoutlet(:,2)-tempout(:,2)),trapz(tempmiddle(:,1),tempmiddle(:,2)-tempout(:,2)),trapz(tempinlet(:,1),tempinlet(:,2)-tempout(:,2))];
    tubingoverallheattranscoeff = 1.97530864211;
    tlength = [0,0.15,0.30];
    tdiameter = 0.02;
    batheat = pi*tdiameter*tubingoverallheattranscoeff*trapz(tlength,tempgrad);
end

% Function to calculate energy lost by air leaving cooler unit
function flowenergy = batchotairout(temps,massflowrate)
    datahold1 = temps{18};
    datahold1 = datahold1(all(~isnan(datahold1),2),:);
    datahold2 = temps{30};
    datahold2 = datahold2(all(~isnan(datahold2),2),:);
    datahold1 = datahold1(1:length(datahold2),:);
    Cpair = 1030.5-0.19975*(mean([datahold1(:,2),datahold2(:,2)],2)+273.15)+3.9734*10^(-4)*(mean([datahold1(:,2),datahold2(:,2)],2)+273.15).^2;
    flow = (Cpair.*(datahold1(:,2)-datahold2(:,2)))*massflowrate;
    flowenergy = trapz(mean([datahold1(:,1),datahold2(:,1)],2),flow);
end

% Function to calculate energy recovered by water cooler unit
function cuwaterenergy = heatsinkwater(temps,Masswater)
    datahold = temps{27}(:,2);
    datahold = datahold(all(~isnan(datahold),2),:);
    Cpwater = 4.1570*10^3;
    cuwaterenergy = Masswater * Cpwater * (datahold(end)-datahold(1));
end

% Function to calculate energy used to cook pseudo chicken
function cookingenergy = heatpseudochicken(temps,massstart,massfinish)
    Cpwater = 3.9626*10^3;
    Latentwater = 2256.4*10^3;
    masspyrex = 1.429;
    Cppyrex = 753;
    temp1 = temps{28};
    temp1 = temp1(all(~isnan(temp1),2),:);
    temp2 = temps{29};
    temp2 = temp2(all(~isnan(temp2),2),:);
    heating1 = massstart*Cpwater*(100-temp1(1,2));
    heating2 = (massstart-massfinish)*Latentwater;
    heating3 = masspyrex*Cppyrex*(temp2(end,2)-temp2(1,2));
    cookingenergy = heating1 + heating2 + heating3;
end

% Function to calculate energy used to heat up cooler unit
function heatcu = cumaterialheat(temps)
    for index = [1,3,4,5,6]
        Altemphold = temps{index+20};
        Altemp(index) = Altemphold(end,2);
    end
    temphold = temps{31};
    temphold = temphold(floor((1+end)/2),2);
    McuAldata = [798.02,797.86,798.13,797.70,797.95];
    McuAl = mean(McuAldata)/1000;
    CpAl = 900;
    Alheat = McuAl*CpAl*(mean(Altemp)-temphold);
    Mcunydata = [490.09,490.08,490.07,490.08,490.06];
    Mcuny = mean(Mcunydata)/1000;
    Cpny = 1.67;
    Cutemphold = temps{22};
    nyheat = Mcuny*Cpny*(Cutemphold(end,2)-temphold);
    heatcu = Alheat+nyheat;
end