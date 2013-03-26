include apt
stage { 'req-install': before => Stage['rvm-install'] }

class requirements {
  group { "puppet": ensure => "present", }
  exec { "apt-update":
    command => "/usr/bin/apt-get -y update"
  }
}

class { requirements:, stage => "req-install" }

class installrvm {
    include rvm
}

stage { 'rvm_stage':
    require => Stage['main'],
}

class { 'installrvm':
    stage => rvm_stage,
}

class postgresinstall {
    include postgresql
    include postgresql::server

    #want to run any commands inside psql?
    #sudo -u postgres psql

    postgresql::psql { "CREATE ROLE vagrant LOGIN CREATEROLE CREATEDB SUPERUSER": 
         db => 'postgres',
         user => 'postgres',
         unless => "SELECT rolename FROM pg_roles WHERE rolename='vagrant'"
    } 

    postgresql::psql { "CREATE ROLE root LOGIN CREATEROLE CREATEDB SUPERUSER": 
         db => 'postgres',
         user => 'postgres',
         unless => "SELECT rolename FROM pg_roles WHERE rolename='root'"
    } 
}

class main_install_stage {
    Exec { path => '/usr/bin:/bin:/usr/sbin:/sbin' }

    #include postgresinstall

    exec { "apt-update-again":
        command => "/usr/bin/apt-get -y update"
    }

    #get node
    include nodejs 

    #apt packages we want installed
    package {
    ["vim", "python-software-properties", "memcached", "augeas-tools", "libaugeas-dev", "libaugeas-ruby", "libpq-dev"]: 
      ensure => installed, require => Exec['apt-update']
    }

    #stuff for rvm??!!??
    package {
    ["libgdbm-dev", "libtool", "pkg-config", "libffi-dev"]:
      ensure => installed, require => Exec['apt-update']
    }

    include zsh
}

class { 'main_install_stage': }

class postrvm {

    Exec { path => '/usr/bin:/bin:/usr/sbin:/sbin:/home/vagrant/.rvm/bin' }

    # installl a ruby

    exec{ "get_a_ruby" :
        user => vagrant,
        command => "bash -l -c '/home/vagrant/.rvm/bin/rvm install 1.9.3-p392 >> /code/code/error.log 2>&1'",
        environment => "HOME=/home/vagrant",
    }

    exec{ "set_a_ruby" :
        user => vagrant,

        command => "bash -l -c 'rvm use 1.9.3 >> /code/code/error.log 2>&1'",

        require => Exec['get_a_ruby'],
        environment => "HOME=/home/vagrant",
    }

    #/home/vagrant/.rvm/rubies/ruby-1.9.3-p392/bin/gem

    #get gem!!!
    exec{ "gem_install":
        user => vagrant,

        command => "bash -l -c 'rvm rubygems latest --verify-downloads 1'",

        require => exec['set_a_ruby'],
        environment => "HOME=/home/vagrant",
    }

    exec{ "bundle_install":
        user => vagrant,

        command => "sudo bash -l -c '/home/vagrant/.rvm/rubies/ruby-1.9.3-p392/bin/gem install bundle --no-rdoc --no-ri >> /code/code/error.log 2>&1'",

        require => exec['gem_install'],
        environment => "HOME=/home/vagrant",
    }

    exec{ "rails_install":
        user => vagrant,
        command => "sudo bash -l -c '/home/vagrant/.rvm/rubies/ruby-1.9.3-p392/bin/gem install rails >> /code/code/error.log 2>&1'",
        require => Exec['bundle_install'],
        environment => "HOME=/home/vagrant",
        timeout => 0
    }
}

stage { 'postrvm_stage':
    require => Stage['main'],
}

class { 'postrvm':
    stage => postrvm_stage,
}

class rails_setup {

    Exec { path => '/usr/bin:/bin:/usr/sbin:/sbin:/home/vagrant/.rvm/bin' }

    file { "/code/code" : 
      path    => "/code/code", 
      mode    => 0755, 
      owner   => vagrant, 
      ensure  => directory, 
      recurse => true, 
    } 

    file { "/code/code/rails" : 
      path    => "/code/code/rails", 
      mode    => 0755, 
      owner   => vagrant, 
      ensure  => directory, 
      recurse => true, 
      require => File["/code/code"]
    } 

    # make a new project
    exec{ "new_rails_project" :
        command => "sudo bash -l -c 'rails new rails-test-1 --skip-bundle >> /code/code/error.log 2>&1'",
        cwd => "/code/code/rails",
        user => vagrant,
        require => File["/code/code/rails"],
        environment => "HOME=/home/vagrant",
    }
    
    # copy the gemfile
    file { "/code/code/rails/rails-test-1/Gemfile":
        source  => "puppet:////local-home/Gemfile.vagrant",
        require => Exec["new_rails_project"]
    }

    # run bundler on it
    exec{ "bundler_install" :
        command => "sudo bash -l -c 'bundle install >> /code/code/error.log 2>&1'",
        cwd => "/code/code/rails/rails-test-1",
        user => vagrant,
        require => File["/code/code/rails/rails-test-1/Gemfile"],
        environment => "HOME=/home/vagrant",
    }
}

stage { 'rails_setup_stage' :
    require => Stage['postrvm_stage']
}

class { 'rails_setup':
    stage => 'rails_setup_stage'
}

class user_land {

    zsh::user { "vagrant": }

    Exec { path => '/usr/bin:/bin:/usr/sbin:/sbin' }

    exec { "oh-my-zsh-install":
       user => vagrant,
       environment => "HOME=/home/vagrant",
       command => "bash -l -c '/usr/bin/curl -L https://github.com/robbyrussell/oh-my-zsh/raw/master/tools/install.sh | bash >> /code/code/error.log 2>&1'",
    }

    file { "/home/vagrant/.bash_aliases":
        source  => "puppet:////local-home/.bash_aliases",
        require => Exec['oh-my-zsh-install'],
    }

    file { "/home/vagrant/.zprofile":
        source  => "puppet:////local-home/.zprofile"
    }

    file { "/home/vagrant/.oh-my-zsh":
        ensure => directory, # so make this a directory
        recurse => true, # enable recursive directory management
        purge => true, # purge all unmanaged junk
        force => true, # also purge subdirs and links etc.
        mode => 0644, # this mode will also apply to files from the source directory
        source  => "puppet:////local-home/.oh-my-zsh",
        require => Exec['oh-my-zsh-install'],
    }

    file { "/home/vagrant/.vimrc":
        source  => "puppet:////local-home/.vimrc"
    }

    file { "/home/vagrant/.vim":
        ensure => directory, # so make this a directory
        recurse => true, # enable recursive directory management
        purge => true, # purge all unmanaged junk
        force => true, # also purge subdirs and links etc.
        source  => "puppet:////local-home/.vim"
    }
}

stage { 'user_land_stage':
    require => Stage['postrvm_stage'],
}

class { 'user_land':
    stage => user_land_stage,
}
