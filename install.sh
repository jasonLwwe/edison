#!/bin/bash

pass="success\n"
fail="failure\n"
done="done\n"
xit="exiting\n"
yes="yes\n"
no="no\n"

# Test for eth0 config file
if [[ -a /etc/sysconfig/network-scripts/ifcfg-eth0 ]]; then
  
  # Test if eth0 starts on boot.
	echo -en "eth0 starts onboot... "
	grep "ONBOOT=yes" /etc/sysconfig/network-scripts/ifcfg-eth0 > /dev/null;
	if [[ $? -ne 0 ]]; then
    
    # eth0 doesn't start on boot, so backup the original config before re-configing it.
	  echo -en $no ;
    filename=ifcfg-eth0.orig
    if [[ -a /etc/sysconfig/network-scripts/${filename} ]]; then
      filename="ifcfg-eth0.`date +%Y%m%d.%H%M`.bak";
    fi
		echo -en "Backing up /etc/sysconfig/network-scripts/ifcfg-eth0 to ${filename}... ";
		mv  /etc/sysconfig/network-scripts/ifcfg-eth0 /etc/sysconfig/network-scripts/${filename};
		echo -en $done ; 

    # Reconfig eth0 to boot on start.
		echo -en "Updating ifcfg-eth0 to start eth0 on boot... ";
		cat /etc/sysconfig/network-scripts/ifcfg-eth0.orig | sed -e 's/ONBOOT=no/ONBOOT=yes/' >  /etc/sysconfig/network-scripts/ifcfg-eth0;
		echo -en $done ; 

    # Restart eth0
    echo -en "Restarting eth0\n"
    echo -en "\tBringing eth0 down... "
    ifdown eth0 > /dev/null
    if [[ $? -eq 0 ]]; then
      echo -en $pass ;
    else
      echo -en $fail ;
    fi
    echo -en "\tBringing eth0 up... "
    ifup eth0 > /dev/null
    if [[ $? -eq 0 ]]; then
      echo -en $pass ;
    else
      echo -en $fail ;
      echo FATAL: Could not start eth0... $xit ;
      exit 1; 
    fi 

  else
    # eth0 was configged to boot on start, don't change the config.
    echo -en $yes ;
  fi
fi

err_file="/tmp/Error"
dev_tools="Development tools"

echo -en "Is group $dev_tools installed... "
yum grouplist "${dev_tools}" | pcregrep -M "Installed Groups:(\n|.)*${dev_tools}" &>/dev/null
if [[ $? -ne 0 ]]; then
  echo -en $no;
  echo -en "Installing group \"${dev_tools}\"... ";

  yum -y groupinstall "${dev_tools}" 2>/tmp/Error 1>/dev/null;
  if [[ $? -eq 0 ]]; then
    echo -en $pass;
  else
    echo -en $fail;
    cat /tmp/Error;
    rm /tmp/Error;
    exit 1;
  fi

  if [[ -a $err_file ]]; then
    rm -f $err_file;
  fi
  
else
  echo -en $yes;
fi

src=/usr/src
web=www
phpext=${web}/php/extensions
mod=${web}/modules
mem=${web}/memcache
echo -en "Downloading and installing...\n"
for apath in perl rpms ${web}/apache ${phpext}/ssh2 ${phpext}/tidy ${phpext}/xhprof ${web}/mysql.x86_64 ${mod}/image ${mod}/encryption ${mem}/client ${mem}/server
do
  newdir=${src}/${apath}
  echo -en "\t${newdir}... "
  if [ -d ${newdir} ]; then
    echo -en "already exists\n";
  else
    mkdir -p $newdir
    if [ -d ${newdir} ]; then
      echo -en ${pass};
    else
      echo -en ${fail};
    fi
  fi
  
  if [ -d ${newdir} ]; then
    cd ${newdir}
    case ${newdir} in
    ${src}/${mod}/image)
      for file in libiconv-1.14.tar.gz zlib-1.2.8.tar.gz libpng-1.6.13.tar.gz jpegsrc.v9a.tar.gz freetype-2.5.3.tar.gz
      do
        if [ ! -e ./${file} ]; then
          echo -en "\t\tDownloading ${file}..."
          case $file in
          libiconv-1.14.tar.gz)
              wget "http://ftp.gnu.org/gnu/libiconv/libiconv-1.14.tar.gz" &>/dev/null 
              ;;
          zlib-1.2.8.tar.gz)
              wget "http://zlib.net/zlib-1.2.8.tar.gz" &>/dev/null
              ;;
          libpng-1.6.13.tar.gz)
              wget "ftp://ftp.simplesystems.org/pub/libpng/png/src/libpng16/libpng-1.6.13.tar.gz" &>/dev/null
              ;;
          jpegsrc.v9a.tar.gz)
              wget "http://www.ijg.org/files/jpegsrc.v9a.tar.gz" &>/dev/null
              ;;
          freetype-2.5.3.tar.gz)
              wget "http://download.savannah.gnu.org/releases/freetype/freetype-2.5.3.tar.gz" &>/dev/null
              ;;
          esac
          if [ -e ./${file} ]; then
            echo -en ${pass};
          else
            echo -en ${fail};
          fi
        fi
      done
      ;;
    *)
      echo -en "\t\t No instructions for ${newdir}\n"
      ;;
    esac
  fi

done

