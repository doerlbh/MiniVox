% Author: Baihan Lin (doerlbh@gmail.com)
% Date: Jan 2020

clear all; close all; clc

addpath matlab
addpath mfcc
run vl_setupnn
run vl_compilenn

rng(666)

% the feature is MFCC if useNN is set to 0, a VGG embedding if set to 1.
opts.useNN = 1;

% the number of speakers appearing in an online learning scenario.
opts.nOptions = 5;

% the episodicality of the reward: the frequency of feedback revealing.
opts.epiReward = 0.1;

% the full length of separate segments of individual talking.
opts.nPiece = 10;

% if the full participants are given, set it to 1; else 0.
opts.oracle = 0;

% set data path information.
opts.modelPath = '' ;
opts.dataDir = './data'; 

% you can easily generate a data stream given these configs. 
data = minivox(opts);

% or if you want to sparsify reward feedback later.
[data,opts] = sparsefeedback(data,opts,0.01);

% evaluate models
res_a = berlinucbkmeans(data,opts);
res_b = berlinucbknn(data,opts);
res_c = berlinucbgmm(data,opts);
res_d = linucb(data,opts);
res_e = kmeansclf(data,opts);
res_f = knnclf(data,opts);
res_g = gmmclf(data,opts);
res_h = randagent(data,opts);
res_i = berlinucb(data,opts);

