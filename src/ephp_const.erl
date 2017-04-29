-module(ephp_const).
-author('manuel@altenwald.com').
-compile([warnings_as_errors]).

-include("ephp.hrl").

%% ------------------------------------------------------------------
%% API Function Exports
%% ------------------------------------------------------------------

-export([
    start_link/0,
    get/4,
    set/3,
    set_bulk/2,
    destroy/1
]).

%% ------------------------------------------------------------------
%% API Function Definitions
%% ------------------------------------------------------------------

start_link() ->
    Ref = make_ref(),
    Init = [
        {<<"__FILE__">>, <<>>}
    ],
    Consts = lists:foldl(fun({K,V},C) ->
        dict:store(K,V,C)
    end, dict:new(), Init),
    erlang:put(Ref, Consts),
    Modules = ephp_config:get(modules, []),
    [ set_bulk(Ref, Module:init_const()) || Module <- Modules ],
    {ok, Ref}.

get(Ref, Name, Line, Context) ->
    Const = erlang:get(Ref),
    case dict:find(Name, Const) of
        {ok, Value} ->
            Value;
        error when Line =/= false ->
            File = ephp_context:get_active_file(Context),
            ephp_error:handle_error(Context,
                {error, eundefconst, Line, File, ?E_NOTICE, {Name}}),
            Name;
        error ->
            false
    end.

set_bulk(Ref, Values) ->
    erlang:put(Ref, lists:foldl(fun({Name, Value}, Const) ->
        dict:store(Name, Value, Const)
    end, erlang:get(Ref), Values)).

set(Ref, Name, Value) ->
    Const = erlang:get(Ref),
    erlang:put(Ref, dict:store(Name, Value, Const)),
    ok.

destroy(Const) ->
    erlang:erase(Const),
    ok.
