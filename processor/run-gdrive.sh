#!/bin/bash

# For each demo on 

    #rm log.txt

    rclone lsf demo-7-5:/Unlabelled/ -R --fast-list  | grep ".dem" | while read line; do
    #cat gdrive-temp-list.txt  | grep "edan" | grep ".dem" | while read line; do

    filename=$(echo $line | xargs -L 1 basename | cut -d. -f1)

    if ! grep -q "$filename" Unlabelled-log.txt; then
        echo "processing $filename"
        echo "$line" >> Unlabelled-log.txt
    else
        echo "skipping $filename"
        continue
    fi
        echo rclone copyto "demo-7-5:/Unlabelled/$line" "./path_to_demos/$filename.dem" -vv --drive-chunk-size=256M --buffer-size=256M
        rclone copyto "demo-7-5:/Unlabelled/$line" "./path_to_demos/$filename.dem" -vv --drive-chunk-size=256M --buffer-size=256M

        python3 ./test.py ./path_to_demos/ 
        #message=$(python3 ./test.py ./path_to_demos/ 2>&1 )

        #if predictions.csv rows greater than 1
        if [ $(wc -l predictions.csv | cut -d' ' -f1) -gt 1 ]; then
            #for each name in predictions.csv echo name
            #name,confidence,id,file
            
            while IFS="," read -r rec_column1 rec_column2 rec_column3 rec_column4
            do
              echo "name: $rec_column1"
              echo "confidence: $rec_column2"
              echo "id: $rec_column3"
              echo "file: $rec_column4"
              echo ""
              
              avatarfull=$(curl "http://api.steampowered.com/ISteamUser/GetPlayerSummaries/v0002/?key=2B3382EBA9E8C1B58054BD5C5EE1C36A&steamids=${rec_column3}" | jq -r '.response.players[0].avatarfull' | sed -e 's/^"//' -e 's/"$//' )

            if grep -q "$rec_column3" "$filename.tmp"; then
                echo "skipped as already alerted on this player"

            else

                #if confidence is above 0.99 then echo high
                if [[ $(echo "$rec_column2 > 0.99" | bc) == 1 ]]; then
                    title_txt="Cheater detected - ${rec_column3}"
                    else
                    title_txt="Possible cheater detected - ${rec_column3}"
                    fi
            
               echo "$rec_column3" >> "$filename.tmp"
                
                #if $rec_column3 count is greater than 1 then echo high
                if [ $(grep -c "$rec_column3" "predictions.csv") -gt 1 ]; then

                    DetectionCount=$(grep -c "$rec_column3" "predictions.csv")

                ./discord.sh \
                --webhook-url="https://discord.com/api/webhooks/XXXXXXXXXXXXXXX" \
                --username "Machine Learning Anti-Cheat" \
                --avatar "https://media.discordapp.net/attachments/970899577685303416/970952811980390410/icon.png" \
                --title "Cheater detected - ${rec_column3}" \
                --url "http://steamcommunity.com/profiles/${rec_column3}" \
                --color "0xFFFFFF" \
                --thumbnail "${avatarfull}" \
                --field "Player Name;""${rec_column1}""" \
                --field "SteamID64;""${rec_column3}""" \
                --field "Detection count from demo;""${DetectionCount}""" \
                --field  "$(echo "Demo;""${rec_column4}"" - "https://demos.kzg-gg.workers.dev/0:/"$filename".dem" " | jq -Rs . | cut -c 2- | rev | cut -c 2- | rev)" \
                --timestamp

                sleep 5s

                grep "$rec_column3" "predictions.csv" >> "$rec_column3.csv"
                ./discord.sh \
                --webhook-url="https://discord.com/api/webhooks/XXXXXXXXXXXXXXX" \
                --file "$rec_column3.csv" \
                --username "Machine Learning Anti-Cheat" \
                --avatar "https://media.discordapp.net/attachments/970899577685303416/970952811980390410/icon.png"

                sed -i '1s/^/name,confidence,steamid64,demo_name\n/' "$rec_column3.csv"
                csvsql --db mysql+mysqlconnector://$SQLDETAILS --insert --tables bans_kzg --no-create "$rec_column3.csv"

                echo "$rec_column3" >> "$filename.tmp"

                else

                #./discord.sh \
                --webhook-url="https://discord.com/api/webhooks/XXXXXXXXXXXXXXX" \
                --username "Machine Learning Anti-Cheat" \
                --avatar "https://media.discordapp.net/attachments/970899577685303416/970952811980390410/icon.png" \
                --title "${title_txt}" \
                --url "http://steamcommunity.com/profiles/${rec_column3}" \
                --color "0xFFFFFF" \
                --thumbnail "${avatarfull}" \
                --field "Player Name;""${rec_column1}""" \
                --field "SteamID64;""${rec_column3}""" \
                --field "Confidence;""${rec_column2}""" \
                --field  "$(echo "Demo;""${rec_column4}"" - "https://demos.kzg-gg.workers.dev/0:/"$filename".dem" " | jq -Rs . | cut -c 2- | rev | cut -c 2- | rev)" \
                --timestamp

                grep "$rec_column3" "predictions.csv" >> "$rec_column3.csv"

                sed -i '1s/^/name,confidence,steamid64,demo_name\n/' "$rec_column3.csv"
                csvsql --db mysql+mysqlconnector://$SQLDETAILS --insert --tables bans_kzg --no-create "$rec_column3.csv"

                echo "$rec_column3" >> "$filename.tmp"
                
                fi



            fi



            done < <(tail -n +2 predictions.csv)




        fi
        
        rm ./*.tmp
        rm ./*.csv
        rm ./path_to_demos/*.dem



    

done

#if failed-demos.txt exists
if [ -f "failed-demos.txt" ]; then
    ./discord.sh \
    --webhook-url="https://discord.com/api/webhooks/XXXXXXXXXXXXXXX" \
    --file "failed-demos.txt" \
    --username "Machine Learning Anti-Cheat" \
    --avatar "https://media.discordapp.net/attachments/970899577685303416/970952811980390410/icon.png"

    rm "failed-demos.txt"
fi
