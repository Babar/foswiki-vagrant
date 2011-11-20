**Vagrant for Foswiki**

Each new Foswiki developer needs to setup her/his own private local Foswiki installation.
This is cumbersome, error-prone, slow, and might lead to having less developers because a first setup for dev is a lot of work.

## Goal
The aim of this project is double:
1. Ease first developer installation so they can start coding in "minutes"
2. Ease and automate unit testing on several architectures

## Installation
To use this, you will need Vagrant, VirtualBox (version 4 at least), and some basebox for Vagrant
<pre>
TODO: Give real instructions
#download and install VirtualBox, then
$ gem install vagrant
$ git clone https://github.com/Babar/foswiki-vagrant.git
$ cd foswiki-vagrant
$ git submodule update --init
</pre>

## Usage
You can simply boot up your VM, and by default it will install all dependencies and run the unit tests for the latest release branch, and trunk. Should take over half an hour the first time:
<pre>
$ vagrant up
</pre>
Then you can "play" with your box, locally using:
<pre>
$ vagrant ssh
</pre>
You can access your local Foswiki installation at: http://localhost:8080

To replay just the provisionning phase (what chef does), issue:
<pre>
$ vagrant provision
</pre>

When you are done, you can delete everything including the VM (**You will loose any modification you made**) using:
<pre>
$ vagrant destroy
</pre>
Or you can simply shutdown the VM:
<pre>
$ vagrant halt
</pre>
