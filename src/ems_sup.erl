%%%-------------------------------------------------------------------
%% @doc ems top level supervisor.
%% @end
%%%-------------------------------------------------------------------

-module(ems_sup).

-behaviour(supervisor).

%% API
-export([
	start_link/0,
	
	add_ms/1,
	stop_ms/1,
	
	jump_consistent_hash/2,
	
	get_client_write/1,
	get_client_read/1,
	get_client_write/2,
	get_client_read/2
]).

%% Supervisor callbacks
-export([init/1]).

-define(SERVER, ?MODULE).

%%====================================================================
%% API functions
%%====================================================================

start_link() ->
    supervisor:start_link({local, ?SERVER}, ?MODULE, []).

%%====================================================================
%% Supervisor callbacks
%%====================================================================

%% Child :: {Id,StartFunc,Restart,Shutdown,Type,Modules}
init([]) ->
    ets:new(ems, [named_table, public]),
	Pools0 = application:get_all_env(ems),
    Pools = proplists:delete(included_applications, Pools0),
	add_ms(Pools),
    {ok, { {one_for_one, 1000, 3600}, []} }.


%% 添加pools
add_ms(Pools)->
	lists:foreach(fun ({PoolName,{PoolSize,M,F,Args}}) ->
		stop_ms(PoolName),
		Partition = lists:foldl(fun({M_Args,S_Args},Temp_Partition)-> 
			M_Pool_name = get_pool_name_write(PoolName,Temp_Partition),
			M_MFAs = [{M,F,[A]} || A <-M_Args],
			S_Pool_name = get_pool_name_read(PoolName,Temp_Partition),
			S_MFAs = [{M,F,[A]} || A <-S_Args],
			
			{ok,_Pid_M} = epool:add_pool(M_Pool_name,PoolSize,M_MFAs,[M]),
			{ok,_Pid_S} = epool:add_pool(S_Pool_name,PoolSize,S_MFAs,[M]),
			
			Temp_Partition + 1						
		end,0,Args),							 
		ets:insert(ems, {PoolName, Partition})
    end,Pools),
	ok.
%% 停止pools
stop_ms(PoolName)->
	case ets:lookup(ems, PoolName) of
		[{PoolName, Partition}] ->
			lists:foreach(fun(I)-> 
				M_Pool_name = get_pool_name_write(PoolName,I-1),
				S_Pool_name = get_pool_name_read(PoolName,I-1),	
				epool:stop_pool(M_Pool_name),
				epool:stop_pool(S_Pool_name)
			end,lists:seq(1,Partition)),
			ok;
		_ ->
			ok
	end.

%% pool name
get_pool_name_write(PoolName,Partition)->
	list_to_atom(lists:concat([PoolName,"_write_",Partition])).
get_pool_name_read(PoolName,Partition)->
	list_to_atom(lists:concat([PoolName,"_read_",Partition])).

%% 获取读写Client
get_client_write(Poolname)->
	Pool_name_wirte = get_pool_name_write(Poolname,0),
	epool:get_worker(Pool_name_wirte).
get_client_write(Poolname,Key)->
	case get_buckets(Poolname) of
		{ok,Buckets}->
			Partition = jump_consistent_hash(Key, Buckets),
			Pool_name_wirte = get_pool_name_write(Poolname,Partition),
			epool:get_worker(Pool_name_wirte);
		R->
			R
	end.

get_client_read(Poolname)->
	Pool_name_read = get_pool_name_read(Poolname,0),
	case epool:get_worker(Pool_name_read) of
		{ok,Pid}->
			{ok,Pid};
		_-> %% 读不存在，用写
			Pool_name_wirte = get_pool_name_write(Poolname,0),
			epool:get_worker(Pool_name_wirte)
	end.
get_client_read(Poolname,Key)->
	case get_buckets(Poolname) of
		{ok,Buckets}->
			Partition = jump_consistent_hash(Key, Buckets),
			Pool_name_read = get_pool_name_read(Poolname,Partition),
			case epool:get_worker(Pool_name_read) of
				{ok,Pid}->
					{ok,Pid};
				_-> %% 读不存在，用写
					Pool_name_wirte = get_pool_name_write(Poolname,Partition),
					epool:get_worker(Pool_name_wirte)
			end;
		R->
			R
	end.

%% 获取桶大小
get_buckets(PoolName)->
	case ets:lookup(ems, PoolName) of
		[{PoolName, Buckets}] ->
			{ok,Buckets};
		_ ->
			{error,<<"not exist">>}
	end.

%% Jump-consistent hashing.
%% OTP 19.3 does not support exs1024s
%% return int [0,NumberOfBuckets)
-define(SEED_ALGORITHM, exs1024).
jump_consistent_hash(_Key, 1) ->
    0;
jump_consistent_hash(KeyList, NumberOfBuckets) when is_list(KeyList) ->
    jump_consistent_hash(hd(KeyList), NumberOfBuckets);
jump_consistent_hash(Key, NumberOfBuckets) when is_integer(Key) ->
    SeedState = rand:seed_s(?SEED_ALGORITHM, {Key, Key, Key}),
    jump_consistent_hash_value(-1, 0, NumberOfBuckets, SeedState);
jump_consistent_hash(Key, NumberOfBuckets) ->
    jump_consistent_hash(erlang:phash2(Key), NumberOfBuckets).
jump_consistent_hash_value(B, J, NumberOfBuckets, _SeedState) when J >= NumberOfBuckets ->
    B;
jump_consistent_hash_value(_B0, J0, NumberOfBuckets, SeedState0) ->
    B = J0,
    {R, SeedState} = rand:uniform_s(SeedState0),
    J = trunc((B + 1) / R),
    jump_consistent_hash_value(B, J, NumberOfBuckets, SeedState).





