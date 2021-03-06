# Class: rabbitmq::config
# Sets all the configuration values for RabbitMQ and creates the directories for
# config and ssl.
class rabbitmq::config {

  $admin_enable               = $rabbitmq::admin_enable
  $cluster_node_type          = $rabbitmq::cluster_node_type
  $cluster_nodes              = $rabbitmq::cluster_nodes
  $config                     = $rabbitmq::config
  $config_cluster             = $rabbitmq::config_cluster
  $config_path                = $rabbitmq::config_path
  $config_stomp               = $rabbitmq::config_stomp
  $config_shovel              = $rabbitmq::config_shovel
  $config_shovel_statics      = $rabbitmq::config_shovel_statics
  $default_user               = $rabbitmq::default_user
  $default_pass               = $rabbitmq::default_pass
  $env_config                 = $rabbitmq::env_config
  $env_config_path            = $rabbitmq::env_config_path
  $erlang_cookie              = $rabbitmq::erlang_cookie
  $interface                  = $rabbitmq::interface
  $management_ip              = $rabbitmq::management_ip
  $management_port            = $rabbitmq::management_port
  $management_ssl             = $rabbitmq::management_ssl
  $management_hostname        = $rabbitmq::management_hostname
  $node_ip_address            = $rabbitmq::node_ip_address
  $plugin_dir                 = $rabbitmq::plugin_dir
  $rabbitmq_user              = $rabbitmq::rabbitmq_user
  $rabbitmq_group             = $rabbitmq::rabbitmq_group
  $rabbitmq_home              = $rabbitmq::rabbitmq_home
  $port                       = $rabbitmq::port
  $tcp_keepalive              = $rabbitmq::tcp_keepalive
  $tcp_backlog                = $rabbitmq::tcp_backlog
  $tcp_sndbuf                 = $rabbitmq::tcp_sndbuf
  $tcp_recbuf                 = $rabbitmq::tcp_recbuf
  $heartbeat                  = $rabbitmq::heartbeat
  $service_name               = $rabbitmq::service_name
  $ssl                        = $rabbitmq::ssl
  $ssl_only                   = $rabbitmq::ssl_only
  $ssl_cacert                 = $rabbitmq::ssl_cacert
  $ssl_cert                   = $rabbitmq::ssl_cert
  $ssl_key                    = $rabbitmq::ssl_key
  $ssl_depth                  = $rabbitmq::ssl_depth
  $ssl_cert_password          = $rabbitmq::ssl_cert_password
  $ssl_port                   = $rabbitmq::ssl_port
  $ssl_interface              = $rabbitmq::ssl_interface
  $ssl_management_port        = $rabbitmq::ssl_management_port
  $ssl_stomp_port             = $rabbitmq::ssl_stomp_port
  $ssl_verify                 = $rabbitmq::ssl_verify
  $ssl_fail_if_no_peer_cert   = $rabbitmq::ssl_fail_if_no_peer_cert
  $ssl_versions               = $rabbitmq::ssl_versions
  $ssl_ciphers                = $rabbitmq::ssl_ciphers
  $stomp_port                 = $rabbitmq::stomp_port
  $stomp_ssl_only             = $rabbitmq::stomp_ssl_only
  $ldap_auth                  = $rabbitmq::ldap_auth
  $ldap_server                = $rabbitmq::ldap_server
  $ldap_user_dn_pattern       = $rabbitmq::ldap_user_dn_pattern
  $ldap_other_bind            = $rabbitmq::ldap_other_bind
  $ldap_use_ssl               = $rabbitmq::ldap_use_ssl
  $ldap_port                  = $rabbitmq::ldap_port
  $ldap_log                   = $rabbitmq::ldap_log
  $ldap_config_variables      = $rabbitmq::ldap_config_variables
  $wipe_db_on_cookie_change   = $rabbitmq::wipe_db_on_cookie_change
  $config_variables           = $rabbitmq::config_variables
  $config_kernel_variables    = $rabbitmq::config_kernel_variables
  $config_management_variables = $rabbitmq::config_management_variables
  $config_additional_variables = $rabbitmq::config_additional_variables
  $auth_backends              = $rabbitmq::auth_backends
  $cluster_partition_handling = $rabbitmq::cluster_partition_handling
  $file_limit                 = $rabbitmq::file_limit
  $collect_statistics_interval = $rabbitmq::collect_statistics_interval
  $ipv6                       = $rabbitmq::ipv6
  $inetrc_config              = $rabbitmq::inetrc_config
  $inetrc_config_path         = $rabbitmq::inetrc_config_path

  if $ssl_only {
    $default_ssl_env_variables = {}
  } else {
    $default_ssl_env_variables = {
      'NODE_PORT'        => $port,
      'NODE_IP_ADDRESS'  => $node_ip_address
    }
  }

  $inetrc_env = {'export ERL_INETRC' => $inetrc_config_path}

  # Handle env variables.
  $_environment_variables = merge($default_ssl_env_variables, $inetrc_env, $rabbitmq::environment_variables)

  if $ipv6 {
    # must append "-proto_dist inet6_tcp" to any provided ERL_ARGS for
    # both the server and rabbitmqctl, being careful not to mess up
    # quoting
    $ipv6_env = ['SERVER', 'CTL'].reduce({}) |$memo, $item| {
      $orig = $_environment_variables["RABBITMQ_${item}_ERL_ARGS"]
      $munged = $orig ? {
        # already quoted, keep quoting
        /^([\'\"])(.*)\1/ => "${1}${2} -proto_dist inet6_tcp${1}",
        # unset, add our own quoted value
        undef             => '"-proto_dist inet6_tcp"',
        # previously unquoted value, add quoting
        default           => "\"${orig} -proto_dist inet6_tcp\"",
      }

      merge($memo, {"RABBITMQ_${item}_ERL_ARGS" => $munged})
    }

    $environment_variables = merge($_environment_variables, $ipv6_env)
  } else {
    $environment_variables = $_environment_variables
  }

  # Get ranch (socket acceptor pool) availability,
  # use init class variable for that since version from the fact comes too late.
  $ranch = versioncmp($rabbitmq::version, '3.6') >= 0

  file { '/etc/rabbitmq':
    ensure => directory,
    owner  => '0',
    group  => '0',
    mode   => '0755',
  }

  file { '/etc/rabbitmq/ssl':
    ensure => directory,
    owner  => '0',
    group  => '0',
    mode   => '0755',
  }

  file { 'rabbitmq.config':
    ensure  => file,
    path    => $config_path,
    content => template($config),
    owner   => '0',
    group   => $rabbitmq_group,
    mode    => '0640',
    notify  => Class['rabbitmq::service'],
  }

  file { 'rabbitmq-env.config':
    ensure  => file,
    path    => $env_config_path,
    content => template($env_config),
    owner   => '0',
    group   => $rabbitmq_group,
    mode    => '0640',
    notify  => Class['rabbitmq::service'],
  }

  file { 'rabbitmq-inetrc':
    ensure  => file,
    path    => $inetrc_config_path,
    content => template($inetrc_config),
    owner   => '0',
    group   => $rabbitmq_group,
    mode    => '0640',
    notify  => Class['rabbitmq::service'],
  }

  if $admin_enable {
    file { 'rabbitmqadmin.conf':
      ensure  => file,
      path    => '/etc/rabbitmq/rabbitmqadmin.conf',
      content => template('rabbitmq/rabbitmqadmin.conf.erb'),
      owner   => '0',
      group   => $rabbitmq_group,
      mode    => '0640',
      require => File['/etc/rabbitmq'],
    }
  }

  case $::osfamily {
    'Debian': {
      if versioncmp($::operatingsystemmajrelease, '16.04') >= 0 {
        file { '/etc/systemd/system/rabbitmq-server.service.d':
          ensure                  => directory,
          owner                   => '0',
          group                   => '0',
          mode                    => '0755',
          selinux_ignore_defaults => true,
        }
        -> file { '/etc/systemd/system/rabbitmq-server.service.d/limits.conf':
          content => template('rabbitmq/rabbitmq-server.service.d/limits.conf'),
          owner   => '0',
          group   => '0',
          mode    => '0644',
          notify  => Exec['rabbitmq-systemd-reload'],
        }
        exec { 'rabbitmq-systemd-reload':
          command     => '/bin/systemctl daemon-reload',
          notify      => Class['Rabbitmq::Service'],
          refreshonly => true,
        }
      }
      file { '/etc/default/rabbitmq-server':
        ensure  => file,
        content => template('rabbitmq/default.erb'),
        mode    => '0644',
        owner   => '0',
        group   => '0',
        notify  => Class['rabbitmq::service'],
      }
    }
    'RedHat': {
      if versioncmp($::operatingsystemmajrelease, '7') >= 0 {
        file { '/etc/systemd/system/rabbitmq-server.service.d':
          ensure                  => directory,
          owner                   => '0',
          group                   => '0',
          mode                    => '0755',
          selinux_ignore_defaults => true,
        }
        -> file { '/etc/systemd/system/rabbitmq-server.service.d/limits.conf':
          content => template('rabbitmq/rabbitmq-server.service.d/limits.conf'),
          owner   => '0',
          group   => '0',
          mode    => '0644',
          notify  => Exec['rabbitmq-systemd-reload'],
        }
        exec { 'rabbitmq-systemd-reload':
          command     => '/usr/bin/systemctl daemon-reload',
          notify      => Class['Rabbitmq::Service'],
          refreshonly => true,
        }
      }
      file { '/etc/security/limits.d/rabbitmq-server.conf':
        content => template('rabbitmq/limits.conf'),
        owner   => '0',
        group   => '0',
        mode    => '0644',
        notify  => Class['Rabbitmq::Service'],
      }
    }
    default: {
    }
  }

  if $erlang_cookie == undef and $config_cluster {
    fail('You must set the $erlang_cookie value in order to configure clustering.')
  } elsif $erlang_cookie != undef {
    rabbitmq_erlang_cookie { "${rabbitmq_home}/.erlang.cookie":
      content        => $erlang_cookie,
      force          => $wipe_db_on_cookie_change,
      rabbitmq_user  => $rabbitmq_user,
      rabbitmq_group => $rabbitmq_group,
      rabbitmq_home  => $rabbitmq_home,
      service_name   => $service_name,
      before         => File['rabbitmq.config'],
      notify         => Class['rabbitmq::service'],
    }
  }
}
