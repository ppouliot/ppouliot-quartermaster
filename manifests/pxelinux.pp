# Class: quartermaster::pxelinux
#
# This Class defines the creation of the linux pxe infrastructure
#
define quartermaster::pxelinux (
  # The following pxe menu variables are required for the templates used in this class
  $default_pxeboot_option        = $quartermaster::default_pxeboot_option,
  $pxe_menu_timeout              = $quartermaster::pxe_menu_timeout,
  $pxe_menu_total_timeout        = $quartermaster::pxe_menu_total_timeout,
  $pxe_menu_allow_user_arguments = $quartermaster::pxe_menu_allow_user_arguments,
  $pxe_menu_default_graphics     = $quartermaster::pxe_menu_default_graphics,
  $puppetmaster                  = $quartermaster::puppetmaster,
  $jenkins_swarm_version_to_use  = $quartermaster::jenkins_swarm_version_to_use,
  $use_local_proxy               = $quartermaster::use_local_proxy,
  $vnc_passwd                    = $quartermaster::vnc_passwd,
){

# this regex works w/ no .
#if $name =~ /([a-zA-Z0-9_]+)-([a-zA-Z0-9_]+)-([a-zA-Z0-9_]+)/ {
  if $quartermaster::use_local_proxy {
    Staging::File {
      # Some curl_options to add for downloading large files over questionable links
      # Use local cache   * --proxy http://${ipaddress}:3128
      # Continue Download * -C 
      # Maximum Time      * --max-time 1500 
      # Retry             * --retry 3 
      curl_option => "--proxy http://${::ipaddress}:3128 --retry 3",
      #
      # Puppet waits for the Curl execution to finish
      #
      timeout     => '0',
    }
  }

  # Define proper name formatting matching distro-release-p_arch
  if $name =~ /([a-zA-Z0-9_\.]+)-([a-zA-Z0-9_\.]+)-([a-zA-Z0-9_\.]+)/ {
    $distro  = $1
    $release = $2
    $p_arch  = $3
    notice($distro)
    notice($release)
    notice($p_arch)
    validate_string($distro, '^(devuan|debian|centos|coreos|flatcar|rancheros|fedora|kali|scientificlinux|openbsd|opensuse|oraclelinux|ubuntu)$', 'The currently supported values for distro are devuan, debian, centos, coreos, flatcar, rancheros, fedora, kali, openbsd, oraclelinux, scientificlinux, opensuse, and ubuntu',)
    validate_string($p_arch, '^(i386|i586|i686|x86_65|amd64)$', 'The currently supported values for pocessor architecture  are i386,i586,i686,x86_64,amd64',)
  } else {
    fail('You must put your entry in format "<Distro>-<Release>-<Processor Arch>" like "centos-7-x86_64" or "ubuntu-14.04-amd64"')
  }
  # convert release into rel_number to check to major and minor releases
  $rel_number = regsubst($release, '(\.)','','G')
  notice($rel_number)

  if $release =~/([0-9]+).([0-9])/{
    $rel_major = $1
    $rel_minor = $2
    notice($rel_major)
    notice($rel_minor)
  } else {
    warning("${distro} ${release} does not have major and minor point releases for ${name}.")
  }

  if ( $distro == 'centos') {
    case $release {
      '2.1':{
        $centos_url        = "http://vault.centos.org/${release}"
        $_dot_bootsplash   = '.lss'
        $vnc_option        = 'vnc'
        $vnc_option_passwd = 'vncpasswd'
        $ks_option         = 'ks'
        $url_option        = 'url'
        $url               = "${centos_url}/final/${p_arch}/isolinux"
        if $p_arch == 'x86_64' {
          fail('Centos 2.1 does not support x86_64, please remove centos-2.1-x86_64 from your pxeboot options!')
        }
      }
      '3.1','3.3','3.4','3.5','3.6','3.7','3.8','3.9',
      '4.0','4.1','4.2','4.3','4.4','4.5','4.6','4.7','4.8','4.9',
      '5.0','5.1','5.2','5.3','5.4','5.5','5.6','5.7','5.8','5.9','5.10','5.11':{
        $centos_url        = "http://vault.centos.org/${release}"
        $_dot_bootsplash   = '.lss'
        $vnc_option        = 'vnc'
        $vnc_option_passwd = 'vncpasswd'
        $ks_option         = 'ks'
        $url_option        = 'url'
        $url             = "${centos_url}/os/${p_arch}/images/pxeboot"
      }
      '6.0','6.1','6.2','6.3','6.4','6.5','6.6','6.7':{
        $centos_url        = "http://vault.centos.org/${release}"
        $_dot_bootsplash   = '.jpg'
        $vnc_option        = 'vnc'
        $vnc_option_passwd = 'vncpasswd'
        $ks_option         = 'ks'
        $url_option        = 'url'
        $url             = "${centos_url}/os/${p_arch}/images/pxeboot"
      }
      '6.8','6.9':{
        $centos_url        = "http://vault.centos.org/centos/${release}"
        $_dot_bootsplash   = '.png'
        $vnc_option        = 'inst.vnc'
        $vnc_option_passwd = 'inst.vncpasswd'
        $ks_option         = 'ks'
        $url_option        = 'url'
        $url             = "${centos_url}/os/${p_arch}/images/pxeboot"
      }
      '7.0.1406','7.1.1503','7.2.1511','7.3.1611','7.4.1708','7.5.1804':{
        $centos_url        = "http://vault.centos.org/centos/${release}"
        $_dot_bootsplash   = '.png'
        $vnc_option        = 'inst.vnc'
        $vnc_option_passwd = 'inst.vncpasswd'
        $ks_option         = 'ks'
        $url_option        = 'inst.repo'
        $url             = "${centos_url}/os/${p_arch}/images/pxeboot"
      }
      '7.6.1810':{
        $centos_url        = "http://mirror.centos.org/centos/${release}"
        $_dot_bootsplash   = '.png'
        $vnc_option        = 'inst.vnc'
        $vnc_option_passwd = 'inst.vncpasswd'
        $ks_option         = 'ks'
        $url_option        = 'inst.repo'
        $url             = "${centos_url}/os/${p_arch}/images/pxeboot"
      }
      default:{
        warning("${name} is not a centos release")
      }
    }
    notice($centos_url)
    notice($url)
    $autofile        = 'kickstart'
    $linux_installer = 'anaconda'
    $pxekernel       = 'vmlinuz'
    $initrd          = '.img'
    $src_initrd      = "initrd${initrd}"
    $target_kernel   = $rel_number
    $target_initrd   = "${rel_number}${initrd}"
    #$url             = "${centos_url}/os/${p_arch}/images/pxeboot"
    $inst_repo       = "${centos_url}/os/${p_arch}/"
    $update_repo     = "${centos_url}/updates/${p_arch}/"
    $splash_url       = "${centos_url}/isolinux/splash${_dot_bootsplash}"
    $logo_url        = 'https://www.centos.org/images/logo_small.png'
    $boot_iso_url    = "${centos_url}/os/${p_arch}/images/${boot_iso_name}"
    $boot_iso_name   = 'boot.iso'
    $mini_iso_name   = 'boot.iso'
    $unzip_iso       = false
    $rel_name        = $name
  }

  if ( $distro == 'fedora') {
    case $release {
      '2','3','4','5','6':{
        $fedora_url        = 'http://archives.fedoraproject.org/pub/archive/fedora/linux/core'
        $fedora_flavor     = ''
        $_dot_bootsplash   = '.lss'
        $vnc_option        = 'vnc'
        $vnc_option_passwd = 'vncpasswd'
        $ks_option         = 'ks'
        $url_option        = 'url'
      }
      '7','8','9','10','11','12','13','14','15','16','17','18','19','20':{
        $fedora_url        = 'http://archives.fedoraproject.org/pub/archive/fedora/linux/releases'
        $fedora_flavor     = 'Fedora/'
        $_dot_bootsplash   = '.jpg'
        $vnc_option        = 'vnc'
        $vnc_option_passwd = 'vncpasswd'
        $ks_option         = 'ks'
        $url_option        = 'url'
      }
      '21':{
        $fedora_url        = 'http://archives.fedoraproject.org/pub/archive/fedora/linux/releases'
        $fedora_flavor     = 'Server/'
        $_dot_bootsplash   = '.png'
        $vnc_option        = 'vnc'
        $vnc_option_passwd = 'vncpasswd'
        $ks_option         = 'ks'
        $url_option        = 'url'
      }
      '22','23','24','25':{
        # Currently http://download.fedoraproject.org redirects to a mirror using a mirror to satisify installations.
        $fedora_url        = 'http://archives.fedoraproject.org/pub/archive/fedora/linux/releases'
        $fedora_flavor     = 'Server/'
        $_dot_bootsplash   = '.png'
        $vnc_option        = 'inst.vnc'
        $vnc_option_passwd = 'inst.vncpasswd'
        $ks_option         = 'inst.ks'
        $url_option        = 'url'
      }
      '26','27':{
        # Currently http://download.fedoraproject.org redirects to a mirror using a mirror to satisify installations.
        if $p_arch == 'i386' {
          $fedora_url = 'http://archives.fedoraproject.org/pub/archive/fedora-secondary/releases'
        }
        if $p_arch == 'x86_64' {
          $fedora_url = 'http://archives.fedoraproject.org/pub/archive/fedora/linux/releases'
        }
        $fedora_flavor     = 'Server/'
        $_dot_bootsplash   = '.png'
        $vnc_option        = 'inst.vnc'
        $vnc_option_passwd = 'inst.vncpasswd'
        $ks_option         = 'inst.ks'
        $url_option        = 'url'
      }
      '28','29','30':{
        if $p_arch == 'i386' {
          $fedora_url = 'http://download-ib01.fedoraproject.org/pub/fedora-secondary/releases'
        }
        if $p_arch == 'x86_64' {
          $fedora_url = 'http://download-ib01.fedoraproject.org/pub/fedora/linux/releases'
        }
        # Currently http://download.fedoraproject.org redirects to a mirror using a mirror to satisify installations.
        #$fedora_url = 'http://download.fedoraproject.org/fedora/linux/releases'
        #$fedora_url = 'http://mirrors.mit.edu/fedora/linux/releases'
        $fedora_flavor  = 'Server/'

        $_dot_bootsplash = '.png'
        $vnc_option        = 'inst.vnc'
        $vnc_option_passwd = 'inst.vncpasswd'
        $ks_option         = 'inst.ks'
        $url_option        = 'inst.repo'
      }
      default:{
        warning("${name} isn't a fedora release!")
      }
    }
    notice($fedora_url)
    notice($fedora_flavor)
    $autofile        = 'kickstart'
    $linux_installer = 'anaconda'
    $pxekernel       = 'vmlinuz'
    $initrd          = '.img'
    $src_initrd      = "initrd${initrd}"
    $target_kernel   = $rel_number
    $target_initrd   = "${rel_number}${initrd}"
    $url             = "${fedora_url}/${release}/${fedora_flavor}${p_arch}/os/images/pxeboot"
    $inst_repo       = "${fedora_url}/${release}/${fedora_flavor}${p_arch}/os"
    $update_repo     = "${fedora_url}/${release}/${fedora_flavor}${p_arch}/os"
    $boot_iso_url    = "${fedora_url}/${release}/${fedora_flavor}${p_arch}/os/images/boot.iso"
    $boot_iso_name   = 'boot.iso'
    $mini_iso_name   = 'boot.iso'
    $splash_url      = "${fedora_url}/isolinux/splash${_dot_bootsplash}"
    $logo_url        = 'https://getfedora.org/static/images/fedora_infinity_140x140.png'
    $unzip_iso       = false
    $rel_name        = $name
  }
  if ( $distro == 'scientificlinux'){
    case $release {
      '4.0','4.1','4.2','4.3','4.4','4.5','4.6','4.7','4.8','4.9':{
        $scientificlinux_url = "http://ftp.scientificlinux.org/linux/scientific/obsolete/${rel_number}/${p_arch}"
        $_dot_bootsplash     = '.lss'
        $vnc_option          = 'vnc'
        $vnc_option_passwd   = 'vncpasswd'
        $ks_option           = 'ks'
        $url_option          = 'url'
        $url                 = "${scientificlinux_url}/images/SL/pxeboot"
      }
      '5.0','5.1','5.2','5.3','5.4','5.5','5.6','5.7','5.8','5.9','5.10','5.11':{
        $scientificlinux_url = "http://ftp.scientificlinux.org/linux/scientific/obsolete/${rel_number}/${p_arch}"
        $_dot_bootsplash     = '.lss'
        $vnc_option          = 'vnc'
        $vnc_option_passwd   = 'vncpasswd'
        $ks_option           = 'ks'
        $url_option          = 'url'
        $url                 = "${scientificlinux_url}/images/pxeboot"
      }
      '6.0','6.1','6.2','6.3','6.4','6.5','6.6','6.7','6.8','6.9':{
        $scientificlinux_url = "http://ftp.scientificlinux.org/linux/scientific/${release}/${p_arch}/os"
        $_dot_bootsplash     = '.jpg'
        $vnc_option          = 'vnc'
        $vnc_option_passwd   = 'vncpasswd'
        $ks_option           = 'ks'
        $url_option          = 'url'
        $url                 = "${scientificlinux_url}/images/pxeboot"
      }
      '7.0','7.1','7.2','7.3','7.4','7.5','7.6':{
        $scientificlinux_url = "http://ftp.scientificlinux.org/linux/scientific/${release}/${p_arch}/os"
        $_dot_bootsplash     = '.png'
        $vnc_option          = 'inst.vnc'
        $vnc_option_passwd   = 'inst.vncpasswd'
        $ks_option           = 'inst.ks'
        $url_option          = 'url'
        $url                 = "${scientificlinux_url}/images/pxeboot"
      }
      default:{
        warning("${name} isn't a scientificlinux release!")
      }
    }
    notice($scientificlinux_url)
    $autofile        = 'kickstart'
    $linux_installer = 'anaconda'
    $pxekernel       = 'vmlinuz'
    $initrd          = '.img'
    $src_initrd      = "initrd${initrd}"
    $target_kernel   = $rel_number
    $target_initrd   = "${rel_number}${initrd}"
    #$url             = "${scientificlinux_url}/images/pxeboot"
    $inst_repo       = "http://ftp.scientificlinux.org/linux/scientific/${release}/${p_arch}/os"
    $update_repo     = "http://ftp.scientificlinux.org/linux/scientific/${release}/${p_arch}/updates/security"
    $splash_url       = "${scientificlinux_url}/isolinux/splash${_dot_bootsplash}"
    $logo_url        = 'http://ftp.scientificlinux.org/sl-banner.png'
    $boot_iso_url    = "${scientificlinux_url}/images/${boot_iso_name}"
    $boot_iso_name   = 'boot.iso'
    $mini_iso_name   = 'boot.iso'
    $unzip_iso       = false
    $rel_name        = $name
  }

  if ( $distro == 'opensuse') {
    case $release {
      '10.2','10.3','11.0','11.1','11.2','11.3','11.4','12.1','12.2','12.3','13.1','13.2','13.3':{
        warning("OpenSUSE ${release} for ${p_arch} a discontinued distribution downloaded from ${url}")
        $opensuse_url = 'http://ftp5.gwdg.de/pub/opensuse/discontinued/distribution'
      }
      'tumbleweed':{
        warning("OpenSUSE ${release} rolling upgrades")
        $opensuse_url = 'http://download.opensuse.org'
      }
      '42.2','42.3','15.0','15.1':{
        warning("OpenSUSE ${release} LEAP")
        $opensuse_url = 'http://download.opensuse.org/distribution/leap'
      }
      default:{
        warning("${name} isn't a openSuSE release!")
      }
    }
    notice($opensuse_url)
    $autofile        = 'autoyast'
    $linux_installer = 'yast'
    $pxekernel       = 'linux'
    $initrd          = undef
    $src_initrd      = "initrd${initrd}"
    $target_kernel   = $rel_number
    $target_initrd   = "${rel_number}.gz"
    $_dot_bootsplash      = '.jpg'
    $url             = "${opensuse_url}/${release}/repo/oss/boot/${p_arch}/loader"
    $inst_repo       = "${opensuse_url}/${release}/repo/oss"
    $update_repo     = "${opensuse_url}/${release}/repo/non-oss/suse"
    $splash_url      = "${opensuse_url}/${release}/repo/oss/boot/${p_arch}/loader/back.jpg"
    $logo_url        = 'https://www.opensuse.org/build/images/opensuse-logo.png'
    $boot_iso_url    = "${opensuse_url}/${release}/iso"
    $boot_iso_name   = "openSUSE-${release}-net-${p_arch}.iso"
    $mini_iso_name   = undef
    $unzip_iso       = false
    $rel_name        = $name

    # This adds scripts to deploy to the system after booting into OpenSuse
    # when finished it should reboot.
    file {"/srv/quartermaster/${distro}/${autofile}/kernelbuilder.${name}.${autofile}":
      ensure  => file,
      mode    => '0777',
      content => template('quartermaster/kernelbuilder/autoyast.erb'),
    }
  }
  if ($distro == /(centos|fedora|oraclelinux)/) and ( $release >= '7.0' ) and ( $p_arch == 'i386'){
    fail("${distro} ${release} does not provide support for processor architecture i386")
  }

  if ( $distro == 'openbsd' ) {
    case $release {
      '6.4','6.5':{
        $boot_iso_name = "install${rel_number}.iso"
        $boot_iso_url    = "https://cdn.openbsd.org/pub/OpenBSD/${release}/${p_arch}/${boot_iso_name}"
        $mini_iso_name = "cd${rel_number}.iso"
        $vnc_option        = undef
        $vnc_option_passwd = undef
        $ks_option         = undef
        $url_option        = undef
      }
      default:{
        warning("${name} isn't currently supprted by this technology!")
      }
    }
    $autofile        = 'install.conf'
    $linux_installer = 'openbsd'
    $pxekernel       = 'pxeboot'
    $initrd          = 'bsd.rd'
    $src_initrd      = "bsd.rd"
    $target_kernel   = 'pxeboot.0'
    $target_initrd   = 'bsd'
    $_dot_bootsplash = '.png'
    $url             = 'ISO Required instead of URL'
    $inst_repo       = "http://cdn.openbsd.org/pub/OpenBSD/${release}/${p_arch}"
    $update_repo     = "http://cdn.openbsd.org/pub/OpenBSD/${release}/${p_arch}"
    $splash_url      = "https://www.openbsd.org/images/banner1.gif"
    $logo_url        = 'https://www.openbsd.org/art/puffy/ppuf100X91.gif'
    $unzip_iso       = false
    $rel_name        = $name
  }

  if ( $distro == 'xcpng' ) {
    case $release {
      '7.4','7.4.1':{
        $boot_iso_name = "xcp-ng-${release}.iso"
        $boot_iso_url    = "https://xcp-ng.org/${release}/${boot_iso_name}"
        $mini_iso_name     = undef
        $vnc_option        = 'vnc'
        $vnc_option_passwd = 'vncpasswd'
        $ks_option         = 'ks'
        $url_option        = 'url'
      }
      '7.5','7.6':{
        $boot_iso_name = "xcp-ng-${release}-netinstall.iso"
        $boot_iso_url    = "https://xcp-ng.org/${release}/${boot_iso_name}"
        $mini_iso_name = "xcp-ng-${release}-netinstall.iso"
        $vnc_option        = 'vnc'
        $vnc_option_passwd = 'vncpasswd'
        $ks_option         = 'ks'
        $url_option        = 'url'
      }
      default:{
        warning("${name} isn't a XCP-NG release!")
      }
    }
    $autofile        = 'kickstart'
    $linux_installer = 'anaconda'
    $pxekernel       = 'vmlinuz'
    $initrd          = '.img'
    $src_initrd      = "initrd${initrd}"
    $target_kernel   = $rel_number
    $target_initrd   = "${rel_number}${initrd}"
    $_dot_bootsplash = '.png'
    $url             = 'ISO Required instead of URL'
    $inst_repo       = "http://updates.xcp-ng.org/${rel_major}/${release}/base/${p_arch}"
    $update_repo     = "http://updates.xcp-ng.org/${rel_major}/${release}/updates/${p_arch}"
    $splash_url      = "http://updates.xcp-ng.org/${rel_major}/${release}/base/${p_arch}"
    $logo_url        = 'https://xcp-ng.org/assets/img/smalllogo.png'
    $unzip_iso       = false
    $rel_name        = $name
  }
  # Begin tests for dealing with OracleLinux Repos
  if ( $distro == 'oraclelinux' ) {
    case $release {
      '4.4','4.5','4.6','4.7','4.8':{
        warning("There are currently no ${p_arch}-boot.iso on mirror so switching to Server ISO for ${name}")
        $boot_iso_name = "Enterprise-R${rel_major}-U${rel_minor}-${p_arch}-dvd.iso"
        $boot_iso_url    = "http://mirrors.kernel.org/oracle/EL${rel_major}/U${rel_minor}/${p_arch}/${boot_iso_name}"
        $mini_iso_name     = undef
        $vnc_option        = 'vnc'
        $vnc_option_passwd = 'vncpasswd'
        $ks_option         = 'ks'
        $url_option        = 'url'

      }
      '5.0':{
        warning("There are currently no ${p_arch}-boot.iso on mirror so switching to Server ISO for ${name}")
        $boot_iso_name = "Enterprise-R${rel_major}-GA-Server-${p_arch}-dvd.iso"
        $boot_iso_url    = "http://mirrors.kernel.org/oracle/EL${rel_major}/GA/${p_arch}/${boot_iso_name}"
        $mini_iso_name     = undef
        $vnc_option        = 'vnc'
        $vnc_option_passwd = 'vncpasswd'
        $ks_option         = 'ks'
        $url_option        = 'url'
      }

      '5.1','5.2','5.3','5.4','5.5','5.6','5.7','5.8','5.9','5.10','5.11':{
        warning("There are currently no ${p_arch}-boot.iso on mirror so switching to Server ISO for ${name}")
        $boot_iso_name = "Enterprise-R${rel_major}-U${rel_minor}-Server-${p_arch}-dvd.iso"
        $boot_iso_url    = "http://mirrors.kernel.org/oracle/EL${rel_major}/U${rel_minor}/${p_arch}/${boot_iso_name}"
        $mini_iso_name     = undef
        $vnc_option        = 'vnc'
        $vnc_option_passwd = 'vncpasswd'
        $ks_option         = 'ks'
        $url_option        = 'url'
      }

      '6.0':{
        warning("There are currently no ${p_arch}-boot.iso on mirror so switching to Server ISO for ${name}")
        $boot_iso_name = "OracleLinux-R${rel_major}-U${rel_minor}-Server-${p_arch}-dvd.iso"
        $boot_iso_url    = "http://mirrors.kernel.org/oracle/OL${rel_major}/GA/${p_arch}/${boot_iso_name}"
        $mini_iso_name     = undef
        $vnc_option        = 'vnc'
        $vnc_option_passwd = 'vncpasswd'
        $ks_option         = 'ks'
        $url_option        = 'url'
      }

      '6.1','6.2','6.3','6.4','6.5','6.6','6.7','6.8','6.9':{
        warning("There are currently no ${p_arch}-boot.iso on mirror so switching to Server ISO for ${name}")
        $boot_iso_name     = "OracleLinux-R${rel_major}-U${rel_minor}-Server-${p_arch}-dvd.iso"
        $boot_iso_url      = "http://mirrors.kernel.org/oracle/OL${rel_major}/U${rel_minor}/${p_arch}/${boot_iso_name}"
        $mini_iso_name     = "${p_arch}-boot.iso"
        $vnc_option        = 'vnc'
        $vnc_option_passwd = 'vncpasswd'
        $ks_option         = 'ks'
        $url_option        = 'url'
      }

      '7.0':{
        warning("There are currently no ${p_arch}-boot.iso on mirror so switching to Server ISO for ${name}")
        $boot_iso_name = "OracleLinux-R${rel_major}-U${rel_minor}-Server-${p_arch}-dvd.iso"
        $boot_iso_url    = "http://mirrors.kernel.org/oracle/OL${rel_major}/u${rel_minor}/${p_arch}/${boot_iso_name}"
        $mini_iso_name     = "${p_arch}-boot.iso"
        $vnc_option        = 'inst.vnc'
        $vnc_option_passwd = 'inst.vncpasswd'
        $ks_option         = 'inst.ks'
        $url_option        = 'inst.repo'
      }

      '7.1','7.2','7.3','7.4':{
        warning("There are currently no ${p_arch}-boot.iso on mirror so switching to Server ISO for ${name}")
        $boot_iso_name     = "OracleLinux-R${rel_major}-U${rel_minor}-Server-${p_arch}-dvd.iso"
        $boot_iso_url      = "http://mirrors.kernel.org/oracle/OL${rel_major}/u${rel_minor}/${p_arch}/${boot_iso_name}"
        $mini_iso_name     = undef
        $vnc_option        = 'inst.vnc'
        $vnc_option_passwd = 'inst.vncpasswd'
        $ks_option         = 'inst.ks'
        $url_option        = 'inst.repo'
      }

      '7.5','7.6','8.0':{
        warning("There are currently no ${p_arch}-boot.iso on mirror so switching to Server ISO for ${name}")
        $boot_iso_name     = "OracleLinux-R${rel_major}-U${rel_minor}-Server-${p_arch}-dvd.iso"
        $boot_iso_url      = "http://mirrors.kernel.org/oracle/OL${rel_major}/u${rel_minor}/${p_arch}/${boot_iso_name}"
        $mini_iso_name     = "${p_arch}-boot.iso"
        $vnc_option        = 'inst.vnc'
        $vnc_option_passwd = 'inst.vncpasswd'
        $ks_option         = 'inst.ks'
        $url_option        = 'inst.repo'
      }
      default:{
        warning("${name} isn't a oraclelinux release!")
      }
    }
    $autofile        = 'kickstart'
    $linux_installer = 'anaconda'
    $pxekernel       = 'vmlinuz'
    $initrd          = '.img'
    $src_initrd      = "initrd${initrd}"
    $target_kernel   = $rel_number
    $target_initrd   = "${rel_number}${initrd}"
    $_dot_bootsplash = '.png'
    $url             = 'ISO Required instead of URL'
    $inst_repo       = "http://${::fqdn}/${distro}/mnt/${boot_iso_name}"
    $update_repo     = "http://public-yum.oracle.com/repo/oracle/OracleLinux/OL${rel_major}/${rel_minor}/base/${p_arch}"
    $splash_url      = "http://mirrors.kernel.org/oracle/OL${rel_major}/${rel_minor}/base/${p_arch}"
    $logo_url        = 'http://public-yum.oracle.com/layout/i/Linux_Logo.jpg'
    $unzip_iso       = false
    $rel_name        = $name
  }
  if ( $distro == 'redhat' ) {
    $autofile        = 'kickstart'
    $linux_installer = 'anaconda'
    $pxekernel       = 'vmlinuz'
    $initrd          = '.img'
    $src_initrd      = "initrd${initrd}"
    $target_kernel   = $rel_number
    $target_initrd   = "${rel_number}${initrd}"
    $_dot_bootsplash = '.jpg'
    $url             = 'ISO Required instead of URL'
    $inst_repo       = 'Install ISO Required'
    $update_repo     = 'Update ISO or Mirror Required'
    $splash_url      = 'ISO Required for Splash'
    $logo_url        = 'https://www.redhat.com/profiles/rh/themes/redhatdotcom/img/logo.svg'
    $boot_iso_url    = 'No mini.iso or boot.iso to download'
    $boot_iso_name   = 'Not Required'
    $ks_option       = 'ks'
    $url_option      = 'url'
    $unzip_iso       = false
    $rel_name        = $name
  }
  if ( $distro == 'sles' ) {
    $autofile        = 'autoyast'
    $linux_installer = 'yast'
    $pxekernel       = 'linux'
    $initrd          = undef
    $src_initrd      = "initrd${initrd}"
    $target_kernel   = $rel_number
    $target_initrd   = "${rel_number}.gz"
    $_dot_bootsplash = '.jpg'
    $url             = 'ISO Required instead of URL'
    $inst_repo       = 'Install ISO Required'
    $update_repo     = 'Update ISO or Mirror Required'
    $splash_url      = 'ISO Required for Splash'
    $logo_url        = 'https://www.suse.com/assets/img/fn-suse-ico.png'
    $boot_iso_url    = 'No mini.iso or boot.iso to download'
    $boot_iso_name   = 'Not Required'
    $unzip_iso       = false
    $rel_name        = $name
  }
  if ( $distro == 'sled' ) {
    $autofile        = 'autoyast'
    $linux_installer = 'yast'
    $pxekernel       = 'linux'
    $initrd          = undef
    $src_initrd      = "initrd${initrd}"
    $target_kernel   = $rel_number
    $target_initrd   = "${rel_number}.gz"
    $_dot_bootsplash = '.jpg'
    $url             = 'ISO Required instead of URL'
    $inst_repo       = 'Install ISO Required'
    $update_repo     = 'Update ISO or Mirror Required'
    $splash_url       = 'ISO Required for Splash'
    $logo_url        = 'https://www.suse.com/assets/img/fn-suse-ico.png'
    $boot_iso_url    = 'No mini.iso or boot.iso to download'
    $boot_iso_name   = 'Not Required'
    $mini_iso_name   = 'Not Required'
    $unzip_iso       = false
    $rel_name        = $name
  }
  if ( $distro == 'windows' ) {
    $autofile = 'unattend.xml'
  }


  if ( $distro == 'ubuntu' ) {
    $rel_name = $release ? {
      /(11.04)/     => 'natty',
      /(11.10)/     => 'oneric',
      /(12.04)/     => 'precise',
      /(12.10)/     => 'quantal',
      /(13.04)/     => 'raring',
      /(13.10)/     => 'saucy',
      /(14.04)/     => 'trusty',
      /(14.10)/     => 'utopic',
      /(15.04)/     => 'vivid',
      /(15.10)/     => 'wily',
      /(16.04)/     => 'xenial',
      /(16.10)/     => 'yakkety',
      /(17.04)/     => 'zesty',
      /(17.10)/     => 'artful',
      /(18.04)/     => 'bionic',
      /(18.10)/     => 'cosmic',
      default       => "${name} is not an Ubuntu release",
    }
    case $release {
      '12.04','14,04','15.04','16.04','18.04','18.10':{
        warning("Ubuntu ${release} is an active release")
      }
      default:{
        warning("${name} isn't an active ubuntu release!")
      }
    }
    $autofile        = 'preseed'
    $linux_installer = 'd-i'
    $pxekernel       = 'linux'
    $initrd          = '.gz'
    $src_initrd      = "initrd${initrd}"
    $target_kernel   = $rel_number
    $target_initrd   = "${rel_number}${initrd}"
    $_dot_bootsplash = '.png'
    $mirror_host     = 'mirrors.kernel.org'
    $mirror_path     = $distro
    $url             = "http://archive.ubuntu.com/${distro}/dists/${rel_name}/main/installer-${p_arch}/current/images/netboot/${distro}-installer/${p_arch}"
    $inst_repo       = "http://archive.ubuntu.com/${distro}/dists/${rel_name}"
    $update_repo     = "http://archive.ubuntu.com/${distro}/dists/${rel_name}"
    $splash_url      = "http://archive.ubuntu.com/${distro}/dists/${rel_name}/main/installer-${p_arch}/current/images/netboot/${distro}-installer/${p_arch}/boot-screens/splash${_dot_bootsplash}"
    $logo_url        = 'https://assets.ubuntu.com/v1/8aff3fa9-ubuntu-logo41.png'
    $boot_iso_url    = 'No mini.iso or boot.iso to download'
    $boot_iso_name   = 'Not Required'
    $mini_iso_name   = 'mini.iso'
    $unzip_iso       = false
  }
  if ( $distro == 'devuan' ) {
    $rel_name = $release ? {
      /(1.0)/   => 'jessie',
      /(2.0)/   => 'ascii',
      /(3.0)/   => 'beowulf',
      default   => "${name} is not an Devuan release",
    }
    case $release {
      '1.0','2.0':{
        $devuan_url  = 'http://pkgmaster.devuan.org'
        $mirror_host = 'pkgmaster.devuan.org'
        $mirror_path = $distro
      }
      default:{
        warning("${name} isn't a devuan release!")
      }
    }
    $autofile        = 'preseed'
    $linux_installer = 'd-i'
    $pxekernel       = 'linux'
    $initrd          = '.gz'
    $src_initrd      = "initrd${initrd}"
    $target_kernel   = $rel_number
    $target_initrd   = "${rel_number}${initrd}"
    $_dot_bootsplash = '.png'
    $url             = "${devuan_url}/${distro}/dists/${rel_name}/main/installer-${p_arch}/current/images/netboot/debian-installer/${p_arch}"
    $inst_repo       = "${devuan_url}/${distro}/dists/${rel_name}"
    $update_repo     = "${devuan_url}/${distro}/dists/${rel_name}"
    $splash_url      = "${devuan_url}/${distro}/dists/${rel_name}/main/installer-${p_arch}/current/images/netboot/debian-installer/${p_arch}/boot-screens/splash${_dot_bootsplash}"
    $logo_url        = 'https://devuan.org/ui/img/devuan-logo-purpy.png'
    $boot_iso_url    = 'No mini.iso or boot.iso to download'
    $boot_iso_name   = 'Not Required'
    $mini_iso_name   = 'Not Required'
    $unzip_iso       = false
  }
  if ( $distro == 'debian' ) {
    $rel_name = $release ? {
      /(2.0)/ => 'hamm',
      /(2.1)/ => 'slink',
      /(2.2)/ => 'potato',
      /(3)/   => 'woody',
      /(3.1)/ => 'sarge',
      /(4)/   => 'etch',
      /(5)/   => 'lenny',
      /(6)/   => 'squeeze',
      /(7)/   => 'wheezy',
      /(8)/   => 'jessie',
      /(9)/   => 'stretch',
      /(10)/  => 'buster',
      /(11)/  => 'bullseye',
      default => "${name} is not an Debian release",
    }
    case $release {
      '2.0','2.1','2.2','3','3.1','4':{
        warning("${name} is not currently a pxeable debian release!")
      }
      '5','6':{
        $debian_url = 'http://archive.debian.org'
        $mirror_host = 'archive.debian.org'
        $mirror_path = $distro

      }
      '7','8','9','10':{
        $debian_url = 'http://http.us.debian.org'
        $mirror_host = 'http.us.debian.org'
        $mirror_path = $distro
      }
      default:{
        warning("${name} isn't a debian release!")
      }
    }
    $autofile        = 'preseed'
    $linux_installer = 'd-i'
    $pxekernel       = 'linux'
    $initrd          = '.gz'
    $src_initrd      = "initrd${initrd}"
    $target_kernel   = $rel_number
    $target_initrd   = "${rel_number}${initrd}"
    $_dot_bootsplash = '.png'
    $url             = "${debian_url}/${distro}/dists/${rel_name}/main/installer-${p_arch}/current/images/netboot/${distro}-installer/${p_arch}"
    $inst_repo       = "${debian_url}/${distro}/dists/${rel_name}"
    $update_repo     = "${debian_url}/${distro}/dists/${rel_name}"
    $splash_url      = "${debian_url}/${distro}/dists/${rel_name}/main/installer-${p_arch}/current/images/netboot/${distro}-installer/${p_arch}/boot-screens/splash${_dot_bootsplash}"
    $logo_url        = 'https://www.debian.org/Pics/openlogo-50.png'
    $boot_iso_url    = 'No mini.iso or boot.iso to download'
    $boot_iso_name   = 'Not Required'
    $mini_iso_name   = 'Not Required'
    $unzip_iso       = false
  }
  if ( $distro == 'kali' ) {
    $autofile        = 'preseed'
    $linux_installer = 'd-i'
    $pxekernel       = 'linux'
    $initrd          = '.gz'
    $src_initrd      = "initrd${initrd}"
    $target_kernel   = $rel_number
    $target_initrd   = "${rel_number}${initrd}"
    $_dot_bootsplash = '.png'
    $mirror_host     = 'http.kali.org'
    $mirror_path     = $distro
    $url             = "http://http.kali.org/kali/dists/kali-rolling/main/installer-${p_arch}/current/images/netboot/debian-installer/${p_arch}"
    $inst_repo       = 'http://http.kali.org/kali/dists/kali-rolling'
    $update_repo     = 'http://http.kali.org/kali/dists/kali-rolling'
    $splash_url      = "http://http.kali.org/kali/dists/kali-rolling/main/installer-${p_arch}/current/images/netboot/debian-installer/${p_arch}/boot-screens/splash${_dot_bootsplash}"
    $logo_url        = 'https://www.kali.org/wp-content/uploads/2015/09/kali-2.0-website-logo-300x90.png'
    $boot_iso_url    = 'No mini.iso or boot.iso to download'
    $boot_iso_name   = 'Not Required'
    $mini_iso_name   = 'Not Required'
    $unzip_iso       = false
  }
  if ( $distro == 'archlinux' ){
    case $release {
      /^((((19|20)(([02468][048])|([13579][26])).02.29))|((20[0-9][0-9])|(19[0-9][0-9])).((((0[1-9])|(1[0-2])).((0[1-9])|(1[0-9])|(2[0-8])))|((((0[13578])|(1[02])).31)|(((0[1,3-9])|(1[0-2])).(29|30)))))$/,'latest':{
#     '2016.12.01','2017.01.01','2017.02.01','latest':{
        warning("Archlinux ${release} for ${p_arch} will be activated")
      }
      default:{
        fail("${name} is not a valid Archlinux release! Try using 2016.12.01,2017.01.01,2017.02.01, or latest for your release vs. ${release} which you are curenntly using.")
      }
    }
    $autofile        = 'kickstart'
    $linux_installer = 'archiso'
    $pxekernel       = 'vmlinuz'
    $initrd          = '.img'
    $src_initrd      = "archiso${initrd}"
    $target_kernel   = $rel_number
    $target_initrd   = "${rel_number}${initrd}"
    $_dot_bootsplash = '.png'
    $url             = "http://archive.archlinux.org/iso/${release}/arch/boot/${p_arch}"
    $inst_repo       = "http://archive.archlinux.org/iso/${release}/arch/boot/initramfs_${p_arch}.${initrd}"
    $update_repo     = "http://mirrors.kernel.org/archlinux/core/os/${p_arch}/${rel_name}/arch/${p_arch}/airootfs.sfs"
    $splash_url      = "http://mirrors.kernel.org/archlinux/iso/${rel_name}/arch/${p_arch}/airootfs.sfs"
    $logo_url        = 'https://www.archlinux.org/static/logos/archlinux-logo-dark-1200dpi.b42bd35d5916.png'
    $boot_iso_url    = "http://mirrors.kernel.org/archlinux/iso/${rel_name}/archlinux-${rel_name}-dual.iso"
    $boot_iso_name   = 'Not Required'
    $mini_iso_name   = 'Not Required'
    $unzip_iso       = false
    $rel_name        = $name
  }
  if ( $distro == 'flatcar' ) {
    case $release {
      'stable':{
        warning("flatcar ${release} for ${p_arch} will be activated")
        $flatcar_version = '1800.7.0'
      }
      'beta':{
        warning("flatcar ${release} for ${p_arch} will be activated")
        $flatcar_version = '1855.3.0'
      }
      'alpha':{
        warning("flatcar ${release} for ${p_arch} will be activated")
        $flatcar_version = '1883.0.0'
      }
      default:{
        fail("${name} is not a valid flatcar release! Valid release are stable, beta  or alpha.")
      }
    }
    case $p_arch {
      'amd64','arm64':{
        warning("flatcar ${release} for ${p_arch} will be activated")
      }
      default:{
        fail("${p_arch} is not a valid processor architecture for flatcar, valid processor arch are amd64 and arm64.")
      }
    }
    $flatcar_channel  = $release
    $autofile        = 'cloud-config.yml'
    $linux_installer = 'container-linux-install'
    $pxekernel      = 'flatcar_production_pxe.vmlinuz'
    $initrd          = 'cpio.gz'
    $src_initrd      = "flatcar_production_pxe_image.${initrd}"
    $target_kernel   = "${release}_production.vmlinuz"
    $target_initrd   = "${release}_production.${initrd}"
    $url             = "https://${release}.release.flatcar-linux.net/${p_arch}-usr/${flatcar_version}"
    $inst_repo       = "https://${release}.release.flatcar-linux.net/${p_arch}-usr/${flatcar_version}"
    $boot_iso_url    = "https://${release}.release.flatcar-linux.net/${p_arch}-usr/${flatcar_version}/flatcar_production_iso_image.iso"
    $splash_url      = 'https://www.flatcar-linux.org/media/brand-logo.svg'
    $logo_url        = 'https://www.flatcar-linux.org/media/brand-logo.svg'
    $boot_iso_name   = 'Not Required'
    $mini_iso_name   = 'Not Required'
    $unzip_iso       = false
    $rel_name        = $name

    # This adds scripts to deploy to the system after booting into flatcar
    # when finished it should reboot.
    file {"/srv/quartermaster/${distro}/${autofile}/${name}.pxe_installer.sh":
      ensure  => file,
      mode    => '0777',
      content => template('quartermaster/scripts/pxe_installer.sh.erb'),
    }
    file {"/srv/quartermaster/${distro}/${autofile}/${name}.running_instance.sh":
      ensure  => file,
      mode    => '0777',
      content => template('quartermaster/scripts/running_instance.sh.erb'),
    }
    file {"/srv/quartermaster/${distro}/${autofile}/${name}.custom_ip_resolution.sh":
      ensure  => file,
      mode    => '0777',
      content => template('quartermaster/scripts/custom_ip_resolution.sh.erb'),
    }
  }

  if ( $distro == 'coreos' ) {
    case $release {
      'stable':{
        warning("coreos ${release} for ${p_arch} will be activated")
        $coreos_version = '1520.8.0'
      }
      'beta':{
        warning("coreos ${release} for ${p_arch} will be activated")
        $coreos_version = '1576.2.0'
      }
      'alpha':{
        warning("coreos ${release} for ${p_arch} will be activated")
        $coreos_version = '1590.0.0'
      }
      default:{
        fail("${name} is not a valid coreos release! Valid release are stable, beta  or alpha.")
      }
    }
    case $p_arch {
      'amd64','arm64':{
        warning("coreos ${release} for ${p_arch} will be activated")
      }
      default:{
        fail("${p_arch} is not a valid processor architecture for coreos, valid processor arch are amd64 and arm64.")
      }
    }
    $coreos_channel  = $release
    $autofile        = 'cloud-config.yml'
    $linux_installer = 'container-linux-install'
    $pxekernel      = 'coreos_production_pxe.vmlinuz'
    $initrd          = 'cpio.gz'
    $src_initrd      = "coreos_production_pxe_image.${initrd}"
    $target_kernel   = "${release}_production.vmlinuz"
    $target_initrd   = "${release}_production.${initrd}"
    $url             = "https://${release}.release.core-os.net/${p_arch}-usr/current"
    $inst_repo       = "https://${release}.release.core-os.net/${p_arch}-usr/current"
    $boot_iso_url    = "https://${release}.release.core-os.net/${p_arch}-usr/current/coreos_production_iso_image.iso"
    $boot_iso_name   = 'Not Required'
    $mini_iso_name   = 'Not Required'
    $unzip_iso       = false
    $splash_url      = 'https://coreos.com/assets/images/brand/coreos-wordmark-horiz-color-reverse.svg'
    $logo_url        = 'https://coreos.com/assets/images/brand/coreos-wordmark-horiz-color-reverse.svg'
    $rel_name        = $name

    # This adds scripts to deploy to the system after booting into coreos 
    # when finished it should reboot.
    file {"/srv/quartermaster/${distro}/${autofile}/${name}.pxe_installer.sh":
      ensure  => file,
      mode    => '0777',
      content => template('quartermaster/scripts/pxe_installer.sh.erb'),
    }
    file {"/srv/quartermaster/${distro}/${autofile}/${name}.running_instance.sh":
      ensure  => file,
      mode    => '0777',
      content => template('quartermaster/scripts/running_instance.sh.erb'),
    }
    file {"/srv/quartermaster/${distro}/${autofile}/${name}.custom_ip_resolution.sh":
      ensure  => file,
      mode    => '0777',
      content => template('quartermaster/scripts/custom_ip_resolution.sh.erb'),
    }
    if ( $quartermaster::matchbox_enable ) {
      notice("matchbox/groups/${release}-install.json")
      exec{"matchbox_get-coreos_${coreos_channel}-${coreos_version}":
        command   => "/usr/local/bin/get-coreos ${coreos_channel} ${coreos_version} /var/lib/matchbox/assets",
        logoutput => true,
        timeout   => 0,
        user      => 'root',
        creates   => [
        "/var/lib/matchbox/assets/coreos/${coreos_version}",
        "/var/lib/matchbox/assets/coreos/${coreos_version}/CoreOS_Image_Signing_Key.asc",
        "/var/lib/matchbox/assets/coreos/${coreos_version}/coreos_production_image.bin.bz2",
        "/var/lib/matchbox/assets/coreos/${coreos_version}/coreos_production_image.bin.bz2.sig",
        "/var/lib/matchbox/assets/coreos/${coreos_version}/coreos_production_pxe_image.cpio.gz",
        "/var/lib/matchbox/assets/coreos/${coreos_version}/coreos_production_pxe_image.cpio.gz.sig",
        "/var/lib/matchbox/assets/coreos/${coreos_version}/coreos_production_pxe.vmlinuz",
        "/var/lib/matchbox/assets/coreos/${coreos_version}/coreos_production_pxe.vmlinuz.sig",
        ],
        require   => File['/var/lib/matchbox/assets'],
      }
      # Begin Examples
      file{[
        "/var/lib/matchbox/examples/${coreos_version}",
        "/var/lib/matchbox/examples/${coreos_version}/groups",
        "/var/lib/matchbox/examples/${coreos_version}/groups/simple",
        "/var/lib/matchbox/examples/${coreos_version}/groups/simple-install",
        "/var/lib/matchbox/examples/${coreos_version}/groups/etcd3",
        "/var/lib/matchbox/examples/${coreos_version}/groups/etcd3-install",
        "/var/lib/matchbox/examples/${coreos_version}/groups/grub",
        "/var/lib/matchbox/examples/${coreos_version}/groups/bootkube",
        "/var/lib/matchbox/examples/${coreos_version}/groups/bootkube-install",
        "/var/lib/matchbox/examples/${coreos_version}/profiles",
#        "/var/lib/matchbox/examples/${coreos_version}/ignition",
      ]:
        ensure => directory,
        owner  => 'matchbox',
        group  => 'matchbox',
      }
      file{ "/var/lib/matchbox/examples/${coreos_version}/ignition":
        ensure  => directory,
        owner   => 'matchbox',
        group   => 'matchbox',
        recurse => true,
        source  => 'puppet:///modules/quartermaster/coreos/matchbox/ignition',
      }
      file{ "/var/lib/matchbox/examples/${coreos_version}/groups/grub/default.json":
        ensure  => file,
        owner   => 'matchbox',
        group   => 'matchbox',
        content => template('quartermaster/matchbox/groups/grub/default.json.erb'),
      }
      file{ "/var/lib/matchbox/examples/${coreos_version}/groups/simple/default.json":
        ensure  => file,
        owner   => 'matchbox',
        group   => 'matchbox',
        content => template('quartermaster/matchbox/groups/simple/default.json.erb'),
      }
      file{ "/var/lib/matchbox/examples/${coreos_version}/groups/simple-install/simple.json":
        ensure  => file,
        owner   => 'matchbox',
        group   => 'matchbox',
        content => template('quartermaster/matchbox/groups/simple-install/simple.json.erb'),
      }
      file{ "/var/lib/matchbox/examples/${coreos_version}/groups/simple-install/install.json":
        ensure  => file,
        owner   => 'matchbox',
        group   => 'matchbox',
        content => template('quartermaster/matchbox/groups/simple-install/install.json.erb'),
      }
      file{ "/var/lib/matchbox/examples/${coreos_version}/groups/etcd3/gateway.json":
        ensure  => file,
        owner   => 'matchbox',
        group   => 'matchbox',
        content => template('quartermaster/matchbox/groups/etcd3/gateway.json.erb'),
      }
      file{ "/var/lib/matchbox/examples/${coreos_version}/groups/etcd3/node1.json":
        ensure  => file,
        owner   => 'matchbox',
        group   => 'matchbox',
        content => template('quartermaster/matchbox/groups/etcd3/node1.json.erb'),
      }
      file{ "/var/lib/matchbox/examples/${coreos_version}/groups/etcd3/node2.json":
        ensure  => file,
        owner   => 'matchbox',
        group   => 'matchbox',
        content => template('quartermaster/matchbox/groups/etcd3/node2.json.erb'),
      }
      file{ "/var/lib/matchbox/examples/${coreos_version}/groups/etcd3/node3.json":
        ensure  => file,
        owner   => 'matchbox',
        group   => 'matchbox',
        content => template('quartermaster/matchbox/groups/etcd3/node3.json.erb'),
      }
      file{ "/var/lib/matchbox/examples/${coreos_version}/groups/etcd3-install/gateway.json":
        ensure  => file,
        owner   => 'matchbox',
        group   => 'matchbox',
        content => template('quartermaster/matchbox/groups/etcd3-install/gateway.json.erb'),
      }
      file{ "/var/lib/matchbox/examples/${coreos_version}/groups/etcd3-install/node1.json":
        ensure  => file,
        owner   => 'matchbox',
        group   => 'matchbox',
        content => template('quartermaster/matchbox/groups/etcd3-install/node1.json.erb'),
      }
      file{ "/var/lib/matchbox/examples/${coreos_version}/groups/etcd3-install/node2.json":
        ensure  => file,
        owner   => 'matchbox',
        group   => 'matchbox',
        content => template('quartermaster/matchbox/groups/etcd3-install/node2.json.erb'),
      }
      file{ "/var/lib/matchbox/examples/${coreos_version}/groups/etcd3-install/node3.json":
        ensure  => file,
        owner   => 'matchbox',
        group   => 'matchbox',
        content => template('quartermaster/matchbox/groups/etcd3-install/node3.json.erb'),
      }
      file{ "/var/lib/matchbox/examples/${coreos_version}/groups/etcd3-install/install.json":
        ensure  => file,
        owner   => 'matchbox',
        group   => 'matchbox',
        content => template('quartermaster/matchbox/groups/etcd3-install/install.json.erb'),
      }
      file{ "/var/lib/matchbox/examples/${coreos_version}/groups/bootkube/node1.json":
        ensure  => file,
        owner   => 'matchbox',
        group   => 'matchbox',
        content => template('quartermaster/matchbox/groups/bootkube/node1.json.erb'),
      }
      file{ "/var/lib/matchbox/examples/${coreos_version}/groups/bootkube/node2.json":
        ensure  => file,
        owner   => 'matchbox',
        group   => 'matchbox',
        content => template('quartermaster/matchbox/groups/bootkube/node2.json.erb'),
      }
      file{ "/var/lib/matchbox/examples/${coreos_version}/groups/bootkube/node3.json":
        ensure  => file,
        owner   => 'matchbox',
        group   => 'matchbox',
        content => template('quartermaster/matchbox/groups/bootkube/node3.json.erb'),
      }
      file{ "/var/lib/matchbox/examples/${coreos_version}/groups/bootkube-install/node1.json":
        ensure  => file,
        owner   => 'matchbox',
        group   => 'matchbox',
        content => template('quartermaster/matchbox/groups/bootkube-install/node1.json.erb'),
      }
      file{ "/var/lib/matchbox/examples/${coreos_version}/groups/bootkube-install/node2.json":
        ensure  => file,
        owner   => 'matchbox',
        group   => 'matchbox',
        content => template('quartermaster/matchbox/groups/bootkube-install/node2.json.erb'),
      }
      file{ "/var/lib/matchbox/examples/${coreos_version}/groups/bootkube-install/node3.json":
        ensure  => file,
        owner   => 'matchbox',
        group   => 'matchbox',
        content => template('quartermaster/matchbox/groups/bootkube-install/node3.json.erb'),
      }
      file{ "/var/lib/matchbox/examples/${coreos_version}/groups/bootkube-install/install.json":
        ensure  => file,
        owner   => 'matchbox',
        group   => 'matchbox',
        content => template('quartermaster/matchbox/groups/bootkube-install/install.json.erb'),
      }
      file{ "/var/lib/matchbox/examples/${coreos_version}/profiles/simple.json":
        ensure  => file,
        owner   => 'matchbox',
        group   => 'matchbox',
        content => template('quartermaster/matchbox/profiles/simple.json.erb'),
      }
      file{ "/var/lib/matchbox/examples/${coreos_version}/profiles/simple-install.json":
        ensure  => file,
        owner   => 'matchbox',
        group   => 'matchbox',
        content => template('quartermaster/matchbox/profiles/simple-install.json.erb'),
      }
      file{ "/var/lib/matchbox/examples/${coreos_version}/profiles/grub.json":
        ensure  => file,
        owner   => 'matchbox',
        group   => 'matchbox',
        content => template('quartermaster/matchbox/profiles/grub.json.erb'),
      }
      file{ "/var/lib/matchbox/examples/${coreos_version}/profiles/etcd3.json":
        ensure  => file,
        owner   => 'matchbox',
        group   => 'matchbox',
        content => template('quartermaster/matchbox/profiles/etcd3.json.erb'),
      }
      file{ "/var/lib/matchbox/examples/${coreos_version}/profiles/etcd3-gateway.json":
        ensure  => file,
        owner   => 'matchbox',
        group   => 'matchbox',
        content => template('quartermaster/matchbox/profiles/etcd3-gateway.json.erb'),
      }
      file{ "/var/lib/matchbox/examples/${coreos_version}/profiles/bootkube-worker.json":
        ensure  => file,
        owner   => 'matchbox',
        group   => 'matchbox',
        content => template('quartermaster/matchbox/profiles/bootkube-worker.json.erb'),
      }
      file{ "/var/lib/matchbox/examples/${coreos_version}/profiles/bootkube-controller.json":
        ensure  => file,
        owner   => 'matchbox',
        group   => 'matchbox',
        content => template('quartermaster/matchbox/profiles/bootkube-controller.json.erb'),
      }
# Below is commented out until bits are properly cleaned up.
      # matchbox profiles grub.json
#
#      file{ "/var/lib/matchbox/groups/${release}-install.json":
#        ensure  => file,
#        owner   => 'matchbox',
#        group   => 'matchbox',
#        content => template('quartermaster/matchbox/groups.channel-install.json.erb'),
#      }
#      notice("matchbox/profiles/${release}-install.json")
#      file{ "/var/lib/matchbox/profiles/${release}-install.json":
#        ensure  => file,
#        owner   => 'matchbox',
#        group   => 'matchbox',
#        content => template('quartermaster/matchbox/profiles.channel-install.json.erb'),
#      }
#      notice("matchbox/groups/${release}.json")
#      file{ "/var/lib/matchbox/groups/${release}.json":
#        ensure  => file,
#        owner   => 'matchbox',
#        group   => 'matchbox',
#        content => template('quartermaster/matchbox/groups.channel.json.erb'),
#      }
      # matchbox groups etcd3-install.json
#      file{ "/var/lib/matchbox/groups/etcd3-${release}-install.json":
#        ensure  => file,
#        owner   => 'matchbox',
#        group   => 'matchbox',
#        content => template('quartermaster/matchbox/groups.etcd3-install.json.erb'),
#      }
      # Begin Examples
#      notice("matchbox/profiles/${release}.json")
#      file{ "/var/lib/matchbox/profiles/${release}.json":
#        ensure  => file,
#        owner   => 'matchbox',
#        group   => 'matchbox',
#        content => template('quartermaster/matchbox/profiles.channel.json.erb'),
#      }
      # matchbox profiles grub.json
#      file{ "/var/lib/matchbox/examples/${coreos_version}/profiles/grub-${release}.json":
#        ensure  => file,
#        owner   => 'matchbox',
#        group   => 'matchbox',
#        content => template('quartermaster/matchbox/profiles.grub.json.erb'),
#      }

      # matchbox profiles etcd3.json
#      file{ "/var/lib/matchbox/profiles/etcd3-${release}.json":
#        ensure  => file,
#        owner   => 'matchbox',
#        group   => 'matchbox',
#        content => template('quartermaster/matchbox/profiles.etcd3.json.erb'),
#      }

      # matchbox profiles etcd3-gateway.json
#      file{ "/var/lib/matchbox/profiles/etcd3-gateway-${release}.json":
#        ensure  => file,
#        owner   => 'matchbox',
#        group   => 'matchbox',
#        content => template('quartermaster/matchbox/profiles.etcd3-gateway.json.erb'),
#      }

      # profiles install-channel-reboot.json
#      file{ "/var/lib/matchbox/profiles/install-${release}-reboot.json":
#        ensure  => file,
#        owner   => 'matchbox',
#        group   => 'matchbox',
#        content => template('quartermaster/matchbox/profiles.install-channel-reboot.json.erb'),
#      }

    }
  }

  if ( $distro == 'rancheros' ) {
    case $release {
      /([0-9]).([0-9]).([0-9])/:{
        warning("rancheros ${release} for ${p_arch} will be activated")
        $rancheros_release = "v${release}"
        $src_initrd      = 'initrd'
      }
      'latest':{
        warning("rancheros ${release} for ${p_arch} will be activated")
        $rancheros_release = 'latest'
        $src_initrd      = 'initrd'
      }
      default:{
        fail("${name} is not a valid rancheros release! Valid release are stable, beta  or alpha.")
      }
    }
    case $p_arch {
      'amd64','arm64':{
        warning("rancher ${release} for ${p_arch} will be activated")
      }
      default:{
        fail("${p_arch} is not a valid processor architecture for coreos, valid processor arch are amd64 and arm64.")
      }
    }
    $autofile        = 'cloud-config.yml'
    $linux_installer = 'ros'
    $pxekernel       = 'vmlinuz'
    $initrd          = 'initrd'
    $target_kernel   = $rel_number
    $target_initrd   = "${rel_number}.img"
    $url             = "https://github.com/rancher/os/releases/download/${rancheros_release}"
    $inst_repo       = "https://github.com/rancher/os/releases/download/${rancheros_release}"
    $boot_iso_url    = "https://releases.rancher.com/os/${rancheros_release}/${boot_iso_name}"
    $boot_iso_name   = 'rancheros.iso'
    $mini_iso_name   = 'Not Required'
    $unzip_iso       = false
    $splash_url      = 'http://cdn.rancher.com/wp-content/uploads/2016/07/25205112/rancheros-logo-01.png'
    $logo_url        = 'http://cdn.rancher.com/wp-content/uploads/2016/07/25205112/rancheros-logo-01.png'
    $rel_name        = $name

    file {"/srv/quartermaster/${distro}/${autofile}/${name}.pxe_installer.sh":
      ensure  => file,
      mode    => '0777',
      content => template('quartermaster/scripts/pxe_installer.sh.erb'),
    }
    file {"/srv/quartermaster/${distro}/${autofile}/${name}.running_instance.sh":
      ensure  => file,
      mode    => '0777',
      content => template('quartermaster/scripts/running_instance.sh.erb'),
    }
    file {"/srv/quartermaster/${distro}/${autofile}/${name}.custom_ip_resolution.sh":
      ensure  => file,
      mode    => '0777',
      content => template('quartermaster/scripts/custom_ip_resolution.sh.erb'),
    }
  }
  if ( $distro == 'reactos' ) {
  # https://www.reactos.org/wiki/Building_PXE-ready_ReactOS#The_QEMU_way
    case $release {
      /([0-9]).([0-9]).([0-9])/:{
        warning("reactos ${release} for ${p_arch} will be activated")
      }
      default:{
        fail("${name} is not a valid ReactOS release!")
      }
    }
    case $p_arch {
      'amd64','i386':{
        warning("ReactOS ${release} for ${p_arch} will be activated")
      }
      default:{
        fail("${p_arch} is not a valid processor architecture for ReactOS, valid processor arch are amd64 and i386.")
      }
    }
    $autofile        = 'unattend.inf'
    $linux_installer = 'ReactOS'
    $pxekernel       = 'freeldr.sys'
    $src_initrd      = 'freeldr.ini'
    $target_kernel   =  undef
    $target_initrd   =  undef
    $url             = 'ISO Required instead of URL'
    $inst_repo       = "https://github.com/reactos/reactos/releases/download/${release}-release/"
    $boot_iso_url    = "https://github.com/reactos/reactos/releases/download/${release}-release/ReactOS-${release}-iso.zip"
    $boot_iso_name   = "ReactOS-${release}.iso"
    $archive_name    = "ReactOS-${release}-iso.zip"
    $mini_iso_name   = 'Not Required'
    $unzip_iso       = true
    $splash_url      = 'https://www.reactos.org/sites/default/files/ReactOS_0.png'
    $logo_url        = 'https://www.reactos.org/sites/default/files/ReactOS_0.png'
    $rel_name        = $name

    if ! defined (Tftp::File["${distro}/${p_arch}/${src_initrd}"]){
      tftp::file { "${distro}/${p_arch}/${src_initrd}":
        ensure  => file,
        content => template('quartermaster/reactos_freeldr.ini.erb'),
      }
    }
    if ! defined (Tftp::File["${distro}/${p_arch}/${pxekernel}"]){
      tftp::file { "${distro}/${p_arch}/${pxekernel}":
        ensure  => file,
        source  => "/srv/quartermaster/${distro}/mnt/${boot_iso_name}/loader/${pxekernel}",
        require => Archive["${name}-boot.iso.zip"],
      }
    }
    if ! defined (File["/srv/quartermaster/tftpboot/${distro}/${p_arch}/${release}"]) {
      file { "/srv/quartermaster/tftpboot/${distro}/${p_arch}/${release}":
        ensure  => link,
        target  => "/srv/quartermaster/${distro}/mnt/${boot_iso_name}",
        require => Archive["${name}-boot.iso.zip"],
      }
    }
  }

  $puppetlabs_repo = $distro ? {
    /(ubuntu|debian)/                                    => "http://apt.puppet.com/dists/${rel_name}",
# These are for puppet 3.x packages
#    /(redhat|centos|scientificlinux|oraclelinux)/        => "http://yum.puppet.com/el/${rel_major}/products/${p_arch}",
#    /(fedora)/                                           => "http://yum.puppet.com/fedora/f${rel_number}/products/${p_arch}",
    /(fedora)/                                           => "http://yum.puppet.com/fedora/f${rel_number}/PC1/${p_arch}",
    /(redhat|centos|scientificlinux|oraclelinux)/        => "http://yum.puppet.com/el/${rel_major}/PC1/${p_arch}",
    default                                              => 'No PuppetLabs Repo',
  }
  notice($puppetlabs_repo)
  notice($_dot_bootsplash)
  notice($autofile)
  notice($linux_installer)
  notice($pxekernel)
  notice($initrd)
  notice($target_initrd)
  notice($url)
  notice($inst_repo)
  notice($update_repo)
  notice($splash_url)
  notice($logo_url)
  notice($boot_iso_url)
  notice($boot_iso_name)
  notice($rel_name)
  notice($unzip_iso)


# Retrieve installation kernel file if supported
  case $url {
    'ISO Required instead of URL':{
      case $unzip_iso {
        true:{
          if ! defined (Archive["${name}-boot.iso.zip"]){
            archive{"${name}-boot.iso.zip":
              path         => "/srv/quartermaster/${distro}/ISO/${archive_name}",
              source       => $boot_iso_url,
              extract      => true,
              extract_path => "/srv/quartermaster/${distro}/ISO",
              creates      => "/srv/quartermaster/${distro}/ISO/${boot_iso_name}",
              cleanup      => true,
              notify       => Service['autofs'],
              require      =>[
                Tftp::File["${distro}/${p_arch}"],
                File["/srv/quartermaster/${distro}/ISO"],
              ],
            }
          }
        }
        default:{
          if ! defined (Staging::File["${name}-boot.iso"]){
            staging::file{"${name}-boot.iso":
              source      => $boot_iso_url,
              target      => "/srv/quartermaster/${distro}/ISO/${boot_iso_name}",
              # Because we are grabbing ISOs here we may need more time when downloading depending on network connection
              # This wget_option will continue downloads (-c) use ipv4 (-4) retry refused connections and failed errors (--retry-connrefused ) then wait 1 sec
              # before next retry (--waitretry=1), wait a max of 20 seconds if no data is recieved and try again (--read-timeout=20)
              # wait max 15 sec before initial connect times out ( --timeout=15) and retry inifinite times ( -t 0)
              wget_option => '-c -4 --retry-connrefused --waitretry=1 --read-timeout=20 --timeout=15 -t 0',
              notify      => Service['autofs'],
              require     =>[
                Tftp::File["${distro}/${p_arch}"],
                File["/srv/quartermaster/${distro}/ISO"],
              ],
              timeout     => '0',
            }
            # Retrieve installation kernel file if supported
            if ! defined (Staging::File["bootiso-${target_kernel}-${name}"]){
              staging::file{"bootiso-${target_kernel}-${name}":
                source  => "http://${::fqdn}/${distro}/mnt/${boot_iso_name}/images/pxeboot/${pxekernel}",
                target  => "/srv/quartermaster/tftpboot/${distro}/${p_arch}/${target_kernel}",
                owner   => $::tftp::username,
                group   => $::tftp::username,
                require => [
                  Service['autofs'],
                  Autofs::Mount[$distro],
                  Staging::File["${name}-boot.iso"],
                ],
              }
            }
            # Retrieve initrd file if supported
            if ! defined (Staging::File["bootiso-${target_initrd}-${name}"]){
              staging::file{"bootiso-${target_initrd}-${name}":
                source  => "http://${::fqdn}/${distro}/mnt/${boot_iso_name}/images/pxeboot/${src_initrd}",
                target  => "/srv/quartermaster/tftpboot/${distro}/${p_arch}/${target_initrd}",
                owner   => $::tftp::username,
                group   => $::tftp::username,
                require => [
                  Service['autofs'],
                  Autofs::Mount[$distro],
                  Staging::File["${name}-boot.iso"],
                ],
              }
            }
          }
        }
      }
    }
    'No URL Specified':{
      warning("No URL is specified for ${name}")
    }
    default:{
    # Retrieve installation kernel file if supported
      if ! defined (Staging::File["${target_kernel}-${name}"]){
        staging::file{"${target_kernel}-${name}":
          source  => "${url}/${pxekernel}",
          target  => "/srv/quartermaster/tftpboot/${distro}/${p_arch}/${target_kernel}",
          owner   => $::tftp::username,
          group   => $::tftp::username,
          require => Tftp::File["${distro}/${p_arch}"],
        }
      }
      # Retrieve initrd file if supported
      if ! defined (Staging::File["${target_initrd}-${name}"]){
        staging::file{"${target_initrd}-${name}":
          source  => "${url}/${src_initrd}",
          target  => "/srv/quartermaster/tftpboot/${distro}/${p_arch}/${target_initrd}",
          owner   => $::tftp::username,
          group   => $::tftp::username,
          require =>  Tftp::File["${distro}/${p_arch}"],
        }
      }
#     if ! defined (Staging::File["dot_bootsplash-${name}"]){
#       staging::file{"dot_bootsplash-${name}":
#         source  => $splash_url,
#         target  => "/srv/quartermaster/tftpboot/${distro}/graphics/${name}${_dot_bootsplash}",
#         require =>  Tftp::File["${distro}/graphics"],
#       }
#     }
    }
  }

#  if ! defined (Staging::File["_dot_bootsplash-${name}"]){
#    staging::file{"_dot_bootsplash-${name}":
#      source  => $splash_url,
#      target  => "/srv/quartermaster/tftpboot/${distro}/graphics/${name}${_dot_bootsplash}",
#      require =>  Tftp::File["${distro}/graphics"],
#    }
#  }

# Distro Specific TFTP Folders

  Tftp::File{
    owner => $::tftp::username,
    group => $::tftp::username,
  }

  if ! defined (Tftp::File[$distro]){
    tftp::file { $distro:
      ensure  => directory,
    }
  }


  if ! defined (Tftp::File["${distro}/menu"]){
    tftp::file { "${distro}/menu":
      ensure  => directory,
    }
  }

  if ! defined (Tftp::File["${distro}/graphics"]){
    tftp::file { "${distro}/graphics":
      ensure  => directory,
    }
  }

  if ! defined (Tftp::File["${distro}/${p_arch}"]){
    tftp::file { "${distro}/${p_arch}":
      ensure  => directory,
    }
  }

# Distro Specific TFTP Graphics.conf

if $linux_installer == !('No Supported Linux Installer') {
  tftp::file { "${distro}/menu/${name}.graphics.conf":
    content => template("quartermaster/pxemenu/${linux_installer}.graphics.erb"),
    require => Tftp::File["${distro}/menu"],
  }
}
#################################################
# Begin Creating Distro Specific HTTP Folder Tree 
#################################################


  if ! defined (File["/srv/quartermaster/${distro}"]) {
    file { "/srv/quartermaster/${distro}":
      ensure  => directory,
      require => File[ '/srv/quartermaster' ],
    }
    notice(File["/srv/quartermaster/${distro}"])
  }

  if ! defined (File["/srv/quartermaster/${distro}/${autofile}"]) {
    file { "/srv/quartermaster/${distro}/${autofile}":
      ensure  => directory,
      require => File[ "/srv/quartermaster/${distro}" ],
    }
  }

  if ! defined (File["/srv/quartermaster/${distro}/${p_arch}"]) {
    file { "/srv/quartermaster/${distro}/${p_arch}":
      ensure  => directory,
      require => File[ "/srv/quartermaster/${distro}" ],
    }
  }

  if ! defined (File["/srv/quartermaster/${distro}/ISO"]) {
    file { "/srv/quartermaster/${distro}/ISO":
      ensure  => directory,
      require => File[ "/srv/quartermaster/${distro}" ],
    }
  }
  if ! defined (Autofs::Mount[$distro]) {
    autofs::mount{$distro:
      mount       => "/srv/quartermaster/${distro}/mnt",
      mapfile     => "/etc/auto.${distro}",
      mapcontents => [
        "* -fstype=iso9660,loop :/srv/quartermaster/${distro}/ISO/&",
      ],
      options     => '--timeout=10',
      order       => 01,
    }
  }
  if ! defined (File["/srv/quartermaster/${distro}/mnt"]) {
    file { "/srv/quartermaster/${distro}/mnt":
      ensure  => directory,
      require => File[ "/srv/quartermaster/${distro}" ],
    }
  }

  ## .README.html (FILE) /srv/quartermaster/distro/.README.html
  if ! defined (Concat["/srv/quartermaster/${distro}/.README.html"]) {
    concat{ "/srv/quartermaster/${distro}/.README.html":
      owner   => $::nginx::daemon_user,
      group   => $::nginx::daemon_user,
      mode    => '0644',
      require => File[ "/srv/quartermaster/${distro}" ],
    }
  }

  ## .README.html (HEADER) /srv/quartermaster/distro/.README.html
  if ! defined (Concat::Fragment["${distro}.default_README_header"]) {
    concat::fragment { "${distro}.default_README_header":
      target  => "/srv/quartermaster/${distro}/.README.html",
      content => "<html>
<head><title> ${distro} ${release} ${p_arch}</title></head>
<body>
<h1>Operating System: ${distro} </h1>
<h2>Platform Releases Installed: </h2>
<ul>",
      order   => 01,
    }
  }
  ## .README.html (BODY) /srv/quartermaster/distro/.README.html
  if ! defined (Concat::Fragment["${distro}.default_README_release_body.${name}"]) {
    concat::fragment { "${distro}.default_README_release_body.${name}":
      target  => "/srv/quartermaster/${distro}/.README.html",
      content => "<li>${release} (${p_arch})</li> ",
      order   => 02,
    }
  }
  ## .README.html (FOOTER) /srv/quartermaster/distro/.README.html
  if ! defined (Concat::Fragment["${distro}.default_README_footer"]) {
    concat::fragment { "${distro}.default_README_footer":
      target  => "/srv/quartermaster/${distro}/.README.html",
      content => '</ul>
</body>
</html>',
      order   => 03,
    }
  }
  notice(File["/srv/quartermaster/${distro}/.README.html"])


  ## .README.html (FILE) /quartermaster/distro/p_arch/.README.html
  if ! defined (Concat["/srv/quartermaster/${distro}/${p_arch}/.README.html"]) {
    concat{ "/srv/quartermaster/${distro}/${p_arch}/.README.html":
      owner   => $::nginx::daemon_user,
      group   => $::nginx::daemon_user,
      mode    => '0644',
      require => File[ "/srv/quartermaster/${distro}/${p_arch}" ],
    }
  }
  ## .README.html (HEADER) /quartermaster/distro/p_arch/.README.html
  if ! defined (Concat::Fragment["${distro}.default_${p_arch}_README_header"]) {
    concat::fragment { "${distro}.default_${p_arch}_README_header":
      target  => "/srv/quartermaster/${distro}/${p_arch}/.README.html",
      content => template('quartermaster/README.html.header.erb'),
      order   => 01,
    }
  }
  ## .README.html (BODY 1) /quartermaster/distro/p_arch/.README.html
  if ! defined (Concat::Fragment["${distro}.default_README_p_arch_body"]) {
    concat::fragment { "${distro}.default_README_p_arch_body":
      target  => "/srv/quartermaster/${distro}/${p_arch}/.README.html",
      content => "<h3>Processor Arch: ${p_arch}</h3>",
      order   => 02,
    }
  }
  ## .README.html (BODY TEMPLATE) /quartermaster/distro/p_arch/.README.html
  if ! defined (Concat::Fragment["${distro}.default_${p_arch}_README_body.${name}"]) {
    concat::fragment { "${distro}.default_${p_arch}_README_body.${name}":
      target  => "/srv/quartermaster/${distro}/${p_arch}/.README.html",
      content => template('quartermaster/README.html.body.erb'),
      order   => 03,
    }
  }
  ## .README.html (FOOTER) /quartermaster/distro/p_arch/.README.html
  if ! defined (Concat::Fragment["${distro}.default_${p_arch}_README_footer"]) {
    concat::fragment { "${distro}.default_${p_arch}_README_footer":
      target  => "/srv/quartermaster/${distro}/${p_arch}/.README.html",
      content => template('quartermaster/README.html.footer.erb'),
      order   => 04,
    }
  }


  #  Distro Kickstart/Preseed File
  file { "${name}.${autofile}":
    ensure  => file,
    path    => "/srv/quartermaster/${distro}/${autofile}/${name}.${autofile}",
    content => template("quartermaster/autoinst/${autofile}.erb"),
    require => File[ "/srv/quartermaster/${distro}/${autofile}" ],
  }

  # PXEMENU ( pxelinux/pxelinux.cfg/default ) 
  if ! defined (Concat::Fragment["${distro}.default_menu_entry"]) {
    concat::fragment { "${distro}.default_menu_entry":
      target  => '/srv/quartermaster/tftpboot/pxelinux/pxelinux.cfg/default',
      content => template('quartermaster/pxemenu/default.erb'),
      order   => 02,
    }
  }
  # PXEMENU ( menu/distro.menu ) 
  if ! defined (Concat["/srv/quartermaster/tftpboot/menu/${distro}.menu"]) {
    concat { "/srv/quartermaster/tftpboot/menu/${distro}.menu":
    }
  }
  if ! defined (Concat::Fragment["${distro}.submenu_header"]) {
    concat::fragment {"${distro}.submenu_header":
      target  => "/srv/quartermaster/tftpboot/menu/${distro}.menu",
      content => template('quartermaster/pxemenu/header2.erb'),
      order   => 01,
    }
  }
  if ! defined (Concat::Fragment["${distro}${name}.menu_item"]) {
    concat::fragment {"${distro}.${name}.menu_item":
      target  => "/srv/quartermaster/tftpboot/menu/${distro}.menu",
      content => template('quartermaster/pxemenu/default2.erb'),
    }
  }
  if ! defined (Concat::Fragment[matchbox-pxe-menu]) {
    if ( $quartermaster::matchbox_enable ) {
      notice('Matchbox is enabled')
      if ( $distro == 'coreos') {
        notice('Matchbox is enabled')
        concat::fragment{'matchbox-pxe-menu':
          target  =>  "/srv/quartermaster/tftpboot/menu/${distro}.menu",
          content => template('quartermaster/pxemenu/matchbox.erb'),
        }
      }
    }
  }
  tftp::file { "${distro}/menu/${name}.menu":
    content => template("quartermaster/pxemenu/${linux_installer}.erb"),
  }
  notify{"${name}-restart-tftp":
    message => "Force restart of tftpd for ${name}",
    notify  => Service['tftpd-hpa'],
  }
}
