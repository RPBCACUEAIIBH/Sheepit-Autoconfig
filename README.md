Current version: 1.1.1(still beta...)

The script runs fine on both of my machines, but it is NOT fully tested! This is intended to be fully automated for lazy people like I am... :P (Sorry Windows/mac/other linux users, I'm not really an expert, bash is the language I know best, I've written it for myself primarily. It may or may not work on other linux distros, but it's open source you can fork it if you want or just use ubuntu. :P)
- Currently only runs on Ubuntu desktop... It can't open terminals in CLI, thus will fail to run. I may make a less fancy CLI option if necessary...
- It does require sudo to install java if not found, and to be able to stop the client upon request! (As far as I know there is no way to interface the client, once it has been launched, it's out of the launcher's control, therefore it simply must kill the process in order to stop... Will fix then if and when the sheepit devs make it possible...)
- Automatic values can be overridden by simply specifying a value in one or more of the config files. (There's a comment in the beginning of the script for more details...)
- From time to time you may need to change the included client to a new official one... It should work fine, it's the third version I've used since I've started this project...
- The client now supports AMD GPUs, and the script should theoretically also work with it, but I have no way of testing that since I do not have an AMD GPU to work with...

New features in:
V1.1.1:
  - Client updated
  - Slight change in config file, and --show-gpu of the client reuslted in not detecting the GPU, and launching only CPU instance... It's fixed now (Only tested with nvidia GPU!)
  - I've noticed that I left the old client attached... Only the latest should be there...

V1.1:
  - Sudo isn't required if java htop and inxi are installed... Thatnks to Tehrasha for pointing it out...
  - -c option for CLI operation added.(Theoretically it should run via SSH with -c option...)
  - --help added
  - Now it displays a summary of final settings...(Previously it only displayed autoconfig values...)
  - -u and -p options added for easily setting credentials, and proxy... (in V1.0 you had to add them to all the config files.)
  - -m option added for skipping autoconfig. (The script will still collect information about the machine, and check the config files for errors.)
