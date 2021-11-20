#! /bin/sh

# Set defaults.
FILE="$HOME/Documents/changelog"
DATE="$(date +"%Y-%m-%d")"

# Check if an entry already exists for the date, and if not, create one.
DATE_CHECK=$(grep "${DATE}" "${FILE}")
if [ -z "${DATE_CHECK}" ]; then
	echo "${DATE}" >>"${FILE}"
fi

# Write the change to the log.
if [ "$@" != "" ]; then
	echo "	$@" >>"${FILE}"
fi

# Print all the changes for the day.
DATE_LINE=$(grep -n "${DATE}" "${FILE}" | cut -d : -f 1 | tail -1)
tail -n +"${DATE_LINE}" "${FILE}"
