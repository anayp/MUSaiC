#frqtotxt.tcl - Starting with an input soundfile, this routine 
#		    carries out the 3-step process ending with 
#		    PTOBRK.EXE to convert the REPITCH GETPITCH binary  
#		    pitch data file to a text file for use with PSOW.
#		    NB. Use REPITCH GETPITCH Mode 1, without -z flag
#		    i.e., without retaining pitch zeros.
# NB: apart from checking the command line arguments there is no 
# error checking in this version of the program.

#OUTPUT MESSAGES TO THE USER
#(These are not yet reaching the screen.)

proc Usage {} {
	Inf "Usage: frqtotxt.tcl yourinfile.wav theoutfile.txt\n"
	Inf "NB: Infile must be mono\n"
	return
}

proc Inf {errmessage} {
	puts stdout $errmessage
}

#COMMAND LINE ARGUMENT CHECK

if {$argc < 2} {
	Usage
	exit;
}

if {![file exists [lindex $argv 0]]} {
	Inf "Input soundfile [lindex $argv 0] does not exist.\n"
	exit;
}

if {[file exists [lindex $argv 1]]} {
	Inf "Output soundfile [lindex $argv 1] already exists.\n"
	exit;
}

#BODY OF THE 3-STEP FRQ-TO-TXT PROCESS

exec copysfx [lindex $argv 0] infile.wav
exec pvoc anal 1 infile.wav infile.ana
exec repitch getpitch 1 infile.ana infilepchdummy.wav infile.frq
exec ptobrk withzeros infile.frq infile.txt 20
file rename infile.txt [lindex $argv 1]

# DELETE (temporary) files no longer needed

file delete infile.wav
file delete infile.ana
file delete infilepchdummy.wav
file delete infile.frq
