#PICAXE 40X2

symbol HSBAUD=B9600_40       	'baud rate for high speed port
symbol Address = %10100000    'I2C address
symbol POLLSLAVES = C.5       'pin used to get i2c slave addresses
symbol packetSize = 9		'packet size received by transmitter
symbol ShiftRegisterCount = 8 'number of shift registers per picaxe
symbol ScratchpadSize = 1023


symbol configurationMode = bit0  'occupies space for b0
symbol found = bit1 'occupies space for b0
symbol counter  = b2
symbol slaveAddress = b3
symbol HserNewDiff = b9
symbol slaveCount = b28


init: 
	SetFreq em40
	hsersetup HSBAUD, %01       'start the hardware serial port background recieve
	hi2csetup i2cmaster, Address, i2cfast_16, i2cbyte
	setint %00000010,%00000010,C 'activate interrupt on c1 signal (can be set between c0-c7)
	slaveCount = 0


main:
	HserNewDiff = HserPtr - ptr	
	
	if HserNewDiff < 0 then
	  HserNewDiff = ScratchpadSize + HserNewDiff	
	endif		
	
	if HserNewDiff =>  packetSize then 'if new packet received then	
		gosub checkSlaves    	     'check if packet contains slave address which this router is connected to
		if found is 1 then		'if found then
			gosub sendToSlave		'send the data to the slave module
		else
			ptr = ptr + packetSize		'else forward the pointer by the packet size to skip data
		endif	  
	endif 	
goto main


'interrupt to send i2c slave address to router
interrupt:
	do     'loop until pin C.1 is switched off
		if configurationMode is 0 then
			slaveCount = 0   'reset salve modules count
			bptr = 28	     'set module address pointer back to 28
			configurationMode = 1 'set configuration flag to 1 to stop resetting init variables
			pulsout POLLSLAVES ,65535 'send signal to slave modules to send back their address
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
		
	configurationMode = 0   'set back configuration flag to 0 for possible reconfiguration
	setint %00000010,%00000010 're-activate interrupt on pin C.1
return


checkSlaves:
	counter = 1    'reset counter to 1
	bptr = 28	   'set module address pointer back to 28	
	found = 0	   'reset found flag
	
	do 'loop until all slave addresses have been parsed
	  if @bptrinc != @ptr then 'if the received slave address not equal to one stored in the peek/poke memory then
	  	inc counter          'increment counter
	  else			   'if salve address found then
	  	found = 1		   'then set found flag to 1
	  	counter = slaveCount	'set counter equal to slave count to stop looping
	  endif
	loop while counter < slaveCount	
return


sendToSlave:
	slaveAddress = @ptrinc	'get slave address received by packet
	counter = 1			'reset counter to 1
	do				' loop until all 8 bytes have been processed
		hi2cout [slaveAddress],(@ptrinc) 'send value byte to scratchpad in slave address
		inc counter				   'increment counter
	loop while counter < ShiftRegisterCount
return
