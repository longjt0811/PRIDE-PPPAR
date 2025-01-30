!! GOOD   -0- not AMB BAD DEL NODATA.
!! OLDAMB -1- ambiguity flag from LOG file
!! NEWAMB -2- newly found ambiguity  
!! NEWBAD -3- temporerily used in check_jump
!! DELBAD -4- removed because of large residual. 
!! DELSHT -5- removed as short piece
!! DELLOW -6- removed due to low elevations 
!! NODATA -10- no data
integer*4, parameter :: GOOD=0, OLDAMB=1, NEWAMB=2
integer*4, parameter :: NEWBAD=3, DELBAD=4
integer*4, parameter :: DELSHT=5, DELLOW=6
integer*4, parameter :: DELORB=7, DELCLK=8, DELBIA=9
integer*4, parameter :: NODATA=10
