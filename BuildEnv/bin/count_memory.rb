#!/usr/bin/env ruby

require 'FileUtils'

MAX_FLASH_SIZE = 129024.0
MAX_RAM_SIZE = 16360.0

class MappingFactory

  attr_reader :mapfile_path, :mapfile_name

  def initialize( mapfile_path )
    reloadMapFile( mapfile_path )
  end

  def reloadMapFile( mapfile_path = @mapfile_path )

    @mapfile_path  = File.expand_path(mapfile_path)
    @map_item_list = []

    mapfile_name   = File.basename( @mapfile_path )
    mapfile_dir    = File.dirname( @mapfile_path )

    File.open(@mapfile_path , 'r') do |f|

		a_code_size  	= 0
		code_QM_size 	= 0
		const_size		= 0
		vari_QM_size	= 0
		vari_A_size		= 0
		varu_QM_size	= 0
		varu_A_size		= 0
		percent_flash 	= 0.0
		percent_ram		= 0.0

		f.each_line do |line|
#			next unless
			next unless line =~ /^\s+[a-fA-F0-9]+\s+([a-fA-F0-9]+)\s+:?\s*(\w+)\.47R\s*\(\.(\w+)_rdci/

			size    = $1
            file    = $2
			section = $3

            #if file =~ /PAL/ or file =~ /TOC/ or file =~ /LLA/ or file =~ /LRN/ or file =~ /STAT/ or file =~ /LOC/
			#if file =~ /TOC/
			#if file =~ /NVM_WRN/
			#if file =~ /WARN/
			#if file =~ /DTC_MGR_WRN/ or file =~ /MALF/ or file =~ /SIG/
			#if file =~ /DIAG/
			#if file =~ /CALIB/
			#if file =~ /HMI/
			#if file =~ /RdciWarn/
			#if file =~ /MUX/
			#if file =~ /SwcRdciComHdlA/
			#if file =~ /SwcRdciDat/ or file =~ /SwcRdciAnz/ or file =~ /SwcRdciComHdlQm/

			#puts "File is: #{file}"

			  case section
			  when "a_code"
			  	a_code_size = a_code_size + size.to_i(16)
			  when "code_QM"
			  	code_QM_size = code_QM_size + size.to_i(16)
			  when "const"
			  	const_size = const_size + size.to_i(16)
			  when "vari_QM"
			  	vari_QM_size = vari_QM_size + size.to_i(16)
			  when "vari_A"
			  	vari_A_size = vari_A_size + size.to_i(16)
			  when "varu_QM"
			  	varu_QM_size = varu_QM_size + size.to_i(16)
			  when "varu_A"
			  	varu_A_size = varu_A_size + size.to_i(16)
			  end
		end #f.each_line
		
		
		#added to give a % of the total flash and ram that is currently being used
		percent_flash = ( ( ( const_size + a_code_size + code_QM_size )/ MAX_FLASH_SIZE )*100.0 )
		percent_ram   = ( ( ( varu_A_size + vari_A_size + varu_QM_size + vari_QM_size )/ MAX_RAM_SIZE )*100.0 )
		

		puts "Const size	= #{const_size}"
		puts "A BSS size	= #{varu_A_size}"
		puts "A DATA size	= #{vari_A_size}"
		puts "A CODE size	= #{a_code_size}"
		puts "QM BBS size	= #{varu_QM_size}"
		puts "QM DATA size	= #{vari_QM_size}"
		puts "QM CODE size	= #{code_QM_size}"
		puts ""
		puts "Total Flash	= #{const_size + a_code_size + code_QM_size}"
		puts "Total Ram	= #{varu_A_size + vari_A_size + varu_QM_size + vari_QM_size}"
		puts "% Flash used    = #{'%.0f' % percent_flash}%"
		puts "% Ram used      = #{'%.0f' %percent_ram}%"

    end #File.open
  end

    def debug()


    ## We have our mappings.  Now do the substitutions!
    @map_item_list.each do|item|
      puts "Item: #{item.input_path}  #{item.output_path}  #{item.partition}   #{item.msn}"
    end

  end

end



# Command Line Support ###############################
if ($0 == __FILE__)

  if ARGF.argv.size != 1
    puts "Usage: count_memory.rb map_filename"
    exit
  end

  map_factory = MappingFactory.new( ARGF.filename )

  #map_factory.debug


end

