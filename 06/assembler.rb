#!/usr/bin/env ruby

dest_table = {
  nil => '000',
  'M' => '001',
  'D' => '010',
  'A' => '100',
  'MD' => '011',
  'AM' => '101',
  'AD' => '110',
  'AMD' => '111'
}

comp_table = {
  '0' => '0101010',
  '1' => '0111111',
  '-1' => '0111010',
  'D' => '0001100',
  'A' => '0110000',
  '!D' => '0001101',
  '!A' => '0110001',
  '-D' => '0001111',
  '-A' => '0110011',
  'D+1' => '0011111',
  'A+1' => '0110111',
  'D-1' => '0001110',
  'A-1' => '0110010',
  'D+A' => '0000010',
  'D-A' => '0010011',
  'A-D' => '0000111',
  'D&A' => '0000000',
  'D|A' => '0010101',
  'M' => '1110000',
  '!M' => '1110001',
  '-M' => '1110011',
  'M+1' => '1110111',
  'M-1' => '1110010',
  'D+M' => '1000010',
  'D-M' => '1010011',
  'M-D' => '1000111',
  'D&M' => '1000000',
  'D|M' => '1010101'
}

jump_table = {
  nil => '000',
  'JGT' => '001',
  'JEQ' => '010',
  'JGE' => '011',
  'JLT' => '100',
  'JNE' => '101',
  'JLE' => '110',
  'JMP' => '111'
}

symbol_table = {
  'SP' => 0,
  'LCL' => 1,
  'ARG' => 2,
  'THIS' => 3,
  'THAT' => 4,
  'SCREEN' => 16384,
  'KBD' => 24576
}

# Registers R0 through R15
(0..15).each do |n|
  symbol_table[('R' + n.to_s)] = n
end

input_file = ARGV[0]
input_lines = File.readlines(input_file)

stripped_lines = []

# Get rid of comments, blank lines as well as trailing and leading whitespace
input_lines.each do |line|
  line.sub! /\/\/.*/, ''
  
  case line
  when /^\s$/
    # No-op
  else
    stripped_lines << line.strip
  end
end

# Fill line labels into the symbol table
line_counter = 0
instruction_lines = []

stripped_lines.each do |line|
  match = line.match(/^\((.+)\)/)

  if match
    symbol_table[match.captures[0]] = line_counter
  else
    instruction_lines << line
    line_counter += 1
  end
end

# Here the instructions will be parsed into a more usable format; variables
# still need to be replaced with numerical addresses
processed_instructions = []

instruction_lines.each do |line|
  if line =~ /^@/
    address = line.slice(1, line.length)

    if address =~ /^\d+$/
      address = address.to_i
    end

    processed_instructions << {type: 'a', content: address}
  else
    dest_match = line.match(/^(.+)=/)
    jump_match = line.match(/;(.+)$/)

    if dest_match
      dest = dest_match.captures[0]
      # The +1 gets the equal sign 
      line = line.slice(dest.length + 1, line.length)
    end

    if jump_match
      jump = jump_match.captures[0]
      # The +1 gets the semicolon as well
      line = line.slice(0, line.length - (jump.length + 1))
    end

    comp = line

    processed_instructions << {
      type: 'c',
      content: [dest, comp, jump]
    }
  end
end

# Replace variables with numerical addresses
variable_counter = 16

processed_instructions.each do |instruction|
  if instruction[:type] == 'a'
    if instruction[:content].class == String
      unless symbol_table[instruction[:content]]
        symbol_table[instruction[:content]] = variable_counter
        variable_counter += 1
      end
    
      instruction[:content] = symbol_table[instruction[:content]]
    end
  end
end

# Finally render the output
output_lines = []
output_file = File.basename(input_file, '.*') + '.hack'

processed_instructions.each do |instruction|
  if instruction[:type] == 'a'
    output_lines << instruction[:content].to_s(2).rjust(16, '0')
  else
    dest, comp, jump = instruction[:content]
    dest = dest_table[dest]
    comp = comp_table[comp]
    jump = jump_table[jump]
   
    output_lines << '111' + comp + dest + jump
  end
end

File.open(output_file, 'w') do |f|
  output_lines.each do |line|
    f.write(line + "\n")
  end
end
