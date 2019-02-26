Current version: 1.3(still beta...)

The script runs fine on both of my machines, but it is NOT fully tested! This is intended to be fully automated for lazy people like me... :P (Sorry Windows/Mac/other linux users for whom it doesn't work, I'm not really an expert... Bash is the language I know best, I've written it for myself primarily. It may or may or may not work on other linux distros, but it's open source you can fork it if you want or just use ubuntu. :P)
- It does require sudo to install java, inxi and htop if not found! (As far as I know there is no way to interface the client, once it has been launched, it's out of the launcher's control, therefore it simply must kill the process in order to stop the client... Will fix then if and when the sheepit devs make it possible...)
- Automatic values can be overridden by simply specifying a value in one or more of the config files. (There's a comment in the beginning of the script for more details...)
- You may want to change the included client to a new official one... It should theretically work fine, but it's not guaranteed!
- The client now supports AMD GPUs, and the script should theoretically also work with it, but I have no way of testing that since I only have a single nvidia GPU to work with... It is however only able to use a single GPU and/or CPU... No SLI/Crossfire, not even 2 GPU at a time without SLI/Crossfire...

People expressed concern about the genuinity of the included client. Here's my answer to that:
It was made primarily for my own convenience, and I want it to work whenever I download it whether or not the latest version of the client is compatible, so I will always include a working client. If you don't trust it you can replace it with the latest available official client from the sheepit site, it generally should work however it's not guaranteed. In 6 month or so I found 2 changes to be incompatible, which required modification of the script, so I can't really rely always on the latest client! That is exactly why the V1.3 feature was implemented!

New features in:
V1.3:
  - Added Client and Script update and rollback possibility. (Thanks to M*C*O for the link to get the latest client!)

V1.2:
  - Client updated
  - Fixed an issue with the new client: Config file got updated, and memory value was not recognized...
  - Memory alocation algorithm improved.
  - Added -s option for compatibility with my Systemd-Service-Generator script to make it run automatically at startup. (Check the help for conficuration tips...)

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
