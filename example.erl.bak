%% Author: nils
%% Created: May 27, 2009
%% Description: TODO: Add description to node
-module(example).

%%
%% Include files
%%

%%
%% Exported Functions
%%
-export([man_life/1, node_life/1, start/0]).

%%
%% API Functions
%%

node_life(POSITION) ->
    receive
      {position_request, MAN_ADDR} ->
	  io:format(" I'm sending my position: ~p to ~p ~n",
		    [POSITION, MAN_ADDR]),
	  MAN_ADDR !
	    {my_pos, self(),
	     POSITION}    %%  this corresponds to a method > position_t givemeposition()
    end,
    node_life(POSITION).

man_life(NODEPID) ->
    NODEPID ! {position_request, self()},
    receive
      %% I use other name, they are LOCAL variables, the exist just from a arrow to a comma !
      {my_pos, NPID, POS} ->
	  io:format(" Node ~p`s position: ~p  ~n", [NPID, POS])
    end.

start() ->
    NEWNODE = spawn(node, node_life, [4]),
    NEWMAN = spawn(node, man_life, [NEWNODE]).

%%
%% Local Functions
%%

