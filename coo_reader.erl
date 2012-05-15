-module(coo_reader).

-export([start/1,read_Pattern/1]).


start(NAME)->

	{ok, File2} = file:open(NAME, [read]),


	_COO= read_Pattern(File2)
	%%io:format( "I've read ~w~n",[COO])	
.









%%%% get_coordinates(LINE) %%%%%%%%%%
%% given as input a Line containing indefinete number of colons, reads the coordinates a puts them in a List  
%% 
%% + returns a List of coordinates

get_coordinates(LINE) -> get_coordinates(LINE,[], []).

get_coordinates([],TEMP, _X) -> TEMP;
get_coordinates([HEAD|TAIL],TEMP, PARTIALNUMBER) ->
	if
		HEAD == 9; HEAD ==10 -> 
			io:format("found tab or new line~n"),
			get_coordinates(TAIL, lists:append(TEMP, PARTIALNUMBER),[]);
		
		HEAD == 46 -> 
			%%io:format("I found a point , i continue to add to partial: ~w	~w~n",[TEMP, [list_to_([HEAD])] ]),
			get_coordinates(TAIL, TEMP, lists:append(PARTIALNUMBER, list_to_binary([HEAD] ) ));
			%%io:format("New number added : ~w~n",[TEMP]);
		
		true->	
			io:format("New number added : ~w	~w~n",[TEMP, list_to_integer( [HEAD] )  ] ),
			get_coordinates(TAIL, TEMP, lists:append(PARTIALNUMBER,list_to_integer([HEAD])))
			%%io:format("New number added : ~w~n",[TEMP])
			
	end
.

str_to_float(Str) ->
try float(list_to_integer(Str))
catch error:_ -> list_to_float(Str)
end. 


%%%%%% read_Pattern(File)
%% reads a new line (a string) form the file descriptor File, separates the substring separated by "	", and converts them into a list of numbers %%
%% (integesr or float) 
%%
%%	+ returns: a list of values
%%	+ calls: convert(Line)
%%
read_Pattern(File) ->
		
    case io:get_line(File, "") 
	of
	        eof  -> file:close(File);
	        Line -> io:format( "I've read ~s~n",[Line]),
			Pattern= string:tokens(Line,"	"),
			%%X=lists:nth(1,Line),			
			Numbers = convert(Pattern),		
			io:format( "READ : Pattern: ~s Numbers :~w~n, ",[Pattern,Numbers])
			
    end
	
.


%%%% convert(LINE) %%%%%%%%%%
%% given as input a List of Tokens (String) containing the BitString form of a floating point or a integer, returns a List of corrisponding integers or %%% float  
%% 
%% es: convert(["22.2","1","33.241235"]) -> [22.2, 1, 33.241235]
%%
%% + returns a List of coordinates

convert(P)->convert(P,[]).

convert([],TEMP) -> TEMP;

convert([HEAD|TAIL],TEMP) ->	
	
	case string:to_float(HEAD) of
		{error, _ } -> 
			convert(TAIL,lists:append(TEMP,[element(1,string:to_integer(HEAD))]));
		{ Number , _Empty } -> 
			convert(TAIL,lists:append(TEMP,[Number]))
	end

.