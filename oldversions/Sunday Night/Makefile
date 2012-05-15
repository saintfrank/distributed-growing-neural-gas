.SUFFIXES: .erl .beam

.erl.beam:
	erlc -W $<

MODS = err_man win_man node input_gen engine

all: compile

compile: ${MODS:%=%.beam}

clean:
	rm -rf *.beam erl_crash.dump


	
