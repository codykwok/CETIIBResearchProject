clear
clc
clf
close all

% Evporation rate data
time = [0,20,40,60,80];
fmass = [200,1595-1429,1540-1429,1485-1429,0];

% Graph plot
plot(time,fmass,'kx','MarkerSize',10)
xlabel('Time (min)')
ylabel('Mass of Water (g)')
interpolyfit1 = polyfit(time(1:5),fmass(1:5),5);
interpolyfit2 = polyfit(time(2:5),fmass(2:5),1);
hold on
plot(0:0.01:20,[200*ones(1,778), polyval(interpolyfit2,7.775768535:0.01:20)],'k-.')
plot(0:20,polyval(interpolyfit1,0:20),'k--')
plot(20:80,polyval(interpolyfit2,20:80),'k-')
text(72,207.5,'200 g','Color','k')
yline(200,'k:')
ylim([0 225])
corrcoef(time(2:5),fmass(2:5))
legend({'Data','Linear Rate','Theorised Rate'},'location','southwest','EdgeColor','White')