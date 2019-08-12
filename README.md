ems
=====

An OTP application

Build
-----

    $ rebar3 compile
    $ rebar3 shell
    
    ems:jump_consistent_hash(0,999).
    ems:add_ms([]).
    ems:get_client_write(pool,<<"a">>).
    ems:get_client_read(pool,<<"a">>).
    
    %% 获取第一个Partion
    ems:get_client_write(pool).
    ems:get_client_read(pool).
    

Conf
-----    
    [
	  {ems, [
	  	{Poolname,{Poolsize,M,F,[
			{
			  [
			  	M_Args
			  ],
			  
			  [
			  	S_Args
			  ]
			}
		]}}
		
	  ]}
	].
	    
