%% Author: Francesco
%% Created: May 27, 2009
%% Description: TODO: Add description to man
-module(win_man).

%%
%% Include files
%%

%%
%% Exported Functions
%%
-export([win_man_life/3	  
		]).

%%
%% API Functions
%%


%%%%%%%%%%% win_man_life( PARENT, CHILDREN, NODES, NUM_N, NUM_C, DEPTH, INPUT, ERROR_TREE_ROOT)
%% param:
%%      PARENT: Father's PID
%%      CHILDREN : a list containing the subtree's PIDs
%%	NODES : a list containing the nodes' PIDs handled by this manager
%%
%% receives:
%%	+ {new_input, PARENT, INPUT }	
%%		-returns the max error in the subtree
%%	+ tree updates: {new_input, PARENT, INPUT } or { update_add_manager, NEWMAN }
%%		- performs the tree updates	
%% sends:
%%      	- PARENT ! { my_win_and_run , self (), WIN_AND_RUN }
%%       
%%		- ERROR_TREE_ROOT ! { my_win_and_run , self (), WIN_AND_RUN }
%%
%% Sends distance request to all the nodes in NODES and asks for the sub_winner and sub_runner to the subtrees in CHILDREN
%% Combines all and sends a message to the father comunicating his winner and runner. 

	
win_man_life( PARENT, CHILDREN, NODES)->
	
	receive

		{ update_add_node, NEW_NODE } ->  %% form root to root
			win_man_life(PARENT, CHILDREN, lists:append(NODES,NEW_NODE));
		

		{ update_add_manager, NEWMAN } ->

			io:format("~p I add a manager ! ~w ~n:",[self(), CHILDREN]),
			

			NEW_CHILDREN= lists:append(CHILDREN, NEWMAN),

			io:format("~p manager added ! ~w ~n:",[self(), NEW_CHILDREN]),
			
			win_man_life(PARENT, NEW_CHILDREN, NODES);
		
		{ update_add_nodes_pack, NODES_PACK } ->
			io:format("~p I add a nodes pack ! ~w ~n:",[self(), NODES_PACK]),
			win_man_life(PARENT, CHILDREN, NODES_PACK );
		
		%% 		
		{new_input, PARENT, INPUT } ->

			io:format("~p Received New Input ~w:~n",[self(), INPUT]),
	
			ask_for_min(CHILDREN, self(), INPUT),  %% the same function, but we can't unify the lists 

			ask_for_min(NODES, self(), INPUT),

        
        		%% MAX is a tuple { { MAX_DISTANCE_NODE_PID , DISTANCE },{ SECOND_NODE_PID , DISTANCE } }
			%% TODO maybe i should call compute_winner(NUM_N) and then a subfuntion adds the inital phoonies {0.0},{0.0} 
        		WIN_AND_RUN = compute_winner(length(NODES)),

			COMPARED_WIN_AND_RUN = compare_winners(length(CHILDREN), element(1,WIN_AND_RUN), element(2,WIN_AND_RUN)),

			%% TODO now, if is not the root, i should comunicate with the father otherwize i should comunicate with the other tree, the error tree to comunicate the Winner and the runner to modify () 

			PARENT ! { my_win_and_run , self (), COMPARED_WIN_AND_RUN },

			io:format("~p Return  to my parent ~w the winner and runner,~w my nodes:  ~w:~n",[self(), PARENT,COMPARED_WIN_AND_RUN,NODES]),
	
		
			win_man_life( PARENT, CHILDREN, NODES)
	
	end
.


%%%%%%%%%%%%%%% ask_for_min(NODESLIST, RETURN_PID, INPUT) %%%%%%%%%%%%%%
%% 	- sends recursively a message {request_distance, RETURN_PID, INPUT} to every emelement of NODES (a node's PID List)

ask_for_min([], _RETURN_PID, _INPUT) ->
	ok;

ask_for_min([ HEAD | TAIL ], RETURN_PID, INPUT)->	
	HEAD ! {request_distance, RETURN_PID,INPUT},
	ask_for_min( TAIL , RETURN_PID, INPUT)
.

%%%%%%% compute_max(NODES_REMAINING, TEMP_WIN, TEMP_RUN)%%%%%%%%%%%%%%%%
%%	params:
%%		NODES_REMAINING is the number on nodes/messages to receive
%%		TEMP_WIN is a tuple { WINNER_NODE_PID , DISTANCE } storing the temporary best
%%		TEMP_RUN is a tuple { RUNNER_NODE_PID , DISTANCE } storing the temporary runner
%%
%%	returns: a tuple { { WINNER_NODE_PID , DISTANCE },{ RUNNER_NODE_PID , DISTANCE } }
%%     
%%	receives: 
%%		 + recursively the distances from all the NODES_REMAINING nodes in the form {my_distance, NODE_PID, DISTANCE}
%%		 	- updates the temporary winner and runner 
%%     

compute_winner(NUM_N) -> 
		compute_winner(NUM_N,{0,0},{0,0}).

compute_winner(0 , TEMP_WIN, TEMP_RUN) -> 
		{TEMP_WIN, TEMP_RUN}; 
compute_winner(NODES_REMAINING, TEMP_WIN, TEMP_RUN)->

	receive 
		{my_distance, NODE_PID, DISTANCE} ->
			DISTANCE_TEMP_WIN = element(2, TEMP_WIN),
			if   
				DISTANCE_TEMP_WIN > DISTANCE ->
					%% if is near enough to be the winner
					NEW_RUN = TEMP_WIN,				
					NEW_WIN = {NODE_PID , DISTANCE},
					compute_winner(NODES_REMAINING - 1, NEW_WIN, NEW_RUN);
				
				true ->  
					%% maybe can still compete for the runner
					DISTANCE_TEMP_RUN = element(2, TEMP_RUN),
					if
						DISTANCE_TEMP_RUN > DISTANCE ->
					
							NEW_RUN = {NODE_PID , DISTANCE},
							compute_winner(NODES_REMAINING - 1, TEMP_WIN, NEW_RUN)
				        end
			end
	end
.

%%%%%%% compare_winners (CHILDREN_REMAINING, TEMP_WIN, TEMP_RUN)%%%%%%%%%%%%%%%%
%%	params:
%%		CHILDREN_REMAINING is the number on nodes/messages to receive
%%		TEMP_WIN is a tuple { WINNER_NODE_PID , DISTANCE } storing the temporary best
%%		TEMP_RUN is a tuple { RUNNER_NODE_PID , DISTANCE } storing the temporary runner
%%
%%	returns: a tuple { { WINNER_NODE_PID , DISTANCE },{ RUNNER_NODE_PID , DISTANCE } }
%%     
%%	receives: 
%%		 + recursively from all childrens (subtree) tuples in the form { { WINNER_NODE_PID , DISTANCE },{ RUNNER_NODE_PID , DISTANCE } }
%%		 	- updates the temporary winner and runner 
%%  
                 
compare_winners(0 , TEMP_WIN, TEMP_RUN) -> 
		{TEMP_WIN, TEMP_RUN}; 

compare_winners (SUBTREES_REMAINING, TEMP_WIN, TEMP_RUN)->

	receive 
		{my_win_and_run, _MAN_PID, WIN_AND_RUN} ->
			SUB_TEMP_WIN_DIST = element(2, element(1, WIN_AND_RUN)),
			SUB_TEMP_RUN_DIST = element(2, element(2, WIN_AND_RUN)),
					
			if   
				SUB_TEMP_WIN_DIST < TEMP_WIN ->
										
					NEW_RUN = TEMP_WIN,				
					NEW_WIN = element(1, WIN_AND_RUN),
					if 
						SUB_TEMP_RUN_DIST < TEMP_RUN ->
							compare_winners(SUBTREES_REMAINING -1, NEW_WIN, element(2, WIN_AND_RUN));
						true ->
							compare_winners(SUBTREES_REMAINING-1, NEW_WIN,NEW_RUN)
					end;
				true->
				
					if
						SUB_TEMP_WIN_DIST< element(2,TEMP_RUN) ->
							NEW_RUN=SUB_TEMP_WIN_DIST,
							compare_winners(SUBTREES_REMAINING - 1, TEMP_WIN, NEW_RUN)	
					end
			end
	end			
.








