%
% read_window_chi.m
% CARL TAPE, 14-March-2008
% printed xxx
%
% This file reads in the output file from mt_measure_adj.f90.
%
% calls xxx
% called by compute_misfit.m
%

function [netwk,strec,cmp,iwin,iker,t1,t2,...
    chiMT_dT,chiMT_dA,chiCC_dT,chiCC_dA,...
    measMT_dT,measMT_dA,measCC_dT,measCC_dA,...
    sigmaMT_dT,sigmaMT_dA,sigmaCC_dT,sigmaCC_dA,...
    wind2,wins2,windiff2,windur,...
    recd2,recs2,recdiff2,recdur,...
    tr_chi,am_chi,T_pmax_dat,T_pmax_syn] = read_window_chi(filename)

[flab,sta,netwk,cmp,iwin,iker,t1,t2,...
    chiMT_dT,chiMT_dA,chiCC_dT,chiCC_dA,...
    measMT_dT,measMT_dA,measCC_dT,measCC_dA,...
    sigmaMT_dT,sigmaMT_dA,sigmaCC_dT,sigmaCC_dA,...
    wind2,wins2,windiff2,windur,...
    recd2,recs2,recdiff2,recdur,...
    tr_chi,am_chi,T_pmax_dat,T_pmax_syn] = ...
    textread(filename,'%s%s%s%s%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f');

for kk = 1:length(sta), strec{kk} = [sta{kk} '.' netwk{kk}]; end
strec = strec(:);

%======================================================
