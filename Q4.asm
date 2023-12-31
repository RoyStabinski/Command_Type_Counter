

#In this program The commands consist only of R-type commands:: lw, sw, beq.\
#The program is on a list of commands, and counts how many commands there are of each type.
#The program counts for any register in the register stack how many times it appears in the various commands
#At the end the program prints the data into a table.
#In case of errors,the program prints suitable error message.



# Data #
.data
TheCode: .word 0x8d690000,0x1232000d,0x02749820,0x8c070040, 0xffffffff
CurrentC: .word 0 #The current command in the array
FinalC: .word 0xffffffff #The final command in the array

# Counters #
#Assigning the value 0 for the counter commands at first.
RegisterSum: .word 32
RegisterCounter : .word 0:32
RCounter: .word 0
lwCounter : .word 0
beqCounter: .word 0
swCounter: .word 0

# Output #
#Printing the registers appearances 
Output: .asciiz "\ninst code /reg \t\tappearances"  #Head of table
Rmsg: .asciiz "\nR-Type \t\t" 
lwMsg: .asciiz "\nlw \t\t"
swMsg: .asciiz "\nsw \t\t"
beqMsg: .asciiz "\nbeq \t\t"
errMsg: .asciiz "\nError! Unsupported command."
lwErrMsg: .asciiz "\nThe register $zero is Rd in lw command "
RtErrMsg: .asciiz "\nThe register $zero is Rd in R-type command "
beqErrMsg: .asciiz "\nThe rd and rt are equal in beq command "
Tab: .asciiz "\t\t"
NewLine : .asciiz "\n"

#Defenition numbers #
#Define the errors and commands.
LegalCommand : .word 0
RCommand: .word 1 #R-type command code
lwCommand : .word 2 #lw command code
swCommand: .word 3 #sw command code
beqCommand : .word 4 #beq command code
ErrCommand: .word 5 #Error command code
RErrCommand: .word 6 #R-type error command code
lwErrCommand: .word 7 #lw error command code
beqErrCommand: .word 8 #beq error command code

# Text #
.text
.globl main

#The next code lines are the main part of the program.
#Their job is to run the program by checking up which commands and registers are used,and how many times they were used

main:

li $s0,0  #Storing s0 as the current command
lw $s2,FinalC # Storing s2 as the final command (0xffffffff)
li $s3, 0xfc000000 #0xfc000000 is reseting all bits except the opcode bits.

Firstloop:

lw $s1 , TheCode($s0)
beq $s1 , $s2,endFirstloop #if s1 = FinalC
and $t0,$s1,$s3 # store t0 as opcode bites.
srl $t0 , $t0 ,26 #Store t0 as opcode value

#R-type command #

bne $t0,$zero,lwCommand_method #if the opcode of t0 isnt 0
lw $t1 ,RCounter
addi $t1,$t1,1 #Adding 1 to the R-type counter
sw $t1,RCounter
lw $t1,RCommand 
sw $t1,CurrentC 
j endIf

#lw Command #
lwCommand_method:

li $t1 , 0x0023 #Opcode of lw command type
bne $t0,$t1,swCommand_method
lw $t1,lwCounter
addi $t1,$t1,1 #Adding 1 to the lw counter
sw $t1,lwCounter
lw $t1,lwCommand
sw $t1 , CurrentC
j endIf

# sw Command #
swCommand_method:

li $t1,0x002b #Opcode of sw command type
bne $t0,$t1,beqCommand_method
lw $t1,swCounter
addi $t1,$t1,1 #Adding 1 to the sw counter
sw $t1,swCounter
lw $t1,swCommand
sw $t1,CurrentC
j endIf

#beq Command #
beqCommand_method:

li $t1 , 0x0004 #Opcode of beq command type
bne $t0,$t1,else
lw $t1,beqCounter
addi $t1,$t1,1 #Adding 1 to the beq counter
sw $t1,beqCounter
lw $t1,beqCommand
sw $t1,CurrentC
j endIf

# else #
else:
sw $zero , CurrentC

#end if#
endIf:
lw $t2 , CurrentC
beqz $t2 , skip

# Working over legal command #
move $a0,$s1
move $a1,$t2
jal analyzeCommand
sll $v0,$v0 ,2 #Turns up v0 to be index of word by multiple v0 in 4 
sll $v1,$v1 ,2 # '' '' '' ''''  v1 '' ''
lw $t0 , RegisterCounter($v0)
addi $t0,$t0,1 #Adding 1 to the register counter
sw $t0 ,RegisterCounter($v0)
lw $t0,RegisterCounter($v1)
addi $t0,$t0,1
sw $t0,RegisterCounter($v1)

skip:

move $a0,$s1
lw $a1,CurrentC
jal errorSearch
beqz $v0,SetupNextLoop #if errors werent found go to the setup of the next loop
move $a0,$s1
move $a1,$v0
jal OutputErrMsg #if errors find go to the printing errors code

SetupNextLoop:

sw,$zero,CurrentC #Reset the current command value to 0
addi $s0,$s0,2 #Adding 4 to s0 variable
j Firstloop

endFirstloop:

jal printResult
j exit

exit:
li $v0,10
syscall

analyzeCommand: #Parsing the command and counting up how many times the register used

move $s0,$a0 #bulding up the stack ,s0=a0
lw $t0, RCommand #t0 = Rtype command
bne $a1 , $t0,skipRdCheck #if a1 = t0 then no chack if it Rtype command
jal analyzeRdRegister

addi $sp , $sp , -8 #Pushing variables into the stack
sw $ra , 4($sp)
sw $s0 , ($sp) 

skipRdCheck:
li $t0 , 0x03e000000 #Resets all bites except of rd bites.
and $v0 , $s0 , $t0 
srl $v0 , $v0 , 21 # sets v0 as rd value
li $t0 , 0x001f0000 #Resets all bites except of rt bites
and $v1,$s0,$t0
srl $v1,$v1,16 #sets v1 as rt value

#Pop out from the stack
lw $s0,($sp)
lw $ra,4($sp)
addi $sp,$sp,8
jr $ra

analyzeRdRegister:

li $t0 , 0x0000f800 #Resets all bites except of rd bites
and $t1,$a0,$t0 
srl $t1,$t1,11 #Sets t1 as rd value
sll $t1,$t1,2  #Multiple t1 in 4 to be an index for the register counter
lw $t2,RegisterCounter($t1)
addi $t2,$t2,1
sw $t2,RegisterCounter($t1)
jr $ra

errorSearch:

lw $v0 ,LegalCommand
bnez $a1 RtypeCheck
lw $v0,ErrCommand
j endCheck

RtypeCheck:

lw $t0,RCommand
bne $t0,$a1,lwCheck #if the error isnt here check at lw command
li $t0,0x0000f800 #Resets all bites except of rd bites
and $t1,$a0,$t0
bnez $t1,endCheck 
lw $v0,RCommand
j endCheck

lwCheck:

lw $t0,lwCommand
bne $t0,$a1,beqCheck #if the error isnt here check at beq command
li $t0,0x001f0000 #Resets all bites except of rd bites
and $t1,$a0,$t0
bnez $t1,endCheck 
lw $v0,lwCommand
j endCheck

beqCheck:

lw $t0,beqCommand
bne $t0,$a1,endCheck #if the error isnt here then end the check
li $t0,0x03e00000 #Resets all bites except of rd bites
and $t1,$a0,$t0
srl $t1,$t1,21
li $t0,0x001f0000
and $t2 ,$a0,$t0
srl $t2,$t2,16 #Stores t2 as rt value
bne $t1,$t2,endCheck 
lw $v0,beqCommand
j endCheck

endCheck:
jr $ra

OutputErrMsg:

move $s0,$a0
la $a0,errMsg
jal PrintString
lw $at,ErrCommand 
beq $a1,$at,ErrCommand_method
lw $at,RErrCommand
beq $a1,$at,RErrCommand_method
lw $at,lwErrCommand
beq $a1,$at,lwErrCommand_method
lw $at,beqErrCommand
beq $a1,$at,beqErrCommand_method
j endOutputErrMsg

addi $sp,$sp,-8
sw $ra,4($sp) #pop out from the stack
sw $s0,($sp)

ErrCommand_method:
la $a0,errMsg
j endOutputErrMsg

RErrCommand_method:
la $a0,RtErrMsg
j endOutputErrMsg

lwErrCommand_method:
la $a0,lwErrMsg
j endOutputErrMsg

beqErrCommand_method:
la $a0,beqErrMsg
j endOutputErrMsg

endOutputErrMsg:

jal PrintString
move $a0,$s0
jal PrintHexa
la,$a0,NewLine
jal PrintString

lw $s0,($sp)
lw $ra,4($sp) #Pop out from the stack
addi $sp,$sp,8
jr $ra

printResult:
addi $sp, $sp, -4
sw $ra, ($sp) #Push into the stack

la $a0,Output #Printing header
jal PrintString 
la $a0, NewLine
jal PrintString
la $a0 ,Rmsg
jal PrintString

#Printing Data
lw $a0,RCounter
jal PrintSum
la $a0,NewLine
jal PrintString
la $a0,lwMsg
jal PrintString
lw $a0,lwCounter
jal PrintSum
la $a0,NewLine
jal PrintString
la $a0,swMsg
jal PrintString
lw $a0,swCounter
jal PrintSum
la $a0,NewLine
jal PrintString
la $a0,beqMsg
jal PrintString
lw $a0,beqCounter
jal PrintSum
la $a0,NewLine
jal PrintString

#Printing Counters
li $t0,0 #t0=0
lw , $t1,RegisterSum #t1 = 32

SecondLoop:

bge $t0,$t1,endSecondLoop #As long t0 < t1 then go on all over the loop
sll $t2,$t0,2 # t2 = t0*4 is the index of the register counter
lw $t3,RegisterCounter($t0) #t3 is counting the register number of t0
beqz $t3,UnusedRegister # if the current counting is 0 jump over to the unused register

#Printing
move $a0,$t0
jal PrintSum
la $a0,Tab
jal PrintString
move $a0,$t3
jal PrintSum
la $a0,NewLine
jal PrintString

UnusedRegister:

addi $t0,$t0,1 #Adding 1 to t0
j SecondLoop

endSecondLoop:

lw $ra,($sp)
addi $sp,$sp,4 #Pop out from the stack
jr $ra

PrintString: #Defining the method

li $v0,4
syscall
jr $ra

PrintSum: #Defining the method
li $v0,1
syscall
jr $ra

PrintHexa: #Defining the method
li $v0,34
syscall
jr $ra





































