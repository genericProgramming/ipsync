module utils.config;

import std.stdio;
import std.file;
import std.string;
import std.array;
import std.algorithm;
import std.range;
import std.regex;

immutable string configurationFileName = "ip_sync_config.txt";

/** 
 * Used to quickly parse the configuration file 
 * and make the information quickly available.
 * 
 * The class does not check to determine if the 
 * correct values are in the file.  It only 
 * checks to make sure a few basic keys are present.
 * 
 **/
class IPSyncConfig {
	
	// These are the four main keys that each file must have
	immutable string name = "username";
	immutable string pwd = "password";
	immutable string subject = "subject";
	immutable string sent = "sentence";
	
	string fileText;
	public string[][string] data;
	public SortedRange!(string[] , "a < b") keySet;
	
	public this (){
		this (configurationFileName);
	}
	
	public this (string configFile){
		
		if (!exists (configFile)){
			throw new Exception ("Error:  Configuration file not found");
		}
		
		fileText = readText(configFile);
		auto lines = std.string.split(fileText, "\n");
		
		/**
		 * loop through the configuration file
		 * and pull out the pieces.
		 **/
		foreach (int i, string line; lines){
			int index = cast (int) line.countUntil(":");
			if (index >= 0){
				auto keyValue = line[index+1..$];
				if (keyValue.canFind(","))
					data[line[0..index].strip()] = std.string.split(replace(keyValue, regex(r"\s+", "g"), ""),",") ;
				else 
					data[line[0..index].strip()] = [ keyValue.strip() ];
			}
		}
		
		// get the keys and sort so that 
		// when we check we can search in6
		// lg(n) time
		keySet = sort!("a < b")(data.keys);
		
		// assert that all of the needed keys can be found 
		foreach (string s ; [name, pwd, subject, sent])
			if (!keySet.contains(s)) throw new Exception ("Error in configuration file:  needed key (" ~ s ~ ") not found");
			
	}
}	

unittest{
	IPSyncConfig icp = new IPSyncConfig( "ip_sync_config.txt");
	writeln(icp.keySet);
	writeln(icp.keySet.contains("subject"));
	writeln(icp.data);
}


