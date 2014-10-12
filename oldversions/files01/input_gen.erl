%% Author: nils
%% Created: May 29, 2009
%% Description: TODO: Add description to input_gen
-module(input_gen).

%%
%% Include files
%%

%%
%% Exported Functions
%%
-export([file/4]).

%%
%% API Functions
%%

%% %%%file(N, WIDTH, TYPE, FILE_NAME)
%% writes a file with test samples
%%
%% param:
%%  N: 		number of samples
%%  WIDTH:	width of the input space, e.g. 10 for a 10x10 inout space
%%  TYPE:		can be:
%% 			rectangle
%% 			circle
%% 			uni
%% 			hilodensity
%% 			cluster
%% FILE_NAME: how the file will be named

file(N, WIDTH, TYPE, FILE_NAME) ->
    {ok, FILE} = file:open(FILE_NAME, [write]),
    case TYPE of
      rectangle -> rect(N, WIDTH, FILE);
      circle -> circle(N, WIDTH, FILE, WIDTH / 4);
      uni -> uni(N, WIDTH, FILE);
      hilodensity -> hilo(N, WIDTH, FILE);
      cluster ->
	  %give a list with {Probability, Radius (i.e. standard derivation), {centreX, CentreY}
	  %where centreX and Y are from [0, 1]
	  cluster(N, WIDTH, FILE,
		  [{2.5e-1, 1.0e-1, {2.0e-1, 2.0e-1}},
		   {2.5e-1, 1.0e-1, {2.0e-1, 8.0e-1}},
		   {5.0e-1, 2.0e-1, {6.99999999999999955591e-1, 5.0e-1}}])
    end.

%% file(N, WIDTH, TYPE, ARGS, FILE_NAME)->
%%
%% 	{ok, FILE} = file:open(FILE_NAME, [write]),
%% 	
%% 	if
%% 		TYPE == rectangle ->
%% 			rect(N, WIDTH, FILE);
%% 		TYPE == circle ->
%% 			circle(N, WIDTH, FILE, ARGS);
%% 		TYPE == uni ->
%% 			uni(N, WIDTH, FILE);
%% 		TYPE == hilodensity ->
%% 			hilo(N, WIDTH, FILE)
%% 	end
%% .

% random x, check if still possible, random y independent of x, check if inside
%circle M, radius, Mx-r<= x <= Mx+r
%	My - sin(arccos((x-Mx)/r))*r <= y <= My + sin(arccos((x-Mx)/r))*r
%ring M, r1, r2, circle M, r2 but not M, r1
%, rectangle easy
% hilodensity, 2 rectangles, random which one,
% large spirals, small spirals,  many cases
% UNI,
% discrete, List with {M,r} p(x)= exp(-(x- M) ^ 2/2)/sqr(2*pi)

%%
%% Local Functions
%%
rect(0, _, FILE) -> file:close(FILE);
rect(N, WIDTH, FILE) ->
    io:format(FILE, "~p\t~p~n",
	      [(2.0e-1 + random:uniform() * 5.99999999999999977796e-1)
		 * WIDTH,
	       (4.0e-1 + random:uniform() * 2.0e-1) * WIDTH]),
    rect(N - 1, WIDTH, FILE).

%center in the M middle, R: radius
circle(0, _, FILE, R) -> file:close(FILE);
circle(N, WIDTH, FILE, R) ->
    io:format(FILE, "~p\t~p~n", rand_circle(WIDTH / 2, R)),
    circle(N - 1, WIDTH, FILE, R).

rand_circle(M, R) ->
    X = 2 * random:uniform() - 1,
    Y = 2 * random:uniform() - 1,
    AY = abs(Y),
    AX = math:sin(math:acos(X)),
    if AY < AX -> [X * R + M, Y * R + M];
       true -> rand_circle(M, R)
    end.

uni(0, _, FILE) -> file:close(FILE);
uni(N, WIDTH, FILE) ->
    io:format(FILE, "~p\t~p~n", rand_uni(WIDTH)),
    uni(N - 1, WIDTH, FILE).

rand_uni(WIDTH) ->
    X = 2.0e-1 +
	  random:uniform() * 6.99999999999999955591e-1,
    if (X > 6.99999999999999955591e-1) and (X < 8.0e-1) ->
	   rand_uni(WIDTH);
       true ->
	   Y = 2.99999999999999988898e-1 +
		 random:uniform() * 4.0e-1,
	   if (X < 4.0e-1) and (X > 2.99999999999999988898e-1) and
		(Y > 4.0e-1) ->
		  rand_uni(WIDTH);
	      (X > 5.0e-1) and (X < 5.99999999999999977796e-1) and
		(Y < 5.99999999999999977796e-1) ->
		  rand_uni(WIDTH);
	      true -> [X * WIDTH, Y * WIDTH]
	   end
    end.

hilo(0, _, FILE) -> file:close(FILE);
hilo(N, WIDTH, FILE) ->
    Q = random:uniform(),
    if Q > 5.0e-1 ->
	   X = 2.0e-1 + random:uniform() * 2.0e-1,
	   Y = 4.0e-1 + random:uniform() * 2.0e-1;
       true ->
	   X = 5.99999999999999977796e-1 +
		 random:uniform() * 2.0e-1,
	   Y = 1.0e-1 + random:uniform() * 8.0e-1
    end,
    io:format(FILE, "~p\t~p~n", [X * WIDTH, Y * WIDTH]),
    hilo(N - 1, WIDTH, FILE).

%cluster is {probability, radius, {centreX, centreY}}

cluster(0, _WIDTH, FILE, _) -> file:close(FILE);
cluster(N, WIDTH, FILE, CLUSTER) ->
    {X, Y} = getGauss(),
    Q = random:uniform(),
    {P, R, {CX, CY}} = whichCluster(CLUSTER, Q),
    io:format(FILE, "~p\t~p~n",
	      [(X * R + CX) * WIDTH, (Y * R + CY) * WIDTH]),
    cluster(N - 1, WIDTH, FILE, CLUSTER).

getGauss() -> getGa(1, 0, 0).

getGa(WA, XA, YA) ->
    if WA >= 1 ->
	   X = 2 * random:uniform() - 1,
	   Y = 2 * random:uniform() - 1,
	   getGa(X * X + Y * Y, X, Y);
       true ->
	   W = math:sqrt(-2 * math:log(WA) / WA), {XA * W, YA * W}
    end.

whichCluster([{P, R, {CX, CY}} | TAIL], Q) ->
    if P > Q -> {P, R, {CX, CY}};
       true -> whichCluster(TAIL, Q - P)
    end.

%% Box-Muller transformation (to generate gauss-distributed data)
%%          float x1, x2, w, y1, y2;
%%
%%          do {
%%                  x1 = 2.0 * ranf() - 1.0;
%%                  x2 = 2.0 * ranf() - 1.0;
%%                  w = x1 * x1 + x2 * x2;
%%          } while ( w >= 1.0 );
%%
%%          w = sqrt( (-2.0 * ln( w ) ) / w );
%%          y1 = x1 * w;
%%          y2 = x2 * w;
%%

