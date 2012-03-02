#trick out the railsready script
sudo mkdir /Library/Developer
sudo mkdir /Library/Developer/Shared

sudo touch /Library/Developer/Shared/XcodeTools.plist

cd ~/Downloads

#setup the gcc
curl -kO http://cloud.github.com/downloads/kennethreitz/osx-gcc-installer/GCC-10.6.pkg

sudo installer -pkg ./GCC-10.6.pkg -target /

rm -f GCC-10.6.pkg

#Sets up Homebrew, Ruby 1.9.3 Imagemagick, libs for Rails (sqlite, mysql), Bundler, Passenger, Rails gems and Git
#curl -kO https://raw.github.com/joshfng/railsready/master/railsready.sh && bash railsready.sh
#start railsready.sh

shopt -s nocaseglob
set -e

ruby_version="1.9.2"
ruby_version_string="1.9.2-p180"
ruby_source_url="http://ftp.ruby-lang.org/pub/ruby/1.9/ruby-1.9.2-p180.tar.gz"
ruby_source_tar_name="ruby-1.9.2-p180.tar.gz"
ruby_source_dir_name="ruby-1.9.2-p180"
script_runner=$(whoami)
railsready_path=$(cd && pwd)/railsready
log_file="$railsready_path/install.log"

control_c()
{
  echo -en "\n\n*** Exiting ***\n\n"
  exit 1
}

# trap keyboard interrupt (control-c)
trap control_c SIGINT

clear

echo "#################################"
echo "########## Rails Ready ##########"
echo "#################################"

#determine the distro
if [[ $MACHTYPE = *linux* ]] ; then
  distro_sig=$(cat /etc/issue)
  if [[ $distro_sig =~ ubuntu ]] ; then
    distro="ubuntu"
  elif [[ $distro_sig =~ centos ]] ; then
    distro="centos"
  fi
elif [[ $MACHTYPE = *darwin* ]] ; then
  distro="osx"
else
  echo -e "\nRails Ready currently only supports Ubuntu and CentOS and OSX\n"
  exit 1
fi

#now check if user is root
if [ $script_runner == "root" ] ; then
  echo -e "\nThis script must be run as a normal user with sudo privileges\n"
  exit 1
fi

echo -e "\n\n"
echo "!!! This script will update your system! Run on a fresh install only !!!"
echo "run tail -f $log_file in a new terminal to watch the install"

echo -e "\n"
echo "What this script gets you:"
echo " * An updated system"
echo " * Ruby $ruby_version_string"
echo " * Imagemagick"
echo " * libs needed to run Rails (sqlite, mysql, etc)"
echo " * Bundler, Passenger, and Rails gems"
echo " * Git"
echo " * SVN"
echo " * svnX"
echo " * MAMP"

# Check if the user has sudo privileges.
sudo -v >/dev/null 2>&1 || { echo $script_runner has no sudo privileges ; exit 1; }

# Ask if you want to build Ruby or install RVM
echo -e "\n"
echo "Build Ruby or install RVM?"
echo "=> 1. Build from source"
echo "=> 2. Install RVM"
echo -n "Select your Ruby type [1 or 2]? "
read whichRuby

if [ $whichRuby -eq 1 ] ; then
  echo -e "\n\n!!! Set to build Ruby from source and install system wide !!! \n"
elif [ $whichRuby -eq 2 ] ; then
  echo -e "\n\n!!! Set to install RVM for user: $script_runner !!! \n"
else
  echo -e "\n\n!!! Must choose to build Ruby or install RVM, exiting !!!"
  exit 1
fi

echo -e "\n=> Creating install dir..."
cd && mkdir -p railsready/src && cd railsready && touch install.log
echo "==> done..."

echo -e "\n=> Downloading and running recipe for $distro...\n"
#Download the distro specific recipe and run it, passing along all the variables as args
if [[ $MACHTYPE = *linux* ]] ; then
  wget --no-check-certificate -O $railsready_path/src/$distro.sh https://raw.github.com/joshfng/railsready/master/recipes/$distro.sh && cd $railsready_path/src && bash $distro.sh $ruby_version $ruby_version_string $ruby_source_url $ruby_source_tar_name $ruby_source_dir_name $whichRuby $railsready_path $log_file
else
  cd $railsready_path/src && curl -O https://raw.github.com/joshfng/railsready/master/recipes/$distro.sh && bash $distro.sh $ruby_version $ruby_version_string $ruby_source_url $ruby_source_tar_name $ruby_source_dir_name $whichRuby $railsready_path $log_file
fi
echo -e "\n==> done running $distro specific commands..."

#now that all the distro specific packages are installed lets get Ruby
if [ $whichRuby -eq 1 ] ; then
  # Install Ruby
  echo -e "\n=> Downloading Ruby $ruby_version_string \n"
  cd $railsready_path/src && wget $ruby_source_url
  echo -e "\n==> done..."
  echo -e "\n=> Extracting Ruby $ruby_version_string"
  tar -xzf $ruby_source_tar_name >> $log_file 2>&1
  echo "==> done..."
  echo -e "\n=> Building Ruby $ruby_version_string (this will take a while)..."
  cd  $ruby_source_dir_name && ./configure --prefix=/usr/local >> $log_file 2>&1 \
   && make >> $log_file 2>&1 \
    && sudo make install >> $log_file 2>&1
  echo "==> done..."
elif [ $whichRuby -eq 2 ] ; then
  #thanks wayneeseguin :)
  echo -e "\n=> Installing RVM the Ruby enVironment Manager http://rvm.beginrescueend.com/rvm/install/ \n"
  curl -O -L -k https://raw.github.com/wayneeseguin/rvm/master/binscripts/rvm-installer
  chmod +x rvm-installer
  "$PWD/rvm-installer" >> $log_file 2>&1
  [[ -f rvm-installer ]] && rm -f rvm-installer
  echo -e "\n=> Setting up RVM to load with new shells..."
  #if RVM is installed as user root it goes to /usr/local/rvm/ not ~/.rvm
  echo  '[[ -s "$HOME/.rvm/scripts/rvm" ]] && . "$HOME/.rvm/scripts/rvm"  # Load RVM into a shell session *as a function*' >> "$HOME/.bash_profile"
  echo "==> done..."
  echo "=> Loading RVM..."
  if [ -f ~/.bashrc ] ; then
    source ~/.bashrc
  fi
  if [ -f ~/.bash_profile ] ; then
    source ~/.bash_profile
  fi
  if [ -f ~/.rvm/scripts/rvm ] ; then
    source ~/.rvm/scripts/rvm
  fi
  echo "==> done..."
  echo -e "\n=> Installing Ruby $ruby_version_string (this will take a while)..."
  echo -e "=> More information about installing rubies can be found at http://rvm.beginrescueend.com/rubies/installing/ \n"
  rvm install $ruby_version >> $log_file 2>&1
  echo -e "\n==> done..."
  echo -e "\n=> Using $ruby_version and setting it as default for new shells..."
  echo "=> More information about Rubies can be found at http://rvm.beginrescueend.com/rubies/default/"
  rvm --default use $ruby_version >> $log_file 2>&1
  echo "==> done..."
else
  echo "How did you even get here?"
  exit 1
fi

# Reload bash
echo -e "\n=> Reloading shell so ruby and rubygems are available..."
if [ -f ~/.bashrc ] ; then
  source ~/.bashrc
fi
if [ -f ~/.bash_profile ] ; then
  source ~/.bash_profile
fi
echo "==> done..."

echo -e "\n=> Updating Rubygems..."
if [ $whichRuby -eq 1 ] ; then
  sudo gem update --system --no-ri --no-rdoc >> $log_file 2>&1
elif [ $whichRuby -eq 2 ] ; then
  gem update --system --no-ri --no-rdoc >> $log_file 2>&1
fi
echo "==> done..."

echo -e "\n=> Installing Bundler, Passenger and Rails..."
if [ $whichRuby -eq 1 ] ; then
  sudo gem install bundler passenger rails --no-ri --no-rdoc >> $log_file 2>&1
elif [ $whichRuby -eq 2 ] ; then
  gem install bundler passenger rails --no-ri --no-rdoc >> $log_file 2>&1
fi
echo "==> done..."

echo -e "\n#################################"
echo    "### Installation is complete! ###"
echo -e "#################################\n"

echo -e "\n !!! logout and back in to access Ruby !!!\n"

#Setup SVN
curl -O http://share.pvcomm.com/GJF/support/Subversion-1.7.2_10.6.x.pkg

sudo installer -pkg ./Subversion-1.7.2_10.6.x.pkg -target /

rm -f Subversion-1.7.2_10.6.x.pkg

#Install svnx
curl -Ok http://svnx.googlecode.com/files/svnX%201.3.2.dmg
hdiutil mount svnX%201.3.2.dmg

sudo cp -R /Volumes/svnX/ /Applications/
hdiutil unmount /Volumes/svnx/

rm -f svnX%201.3.2.dmg

#Install MAMP
curl -Ok http://mamp.mac-devedge.de/downloads/MAMP-PRO/releases/1.9.6.1/MAMP_MAMP_PRO_1.9.6.1.dmg.zip

unzip MAMP_MAMP_PRO_1.9.6.1.dmg.zip

hdiutil mount MAMP_MAMP_PRO_1.9.6.1.dmg

cp -R /Volumes/MAMP\ \&\ MAMP\ PRO/MAMP /Applications
hdiutil unmount /Volumes/MAMP\ \&\ MAMP\ PRO/

clear

echo "Ready to run some rails projects"
