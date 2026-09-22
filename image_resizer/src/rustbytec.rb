require 'rbconfig'

abort 'RubyVM::InstructionSequence not available' unless defined?(RubyVM::InstructionSequence)

input_file = ARGV[0]
output_file = ARGV[1]

script = File.read(input_file)
bytecode = RubyVM::InstructionSequence.compile(script)

bytecode_structure = bytecode
puts 'Bytecode generated'
File.binwrite(output_file, bytecode_structure.to_binary)
puts "Bytecode written to #{output_file}"
