#!/bin/bash

TEST_HOME=$(dirname "$0")
TEST_DIR=${TEST_HOME}/tests
workdir=${TEST_HOME}/workdir
LOG_FILE="${workdir}/$(date +%F-%H:%M:%S).log"
if [[ !(-d $workdir) ]]; then
	mkdir -p $workdir
fi

QUIET=false
LOG=false
LAB_NUM=
TEST_SET_NUM=
TEST_FILE_NAME=

usage() {
	echo "Usage: $(basename $0) [-hc] [-gtn] [-q] [--log] [parser]"
}

alert() {
	RED='\033[0;31m'
	NC='\033[0m'
	#BOLD=$(tput bold)
	#NORMAL=$(tput sgr0)
	echo -e "${RED}$1${NC}"
}

set -- $(getopt -n autotest.sh -o qhct:n:l: -l quiet,help,ins,clean,log,test:,name:,lab: -u -- "$@")

if [ $? -ne 0 ]; then
	usage
	exit -1
fi

QUIET=false
while true; do
	case "$1" in
	-q | --quiet)
		QUIET=true
		shift
		;;
	-h | --help)
		usage
		exit 0
		;;
	-t | --test)
		TEST_SET_NUM=$2
		shift 2
		;;
	-n | --name)
		TEST_FILE_NAME=$2
		QUIET=true
		shift 2
		;;
	-l | --LAB)
		LAB_NUM=$2
		shift 2
		;;
	-c | --clean)
		rm -rf $workdir/*.log
		exit 0
		;;
	--log)
		LOG=true
		shift
		;;
	--ins)
		INSTR=true
		num_instr="0"
		shift
		;;
	--)
		shift
		break
		;;
	esac
done

# Load Running Script
if [[ -z $1 ]]; then
	if [ -e $workdir/saved_binary.sh ]; then
		source $workdir/saved_binary.sh
	else
		usage
		exit -1
	fi
else
	RUN=$1
	echo "RUN=$(realpath $RUN)" >${workdir}/saved_binary.sh
fi
if ! [ -x $RUN ]; then
	echo "Error: file \"$RUN\" is not executable"
	exit -1
fi

# TEST
CODE=0
echo 0 >$workdir/count
if [[ -z $LAB_NUM ]]; then
	LABS=("$(ls $TEST_DIR)")
else
	LABS=(Lab-$LAB_NUM)
fi

for LAB in $LABS; do
	echo "[In $LAB]"
	if [[ -f $TEST_DIR/$LAB/check.sh ]]; then
		CHECK_FUNC="sh $TEST_DIR/$LAB/check.sh"
		CHECK_TYPE="out"
	elif [[ -f $TEST_DIR/$LAB/check.py ]]; then
		CHECK_FUNC="python $TEST_DIR/$LAB/check.py"
		CHECK_TYPE="json"
	else
		alert "check.[sh|py] not exists"
		continue
	fi

	if [[ -z $TEST_SET_NUM ]]; then
		_TESTS="$(ls $TEST_DIR/$LAB | grep -v \"check*\")"
		TESTS=($_TESTS)
	else
		if ! [[ -d $TEST_DIR/$LAB/test-$TEST_SET_NUM ]]; then
			alert "$LAB doesn't have test-$TEST_SET_NUM"
			continue
		fi
		TESTS=(test-$TEST_SET_NUM)
	fi
	if [[ -z $TESTS ]]; then
		alert "Nothing to test in $LAB"
		continue
	fi

	for TEST in $TESTS; do
		echo "[[In $LAB:$TEST]]"
		pTEST=$TEST_DIR/$LAB/$TEST

		if [[ -z $TEST_FILE_NAME ]]; then
			TEST_FILES=$pTEST/*.cmm
		else
			TEST_FILES=$pTEST/$TEST_FILE_NAME.cmm
			if ! [[ -f $TEST_FILES ]]; then
				continue
			fi
		fi

		if [[ "$LOG" = true ]]; then
			echo "$(date)" >$LOG_FILE
		fi

		for fcmm in $TEST_FILES; do
			cp $fcmm ${workdir}/a.cmm

			if ! [[ -f ${fcmm%.cmm}.${CHECK_TYPE} ]]; then
				alert "Test [$(basename $fcmm)] correct output not given"
				CODE=-1
				if [[ "$QUIET" = false ]]; then
					read -p "Enter [c] to continue, other keys to abort: " txt
					if [ -z "$txt" ] || [ $txt != 'c' ]; then
						exit -1
					fi
				fi
				continue
			fi
			cp ${fcmm%.cmm}.${CHECK_TYPE} ${workdir}/a.${CHECK_TYPE}

			$RUN ${workdir}/a.cmm >${workdir}/yours.out 2>&1
			$CHECK_FUNC ${workdir}/a.${CHECK_TYPE} ${workdir}/yours.out
			RET=$?
			if [[ "$INSTR" = true ]]; then
				instr_c="$(wc -l ${workdir}/yours.out | awk '{print $1}')"
				num_instr=$(expr $num_instr + $instr_c)
				instruction="(translated irs: $instr_c)"
			fi
			if [ $RET -eq 0 ]; then
				echo "Test [$(basename $fcmm)] matched $instruction"
				if [[ -n $NAME && $CHECK_TYPE == "out" ]]; then
					diff ${workdir}/a.${CHECK_TYPE} ${workdir}/yours.out | head -10
				fi
			else
				alert "Test [$(basename $fcmm)] mismatch"
				if [[ "$LOG" = true ]]; then
					echo "Test [$(basename $fcmm)] mismatch" >>$LOG_FILE
				fi
				if [[ $CHECK_TYPE == "out" ]]; then
					diff ${workdir}/a.${CHECK_TYPE} ${workdir}/yours.out | head -10
				fi
				CODE=-1
				if [[ "$QUIET" = false ]]; then
					read -p "Enter [c] to continue, other keys to abort: " txt
					if [ -z "$txt" ] || [ $txt != 'c' ]; then
						exit -1
					fi
				fi
			fi
		done
	done
done

if [[ $CODE -eq "0" && "$LOG" = true ]]; then
	echo "All Success" >>$LOG_FILE
fi
if [[ "$INSTR" = true ]]; then
	echo "Total translated IR: $num_instr"
	echo "Total executed IR: $(cat $workdir/count)"
fi
exit $CODE
