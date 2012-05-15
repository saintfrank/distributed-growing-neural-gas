%% Author: Francesco
%% Created: May 27, 2009
%% Description: TODO: Add description to man
-module(err_man).

%%
%% Include files
%%

%%
%% Exported Functions
%%
-export([err_man_life/5	  
		]).

%%
%% API Functions
%%


%%%%%%%%%%% err_man_life( PARENT, CHILDREN, NODES, NUM_N, NUM_C, DEPTH, INPUT, ERROR_TREE_ROOT, TWIN)
%% param:
%%      PARENT: Father's PID
%%      CHILDREN : a list containing the subtree's PIDs
%%	NODES : a list containing the nodes' PIDs handled by this manager
%%	DEPTH : the depth in the tree
%%	TWIN : is the associate manager in the winner tree
%% receives:
%%	+ {decrease_error, PARENT ,ALPHA}
%%		- comunicates to decrease error of a factor ALPHA to all the subtree	
%% sends:      
%%		- PARENT ! { my_error , self (), MAX }
%%      
%%
%% Sends distance request to all the nodes in NODES and asks for the sub_winner and sub_runner to the subtrees in CHILDREN
%% Combines all and sends a message to the father comunicating his winner and runner. 

	
err_man_life( PARENT, CHILDREN, NODES, DEPTH,  TWIN)->
	
	receive 
		{set_twin, NEW_TWIN} ->
			err_man_life (PARENT, CHILDREN, NODES, DEPTH,  NEW_TWIN);
		
		{ removeNode, NodePID } -> 
			io:format("E_M ~p ERR:I received Remove Node :~p~n",[self(),NodePID]),
			TWIN ! {removeNode, NodePID},
			err_man_life( PARENT, CHILDREN, lists:delete(NodePID, NODES), DEPTH,  TWIN);


		{ addNode, NEW_NODE } -> %% this is received just form the tree
			io:format("E_M Received add_node~n "),
			
			NEW_NODES_LIST = lists:append(NODES, [NEW_NODE]),%%TODO i've to remember to call the function with this NEW_NODES_LIST
			TWIN ! {update_add_node, NEW_NODE},
			io:format("E_M ~p Received add_node , i've told my twin ~p , my nodes :~w~n",[self(), TWIN,NEW_NODES_LIST]),
			err_man_life( PARENT, CHILDREN, NEW_NODES_LIST, DEPTH,  TWIN);  %%TODO i've to add this in the win_man
 		
		{decrease_error, PARENT ,ALPHA} ->
			io:format("E_M ~p Received decrease_error, i'll tell everyone:~n",[self()]),
			tell_everyone(CHILDREN, { decrease_Error, self(), ALPHA } ),
			tell_everyone(NODES, { decrease_error, self(),ALPHA }),
			err_man_life( PARENT, CHILDREN, NODES, DEPTH,  TWIN);

		{request_decreased_error, PARENT,ALPHA} ->	

			io:format("E_M ~p Received request_decreased_error, i begin calculate the max:~n",[self() ]),
	
			tell_everyone(CHILDREN, {request_decreased_error, self(), ALPHA}),  %% the same function, but we can't unify the lists 

			tell_everyone(NODES, {request_decreased_error, self(), ALPHA}),
			
			io:format("E_M ~p I asked about the error. My Nodes: ~w My CHildren: ~w:~n",[self(), NODES, CHILDREN ]),
		
        		%% NUM_ANSWERS_ARRIVING is a number that tell how many distances to wait
        		NUM_ANSWERS_ARRIVING= length(NODES) + length(CHILDREN),
			io:format("E_M ~p Waits : ~p~n",[self(), NUM_ANSWERS_ARRIVING]),
	
        		%% MAX is a tuple { {NODE, ERROR} }
			%% TODO maybe i should call compute_max(NUM_ANSWERS_ARRIVING) and then a subfuntion adds the inital phoonies {0.0},{0.0} 
        		MAX = compute_max(NUM_ANSWERS_ARRIVING),
			
			io:format("E_M ~p My error: ~w~n",[self(), MAX]),
	
        		PARENT ! { my_error , self (), MAX},
			err_man_life( PARENT, CHILDREN, NODES, DEPTH,  TWIN);
						
		
		{ move_nodes_start, NEW_NODE, DIRECTIONS} ->
			
			L_DIR = length(DIRECTIONS),
			[ NEXT_D | OTHER_DIRECTIONS] = DIRECTIONS,
			
			NODES_PACKAGE = lists:append(NODES, [NEW_NODE]),
			io:format("E_M ~p Received move_node_start, i'll pass :~w~n",[self(), NODES_PACKAGE]),
			NEW_NODES_LIST = [],
			TWIN ! {reset_nodes_list},    %% TODO tell the twin the news !
			
			if 
				L_DIR == 1 ->	%%  TODO adds a new manager
					NEW_CHILDREN_LIST = lists:append ( CHILDREN, [add_manager(DEPTH + 1 ,TWIN)] );
				true ->
					NEW_CHILDREN_LIST = CHILDREN
					
			end,

			%%spreads the messages down the tree
			lists:nth(NEXT_D, CHILDREN) ! {move_nodes, NODES_PACKAGE, OTHER_DIRECTIONS},
			err_man_life( PARENT, NEW_CHILDREN_LIST , NEW_NODES_LIST, DEPTH,  TWIN); 

		{move_nodes, NODES_PACK, DIRECTIONS}->   %% By-passing manager 
			io:format("E_M ~p Received move_node, i'll pass :~w~n",[self(), NODES_PACK]),
											
			L_DIR = length(DIRECTIONS),
			[ NEXT_D | OTHER_DIRECTIONS] = DIRECTIONS,
			
			
			case  L_DIR of %% check how long is the directions list

				1 ->	%% if is 1 adds a new manager	
					NEW_NODES_LIST=NODES,					
					NEW_CHILDREN_LIST = lists:append( CHILDREN, [add_manager(DEPTH + 1 ,TWIN)] ),
					lists:nth(NEXT_D, CHILDREN) ! {move_nodes, NODES_PACK, OTHER_DIRECTIONS};
					
				0 ->	%% if is zero adds the nodes package to his NODES list
					NEW_CHILDREN_LIST=CHILDREN,
					NEW_NODES_LIST = NODES_PACK,
					tell_everyone(NEW_NODES_LIST, {set_parent, self()}),
					TWIN ! {update_add_nodes_pack, NODES_PACK}	
								
			end,
			
			err_man_life( PARENT, NEW_CHILDREN_LIST , NEW_NODES_LIST,  DEPTH, TWIN)
	
	end
		
.
%%%%%%%%%%%%%%% ask_for_min(NODESLIST, RETURN_PID, INPUT) %%%%%%%%%%%%%%
%% 	- sends recursively a message {request_distance, RETURN_PID, INPUT} to every emelement of NODES (a node's PID List)

tell_everyone([], _MESSAGE) ->
	ok;

tell_everyone([ HEAD | TAIL ], MESSAGE)->	
	HEAD ! MESSAGE,
	tell_everyone( TAIL , MESSAGE)
.



%%%%%%% compute_max(NODES_REMAINING, TEMP_WIN, TEMP_RUN)%%%%%%%%%%%%%%%%
%%
%%	In this case the node's max and the runner's max can be computed in the same way, receiving the same message 
%%
%%	params:
%%		NODES_REMAINING is the number on nodes/messages to receive
%%		TEMP_MAX is a tuple { MAX_ERR_NODE_PID , ERROR } storing the temporary best
%%		
%%
%%	returns: a tuple { MAX_ERR_NODE_PID , ERROR} }
%%     
%%	receives: 
%%		 + recursively the error from all the NODES_REMAINING nodes in the form {my_error, self(), ERROR }
%%		 	- updates the temporary winner and runner 
%%     

compute_max(NUM_ANSWERS_ARRIVING) ->
		compute_max(NUM_ANSWERS_ARRIVING,{0,0}).  %% TODO think about this

compute_max(0 , TEMP_MAX) -> 
		TEMP_MAX; 
compute_max(NOD_OR_CHILD_REMAINING, TEMP_MAX)->
	%%io:format("I'm in compute_max ~p~n",[self()]),			
			
	receive 
		{my_decreased_error, NodePID, ERROR }->
			%%io:format("I received form ~p the error ~p~n",[NodePID,ERROR]),			
			ERR_TEMP_MAX = element(2, TEMP_MAX),
			if   
				ERR_TEMP_MAX < ERROR ->
					%% if is big enough to be the next max
					compute_max(NOD_OR_CHILD_REMAINING - 1, {NodePID, ERROR});
				
				true ->  
					compute_max(NOD_OR_CHILD_REMAINING - 1, TEMP_MAX)
			end
	end
.


%%addNode_TWIN_NODES_VERSION( NEW_NODE_PID, TWIN) ->

	%% comunicates to add new node to the twin
	
%%	TWIN ! { update_add_node, NEW_NODE_PID },  
%%
%%	receive
%%		{update_new_node_confirm , WIN_NEW_PID } -> 
%%				NEW_NODE_PID ! { set_twin, WIN_NEW_PID }
%%		after 4000 -> 
%%			io:format("~w :I've added a node but I didn't receive confirmation from my twin ~w~n",self(),TWIN)
%%
%%	end
%%
%%.


add_manager(DEPTH, TWIN) ->

	NEW_MAN = spawn( err_man, err_man_life, [self(),  % new parent
						[],	% new NODES list
						[],	% new CHILDREN list	
						DEPTH, % new DEPTH
						0]),	%%  New TWIN, 0 is temporary, until i receive the confirmation from the win_tree 
	TWIN ! { update_add_manager, NEW_MAN , self()} ,
	
	receive
		{ update_add_manager_confirm , WIN_TWIN } ->
			NEW_MAN ! {set_twin, WIN_TWIN},
			NEW_MAN
		after 4000 -> io:format("E_M ~p :I've added a node but I didn't receive confirmation from my twin ~p~n",self(),TWIN)
	end
.

