module utils.ip_cipher;

import std.stdio;
import std.array;
import std.string;
import std.conv;
import std.algorithm;
import std.traits;
import std.regex;
import std.file;
import utils.config;

/**
 * Static arrays used to generate the cipher
 */
immutable int numberOfIPNumbers = 11; // this is the number of choices for the index (0-9 + a null) 
immutable int ipAddressLength = 12; 

/**
 * This is a pretty basic cipher.
 * We encode the cipher as 15 word 
 * sentence with the format 
 * contained in the configuration
 * file.
 * 
 * 
 * The numbers are offset by their placement in the sentence.
 **/
string encodeSentence( string ipAddress, IPSyncConfig c){
	
	string getNextWord (string type, ulong index){
		auto arr = c.keySet.contains(type) ? c.data[type] : null;
		if (arr != null)
			return arr[index];
		else
			return type;
	}
	
	// first split up the values
	string[] sentence = c.data["sentence"]; 
	auto numbers = getNumbers ( ipAddress );
	if (numbers is null)
		return null;
	else {
		/++
		 + Walk through the sentence and fill
		 + in the words using the numbers from
		 + the ip address
		 ++/
		int offset = 0;
		foreach (int i, ref string wordType; sentence){
			ulong index = offset < ipAddressLength ? numbers[offset] : 10 ;
			string word = getNextWord(wordType, (index + i) % numberOfIPNumbers );  // once we run out just fill in the extra words for fun
			if (word != wordType) {
				offset++; 
			}
			wordType = word;
			
			// makes the sentence look like a sentence
			if (i == 0) wordType = capitalize(wordType);
		}

		return join (sentence, " ");
	}
}

/**
 * Get the ip address back from the 
 * fun sentence.
 */
string decodeIP(string sent, IPSyncConfig c ){
	
	/+ contained method +/
	int getOriginalNumber(int wordIndex, int index){
		int temp = 0;
		for (int i = 0 ; ; i++){
			temp = wordIndex + numberOfIPNumbers * i - index;
			if (temp >= 0)
				break;
		}
		
		return temp;
	}
	
	int numberCounter = 0;
	auto ipAddress = appender!string();
	
	foreach (int i, string word; sent.split(" ")){
		// first get the word type array (noun, verb, etc
		auto arrayKey = c.data["sentence"][i];
		auto wordArray = c.keySet.contains(arrayKey) ? c.data[arrayKey] : null;
			
		if (wordArray != null){
			int wordIndex = cast (int) countUntil(wordArray, word);
			// because the first word is sometimes capitalized, try it again lowercases
			if (wordIndex < 0) wordIndex =  cast (int) wordArray.countUntil( word.toLower ); 
			// get the ip number
			auto number = to!string( getOriginalNumber(wordIndex, i) );
			ipAddress.put( number == "10" ? "" : number );
			
			// update our place in the array and 
			// add in the ip address string
			numberCounter++;
			if (numberCounter >= ipAddressLength)
				break;
			else if (numberCounter % 3 == 0 ) 
				ipAddress.put(".");
		}
	}
	return ipAddress.data.strip();
}

// demonstrating the function
unittest {
	auto sentence = encodeSentence("255.255.255.0");
	writeln(sentence);
	auto decoded = decodeIP(sentence);
	writeln(decoded);
}

/**
 * Take an ip address and convert 
 * it into an array of numbers for 
 * easy indexed word lookup in the 
 * arrays
 **/
int[] getNumbers( string ipAddress ){
	int[] numbers = new int[12];
	string[] numberPairs = ipAddress.split(".");
	
	if ( numberPairs.length != 4 ) {
		return null;
	}
	else {
		/++
		 + Loop over the four pairs of numbers and 
		 + add them to the array
		 ++/
		 auto pairNumber = 0;
		 foreach (string pair; numberPairs){
			// get a char pointer so that
			// we can get the correct characters
			auto chars = pair.toStringz;
			ulong len = pair.length;
			// add in the values that we have
			foreach (ulong i ; 0..len)
				numbers[i+pairNumber] = to!(int)(chars[i])-48; // assumes ascii/utf-8
			// add in a "null" value
			foreach (ulong i; len..3)
				numbers[i+pairNumber] = 10; // our marker for a null value 
			
			pairNumber += 3;
		}
		assert (numbers.length == ipAddressLength);
		return numbers;
	}
}

// first unit test, just checking getNumbers 
unittest{
	writeln (getNumbers("192.168.1.1") == [1, 9, 2, 1, 6, 8, 1, 10, 10, 1, 10, 10]);
}
