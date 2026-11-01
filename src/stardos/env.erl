-module(stardos_env_ffi).

-export([runtime/0]).

runtime() ->
    {erlang, <<(stringarg(bindir))/binary, "/", (stringarg(progname))/binary>>}.