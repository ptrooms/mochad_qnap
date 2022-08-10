#!/bin/sh
# vim:textwidth=80:tabstop=4:shiftwidth=4:smartindent:autoindent

EMAIL_TO=ptr.ooms@gmail.com
EMAIL_FROM=qnap.ooms@pafo2.nl
MOCvSBINDIR=/share/homes/admin/mochad
MOCvVARRUNDIR=/share/homes/admin/mochad
MOCvVARLOGDIR=/share/homes/admin/mochad

CLIARGS="$*"					# Grab any args passed to safe_mochad
MOCvARGS="--raw-data -d"
# TTY=9						# TTY (if you want one) for mochad to run on
CONSOLE=yes					# Whether or not you want a console
NOTIFY=ptr.ooms@gmail.com		# Who to notify about crashes
# NOTIFY=${NOTIFY:-}				# Who to notify about crashes
#EXEC=/path/to/somescript			# Run this command if mochad crashes
#LOGFILE=${MOCvVARLOGDIR}/safe_mochad.log	# Where to place the normal logfile (disabled if blank)
SYSLOG=${SYSLOG:-}				# Which syslog facility to use (disabled if blank)
MACHINE=`hostname`				# To specify which machine has crashed when getting the mail
DUMPDROP=${DUMPDROP:-/share/homes/admin/mochad/tmp}
RUNDIR=${RUNDIR:-/share/homes/admin/mochad/tmp}
SLEEPSECS=8
MOCvPIDFILE=${MOCvVARRUNDIR}/mochad.pid

# comment this line out to have this script _not_ kill all mpg123 processes when
# mochad exits
KILLALLMPG123=1

# run mochad with this priority
PRIORITY=0

# set system filemax on supported OSes if this variable is set
# SYSMAXFILES=262144

# mochad allows full permissions by default, so set a umask, if you want
# restricted permissions.
#UMASK=022

# set max files open with ulimit. On linux systems, this will be automatically
# set to the system's maximum files open devided by two, if not set here.
# MAXFILES=32768

function send_mail() {
	# Takes one optional parameter to indicate error level as subject prefix ($1)
	echo "mochad notification email: Error level: $1"
	subject="mochad $MOCvSBINDIR"
	tail /share/MD0_DATA/homes/admin/mochad/mochad.log > /share/MD0_DATA/homes/admin/mochad/tailmessage.txt
	body=/share/MD0_DATA/homes/admin/mochad/tailmessage.txt
	timestamp=`date '+%F %T'`
	tmpfile="/share/MD0_DATA/homes/admin/mochad/sendmail.tmp"
	/bin/echo -e "Subject:$1 - $subject [$timestamp]\r" > "$tmpfile"
	/bin/echo -e "To: $EMAIL_TO\r" >> "$tmpfile"
	/bin/echo -e "From: $EMAIL_FROM\r" >> "$tmpfile"
	/bin/echo -e "\r" >> "$tmpfile"
	if [ -f "$body" ]; then
		#cat "$body" >> "$tmpfile"
		tail -50 "$body" >> "$tmpfile"
		/bin/echo -e "\r\n" >> "$tmpfile"
	else
		/bin/echo -e "$body\r\n" >> "$tmpfile"
	fi

	# --> sendmail: RCPT TO:<ptr.ooms@gmail.com> (553 5.7.1 <qnap.ooms@xs4all.nl>: Sender address rejected: not owned by user ptro@pafo2.nl)
	# /usr/sbin/sendmail -t < "$tmpfile"
	# rm $tmpfile
}


message() {
	echo "$1" >&2
	mymessage="$1"
	if test "x$SYSLOG" != "x" ; then
	    logger -p "${SYSLOG}.warn" -t safe_mochad[$$] "$1"
	fi
	if test "x$LOGFILE" != "x" ; then
	    echo "safe_mochad[$$]: $1" >> "$LOGFILE"
	fi
	send_mail "$mymessage" >&2
}

# Check if mochad is already running.  If it is, then bug out, because
# starting safe_mochad when mochad is running is very bad.
MYPID=`pidof mochad 2>/dev/null`
if test "x$MYPID" != "x" ; then
	message "mochad is already running as $MYPID .  $0 will exit now."
	echo "mochad is already running as $MYPID .  $0 will exit now."
	exit 1
fi

# since we're going to change priority and open files limits, we need to be
# root. if running mochad as other users, pass that to mochad on the command
# line.
# if we're not root, fall back to standard everything.
if test `id -u` != 0 ; then
	echo "Oops. I'm not root. Falling back to standard prio and file max." >&2
	echo "This is NOT suitable for large systems." >&2
	PRIORITY=0
	message "safe_mochad was started by `id -n` (uid `id -u`)."
else
	if `uname -s | grep Linux >/dev/null 2>&1`; then
		# maximum number of open files is set to the system maximum divided by two if
		# MAXFILES is not set.
		if test "x$MAXFILES" = "x" ; then
			# just check if file-max is readable
			if test -r /proc/sys/fs/file-max ; then
				MAXFILES=$(( `cat /proc/sys/fs/file-max` / 2 ))
			fi
		fi
		SYSCTL_MAXFILES="fs.file-max"
	elif `uname -s | grep Darwin /dev/null 2>&1`; then
		SYSCTL_MAXFILES="kern.maxfiles"
	fi


	if test "x$SYSMAXFILES" != "x"; then
		if test "x$SYSCTL_MAXFILES" != "x"; then
			sysctl -w $SYSCTL_MAXFILES=$SYSMAXFILES
		fi
	fi

	# set the process's filemax to whatever set above
	ulimit -n $MAXFILES

	if test ! -d ${MOCvVARRUNDIR} ; then
		mkdir -p ${MOCvVARRUNDIR}
		chmod 770 ${MOCvVARRUNDIR}
	fi

fi

if test "x$UMASK" != "x"; then
	umask $UMASK
fi

#
# Let mochad dump core
#
ulimit -c unlimited

#
# Don't fork when running "safely"
#
# set on top MOCvARGS=""
if test "x$TTY" != "x" ; then
	if test -c /dev/tty${TTY} ; then
		TTY=tty${TTY}
	elif test -c /dev/vc/${TTY} ; then
		TTY=vc/${TTY}
	else
		message "Cannot find specified TTY (${TTY})"
		exit 1
	fi
	MOCvARGS="${MOCvARGS} -v"
	if test "x$CONSOLE" != "xno" ; then
		MOCvARGS="${MOCvARGS} -c"
	fi
fi

if test ! -d "${RUNDIR}" ; then
	message "${RUNDIR} does not exist, creating"
	mkdir -p "${RUNDIR}"
	if test ! -d "${RUNDIR}" ; then
		message "Unable to create ${RUNDIR}"
		exit 1
	fi
fi

if test ! -w "${DUMPDROP}" ; then	
	message "Cannot write to ${DUMPDROP}"
	exit 1
fi

#
# Don't die if stdout/stderr can't be written to
#
trap '' PIPE

#
# Run scripts to set any environment variables or do any other system-specific setup needed
#

if test -d /etc/mochad/startup.d ; then
	for script in /etc/mochad/startup.d/*.sh; do
		if test -r ${script} ; then
			. ${script}
		fi
	done
fi

run_mochad()
{
	while :; do 

		if test "x$TTY" != "x" ; then
			cd "${RUNDIR}"
			echo "running tty $TTY"
			stty sane < /dev/${TTY}
			nice -n $PRIORITY ${MOCvSBINDIR}/mochad ${MOCvARGS} ${CLIARGS} > /dev/${TTY} 2>&1 < /dev/${TTY}  
		else
			# mochad --raw-data -d 2>&1 | ts %H:%M:%.S > mochad.log &
			cd "${RUNDIR}"
			echo "not running tty $TTY"
			# echo "${MOCvSBINDIR}/mochad ${MOCvARGS} ${CLIARGS} 2> mochad2.log 1 1> mochad1.log"
			# echo `${MOCvSBINDIR}/mochad ${MOCvARGS} ${CLIARGS} 2> mochad2.log 1 1> mochad1.log`
			# ( /share/homes/admin/mochad/mochad --raw-data -d 3>&1 1>&2- 2>&3- ) 2>&1 | ts > mochad2.log
			# /share/homes/admin/mochad/mochad --raw-data -d 3>&1 1>&2- 2>&3- >> mochad.log
			#  >> mochad.log` )
			# ( /share/homes/admin/mochad/mochad --raw-data -d 3>&1 1>&2- 2>&3- | ts > mochad2.log ) |  ts > mochad1.log
			n=1
			while read line;
			do
				# for read each line
				echo "line $n : $line"
				n=$((n+1))
			done < `/share/homes/admin/mochad/mochad --raw-data -d 3>&1 1>&2- 2>&3-`


		fi
		message "mochad ended with exit status $?"
		EXITSTATUS=$?
		message "mochad ended with exit status $EXITSTATUS"
		echo "mochadexit on $EXITSTATUS signal $EXITSIGNAL."
		if test "xs$EXITSTATUS" = "x0" ; then
			# Properly shutdown....
			message "mochad shutdown normally."
			exit 0
		elif test "0$EXITSTATUS" -gt "128" ; then
			EXITSIGNAL=$(($EXITSTATUS - 128))
			echo "mochad exited on signal $EXITSIGNAL."
			if test "x$NOTIFY" != "x" ; then
				echo "mochad on $MACHINE exited on signal $EXITSIGNAL.  Might want to take a peek." | \
				# mail -s "mochad Died" $NOTIFY
				message "Exited on signal $EXITSIGNAL"
			fi
			if test "x$EXEC" != "x" ; then
				$EXEC
			fi

			PID=`cat ${MOCvPIDFILE}`
			DATE=`date "+%Y-%m-%dT%H:%M:%S%z"`
			if test -f ${RUNDIR}/core.${PID} ; then
				mv ${RUNDIR}/core.${PID} ${DUMPDROP}/core.`hostname`-$DATE &
			elif test -f ${RUNDIR}/core ; then
				mv ${RUNDIR}/core ${DUMPDROP}/core.`hostname`-$DATE &
			fi
		else
			message "mochad died with code $EXITSTATUS."

			PID=`cat ${MOCvPIDFILE}`
			DATE=`date "+%Y-%m-%dT%H:%M:%S%z"`
			if test -f ${RUNDIR}/core.${PID} ; then
				mv ${RUNDIR}/core.${PID} ${DUMPDROP}/core.`hostname`-$DATE &
			elif test -f ${RUNDIR}/core ; then
				mv ${RUNDIR}/core ${DUMPDROP}/core.`hostname`-$DATE &
			fi
		fi
		message "Automatically restarting mochad."
		sleep $SLEEPSECS
		echo 'sleep done'
		# if test "0$KILLALLMPG123" -gt "0" ; then
		#	pkill -9 mpg123
		# fi
	done
}

run_mochad &
message "mochad started normally."
