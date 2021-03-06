class fcrepo inherits fcrepo::config {

  #we need a "valid fqdn" for fedora purposes, so lets enter a hosts file entry equivalent to our box

  host { $hostname:
    ip     => '127.0.0.1',
    ensure => present,
  }
  
  if $config::version == 'latest' {
    $download_url = "http://sourceforge.net/projects/fedora-commons/files/latest/download"
  } else {
    $download_url = "http://downloads.sourceforge.net/fedora-commons/fcrepo-installer-#{version}.jar"
  }

  staging::file { 'fcrepo-installer.jar':
    source  => $download_url,
    timeout => 1200,
    subdir  => 'fedora',
    require => Class['tomcat::service'],
  }
 
  file { $config::fedora_base:
    ensure => directory,
    owner  => $config::user,
    group  => $config::group,
    mode   => '0775',
    require => Class['fcrepo::config']
  }
 
  exec { 'install-fedora':
    command     => "java -jar /opt/staging/fedora/fcrepo-installer.jar ${fcrepo::config::propfile}",
    creates     => "$fcrepo::config::tomcat_home/webapps/fedora.war",
    environment => "FEDORA_HOME=${config::fedora_home}",
    timeout     => 1800,
    user        => $config::user,
    group       => $config::group,
    path        => ['/bin', '/usr', '/usr/bin'],
    require     => [Staging::File['fcrepo-installer.jar'],Concat["$fcrepo::config::propfile"],File["$config::fedora_base"],Class['tomcat'],],
    notify      => File["${config::fedora_home}/server/status"], 
    #Concat::Fragment['fedora-tomcat-config']]
  }
 
  file { [$config::fedora_home, "${config::fedora_home}/server/logs", "${config::fedora_home}/server/fedora-internal-use", 
    "${config::fedora_home}/server/management/upload", "${config::fedora_home}/server/work"]:
    ensure  => directory,
    owner   => $config::user,
    group   => $config::group,
    mode    => '0775',
    require => Exec['install-fedora']
  }

  file { "${config::fedora_home}/server/status":
    ensure  => present,
    owner   => $config::user,
    group   => $config::group,
    mode    => '0664',
    recurse => true,
    require => Exec['install-fedora']
  }

}
