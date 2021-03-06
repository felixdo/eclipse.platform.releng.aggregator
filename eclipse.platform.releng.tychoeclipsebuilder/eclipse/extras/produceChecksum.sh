#!/usr/bin/env bash

# this localBuildProperties.shsource file is to ease local builds to
# override some variables.
# It should not be used for production builds.
source localBuildProperties.shsource 2>/dev/null

echo "[DEBUG] Producing checksums starting"
echo "[DEBUG] current directory: ${PWD}"
if [[ -z "${SCRIPT_PATH}" ]]
then
  echo -e "\n\tWARNING: SCRIPT_PATH not defined in ${0##*/}"
else
  source "${SCRIPT_PATH}/bashUtilities.shsource"
  checkSumStart="$(date +%s )"
fi

# This checkSums script is called twice, once while publishing Eclipse DL site, again
# when publishing Equinox DL site. We use a simple heuristic to
# make use of "eclipse" or "equinox".
# TODO: better design to require it to be passed in?
currentDirectory="${PWD}"
equinoxPattern="^.*equinox.*$"
eclipsePattern="^.*eclipse.*$"
if [[ "${currentDirectory}" =~ $equinoxPattern ]]
then
  client="equinox"
elif [[ "${currentDirectory}" =~ $eclipsePattern ]]
then
  client="eclipse"
else
  echo -e "\n\t[ERROR]: Unknown client: ${client} in ${0##*/}\n"
  exit 1
fi

allCheckSumsSHA256=checksum/${client}-${BUILD_ID}-SUMSSHA256
allCheckSumsSHA512=checksum/${client}-${BUILD_ID}-SUMSSHA512

#  Remove the "all" files, here at beginning if they all ready exist,
#  so that subsequent calls can all use append (i.e. ">>")

if [[ -e ${allCheckSumsSHA256} ]]
then
  rm ${allCheckSumsSHA256}
fi
if [[ -e ${allCheckSumsSHA512} ]]
then
  rm ${allCheckSumsSHA512}
fi

#array of zipfiles
zipfiles=`ls *.zip`

for zipfile in ${zipfiles}
do
  # There is one zip file to not list, eclipse.platform.releng.aggregator-<hash>.zip, which is merely
  # a collected utility scripts used to run unit tests.
  aggrPattern="^eclipse.platform.releng.aggregator.*.zip$"
  if [[ ! "${zipfile}" =~ $aggrPattern ]]
  then
    echo [sha256] ${zipfile}
    sha256sum -b ${zipfile} | tee checksum/${zipfile}.sha256 >>${allCheckSumsSHA256}
    echo [sha512] ${zipfile}
    sha512sum -b ${zipfile} | tee checksum/${zipfile}.sha512  >>${allCheckSumsSHA512}
  fi
done

#array of tar.gzip files
gzipfiles=`ls *.gz`

for gzipfile in ${gzipfiles}
do
  echo [sha256] ${gzipfile}
  sha256sum -b ${gzipfile} | tee checksum/${gzipfile}.sha256 >>${allCheckSumsSHA256}
  echo [sha512] ${gzipfile}
  sha512sum -b ${gzipfile} | tee checksum/${gzipfile}.sha512 >>${allCheckSumsSHA512}
done


#array of .jar files
jarfiles=`ls *.jar`

for jarfile in ${jarfiles}
do
  echo [sha256] ${jarfile}
  sha256sum -b ${jarfile} | tee checksum/${jarfile}.sha256 >>${allCheckSumsSHA256}
  echo [sha512] ${jarfile}
  sha512sum -b ${jarfile} | tee checksum/${jarfile}.sha512 >>${allCheckSumsSHA512}
done

# We'll always try to sign checksum files, if passphrase file exists
echo "[DEBUG] Producing GPG signatures starting."
# We make double use of the "client". One to simplify signing script. Second to identify times in timefile.
# remember, this "HOME" is for genie.releng for production builds.
key_passphrase_file=${key_passphrase_file:-${HOME}/${client}-dev.passphrase}
if [[ -r $key_passphrase_file ]]
then
  signer=${signer:-${client}-dev@eclipse.org}
  signature_file256=${allCheckSumsSHA256}.asc
  signature_file512=${allCheckSumsSHA512}.asc
  fileToSign256=${allCheckSumsSHA256}
  fileToSign512=${allCheckSumsSHA512}

  cat ${key_passphrase_file} | gpg --local-user ${signer} --sign --armor --output ${signature_file256} --batch --yes --passphrase-fd 0 --detach-sig ${fileToSign256}
  cat ${key_passphrase_file} | gpg --local-user ${signer} --sign --armor --output ${signature_file512} --batch --yes --passphrase-fd 0 --detach-sig ${fileToSign512}
else
  # We don't treat as ERROR since would be normal in a "local build".
  # But, would be an ERROR in production build so could be improved.
  echo -e "\n\t[WARNING] The key_passphrase_file did not exist or was not readable.\n"
fi
# if SCRIPT_PATH not defined, we can not call elapsed time
if [[ -n "${SCRIPT_PATH}" ]]
then
  checkSumEnd="$(date +%s )"
  elapsedTime $checkSumStart $checkSumEnd "${client} Elapsed Time computing checksums"
fi
echo "[DEBUG] Producing checksums ended normally"
