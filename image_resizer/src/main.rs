use std::collections::BTreeMap;
use std::collections::BTreeSet;
use std::collections::BinaryHeap;
use std::collections::HashMap;
use std::collections::HashSet;
use std::collections::LinkedList;
use std::collections::VecDeque;
use std::fs::File;
use std::io::BufReader;
use std::io::prelude::*;
use std::path::Path;
use std::process::Command;

use magnus::embed::init;
use magnus::{
    Error, RArray, RClass, RFile, RFloat, RHash, RModule, RObject, RRegexp, RString, RStruct, Ruby,
    Value, function, method, prelude::*, rb_assert, typed_data, value::Lazy, value::Opaque,
};

use std::env;
use std::mem::drop;
use std::thread::{self, sleep};

use std::io::Read;
use std::time::Duration;

extern crate md5;

// include proc macro crate
// include proc macro crate

fn main() -> Result<(), Box<dyn std::error::Error>> {
    let current_dir: String = env::current_dir().unwrap().display().to_string();
    let ruby: magnus::embed::Cleanup = unsafe { init() };

    let ruby_id = "3489075345bsedfnmhjkdaslfkaljsdhflkjahgfd899345893475893475dfgjkhdHSDJFHSDIKUEJK-3489075345bsedfnmhjkdaslfkaljsdhflkjahgfd899345893475893475dfgjkhdHSDJFHSDIKUEJK-3489075345bsedfnmhjkdaslfkaljsdhflkjahgfd899345893475893475dfgjkhdHSDJFHSDIKUEJK-3489075345bsedfnmhjkdaslfkaljsdhflkjahgfd899345893475893475dfgjkhdHSDJFHSDIKUEJK";

    // Load the Ruby bytecode as binary data
    let main_file_bytes: Vec<u8> = include_bytes!("main.rustby").to_vec();
    // Write the bytecode to a file in the current directory

    //get timestamp
    let timestamp = std::time::SystemTime::now()
        .duration_since(std::time::UNIX_EPOCH)
        .unwrap()
        .as_secs();

    let main_file_path: std::path::PathBuf = Path::new(&current_dir).join(timestamp.to_string());
    std::fs::write(&main_file_path, main_file_bytes)?;

    let local_time_compiled: i64 = std::time::SystemTime::now()
        .duration_since(std::time::UNIX_EPOCH)
        .unwrap()
        .as_secs() as i64;

    println!(
        "Compile time (seconds since UNIX_EPOCH): {}",
        local_time_compiled
    );
    println!("Evaluating Ruby bytecode...");

    let result: Result<RString, Error> = ruby.eval(&format!(
        r#########"

        # NOTE: CREATE A SERVER BACKEND URL DOWNLOADER THAT MAY BE IMPLEMENTED TO DOWNLOAD SCRIPTS, rujn thenm, then delete the remoteley for easy maintenance purposes...!

        local_time_compiled = '{}'

        p "HUDLink engine [is] active: ..."
        p "... Current Compile Difference/Local Time: "
        p local_time_compiled
        p Time.now.to_s
        p "Time Difference: " + (Time.now - Time.at(local_time_compiled.to_i)).to_s + " seconds"
        p " - RustbyVM"
        p "Ok..."

        id_tampering_hardcode = "3489075345bsedfnmhjkdaslfkaljsdhflkjahgfd899345893475893475dfgjkhdHSDJFHSDIKUEJK-3489075345bsedfnmhjkdaslfkaljsdhflkjahgfd899345893475893475dfgjkhdHSDJFHSDIKUEJK-3489075345bsedfnmhjkdaslfkaljsdhflkjahgfd899345893475893475dfgjkhdHSDJFHSDIKUEJK-3489075345bsedfnmhjkdaslfkaljsdhflkjahgfd899345893475893475dfgjkhdHSDJFHSDIKUEJK"
        id_tampering_rust_eval = '{}'

        exit if id_tampering_hardcode != id_tampering_rust_eval


        MAIN_FILE = '{}'


        # load_bytecode.rb
        main_data = File.binread(MAIN_FILE)
        compiled = RubyVM::InstructionSequence.load_from_binary(main_data)

        # Delete the file after loading
        File.delete(MAIN_FILE)

        compiled.eval

        puts "VM Taking A Break..."

        #sleep(0.5)

        'loaded_and_evaluated'
        "#########,
        local_time_compiled,
        ruby_id,
        main_file_path.display()
    ));

    // convert result to a string in a new variable
    let result_string = result.clone().unwrap();
    // compare the result variable to a harcoded string to ensure that the VM is not tampered with
    // if the result is tampered with, the VM will exit
    // if the result is not tampered with, the VM will continue to run the script

    // if the result is tampered with, the VM will exit
    println!("RustbyVM check: ...");
    assert_eq!(
        unsafe { result_string.to_string_lossy() },
        "loaded_and_evaluated"
    );
    println!("RustbyVM check: ...passed");

    let result: Result<RString, Error> = ruby.eval(
        r#########"
          r#"

          argv = ARGV.dup
          image = nil
          output = nil
          until argv.empty?
            a = argv.shift
            case a
            when '--image','-i'
              image = argv.shift
            when '--image_location_output','--image-location-output','-o'
              output = argv.shift
              when '--image-name','--image_name','-n'
              original_to_new_filename = argv.shift
            else
              image ||= a
              output ||= argv.shift if output.nil?
            end
          end
          raise 'usage' unless image && output

           Thread.new do
            create_image_thumbnail!(image_path: output, thumbnail_size: 350, thumbnail_path: "public/gallery_index/#{@user}/thumbnail_#{original_to_new_filename}")
          end
          Thread.new do
            resize_image!(image_path: output, size: 1920, resized_image_path: "public/gallery_index/#{@user}/resized_#{original_to_new_filename}")
          end


     #   image_reziser --image image.png --image-name new_name.png --image_location_output output.png

          [image, output]
        "#;

        'loaded_and_evaluated'
        "#########,
    );

    // delete the main.rustby file
    // delete the main.rustby file
    // std::fs::remove_file(&main_file_path)?;

    // Remove the temporary file
    //std::fs::remove_file(main_file_path)?;
    //println!("Result of Ruby evaluation: {}", result);

    //let evaluated: Result<Value, Error> = ruby.eval(&main_file);     //.map_err(|e| magnus::Exception::from(e))?;

    //let evaluated: Result<String, Error> = ruby.eval::<String>(&main_file);
    // Now you have access to the Ruby environment through the `ruby` variable.
    // You can use this to interact with Ruby objects, evaluate Ruby code, and more.

    // For example, let's evaluate a simple Ruby expression:
    // let result: i64 = ruby.eval("2 + 2").unwrap();

    // Enter your Macroquad game loop

    Ok(())
}
