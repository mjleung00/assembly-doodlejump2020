# Doodle Jump Attempt #1 lol

  #################################################################################################################
 ######                                        V A R I A B L E S                                            ######
#################################################################################################################
.data

# Screen Variables 
displayBuffer:		.space 4096		# allocate memory for buffer to use for rendering
screenHeight: 		.word 32		# maximum X and Y coordinates of the 256x256 display with 8x8 pixels
screenWidth: 		.word 32

# Colors
backgroundColour:  	.word 0x0082c6ff     	# colour constant for background (paleskyblue)
doodleColour:      	.word 0x00e459e8      	# colour constant for Doodler sprite (brightpink)
doodleEyeColour:  	.word 0x00c2d8e5	# colour constant for Doodler eye to indicate direction (bluegrey)
platformColour:   	.word 0x0035ac4b      	# colour constant for default platforms (grassgreen)

# Game variables
updateSpeed: 		.word 10		# used as input to Sleep command, determines how long before doodler pos. is updated
keyLeft:		.word 0x106		# ASCII code for j, indicating left input
keyRight:		.word 0x107		# ASCII code for k, indicating right input

# Doodler Position Variables
spriteX: 		.word 16   		# X coordinate of central pixel of Doodler sprite
spriteY:		.word 28		# Y coordinate of central pixel of Doodler sprite
xyDirection:    	.word 0x106		# ASCII code for j, inital lateral direction is facing left
xSpeed:			.word 0			# holds lateral direction, positive for right, neg for left; initially 0
ySpeed:			.word 1			# holds vertical direction, positive for up, neg for down; initially going up  [-1, 1]

# Platform Position Variables
platformArrayX:		.space 16		# array to hold the X values of 4 platforms
platformArrayY:		.space 16		# array to hold the Y values of 4 platforms

  #################################################################################################################
 ######                                           C O D E ! ! !                                             ######
#################################################################################################################
.text  # actual code

main: 

####################################    INITIAL SETUP OF SCREEN    ################################################
# Initialize the background by filling the whole thing in
lw $a0, backgroundColour
lw $a1, screenHeight
la $s7, displayBuffer		# set $s7 to address of displayBuffer to be used in future
mul $a2, $a1, $a1 		# assign $a2 the number of pixels on screen by multiplying dimensions
mul $a2, $a2, 4 		# obtain relative address of final bottom-right coord so we know when its done drawing
add $a2, $a2, $s7 		# $a2 is now the final address in the buffer for bottom-right pixel
move $a1, $s7 			# redefine $a1 as displayBuffer address for incremental use when drawing

# draws the background: <$a0>: background colour <$a1>: initial address of buffer  <$a2>: final address of buffer
DrawBGLoop:
	beq $a1, $a2, InitialSprite	# while $a1 (current coord being drawn) is != $a2 (coord of last pixel), do the following:
	sw $a0, 0($a1) 			# give the current pixel denoted by $a1 the BG colour held in $a0
	addiu $a1, $a1, 4 		# increment counter
	j DrawBGLoop
	
# Draw initial position of Doodler at central-bottom
InitialSprite:
	jal DrawSprite			# call DrawSprite function with default values to draw initial Doodler

# Draw initial platform beneath initial Doodler, called Home :)
InitialPlatformHome:
	# centre of platform
	lw $a0, spriteX 		# load X coord of initialSprite
	lw $a1, spriteY	 		# load Y coord of initialSprite
	add $a1, $a1, 2			# shift down 2 rows to get below the feet
	jal GetCoordAddress 		# convert XY to bitmap coords
	move $a0, $v0 			# copy coordinates to $a0
	lw $a1, platformColour 		# store color into $a1
	jal Draw			# draw color at pixel

	# left side
	lw $a0, spriteX 		# load X coord of initialSprite
	lw $a1, spriteY	 		# load Y coord of initialSprite
	add $a1, $a1, 2			# shift down 2 rows to get below the feet
	add $a0, $a0, -1 		# shift left 1 column
	jal GetCoordAddress 		# convert XY to bitmap coords
	move $a0, $v0 			# copy coordinates to $a0
	lw $a1, platformColour 		# store color into $a1
	jal Draw			# draw color at pixel
	
	lw $a0, spriteX 		# load X coord of initialSprite
	lw $a1, spriteY	 		# load Y coord of initialSprite
	add $a1, $a1, 2			# shift down 2 rows to get below the feet
	add $a0, $a0, -2 		# shift left 2 columns
	jal GetCoordAddress 		# convert XY to bitmap coords
	move $a0, $v0 			# copy coordinates to $a0
	lw $a1, platformColour 		# store color into $a1
	jal Draw			# draw color at pixel
	
	# right side
	lw $a0, spriteX 		# load X coord of initialSprite
	lw $a1, spriteY	 		# load Y coord of initialSprite
	add $a1, $a1, 2			# shift down 2 rows to get below the feet
	add $a0, $a0, 1 		# shift left 1 column
	jal GetCoordAddress 		# convert XY to bitmap coords
	move $a0, $v0 			# copy coordinates to $a0
	lw $a1, platformColour 		# store color into $a1
	jal Draw			# draw color at pixel
	
	lw $a0, spriteX 		# load X coord of initialSprite
	lw $a1, spriteY	 		# load Y coord of initialSprite
	add $a1, $a1, 2			# shift down 2 rows to get below the feet
	add $a0, $a0, 2 		# shift left 2 columns
	jal GetCoordAddress 		# convert XY to bitmap coords
	move $a0, $v0 			# copy coordinates to $a0
	lw $a1, platformColour 		# store color into $a1
	jal Draw			# draw color at pixel

# Draw 4 initial platforms, randomly generated
InitialRandomPlatform:
	la $t0, platformArrayX		# load address of platformArrayX  and Y so they can be accessed and modified
	la $t1, platformArrayY
	add $t3, $t0, 16		# stop value for address

	PlatformLoop:
		li $v0, 42			# syscall for RNG with bound
		li $a1, 28			# bound $a0: [0, 28)
		syscall
		addiu $a0, $a0, 2		# add 2 in case $a0 is 0, so platform isn't outside border
		sw $a0, ($t0)			# store x val into appropriate slot
		move $t4, $t0			
		addiu $t0, $t0, 4		# increment address
	
		li $a1, 4			# bound $a0: [0, 4)
		syscall 
		addiu $a0, $a0, 5		# add 5 so y-dist between platforms is between 5 and 8 pixels
		sw $a0, ($t1)			# store y val into appropriate slot
		addiu $t1, $t1, 4		# increment address
		bne $t4, $t3, PlatformLoop  	# if we have not stored enough platforms, loop
	
	jal DrawPlatform			# draw platforms stored in platformArrayX and platformArrayY

jal BufferToDisplay			# update the bitmap display to show initial setup
	
###########################   Get user input from keyboard   ##################################################
GetInput:
	lw $a0, updateSpeed			# small nap
	jal Sleep
	
	# get input from keyboard
	lw $a0, xyDirection			# $a0 holds lateral direction value
	lw $t0, 0xffff0000			# $t0 should be 1 if input, 0 otherwise
	beqz $t0, UpdateSprite			# no new input so same direction
	lw $a1, 0xffff0004			# $a1 now holds new keyboard input, valid or not
	
	bne $a1, $a0, CheckValidDirection	# if input direction is not equal to current direction, check if its valid first
	
	# input is equal to same direction so update Doodler position accordingly
	la $t0, xSpeed				# give $t0 xSpeed data address
	lw $t1, 0($t0)				# give $t1 xSpeed value
	beq $t1, 0x106, Left
		add $t1, $t1, 1			# going right so accelerate right more
		Left:
		add $t1, $t1, -1		# going left so accelerate left more	
	sw $t1, 0($t0)				# store updated xSpeed	
	j UpdateSprite


CheckValidDirection:
	beq $a1, 0x106, ChangeRightToLeft  	# if input direction is left, continue to ChangeRightToLeft
	beq $a1, 0x107, ChangeLeftToRight	# if input direction is right, continue to ChangeLeftToRight
	j UpdateSprite				#else, $a1 is invalid input but we treat this as no input (i.e. continue in same direction)

ChangeRightToLeft:
	la $t0, xyDirection		# load address of xyDirection into $t0 so we can modify its value
	sw $a1, 0($t0)			# move left value (106) into address for xyDirection
	la $t1, xSpeed			# load address of xSpeed into $t1 so we can modify its value
	lw $t2, xSpeed			# load value of xSpeed into $t2 so we can use it for calculations
	subi $t2, $t2, 1		# subtract 1 from the xSpeed (simulate leftward acceleration)
	sw $t2, 0($t1)			# move updated xSpeed value into xSpeed address
	j UpdateSprite

ChangeLeftToRight:
	la $t0, xyDirection		# load address of xyDirection into $t0 so we can modify its value
	sw $a1, 0($t0)			# move right value (107) into address for xyDirection
	la $t1, xSpeed			# load address of xSpeed into $t1 so we can modify its value
	lw $t2, xSpeed			# load value of xSpeed into $t2 so we can use it for calculations
	addi $t2, $t2, 1		# add 1 to the xSpeed (simulate rightward acceleration)
	sw $t2, 0($t1)			# move updated xSpeed value into xSpeed address
	j UpdateSprite

# updates the central Doodler pixel according to xSpeed <$a0>, ySpeed <$a1>
UpdateSprite:			
	lw $a0, xSpeed			# give $a0 xSpeed value for future use
	lw $a1, ySpeed			# load ySpeed value
	lw $a2, spriteX			# load X and Y coordinates of central pixel of Doodler
	lw $a3, spriteY 	
	
	beq $a0, 106, FaceLeft		# if the xyDirection is left, jump there. otherwise, it's facing right and so:
	
	
	FaceLeft:
		


  #################################################################################################################
 ######                                       H E L P E R R S ! ! !                                         ######
#################################################################################################################

DrawPlatform:
	addiu $sp, $sp, -4		# allocate stack space for a word
	sw $ra, 0($sp)			# save return address out of DrawSprite
	
	la $t0, platformArrayX		# load address of platformArrayX  and Y so they can be accessed and modified
	la $t1, platformArrayY
	add $t3, $t0, 16		# stop value for address

	DrawPlatformLoop:
		# centre pixel
		lw $a0, ($t0)			# store X value of platform into $a0
		lw $a1, ($t1)			# store Y value of platform into $a1
		jal GetCoordAddress		# convert XY to bitmap coords
		move $a0, $v0 			# copy coordinates to $a0
		lw $a1, platformColour 		# store color into $a1
		jal Draw			# draw color at pixel
		
		# left side
		lw $a0, ($t0)			# store X value of platform into $a0
		lw $a1, ($t1)			# store Y value of platform into $a1
		add $a0, $a0, -1 		# shift left 1 column
		jal GetCoordAddress 		# convert XY to bitmap coords
		move $a0, $v0 			# copy coordinates to $a0
		lw $a1, platformColour 		# store color into $a1
		jal Draw			# draw color at pixel
	
		lw $a0, ($t0)			# store X value of platform into $a0
		lw $a1, ($t1)			# store Y value of platform into $a1
		add $a0, $a0, -2 		# shift left 2 columns
		jal GetCoordAddress 		# convert XY to bitmap coords
		move $a0, $v0 			# copy coordinates to $a0
		lw $a1, platformColour 		# store color into $a1
		jal Draw			# draw color at pixel
		
		# right side
		lw $a0, ($t0)			# store X value of platform into $a0
		lw $a1, ($t1)			# store Y value of platform into $a1
		add $a0, $a0, 1 		# shift right 1 column
		jal GetCoordAddress 		# convert XY to bitmap coords
		move $a0, $v0 			# copy coordinates to $a0
		lw $a1, platformColour 		# store color into $a1
		jal Draw			# draw color at pixel
	
		lw $a0, ($t0)			# store X value of platform into $a0
		lw $a1, ($t1)			# store Y value of platform into $a1
		add $a0, $a0, 2 		# shift right 2 columns
		jal GetCoordAddress 		# convert XY to bitmap coords
		move $a0, $v0 			# copy coordinates to $a0
		lw $a1, platformColour 		# store color into $a1
		jal Draw			# draw color at pixel
		
		move $t4, $t0			
		addiu $t0, $t0, 4		# increment X address
		addiu $t1, $t1, 4		# increment Y address
		bne $t4, $t3, DrawPlatformLoop

	DoneDrawPlatform:
	lw $ra, 0($sp)			# load return address out of DrawSprite from stack
	addiu $sp, $sp, 4		# refill $sp
	jr $ra				# return
	

###################################################################################################################

DrawSprite: 				# draws the whole Doodler to buffer according to spriteX <$a0>, spriteY <$a1>, xyDirection <$a2> 
	addiu $sp, $sp, -4		# allocate stack space for a word
	sw $ra, 0($sp)			# save return address out of DrawSprite
	
	# draw initial central pixel
	lw $a0, spriteX 		# load X coord
	lw $a1, spriteY	 		# load Y coord
	jal GetCoordAddress 		# convert XY to bitmap coords
	move $a0, $v0 			# copy coordinates to $a0
	lw $a1, doodleColour 		# store color into $a1
	jal Draw			# draw color at pixel
	
	#draw top row
	lw $a0, spriteX 		# load X coord
	lw $a1, spriteY 		# load Y coord
	add $a0, $a0, -1 		# shift left 1 column for forehead
	add $a1, $a1, -1 		# shift up 1 row for forehead
	jal GetCoordAddress 		# convert XY to bitmap coords
	move $a0, $v0 			# copy coordinates to $a0
	lw $a1, doodleColour 		# store color into $a1
	jal Draw			# draw color at pixel
	
	lw $a0, spriteX 		# load X coord
	lw $a1, spriteY 		# load Y coord
	add $a1, $a1, -1 		# shift up 1 row for forehead
	jal GetCoordAddress 		# convert XY to bitmap coords
	move $a0, $v0 			# copy coordinates to $a0
	lw $a1, doodleColour 		# store color into $a1
	jal Draw			# draw color at pixel

	#draw bottom row
	lw $a0, spriteX 		# load X coord
	lw $a1, spriteY 		# load Y coord
	add $a1, $a1, 1			# shift down 1 row
	add $a0, $a0, -1 		# shift left 1 column for left foot
	jal GetCoordAddress 		# convert XY to bitmap coords
	move $a0, $v0 			# copy coordinates to $a0
	lw $a1, doodleColour 		# store color into $a1
	jal Draw			# draw color at pixel
	
	lw $a0, spriteX 		# load X coord
	lw $a1, spriteY 		# load Y coord
	add $a1, $a1, 1			# shift down 1 row
	add $a0, $a0, 1 		# shift right 1 column for right foot
	jal GetCoordAddress 		# convert XY to bitmap coords
	move $a0, $v0 			# copy coordinates to $a0
	lw $a1, doodleColour 		# store color into $a1
	jal Draw			# draw color at pixel
	
	#draw middle row
	lw $t5, keyRight
	beq $a2, $t5, DrawRight	# if xyDirection is right, draw the doodler facing right in drawRight branch.
	# left-facing doodler	
		lw $a0, spriteX 		# load X coord
		lw $a1, spriteY 		# load Y coord
		add $a0, $a0, -1 		# shift left 1 column for eye
		jal GetCoordAddress 		# convert XY to bitmap coords
		move $a0, $v0 			# copy coordinates to $a0
		lw $a1, doodleEyeColour 	# store color into $a1
		jal Draw			# draw color at pixel
	
		lw $a0, spriteX 		# load X coord
		lw $a1, spriteY 		# load Y coord
		add $a0, $a0, 1 		# shift left 1 column for back of body
		jal GetCoordAddress 		# convert XY to bitmap coords
		move $a0, $v0 			# copy coordinates to $a0
		lw $a1, doodleColour 		# store color into $a1
		jal Draw			# draw color at pixel
		
		j DoneDrawSprite		# prepare to go away
	# right-facing doodler
	DrawRight:
		lw $a0, spriteX 		# load X coord
		lw $a1, spriteY 		# load Y coord
		add $a0, $a0, 1 		# shift right 1 column for eye
		jal GetCoordAddress 		# convert XY to bitmap coords
		move $a0, $v0 			# copy coordinates to $a0
		lw $a1, doodleEyeColour 	# store color into $a1
		jal Draw			# draw color at pixel
	
		lw $a0, spriteX 		# load X coord
		lw $a1, spriteY 		# load Y coord
		add $a0, $a0, -1 		# shift left 1 column for back of body
		jal GetCoordAddress 		# convert XY to bitmap coords
		move $a0, $v0 			# copy coordinates to $a0
		lw $a1, doodleColour 		# store color into $a1
		jal Draw			# draw color at pixel
	
	DoneDrawSprite:
	lw $ra, 0($sp)			# load return address out of DrawSprite from stack
	addiu $sp, $sp, 4		# refill $sp
	jr $ra				# return

###################################################################################################################

BufferToDisplay:		# updates the $gp display by copying contents of the Buffer over
	addiu $sp, $sp, -4		# allocate stack space for a word
	sw $ra, 0($sp)			# save return address out of DrawSprite

	move $t0, $s7		# load $t0 with address for start of buffer
	addiu $t1, $t0, 4096	# load $t1 with address for last pixel of buffer
	add $t2, $gp, $zero	# load $t2 with address for start of bitmap display
	li $t3, 0		# $t3 is the incrememnt for the data addresses
	
	UpdateDisplayLoop:
		add $t5, $t0, $t3	# increment the data address of buffer
		add $t6, $t2, $t3	# increment the data address of bitmap display
		addiu $t3, $t3, 4	# incrememnt the counter
		
		lw $t4, ($t5)		# copy content of buffer
		sw $t4, ($t6)		# into bitmap display
	
		beq $t3, 4096, DoneUpdateDisplay	# if we have reached the increment of 4096, we have updated the whole bitmap and can stop looping
		j UpdateDisplayLoop
	
	DoneUpdateDisplay:
	lw $ra, 0($sp)			# load return address out of DrawSprite from stack
	addiu $sp, $sp, 4		# refill $sp
	jr $ra				# return
	
	

###################################################################################################################

GetCoordAddress:  		# inputs: $a0 <x coord>; $a1 <y coord>;     outputs: $v0 <bitmap address>
	lw $v0, screenWidth 	# give $v0 value of # of rows in screen
	mul $v0, $v0, $a1	# multiply y coord by screenWidth to get row number
	add $v0, $v0, $a0	# add x coord to $v0 to obtain square number 
	mul $v0, $v0, 4		# multiply square number by 4 to obtain relative address distance
	add $v0, $v0, $s7	# add buffer address to get bitmap coord relative to buffer start
	jr $ra			# return to function call location

###################################################################################################################

Draw:
	sw $a1, ($a0) 	# give the coordinate in $a0 the color value in $a1
	jr $ra		# return

###################################################################################################################
			
Sleep:			# give the doodler a little nap
	li $v0, 32 	# syscall sleep with code 32, sleeps for the value in $a0  <<can use this to include acceleration later>>
	syscall
	jr $ra		# return to call location

###################################################################################################################
###################################################################################################################

Exit:
li $v0, 10 # terminate the program gracefully
syscall
