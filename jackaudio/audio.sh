#! /bin/sh
PLUMB=/usr/bin/jack.plumbing
PLUMB_PID=""
PLUMB_PIDFILE="/home/jay/.audio/jack.plumbing.pid"
A2J_CONTROL=/usr/bin/a2j_control
ALSA_IN=/usr/bin/alsa_in
ALSA_OUT=/usr/bin/alsa_out
JACK_MIXER=/usr/bin/jack_mixer
JACK_MIXER_PID=""
JACK_MIXER_PIDFILE="/home/jay/.audio/jack_mixer.pid"
JACK_RACK=/usr/bin/jack-rack
PULSEAUDIO=/usr/bin/pulseaudio

check_progs()
{
  if ! [ -x $PLUMB ]; then
    echo 'Cannot find jack.plumbing binary'
    exit 1
  fi
  if ! [ -x $A2J_CONTROL ]; then
    echo 'Cannot find a2j_control binary'
    exit 1
  fi
  if ! [ -x $ALSA_IN ]; then
    echo 'Cannot find alsa_in binary'
    exit 1
  fi
  if ! [ -x $ALSA_OUT ]; then
    echo 'Cannot find alsa_out binary'
    exit 1
  fi
  if ! [ -x $JACK_MIXER ]; then
    echo 'Cannot find jack_mixer binary'
    exit 1
  fi
  if ! [ -x $JACK_RACK ]; then
    echo 'Cannot find jack-rack binary'
    exit 1
  fi
  if ! [ -x $PULSEAUDIO ]; then
    echo 'Cannot find pulseaudio binary'
    exit 1
  fi
}

check_jack()
{
  if [ `ps -ef | grep jackd | grep -v grep | wc -l` -lt 1 ]; then
    echo "Jackd is not running!"
    exit 1
  fi
}

check_running_status()
{
  if [ -e $PLUMB_PIDFILE ]; then
    PLUMB_PID=`cat $PLUMB_PIDFILE`
  fi
  if [ -e $JACK_MIXER_PIDFILE ]; then
    JACK_MIXER_PID=`cat $JACK_MIXER_PIDFILE`
  fi
}

case "$1" in
  start)
        check_progs
        check_jack
        check_running_status

        # Start jack.plumbing
        $PLUMB 1>/dev/null 2>&1 &
        if [ $! -gt 0 ]; then
          echo $! > $PLUMB_PIDFILE
        else
          echo 'Failed to start jack.plumbing'
        fi

	# Start Alsa-2-jack midi
	$A2J_CONTROL start

	# Start Alsa loopbacks
        $ALSA_IN  -j alsa  -d cloop &
        #$ALSA_OUT -j alsa  -d ploop &

	sleep 1

	# Fix incorrect file mode on shared-memory segments
        # chmod 666 /dev/shm/sem.jack_*

        # Start Jack Mixer
        $JACK_MIXER -c /home/jay/.audio/jackmixer-default.xml &

        if [ $! -gt 0 ]; then
          echo $! > $JACK_MIXER_PIDFILE
        else
          echo 'Failed to start jack_mixer'
        fi

        # Start Jack rack
        $JACK_RACK ~/.audio/jackrack-default &

	sleep 5

	# Start Pulse audio
	# $PULSEAUDIO -D -n -F ~/.pulse/pulsejack.pa
	;;

  stop)
        check_progs
        check_running_status

	# Kill Alsa-2-jack midi
	$A2J_CONTROL stop

        # Kill alsa loopbacks
        killall alsa_in
        killall alsa_out

        # Kill jack.plumbing
        if [ "$PLUMB_PID" != "" ]; then
          kill $PLUMB_PID
          rm $PLUMB_PIDFILE
        fi

	# Kill jack mixer and jack rack
        if [ "$JACK_MIXER_PID" != "" ]; then
          kill $JACK_MIXER_PID
          rm $JACK_MIXER_PIDFILE
        fi

	# Kill jack rack
        killall jack-rack

	# Stop pulseaudio
	$PULSEAUDIO -k
	;;

  restart)
  	$0 stop
	sleep 5
	$0 start
	;;

  status)
        check_jack
        check_running_status

        if [ "$PLUMB_PID" = "" ]; then
          echo "jack.plumbing is NOT running!"
        else
          echo "jack.plumbing is running (PID: $PLUMB_PID)"
        fi

        if [ "$JACK_MIXER_PID" = "" ]; then
          echo "jack_mixer is NOT running!"
        else
          echo "jack_mixer is running (PID: $JACK_MIXER_PID)"
        fi

	$PULSEAUDIO --check
	if [ $? -eq 0  ]; then
	  echo "pulseaudio is  running"
	else
	  echo "pulseaudio is NOT running"
	fi

	;;

  *)
	echo "Usage: $0 {start|stop|restart|status}"
	exit 1
	;;
esac

exit 0
