import std.stdio;
import std.file;
import std.net.curl;
import std.string;
import std.conv;
import std.array;
import std.exception;
import std.array;
import std.string;
import core.memory : GC;
import etc.c.curl; // the d bindings to the cURL lib

import utils.ip_cipher;
import utils.config;

alias std.file.write fileWrite;

immutable string ipaddressfilename = "ip_address.txt";

/**
 * Simple wrapper that writes out the 
 * new IP to a file.
 */
void writeToFile(string newIP){
	// update the login text file
	fileWrite(ipaddressfilename, newIP);
}

/**
 * Quick function to determine if 
 * the ip address is still valid 
 * or not
 **/
bool validateCurrentIP(){
	
	if ( !exists( ipaddressfilename ) ) // program's never been run so get the IP
		return false;
	else { // check to see if the old address is valid.  if not, update it
		auto http = HTTP( readText(ipaddressfilename).strip() );
		http.onReceiveHeader = (in char[] key, in char[] value) { writeln (key , ": ", value); };
		try {
			http.perform;
		}
		catch (Throwable o) {
			return false;
			writeln(o.msg);
		}
		return true;
	}
}

/**
 * This is bascially a cut and paste
 * from the cURL demo.
 * 
 * Note: Not sure if this should use GC malloc
 * or normal C malloc.
 * 
 **/
string getIPFromEmail(IPSyncConfig e){
		
	auto curl = curl_easy_init(); assert(curl);
	
	struct MemoryStruct {
		char* memory;
		size_t size;
	};
		
	MemoryStruct s;
	s.memory = cast(char *) GC.malloc(1);
	s.size = 0;

	static size_t getEmailText(void *userp, size_t size, size_t nmemb, void *contents){
		size_t realsize = size * nmemb;
		MemoryStruct *mem = cast(MemoryStruct *) userp;
		
		(*mem).memory = cast (char*) GC.realloc((*mem).memory, (*mem).size + realsize + 1);
		if((*mem).memory == null) {
			/* out of memory! */ 
			writeln("not enough memory (realloc returned NULL)\n");
			return 0;
		}
		
		memcpy(&((*mem).memory[(*mem).size]), contents, realsize);
		(*mem).size += realsize;
		(*mem).memory[(*mem).size] = 0;

		return realsize;
	}

	/**
	 * Sets all the parameters to 
	 * send 
	 **/

	curl_easy_setopt(curl, CurlOption.username,toStringz(e.data["username"][0]));
	curl_easy_setopt(curl, CurlOption.password, toStringz(e.data["password"][0]));
	curl_easy_setopt(curl, CurlOption.url, toStringz("imaps://imap.gmail.com:993/"~ e.data["folder"][0] ~ ";UID=*/;SECTION=TEXT"));
	curl_easy_setopt(curl, CurlOption.writefunction, &getEmailText);
	curl_easy_setopt(curl, CURLOPT_WRITEDATA, &s);
	auto res = curl_easy_perform(curl);	
	
	string emailText = to!string(s.memory);
	
	// avoid some memory leaks
	if(s.memory)
		GC.free(s.memory);
	
	// remove the curl memory options
	scope(exit) curl_easy_cleanup(curl);
	
	return emailText;
}


/**
 * This simple program is designed to 
 * check availabliity of an ip address. 
 * If the ip address is 
 **/
void main(){
	// get the configuration bits for email lookup
	// and sentence decoding 
	
	IPSyncConfig e = new IPSyncConfig();
	
	writeToFile( decodeIP( getIPFromEmail(e) , e) );
}
