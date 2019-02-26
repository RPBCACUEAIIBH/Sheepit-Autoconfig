#! /bin/bash

# If you just want to start it for the night, auto config should be fine, but if you're using proxy, you must specify that with -p option... If you want to use the machine in the mean time, you can set a fixed amount of RAM or CPU cores in the config files since the defined values in the config file will override the automatic even if the ManualConfig constant is not set to true however the script will still decide automatically if it uses CPU, GPU, both in a single instance, or none for rendering.(that is only true to memory and CPU cores, the credentials, and proxy must be defined by using options. run it with --help for more info, the script does not edit other values.) You can go all manual, with -m option, and the script will not auto-configure anything but set username and proxy(again... options) but will still check if there are enough CPU cores, and RAM for your config...

# Finding Roots
cd $(cd "$(dirname "$0")"; pwd -P)

# Constant(s) and pre defined variables
ManualConfig=false
CommandLine=false
SilentMode=false
Facepalm=true # ...I should have tried killing processes without sudo in the first place.
Permission=false
UpdateScript=false
UpdateClient=false
RevertScript=false
RevertClient=false
CPU=true
GPU=false
CPU_GPU=false
Quit=""
UserName="RPBCACUEAIIBH"
Password="d5y7FgPYCQjrg9JP0iqqjt5AlCYXkGmiKcgCF0O8"
Proxy=""
Version="$(grep "Current version:" "$(pwd)/README.md")"

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

# Processing options
while [[ ! -z $@ ]]
do
  case $1
  in
               "-m" ) ManualConfig=true
                      ;;
               "-c" ) CommandLine=true
                      ;;
               "-s" ) SilentMode=true
                      ;;
               "-p" ) shift
                      Proxy=$1
                      ;;
               "-u" ) shift
                      UserName=$1
                      shift
                      Password=$1
                      ;;
               "-A" ) UpdateScript=true
                      ;;
              "-RA" ) RevertScript=true
                      ;;
               "-C" ) UpdateClient=true
                      ;;
              "-RC" ) RevertClient=true
                      ;;
           "--help" ) echo ""
                      echo "Options"
                      echo "-c                         Specify this for command line operation.(Will launch the instances but not in new terminals... This runs via SSH, but will NOT continue running if you close the terminal.)"
                      echo "-m                         Use manual config(only if at least one of the config files are completed...)"
                      echo "-s                         Silent mode... This will launch the instances without any feedback. no need to also specify -c option. (for compatibility with my Systemd-Service-Generator script, which *hopefuly* makes it run automatically at startup...)"
                      echo ""
                      echo "-p [proxy]                 Specify proxy"
                      echo "-u [username] [password]   Specify different user"
                      echo ""
                      echo "Specify options separately... For eample: It does not currently recognize -mu as separate options. you must specify them as -m -u"
                      echo ""
                      echo "-A                         Update Autoconfig script(Exits after execution!)"
                      echo "-RA                        Revert Autoconfig script to older version(Exits after execution!)"
                      echo "-C                         Update Sheepit client"
                      echo "-RC                        Revert Sheepit client to older version"
                      echo "You have to update the script first then the client if you wanna update both!"
                      echo ""
                      echo "Since version 1.2 you can make it a systemd service and have your machine autoconfigure and connect automatically at startup!(you may not wanna do that if you're using the machine for anythng else...)"
                      echo "- Download my Systemd-Service-Generator script from github.com/RPBCACUEAIIBH/Systemd-Service-Generator"
                      echo "- Run it as root"
                      echo "- Specify the following settings:"
                      echo "  - Service name: Sheepit"
                      echo "  - Startup command: sudo -u [yourusername] /home/[yourusername]/location/Sheepit-Autoconfig/Launch.sh -u [sheepitusename] [key/password] -s"
                      echo "  - Shutdown command: (leave it empty)"
                      echo "  - ServiceType: forking"
                      echo "  - Should the service be considered running when it exits?: no"
                      echo "  - Would you like to run the service now?: no (you want to reboot, and see if it starts rendering automatically at startup with everything it got autoconfigured...)"
                      echo "- Reboot, and check if you're rendering... :D"
                      echo "- You can check the service with: systemctl status Sheepit.service"
                      echo "- If you mess it up, run Systemd-Service-Generator script again with --cleaup option, and specify the service name: Sheepit"
                      echo ""
                      exit
                      ;;
        "--version" ) echo ""
                      echo "$Version"
                      echo ""
                      cat $(pwd)/LICENSE.md
                      exit
                      ;;
                   *) echo "Error: Unknown option!"
                      exit
                      ;;
  esac
  shift
done

# Root check
if [[ $(whoami) == "root" ]]
then
  Permission=true
fi

if [[ ! -z $(ps -e | grep "rend.exe") || ! -z $(ps -aux | grep "sheepit" | grep -v "grep") ]]
then
  echo "Fatal: Sheepit is already rendering... If the client(s) are closed, please run the following command for closing the process: sudo kill $(ps -e | grep rend.exe | awk '{ print $1 }')"
  exit
fi

# Checking java
if [[ $SilentMode == false ]]
then
  echo -n "Checking java: "
fi
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
  if [[ $SilentMode == false ]]
  then
    echo "Ok"
    echo ""
  fi
fi

# Checking git
if [[ -z $(git --version | grep "git version") ]]
then
  read -p "Git is required for update management! Do you want to install git?(y/n): " Yy
  if [[ $Yy == [Yy]* ]]
  then
    sudo apt-get -y install git
  else
    echo "Aborting... Sheepit client won't work without java..."
    exit
  fi
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

# Update management
if [[ $UpdateScript == true ]]
then
  if [[ $Permission == true && ! -z $SUDO_USER ]]
  then
    rm -Rf ./WD-CPU/*
    rm -Rf ./WD-GPU/*
    git clone https://github.com/RPBCACUEAIIBH/Sheepit-Autoconfig.git
    rm -Rf ./Sheepit-Autoconfig/.git # Otherwise it gives a lecture about embedded git repos...
    CloneVersion=$(grep "Current version:" "$(pwd)/Sheepit-Autoconfig/README.md")
    if [[ "$CloneVersion" == "$Version" ]]
    then
      rm -Rf ./Sheepit-Autoconfig
      if [[ $SilentMode == false ]]
      then
        echo "Autoconfig is already up to date!"
      fi
      exit
    fi
    CurrentBranch=$(git branch | awk '{ print $2 }')
    if [[ ! -z $(git branch | grep "Old") && $(echo $CurrentBranch) != "Old" ]]
    then
      git branch -D Old
    fi
    if [[ $CurrentBranch != "Old" ]]
    then
      git branch -m Old
    fi
    if [[ ! -z $(git branch | grep "Current") ]]
    then
      git branch -D Current
    fi
    git add -A
    git commit -a -m $RANDOM
    git branch Current
    rm -Rf ./Sheepit-Autoconfig
    git add -A
    git commit -a -m $RANDOM
    git checkout Current
    cp -Rf ./Sheepit-Autoconfig/* ./
    rm -Rf ./Sheepit-Autoconfig
    chmod +x ./Launch.sh
    chmod +x ./sheepit-client*.jar
    chown -R $SUDO_USER:$SUDO_USER ./*
    git add -A
    git commit -a -m $RANDOM
    if [[ $SilentMode == false ]]
    then
      echo "Autoconfig updated!"
      exit # It must exit here otherwise it would malfunction!
    fi
  fi
  if [[ $Permission == false ]]
  then
    rm -Rf ./WD-CPU/*
    rm -Rf ./WD-GPU/*
    git clone https://github.com/RPBCACUEAIIBH/Sheepit-Autoconfig.git
    rm -Rf ./Sheepit-Autoconfig/.git # Otherwise it gives a lecture about embedded git repos...
    CloneVersion=$(grep "Current version:" "$(pwd)/Sheepit-Autoconfig/README.md")
    if [[ "$CloneVersion" == "$Version" ]]
    then
      rm -Rf ./Sheepit-Autoconfig
      if [[ $SilentMode == false ]]
      then
        echo "Autoconfig is already up to date!"
      fi
      exit
    fi
    CurrentBranch=$(git branch | awk '{ print $2 }')
    if [[ ! -z $(git branch | grep "Old") && $(echo $CurrentBranch) != "Old" ]]
    then
      git branch -D Old
    fi
    if [[ $CurrentBranch != "Old" ]]
    then
      git branch -m Old
    fi
    if [[ ! -z $(git branch | grep "Current") ]]
    then
      git branch -D Current
    fi
    git add -A
    git commit -a -m $RANDOM
    git branch Current
    rm -Rf ./Sheepit-Autoconfig
    git add -A
    git commit -a -m $RANDOM
    git checkout Current
    cp -Rf ./Sheepit-Autoconfig/* ./
    rm -Rf ./Sheepit-Autoconfig
    sudo chmod +x ./Launch.sh
    sudo chmod +x ./sheepit-client*.jar
    git add -A
    git commit -a -m $RANDOM
    if [[ $SilentMode == false ]]
    then
      echo "Autoconfig updated!"
      exit # It must exit here otherwise it would malfunction!
    fi
  else
    if [[ $SilentMode == false ]]
    then
      echo "Error: The script runs as root, and no \$SUDO_USER found! Aborting..."
    fi
    exit
  fi
fi

if [[ $UpdateClient == true ]]
then
  if [[ $Permission == true && ! -z $SUDO_USER ]]
  then
    if [[ ! -d ./Latest ]]
    then
      mkdir ./Latest
    else
      rm -f ./Latest/*
    fi
    if [[ ! -d ./Old ]]
    then
      mkdir ./Old
    fi
    cd ./Latest
    wget "https://www.sheepit-renderfarm.com/media/applet/client-latest.php" -O sheepit-client-latest.jar
    LatestClientSum=$(md5sum ./sheepit-client*.jar)
    cd ..
    CurrentClientSum=$(md5sum ./sheepit-client*.jar)
    if [[ $(echo "$LatestClientSum" | awk '{ print $1 }') == $(echo "$CurrentClientSum" | awk '{ print $1 }') ]]
    then
      if [[ $SilentMode == false ]]
      then
        echo "Client is already the latest!"
      fi
    else
      rm -f ./Old/*
      mv ./sheepit-client*.jar ./Old/sheepit-client-old.jar
      mv ./Latest/sheepit-client*.jar ./sheepit-client-current.jar
      chown $SUDO_USER:$SUDO_USER ./sheepit-client-current.jar
      chown -R $SUDO_USER:$SUDO_USER ./Old
      chmod +x ./sheepit-client-current.jar
      rm -r ./Latest
      if [[ $SilentMode == false ]]
      then
        echo "Client updated!"
      fi
    fi
  fi
  if [[ $Permission == false ]]
  then
    if [[ ! -d ./Latest ]]
    then
      mkdir ./Latest
    else
      rm -f ./Latest/*
    fi
    if [[ ! -d ./Old ]]
    then
      mkdir ./Old
    fi
    cd ./Latest
    wget "https://www.sheepit-renderfarm.com/media/applet/client-latest.php" -O sheepit-client-latest.jar
    LatestClientSum=$(md5sum ./sheepit-client*.jar)
    cd ..
    CurrentClientSum=$(md5sum ./sheepit-client*.jar)
    if [[ $(echo "$LatestClientSum" | awk '{ print $1 }') == $(echo "$CurrentClientSum" | awk '{ print $1 }') ]]
    then
      if [[ $SilentMode == false ]]
      then
        echo "Client is already the latest!"
      fi
    else
      rm -f ./Old/*
      mv ./sheepit-client*.jar ./Old/sheepit-client-old.jar
      mv ./Latest/sheepit-client*.jar ./sheepit-client-current.jar
      sudo chmod +x ./sheepit-client-current.jar
      rm -r ./Latest
      if [[ $SilentMode == false ]]
      then
        echo "Client updated!"
      fi
    fi
  else
    if [[ $SilentMode == false ]]
    then
      echo "Error: The script runs as root, and no \$SUDO_USER found! Aborting..."
    fi
    exit
  fi
fi

if [[ $RevertScript == true ]]
then
  if [[ -z $(git branch | grep "Old") ]]
  then
    if [[ $SilentMode == false ]]
    then
      echo "Error: No older version found!"
    fi
    exit
  fi
  CurrentBranch=$(git branch | awk '{ print $2 }')
  git add -A
  git commit -a -m $RANDOM
  if [[ $(echo $CurrentBranch) != "Old" ]]
  then
    git checkout Old
  else
    if [[ $SilentMode == false ]]
    then
      echo "This is the old version!"
    fi
    exit
  fi
  git branch -D Current
  if [[ $SilentMode == false ]]
  then
    echo "Reverted to old Autoconfig!"
    exit # It must exit here otherwise it would malfunction!
  fi
fi

if [[ $RevertClient == true ]]
then
  if [[ $Permission == true && ! -z $SUDO_USER ]]
  then
    if [[ ! -f ./Old/sheepit-client-old.jar ]]
    then
      if [[ $SilentMode == false ]]
      then
        echo "Error: No older version found! Can't revert!"
      fi
    else
      rm -f ./sheepit-client*.jar
      mv ./Old/sheepit-client-old.jar ./sheepit-client-current.jar
      if [[ ! -z $SUDO_USER ]]
      then
        chown $SUDO_USER:$SUDO_USER ./sheepit-client-current.jar
      fi
      chmod +x ./sheepit-client-current.jar
      if [[ $SilentMode == false ]]
      then
        echo "Reverted to old client!"
      fi
    fi
  fi
  if [[ $Permission == false ]]
  then
    if [[ ! -f ./Old/sheepit-client-old.jar ]]
    then
      if [[ $SilentMode == false ]]
      then
        echo "Error: No older version found! Can't revert!"
      fi
    else
      rm -f ./sheepit-client*.jar
      mv ./Old/sheepit-client-old.jar ./sheepit-client-current.jar
      sudo chmod +x ./sheepit-client-current.jar
      if [[ $SilentMode == false ]]
      then
        echo "Reverted to old client!"
      fi
    fi
  else
    if [[ $SilentMode == false ]]
    then
      echo "Error: The script runs as root, and no \$SUDO_USER found! Aborting..."
    fi
    exit
  fi
fi

# Probing system and preparing for launch
CPUs=$(grep -c ^processor /proc/cpuinfo)
if [[ $SilentMode == false ]]
then
  echo "Detected CPU cores: $CPUs"
fi
MemAvailable=$(grep "MemAvailable:" /proc/meminfo | awk '{print $2}')
if [[ $MemAvailable -lt 2000000 ]]
then
  if [[ $SilentMode == false ]]
  then
    echo "There's no point rendering with less then 2GB of available RAM... It would produce too much out of memory errors..."
  fi
  if [[ $GPU != true ]]
  then
    if [[ $SilentMode == false ]]
    then
      echo "Aborting..."
    fi
    exit
  fi
fi
if [[ $SilentMode == false ]]
then
  echo "Available memory: ~$(( $MemAvailable / 1000 ))MB"
fi
if [[ ! -z $(java -jar $(pwd)/sheepit-client-*.jar --show-gpu | grep "Id") ]]
then
  GPU=true
# I don't know exactly how AMD/Intel GPUs supposed to show up, but help says "Name of the GPU used for the render, for example CUDA_0 for Nvidia or OPENCL_0 for AMD/Intel card" I don't have an AMD/Intel GPU to work with, so can't test it.
  GPUID=$(java -jar $(pwd)/sheepit-client-*.jar --show-gpu | grep "Id" | awk '{ print $3 }')
  GPUID=$(echo $GPUID | awk '{ print $1 }') # This makes shure that only the first GPUID gets specified in the config file. When I have more then 1 supported GPUs to work with will make it lauunch an instance for all separately.
  CPUs=$(( $CPUs - 1 ))
  GPUMem=$(java -jar $(pwd)/sheepit-client-*.jar --show-gpu | grep "Memory" | awk '{ print $3 }')
  if [[ $SilentMode == false ]]
  then
    echo "Supported GPU: yes($GPUID)"
    echo "Reported video memory: ${GPUMem}MB"
  fi
else
  GPU=false
  if [[ $SilentMode == false ]]
  then
    echo "Supported GPU: No"
  fi
fi
AvailSpace=$(echo $(df -k $(pwd)) | awk '{ print $11 }')
SheepitSize=$(du -s $(pwd) | awk '{ print $1 }')
if [[ $SilentMode == false ]]
then
  echo "Available disk space: $(( $(( $AvailSpace + $SheepitSize )) / 1000 ))MB"
fi

#Automatic configuration attempt
if [[ $ManualConfig == false ]]
then
  if [[ $GPU == true ]]
  then
    if [[ $GPUMem -lt 2000 ]]
    then
      if [[ $SilentMode == false ]]
      then
        echo "There's no point rendering with less then 2GB of VRAM! It would produce too much out of memory errors. Falling back to CPU only rendering..."
      fi
      GPU=false
      CPUs=$(( $CPUs + 1 ))
    fi
  fi
  if [[ $(( $AvailSpace + $SheepitSize )) -lt 2000000 ]]
  then
    if [[ $SilentMode == false ]]
    then
      echo "At least 2GB disk space is required per instance for efficient operation. Aborting..."
    fi
    exit
  fi
  if [[ $CPU == true && $GPU == true && $(( $AvailSpace + $SheepitSize )) -lt 4000000 ]]
  then
    if [[ $SilentMode == false ]]
    then
      echo "At least 2GB disk space is required per instance for efficient operation. Falling back to single client operation..."
    fi
    ComputeMethod
  fi
  if [[ $MemAvailable -lt 5000000 ]]
  then
    if [[ $SilentMode == false ]]
    then
      echo "Your system is low on memory! It can not run 2 instances of the client efficiently. Falling back to single client operation..."
    fi
    ComputeMethod
  fi
  if [[ $CPU == true && $GPU == true ]]
  then
    AUTORAMGPU=$(( $(( $GPUMem * 1000 )) + 500000 )) # Give it some more memory to work with...
    AUTORAMCPU=$(( $MemAvailable - $AUTORAMGPU )) # Subtract that from avaiblable, and give the rest to the CPU instance.
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
    sed -i "s/AUTO_RAM/${AUTORAMCPU}k/g" ./.sheepit-cpu.conf
    HOSTNAME="$(uname -a | awk '{ print $2 }')_CPU"
    sed -i "s/HOSTNAME/$HOSTNAME/g" ./.sheepit-cpu.conf
    if [[ $SilentMode == false ]]
    then
      echo ""
      echo "Auto-config for CPU instance: $CPUs CPU cores, and $(( $AUTORAMCPU / 1000 )) MB of memory."
    fi
  fi
  if [[ $CPU_GPU == true ]] # The CPU_GPU instance uses WD_CPU and .sheepit-cpu.conf but it copies the .sheepit-cpu_gpu.conf not the .sheepit-cpu.conf The only difference is compute method and tile size...
  then
    if [[ -e ./.sheepit-cpu.conf ]]
    then
      rm -f ./.sheepit-cpu.conf
    fi
    cp ./sheepit-cpu_gpu.conf ./.sheepit-cpu.conf
    sed -i "s/AUTO_CORE_COUNT/$CPUs/g" ./.sheepit-cpu.conf
    sed -i "s/AUTO_RAM/${AUTORAMCPU}k/g" ./.sheepit-cpu.conf
    HOSTNAME="$(uname -a | awk '{ print $2 }')"
    sed -i "s/HOSTNAME/$HOSTNAME/g" ./.sheepit-cpu.conf
    sed -i "s/GPUID/$GPUID/g" ./.sheepit-cpu.conf
    if [[ $SilentMode == false ]]
    then
      echo ""
      echo "Auto-config for single instance: $CPUs CPU cores, and $(( $AUTORAMCPU / 1000 )) MB of memory, and will render with either CPU or GPU."
    fi
  fi
  if [[ $GPU == true ]]
  then
    if [[ -e ./.sheepit-gpu.conf ]]
    then
      rm -f ./.sheepit-gpu.conf
    fi
    cp ./sheepit-gpu.conf ./.sheepit-gpu.conf
    sed -i "s/AUTO_RAM/${AUTORAMGPU}k/g" ./.sheepit-gpu.conf
    HOSTNAME="$(uname -a | awk '{ print $2 }')_GPU"
    sed -i "s/HOSTNAME/$HOSTNAME/g" ./.sheepit-gpu.conf
    sed -i "s/GPUID/$GPUID/g" ./.sheepit-gpu.conf
    if [[ $SilentMode == false ]]
    then
      echo ""
      echo "Auto-config for GPU instance: 1 CPU cores, and $(( $AUTORAMGPU / 1000 )) MB of memory."
    fi
  fi
else
  if [[ -z $(grep "AUTO_RAM" "$(pwd)/sheepit-cpu_gpu.conf") && -z $(grep "AUTO_CORE_COUNT" "$(pwd)/sheepit-cpu_gpu.conf") && $GPU == true ]] # in case of manual config if there is GPU it will be true
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
      if [[ -e ./.sheepit-cpu.conf ]]
      then
        rm -f ./.sheepit-cpu.conf
      fi
      cp ./sheepit-cpu.conf ./.sheepit-cpu.conf
    else
      CPU=false # Disable if config incomplete
    fi
    if [[ -z $(grep "AUTO_RAM" "$(pwd)/sheepit-gpu.conf") && $GPU == true ]]
    then
      if [[ -e ./.sheepit-gpu.conf ]]
      then
        rm -f ./.sheepit-gpu.conf
      fi
      cp ./sheepit-gpu.conf ./.sheepit-gpu.conf
    else
      GPU=false # If gpu supported, but config file is incomplete it should disable GPU
    fi
  fi
  if [[ $CPU == false && $GPU == false && $CPU_GPU == false ]]
  then
    if [[ $SilentMode == false ]]
    then
      echo "Error: None of the config files are complete, and ManualConfig is set! (Or GPU not recognized... Make sure you have the latest proprietary driver!) Aborting..."
    fi
    exit
  fi
fi

# Credentials
if [[ $CPU == true || $CPU_GPU == true ]]
then
  X=$(grep "login" "$(pwd)/.sheepit-cpu.conf")
  UNAME=$(echo ${X##*=})
  if [[ "$UNAME" != "$UserName" ]]
  then
    sed -i "s/login=$UNAME/login=$UserName/g" $(pwd)/.sheepit-cpu.conf
  fi
  X=$(grep "password" "$(pwd)/.sheepit-cpu.conf")
  PASSWD=$(echo ${X##*=})
  if [[ "$PASSWD" != "$Password" ]]
  then
    sed -i "s/password=$PASSWD/password=$Password/g" $(pwd)/.sheepit-cpu.conf
  fi
  X=$(grep "proxy" "$(pwd)/.sheepit-cpu.conf")
  PROXY=$(echo ${X##*=})
  if [[ "$PROXY" != "$Proxy" ]]
  then
    sed -i "s/proxy=$PROXY/proxy=$Proxy/g" $(pwd)/.sheepit-cpu.conf
  fi
fi
if [[ $GPU == true ]]
then
  X=$(grep "login" "$(pwd)/.sheepit-gpu.conf")
  UNAME=$(echo ${X##*=})
  if [[ "$UNAME" != "$UserName" ]]
  then
    sed -i "s/login=$UNAME/login=$UserName/g" $(pwd)/.sheepit-gpu.conf
  fi
  X=$(grep "password" "$(pwd)/.sheepit-gpu.conf")
  PASSWD=$(echo ${X##*=})
  if [[ "$PASSWD" != "$Password" ]]
  then
    sed -i "s/password=$PASSWD/password=$Password/g" $(pwd)/.sheepit-gpu.conf
  fi
  X=$(grep "proxy" "$(pwd)/.sheepit-gpu.conf")
  PROXY=$(echo ${X##*=})
  if [[ "$PROXY" != "$Proxy" ]]
  then
    sed -i "s/proxy=$PROXY/proxy=$Proxy/g" $(pwd)/.sheepit-gpu.conf
  fi
fi

# Displaying final config...
if [[ $SilentMode == false ]]
then
  if [[ $CPU == true ]]
  then
    echo ""
    echo "CPU instance final configuration:"
    X=0
    for i in "cache-dir" "login" "proxy" "cpu-cores" "ram" "tile-size"
    do
      Y=$(grep "$i" "$(pwd)/.sheepit-cpu.conf")
      CfCPU[$X]=$(echo ${Y##*=})
      if [[ $i == "ram" ]]
      then
        CfCPU[$X]=${CfCPU[$X]:0:-1}
      fi
      case $X
      in
                    "0" ) :
                          ;;
                    "1" ) echo "  Login as user: ${CfCPU[$X]}"
                          ;;
                    "2" ) echo "  Proxy: ${CfCPU[$X]}"
                          ;;
                    "3" ) echo "  Assigned CPU cores: ${CfCPU[$X]}"
                          ;;
                    "4" ) echo "  Assigned memory: $(( ${CfCPU[$X]} / 1000 )) MB"
                          ;;
                    "5" ) echo "  Tile size: ${CfCPU[$X]}"
                          ;;
                       *) echo "  Error: Unknown option at: case $X!"
                          ;;
      esac
      X=$(( $X + 1 ))
    done
  fi
  if [[ $CPU_GPU == true ]]
  then
    echo ""
    echo "Final configuration:"
    X=0
    for i in "cache-dir" "login" "proxy" "cpu-cores" "ram" "tile-size"
    do
      Y=$(grep "$i" "$(pwd)/.sheepit-cpu_gpu.conf")
      CfCPU[$X]=$(echo ${Y##*=})
      if [[ $i == "ram" ]]
      then
        CfCPU[$X]=${CfCPU[$X]:0:-1}
      fi
      case $X
      in
                    "0" ) :
                          ;;
                    "1" ) echo "  Login as user: ${CfCPU[$X]}"
                          ;;
                    "2" ) echo "  Proxy: ${CfCPU[$X]}"
                          ;;
                    "3" ) echo "  Assigned CPU cores: ${CfCPU[$X]}"
                          ;;
                    "4" ) echo "  Assigned memory: $(( ${CfCPU[$X]} / 1000 )) MB"
                          ;;
                    "5" ) echo "  Tile size: ${CfCPU[$X]}"
                          ;;
                       *) echo "  Error: Unknown option at: case $X!"
                          ;;
      esac
      X=$(( $X + 1 ))
    done
  fi
  if [[ $GPU == true ]]
  then
    echo ""
    echo "GPU instance final configuration:"
    X=0
    for i in "cache-dir" "login" "proxy" "cpu-cores" "ram" "tile-size"
    do
      Y=$(grep "$i" "$(pwd)/.sheepit-gpu.conf")
      CfGPU[$X]=$(echo ${Y##*=})
      if [[ $i == "ram" ]]
      then
        CfGPU[$X]=${CfGPU[$X]:0:-1}
      fi
      case $X
      in
                    "0" ) :
                          ;;
                    "1" ) echo "  Login as user: ${CfGPU[$X]}"
                          ;;
                    "2" ) echo "  Proxy: ${CfGPU[$X]}"
                          ;;
                    "3" ) echo "  Assigned CPU cores: ${CfGPU[$X]}"
                          ;;
                    "4" ) echo "  Assigned memory: $(( ${CfGPU[$X]} / 1000 )) MB"
                          ;;
                    "5" ) echo "  Tile size: ${CfGPU[$X]}"
                          ;;
                       *) echo "  Error: Unknown option at: case $X!"
                          ;;
      esac
      X=$(( $X + 1 ))
    done
  fi
else # Not displaying in silent mode, but still need that array for error checking...
  if [[ $CPU == true ]]
  then
    X=0
    for i in "cache-dir" "login" "proxy" "cpu-cores" "ram" "tile-size"
    do
      Y=$(grep "$i" "$(pwd)/.sheepit-cpu.conf")
      CfCPU[$X]=$(echo ${Y##*=})
      if [[ $i == "ram" ]]
      then
        CfCPU[$X]=${CfCPU[$X]:0:-1}
      fi
      X=$(( $X + 1 ))
    done
  fi
  if [[ $CPU_GPU == true ]]
  then
    X=0
    for i in "cache-dir" "login" "proxy" "cpu-cores" "ram" "tile-size"
    do
      Y=$(grep "$i" "$(pwd)/.sheepit-cpu_gpu.conf")
      CfCPU[$X]=$(echo ${Y##*=})
      if [[ $i == "ram" ]]
      then
        CfCPU[$X]=${CfCPU[$X]:0:-1}
      fi
      X=$(( $X + 1 ))
    done
  fi
  if [[ $GPU == true ]]
  then
    X=0
    for i in "cache-dir" "login" "proxy" "cpu-cores" "ram" "tile-size"
    do
      Y=$(grep "$i" "$(pwd)/.sheepit-gpu.conf")
      CfGPU[$X]=$(echo ${Y##*=})
      if [[ $i == "ram" ]]
      then
        CfGPU[$X]=${CfGPU[$X]:0:-1}
      fi
      X=$(( $X + 1 ))
    done
  fi
fi

# Error checking
if [[ $CPU == true && $GPU == true ]]
then
  if [[ ${CfCPU[0]} == ${CfGPU[0]} ]]
  then
    if [[ $SilentMode == true ]]
    then
      exit
    else
      echo "Error: The working directory can not be the same directory! The 2 instance would interfere and crash..."
      exit
    fi
  fi
  if [[ ${CfCPU[3]} -gt $CPUs ]]
  then
    if [[ $SilentMode == true ]]
    then
      exit
    else
      echo "Error: You need at least 1 CPU core for feeding the GPU with data unless you disable your GPU..."
      exit
    fi
  fi
  if [[ $(( ${CfCPU[3]} + ${CfGPU[3]} )) -gt $(( $CPUs + 1 )) ]]
  then
    if [[ $SilentMode == true ]]
    then
      exit
    else
      echo "Error: You have specified more CPU cores overall then the CPU actually has!"
      exit
    fi
  fi
  if [[ $(( ${CfCPU[4]} + ${CfGPU[4]} )) -gt $MemAvailable ]]
  then
    if [[ $SilentMode == true ]]
    then
      exit
    else
      echo "Error: You have specified more RAM overall then the total availabel memory of your machine!"
      exit
    fi
  fi
fi
if [[ $CPU == true || $CPU_GPU == true ]]
then
  if [[ ${CfCPU[3]} -gt $CPUs ]]
  then
    if [[ $SilentMode == true ]]
    then
      exit
    else
      echo "Error: You have specified more CPU cores then the CPU actually has!"
      exit
    fi
  fi
  if [[ ${CfCPU[4]} -gt $MemAvailable ]]
  then
    if [[ $SilentMode == true ]]
    then
      exit
    else
      echo "Error: You have specified more RAM then the availabel memory of your machine!"
      exit
    fi
  fi
fi
if [[ $GPU == true ]]
then
  if [[ ${CfGPU[3]} -gt $CPUs ]]
  then
    if [[ $SilentMode == true ]]
    then
      exit
    else
      echo "Error: You have specified more CPU cores then the CPU actually has!"
      exit
    fi
  fi
  if [[ ${CfGPU[4]} -gt $MemAvailable ]]
  then
    if [[ $SilentMode == true ]]
    then
      exit
    else
      echo "Error: You have specified more RAM then the availabel memory of your machine!"
      exit
    fi
  fi
fi

# Launching processes (gnome-terminal -e option gave deprecated error, so I'm only using that command to open multiple terminals...)
echo ""
echo "Launching client instance(s)!"
if [[ $CommandLine == false && $SilentMode == false ]]
then
  if [[ $GPU == true ]]
  then
    if [[ $TempMon == true || $HTop == true || $CPU == true || $Facepalm == true ]]
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
    if [[ $TempMon == true || $HTop == true || $Facepalm == true ]]
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
    if [[ $TempMon == true || $Facepalm == true ]]
    then
      NewTerminal
      TermH="$NewTerm"
      setsid sh -c "exec htop <> $NewTerm >&0 2>&1"&
    else
      htop
    fi
  fi
  echo ""
  echo "Temperatures should generally be below 80 degrees C or 176 degrees F even after about 30 minutes under full load. If it ever goes over that, you should stop rendering and try:"
  echo "  1. Cleaning the machine of dust."
  echo "  2. Change the thermal paste."
  echo "  3. Leave the case open."
  echo "  4. Put the machine in a cooler environment."
  echo "  5. If none of this work, buy an adequate cooler, or just don't render."
  sleep 15
  while [[ $TempMon == true || $Facepalm == true ]]
  do
    clear
    if [[ $TempMon == true ]]
    then
      inxi -s
    fi
     # There is basically no good way to stop the client when it was started in command line, so the script simply kills the process.
    if [[ $Facepalm == true ]]
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
else ### Silent Mode ###
  if [[ $SilentMode == true ]]
  then
    if [[ $GPU == true ]]
    then
      if [[ $Permission == false ]]
      then
        java -jar $(pwd)/sheepit-client-*.jar -config $(pwd)/.sheepit-gpu.conf > /dev/null&
      fi
    fi
    if [[ $CPU == true || $CPU_GPU == true ]]
    then
      if [[ $Permission == false ]]
      then
        java -jar $(pwd)/sheepit-client-*.jar -config $(pwd)/.sheepit-cpu.conf > /dev/null&
      fi
    fi
  else ### Command Line ###
    if [[ $GPU == true ]]
    then
      if [[ ! -f "$(pwd)/.SilencerGPU" ]]
      then
        touch $(pwd)/.SilencerGPU
      else
        echo -n "" > "$(pwd)/.SilencerGPU"
      fi
      if [[ $Permission == true ]]
      then
        sudo -u $SUDO_USER java -jar $(pwd)/sheepit-client-*.jar -config $(pwd)/.sheepit-gpu.conf > $(pwd)/.SilencerGPU&
      else
        java -jar $(pwd)/sheepit-client-*.jar -config $(pwd)/.sheepit-gpu.conf > $(pwd)/.SilencerGPU&
      fi
    fi
    if [[ $CPU == true || $CPU_GPU == true ]]
    then
      if [[ ! -f "$(pwd)/.SilencerCPU" ]]
      then
        touch $(pwd)/.SilencerCPU
      else
        echo -n "" > "$(pwd)/.SilencerCPU"
      fi
      if [[ $Permission == true ]]
      then
        sudo -u $SUDO_USER java -jar $(pwd)/sheepit-client-*.jar -config $(pwd)/.sheepit-cpu.conf > $(pwd)/.SilencerCPU&
      else
        java -jar $(pwd)/sheepit-client-*.jar -config $(pwd)/.sheepit-cpu.conf > $(pwd)/.SilencerCPU&
      fi
    fi
    echo ""
    echo "Temperatures should generally be below 80 degrees C or 176 degrees F even after about 30 minutes under full load. If it ever goes over that, you should stop rendering and try:"
    echo "  1. Cleaning the machine of dust."
    echo "  2. Change the thermal paste."
    echo "  3. Leave the case open."
    echo "  4. Put the machine in a cooler environment."
    echo "  5. If none of this work, buy an adequate cooler, or just don't render."
    sleep 15
    while [[ $TempMon == true || $Facepalm == true ]]
    do
      clear
      if [[ $TempMon == true ]]
      then
        inxi -s
      fi
       # There is basically no good way to stop the client when it was started in command line, so the script simply kills the process.
      if [[ $Facepalm == true ]]
      then
        if [[ -f "$(pwd)/.SilencerCPU" ]]
        then
          echo ""
          if [[ $CPU_GPU == true ]]
          then
            echo "CPU/GPU instance(last 5 lines):"
          else
            echo "CPU instance(last 5 lines):"
          fi
          tail -n 5 "$(pwd)/.SilencerCPU"
        fi
        if [[ -f "$(pwd)/.SilencerGPU" ]]
        then
          echo ""
          echo "GPU instance(last 5 lines):"
          tail -n 5 "$(pwd)/.SilencerGPU"
        fi
        echo ""
        read -t 3 -p "Type \"q\" for quit (and hit enter): " Quit
        if [[ $Quit == "q" ]]
        then
          Kill="$(ps -aux | grep "sheepit" | grep -v "grep" | grep -v "sudo" | awk '{ print $2 }')"
          for i in GPU CPU
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
fi
