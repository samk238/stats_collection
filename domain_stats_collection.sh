#################################################################################
# Author: Sampath Kunapareddy                                                   #
# sampath.a926@gmail.com                                                        #
#################################################################################
#!/bin/bash
#set -x

#Dependencies
#props="/home/skunapar/sam.txt"
#outputdir=""
#JAVA_HOME=""
#MW_HOME=""

if [ ! -f "$props" ]; then
  echo -e "NO \"$props\" file...\n\tPlease check and re-run..."
  exit 1
fi

error_op() {
  echo -e "\nPlease run script as\n\t$0 -t -l -r OR any combinations -tr -tl -lt -ltr etc.."
  echo -e "\t\t -> \"-t\" to get thread dumps..."
  echo -e "\t\t -> \"-l\" to collect logs..."
  echo -e "\t\t -> \"-r\" to run RDA..."
}

if [[ $# -eq 2 ]]; then
  export ENVNAME=$1
  export SECOPT=$2
  if [[ ! -z $(cat $props | grep -i "$ENVNAME" 2>/dev/null) ]]; then
    if [[ ! -z $(echo "$SECOPT" | cut -d"-" -f2 | sed 's/./\0\n/g' | grep "t\|l\|r" ) ]]; then
      t_job() {
        echo "******************************************************************************************"
        echo "*           This will capture 5 thread dumps with 10 seconds apart from each             *"
        echo "******************************************************************************************"
        FOLDER_NAME=$outputdir/thread_dumps_${ENVNAME}
        mkdir -p "$FOLDER_NAME"
        for eachpid in $(ps -ef | grep java | grep -i "weblogic.Server" | awk '{print $2}'); do
          for i in 1 2 3 4 5; do
            $JAVA_HOME/bin/jstack ${eachpid} >> $FOLDER_NAME/td_${ENVNAME}_${eachpid}_$(date +"%m-%d-%Y%H%M").txt
            sleep 10s
            echo "Thread Dump ${i} is created for $eachpid"
          done
        done
        tar -zcf ${FOLDER_NAME}.tar.gz $FOLDER_NAME
        rm -rf $FOLDER_NAME
      }
      l_job() {
        echo "******************************************************************************************"
        echo "*           This will collect all log files older than 7 days                            *"
        echo "******************************************************************************************"
        FOLDER_NAME=$outputdir/logfiles_${ENVNAME}
        mkdir -p "$FOLDER_NAME"        
        for dir in $(ls -d */); do
          find $dir/logs/ -type f -name "*.log" -mtime -5 -exec cp {} -rpf $FOLDER_NAME \;
        done
        tar -zcf ${FOLDER_NAME}.tar.gz $FOLDER_NAME
        rm -rf $FOLDER_NAME
      }
      r_job() {
        echo "******************************************************************************************"
        echo "*           This will collect RDA Information without the User Interface                 *"
        echo "******************************************************************************************"
        if [[ -f "$MW_HOME/rda" ]]; then
          cd $MW_HOME/rda
          ./rda.sh -f
          mv $MW_HOME/rda/output/RDA.STA__HOSTNAME.zip $outputdir/RDA_${ENVNAME}.zip
        else
          echo "Unable to locate the rda.sh file, please check and re-run.."
        fi
      }
      #Script Run:
      for c in $(echo "$SECOPT" | cut -d"-" -f2 | sed 's/./\0\n/g'); do
        ${c}_job
      done
    else
      echo -e "\n\n\"$SECOPT\" is NOT VALID ..."
      error_op
      exit 1
    fi
  else
    echo -e "\n\nNO SUCH ENVNAME as \"$ENVNAME\" AVAILABLE in \"$props\" file!!\n\tPlease check and re-run..."
    exit 1
  fi
else
  error_op
fi
