# Doodle Jump Attempt #1 lol

  #################################################################################################################
 ######                                        V A R I A B L E S                                            ######
#################################################################################################################
.data
# Declaration of important variables:
# Screen Dimensions 
screenHeight: 		.word 32		# maximum X and Y coordinates of the 256x256 display with 8x8 pixels
screenWidth: 		.word 32

# Colors
backgroundColour:  	.word 0x0082c6ff     	# colour constant for background (paleskyblue)
doodleColour:      	.word 0x00e459e8      	# colour constant for Doodler sprite (brightpink)
doodleEyeColour:  	.word 0x00c2d8e5	# colour constant for Doodler eye to indicate direction (bluegrey)
platformColour:   	.word 0x0035ac4b      	# colour constant for default platforms (grassgreen)

# Doodler Position Variables
spriteX: 		.word 16   		# X coordinate of central pixel of Doodler sprite
spriteY:		.word 28		# Y coordinate of central pixel of Doodler sprite
xyDirection:    	.word 106		# ASCII code for j, inital lateral direction is facing left
xSpeed:			.word 0			# holds lateral direction, positive for right, neg for left; initially 0
ySpeed:			.word 1			# holds vertical direction, positive for up, neg for down; initially going up  [-1, 1]

# Game variables
updateSpeed: 		.word 10		# used as input to Sleep command, determines how long before doodler pos. is updated

  #################################################################################################################
 ######                                           C O D E ! ! !                                             ######
#################################################################################################################
.text  # actual code

main: 

# Initialize the background by filling the whole thing in
lw $a0, backgroundColour
lw $a1, screenHeight
mul $a2, $a1, $a1 		# assign $a2 the number of pixels on screen by multiplying dimensions
mul $a2, $a2, 4 		# obtain address of final bottom-right coord so we know when its done drawing
add $a2, $a2, $gp 		
add $a1, $gp, $zero 		# redefine $a1 as $gp for incremental use when drawing

DrawBGLoop:
	beq $a1, $a2, InitialSprite	# while $a1 (current coord being drawn) is != $a2 (coord of last pixel), do the following:
	sw $a0, 0($a1) 			# give the current pixel denoted by $a1 the BG colour held in $a0
	addiu $a1, $a1, 4 		# increment counter
	j DrawBGLoop
	
# Draw initial position of Doodler at central-bottom
InitialSprite:
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
	
	#draw middle row
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

# Draw initial platform beneath initial Doodler, called Home :)
InitialPlatform:
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
	
###########################   Get user input from keyboard   ##################################################
GetInput:
	lw $a0, updateSpeed		# small nap
	jal Sleep
	
	# get input from keyboard
	lw $a0, xyDirection		# $a0 holds lateral direction value
	li $v0, 12			# syscall for reading a character, loads ASCII into $v0
	syscall	
	bne $v0, $a0, CheckValidDirection	# if input direction is not equal to current direction, check if its valid first
	
	# input is equal to same direction so update Doodler position accordingly
	lw $a0, xyDirection 		# give $a0 xyDirection value for future use
	lw $a1, xSpeed			# give $a1 xSpeed value
	beq $a0, 106, Left
		add $a1, $a1, 1		# going right so accelerate right more
		Left:
		add $a1, $a1, -1	# going left so accelerate left more			
	j UpdateSprite


CheckValidDirection:
	beq $v0, 106, ChangeRightToLeft  	# if input direction is left, continue to ChangeRightToLeft
	beq $v0, 107, ChangeLeftToRight		# if input direction is right, continue to ChangeLeftToRight
	#else, $v0 is invalid input but we treat this as no input and nothing changes
	lw $a0, xSpeed				# same unchanged xSpeed
	lw $a1, ySpeed				# same unchanged ySpeed
	j GetInput

ChangeRightToLeft:
	la $t0, xyDirection		# load address of xyDirection into $t0 so we can modify its value
	sw $v0, 0($t0)			# move left value (106) into address for xyDirection
	la $t1, xSpeed			# load address of xSpeed into $t1 so we can modify its value
	lw $t2, xSpeed			# load value of xSpeed into $t2 so we can use it for calculations
	subi $t2, $t2, 1		# subtract 1 from the xSpeed (simulate leftward acceleration)
	sw $t2, 0($t1)			# move updated xSpeed value into xSpeed address
	lw $a0, xSpeed			# give $a0 xSpeed value for future use
	lw $a1, ySpeed			# load ySpeed value
	j UpdateSprite

ChangeLeftToRight:
	la $t0, xyDirection		# load address of xyDirection into $t0 so we can modify its value
	sw $v0, 0($t0)			# move right value (107) into address for xyDirection
	la $t1, xSpeed			# load address of xSpeed into $t1 so we can modify its value
	lw $t2, xSpeed			# load value of xSpeed into $t2 so we can use it for calculations
	addi $t2, $t2, 1		# add 1 to the xSpeed (simulate rightward acceleration)
	sw $t2, 0($t1)			# move updated xSpeed value into xSpeed address
	lw $a0, xSpeed			# give $a0 xSpeed value for future use
	lw $a1, ySpeed			# load ySpeed value
	j UpdateSprite

UpdateSprite:			# updates the central Doodler pixel according to xSpeed <$a0>, ySpeed <$a1>
	lw $a2, spriteX		# load X and Y coordinates of central pixel of Doodler
	lw $a3, spriteY 	
	
	beq $a0, 106, FaceLeft	# if the xyDirection is left, jump there. otherwise, it's facing right and so:
	
	
	FaceLeft:
		


  #################################################################################################################
 ######                                       H E L P E R R S ! ! !                                         ######
#################################################################################################################



DrawSprite: 			# draws the whole Doodler according to xyDirection <$a0>, xSpeed <$a1>, ySpeed <$a2>

GetCoordAddress:  		# inputs: $a0 <x coord>; $a1 <y coord>;     outputs: $v0 <bitmap address>
	lw $v0, screenWidth 	# give $v0 value of # of rows in screen
	mul $v0, $v0, $a1	# multiply y coord by screenWidth to get row number
	add $v0, $v0, $a0	# add x coord to $v0 to obtain square number 
	mul $v0, $v0, 4		# multiply square number by 4 to obtain relative address distance
	add $v0, $v0, $gp	# add display address to get bitmap coord relative to starting $gp
	jr $ra			# return to function call location

Draw:
	sw $a1, ($a0) 	# give the coordinate in $a0 the color value in $a1
	jr $ra		# return
	
Sleep:			# give the doodler a little nap
	li $v0, 32 	# syscall sleep with code 32, sleeps for the value in $a0  <<can use this to include acceleration later>>
	syscall
	jr $ra		# return to call location


###################################################################################################################
Exit:
li $v0, 10 # terminate the program gracefully
syscall