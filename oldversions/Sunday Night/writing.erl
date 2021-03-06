-module(writing).

-export([read_Pattern/1, start/1, write_position/2]).

start(NAME) ->
    {ok, File} = file:open(NAME, [write]),
    spawn(writing, write_position, [1.1213213413e+1, File]),
    spawn(writing, write_position, [2.1213423541e+1, File]),
    spawn(writing, write_position, [3.1213412341e+1, File]),
    timer:sleep(1000),
    file:position(File, 0),
    %%spawn(writing,foo2,[4,File]),
    timer:sleep(1000),
    file:close(File),
    {ok, File2} = file:open(NAME, [read]),
    %%spawn(writing,read_Pattern,[File2]),
    %%spawn(writing,read_Pattern,[File2]),
    %%spawn(writing,read_Pattern,[File2])
    COO = read_Pattern(File2),
    io:format("I've read ~w~n", [COO]).

write_position(N, File) ->
    io:format(File, "~w\t~w\t~w~n", [N, N, N]).

        %file:write(File,"data to be written ~n"),

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
      Line ->
	  io:format("I've read ~s~n", [Line]),
	  Pattern = string:tokens(Line, "\t"),
	  %%X=lists:nth(1,Line),			
	  Numbers = convert(Pattern),
	  io:format("READ : Pattern: ~s Nombers :~w~n, ",
		    [Pattern, Numbers]),
	  read_Pattern(File)
    end.

%%%% get_coordinates(LINE) %%%%%%%%%%
%% given as input a Line containing indefinete number of colons, reads the coordinates a puts them in a List
%%
%% + returns a List of coordinates

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
      Line ->
	  io:format("I've read ~s~n", [Line]),
	  Pattern = string:tokens(Line, "\t"),
	  %%X=lists:nth(1,Line),			
	  Numbers = convert(Pattern),
	  io:format("READ : Pattern: ~s Nombers :~w~n, ",
		    [Pattern, Numbers]),
	  read_Pattern(File)
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
