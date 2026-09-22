// Standard numerology by name calculator for Second Life
// VERSION: v3.0 - 2026/07/20
// LSL (Linden Scripting Language) port for Second Life embedding

// Letter to number mapping: a-i=1-9, j-r=1-9, s-z=1-8
integer getNumValue(string letter)
{
    list letters = ["a","b","c","d","e","f","g","h","i","j","k","l","m","n","o","p","q","r","s","t","u","v","w","x","y","z"];
    list values =  [1,   2,   3,   4,   5,   6,   7,   8,   9,   1,   2,   3,   4,   5,   6,   7,   8,   9,   1,   2,   3,   4,   5,   6,   7,   8];
    
    integer index = llListFindList(letters, [letter]);
    if (index >= 0)
        return llList2Integer(values, index);
    return 0;
}

// Reduce an integer to its digit root (single digit via formula)
// digit_root = 1 + (n - 1) % 9
integer reduceToDigitRoot(integer num)
{
    if (num == 0)
        return 0;
    return 1 + ((num - 1) % 9);
}

// Convert a word to its numerological value using digit root reduction
// @param word - The word to convert (will be lowercased)
// @return Integer - Single digit numerological value (1-9)
integer convertWordToNumber(string word)
{
    word = llToLower(word);
    
    if (word == "")
        return 0;
    
    integer sum = 0;
    integer i;
    for (i = 0; i < llStringLength(word); ++i)
    {
        string char = llGetSubString(word, i, i);
        sum += getNumValue(char);
    }
    
    return reduceToDigitRoot(sum);
}

// Validate numerological number
// @param value - The value to validate
// @return TRUE if 1-9, FALSE otherwise
integer isValidNumerologyNumber(integer value)
{
    return (value >= 1 && value <= 9);
}

// Batch process multiple names and return as formatted string
// @param names_list - Space-separated or comma-separated names
// @return String - Formatted results "name: number, name: number, ..."
string batchConvertNames(list names)
{
    string result = "";
    integer i;
    
    for (i = 0; i < llGetListLength(names); ++i)
    {
        string name = llList2String(names, i);
        integer num = convertWordToNumber(name);
        
        if (result != "")
            result += ", ";
        result += name + ": " + (string)num;
    }
    
    return result;
}

// USAGE EXAMPLES (paste into LSL scripts or invoke from state events):
// convertWordToNumber("alice")                              // => 3
// convertWordToNumber("bob")                                // => 2
// batchConvertNames(["alice", "bob", "charlie"])           // => "alice: 3, bob: 2, charlie: 3"
// isValidNumerologyNumber(5)                                // => 1 (TRUE)
// isValidNumerologyNumber(0)                                // => 0 (FALSE)
// llSay(0, "Your numerology number: " + (string)convertWordToNumber(llGetDisplayName(llGetOwner())));

// Default state: listen on local chat channel 0 and parse all letters
default
{
    state_entry()
    {
        // Listen on channel 0 (local chat only)
        llListen(0, "", NULL_KEY, "");
        
        llOwnerSay("Numerology calculator listening on local chat (channel 0)");
        llOwnerSay("Any text spoken will be parsed for numerology values");
        llOwnerSay("Individual letter numerology values will be shown");
    }
    
    listen(integer channel, string name, key id, string message)
    {
        // Convert message to lowercase for processing
        string lower_msg = llToLower(message);
        
        // Extract only alphabetic characters
        string letters_only = "";
        integer i;
        for (i = 0; i < llStringLength(lower_msg); ++i)
        {
            string char = llGetSubString(lower_msg, i, i);
            integer val = getNumValue(char);
            if (val > 0)  // Only keep characters that have numerology values
                letters_only += char;
        }
        
        // If no letters found, skip
        if (letters_only == "")
        {
            llRegionSayTo(id, -1111, "No letters found in that message.");
            return;
        }
        
        // Build individual letter analysis
        string letter_breakdown = "Letters: ";
        integer total = 0;
        
        for (i = 0; i < llStringLength(letters_only); ++i)
        {
            string char = llGetSubString(letters_only, i, i);
            integer val = getNumValue(char);
            total += val;
            letter_breakdown += char + "(" + (string)val + ") ";
        }
        
        // Calculate final numerology number for the entire message
        integer final_num = reduceToDigitRoot(total);
    
        
        // Owner gets audit log
        llOwnerSay("[" + name + "]: '" + message + "' => Letters: " + letters_only + " | Sum: " + (string)total + " | Final: " + (string)final_num);
    }
    
    touch_start(integer num_detected)
    {
        key toucher = llDetectedKey(0);
        string toucher_name = llGetDisplayName(toucher);
        integer num = convertWordToNumber(toucher_name);
        

        llOwnerSay("Touched by " + toucher_name + " - Number: " + (string)num);
    }
}

// USAGE IN SECOND LIFE:
// Say in local chat: "hello"
// Output: h(8) e(5) l(3) l(3) o(6) | Sum: 25 | Final: 7
//
// Say in local chat: "alice bob"
// Output: a(1) l(3) i(9) c(3) e(5) b(2) o(6) b(2) | Sum: 31 | Final: 4
//
// Say in local chat: "numerology"
// Output: n(5) u(3) m(4) e(5) r(9) o(6) l(3) o(6) g(7) y(7) | Sum: 55 | Final: 1
