#! /bin/bash

# If you just want to start it for the night, auto config should be fine, but if you're using proxy, you must specify that in all 3 of the config files... If you want to use the machine in the mean time, you can set a fixed amount of RAM or CPU cores in the config files since that defined values in the config file will override the automatic even if the ManualConfig constant is not set to true, however the script will still decide automatically if it uses CPU, GPU or both, or none for rendering... If the ManualConfig constant is set then script will check the config files, and will use the one or 2 that is edited, but will not try to auto complete them, so you should both RAM amount, and CPU cores... If the ManualConfig is set, and both the RAM amount and CPU cores are specified in the CPU_GPU config file, the other 2 will be ignored!

# Finding Roots
cd $(cd "$(dirname "$0")"; pwd -P)

# Constant(s) and pre defined variables
ManualConfig=false
CPU=true
GPU=false
CPU_GPU=false
Quit=""

function NewTerminal
{
  ExistingTerm=$(ls /dev/pts/*)
  if [[ $Permission == true ]]
  then
    sudo -u $SUDO_USER gnome-terminal&
  else
    gnome-terminal&
  fi
  sleep 1 # need some time for the gnome-terminal command to open the terminal...
  NewTerm=""
  for i in $(ls /dev/pts/*)
  do
    if [[ -z $(echo $ExistingTerm | grep $i) ]]
    then
      NewTerm=$i
    fi
  done
}

function ComputeMethod
{
  if [[ $GPUMem -ge 8000 && $CPUs -gt 7 ]]
  then
    echo "Rendering with single instance of either CPU or GPU. Server decides..."
    CPU=false
    GPU=false
    CPU_GPU=true
    CPUs=$(( $CPUs + 1 ))
  else
    if [[ $GPUMem -ge 8000 ]]
    then
      echo "Rendering with GPU only..."
      CPU=false
    else
      if [[ $GPUMem -ge 4000 && $CPUs -ge 5 && $CPUs -le 7 ]]
      then
        echo "Rendering with single instance of either CPU or GPU. Server decides..."
        CPU=false
        GPU=false
        CPU_GPU=true
        CPUs=$(( $CPUs + 1 ))
      else
        if [[ $GPUMem -ge 4000 && $CPUs -lt 5 ]]
        then
          echo "Rendering with GPU only..."
          CPU=false
        else
          echo "Rendering with CPU only..."
          GPU=false
        fi
      fi
    fi
  fi
}

# Root check
if [[ $(whoami) == "root" ]]
then
  Permission=true
else
  read -p "The script can't stop the client if not running as root. (If you're not an admin I recoomend not to continue, or you may have to restart the PC in order to stop rendering.) Continue? (y/n): " Yy
  if [[ $Yy == [Yy]* ]]
  then
    Permission=false
  else
    exit
  fi
fi

if [[ ! -z $(ps -e | grep rend.exe) ]]
then
  echo "Fatal: Sheepit is already rendering... If the client(s) are closed, please run the following command for closing the process: sudo kill $(ps -e | grep rend.exe | awk '{ print $1 }')"
  exit
fi

# Checking java
echo -n "Checking java: "
if [[ -z $(dpkg -l | grep openjdk) ]]
then
  echo "Fail"
  echo ""
  read -p "The sheepit client needs java to run... Do you want to install java?(y/n): " Yy
  if [[ $Yy == [Yy]* ]]
  then
    if [[ $Permission == true ]]
    then
      apt-get -y install openjdk-8-jdk
      echo ""
    else
      sudo apt-get -y install openjdk-8-jdk
      echo ""
      if [[ -z $(dpkg -l | grep openjdk) ]]
      then
        echo "Aborting... Sheepit client won't work without java..."
        exit
      fi
    fi
  else
    echo "Aborting... Sheepit client won't work without java..."
    exit
  fi
else
  echo "Ok"
  echo ""
fi

# Checking inxi
if [[ -z $(dpkg -l | grep inxi) ]]
then
  if [[ ! -e ./.noinxi ]]
  then
    read -p "This script uses inxi for temperature monitoring, but it is not absolutely necessary if you have another prefered way of monitoring CPU and GPU temperatures. Do you want to install it?(y/n): " Yy
  else
    Yy="n"
  fi
  if [[ $Yy == [Yy]* ]]
  then
    TempMon=true
    if [[ $Permission == true ]]
    then
      apt-get -y install inxi
      echo ""
    else
      sudo apt-get -y install inxi
      echo ""
      if [[ -z $(dpkg -l | grep inxi) ]]
      then
        TempMon=false
        touch ./.noinxi
      fi
    fi
  else
    TempMon=false
    touch ./.noinxi # if you install inxi later you can delete the .noinxi file to have temperature monitoring...
  fi
else
  TempMon=true
fi

# Checking htop
if [[ -z $(dpkg -l | grep htop) ]]
then
  if [[ ! -e ./.nohtop ]]
  then
    read -p "Htop is a light weight system monitor program, but it is not absolutely necessary if you have another prefered way of monitoring processes and CPU load. Do you want to install it?(y/n): " Yy
  else
    Yy="n"
  fi
  if [[ $Yy == [Yy]* ]]
  then
    HTop=true
    if [[ $Permission == true && -z $Passwd ]]
    then
      apt-get -y install htop
      echo ""
    else
      sudo apt-get -y install htop
      echo ""
      if [[ -z $(dpkg -l | grep htop) ]]
      then
        HTop=false
        touch ./.nohtop  
      fi
    fi
  else
    HTop=false
    touch ./.nohtop # if you install htop later you can delete the .nohtop file to launch it...
  fi
else
  HTop=true
fi

# Probing system and preparing for launch
CPUs=$(grep -c ^processor /proc/cpuinfo)
echo "Detected CPU cores: $CPUs"
MemAvailable=$(grep "MemAvailable:" /proc/meminfo | awk '{print $2}')
if [[ $MemAvailable -lt 2000000 ]]
then
  echo "There's no point rendering with less then 2GB of available RAM... It would produce too much out of memory errors..."
  if [[ $GPU != true ]]
  then
    echo "Aborting..."
    exit
  fi
fi
echo "Available memory: ~$(( $MemAvailable / 1000 ))MB"
if [[ $(java -jar $(pwd)/sheepit-client-*.jar --show-gpu | grep "CUDA Name :") ]]
then
  GPU=true
  CPUs=$(( $CPUs - 1 ))
  echo "Supported GPU: yes"
  GPUMem=$(java -jar $(pwd)/sheepit-client-*.jar --show-gpu | grep "Memory" | awk '{ print $3 }')
  echo "Reported video memory: ${GPUMem}MB"
else
  GPU=false
  echo "Supported GPU: No"
fi
AvailSpace=$(echo $(df -k $(pwd)) | awk '{ print $11 }')
SheepitSize=$(du -s $(pwd) | awk '{ print $1 }')
echo "Available disk space: $(( $(( $AvailSpace + $SheepitSize )) / 1000 ))MB"

#Automatic configuration attempt
if [[ $ManualConfig == false ]]
then
  echo ""
  echo "Autoconfig begins..."
  if [[ $GPU == true ]]
  then
    if [[ $GPUMem -lt 2000 ]]
    then
      echo "There's no point rendering with less then 2GB of VRAM! It would produce too much out of memory errors. Falling back to CPU only rendering..."
      GPU=false
      CPUs=$(( $CPUs + 1 ))
    fi
  fi
  if [[ $(( $AvailSpace + $SheepitSize )) -lt 2000000 ]]
  then
    echo "At least 2GB disk space is required per instance for efficient operation. Aborting..."
    exit
  fi
  if [[ $CPU == true && $GPU == true && $(( $AvailSpace + $SheepitSize )) -lt 4000000 ]]
  then
    echo "At least 2GB disk space is required per instance for efficient operation. Falling back to single client operation..."
    ComputeMethod
  fi
  if [[ $MemAvailable -lt 5000000 ]]
  then
    echo "Your system is low on memory! It can not run 2 instances of the client efficiently. Falling back to single client operation..."
    ComputeMethod
  fi
  if [[ $CPU == true && $GPU == true ]]
  then
    AUTORAMGPU=$(( $MemAvailable - 1000000 ))
    AUTORAMGPU=$(( $AUTORAMGPU / 2 ))
    AUTORAMCPU=$(( 1000000 + $AUTORAMGPU ))
  fi
  if [[ $CPU != true && $GPU == true ]]
  then
    AUTORAMGPU=$MemAvailable
  fi
  if [[ $CPU_GPU == true || $CPU == true && $GPU != true ]]
  then
    AUTORAMCPU=$MemAvailable
  fi

  if [[ $CPU == true ]]
  then
    if [[ -e ./.sheepit-cpu.conf ]]
    then
      rm -f ./.sheepit-cpu.conf
    fi
    cp ./sheepit-cpu.conf ./.sheepit-cpu.conf
    sed -i "s/AUTO_CORE_COUNT/$CPUs/g" ./.sheepit-cpu.conf
    sed -i "s/AUTO_RAM/$AUTORAMCPU/g" ./.sheepit-cpu.conf
    echo ""
    echo "CPU instance will use: $CPUs CPU cores, and $(( $AUTORAMCPU / 1000 )) MB of memory."
  fi
  if [[ $CPU_GPU == true ]] # The CPU_GPU instance uses WD_CPU and .sheepit-cpu.conf but it copies the .sheepit-cpu_gpu.conf not the .sheepit-cpu.conf The only difference is compute method and tile size...
  then
    if [[ -e ./.sheepit-cpu.conf ]]
    then
      rm -f ./.sheepit-cpu.conf
    fi
    cp ./sheepit-cpu_gpu.conf ./.sheepit-cpu.conf
    sed -i "s/AUTO_CORE_COUNT/$CPUs/g" ./.sheepit-cpu.conf
    sed -i "s/AUTO_RAM/$AUTORAMCPU/g" ./.sheepit-cpu.conf
    echo ""
    echo "Single instance will use: $CPUs CPU cores, and $(( $AUTORAMCPU / 1000 )) MB of memory, and will render with either CPU or GPU."
  fi
  if [[ $GPU == true ]]
  then
    if [[ -e ./.sheepit-gpu.conf ]]
    then
      rm -f ./.sheepit-gpu.conf
    fi
    cp ./sheepit-gpu.conf ./.sheepit-gpu.conf
    sed -i "s/AUTO_RAM/$AUTORAMGPU/g" ./.sheepit-gpu.conf
    echo ""
    echo "GPU instance will use: 1 CPU cores, and $(( $AUTORAMGPU / 1000 )) MB of memory."
  fi
else
  if [[ -z $(grep "AUTO_RAM" "$(pwd)/sheepit-cpu_gpu.conf") && -z $(grep "AUTO_CORE_COUNT" "$(pwd)/sheepit-cpu_gpu.conf") ]]
  then
    CPU=false
    GPU=false
    CPU_GPU=true
    if [[ -e ./.sheepit-cpu.conf ]]
    then
      rm -f ./.sheepit-cpu.conf
    fi
    cp ./sheepit-cpu_gpu.conf ./.sheepit-cpu.conf
  else
    if [[ -z $(grep "AUTO_RAM" "$(pwd)/sheepit-cpu.conf") && -z $(grep "AUTO_CORE_COUNT" "$(pwd)/sheepit-cpu.conf") ]]
    then
      CPU=true
      if [[ -e ./.sheepit-cpu.conf ]]
      then
        rm -f ./.sheepit-cpu.conf
      fi
      cp ./sheepit-cpu.conf ./.sheepit-cpu.conf
    else
      CPU=false
    fi
    if [[ -z $(grep "AUTO_RAM" "$(pwd)/sheepit-gpu.conf") ]]
    then
      GPU=true
      if [[ -e ./.sheepit-gpu.conf ]]
      then
        rm -f ./.sheepit-gpu.conf
      fi
      cp ./sheepit-gpu.conf ./.sheepit-gpu.conf
    else
      GPU=false
    fi
  fi
  if [[ $CPU == false && $GPU == false ]]
  then
    echo "Error: None of the config files are complete, and ManualConfig is set! Aborting..."
    exit
  fi
fi

echo ""
echo "Launching client instance(s)!"
# Launching processes (gnome-terminal -e option gave deprecated error, so I'm only using that command to open multiple terminals...)
if [[ $GPU == true ]]
then
  if [[ $TempMon == true || $HTop == true || $CPU == true || $Permission == true ]]
  then
    NewTerminal
    TermGPU="$NewTerm"
    if [[ $Permission == true ]]
    then
      sudo -u $SUDO_USER setsid sh -c "exec java -jar $(pwd)/sheepit-client-*.jar -config $(pwd)/.sheepit-gpu.conf <> $NewTerm >&0 2>&1"&
    else
      setsid sh -c "exec java -jar $(pwd)/sheepit-client-*.jar -config $(pwd)/.sheepit-gpu.conf <> $NewTerm >&0 2>&1"&
    fi
  else
    if [[ $Permission == true ]]
    then
      sudo -u $SUDO_USER java -jar $(pwd)/sheepit-client-*.jar -config $(pwd)/.sheepit-gpu.conf
    else
      java -jar $(pwd)/sheepit-client-*.jar -config $(pwd)/.sheepit-gpu.conf
    fi
  fi
fi

if [[ $CPU == true || $CPU_GPU == true ]]
then
  if [[ $TempMon == true || $HTop == true || $Permission == true ]]
  then
    NewTerminal
    TermCPU="$NewTerm"
    if [[ $Permission == true ]]
    then
      sudo -u $SUDO_USER setsid sh -c "exec java -jar $(pwd)/sheepit-client-*.jar -config $(pwd)/.sheepit-cpu.conf <> $NewTerm >&0 2>&1"&
    else
      setsid sh -c "exec java -jar $(pwd)/sheepit-client-*.jar -config $(pwd)/.sheepit-cpu.conf <> $NewTerm >&0 2>&1"&
    fi
  else
    if [[ $Permission == true ]]
    then
      sudo -u $SUDO_USER java -jar $(pwd)/sheepit-client-*.jar -config $(pwd)/.sheepit-cpu.conf
    else
      java -jar $(pwd)/sheepit-client-*.jar -config $(pwd)/.sheepit-cpu.conf
    fi
  fi
fi

if [[ $HTop == true ]]
then
  if [[ $TempMon == true || $Permission == true ]]
  then
    NewTerminal
    TermH="$NewTerm"
    setsid sh -c "exec htop <> $NewTerm >&0 2>&1"&
  else
    htop
  fi
fi

if [[ $TempMon == true || $Permission == true ]]
then
  echo ""
  echo "Temperatures should generally be below 80 degrees C or 176 degrees F even after about 30 minutes under full load. If it ever goes over that, you should stop rendering and try:"
  echo "-> 1. Cleaning the machine of dust."
  echo "-> 2. Change the thermal paste."
  echo "-> 3. Leave the case open."
  echo "-> 4. Put the machine in a cooler environment."
  echo "-> 5. If none of this work, buy an adequate cooler, or just don't render."
  sleep 15
  while [[ $TempMon == true || $Permission == true ]]
  do
    clear
    if [[ $TempMon == true ]]
    then
      inxi -s
    fi
     # There is basically no good way to stop the client when it was started in command line, so the script simply kills the process.
    if [[ $Permission == true ]]
    then
      read -t 3 -p "Type \"q\" for quit (and hit enter): " Quit
      if [[ $Quit == "q" ]]
      then
        Kill="$(ps -aux | grep "sheepit" | grep -v "grep" | grep -v "sudo" | awk '{ print $2 }')"
        if [[ $HTop == true ]]
        then
          Kill="$Kill $(ps -aux | grep "htop" | grep -v "grep" | awk '{ print $2 }')"
        fi
        for i in GPU CPU H
        do
          X=$(eval "echo \"\$Term$(echo $i)\"")
          if [[ ! -z "$X" ]]
          then
            Kill="$Kill $(ps -e | grep "${X:5:5}" | grep -v "grep" | awk '{ print $1 }')"
          fi
        done
        kill $Kill
        for i in $(ls "$(pwd)/WD-CPU")
        do
          Ext="${i##*.}"
          if [[ $Ext != "zip" ]]
          then
            rm -Rf "$(pwd)/WD-CPU/$i"
          fi
        done
        for i in $(ls "$(pwd)/WD-GPU")
        do
          Ext="${i##*.}"
          if [[ $Ext != "zip" ]]
          then
            rm -Rf "$(pwd)/WD-GPU/$i"
          fi
        done
        rm -Rf /tmp/sheepit*
        exit
      fi
    else
      sleep 3
    fi
  done
fi
