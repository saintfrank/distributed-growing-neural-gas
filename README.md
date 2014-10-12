An distributed implementation of the Growing Neural Gas algorithm
====

An Erlang implementation that adds distribution and parallelization to the famous algorithm from "A growing Neural gas Network Learns Topologies" by Bernd Fritze.


How it works
====

The algorithm is decomposed in 3 main task:
– Winner election
– Neighbourhood updates
– Error analysis and network Growth

Two different tree strucutres connect the nodes and work in parallel:
– win_man, performing the winner election.
– err_man, performing the max_error decision and controlling the tree growth

These two trees will always have the same network representation.
err_man performs the addition or deletion of leaf nodes and intermediate
nodes. Every time this happens this is communicated to win_man which
will update its structure accordingly. 


Requirements
====

- Erlang 
- gnuplot
- linux


Usage
====


