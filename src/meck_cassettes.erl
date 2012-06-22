-module(meck_cassettes).
-behaviour(gen_server).
-export([use_cassette/2]).
-export([code_change/3,handle_call/3,handle_cast/2,handle_info/2,terminate/2,init/1]).

use_cassette(Name, Fun) ->
    meck:new(httpc, [unstick]),
    meck:expect(httpc,
                request,
                fun(Method, Request, HTTPOptions, Options) ->
                        Args = [Method, Request],
                        %% within .eunit directory
                        Fixture = "../test/fixtures/cassettes/" ++ Name,
                        io:format("Fixture = ~p~n", [Fixture]),
                        case file:read_file_info(Fixture) of
                            {error, enoent} ->
                                io:format("fixture doesn't exist~n",[]),
                                Response = httpc_meck_original:request(Method, Request, HTTPOptions, Options),
                                RequestCall = [{request, Args},
                                               {response, Response}],
                                io:format("going to write file: ~p while in: ~p~n", [Fixture, file:get_cwd()]),
                                ok = file:write_file(Fixture, term_to_binary(RequestCall)),
                                Response;
                            _ ->
                                io:format("reading fixture file..~n", []),
                                case file:read_file(Fixture) of
                                    {ok, ResponseBinary} ->
                                        ResponseCall = binary_to_term(ResponseBinary),
                                        proplists:get_value(response, ResponseCall);
                                    {error, Something} ->
                                        {error, Something}
                                end
                        end
                end),
    Response = Fun(),
    meck:unload(httpc),
    Response.

%% @hidden
code_change(_OldVsn, S, _Extra) -> {ok, S}.

%% @hidden
handle_call(_Something, _from, S) ->
    {noreply, S}.

%% @hidden
handle_cast(_Msg, S)  ->
    {noreply, S}.

%% @hidden
handle_info(_Info, S) -> {noreply, S}.

%% @hidden
terminate(_Reason, _State) ->
    ok.

%% @hidden
init([]) ->
    process_flag(trap_exit, true),
    {ok, []}.
