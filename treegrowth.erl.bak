%% Author: nils
%% Created: May 30, 2009
%% Description: TODO: Add description to treegrowth
-module(treegrowth).

%%
%% Include files
%%

%%
%% Exported Functions
%%
-export([getDirections/3]).

%%
%% API Functions
%%

%%%%% getDirections(C, M, N)
%param:
% C: number of nodes including new one
% M: Max number of Manager per Manager
% N: Max number of Nodes per Manager
% returns a list, which indicates the path
%    to the manager where the new node should be addd
getDirections(C, M, N) -> whichDepth(C, 0, M, N).

%% Local Functions

whichDepth(C, I, M, N) ->
    TMP = C - math:pow(M, I) * N,
    if TMP < 0 ->
	   io:format("DEPTH is ~p~n", [I]),
	   whichManager(C, 0, I, M, N, []);
       true -> whichDepth(TMP, I + 1, M, N)
    end.

whichManager(C, K, DEPTH, M, N, DIRECTIONS) ->
    if K - DEPTH == 0 -> DIRECTIONS;
       true ->
	   TMP = trunc(C) div
		   trunc(math:pow(M, DEPTH - 1 - K) * N),
	   whichManager(C - TMP, K + 1, DEPTH, M, N,
			lists:append([DIRECTIONS, [TMP]]))
    end.
