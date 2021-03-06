%% Author: nils
%% Created: May 31, 2009
%% Description: TODO: Add description to engine
-module(engine).

%%
%% Include files
%%

%%s
%% Exported Functions
%%
-export([start/1, start/12, starter/1]).

%%
%% API Functions
%%engine:start(int.dat).

%% this function isto semplify the init boot, returning sudden
starter(PARAM) -> spawn(fun () -> start(PARAM) end).

start ( [ FILE_NAME ] ) -> case file : open ( FILE_NAME , [ read ] ) of { ok , FILE } -> case file : open ( nodes .


dat , [ write ] ) of { ok , FILE_WRITE } -> io : format ( " file ~p opened as ~p~n" , [ FILE_NAME , FILE ] ) , start ( FILE , FILE_WRITE , 100 , 10 , 3 , 5.00000000000000000000e-01 , 5.99999999999999947438e-04 , 5.00000000000000000000e-01 , 9.99500000000000055067e-01 , 1 , 5 , 1.00000000000000004792e-04 ) ; { error , WHY } -> io : format ( "Problems opening the file nodes.dat because ~p~n" , [ WHY ] ) end ; { error , WHY } -> io : format ( "Problems opening the file ~p because ~p~n" , [ FILE_NAME , WHY ] ) end .


                        %	 88	 600  0.05						0.1

                            %TODO set those

start(FILE, FILE_WRITE, MAX_NODES, MAX_AGE, LAMBDA,
      MOVE_K, MOVE_N, ALPHA, D, FINAL_ERROR,
      FINAL_DELTA_ERROR, FINAL_DELTA_ERROR_DECAY) ->
    start(FILE, FILE_WRITE, MAX_NODES, MAX_AGE, LAMBDA,
	  MOVE_K, MOVE_N, ALPHA, D, 3, 5, 0, 0, FINAL_ERROR,
	  FINAL_DELTA_ERROR, FINAL_DELTA_ERROR_DECAY, err_man,
	  win_man, [], 0, 0).

start(FILE, FILE_WRITE, MAX_NODES, MAX_AGE, LAMBDA,
      MOVE_K, MOVE_N, ALPHA, D, M, N, 0, 0, FINAL_ERROR,
      FINAL_DELTA_ERROR, FINAL_DELTA_ERROR_DECAY, _ERR_MAN,
      _WIN_MAN, LOST_NODE_LIST, LAST_ERROR, DELTA_ERROR) ->
    %% Algorithm
    %%
    %% 0. 	Create max			(this has to create a MinManager)
    io:format("setting up algorithm~n"),
    WIN_MAN = spawn(win_man, win_man_life,
		    [self(), % PARENT,
		     [], % CHILDREN,
		     []]), % NODES,
    io:format(" win_man created~n"),
    ERR_MAN = spawn(err_man, err_man_life,
		    [self(), %PARENT,
		     [], % CHILDREN,
		     [], %NODES,
		     0, % DEPTH, TODO to be removed
		     WIN_MAN]), % TWIN
    io:format(" err_man created~n"),
    FIRST_NODE = spawn(node, node_life,
		       [read_Pattern(FILE), %POSITION,
			[], % EDGES,
			0, %ERROR,
			ERR_MAN, % PARENT
			self()]), %ENGINE
    io:format(" first node created ~p~n", [FIRST_NODE]),
    SECOND_NODE = spawn(node, node_life,
			[read_Pattern(FILE), %POSITION,
			 [{FIRST_NODE, 0}], % EDGES,
			 0, %ERROR,
			 ERR_MAN, % PARENT
			 self()]), %ENGINE
    io:format(" first node created ~p~n", [SECOND_NODE]),
    ERR_MAN ! {addNode, FIRST_NODE},
    ERR_MAN ! {addNode, SECOND_NODE},
    %io:format(" ITERATION = ~p~n",[ITERATION]),
    FIRST_NODE ! {newEdge, SECOND_NODE},
    ERR_MAN ! {add_Node, FIRST_NODE},
    ERR_MAN ! {add_Node, SECOND_NODE},
    io:format(" leaving setup~n"),
    start(FILE, FILE_WRITE, MAX_NODES, MAX_AGE, LAMBDA,
	  MOVE_K, MOVE_N, ALPHA, D, M, N, 1, 2, FINAL_ERROR,
	  FINAL_DELTA_ERROR, FINAL_DELTA_ERROR_DECAY, ERR_MAN,
	  WIN_MAN, LOST_NODE_LIST, LAST_ERROR, DELTA_ERROR);
%% 	countIteration := 0
%% 	countNodes := 0
%% 	Create 2 nodes randomly in the inputspace
%% 		(take 2 samples?)
%% 	Add nodes to max, max.AddNode, countNodes += 2
%% 	Make the 2 nodes neighbors,2 times nodes .newEdge(otherNode)
%% ---------------	
%% 	
start(FILE, FILE_WRITE, MAX_NODES, MAX_AGE, LAMBDA,
      MOVE_K, MOVE_N, ALPHA, D, M, N, ITERATION,
      NUMBER_OF_NODES, FINAL_ERROR, FINAL_DELTA_ERROR,
      FINAL_DELTA_ERROR_DECAY, ERR_MAN, WIN_MAN,
      LOST_NODE_LIST, LAST_ERROR, DELTA_ERROR) ->
    io:format("****************************************~n~nL"
	      "OOP we're in the loop I = ~p and have "
	      "~p Nodes~n~n*********************************"
	      "*******~n",
	      [ITERATION, NUMBER_OF_NODES]),
    INPUT = read_Pattern(FILE),
    io:format("\tLOOP Input read ~p~n", [INPUT]),
    %% Reset the file
    if ITERATION rem 600 == 50 ->
	   file:copy("nodes.dat", "nodes2.dat");
       ITERATION rem 600 == 100 -> file:delete("nodes.dat");
       true -> ok
    end,
    WIN_MAN ! {new_input, self(), INPUT},
    io:format("LOOP searching for winner~n"),
    receive
      {my_win_and_run, WIN_MAN, COMPARED_WIN_AND_RUN} ->
	  {{WINNER, DISTANCE}, {RUNNER_UP, _DISTANCE}} =
	      COMPARED_WIN_AND_RUN
    end,
    io:format("LOOP Winner received ~p~n", [WINNER]),
    %% 1.	Take input I (random?)
    %%
    %% 2. 	min.AskForMin(I)
    %% 	s1 := min.s1?
    %% 	s2 := min.s2?	
    WINNER ! {ageEdges, MAX_AGE},
    %% 	
    %% 3.	s1.Node.AgeEdges(maxAge)	
    %% 	
    WINNER ! {addToError, DISTANCE},
    %% 4.	s1.Node.UpdateError(s1.Distance)	
    %% 	//if Euclid without squareroot (see Node.ComputeDistance) then this without ^ 2
    %%
    WINNER ! {moveKN, INPUT, MOVE_K, MOVE_N},
    %% 5.	s1.Node.Move(I, move_k, move_n)	
    %% 		
    RUNNER_UP ! {refreshEdge, WINNER},
    WINNER ! {refreshEdge, RUNNER_UP},
    %% 6.	s1.Node.FreshNeighbor(s2.Node)
    %% 	s2.Node.FreshNeighbor(s1.Node)	
    %% 	
    %% 7.	implemented in 3.
    %%
    %TODO not sure if here or somewhere else
    io:format("ENGINE / LOOP waiting for the \"addEdges_done\" "
	      "message~n"),
    receive {ageEdges_done, WINNER} -> ok end,
    io:format("ENGINE / LOOP : message receive. checking "
	      "if we're in the lambda'th iteration~n"),
    REM_IT = trunc(ITERATION) rem trunc(LAMBDA),
    io:format("ENGINE / LOOP REM_IT calculated : ~p~n",
	      [REM_IT]),
    if REM_IT == 0 ->
	   ERR_MAN ! {request_decreased_error, self(), D},
	   receive
	     {my_error, ERR_MAN, MAX} -> {Q, ERROR} = MAX
	   end,
	   io:format("LOOP Q received: ~p~n", [Q]),
	   %%%%%check if GNG should stop engine:start(int.dat).
	   if ERROR < FINAL_ERROR ->
		  io:format("LOOP with ~p nodes a maximal error of "
			    "~p is reached~n",
			    [NUMBER_OF_NODES, ERROR]),
		  exit("maximal error reached");
	      %TODO store the graph
	      DELTA_ERROR <
		FINAL_DELTA_ERROR ->%DELTA_ERROR = DELTA_ERROR*ERROR_DECAY + abs(LAST_ERROR - ERROR)
		  io:format("LOOP maximal number (~p) of nodes reached, "
			    "and the maximal error stays the same "
			    "at about ~p~n",
			    [NUMBER_OF_NODES, ERROR]);
	      true ->
		  Q ! {request_maxNeighbor, self()},
		  io:format("LOOP maxNeighbor request ~n"),
		  receive
		    {my_maxNeighbor, Q, MAX_NEIGHBOR} -> F = MAX_NEIGHBOR
		  end,
		  io:format("LOOP maxNeighbor ~p received ~n", [F]),
		  Q !
		    {request_decreased_error_and_position, self(), ALPHA},
		  %TODO decrease error only for q, not for f???
		  %hm, i'm thinkin about it, i had a reason, but i can't remember it. i will write my answer here.
		  % i dohn't know, so i change it
		  %F ! {request_position, self()},
		  F !
		    {request_decreased_error_and_position, self(), ALPHA},
		  io:format("LOOP asking for error and position ~n"),
		  receive
		    {my_decreased_error_and_position, Q, Q_RETURN} ->
			{Q_ERROR, Q_POSITION} = Q_RETURN
		  end,
		  io:format("LOOP position and error from Q received ~n"),
		  %receive
		  %{my_position, F, F_RETURN}->
		  %	F_POSITION = F_RETURN
		  %end,
		  %io:format("LOOP position from F received ~n"),
		  receive
		    {my_decreased_error_and_position, F, F_RETURN} ->
			{_F_ERROR, F_POSITION} = F_RETURN
		  end,
		  NEW_NODE = spawn(node, node_life,
				   [getMiddle(Q_POSITION,
					      F_POSITION), %POSITION,
				    [{Q, 0}, {F, 0}], % EDGES,
				    Q_ERROR, %ERROR,
				    ERR_MAN, % PARENT
				    self()]), %ENGINE
		  addNode(ERR_MAN, NEW_NODE, NUMBER_OF_NODES + 1, M, N,
			  LOST_NODE_LIST),
		  Q ! {refreshEdge, NEW_NODE},
		  F ! {refreshEdge, NEW_NODE},
		  %inserts the new node in the neighborhood lists of f and q
		  Q ! {removeEdge, F},
		  F ! {removeEdge, Q}
	   end,
	   % check for messages of modification
	   checkMessages(FILE, FILE_WRITE, MAX_NODES, MAX_AGE,
			 LAMBDA, MOVE_K, MOVE_N, ALPHA, D, M, N, ITERATION + 1,
			 NUMBER_OF_NODES + 1, FINAL_ERROR, FINAL_DELTA_ERROR,
			 FINAL_DELTA_ERROR_DECAY, ERR_MAN, WIN_MAN,
			 LOST_NODE_LIST, ERROR,
			 DELTA_ERROR * FINAL_DELTA_ERROR_DECAY +
			   abs(LAST_ERROR - ERROR));
       %DELTA_ERROR = DELTA_ERROR*ERROR_DECAY + abs(LAST_ERROR - ERROR)
       true ->
	   ERR_MAN ! {decrease_error, self()},
	   % check for messages of modification
	   checkMessages(FILE, FILE_WRITE, MAX_NODES, MAX_AGE,
			 LAMBDA, MOVE_K, MOVE_N, ALPHA, D, M, N, ITERATION + 1,
			 NUMBER_OF_NODES, FINAL_ERROR, FINAL_DELTA_ERROR,
			 FINAL_DELTA_ERROR_DECAY, ERR_MAN, WIN_MAN,
			 LOST_NODE_LIST, LAST_ERROR, DELTA_ERROR)
    end.

%% 8.	if(countIteration mod lamba == 0)
%% 		max.AskForMax  (this implements also DecreaseError or equivalent)
%% 		q := max.q?.Node 	
%% 		f := q.Node.maxNeighbor
%% 		f.removeEdge(q.Node)
%% 		q.removeEdge(f.Node)
%% 		Create Node r
%% 		max.AddNode(r)
%% 		countNodes++
%% 		max.AddNode(r)
%% 		for(i = 0;i<n;i++)
%% 			r.Position[i] = (q.Node.Position[i]+f.Position[i])/2	
%% 		q.Node.DecreaseError(alpha)
%% 		f.DecreaseError(alpha)
%% 		r.Error = q.Error
%% 		q.NewEdge(r)
%% 		f.NewEdge(r)
%% 	else
%% 		max.DecreaseError(d)	
%% 		
%% 9.	included in 8., see also Manager.AskForMax	
%% 	
%% 10.	if(endCondition)
%% 		end
%% 	else
%% 		countIteration++
%% 		goto 1.	

%%
%% Local Functions
%%

%%%%CheckMessages(same arguments as start())
checkMessages(FILE, FILE_WRITE, MAX_NODES, MAX_AGE,
	      LAMBDA, MOVE_K, MOVE_N, ALPHA, D, M, N, FINAL_ERROR,
	      FINAL_DELTA_ERROR, FINAL_DELTA_ERROR_DECAY, ITERATION,
	      NUMBER_OF_NODES, ERR_MAN, WIN_MAN, LOST_NODE_LIST,
	      LAST_ERROR, DELTA_ERROR) ->
    receive
      {nodeRemoved, MANAGER_PID} ->
	  checkMessages(FILE, FILE_WRITE, MAX_NODES, MAX_AGE,
			LAMBDA, MOVE_K, MOVE_N, ALPHA, D, M, N, FINAL_ERROR,
			FINAL_DELTA_ERROR, FINAL_DELTA_ERROR_DECAY, ITERATION,
			NUMBER_OF_NODES - 1, ERR_MAN, WIN_MAN,
			LOST_NODE_LIST ++ [MANAGER_PID], LAST_ERROR,
			DELTA_ERROR)
      after 1 ->
		start(FILE, FILE_WRITE, MAX_NODES, MAX_AGE, LAMBDA,
		      MOVE_K, MOVE_N, ALPHA, D, M, N, FINAL_ERROR,
		      FINAL_DELTA_ERROR, FINAL_DELTA_ERROR_DECAY, ITERATION,
		      NUMBER_OF_NODES, ERR_MAN, WIN_MAN, LOST_NODE_LIST,
		      LAST_ERROR, DELTA_ERROR)
    end.

%% addNode(NEW_NODE, NUMBER_OF_NODES)
% checks where to add the NEW_NODE and does it
% NuMBER_OF_NODES includes the new one
addNode(ERR_MAN, NEW_NODE, NUMBER_OF_NODES, M, N, []) ->
    CHECK = NUMBER_OF_NODES rem N,
    if CHECK == 0 ->
	   io:format("addNODE ENGINE_ADDNODE sends move_nodes_start~n"),
	   ERR_MAN !
	     {move_nodes_start, NEW_NODE,
	      getDirections(NUMBER_OF_NODES + 1, M, N)};
       true ->
	   io:format("addNODE ENGINE_ADDNODE sends addNode~p~n",
		     [NEW_NODE]),
	   ERR_MAN ! {addNode, NEW_NODE}
    end;
addNode(_ERR_MAN, NEW_NODE, _NUMBER_OF_NODES, _M, _N,
	[HEAD | _LOST_NODE_LIST]) ->
    io:format("addNODE ENGINE_ADDNODE sends addNode, "
	      "to first element of LOST_NODE_LIST~n"),
    NEW_NODE ! {setParent, HEAD},
    HEAD ! {addNode, NEW_NODE}.

%%getDirection(C, M, N)
%C: Number of nodes
%returns an array with the directions, i.e. to which managers to pass the nodes
getDirections(C, M, N) -> whichDepth(C, 0, M, N).

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

%%%getMiddle(A, B)
%A, B, are positions (lists of numbers)
%returns (A + B)/2, the position in the middle of the two
getMiddle(A, B) -> getMiddle(A, B, []).

getMiddle([], [], TMP) -> TMP;
getMiddle([A_HEAD | A_TAIL], [B_HEAD | B_TAIL], TMP) ->
    getMiddle(A_TAIL, B_TAIL,
	      [(A_HEAD + B_HEAD) / 2 | TMP]).

%% Reads jsut one pattern
%% + returns a List of Coordinates
% read_Pattern(File) ->
% 		
%     case io:get_line(File, "")
% 	of
% 	        eof  -> file:position(File,0),
% 					get_coordinates(io:get_line(File, ""));
% 	        Line -> %io:format( "I've read ~s~n",[Line]),
% 					get_coordinates(Line)
% 			
%     end
% 	
% .

%%%% get_coordinates(LINE) %%%%%%%%%%
%% given as input a Line containing indefinete number of colons, reads the coordinates a puts them in a List
%%
%% + returns a List of coordinates
%
% get_coordinates(LINE) -> get_coordinates(LINE,[]).
%
% get_coordinates([],TEMP) -> TEMP;
% get_coordinates([HEAD|TAIL],TEMP) ->
% 	if
% 		HEAD == 9; HEAD ==10 ->
% 			%io:format("found tab or new line~n"),
% 			get_coordinates(TAIL, TEMP);
% 		
% 		true->	
% 			%io:format("New number added : ~w	~w~n",[TEMP, [list_to_integer([HEAD])] ]),
% 			get_coordinates(TAIL, lists:append(TEMP, [list_to_integer([HEAD])]))
% 			%%io:format("New number added : ~w~n",[TEMP])
% 			
% 	end
% .

%%%%%% read_Pattern(File)
%% reads a new line (a string) form the file descriptor File, separates the substring separated by "	", and converts them into a list of numbers %%
%% (integesr or float)
%%
%%	+ returns: a list of values
%%	+ calls: convert(Line)
%%
read_Pattern(File) ->
    case io:get_line(File, "") of
      eof -> file:close(File);
      Line -> %%io:format( "I've read ~s~n",[Line]),
	  Pattern = string:tokens(Line, "\t"),
	  Numbers =
	      convert(Pattern)                        %%io:format( "READ : Pattern: ~s Numbers :~w~n, ",[Pattern,Numbers])
    end.

%%%% convert(LINE) %%%%%%%%%%
%% given as input a List of Tokens (String) containing the BitString form of a floating point or a integer, returns a List of corrisponding integers or %%% float
%%
%% es: convert(["22.2","1","33.241235"]) -> [22.2, 1, 33.241235]
%%
%% + returns a List of coordinates

convert(P) -> convert(P, []).

convert([], TEMP) -> TEMP;
convert([HEAD | TAIL], TEMP) ->
    case string:to_float(HEAD) of
      {error, _} ->
	  convert(TAIL,
		  TEMP ++ [element(1, string:to_integer(HEAD))]);
      {Number, _Empty} -> convert(TAIL, TEMP ++ [Number])
    end.
