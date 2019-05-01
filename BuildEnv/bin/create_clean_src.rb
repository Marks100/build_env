#!/usr/bin/env ruby

require 'FileUtils'

SEL_MODULE_FILE  = /\b(([A-Z]+)(_[A-Z]+)*)(\w*)\.([cChH])/

def get_source_files()

  list = Dir["**/*.[cChH]"]

  list.delete_if { |x| x =~ /template/i }
  list.delete_if { |x| x !~ SEL_MODULE_FILE }
  list.delete_if { |x| x =~ /_common/ }

  list
end

# Command Line Support ###############################
if ($0 == __FILE__)

  if ARGF.argv.size != 2
    puts "Usage: create_clean_src.rb <source_path> <dest_path>"
    exit
  end

  src_dir  = ARGF.argv[0]
  dest_dir = ARGF.argv[1]

  src_dir  = File.expand_path(src_dir)
  dest_dir = File.expand_path(dest_dir)

  if Dir.exists?(src_dir)

    FileUtils.cd(src_dir)

    list = get_source_files()

    list.each do |src_file|

      out_name = "#{dest_dir}\\#{src_file}"

      if not Dir.exists?(File.dirname(out_name))
         FileUtils.mkdir_p(File.dirname(out_name))
      end

      out_file = File.new(out_name, 'w')

      File.open(src_file, 'r') do |f|
        f.each_line do |line|

          if line !~ /ST(ART|OP)_SEC_/ and line !~ /placement\.h/

            line.gsub!(/CONSTP2CONST\s*\(\s*(\w+)\s*,.*\)\s+(\w+)/,'\1 const * const \2')
            line.gsub!(/CONSTP2VAR\s*\(\s*(\w+)\s*,.*\)\s+(\w+)/,'\1 * const \2')
            line.gsub!(/P2VAR\s*\(\s*(\w+)\s*,.*\)\s+(\w+)/,'\1 * \2')
            line.gsub!(/P2CONST\s*\(\s*(\w+)\s*,.*\)\s+(\w+)/,'\1 const * \2')
            line.gsub!(/P2FUNC\s*\(\s*(\w+)\s*,.+,\s*(\w+).*\)\s+(\w+)/,'\1 (* \2) \3')
            line.gsub!(/CONST\s*\(\s*(\w+)\s*,.*\)\s+(\w+)/,'\1 const \2')
            line.gsub!(/VAR\s*\(\s*(\w+)\s*,.*\)\s+(\w+)/,'\1 \2')
            line.gsub!(/FUNC\s*\(\s*(\w+)\s*,.*\)\s+(\w+)/,'\1 \2')
            line.gsub!(/STATIC/,'static')

            out_file.puts line
          end
        end
      end
    end

  else
    puts "Error: Source path '#{src_dir}' does not exist or is not a directory."
  end

end

