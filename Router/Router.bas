#PICAXE 40X2

symbol HSBAUD=B9600_40       	'baud rate for high speed port
symbol Address = %10100000    'I2C address
symbol POLLSLAVES = C.5       'pin used to get i2c slave addresses
symbol packetSize = 9		'packet size received by transmitter
symbol ShiftRegisterCount = 8 'number of shift registers per picaxe


symbol ScratchpadSize = 1023

symbol slaveAddress = b3
symbol slaveCount = b28
symbol HserNewDiff = b9
symbol configurationMode = bit0  'occupies space for b0
symbol found = bit1 'occupies space for b0



init: 
	SetFreq em40
	hsersetup HSBAUD, %10       'start the hardware serial port background recieve
	hi2csetup i2cmaster, Address, i2cfast_16, i2cbyte
	setint %00000010,%00000010 'c1 signal (can be set between c0-c7)
	slaveCount = 0


main:		
	HserNewDiff = HserPtr - ptr	
	
	if HserNewDiff < 0 then
	  HserNewDiff = ScratchpadSize + HserNewDiff	
	endif		
	
	if HserNewDiff =>  packetSize then			
		gosub checkSlaves
		if found is 1 then
			gosub sendToSlave		
		else
			ptr = ptr + 9	
		endif	  
	endif 	
goto main


'interrupt to send i2c slave address to router
interrupt:
	do
		if configurationMode is 0 then
			slaveCount = 0   'reset salve modules count
			bptr = 28	     'set module address pointer back to 28
			configurationMode = 1 'set configuration flag to 1 to stop resetting init variables
			pulsout POLLSLAVES ,2 'send signal to slave modules to send back their address
		endif
		
		HserNewDiff = HserPtr - ptr	
		
		if HserNewDiff < 0 then
		  HserNewDiff = ScratchpadSize + HserNewDiff	
		endif		
		
		if HserNewDiff =>  1 then  'if new data exists then			
			@bptrinc = @ptrinc   'get data salve address and put in peek/poke memory
			inc slaveCount	   'increment slave count to keep record on the number of slave modules  
		endif 
	loop while pinC.1 is 1
		
	configurationMode = 0
return


checkSlaves:
	b2 = 1
	bptr = 28
	found = 0
	
	do
	  if @bptrinc != @ptr then
	  	inc b2
	  else
	  	found = 1
	  	b2 = 	slaveCount
	  endif
	loop while b2 < slaveCount	
return


sendToSlave:
	slaveAddress = @ptrinc
	b2 = 1
	do
		hi2cout [slaveAddress],(@ptrinc) 'send value 9 to scratchpad location10 in slave1
		inc b2
	loop while b2 < ShiftRegisterCount
return





