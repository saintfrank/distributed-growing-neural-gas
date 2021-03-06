%% Author: Francesco
%% Created: May 27, 2009
%% Description: TODO: Add description to man
-module(max_man).

%%
%% Include files
%%

%%
%% Exported Functions
%%
-export([max_man_life/7]).

%%
%% API Functions
%%

max_man_life(PARENT, CHILDREN, NODES, NUM_N, NUM_C,
	     DEPTH, INPUT) ->
    ask_for_min(CHILDREN, self(),
		INPUT),  %% the same function, but we can't unify the lists
    ask_for_min(NODES, self(), INPUT),
    %% NUM_ANSWERS_ARRIVING is a number that tell how many distances to wait
    NUM_ANSWERS_ARRIVING = NUM_N + NUM_C,
    %% MAX is a tuple { { MAX_DISTANCE_NODE_PID , DISTANCE },{ SECOND_NODE_PID , DISTANCE } }
    %% TODO maybe i should call compute_max(NUM_ANSWERS_ARRIVING) and then a subfuntion adds the inital phoonies {0.0},{0.0}
    MAX_AND_SECOND = compute_max(NUM_ANSWERS_ARRIVING,
				 {0, 0}, {0, 0}),
    PARENT ! {my_max_and_second, self(), MAX_AND_SECOND},
    %%TODO
    %% HERE the tree updates from the Tree/Error manager
    %% receive
    %%      {update_.....}
    %%
    receive
      {new_input, PARENT, PATTERN} ->
	  max_man_life(PARENT, CHILDREN, NODES, NUM_N, NUM_C,
		       DEPTH, PATTERN)
    end.

%% 	- sends recursively a message {request_distance, RETURN_PID, INPUT} to every emelement of NODES (a node's PID List)
ask_for_min([], _RETURN_PID, _INPUT) -> ok;
ask_for_min([HEAD | TAIL], RETURN_PID, INPUT) ->
    HEAD ! {request_distance, RETURN_PID, INPUT},
    ask_for_min(TAIL, RETURN_PID, INPUT).

%%	returns a tuple { { MAX_DISTANCE_NODE_PID , DISTANCE },{ SECOND_NODE_PID , DISTANCE } }
%% 	+ receives recursively the distances from all the NODES_REMAINING nodes
%%	

compute_max(0, TEMP_MAX, TEMP_SECOND) ->
    {TEMP_MAX, TEMP_SECOND};
compute_max(NODES_REMAINING, TEMP_MAX, TEMP_SECOND) ->
    receive
      {my_distance, NODE_PID, DISTANCE} ->
	  DISTANCE_TEMP_MAX = element(2, TEMP_MAX),
	  if DISTANCE_TEMP_MAX > DISTANCE ->
		 %% if is near enough to be the winner
		 TEMP_SECOND = TEMP_MAX,
		 NEW_MAX = {NODE_PID, DISTANCE},
		 compute_max(NODES_REMAINING - 1, NEW_MAX, TEMP_SECOND);
	     true ->
		 %% maybe can still compete for the runner
		 DISTANCE_TEMP_SECOND = element(2, TEMP_SECOND),
		 if DISTANCE_TEMP_SECOND > DISTANCE ->
			NEW_SECOND = {NODE_PID, DISTANCE},
			compute_max(NODES_REMAINING - 1, TEMP_MAX, NEW_SECOND)
		 end
	  end
    end.
