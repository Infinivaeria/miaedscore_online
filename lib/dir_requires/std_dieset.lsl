// Dice roller based on character count - LSL port from Ruby
// VERSION: v4.0 - 2026/07/20
// Listens on local chat, rolls dice based on character count (including emojis)
// Outputs to channel 1111 and owner chat

// Configuration
integer DIE_SIDES = 2;      // 2-sided die (1 or 2 per roll)
integer NUMDIE_SET = 100;   // Maximum dice rolls allowed

// Roll a single die with specified number of sides
// @param sides - Number of sides on the die
// @return Integer - Random result from 1 to sides
integer rollDie(integer sides)
{
    return 1 + llFloor(llFrand((float)sides));
}

// Process multiple dice rolls and sum the results
// @param num_dice - Number of times to roll the die
// @return Integer - Sum of all dice rolls
integer processDiceRolls(integer num_dice)
{
    integer sum = 0;
    integer i;
    
    // Cap at NUMDIE_SET to prevent script overload
    if (num_dice > NUMDIE_SET)
        num_dice = NUMDIE_SET;
    
    for (i = 0; i < num_dice; ++i)
    {
        sum += rollDie(DIE_SIDES);
    }
    
    return sum;
}

// Get length of string (counts all characters including emojis)
// LSL's llStringLength counts UTF-8 characters correctly
integer getMessageLength(string message)
{
    return llStringLength(message);
}

// Default state: listen on local chat and process dice rolls
default
{
    state_entry()
    {
        // Listen on channel 0 (local chat)
        llListen(0, "", NULL_KEY, "");
        
        llOwnerSay("=== Dice Roller Active ===");
        llOwnerSay("Configuration: " + (string)DIE_SIDES + "-sided die");
        llOwnerSay("Max dice rolls: " + (string)NUMDIE_SET);
        llOwnerSay("Listening on local chat (channel 0)");
        llOwnerSay("Results broadcast to channel 1111");
    }
    
    listen(integer channel, string name, key id, string message)
    {
        // Get the length of the message (all characters, including emojis)
        integer char_count = getMessageLength(message);
        
        // Use character count as number of dice to roll
        integer dice_rolls = processDiceRolls(char_count);
        
        // Calculate average per die
        float average = (float)dice_rolls / (float)char_count;
        
        // Build output message
        string result = "[" + name + "] Message length: " + (string)char_count + " chars | " + 
                        (string)char_count + "d" + (string)DIE_SIDES + " = " + (string)dice_rolls + 
                        " (avg: " + llGetSubString((string)average, 0, 3) + ")";
        
        // Broadcast to channel 1111
        llSay(1111, result);       
       
        
        // Owner gets full audit log
        llOwnerSay(result);
        //llOwnerSay("  Raw message: '" + message + "'");
    }
    
    touch_start(integer num_detected)
    {
        key toucher = llDetectedKey(0);
        string toucher_name = llGetDisplayName(toucher);
        
        // Roll based on toucher's display name length
        integer name_len = getMessageLength(toucher_name);
        integer roll_result = processDiceRolls(name_len);
        
        
        llOwnerSay("Touched by " + toucher_name + " - Name roll: " + (string)name_len + "d" + 
                   (string)DIE_SIDES + " = " + (string)roll_result);
    }
}

// USAGE EXAMPLES:
// Say in local chat: "hi"
//   Length: 2 chars | Result: 2d2 = 3 (rolls two 2-sided dice, sums result)
//
// Say in local chat: "hello world"
//   Length: 11 chars | Result: 11d2 = 15 (rolls eleven 2-sided dice)
//
// Say in local chat: "🎲🎰"
//   Length: 2 chars | Result: 2d2 = 3 (emojis count as 1 character each)
//
// Touch object with name "Alice":
//   Name roll: 5d2 = 8 (5 characters in name, rolled twice per char)
