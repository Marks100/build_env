#!/usr/bin/env ruby

require 'FileUtils'

SEL_MODULE_FILE  = /\b(([A-Z]+)(_[A-Z]+)*)(\w*)\.([cChH])/


class MappingItem
  attr_reader :input_path, :partition, :msn

  def initialize( input_path, output_dir, partition )
    @input_path  = input_path
    @output_dir  = output_dir
    @partition   = partition

    basename = File.basename(@input_path)

    #/\b(([A-Z]+)(_[A-Z]+)*)(\w*)\.([cChH])/
    #   (        $1        )($4 )  (  $5  )
    if basename !~ SEL_MODULE_FILE
      puts "Error: unexpected match failure"
      exit
    end

    @msn_list    = []
    @msn         = $1
    @mangled_output_path     = "#{@output_dir}/#{@msn}_#{@partition}#{$4}.#{$5}"
    @non_mangled_output_path = "#{@output_dir}/#{basename}"

  end

  def addShortNameList( list )
    @msn_list = list.uniq

    #print "#{@input_path} has these msn: "
    #@msn_list.each do |msn|
    #   print "#{msn} "
    #end
    #puts ''

  end

  def doMangling

    #@msn_list.each do |msn|
    #  print "#{msn} "
    #end
    #puts ''


    #if our own msn is not found in the msn_list then we should use the non-mangled output name
    if @msn_list.index( @msn ).nil?
      output_path = @non_mangled_output_path
    else
      output_path = @mangled_output_path
    end

    printf "%-100s", output_path

    FileUtils.mkdir_p( @output_dir );
    out_file = File.open(output_path, 'w')

    File.open(@input_path, 'r') do |f|
      f.each_line do |line|
        @msn_list.each do |msn|
          line.gsub!(/("#{msn})(\.[hH]")/){|s| "#{$1}_#{@partition}#{$2}" }            # pub includes
          line.gsub!(%r{([\w]*/#{msn}_)(.*\.[hH])}) { "#{$1}#{@partition}_#{$2}" }     # other includes with path
          line.gsub!(/([ ")}]#{msn}_)([a-z0-9])/) { |s| "#{$1}#{@partition}_#{$2}" }   # Function calls, enums, structs, pri includes
          line.gsub!(/([ ,)]#{msn.downcase}_)([a-z0-9])/) { |s| "#{$1}#{@partition}_#{$2}" }   # static Function calls and variables
          line.gsub!(/(MUX_ID_#{msn})([ _])/) { |s| "#{$1}_#{@partition}#{$2}" }       # Just for DECLARE_MUX( MUX_ID_xxxx )
          line.gsub!(/(#{msn})(_ST(ART|OP)_SEC_)/) { |s| "#{$1}_#{@partition}#{$2}" }  # Just for <MSN>_ST(ART|OP)_SEC_XXX(
          line.gsub!('MUX_GEN_2', "MUX_#{@partition}_GEN_2")                           # To mangle MUX on/off compile flag
          line.gsub!( '#if( defined SEL_COMPILER_DOXYGEN ) || ( defined MUX_GENERATOR_RUN )', '#if( SEL_COMPILER_DOXYGEN == 1 ) || ( MUX_GENERATOR_RUN == 1 )' )  # Workaround for SSTDLIB issue
        end

        out_file.puts(line)
      end
    end

    out_file.close

    puts '[ Done ]'
  end

end


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

    puts "Parsing map file #{@mapfile_path}."

    File.open(@mapfile_path , 'r') do |f|

      f.each_line do |line|

        next unless line =~ /^\s*([.\/\w\\]+)\s+([.\/\w\\]+)\s*$/

        input  = $1
        output = $2

        input_dir   = File.expand_path("#{mapfile_dir}/#{input}")
        output_dir  = File.expand_path("#{mapfile_dir}/#{output}")

        # Up front format checks
        if output =~ /[\/\\]([A-Z]+)_partition[\/\\]/
          partition = $1
        else
          puts "WARNING: No X_partition label found in the output path #{output_dir}.  Skipping."
          next
        end

        if !File.directory?(input_dir)
          puts "WARNING: the input path #{input_dir} is not a directory.  Skipping."
          next
        end

        puts "Searching specified input directory #{input_dir} for Schrader source files."

        #list of files found in the input directory
        list = Dir["#{input_dir}/*.*"]

        list.each do |src_file|

          basename = File.basename(src_file)

          if basename =~ SEL_MODULE_FILE
            @map_item_list << MappingItem.new(src_file, output_dir, partition)
            puts "  Found: #{basename}."
          else
            puts "  Skipping: #{basename} - desn't match SEL module filename convention."
          end

        end #list.each

      end #f.each_line

    end #File.open

    puts "Mapfile parse complete."

  end


  def createOutputs

    # Extract a hash of all the partition names as key and a list of MSNs as the value
    part_hash = Hash.new
    msn_hash  = Hash.new

    @map_item_list.each do|item|
      part_hash["#{item.partition}"] = [] if part_hash["#{item.partition}"].nil?
      part_hash["#{item.partition}"] << item.msn
      part_hash["#{item.partition}"].uniq!

      msn_hash["#{item.msn}"] = [] if msn_hash["#{item.msn}"].nil?
      msn_hash["#{item.msn}"] << item.partition
      msn_hash["#{item.msn}"].uniq!
    end

    # Stip out the MSNs from the part_hash that only occur in one partition
    @map_item_list.each do|item|
      #if our MSN is only used in one partition, there is no need to mangle itself so remove from the MSN list
      if( msn_hash["#{item.msn}"].size == 1 )
        part_hash["#{item.partition}"].delete(item.msn)
      end
    end

    # Now push the msn list to each item
    @map_item_list.each do|item|
      item.addShortNameList( part_hash["#{item.partition}"] )
    end

    # Now get each item to mangle itself
    @map_item_list.each do|item|
      item.doMangling()
    end

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
    puts "Usage: common_modules_gen.rb map_filename"
    exit
  end

  map_factory = MappingFactory.new( ARGF.filename )

  puts 'Begin mapping.'
  map_factory.createOutputs()
  puts 'Mapping complete'
  puts ''

  #map_factory.debug


end
