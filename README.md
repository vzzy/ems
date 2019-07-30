ems
=====

An OTP application

Build
-----

    $ rebar3 compile
    $ rebar3 shell
    
    ems:add_ms([]).
    ems:get_client_write(pool,<<"a">>).
    ems:get_client_read(pool,<<"a">>).
    

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
	    
