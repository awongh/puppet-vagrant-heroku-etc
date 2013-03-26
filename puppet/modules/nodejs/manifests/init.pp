class nodejs {

  user { "node":
    ensure => "present",
    home => "/home/node"
  }

  package { "g++":
    ensure => "installed"
  }

  file { "/home/node":
    ensure => "directory",
    owner => "node"
  }

  file { "/home/node/opt":
    ensure => "directory",
    require => File["/home/node"],
    owner => "node"
  }

  file { "/home/node/.bashrc":
    ensure => "present",
    owner => "node",
    content => template('nodejs/node_bashrc.erb')
  }

  file { "/tmp/node-v0.3.3.tar.gz":
    source => "puppet:///modules/nodejs/node-v0.3.3.tar.gz",
    ensure => "present",
    owner => "node",
    group => "node"
  }

  exec { "extract_node":
    command => "/bin/tar -xzf node-v0.3.3.tar.gz",
    cwd => "/tmp",
    creates => "/tmp/node-v0.3.3",
    require => [File["/tmp/node-v0.3.3.tar.gz"], User["node"]],
    user => "node"
  }

  exec { "/bin/bash ./configure --prefix=/home/node/opt":
    alias => "configure_node",
    cwd => "/tmp/node-v0.3.3",
    require => [Exec["extract_node"], Package["g++"]],
    timeout => 0,
    creates => "/tmp/node-v0.3.3/.lock-wscript",
    user => "node"
  }

  file { "/tmp/node-v0.3.3":
    ensure => "directory",
    owner => "node",
    group => "node",
    require => Exec["configure_node"]
  }

  exec { "make_node":
    command => "/usr/bin/make",
    cwd => "/tmp/node-v0.3.3",
    require => Exec["configure_node"],
    timeout => 0,
    user => "node"
  }

  exec { "install_node":
    command => "/usr/bin/make install",
    cwd => "/tmp/node-v0.3.3",
    require => Exec["make_node"],
    timeout => 0,
    creates => "/home/node/opt/bin/node",
    user => "node"
  }

  file { "/home/node/opt/bin/node":
    owner => "node",
    group => "node",
    require => Exec["install_node"],
    recurse => true
  }

  file { "/home/node/opt/bin/node-waf":
    owner => "node",
    group => "node",
    recurse => true,
    require => Exec["install_node"]
  }

}

