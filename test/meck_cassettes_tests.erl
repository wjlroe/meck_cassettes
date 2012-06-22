-module(meck_cassettes_tests).
-include_lib("eunit/include/eunit.hrl").
-compile(export_all).

use_cassette_test() ->
    application:start(inets),
    Name = "fold.me_count",
    FixtureName = "../test/fixtures/cassettes/" ++ Name,
    ?assertMatch({error, enoent}, file:read_file_info(FixtureName)),
    Response = meck_cassettes:use_cassette(Name,
                                           fun() ->
                                                   httpc:request(get, {"http://foldme.herokuapp.com/count",[]},[],[])
                                           end),
    application:stop(inets),
    ?assertMatch({ok, _}, file:read_file_info(FixtureName)),
    ?assertEqual(ok, file:delete(FixtureName)),
    ?assertMatch({ok, {{_, 200, _}, _, "{\"fold_count\""++_}}, Response).
