%%% TSE2018 - SDDP paper
clc ; close all ; clear;
addpath(genpath('./Fast/src')); % add fast src to your matlab path
tic

%% read static data into tables

% read converntional generator data
GeneratorConv = readtable('GeneratorsConv.csv');
% take care of NaN value in the table
GeneratorConv.hr2(isnan(GeneratorConv.hr2))=0;
GeneratorConv.hr3(isnan(GeneratorConv.hr3))=0;
GeneratorConv.f2(isnan(GeneratorConv.f2))=0;
GeneratorConv.f3(isnan(GeneratorConv.f3))=0;

% read renewable generator data
GeneratorPS = readtable('GeneratorsPS.csv'); % pumped storage
GeneratorWS = readtable('GeneratorsWindAndSolar.csv'); % wind and solar

% read system data
Loads = readtable('Loads.csv');
Bus = readtable('Bus.csv');
Lines = readtable('Lines.csv');

% the horizon is from 4 to 93
H = 90 ; % Horizon
%global common_cstr          % to avoid building commmon constraints for several scenarios at a given time stage
%common_cstr = cell(1,H);
G = size(GeneratorConv,1);  % number of conventional generators that committed
Gps = size(GeneratorPS,1);  % number of pumped storage
Gws = size(GeneratorWS,1);  % number of wind and solar generators
nBus = size(Bus,1);         % number of buses
nLines = size(Lines,1);     % number of lines
Production = csvread('Production.csv', 1, 4, [1,4,G,93]);   % production from day-ahead market

UC=ones(G,H);
global runningForwardPass;
%runningForwardPass =0;
%% SDDP
% Creating a simple 96 stages lattice with 10 nodes from second stage
lattice = Lattice.latticeEasy(H, 10, @ErrorDisturbance) ;

disp('Running WS...');

params = sddpSettings('algo.McCount',50, ...
    'stop.iterationMax',10,...
    'algo.purgeCutsNumber', 100,...
    'log.useDiary', true,...
    'log.saveTempResults', false,...
    'stop.stopWhen','never',...
    'verbose',1,...
    'stop.pereiraCoef',0.1,...
    'solver','gurobi') ;

var.s = sddpVar(Gps,H) ;        % storage of pumped storage
var.p_pump = sddpVar(Gps,H) ;   % power pumped to pumped storage
var.p_prod = sddpVar(Gps,H) ;   % power produced by pumped storage

var.p = sddpVar(G, H) ;         % Production of conv generators
var.c = sddpVar(G, H) ;         % cost of conv generators at the coresponding production level
var.ls = sddpVar(nBus, H) ;     % load shedding at each bus
var.psh = sddpVar(nBus, H) ;    % production shedding at each bus

var.redispatchC = sddpVar(H);%

var.flow = sddpVar(nLines, H);  % power flow at each line
var.angle = sddpVar(nBus, H) ;  % angle at each bus
var.e = sddpVar(H);             %forecast error

lattice = compileLattice(lattice,@(scenario)nldsAR(scenario,var,GeneratorConv,GeneratorPS,GeneratorWS,Loads,Bus,Lines,UC),params) ;
latticeComplied = lattice;  % store the complied lattice

toc

disp('Generating Output...');

%% Forward passes
nForward = 100 ;
objVec = zeros(nForward,1);

s = zeros(Gps,H,nForward);
p_pump = zeros(Gps,H,nForward);
p_prod = zeros(Gps,H,nForward);

p = zeros(G,H,nForward);
c = zeros(G,H,nForward);

ls = zeros(nBus,H,nForward);
psh = zeros(nBus,H,nForward);

redispatchC = zeros(H,nForward);

flow = zeros(nLines,H,nForward);

e = zeros(nForward,H);

sResidual = zeros(Gps,nForward);

%loadsheddingCost = zeros(nForward,1);
redispatchCost = zeros(nForward,1);
loadshedding = zeros(nForward,1);
productionshedding = zeros(nForward,1);

totalGasSupply = zeros(nForward,1);
fuelCost = zeros(nForward,1);
totalCost = zeros(nForward,1);
totalResidual = zeros(nForward,1);%ernergy left in pumped storage
%myPath = zeros(nForward,H); %creat my own random path to record scnerio


solutionRecord = cell(nForward,1);

load 'myPath96.mat';
runningForwardPass = 0;
for  i = 1:nForward
%     if i>1
%         runningForwardPass = 1;
%     end
    i
    %myPath(i,:) =  [1, randi(10,[1,H-1])];
    %myPath(i,:) =  [1, 10*ones(1,H-1)]; %worest case
    %myPath(i,:) =  [1, ones(1,H-1)]; %best case
    [objVec(i),~,solution] = waitAndSee(latticeComplied,myPath(i,1:H) ,params) ;
    %record solution of every forewardpass
    solutionRecord{i} = solution;
    s(:,:,i) = lattice.getPrimalSolution(var.s, solution) ;
    p_pump(:,:,i) = lattice.getPrimalSolution(var.p_pump, solution) ;
    p_prod(:,:,i) = lattice.getPrimalSolution(var.p_prod, solution) ;
    
    p(:,:,i) = lattice.getPrimalSolution(var.p , solution);
    c(:,:,i) = lattice.getPrimalSolution(var.c , solution);
    
    ls(:,:,i) = lattice.getPrimalSolution(var.ls , solution) ;
    psh(:,:,i) = lattice.getPrimalSolution(var.psh , solution) ;
    
    redispatchC(:,i) = lattice.getPrimalSolution(var.redispatchC , solution) ;
    
    flow(:,:,i) = lattice.getPrimalSolution(var.flow , solution) ;
    
    e (i,:) = lattice.getPrimalSolution(var.e , solution) ;
       
    
    loadshedding(i) = sum(sum(ls(:,:,i) ));
    productionshedding(i) = sum(sum(psh(:,:,i) ));
    
    %get the costs
    

    
    redispatchCost(i) = sum(redispatchC(:,i));
    totalGasSupply(i) =sum(sum(p(:,:,i)));
    fuelCost(i) = sum(sum(c(:,:,i) ));
    

    
    totalCost(i) = redispatchCost(i) + fuelCost(i) ;
    
    sResidual(:,i) = s(:,H,i);
    totalResidual(i) = sum(sResidual(:,i)); 
end



loadshedding = loadshedding/4;
loadsheddingAverge = mean(loadshedding);
loadsheddingSTD = std(loadshedding)/nForward^0.5;

productionshedding = productionshedding/4;
productionsheddingAverge = mean(productionshedding);
productionsheddingSTD = std(productionshedding)/nForward^0.5;



redispatchCost = redispatchCost/4;
redispatchCosttAverge = mean(redispatchCost);
redispatchCostSTD = std(redispatchCost)/nForward^0.5;

fuelCost= fuelCost/4;
fuelCostAverage = mean(fuelCost);
fuelCostSTD = std(fuelCost)/nForward^0.5;

totalCost = totalCost/4;
totalCostAverage = mean( totalCost);
totalCostSTD = std( totalCost)/nForward^0.5;

sResidualAverage = mean( totalResidual);
sResidualSTD = std( totalResidual)/nForward^0.5;


totalGasSupply = totalGasSupply/4;


toc



disp('Saving...');

save('transmission_WS') ;
disp('All Done.');


