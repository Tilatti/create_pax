#!/usr/bin/env bash

TAR="/usr/bin/env tar"

if [ $# -ne 2 ]; then
	echo -e "Usage: ${0} ARCHIVE VENDOR_IDENTIFIER < INI_FILE"
	echo -e "Example: ${0} archive.tar VENDOR < conf.ini"
	exit -1
fi

archive=$1
vendor=$2

# Remove the previous archive
if [ -e "$archive" ]; then
	rm "$archive"
fi

global_options=""
options=""
is_global=false
is_file=false

while read line # Read on the standard input
do
	# Ignore blank lines
	if [ -z "$line" ]; then
		continue
	fi

	if [ "$line" == "[global]" ]; then
		if $is_file; then
			echo "[global] section shall be only at the beginning"
			exit -1
		fi
		is_global=true
	elif [ "$line" == "[file]" ]; then
		if $is_file; then
			if [ ! -e $archive ]; then
				echo "[global] section not found"
				exit -1
			fi
			if [ -z $pathname ]; then
				echo "A [file] section has not 'pathname' property"
				exit -1
			fi
			# Add the previous file inside the archive with the corresponding PAX options
			${TAR} -r -v -f "$archive" --pax-option "$options" "$pathname"
		elif $is_global; then
			# Create the archive with only the global PAX options
			${TAR} -c -v -f "$archive" --format=pax --pax-option "$global_options" -T /dev/null
		fi
		options=""
		is_global=false
		is_file=true
	else
		# Parse a line with a property
		field=$(echo "$line" | cut -f1 -d=)
		value=$(echo "$line" | cut -f2 -d=)
		if [  "$field" == "pathname" ]; then
			if $is_global; then
				echo "'pathname' property is forbidden in the [global] section"
				exit -1
			fi
			pathname="$value"
		else
			if $is_global; then
				# Add the property to the global options
				if [ -z "$global_options" ]; then
					global_options="${vendor}.${field}=${value}"
				else
					global_options="${global_options},${vendor}.${field}=${value}"
				fi

			else
				# Add the property to the local options
				if [ -z "$options" ]; then
					options="${vendor}.${field}:=${value}"
				else
					options="${options},${vendor}.${field}:=${value}"
				fi
			fi
		fi
	fi
done

if [ ! -e $archive ]; then
	echo "[global] section not found."
	exit -1
fi
if [ -z $pathname ]; then
	echo "A [file] section has not 'pathname' property"
	exit -1
fi
# Add the last file inside the archive with the corresponding PAX options
${TAR} -r -v -f "$archive" --pax-option "$options" "$pathname"
