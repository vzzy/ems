%% @author bai
%% @doc @todo Add description to ems.


-module(ems).

%% ====================================================================
%% API functions
%% ====================================================================
-export([
	start/0,	 
		 
	jump_consistent_hash/2,
		
	add_ms/1,

	get_client_write/1,
	get_client_read/1,
	get_client_write/2,
	get_client_read/2
]).

%% 启动方法
start()->
	%% 含连接从节点过程。
	ok = start(?MODULE),
	ok.
%% 启动App
start(App) ->
    start_ok(App, application:start(App, permanent)).
start_ok(_App, ok) -> ok;
start_ok(_App, {error, {already_started, _App}}) -> ok;
start_ok(App, {error, {not_started, Dep}}) ->
    ok = start(Dep),
    start(App);
start_ok(App, {error, Reason}) ->
    erlang:error({aps_start_failed, App, Reason}).

%% JCH
jump_consistent_hash(KeyList, NumberOfBuckets)->
	ems_sup:jump_consistent_hash(KeyList, NumberOfBuckets).

%% 添加Master-Slave Pool
add_ms(Pools)->
	ems_sup:add_ms(Pools).

%% 获取Client
%% {ok,Pid} | {error,Reason}
get_client_write(Poolname)->
	ems_sup:get_client_write(Poolname).
get_client_read(Poolname)->
	ems_sup:get_client_read(Poolname).
get_client_write(Poolname,Key)->
	ems_sup:get_client_write(Poolname,Key).
get_client_read(Poolname,Key)->
	ems_sup:get_client_read(Poolname,Key).
