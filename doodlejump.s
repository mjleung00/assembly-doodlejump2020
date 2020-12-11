#####################################################################
#
# CSC258H5S Fall 2020 Assembly Final Project
# University of Toronto, St. George
#
# Student: Jiabao Michael Leung, 1003333671
#
# Bitmap Display Configuration:
# - Unit width in pixels: 8
# - Unit height in pixels: 8
# - Display width in pixels: 256
# - Display height in pixels: 256
# - Base Address for Display: 0x10008000 ($gp)
#
# Which milestone is reached in this submission?
# - Milestone 5? (choose the one the applies)
#
# Which approved additional features have been implemented?
# 1. sound effects (start sound, jumping off platforms, death sound, new high-score sound)
# 2. player names
# 3. realistic physics: acceleration and deceleration near apex of jump, as well as player-controlled lateral acceleration
#
# Any additional information that the TA needs to know:
# Implemented score-tracking with high-score functionality within the same program session. I wrote some code for displaying the score on-screen but
# it really didn't look so good so I decided not to add it... hopefully I have already adequately demonstrated that I know how to draw and redraw
# within the bitmap display, as well as store and update score values at the same time. Score is equivalent to the height gained by jumping, and
# cannot decrease (i.e. jumping from a higher platform down to a lower one will not reduce your score).
#
#####################################################################

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
gameScore:		.word 0			# used to keep track of player score
currPlayer:		.space 20		# used to keep track of current player name
highScore:		.word 0			# used to keep track of highscore for the session
updateSpeed: 		.word 150		# used as input to Sleep command, determines how long before doodler pos. is updated
keyLeft:		.word 106		# ASCII code for j, indicating left input
keyRight:		.word 107		# ASCII code for k, indicating right input

# Doodler Position Variables
spriteX: 		.word 16   		# X coordinate of central pixel of Doodler sprite
spriteY:		.word 28		# Y coordinate of central pixel of Doodler sprite
xyDirection:    	.word 106		# ASCII code for j, inital lateral direction is facing left
xSpeed:			.word 0			# holds lateral direction, positive for right, neg for left; initially 0
ySpeed:			.word -1		# holds vertical direction, positive for down, neg for up; initially going up  [-1, 1]

# Platform Position Variables
platformArrayX:		.space 24		# array to hold the X values of 4 platforms
platformArrayY:		.space 24		# array to hold the Y values of 4 platforms

# other output Variables
getUserMessage:		.asciiz "Please enter your name in the console!"
gameStartPromptA:	.asciiz "Press OK to "
gameStartPromptB:	.asciiz "start game"
gameOverMessage:	.asciiz "Game Over! Your score: "
highScoreMessage:	.asciiz "Congrats! NEW HIGH SCORE: "
playAgainMessage:	.asciiz "Play Again?"

  #################################################################################################################
 ######                                           C O D E ! ! !                                             ######
#################################################################################################################
.text  # actual code

main: 
####################################    RESET REGISTERS/VARIABLES IF REPLAYING    ################################################
# variable reset
li $t0, 0
sw $t0, gameScore
sw $t0, xSpeed
li $t0, -1
sw $t0, ySpeed
li $t0, 150
sw $t0, updateSpeed
li $t0, 16
sw $t0, spriteX
li $t0, 28
sw $t0, spriteY
li $t0, 106
sw $t0, xyDirection

# register reset
li $t0, 0
li $t1, 0
li $t2, 0
li $t3, 0
li $t4, 0
li $t5, 0
li $t6, 0
li $t7, 0
li $s0, 0
li $s1, 0
li $s2, 0
li $s3, 0
li $s4, 0
li $s5, 0 
li $s6, 0
li $s7, 0
li $v0, 0
li $v1, 0
li $a0, 0
li $a1, 0
li $a2, 0
li $a3, 0

####################################    INITIAL SETUP OF SCREEN    ################################################
jal GameStart

# Initialize the background by filling the whole thing in
lw $a0, backgroundColour
lw $a1, screenHeight
la $s7, displayBuffer		# set $s7 to address of displayBuffer to be used in future
mul $a2, $a1, $a1 		# assign $a2 the number of pixels on screen by multiplying dimensions
mul $a2, $a2, 4 		# obtain relative address of final bottom-right coord so we know when its done drawing
add $a2, $a2, $s7 		# $a2 is now the final address in the buffer for bottom-right pixel
move $a1, $s7 			# redefine $a1 as displayBuffer address for incremental use when drawing

# scorekeeping initialization
li $s5, 30

# get player name

# draws the background: <$a0>: background colour <$a1>: initial address of buffer  <$a2>: final address of buffer
DrawBGLoop:
	beq $a1, $a2, InitialRandomPlatform	# while $a1 (current coord being drawn) is != $a2 (coord of last pixel), do the following:
	sw $a0, 0($a1) 				# give the current pixel denoted by $a1 the BG colour held in $a0
	addiu $a1, $a1, 4 			# increment counter
	j DrawBGLoop
	

# Draw 5 initial platforms, 4 are randomly generated and 1 is always under the initial Doodler
InitialRandomPlatform:
	la $t0, platformArrayX		# load address of platformArrayX  and Y so they can be accessed and modified
	la $t1, platformArrayY
	lw $a0, spriteX 		# load X coord of initialSprite
	lw $a1, spriteY	 		# load Y coord of initialSprite
	addiu $a1, $a1, 2
	sw $a0, ($t0)
	sw $a1, ($t1)
	addiu $t0, $t0, 4
	addiu $t1, $t1, 4
	add $t3, $t0, 16		# stop value for address

	PlatformLoop:
		li $v0, 42			# syscall for RNG with bound
		li $a0, 0         		# Select random generator 0
		li $a1, 28			# bound $a0: [0, 28)
		syscall
		addiu $a0, $a0, 2		# add 2 in case $a0 is 0, so platform isn't outside border
		sw $a0, ($t0)			# store x val into appropriate slot
		move $t4, $t0			
		addiu $t0, $t0, 4		# increment address

		li $v0, 42			# syscall for RNG with bound
		li $a0, 0          		# Select random generator 0
		li $a1, 3			# bound $a0: [0, 3)
		syscall
		addiu $a0, $a0, 6		# add 5 so y-dist between platforms is between 6 and 8 pixels

		la $t2, platformArrayY
		la $t5, platformArrayX
		addiu $t5, $t5, 4
		bne $t4, $t5, NotFirstPlatform	# if current platform being generated isn't the first in the array,

		FirstPlatform:
		lw $t6, ($t2)			# random reachable height of first RNG platform
		sub $a0, $t6, $a0
		j StorePlatformY
		
		NotFirstPlatform:
		sub $a0, $t7, $a0 
		
		StorePlatformY:
		sw $a0, ($t1)			# store y val into appropriate slot
		move $t7, $a0			# store y val for generation of next platform
		addiu $t1, $t1, 4		# increment address
		bne $t4, $t3, PlatformLoop  	# if we have not stored enough platforms, loop
	
	jal DrawPlatform			# draw platforms stored in platformArrayX and platformArrayY

# Draw initial position of Doodler at central-bottom
InitialSprite:
	jal DrawSprite			# call DrawSprite function with default values to draw initial Doodler

jal BufferToDisplay			# update the bitmap display to show initial setup

# initialize tracker for jumping
li $s6, 12
	
	

###############################################################################################################	
###########################             MAIN LOOP	     ##################################################   (sorry just makes it easier for me to see this myself)
###############################################################################################################	
###########################   Get user input from keyboard   ##################################################
GetInput:
	lw $a0, updateSpeed			# small nap
	jal Sleep
	
	# get input from keyboard
	lw $a0, xyDirection			# $a0 holds lateral direction value
	li $t0, 0xffff0000			# load address for keyboard input check
	lw $t1, ($t0)				# $t1 should be 1 if input, 0 otherwise
	beqz $t1, UpdateSprite			# no new input so same direction
	lw $a1, 4($t0)				# $a1 now holds new keyboard input, valid or not
	
	jal CheckValidDirection	# if input direction is not equal to current direction, check if its valid first
	
	# input is equal to same direction so update Doodler position accordingly
	la $t0, xSpeed				# give $t0 xSpeed data address
	lw $t1, 0($t0)				# give $t1 xSpeed value
	beq $t1, 106, Left
		add $t1, $t1, 1			# going right so accelerate right more
		Left:
		add $t1, $t1, -1		# going left so accelerate left more	
	sw $t1, 0($t0)				# store updated xSpeed	
	j UpdateSprite


CheckValidDirection:
	beq $a1, 106, ChangeRightToLeft  	# if input direction is left, continue to ChangeRightToLeft
	beq $a1, 107, ChangeLeftToRight	# if input direction is right, continue to ChangeLeftToRight
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

# updates the central Doodler pixel according to xSpeed and ySpeed
UpdateSprite:	
	lw $a0, spriteX 		# load X coord
	lw $a1, spriteY	 		# load Y coord
	li $t0, 10			# y-level at which we start scrolling the screen and not the doodler
	blt $t0, $a1, MoveSprite	# if below y = 10, move the sprite as usual
	
	MovePlatform:
	lw $a2, ySpeed			# load ySpeed
	la $t1, ySpeed
	li $t2, 0
	sw $t2, ($t1)			# set ySpeed to 0
	jal UpdatePlatform
	
	
	MoveSprite:
	jal DrawPlatform		
	EraseSprite:
		# erase initial central pixel
		lw $a0, spriteX 		# load X coord
		lw $a1, spriteY	 		# load Y coord
		jal GetCoordAddress 		# convert XY to bitmap coords
		move $a0, $v0 			# copy coordinates to $a0
		jal CheckErasePixel
	
		# erase top row
		lw $a0, spriteX 		# load X coord
		lw $a1, spriteY 		# load Y coord
		add $a0, $a0, -1 		# shift left 1 column for top left
		add $a1, $a1, -1 		# shift up 1 row for forehead
		jal GetCoordAddress 		# convert XY to bitmap coords
		move $a0, $v0 			# copy coordinates to $a0
		jal CheckErasePixel

		lw $a0, spriteX 		# load X coord
		lw $a1, spriteY 		# load Y coord
		add $a0, $a0, 1 		# shift right 1 column for top right
		add $a1, $a1, -1 		# shift up 1 row for forehead
		jal GetCoordAddress 		# convert XY to bitmap coords
		move $a0, $v0 			# copy coordinates to $a0
		jal CheckErasePixel
		
		lw $a0, spriteX 		# load X coord
		lw $a1, spriteY 		# load Y coord
		add $a1, $a1, -1 		# shift up 1 row for top middle
		jal GetCoordAddress 		# convert XY to bitmap coords
		move $a0, $v0 			# copy coordinates to $a0
		jal CheckErasePixel

		# erase bottom row
		lw $a0, spriteX 		# load X coord
		lw $a1, spriteY 		# load Y coord
		add $a1, $a1, 1			# shift down 1 row
		add $a0, $a0, -1 		# shift left 1 column for left foot
		jal GetCoordAddress 		# convert XY to bitmap coords
		move $a0, $v0 			# copy coordinates to $a0
		jal CheckErasePixel
	
		lw $a0, spriteX 		# load X coord
		lw $a1, spriteY 		# load Y coord
		add $a1, $a1, 1			# shift down 1 row
		add $a0, $a0, 1 		# shift right 1 column for right foot
		jal GetCoordAddress 		# convert XY to bitmap coords
		move $a0, $v0 			# copy coordinates to $a0
		jal CheckErasePixel
		
		lw $a0, spriteX 		# load X coord
		lw $a1, spriteY 		# load Y coord
		add $a1, $a1, 1			# shift down 1 row
		jal GetCoordAddress 		# convert XY to bitmap coords
		move $a0, $v0 			# copy coordinates to $a0
		jal CheckErasePixel
	
		# erase middle
		lw $a0, spriteX 		# load X coord
		lw $a1, spriteY 		# load Y coord
		add $a0, $a0, -1 		# shift left 1 column for eye
		jal GetCoordAddress 		# convert XY to bitmap coords
		move $a0, $v0 			# copy coordinates to $a0
		jal CheckErasePixel
	
		lw $a0, spriteX 		# load X coord
		lw $a1, spriteY 		# load Y coord
		add $a0, $a0, 1 		# shift left 1 column for back of body
		jal GetCoordAddress 		# convert XY to bitmap coords
		move $a0, $v0 			# copy coordinates to $a0
		jal CheckErasePixel
	
	jal CheckJump
	
	lw $a0, spriteX			# load X and Y coordinates of central pixel of Doodler
	lw $a1, spriteY 		
	lw $a2, xSpeed			# give $a0 xSpeed value for future use
	lw $a3, ySpeed			# load ySpeed value
	
	add $t0, $a0, $a2		# change X coord by xSpeed
	add $t1, $a1, $a3		# change Y coord by ySpeed
	
	la $t2, spriteX			# store updated X and Y coords into variable 
	la $t3, spriteY
	sw $t0, ($t2)
	sw $t1, ($t3)
	
jal checkCollision	
jal DrawSprite
jal BufferToDisplay
#jal ScoreCheckBG

j GetInput
		


  #################################################################################################################
 ######                                       H E L P E R R S ! ! !                                         ######
#################################################################################################################

checkCollision: 				# spriteX <$t0>, spriteY <$t1>
	addiu $sp, $sp, -4		# allocate stack space for a word
	sw $ra, 0($sp)			# save return address out of checkCollision
	
	la $t3, ySpeed
	lw $t4, ($t3)
	ble  $t4, $zero, DoneCheckCollision 	# return because no need to check collisions if Doodler is still on the way up.
	
	li $t3, 31
	ble $t3, $t1, GameOver			# if the sprite is touching the bottom, game over!
	
	# get coord of squares under left and right feet
	sub $s0, $t0, 1    			# under right leg: ($s0, $s2)  
	add $s1, $t0, 1				# under left leg: ($s1, $s2)
	add $s2, $t1, 2
	
	add $a0, $s0, $zero
	add $a1, $s2, $zero
	jal GetCoordAddress
	move $s3, $v0				# $s3 now holds buffer address of pixel below foot
	
	lw $t2, platformColour
	lw $t3, ($s3)
	beq $t3, $t2, HandleCollision
	
	add $a0, $s1, $zero
	add $a1, $s2, $zero
	jal GetCoordAddress
	move $s3, $v0				# $s3 now holds buffer address of pixel below foot
	
	lw $t3, ($s3)
	beq $t3, $t2, HandleCollision
	j DoneCheckCollision
	
	HandleCollision:
		#sub $t0, $s5, $s2		# $t0 stores the height gained from this jump; $s2 is the Y-value of the platform being collided with
		blez $s6, Collide 		# if the height gained is negative (i.e. we went from a higher platform to a lower one), we skip so we can't lose score
		
		la $t1, gameScore		
		li $t2, 12
		sub $t2, $t2, $s6
		add $s4, $s4, $t2			# add this gained height (score gain) to $s4, a temporary score holder
		sw $s4, ($t1)			# load into the gameScore variable
		move $s5, $s2			# log the new y-value
		
		Collide:
		la $t0, ySpeed
		li  $t1, -1
		sw $t1, ($t0)
		li $s6, 12
		
		li $v0, 31    			 # collision sound
		li $a0, 70
		li $a1, 300
		li $a2, 115
		li $a3, 127
		syscall
		
	DoneCheckCollision:
	lw $ra, 0($sp)			# load return address out of DrawSprite from stack
	addiu $sp, $sp, 4		# refill $sp
	jr $ra				# return

###################################################################################################################

CheckJump:				# deals with acceleration at apex of jump, manages jump height to set value.
	addiu $sp, $sp, -4		# allocate stack space for a word
	sw $ra, 0($sp)			# save return address out of checkCollision

	lw $t0, ySpeed
	beqz $t0, Stationary		# if the ySpeed is 0, that means we're going "up" by scrolling the platforms
	bgtz $t0, Falling		# if the yspeed is > 0, that means we're going down. We only move downwards by moving the doodler
	
	beqz $s6, BeginFall		# if we are not supposed to go up anymore, fall (by setting ySpeed to 1)
	sub $s6, $s6, 1			# decrement how many times left to go up
	UpSpeedCheck:			# decelerate near apex of jump; count number of times left to go up
	beq $s6, 2, ThirdLast
	beq $s6, 1, SecondLast
	beq $s6, 0, Last
	la $t0, updateSpeed
	li $t1, 150
	sw $t1, ($t0)
	j DoneCheckJump
	ThirdLast:
	la $t0, updateSpeed
	li $t1, 250
	sw $t1, ($t0)
	j DoneCheckJump
	SecondLast:
	la $t0, updateSpeed
	li $t1, 350
	sw $t1, ($t0)
	j DoneCheckJump
	Last:
	la $t0, updateSpeed
	li $t1, 450
	sw $t1, ($t0)
	j DoneCheckJump
	
	Stationary:			
	beqz $s6, BeginFall		# if we are not supposed to go up anymore, fall (by setting ySpeed to 1)
	sub $s6, $s6, 1
	j DoneCheckJump			# decrement how many times left to go up (by shifting platforms down)
	
	BeginFall:
	la $t0, updateSpeed
	li $t1, 350
	sw $t1, ($t0)
	la $t0, ySpeed
	li $t1, 1
	sw $t1, ($t0)				# set ySpeed to 1, aka Doodler falls down
	add $s6, $s6, 1
	j DoneCheckJump
	
	Falling:
	add $s6, $s6, 1
	beq $s6, 2, DownSecondLast
	beq $s6, 3, DownThirdLast
	la $t0, updateSpeed
	li $t1, 150
	sw $t1, ($t0)
	j DoneCheckJump
	DownThirdLast:
	la $t0, updateSpeed
	li $t1, 200
	sw $t1, ($t0)
	j DoneCheckJump
	DownSecondLast:
	la $t0, updateSpeed
	li $t1, 250
	sw $t1, ($t0)
	j DoneCheckJump
	
	DoneCheckJump:
	lw $ra, 0($sp)			# load return address out of DrawSprite from stack
	addiu $sp, $sp, 4		# refill $sp
	jr $ra				# return

###################################################################################################################

UpdatePlatform:	
	addiu $sp, $sp, -4		# allocate stack space for a word
	sw $ra, 0($sp)			# save return address out of UpdatePlatform
	
	la $t0, platformArrayX		# load address of platformArrayX  and Y so they can be accessed and modified
	la $t1, platformArrayY
	add $t3, $t0, 16		# stop value for address
	
	UpdatePlatformLoop:
		lw $a0, ($t0)			# store X value of platform into $a0
		lw $a1, ($t1)			# store Y value of platform into $a1
		
		ErasePlatform:
		# erase central pixel
		jal GetCoordAddress 		# convert XY to bitmap coords
		move $a0, $v0 			# copy coordinates to $a0
		lw $a1, backgroundColour
		jal Draw
		
		lw $a0, ($t0)			# store X value of platform into $a0
		add $a0, $a0, 1
		lw $a1, ($t1)			# store Y value of platform into $a1
		jal GetCoordAddress 		# convert XY to bitmap coords
		move $a0, $v0 			# copy coordinates to $a0
		lw $a1, backgroundColour
		jal Draw

		lw $a0, ($t0)			# store X value of platform into $a0
		add $a0, $a0, 2
		lw $a1, ($t1)			# store Y value of platform into $a1
		jal GetCoordAddress 		# convert XY to bitmap coords
		move $a0, $v0 			# copy coordinates to $a0
		lw $a1, backgroundColour
		jal Draw		
		
		lw $a0, ($t0)			# store X value of platform into $a0
		sub $a0, $a0, 1
		lw $a1, ($t1)			# store Y value of platform into $a1
		jal GetCoordAddress 		# convert XY to bitmap coords
		move $a0, $v0 			# copy coordinates to $a0
		lw $a1, backgroundColour
		jal Draw

		lw $a0, ($t0)			# store X value of platform into $a0
		sub $a0, $a0, 2
		lw $a1, ($t1)			# store Y value of platform into $a1
		jal GetCoordAddress 		# convert XY to bitmap coords
		move $a0, $v0 			# copy coordinates to $a0
		lw $a1, backgroundColour
		jal Draw		
		
		
		lw $a1, ($t1)			# store Y value of platform into $a1
		add $a1, $a1, 1 		# shift down 1 row
		sw $a1, ($t1)			# store new shifted Y value
		
		li $t2, 32				# handle a platform that has fallen off the bottom of the screen
		blt $a1, $t2, ContinueUpdateLoop	# if platform is still on screen, skip this
		
		li $a0, 0
		sw $a0, ($t1)			# set new y val for this platform to 0 (top of screen)
		# give random x value to this platform
		li $v0, 42			# syscall for RNG with bound
		li $a1, 28			# bound $a0: [0, 28)
		syscall
		addiu $a0, $a0, 2		# add 2 in case $a0 is 0, so platform isn't outside border
		sw $a0, ($t0)			# store x val into appropriate slot
	
		ContinueUpdateLoop:
		move $t4, $t0			
		addiu $t0, $t0, 4		# increment X address
		addiu $t1, $t1, 4		# increment Y address
		bne $t4, $t3, UpdatePlatformLoop
	
	DoneUpdatePlatform:
	lw $ra, 0($sp)			# load return address out of DrawSprite from stack
	addiu $sp, $sp, 4		# refill $sp
	jr $ra				# return
	
###################################################################################################################

DrawPlatform:
	addiu $sp, $sp, -4		# allocate stack space for a word
	sw $ra, 0($sp)			# save return address out of DrawPlatform
	
	la $t0, platformArrayX		# load address of platformArrayX  and Y so they can be accessed and modified
	la $t1, platformArrayY
	add $t3, $t0, 16		# stop value for address
	
	la $t7, platformArrayX

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
	lw $ra, 0($sp)			# load return address out of DrawPlatform from stack
	addiu $sp, $sp, 4		# refill $sp
	jr $ra				# return
	

###################################################################################################################

DrawSprite: 				# draws the whole Doodler to buffer according to spriteX, spriteY, and xyDirection
	addiu $sp, $sp, -4		# allocate stack space for a word
	sw $ra, 0($sp)			# save return address out of DrawSprite
	
	# draw initial central pixel
	lw $a0, spriteX 		# load X coord
	lw $a1, spriteY	 		# load Y coord
	jal GetCoordAddress 		# convert XY to bitmap coords
	move $a0, $v0 			# copy coordinates to $a0
	lw $a1, doodleColour 		# store color into $a1
	jal Draw			# draw color at pixel
	
	#draw top middle
	
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
	lw $a2, xyDirection
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
		
		lw $a0, spriteX 		# load X coord
		lw $a1, spriteY 		# load Y coord
		add $a0, $a0, -1 		# shift left 1 column for forehead
		add $a1, $a1, -1 		# shift up 1 row for forehead
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
		
		lw $a0, spriteX 		# load X coord
		lw $a1, spriteY 		# load Y coord
		add $a0, $a0, 1 		# shift left 1 column for forehead
		add $a1, $a1, -1 		# shift up 1 row for forehead
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
GameStart:
# get player name
li $v0, 55 			# text box output
la $a0, getUserMessage		# get the prompt asking for name
li $a1, 1			# information type
syscall

li $v0, 8
la $a0, currPlayer
li $a1, 20
syscall

li $v0, 59			# text box output
la $a0, gameStartPromptA	# get the start prompt
la $a1, gameStartPromptB
syscall

li $v0, 33    			 # collision sound
li $a0, 65
li $a1, 150
li $a2, 56
li $a3, 127
syscall
li $v0, 31   
li $a1, 450
syscall

jr $ra

###################################################################################################################

#ScoreCheckBG:
#	li $t0, 35
#	blt $s5, $t0, DoneScoreCheckBG
#	lw $t1, backgroundColour
#	beq $t1, 0x0082c6ff, DoneScoreCheckBG
#	lw $t2, 0x0082c6ff
#	sw $t2, backgroundColour
	
#	DoneScoreCheckBG:
#	jr $ra 
	
###################################################################################################################

GetCoordAddress:  		# inputs: $a0 <x coord>; $a1 <y coord>;     outputs: $v0 <buffer address>
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

CheckErasePixel:	# <$v0> buffer address of pixel to check if it needs to be erased or not
	addiu $sp, $sp, -4		# allocate stack space for a word
	sw $ra, 0($sp)			# save return address out of DrawSprite
	
	lw $t6, 0($v0)
	lw $t7, platformColour
	beq $t6, $t7, DoneCheckErase		# if the current pixel has been updated to be a platform
	lw $a1, backgroundColour
	move $a0, $v0
	jal Draw
	
	DoneCheckErase:
	lw $ra, 0($sp)			# load return address out of DrawSprite from stack
	addiu $sp, $sp, 4		# refill $sp
	jr $ra				# return
	


###################################################################################################################
			
Sleep:			# give the doodler a little nap
	li $v0, 32 	# syscall sleep with code 32, sleeps for the value in $a0  <<can use this to include acceleration later>>
	syscall
	jr $ra		# return to call location

###################################################################################################################
GameOver:   
	li $v0, 33      		# game over sound
	li $a0, 50
	li $a1, 450
	li $a2, 64
	li $a3, 127
	syscall
	li $a0, 49
	li $a1, 400
	syscall
	li $a0, 48
	li $a1, 300
	syscall
	li $v0, 31
	li $a0, 47
	li $a1, 1000
	syscall
	
	li $v0, 56 			# text box output
	la $a0, gameOverMessage		# get the game over message
	lw $a1, gameScore		# get player score
	syscall
	
	lw $t9, highScore		# check if new highscore
	ble $a1, $t9, PlayAgain
	
	li $v0, 33    			 # some trumpets for your highscore lol
	li $a0, 52
	li $a1, 200
	li $a2, 56
	li $a3, 127
	syscall
	li $a0, 59
	li $a1, 400
	syscall
	li $a0, 52
	li $a1, 150
	syscall
	li $v0, 31
	li $a0, 59
	li $a1, 600
	syscall
	
	lw $a1, gameScore		# get player score
	la $t1, highScore
	sw $a1, ($t1)			# store new highscore
	li $v0, 56 			# text box output
	la $a0, highScoreMessage		# get the new highscore message
	lw $a1, highScore		# get player score, aka new highscore
	syscall
	
	PlayAgain:# Play again calls
	li $v0, 50 			# syscall for yes/no dialog
	la $a0, playAgainMessage 	# get message
	syscall
	
	beqz $a0, main 			# back to top if user wants to play again


###################################################################################################################

Exit:
li $v0, 10 # terminate the program gracefully
syscall
