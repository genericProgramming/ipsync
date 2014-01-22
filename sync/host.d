module sync.host;

import std.stdio;
import std.file;
import std.array;
import std.datetime;
import std.conv;
import std.string;
import std.net.curl;

import utils.ip_cipher;
import utils.config;

immutable string listOfIPs = "ip_change_tracker.csv";
 
/******************************************
 * The goal of this project is to create a 
 * clean and simple way to monitor the 
 * dynamically assigned IP of my home 
 * computer using gmail as a remote
 * server.
 * 
 * This function also tracks the frequency 
 * of ip address reassignments.
 ******************************************/
string fileText;

/+
 + Sends the ciphered email to 
 + my email address
 +/
void sendEmail(string address){
		
	IPSyncConfig e = new IPSyncConfig();
	
	auto email = e.data["username"][0] ~ "@gmail.com";
	
	// Send an email with SMTPS
	auto smtp = SMTP("smtps://smtp.gmail.com");
	smtp.setAuthentication(email, e.data["password"][0]);
	smtp.mailTo = [email];
	smtp.mailFrom = email;
	smtp.message = "Subject:"~e.data["subject"][0]~"\n" ~ encodeIP(address, e);
	smtp.perform();
	
}

/++
 + Check out ip_cipher to see how the cipher code 
 + works
 +/
string encodeIP(string ip, IPSyncConfig i){	
	return encodeSentence(ip, i);
}

/++
 + This first function simply gets the 
 + computer's currently assigned IP 
 + from the web.
 +/
string getCurrentIP(){
	return strip(to!string(get("http://ipecho.net/plain")));
}

/++
 + Get the previous IP from 
 + the list of IP addresses
 +/
string getPreviousIP(){
	auto prevIP = "";
	// open the file and load the last line
	if (exists(listOfIPs)){
		auto file = File(listOfIPs);
		auto firstLine = true;
		auto listText = appender!string();
		string line;
		
		/++
		 + This is looping through the entire file
		 + and saving the old ip address to be 
		 + re-written out again
		 ++/
		while ((line = file.readln()) !is null){
			if (firstLine) {
				prevIP = line.split(",")[1]; 
				// check for the newline character and remove
				// it if necessary
				if (prevIP.length > 0 && prevIP[$-1..$] == "\n")
					prevIP = strip(prevIP[0..$-1]);
				firstLine = false;
				}
			listText.put(line); 
		}
		fileText = listText.data;
		file.close();
	}
	else {
		auto file = File (listOfIPs, "w");
		file.close();
	}
	return prevIP;
}

void main(string[] args)
{
	
	// get the current and previous IP
	auto prevIP = getPreviousIP();
	auto currentIP = getCurrentIP();
	// out list
	auto newList = appender!string();
	
	/+ 
	 + If the IP's are equal do nothing, 
	 + otherwise send the new updated 
	 + IP to the email address. 
	 +/
	auto currentTime = to!string(Clock.currTime);
	auto newRow = [currentTime, currentIP];
	if (prevIP != currentIP) {
		writeln("Previous IP: ", prevIP, " Current IP: ", currentIP);
		
		// write out the ip to the file and close
		auto file = File (listOfIPs, "w");
		file.writeln(join (newRow, ","));
		file.write(fileText);
		file.close();
		
		sendEmail(currentIP);
	}	
}
