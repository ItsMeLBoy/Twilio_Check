# !/bin/bash
# JAVAGHOST TWILIO CHECKER - CREATED BY : ./LAZYBOY - JAVAGHOST TEAM

# COLOR ( BOLD )
RED="\e[1;31m"
GREEN="\e[1;32m"
YELLOW="\e[1;33m"
BLUE="\e[1;34m"
MAGENTA="\e[1;35m"
CYAN="\e[1;36m"
WHITE="\e[1;37m"

# BASE URL TWILIO API
BASE_URL="https://api.twilio.com/2010-04-01"

# EDIT NUMBER FOR TEST MSG
TO_NUMBER="+12546295126"

# MESSAGE TO SEND
BODY_MSG="JAVAGHOST-#MSG${RANDOM}"

# DATE
LOG_DATE=$(date +"%Y-%m-%d")

# CREATE DIR
if [[ ! -d Results ]]; then
	# CREATE OUTPUT FILES
	mkdir Results
	OUTPUT_FILES=("TWILIO_CANT_GET_NUM" "TWILIO_CAN_SEND" "TWILIO_CANT_SEND" "TWILIO_TRIAL" "TWILIO_DEAD_AUTH" "TWILIO_TEST_ACC" "REGION_NOT_SUPPORT" "INVALID_FROM_NUMBER" "UNKNOWN_ERROR")
	for LST_OUTPUT in ${OUTPUT_FILES[@]}; do
		touch "Results/${LST_OUTPUT}-${LOG_DATE}.txt" TWILIO_AUTH.tmp
	done
fi

# BANNER
echo -e '''
				\e[1;37m
		     ┌┬┐┬ ┬┬┬  ┬┌─┐   ┌─┐
		      │ │││││  ││ │───│  
		      ┴ └┴┘┴┴─┘┴└─┘   └─┘
		 - JAVAGHOST TWILIO CHECKER -
'''

# ASK OPTION
read -p "$(echo -e "${WHITE}[ ${GREEN}? ${WHITE}] TYPE [ ${GREEN}1 ${WHITE}] FOR SINGLE CHECK OR TYPE [ ${GREEN}2 ${WHITE}] FOR MASS CHECK : ${GREEN}")" ASK_OPT

# CHECK OPTIONS
if [[ $ASK_OPT == "1" ]]; then
	# ASK TWILIO AUTH
	read -p "$(echo -e "\n${WHITE}[ ${GREEN}? ${WHITE}] INPUT TWILIO SID   : ${GREEN}")" ASK_SID
	read -p "$(echo -e "${WHITE}[ ${GREEN}? ${WHITE}] INPUT TWILIO TOKEN : ${GREEN}")" ASK_TOKEN
	if [[ -z $ASK_SID ]] || [[ -z $ASK_TOKEN ]] ; then
		echo -e "${WHITE}[ ${RED}ERROR ${WHITE}] - ${RED}PLEASE INPUT VALID TWILIO AUTH${WHITE}"
		exit
	else
		echo "${ASK_SID}:${ASK_TOKEN}" > TWILIO_AUTH.tmp
	fi
elif [[ $ASK_OPT == "2" ]]; then
	# INFO
	echo -e "${WHITE}[ ${GREEN}! ${WHITE}] PLEASE MAKE SURE YOUR LIST USES THE DELIMITER '${GREEN}:${WHITE}' [ E.G : ${GREEN}SID:TOKEN ${WHITE}]"
	
	# ASK FILES
	read -p "$(echo -e "${WHITE}[ ${GREEN}? ${WHITE}] INPUT YOUR LIST TWILIO AUTH : ${GREEN}")" ASK_FILE
	if [[ ! -e $ASK_FILE ]]; then
		echo -e "${WHITE}[ ${RED}ERROR ${WHITE}] - ${RED}LIST NOT FOUND IN YOUR DIRECTORY${WHITE}"
		exit
	else
		if [[ $(file $ASK_FILE) =~ "line terminators" ]]; then
			# CONVERT DOS FORMAT TO UNIX FORMAT
			sed -i 's/\x0D$//' $ASK_FILE
			cat $ASK_FILE | sort -u > TWILIO_AUTH.tmp
		else
			cat $ASK_FILE | sort -u > TWILIO_AUTH.tmp
		fi
	fi
else
	echo -e "${WHITE}[ ${RED}ERROR ${WHITE}] - ${RED}YOU SELECTED WRONG OPTION${WHITE}"
	exit
fi

# FUNC FOR MAKING TWILIO REQUEST
function TWILIO_REQ(){
	curl -sXGET "${BASE_URL}/${1}" -u "${TWILIO_AUTH}"
}

# MAIN SCRIPT
for TWILIO_AUTH in $(cat TWILIO_AUTH.tmp); do
	# GET SID VALUE FROM TWILIO AUTH
	TWILIO_SID=$(echo "${TWILIO_AUTH}" | cut -d ":" -f1)
	CHECK_AUTH=$(TWILIO_REQ "Accounts/${TWILIO_SID}.json")

	# CHECKING TWILIO AUTH
	if [[ $CHECK_AUTH =~ "friendly_name" ]]; then
	
		# GET INFROMATION ABOUT THE SID + TOKEN
		GET_TYPE_ACC=$(TWILIO_REQ "Accounts.json" | grep -Po '"type": "\K[^"]+')
		GET_FROM_NUM=$(TWILIO_REQ "Accounts/${TWILIO_SID}/IncomingPhoneNumbers.json" | grep -Po '"(incoming_phone_numbers|phone_number)": "\K[^"]+')
		GET_BALANCE=$(TWILIO_REQ "Accounts/${TWILIO_SID}/Balance.json" | grep -Po '"(currency|balance)": "\K[^"]+' | sed -n '1{h;d};2{p;x;};p' | sed '/./{:a;N;s/\n\(.\)/ \1/;ta}')
		GET_ERROR_MSG=$(echo $CHECK_AUTH | grep -Po '"more_info": "\K[^"]+')

		if [[ $GET_TYPE_ACC =~ "Full" ]]; then
			if [[ -z $GET_FROM_NUM ]]; then
				echo -e "\n ${WHITE}[ ${GREEN}AUTH ${WHITE}] - ${GREEN}${TWILIO_SID}\n ${WHITE}[ ${GREEN}? ${WHITE}] ACC TYPE : ${GREEN}FULL\n ${WHITE}[ ${GREEN}$ ${WHITE}] BALANCE  : ${GREEN}${GET_BALANCE}\n ${WHITE}[ ${GREEN}* ${WHITE}] FROM NUM : ${RED}FAILED FOR GET FROM NUMBER\n${WHITE} [ ${GREEN}? ${WHITE}] STATUS   : ${RED}SKIPPED FOR CHECK SEND${WHITE}"
				echo "TWILIO AUTH : ${TWILIO_AUTH}-${GET_BALANCE}:FAILED GET FROM NUM [ ACC TYPE : FULL ]" >> "Results/TWILIO_CANT_GET_NUM-${LOG_DATE}.txt"
			else
				# SHOW INFORMATION
				echo -e "\n ${WHITE}[ ${GREEN}AUTH ${WHITE}] - ${GREEN}${TWILIO_SID}\n ${WHITE}[ ${GREEN}? ${WHITE}] ACC TYPE : ${GREEN}FULL\n ${WHITE}[ ${GREEN}$ ${WHITE}] BALANCE  : ${GREEN}${GET_BALANCE}"

				# GET LIST FN
				TOTAL_FN=$(echo "${GET_FROM_NUM}" | tr " " "\n" | wc -l)
				echo -e " ${WHITE}[ ${GREEN}? ${WHITE}] FOUND    ${WHITE}: ${GREEN}${TOTAL_FN} FROM NUMBER"
				echo -e " ${WHITE}[ ${GREEN}! ${WHITE}] ${YELLOW}TRYING CHECK SEND USING ONE OF THE ${WHITE}: ${GREEN}${TOTAL_FN} FROM NUMBER - UNTIL FOUND WORK FOR SEND"

				# TEST SENDING MSG
				for LIST_FN in $(echo "${GET_FROM_NUM}" | tr " " "\n"); do
					# SENDING MSG
					CHECK_SEND=$(curl -sXPOST "${BASE_URL}/Accounts/${TWILIO_SID}/Messages.json" \
											--data-urlencode "Body=${BODY_MSG}" \
											--data-urlencode "From=${LIST_FN}" \
											--data-urlencode "To=${TO_NUMBER}" \
											-u "${TWILIO_AUTH}")

					# CHECKING RESPONSE SENDING MSG
					if [[ $CHECK_SEND =~ "sent" || $CHECK_SEND =~ "queued" || $CHECK_SEND =~ "delivered" ]]; then
						echo -e "  ${WHITE}[ ${YELLOW}* ${WHITE}] FROM NUMBER : ${GREEN}${LIST_FN} ${WHITE}- ${GREEN}SUCCESS SEND TO NUM : ${GREEN}${TO_NUMBER}${WHITE}"
						echo "TWILIO AUTH : ${TWILIO_AUTH} - ${GET_BALANCE} - ${LIST_FN} : WORK SEND TO US NUMBER [ ACC TYPE : FULL ]" >> "Results/TWILIO_CAN_SEND-${LOG_DATE}.txt"
						break
					elif [[ $CHECK_SEND =~ "failed" || $CHECK_SEND =~ "undelivered" ]]; then
						echo -e "  ${WHITE}[ ${YELLOW}* ${WHITE}] FROM NUMBER : ${RED}${LIST_FN} ${WHITE}- ${RED}FAILED SEND TO NUM : ${RED}${TO_NUMBER}${WHITE}"
						echo "TWILIO AUTH : ${TWILIO_AUTH} - ${GET_BALANCE} - ${LIST_FN} : FAILED SEND TO US NUMBER [ ACC TYPE : FULL ]" >> "Results/TWILIO_CANT_SEND-${LOG_DATE}.txt"
					elif [[ $CHECK_SEND =~ "Permission to send an SMS has not been enabled" ]]; then
						echo -e "  ${WHITE}[ ${YELLOW}* ${WHITE}] FROM NUMBER : ${RED}${LIST_FN} ${WHITE}- ${RED}CANT SEND TO REGION WITH CODE ${WHITE}: ${RED}$(echo "${TO_NUMBER}" | head -c2)${WHITE}"
						echo "TWILIO AUTH : ${TWILIO_AUTH} - ${GET_BALANCE} - ${LIST_FN} : FAILED SEND - REGION NOT SUPPORT [ ACC TYPE : FULL ]" >> "Results/REGION_NOT_SUPPORT-${LOG_DATE}.txt"
					elif [[ $CHECK_SEND =~ "The From phone number" ]]; then
						echo -e "  ${WHITE}[ ${YELLOW}* ${WHITE}] FROM NUMBER : ${RED}${LIST_FN} ${WHITE}- ${RED}FAILED SEND ${WHITE}[ ${RED}INVALID FROM NUMBER ${WHITE}]"
						echo "TWILIO AUTH : ${TWILIO_AUTH} - ${GET_BALANCE} - ${LIST_FN} : FAILED SEND - INVALID FN [ ACC TYPE : FULL ]" >> "Results/INVALID_FROM_NUMBER-${LOG_DATE}.txt"
					else
						echo -e "  ${WHITE}[ ${YELLOW}* ${WHITE}] FROM NUMBER : ${RED}${LIST_FN} ${WHITE}- ${RED}CHECK SEND UNKNOWN ERROR${WHITE}"
						echo "TWILIO AUTH : ${TWILIO_AUTH} - ${GET_BALANCE} - ${LIST_FN} : FAILED SEND - UNKNOWN ERROR TEST SEND [ ACC TYPE : FULL ]" >> "Results/UNKNOWN_ERROR-${LOG_DATE}.txt"
					fi
					# SENDING MSG
				done
			fi
		elif [[ $GET_TYPE_ACC =~ "Trial" ]]; then
			echo -e "\n ${WHITE}[ ${GREEN}AUTH ${WHITE}] - ${GREEN}${TWILIO_SID}\n ${WHITE}[ ${GREEN}? ${WHITE}] ACC TYPE : ${GREEN}TRIAL\n ${WHITE}[ ${GREEN}$ ${WHITE}] BALANCE  : ${GREEN}${GET_BALANCE}\n ${WHITE}[ ${GREEN}? ${WHITE}] STATUS   : ${RED}SKIP FOR CHECK SEND${WHITE}"
			echo "TWILIO AUTH : ${TWILIO_AUTH} - ${GET_BALANCE} - [ ACC TYPE : TRIAL ]" >> "Results/TWILIO_TRIAL-${LOG_DATE}.txt"
		else
			echo -e "\n ${WHITE}[ ${RED}AUTH ${WHITE}] - ${GREEN}${TWILIO_SID} : ${RED}UNKNOWN ERROR${WHITE}"
			echo "TWILIO AUTH : ${TWILIO_AUTH} - UNKNOWN ERROR CHECKING TYPE ACC" >> "Results/UNKNOWN_ERROR-${LOG_DATE}.txt"
		fi
	elif [[ $CHECK_AUTH =~ "Test Account" ]]; then
		echo -e "\n ${WHITE}[ ${RED}AUTH ${WHITE}] - ${GREEN}${TWILIO_SID} : ${RED}TEST ACCOUNT - SKIPPED FOR GET ANOTHER INFORMATION${WHITE}"
		echo "TWILIO AUTH : ${TWILIO_AUTH} - TEST ACCOUNT - MORE INFO ABOUT THIS : ${GET_ERROR_MSG}" >> "Results/TWILIO_TEST_ACC-${LOG_DATE}.txt"
	elif [[ $CHECK_AUTH =~ "Authenticate" ]]; then
		echo -e "\n ${WHITE}[ ${RED}AUTH ${WHITE}] - ${GREEN}${TWILIO_SID} : ${RED}BAD AUTH${WHITE}"
		echo "TWILIO AUTH : ${TWILIO_AUTH} - DEAD SID AND TOKEN" >> "Results/TWILIO_DEAD_AUTH-${LOG_DATE}.txt"
	else
		echo -e "\n ${WHITE}[ ${RED}AUTH ${WHITE}] - ${GREEN}${TWILIO_SID} : ${RED}UNKNOWN ERROR${WHITE}"
		echo "TWILIO AUTH : ${TWILIO_AUTH} - UNKNOWN ERROR CHECKING ACC" >> "Results/UNKNOWN_ERROR-${LOG_DATE}.txt"
	fi
done

# REMOVE TMP FILES
if [[ -e TWILIO_AUTH.TMP ]]; then
	rm TWILIO_AUTH.tmp
fi

echo -e "\n${WHITE}[ ${GREEN}+ ${WHITE}] ${GREEN}GOOD TWILIO SAVED IN : ${GREEN}$(pwd)/Results/TWILIO_CAN_SEND-${LOG_DATE}.txt${WHITE}"
# END
