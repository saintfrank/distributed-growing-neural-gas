%% Author: nils
%% Created: May 27, 2009
%% Description: TODO: Add description to node
-module(node).

%%
%% Include files
%%

%%
%% Exported Functions
%%
-export([%start/0, 
		 node_life/5
		%, man_life/4 
		]).

%%
%% API Functions
%%




%% 	Param:
%% 	+ POSITION is a list of the positions in each dimension
%% 	+ EDGES is a list of pairs {nodepid, age} 
%% 	+ ERROR is a real number
%% 	+ PARENT is a ManagerPID
%% 	+ ENGINE is the PID of the engine
%%
%% 	receives:
%% 
%% 	+ {set_parent, NEW_PARENT_PID} ->
%% 			- sets the Parent_PID of the node
%% 
%%  + {position_request, REQUESTING_PID }
%%     		- Sends REQUESTING_PID ! {my_position, self(), POSITION } 
%% 
%% 	+ {edges_request, REQUESTING_PID} -> 
%% 			- Sends REQUESTING_PID ! {my_edges, self(), EDGES }
%% 
%% 	+ {request_error, REQUESTING_PID} -> 
%% 			- sends REQUESTING_PID ! {my_error, self(), ERROR }
%% 	
%% 	+ {request_decreased_error, REQUESTING_PID, D} ->
%% 			- decreases the error by D in the node
%% 			- returns the decreased error
%% 			- this is request_error and decrease_error in one
%% 			- sends REQUESTING_PID ! {my_decreased_error, self(), ERROR*D }
%% 
%% 	+ {newEdge, OTHER_NODEPID} ->	%has to be added also in the otherNode
%% 			- creates a new edge to OTHER_NODE
%% 		
%% 	+ {ageEdges, MAX_AGE} ->
%% 			- ages the edges and removes the node if no edges left
%% 			- might send PARENT ! {removeNode, self(), self()},
%% 			
%% 	+ {removeEdge, OTHER_NODE} ->
%% 			- has to be evoqued in both nodes
%% 		  	- removes the edge to OTHER_NODE
%% 		
%% 	+ {addToError, DELTA_ERROR} ->
%% 			- adds DELTA_ERROR to ERROR
%% 		
%% 	+ {decreaseError, ALPHA} ->
%% 			- ERROR <- ERROR * ALPHA
%% 
%% 	+ {moveKN, INPUT, MOVE_K, MOVE_N} ->
%% 			- sends {moveN, self(), INPUT, MOVE_N} to all neighbors
%% 			- moves this node MOVE_K towards INPUT
%% 	
%% 	+ {moveN, INPUT, MOVE_N} ->
%% 			- moves this node MOVE_N towards INPUT
%% 		
%% 	+ {refreshEdge, OTHER_NODE} -> %has to be called for both nodes
%% 			- sets the age of the edge to OTHER_NODE to 0 or creates this edge
%% 	
%% 	+ {request_maxNeighbor, REQUESTING_PID} ->  
%% 			- sends REQUESTING_PID ! {my_maxNeighbor, self(), maxNeighbor(EDGES)},
%% 			
%% 	+ {request_distance, REQUESTING_PID, INPUT} ->  %here is REQUESTING_PID needed
%% 			- sends REQUESTING_PID ! {my_distance, self(), distance(POSITION, INPUT)},
%% 

node_life(POSITION, EDGES, ERROR, PARENT, ENGINE)-> 

%% 	io:format(" I'm back to life ~p to ~p ~n", [POSITION,self()]),
	
	receive 
		{ageEdges, MAX_AGE} ->
			% calls ageEdges and removes the node if no edges left
			io:format("NODE / ageEdges : ~p's old edges ~p ~n", [self(), EDGES]),
			TMP = ageEdges(EDGES, MAX_AGE),
			ENGINE ! {ageEdges_done, self()},
			io:format("NODE / ageEdges : ~p's new edges ~p ~n", [self(), TMP]),
			if
				TMP == [] -> 
					PARENT ! {removeNode, self()},
					ENGINE ! {nodeRemoved, PARENT},
					io:format("NODE / ageEdges ~p : I'm dead, because i have no friends :( ~n",[self()]),
					exit("no friends");
				true ->
					io:format("NODE / ageEdges ~p : I have aged all my Edges ~n", [self()]),
					node_life(POSITION, TMP, ERROR, PARENT, ENGINE)
			end;
			
	
		{ageMyEdge, OTHER_NODE}->
			io:format("NODE / ageMyEdge ~p : edge to ~p should be aged~n", [self(), OTHER_NODE]),
			node_life(POSITION, ageAnEdge(EDGES, OTHER_NODE), ERROR, PARENT, ENGINE);		
			

		{newEdge, OTHER_NODEPID} ->	%has to be added also in the otherNode
			io:format("NODE / newEdge ~p : I have created a new Edge with ~p ~n", [self(),OTHER_NODEPID]),
			io:format("  my new EDGES ~p ~n", [[{OTHER_NODEPID, 0}|EDGES]]),
			node_life(POSITION, [{OTHER_NODEPID, 0}|EDGES], ERROR, PARENT, ENGINE);
		
		
		{request_position, REQUESTING_PID} -> 
			io:format("NODE / request_position ~p :  I'm sending my position: ~p to ~p ~n", [self(), POSITION,REQUESTING_PID]),
			REQUESTING_PID ! {my_position, self(), POSITION },
			node_life(POSITION, EDGES, ERROR, PARENT, ENGINE);
		
		{request_edges, REQUESTING_PID} -> %TODO has to be REQUESTING_PID_2 ??? 
			io:format("NODE / request_edges ~p : I'm sending my edges: ~p to ~p ~n", [self(), EDGES, REQUESTING_PID]),
			REQUESTING_PID ! {my_edges, self(), EDGES },
			node_life(POSITION, EDGES, ERROR, PARENT, ENGINE);
		
		{request_error, REQUESTING_PID} -> 
			io:format("NODE / request_error ~p : I'm sending my error: ~p to ~p ~n", [self(),ERROR,REQUESTING_PID]),
			REQUESTING_PID ! {my_error, self(), ERROR },
			node_life(POSITION, EDGES, ERROR, PARENT, ENGINE);
    
		{request_decreased_error, REQUESTING_PID, D} ->
			%returns the decreased error
			io:format("NODE / request_decreased_error ~p : I'm sending my error: ~p to ~p ~n", [self(),ERROR,REQUESTING_PID]),
			REQUESTING_PID ! {my_decreased_error, self(), ERROR*D },
			node_life(POSITION, EDGES, ERROR*D, PARENT, ENGINE);
		
		{request_decreased_error_and_position, REQUESTING_PID, ALPHA}->
			%returns the decreased error and the position in a tuple
			REQUESTING_PID ! {my_decreased_error_and_position, self(), {ERROR*ALPHA, POSITION}},
			io:format("NODE / request_decreased_error_and_position ~p : I returned my error ~p and my position ~p~n",[self(), ERROR*ALPHA, POSITION]),
			
			%% PRINTING POSITION ON THE FILE  %%%%%%%%%
			{ok, FILE_WRITE} = file:open(nodes.dat, [append]),
			io:format(FILE_WRITE,"~s~n",[posToStr2(POSITION)]),
			file:close(FILE_WRITE),
			io:format(" NODE / request_distance ~p : filewrite was OK~n", [self()]),
			
			node_life(POSITION, EDGES, ERROR*ALPHA, PARENT, ENGINE);
		


		
		{removeEdge, OTHER_NODE} ->
			TMP = removeEdge(OTHER_NODE, EDGES),
			if
								TMP == [] -> 
					PARENT ! {removeNode, self()},
					ENGINE ! {nodeRemoved, PARENT},
					io:format("NODE / removeEdge ~p : I'm dead, because i have no friends :( ~n",[self()]),
					exit("no friends");
				true ->
					io:format("NODE / removeEdge ~p : edge to ~p was removed~n",[self(), OTHER_NODE]),
		  			node_life(POSITION, TMP, ERROR, PARENT, ENGINE)
			end;
		
		
		{addToError, DELTA_ERROR} ->
			io:format("NODE / addToError ~p : my error is now ~p bigger ~n", [self(), DELTA_ERROR]),
			node_life(POSITION, EDGES, ERROR + DELTA_ERROR, PARENT, ENGINE);
		
		
		{decreaseError, ALPHA} ->
			io:format("NODE / decreaseError ~p : I decreased my error to a ~p part ~n", [self(), ALPHA]),
			node_life(POSITION, EDGES, ERROR*ALPHA, PARENT, ENGINE);

		
		{moveKN, INPUT, MOVE_K, MOVE_N} ->
			moveNeighbors(EDGES, INPUT, MOVE_N),
			io:format("NODE / moveKN ~p : I moved ~p and hopefully my neighbors ~n", [self(),MOVE_K]),
			node_life(move(POSITION, INPUT, MOVE_K), EDGES, ERROR, PARENT, ENGINE);
	
		
		{moveN, INPUT, MOVE_N} ->
			io:format("NODE / moveN ~p : I moved ~p ~n", [self(),MOVE_N]),
			node_life(move(POSITION, INPUT, MOVE_N), EDGES, ERROR, PARENT, ENGINE);
		
		
		{refreshEdge, OTHER_NODE} -> %has to be called for both nodes
			io:format("NODE / refreshEdge ~p : edge to ~p refreshed~n", [self(), OTHER_NODE]),
			node_life(POSITION, refreshEdge(OTHER_NODE, EDGES), ERROR, PARENT, ENGINE);
	
		
		{request_maxNeighbor, REQUESTING_PID} ->  
			REQUESTING_PID ! {my_maxNeighbor, self(), maxNeighbor(EDGES)},
			io:format("NODE / request_maxNeighbor ~p : neighbor with biggest error was returned to ~p~n", [self(), REQUESTING_PID]),
			node_life(POSITION, EDGES, ERROR, PARENT, ENGINE);
		
		
		{request_distance, REQUESTING_PID, INPUT} ->  
			io:format("NODE / request_distance ~p : I'm sending my distance, i'm in position: ~p~n", [self(), POSITION]),
			
			REQUESTING_PID ! {my_distance, self(), distance(POSITION, INPUT)},
			io:format(" NODE / request_distance ~p : I'm about printing my position: ~p~n", [self(), POSITION]),
			
% 			%% PRINTING POSITION ON THE FILE  %%%%%%%%%
% 			{ok, FILE_WRITE} = file:open(nodes.dat, [append]),
% 			io:format(FILE_WRITE,"~s~n",[posToStr2(POSITION)]),
% 			file:close(FILE_WRITE),
% 			io:format(" NODE / request_distance ~p : filewrite was OK~n", [self()]),

			node_life(POSITION, EDGES, ERROR, PARENT, ENGINE);
		

		{removeEdgeAndTell, OTHER_NODE}->			
			TMP = removeEdge(OTHER_NODE, EDGES),
			io:format("NODE / removeEdgeAndTell ~p : edge to ~p was removed ~n",[self(), OTHER_NODE]),
			io:format("   my old edges ~p~n",[EDGES]),
			io:format("   my new edges ~p~n",[TMP]),
			OTHER_NODE ! {removeEdgeAndTell_done, self()},
			if
				TMP == [] -> 
					PARENT ! {removeNode, self()},
					ENGINE ! {nodeRemoved, PARENT},
					io:format("NODE / removeEdgeAndTell ~p : I'm dead, because i have no friends :( ~n",[self()]),
					exit("no friends");
				true ->
					node_life(POSITION, removeEdge(OTHER_NODE, EDGES), ERROR, PARENT, ENGINE)
			end;


		{set_parent, NEW_PARENT_PID} ->
			node_life(POSITION, EDGES, ERROR, NEW_PARENT_PID, ENGINE)

	end
.

% posToStr([], FILE)->
% 	io:format(FILE, "\n",[]),
% 	[];
% posToStr([HEAD|TALE], FILE)->
% 		io:format(FILE, "~f\t",[HEAD]),
% 		posToStr(TALE, FILE)
% .

posToStr2([])->
	"";
posToStr2([HEAD|TALE])->
		io:format("NODE / mando: ~f\t  ~n", [HEAD]),
		float_to_list(HEAD) ++ "      " ++ posToStr2(TALE)
.
		
%% man_life(NODEPID, OTHER_NODE, STAYING_NODE, INPUT) ->
%% 	
%% 	
%% 	
%% 	NODEPID ! {request_position, self()},
%% 
%% 	NODEPID ! {request_edges, self()},
%% 
%% 	NODEPID ! {request_error, self()},
%% 
%% 	NODEPID ! {newEdge, self(), OTHER_NODE},
%% 	
%% 	NODEPID ! {newEdge, self(), STAYING_NODE},
%% 
%%  	NODEPID ! {ageEdges, self(), 5 },%MAX_AGE},
%% 	
%% 	NODEPID ! {ageEdges, self(), 1 },%MAX_AGE},
%% 
%% 	NODEPID ! {removeEdge, self(), OTHER_NODE},
%% 
%% 	NODEPID ! {addToError, self(), 1.4 }, %DELTA_ERROR},
%% 
%% 	NODEPID ! {decreaseError, self(), 0.5},%ALPHA},
%% 
%% 	NODEPID ! {moveKN, self(), INPUT, 0.3, 0.1}, %MOVE_K, MOVE_N},
%% 
%% 	NODEPID ! {moveN, self(), INPUT, 0.2}, %MOVE_N},
%% 
%% 	NODEPID ! {refreshEdge, self(), OTHER_NODE},
%% 
%% 	NODEPID ! {request_maxNeighbor, self()},
%% 
%% 	NODEPID ! {request_distance, self(), INPUT}
%% 	
%% %% 	,
%% %% 	receive
%% %% 		{my_pos, NPID, POS} -> 
%% %% 			io:format(" Node ~p`s position: ~p  ~n", [NPID,POS])  
%% %% 	     
%% %% 	
%% %% 	end
%%     
%% .
%% 
%% 
%% start()->
%% 	
%% 	NEWNODE=spawn(node,node_life, [[1,1],[],0,self()]),
%% 	OTHER_NODE = spawn(node,node_life, [[2,2],[],0,self()]),
%% 	STAYING_NODE = spawn(node,node_life, [[5,5],[],0,self()]),
%% 	NEWMAN=spawn(node,man_life,[NEWNODE, OTHER_NODE, STAYING_NODE, [3,3]])
%% .



%%
%% local Functions
%%

%%%%% ageEdges %%%%%
% ages all the edges and removes too old ones
% returns all edges

ageEdges([], _MAX_AGE) -> 
	[];
ageEdges(ok, _MAX_AGE) -> 
	io:format("NODE / (func) ageEdges ~p : ok instead of [] is strange~n", [self()]),
	[];
ageEdges([{NODE, AGE}|TAIL], MAX_AGE) ->
	if
		AGE + 1 > MAX_AGE ->
			NODE ! {removeEdgeAndTell, self()},
			io:format("NODE / (func) ageEdges ~p: waiting for ~p to remove my edge~n", [self(), NODE]),
			receive
				{removeEdgeAndTell_done, NODE}->ok
			end,
			io:format("NODE / (func) ageEdges : edge between ~p and ~p was removed in both~n", [self(), NODE]),
			ageEdges(TAIL, MAX_AGE);
		true ->	
			NODE ! {ageMyEdge, self()},
			[{NODE, AGE + 1}|ageEdges(TAIL, MAX_AGE)]
	end
.
ageAnEdge(ok, OTHER_NODE)->
	io:format("NODE / (func) ageAnEdge ~p : there is no edge to ~p~n",[self(), OTHER_NODE]);
ageAnEdge([], OTHER_NODE)->
	io:format("NODE / (func) ageAnEdge ~p : there is no edge to ~p~n",[self(), OTHER_NODE]);
ageAnEdge([{NODE, AGE}|TAIL], OTHER_NODE)->
	if
		NODE == OTHER_NODE ->
			io:format("NODE / (func) ageAnEdge ~p : edge to ~p was aged~n",[self(), OTHER_NODE]),
			[{NODE, AGE+1}|TAIL];
		true ->
			[{NODE, AGE}|ageAnEdge(TAIL, OTHER_NODE)]
	end
.
  
%%%%% removeEdge(OTHER_NODE, EDGES) %%%%%  
% removes the edge to OTHER_NODE 
% returns all edges

removeEdge(_OTHER_NODE, [])->
	[];
removeEdge(OTHER_NODE, [{OTHER_NODE, _}|TAIL]) ->
	%TO DO should this send confirmation?
	io:format("NODE / (func) removeEdge ~p : edge to ~p removed ~n",[self(), OTHER_NODE]),
	removeEdge(OTHER_NODE, TAIL);
removeEdge(OTHER_NODE, [H|TAIL]) ->
	[H|removeEdge(OTHER_NODE, TAIL)]
.  


%%%%% move %%%%%
% returns a new position, (INPUT -POSITION)*MOVE + POSITION

move([], [], _) ->
	[];
move([H_POSITION|TAIL_POSITION], [H_INPUT|TAIL_INPUT], MOVE)-> 
	[(H_INPUT - H_POSITION)*MOVE + H_POSITION|move(TAIL_POSITION, TAIL_INPUT, MOVE)]
.


%%%%% moveNeighbors %%%%%
% tells all neighbors to move
moveNeighbors(ok, _, _) -> io:format("NODE / (func) moveNeighbors ~p : ok instead of [] is strange~n", [self()]);
moveNeighbors([], _, _)-> io:format("NODE / (func) moveNeighbors ~p : all neighbors are moved ~n", [self()]);
moveNeighbors([{NODE, _}|TAIL], INPUT, MOVE_N)->
	NODE ! {moveN, self(), INPUT, MOVE_N},
	moveNeighbors(TAIL, INPUT, MOVE_N)
.


%%%%% refreshEdge %%%%%
% sets the age of the edge to OTHER_NODE to 0 or creates the edge
% can also be used to add edges
refreshEdge(OTHER_NODE, []) ->
	io:format("NODE / (func) refreshEdge ~p : edge to ~p was created instead of refreshed ~n", [self(),OTHER_NODE]),
	[{OTHER_NODE, 0}];	%no edge was updated, so create new one
refreshEdge(OTHER_NODE, ok) ->
	io:format("NODE / (func) refreshEdge ~p : edge to ~p was created instead of refreshed~n AND ok instead of [] is strange ~n", [self(), OTHER_NODE]),
	[{OTHER_NODE, 0}];	%no edge was updated, so create new one
refreshEdge(OTHER_NODE, [{OTHER_NODE, _}|TAIL]) ->
	io:format("NODE / (func) refreshEdge ~p : edge to ~p was refreshed ~n", [self(), OTHER_NODE]),
	[{OTHER_NODE, 0}|TAIL]; %stops if edge updated
refreshEdge(OTHER_NODE, [H|TAIL]) ->
	[H|refreshEdge(OTHER_NODE, TAIL)]
.


%%%%% maxNeighbor %%%%%
% returns the neighbor with the highest accumulated error
% TODO better, more parallel function?engine:start(int.dat).


maxNeighbor(EDGES)->
	io:format("NODE / (func) maxNeighbor ~p : I will wait for the following nodes~n~p~n",[self(), EDGES]),
	maxNeighbor({0, null}, EDGES) 
.
maxNeighbor({_, ACT_NODE}, []) ->
	ACT_NODE;
maxNeighbor({ACT_ERR, ACT_NODE}, [{NODE, _}|TAIL]) ->
	NODE ! {request_error, self()},
	receive
		{my_error, NODE, ERROR }-> 
			if
				ERROR > ACT_ERR->
					io:format("NODE / (func) maxNeighbor ~p : error from ~p received. it was biggest~n",[self(), NODE]),
					maxNeighbor({ERROR, NODE},TAIL);
				true ->
					io:format("NODE / (func) maxNeighbor ~p : error from ~p received~n",[self(), NODE]),
					maxNeighbor({ACT_ERR, ACT_NODE}, TAIL)
			end
	end	
.


%%%%% distance %%%%%
% returns the square of the Euclidean distance between POSITION and INPUT

distance(POSITION, INPUT) ->
	dist(POSITION, INPUT, 0)
.
dist([], [], D) ->
	D;
dist([H_POSITION|TAIL_POSITION], [H_INPUT|TAIL_INPUT], D)->
  	dist(TAIL_POSITION, TAIL_INPUT, D +(H_POSITION - H_INPUT)*(H_POSITION - H_INPUT))
	%TODO is there a square function?
.
