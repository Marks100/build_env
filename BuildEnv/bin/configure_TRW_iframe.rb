#!/usr/bin/env ruby

require 'FileUtils'

@file_name_1 = ARGV[0]
@file_name_2 = ARGV[1]
@file_name_3 = ARGV[2]

 if ARGF.argv.size != 3
    puts "Incorrect Usage!!!!: Need 3 files\nKBMI17_MM_APP.INI,\nLibraries.cmd\nand CustBsw.ini\nall files \
should be located in the PROJ_TrwBuildEnv folder,\nPerhaps that folder does not exist in youre build env?"
	exit
 end
 
puts "\n
########################################################
#######   Making necessary Changes to iFrame   #########
########################################################"
 
file_names = [@file_name_1, @file_name_2, @file_name_3]
file_dirs = [File.expand_path(@file_name_1), File.expand_path(@file_name_2), File.expand_path(@file_name_3)]

puts "\nList of filenames that will be modified:\n"
puts file_names

@KBM17_replacement_string = "RDCI=1,DIR=CustBsw\\Rdci\\RdciMain\\Source,CAL=0,V_FILE=,COMPILE_MODE=DEFAULT"
@LinkLibraries_replacement_string = "//--library=..\\..\\..\\MainMicro\\Application\\CustBsw\\Rdci\\Library\\RDCILIBNAME"

  

##File 1
@file_name_1_dir = File.expand_path(@file_name_1)
puts "\n\n\nSearching for file:\n#{@file_name_1_dir}\n"


if File.exists?(@file_name_1_dir)
	puts "The file KBMI17_MM_APP.INI exists and will be modified"
	text = File.read(@file_name_1)
	new_contents = text.gsub(/^CUSTBSW=1,DIR=CustBsw\\Make,CAL=0,V_FILE=CUSTBSW_VER.H,COMPILE_MODE=DEFAULT/, @KBM17_replacement_string )

	#To merely print the contents of the file, use:
	#puts new_contents

	#To write changes to the file, use:
	File.open(@file_name_1, "w") {|file| file.puts new_contents }
	puts "#{@file_name_1} has been modified"

else
	puts ">ERROR: File does not exist"
end


##File 2
@file_name_2_dir = File.expand_path(@file_name_2)
puts "\n\n\nSearching for file:\n#{@file_name_2_dir}\n"

if File.exists?(@file_name_2_dir)
	puts "The file #{@file_name_2} exists and will be modified"
	text = File.read(@file_name_2)
	#new_contents = text.gsub(@LinkLibraries_target_string , @LinkLibraries_replacement_string )

	new_contents = text.gsub( /^--library=..\\..\\..\\MainMicro\\Application\\CustBsw\\Rdci\\Library\\RDCILIBNAME/, @LinkLibraries_replacement_string)

	#To write changes to the file, use:
	File.open(@file_name_2, "w") {|file| file.puts new_contents }
	puts "#{@file_name_2} has been modified"

else
	puts ">ERROR: File does not exist"
end

##File 3
@file_name_3_dir = File.expand_path(@file_name_3)
puts "\n\n\nSearching for file:\n#{@file_name_3_dir}\n"

if File.exists?(@file_name_3_dir)
	puts "The file #{@file_name_3} exists and will be modified"
	text = File.read(@file_name_3)

	new_contents = text.gsub(/^\[CustBsw\\Rdci\\RdciMain\\Source\\SwcRdci(Anz|Dat|ComHdlA|ComHdlQm|Erfs|Warn)_Template.c\].*\[FILES_DIRS\]/m, "\n\n[FILE_DIRS]" ) 

	File.open(@file_name_3, "w") {|file| file.puts new_contents }
	puts "#{@file_name_3} has been modified"
	
	
	puts "\n
########################################################
#######   iFrame succesfully configured   ##############
########################################################"
else
	puts ">ERROR: File does not exist"
end