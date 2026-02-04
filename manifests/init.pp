# @summary Prepare a server for running Jira Service Management
#
# Prepare a server for running Jira Service Management
#
# @param db_name Database name
#
# @param db_user Authorized user to access the database
#
# @param db_password Password for $db_user to access the database
#
# @param jira_home Jira [shared] home, absolute filesystem path
#
# @param backup_dir Absolute path where backups should go
#
# @param backups_max_qty Keep this many backups
#
# @param maintenance_allowed_ips Array of IPs allowed to access Jira while in
#        maintenance mode
#
# @param enable_cron_restart Boolean - Enable or disable the cronjob to
#        periodically restart the Confluence service.
#        Default: False
#
# @param cron_restart_params Hash, when to schedule the Confluence restart cron,
#        must be valid parameters to the Puppet Cron Resource
#
# @example
#   include profile_jsm
class profile_jsm (
  String  $db_name,
  String  $db_user,
  String  $db_password,
  String  $jira_home,
  String  $backup_dir,
  Hash  $pg_hba_rule,
  Integer $backups_max_qty,
  Array   $maintenance_allowed_ips,
  Boolean $enable_cron_restart,
  Hash    $cron_restart_params,
) {
  # For internal access to DB
  include profile_jsm::firewall

  $cron_params = {
    hour   => 4,
    minute => 4,
    user   => 'root',
  }

  # This seems to be the only way to interact with postgresql::globals
  # but install fails regardless
  # class { 'postgresql::globals':
  #   manage_dnf_module =>  true,
  #   manage_package_repo =>  true,
  #   version =>  '15',
  # }

  ### Postgres setup
  class { 'postgresql::server':
  }

  postgresql::server::database { $db_name :
    comment  => 'Jira Service Management',
    encoding => 'UNICODE',
  }

  $pwdhash = postgresql::postgresql_password( $db_user, $db_password )
  postgresql::server::role { $db_user :
    password_hash => $pwdhash,
    createdb      => true,
    db            => $db_name,
  }

  postgresql::server::grant { $db_name :
    privilege => 'ALL',
    db        => $db_name,
    role      => $db_user,
  }

  ### Maintenance setup
  # 503 downtime announcement
  $maint_html = '/var/www/html/maint.html'
  file { $maint_html:
    ensure => 'file',
    source => "puppet:///modules/${module_name}${maint_html}",
  }

  # IPs allowed to bypass maintenance mode
  $maint_dir = '/var/www/maintenance'
  $exceptions = "${maint_dir}/exceptions.map"
  file { $maint_dir:
    ensure => 'directory',
  }
  file { $exceptions:
    ensure  => 'file',
    content => epp("${module_name}/${exceptions}.epp", { 'cidr_list' => $maintenance_allowed_ips }),
  }

  # Enable scheduled service restarts
  if $enable_cron_restart {
    cron { 'Restart the jira service periodically' :
      command => '/usr/bin/systemctl restart jira',
      user    => root,
      *       => $cron_restart_params,
    }
  }

  # ### Jira Backups
  # $jira_backup = '/root/cron_scripts/jira-backup.sh'
  # file { $jira_backup :
  #   ensure  => file,
  #   mode    => '0700',
  #   owner   => 'root',
  #   group   => '0',
  #   content => epp("profile_jsm/${jira_backup}.epp", {
  #       jira_home  => $jira_home,
  #       backup_dir => "${backup_dir}/jirahome",
  #       rotate     => $backups_max_qty,
  #     }
  #   ),
  # }

  # cron { 'jira home backup':
  #   command => $jira_backup,
  #   *       => $cron_params,
  # }

  # Adds HBA rules for postgresql which allows DB access
  $pg_hba_rule.each |$type, $properties| {
    profile_jsm::hba {$type: * => $properties}
  }
}
