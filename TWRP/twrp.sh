#!/bin/bash


# Prints a formatted header; used for outlining what the script is doing to the user
function echoText() {
   RED="\033[01;31m"
   RST="\033[0m"

   echo -e ${RED}
   echo -e "$( for i in $( seq ${#1} ); do echo -e "-\c"; done )"
   echo -e "${1}"
   echo -e "$( for i in $( seq ${#1} ); do echo -e "-\c"; done )"
   echo -e ${RST}
}


# Creates a new line
function newLine() {
   echo -e ""
}


# Compiliation function
function compile() {
   # Parameters
   DEVICE=${1}


   # Directories
   SOURCE_DIR=${HOME}/TWRP
   OUT_DIR=${SOURCE_DIR}/out/target/product/${DEVICE}
   UPLOAD_DIR=${HOME}/shared/TWRP


   # File names
   COMP_FILE=recovery.img
   UPLD_FILE=twrp-${DEVICE}-$( date +%m%d%Y ).img
   FILE_FORMAT=twrp-${DEVICE}*


   # Clear the terminal
   clear


   # Start tracking time
   echoText "SCRIPT STARTING AT $( date +%D\ %r )"

   START=$( date +%s )


   # Change to the source directory
   echoText "MOVING TO SOURCE DIRECTORY"

   cd ${SOURCE_DIR}


   # Start syncing the latest sources
   echoText "SYNCING LATEST SOURCES"; newLine

   repo sync --force-sync


   # Setup the build environment
   echoText "SETTING UP BUILD ENVIRONMENT"; newLine

   . build/envsetup.sh


   # Prepare device
   newLine; echoText "PREPARING $( echo ${DEVICE} | awk '{print toupper($0)}' )"

   lunch omni_${DEVICE}-eng


   # Clean up
   echoText "CLEANING UP OUT DIRECTORY"; newLine

   mka clobber


   # Start building
   newLine; echoText "MAKING TWRP"; newLine
   NOW=$( date +"%Y-%m-%d-%S" )
   time mka recoveryimage 2>&1 | tee ${LOGDIR}/Compilation/twrp_${DEVICE}-${NOW}.log


   # If the compilation was successful, there will be a file in the format above in the out directory
   if [[ $( ls ${OUT_DIR}/${COMP_FILE} 2>/dev/null | wc -l ) != "0" ]]; then
      # Make the build result string show success
      BUILD_RESULT_STRING="BUILD SUCCESSFUL"



      # If the upload directory doesn't exist, make it; otherwise, remove existing files in UPLOAD_DIR
      if [[ ! -d "${UPLOAD_DIR}" ]]; then
         newLine; echoText "MAKING UPLOAD DIRECTORY"

         mkdir -p "${UPLOAD_DIR}"
      else
         newLine; echoText "CLEANING UPLOAD DIRECTORY"; newLine

         rm -vrf "${UPLOAD_DIR}"/*${FILE_FORMAT}*
      fi


      # Copy new files to UPLOAD_DIR
      newLine; echoText "MOVING FILE TO UPLOAD DIRECTORY"; newLine

      mv -v ${OUT_DIR}/${COMP_FILE} "${UPLOAD_DIR}"/${UPLD_FILE}


      # Upload the files
      newLine; echoText "UPLOADING FILE"; newLine

      . ${HOME}/upload.sh


      # Clean up out directory to free up space
      newLine; echoText "CLEANING UP OUT DIRECTORY"; newLine

      mka clobber


      # Go back home
      newLine; echoText "GOING HOME"

      cd ${HOME}

   # If the build failed, add a variable
   else
      BUILD_RESULT_STRING="BUILD FAILED"
   fi



   # Stop tracking time
   END=$( date +%s )
   echo -e ${RED}
   echo -e "-------------------------------------"
   echo -e "SCRIPT ENDING AT $( date +%D\ %r )"
   echo -e ""
   echo -e "${BUILD_RESULT_STRING}!"
   echo -e "TIME: $( echo $((${END}-${START})) | awk '{print int($1/60)" MINUTES AND "int($1%60)" SECONDS"}' )"
   echo -e "-------------------------------------"
   echo -e ${RST}; newLine

   # Add line to compilation log
   echo -e "$( date +%H:%M:%S ): ${BASH_SOURCE} ${DEVICE}" >> ${LOG}
   echo -e "${BUILD_RESULT_STRING} IN $( echo $((${END}-${START})) | awk '{print int($1/60)" MINUTES AND "int($1%60)" SECONDS"}' )\n" >> ${LOG}

   echo -e "\a"
}


# If the first parameter to the twrp.sh script is "all", we are running five builds for the devices we support; otherwise, it is just a device specific build
if [[ "${1}" == "all" ]]; then
   DEVICES="angler shamu bullhead hammerhead mako"

   for DEVICE in ${DEVICES}; do
      compile ${DEVICE}
   done

   cd ${HOME}
   cat ${LOG}
else
   compile ${1}
fi
