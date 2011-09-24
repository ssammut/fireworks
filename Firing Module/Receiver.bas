#PICAXE 40X2

symbol HSBAUD=B9600_40       	'baud rate for high speed port
symbol CLOCK = B.1 		'clock for all registers
symbol LATCH = D.0		'latch for all registers
symbol MASK = %01111111		'mask to determine next bit
symbol ShiftRegisterCount = 8 'number of shift registers per picaxe
symbol ScratchpadSize = 1023

'shift registers
symbol DataOut_1 = A.1
symbol DataOut_2 = A.3
symbol DataOut_3 = A.6
symbol DataOut_4 = B.0
symbol DataOut_5 = B.2
symbol DataOut_6 = B.4
symbol DataOut_7 = B.6
symbol DataOut_8 = C.0

'the signal received by the xbee
symbol RegData1 = b1
symbol RegData2 = b2
symbol RegData3 = b3
symbol RegData4 = b4
symbol RegData5 = b5
symbol RegData6 = b6
symbol RegData7 = b7
symbol RegData8 = b8

symbol HserNewDiff = b9


init: hsersetup HSBAUD, %001       'start the hardware serial port background recieve
	SetFreq em40
	Low LATCH
	Low CLOCK
	Low DataOut_4		

main:		
	HserNewDiff = HserPtr - ptr	
	
	if HserNewDiff < 0 then
	  HserNewDiff = ScratchpadSize + HserNewDiff	
	endif		
	
	if HserNewDiff =>  ShiftRegisterCount then			
		gosub XbeeEventHandle		  
	endif 	
goto main

'triggered when data is received
XbeeEventHandle:

	'read data from scratch pad
    	RegData1 = @ptrinc
   	RegData2 = @ptrinc
   	RegData3 = @ptrinc
    	RegData4 = @ptrinc
    	RegData5 = @ptrinc
      RegData6 = @ptrinc
    	RegData7 = @ptrinc
    	RegData8 = @ptrinc		    		
	
	gosub Send_to_Registers		
return


'output data to shift registers
Send_to_Registers:

for b0 = 1 to 8
	
	
	    if RegData1 > MASK then 'check if the 8th bit is set
	        high DataOut_1
	    else
	        low DataOut_1
	    endif
	    
	    
	    if RegData2 > MASK then 'check if the 8th bit is set
	        high DataOut_2
	    else
	        low DataOut_2
	    endif
    	    
	    	    
	    if RegData3 > MASK then 'check if the 8th bit is set
	        high DataOut_3
	    else
	        low DataOut_3
	    endif
	    
	    
	    if RegData4 > MASK then 'check if the 8th bit is set
	        High DataOut_4
	    else
	        Low DataOut_4
	    endif
	    
	    
	    if RegData5 > MASK then 'check if the 8th bit is set
	        high DataOut_5
	    else
	        low DataOut_5
	    endif
   
	    
	    if RegData6 > MASK then 'check if the 8th bit is set
	        high DataOut_6
	    else
	        low DataOut_6
	    endif

	    
	    if RegData7 > MASK then 'check if the 8th bit is set
	        high DataOut_7
	    else
	        low DataOut_7
	    endif
	    

    	    if RegData8 > MASK then 'check if the 8th bit is set
	        high DataOut_8
	    else
	       low DataOut_8
	    endif
	    
	    
	    'pulse clock to shift registers	    
    	    pulsout CLOCK , 2   
	    
	    'Shift bits left
	    RegData1 = RegData1 * 2 
	    RegData2 = RegData2 * 2 
	    RegData3 = RegData3 * 2 
	    RegData4 = RegData4 * 2 
	    RegData5 = RegData5 * 2 
	    RegData6 = RegData6 * 2 
	    RegData7 = RegData7 * 2 
	    RegData8 = RegData8 * 2 	    	    	    
	    
	next b0
	
	'flush shifter data
	pulsout LATCH , 2

return