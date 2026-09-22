echo "Cleaning up old file(s)"
rm compiled_rb_file.rb
echo "Cleaning up old file(s) complete"
echo "Compiling"
ruby rustbyc.rb compile_rb_require_list.rblist compiled_rb_file.rb
ruby rustbyc.rb compile_rb_list.rblist compiled_rb_file.rb --strip-requires
ruby rustbytec.rb compiled_rb_file.rb main.rustby

echo "Compiled successfully"
rm compiled_rb_file.rb
echo "Cleaning up old file(s) complete"
echo "finished."
