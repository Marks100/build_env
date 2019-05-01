#!/usr/bin/env ruby

require 'FileUtils'

SEL_MODULE_FILE  = /\b(([A-Z]+)(_[A-Z]+)*)(\w*)\.([cChH])/

def get_source_files()

  list = Dir["**/*.[cChH]"]

  list.delete_if { |x| x =~ /template/i }
  #list.delete_if { |x| x !~ SEL_MODULE_FILE }
  list.delete_if { |x| x =~ /_common/ }
  list.delete_if { |x| x =~ /test/ }
  list.delete_if { |x| x == /MemMapSel/ }

  list
end


def check_src_files( files )

  a_sections  = []
  qm_sections = []


  files.each do |src_file|

    contents = File.readlines( src_file )

    prev_line = ''
    section   = ''
    count     = 0
    line_num  = 0
    sec_msn   = ''

    contents.each do |line|

      line_num = line_num + 1

      #define NVM_WRN_START_SEC_VAR_INIT_UNSPECIFIED
      #include "MEM_A_placement.h"
      if line =~ /^#include\s+"MEM_(A|QM)_placement.h"/

        # First check that the A and QM are correct
        mem_placement_part = $1
        file_placement     = ''

        if src_file =~ /(A|QM)_partition/
          file_placement = $1

          if mem_placement_part != file_placement
            puts "WARNING - #{src_file}:(#{line_num}): Incorrect partition letter #{mem_placement_part}!"
          end
        else
          puts "ERROR - #{src_file} does not seem to be in a (A|QM)_partition"
          exit -1
        end


        # Move on to check the START and STOP pairs
        if prev_line =~ /^#define\s+(([A-Z_]+)_START_([A-Z_0-9]+))/

          # Store off for later - only storing START
          if file_placement == 'A'
            a_sections << $1
          else
            qm_sections << $1
          end

          sec_test = $3

          # Grab and check the sec_msn if not already done
          if sec_msn == ''
            sec_msn = $2

            # extract MSN
            src_file =~ SEL_MODULE_FILE
            if sec_msn != $1
              puts "WARNING - #{src_file}:(#{line_num}): Section name #{sec_msn} does not match file MSN"
            end

          else
            # Check it's staying the same each time
            if $2 != sec_msn
              puts "#{src_file}:(#{line_num}): Inconsistent MSN #{$1}, expected #{sec_msn}"
              exit -1
            end
          end

          if count % 2 == 0
            section = sec_test
            #puts "INFO - #{src_file}:(#{line_num}): Found START section: #{section}"
          else
            puts "ERROR - #{src_file}:(#{line_num}): Unexpexted START section: #{prev_line}"
            exit -1
          end

        elsif prev_line =~ /^#define\s+([A-Z_]+)_STOP_([A-Z_0-9]+)/
          if count % 2 != 0
            if section == $2
              #puts "INFO - #{src_file}:(#{line_num}): Found matching STOP section: #{section}"
            else
              puts "ERROR - #{src_file}:(#{line_num}): Incorrect STOP section: #{prev_line}"
              exit -1
            end
          else
            puts "ERROR - #{src_file}:(#{line_num}): Unexpexted STOP section: #{prev_line}"
            exit -1
          end
        else
            puts "ERROR - Didn't recognise your placement line: #{prev_line}"
            exit -1
        end

        count = count + 1
      end

      prev_line = line

    end

    if count % 2 != 0
      puts "ERROR - #{src_file}: Couldn't find final matching STOP section for #{section}"
      exit -1
    end

  end

  return a_sections, qm_sections

end


def check_memmap_file( memmap, a_sections, qm_sections, start_stop )

  contents = File.readlines( memmap )

  if start_stop != 'START' and start_stop != 'STOP'
    puts "ERROR - API start_stop must be either START or STOP"
    exit -1
  end

  line_num   = 1
  chunk_line = 0
  msn_sec    = ''
  sec        = ''
  mem_place  = ''
  complete   = ''

  asil_a_sections = a_sections.clone
  asil_qm_sections = qm_sections.clone

  # Our lookup is based on START
  if start_stop == 'STOP'
    asil_a_sections.each  { |x| x.gsub!('START','STOP') }
    asil_qm_sections.each { |x| x.gsub!('START','STOP') }
  end

  contents.each do |line|

    # We don't check the default sections at the end
    if line =~ /\/\*\*\s+Default placements\s+\*\//
      break
    end

    if start_stop == 'START'
      regex_vars = /^#elif\s+\(\s*defined\s+(([A-Z_]+)_START_([A-Z_0-9]+)_(UNSPECIFIED|8|16|32))\s*\)/
      regex_code = /^#elif\s+\(\s*defined\s+(([A-Z_]+)_START_(SEC_CODE))\s*\)/
    else
      regex_vars = /^#elif\s+\(\s*defined\s+(([A-Z_]+)_STOP_(SEC_VAR|SEC_CONST)_[A-Z_0-9]+)\s*\)/
      regex_code = /^#elif\s+\(\s*defined\s+(([A-Z_]+)_STOP_(SEC_CODE))\s*\)/
    end

    if line =~ regex_vars or line =~ regex_code

      if chunk_line != 0
        puts "ERROR - #{memmap}:(#{line_num}): Incomplete Chunk in previous section"
        exit -1
      end

      chunk_line = 1
      complete   = $1
      msn_sec    = $2
      sec        = $3

      # Look up MSN in arrays
      if asil_a_sections.delete($1)
        #puts "INFO - #{memmap}:(#{line_num}): Found Section #{$1}"
        mem_place = 'A'
      elsif asil_qm_sections.delete($1)
        mem_place = 'QM'
      else
        puts "WARNING - #{memmap}:(#{line_num}): Unneccessary Section #{complete}"
      end

    else

      case chunk_line
      when 1
        if start_stop == 'START'
          regex = Regexp.new( "#define\s+DEFAULT_#{mem_place}_START_#{sec}" )
        else
          regex = Regexp.new( "#define\s+DEFAULT_STOP_#{sec}" )
        end

        if line !~ regex
            if start_stop == 'START'
              puts "ERROR - #{memmap}:(#{line_num}): Didn't find expected DEFAULT_#{mem_place}_#{start_stop}_#{sec}"
            else
              puts "ERROR - #{memmap}:(#{line_num}): Didn't find expected DEFAULT_#{start_stop}_#{sec}"
            end
            exit -1
        end

        chunk_line = 2

      when 2
        regex = Regexp.new( "#undef\s+#{complete}")

        if line !~ regex
          puts "ERROR - #{memmap}:(#{line_num}): Didn't find expected #undef #{complete}"
          exit -1
        end

        chunk_line = 3

      when 3
        if line !~ /#undef\s+MEMMAP_ERROR/
          puts "ERROR - #{memmap}:(#{line_num}): Didn't find expected #undef MEMMAP_ERROR"
          exit -1
        end

        chunk_line = 4
      when 4
        if line !~ /^\s*$/
          puts "ERROR - #{memmap}:(#{line_num}): Didn't find expected blank line"
          exit -1
        end

        chunk_line = 0
      else
          # Nothing to do
      end
    end

    line_num = line_num + 1

  end

  # Check if there are any left over sections unaccounted for!
  if not asil_a_sections.empty?
    puts "ERROR - You need to update MemMapSel.h for the following ASIL A sections:"
    puts asil_a_sections
    exit -1
  end

  if not asil_qm_sections.empty?
    puts "ERROR - You need to update MemMapSel.h for the following ASIL QM sections:"
    puts asil_qm_sections
    exit -1
  end

end


# Command Line Support ###############################
if ($0 == __FILE__)

  if ARGF.argv.size != 2
    puts "Usage: checkMemMap.rb <memmap_path> <src_path>"
    exit
  end

  memmap     = ARGF.argv[0]
  src_dir    = ARGF.argv[1]

  memmap     = File.expand_path(memmap)
  src_dir    = File.expand_path(src_dir)


  if File.exists?(memmap) and Dir.exists?(src_dir)

    FileUtils.cd(src_dir)

    # Check source files consistency
    a_sections,qm_sections = check_src_files( get_source_files() )

    a_sections.uniq!
    qm_sections.uniq!

    check_memmap_file( memmap, a_sections, qm_sections, 'START' )
    check_memmap_file( memmap, a_sections, qm_sections, 'STOP' )

  else
    puts "Error: Source path '#{src_dir}' or MemMap file '#{memmap}' does not exist."
  end

end

