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
# @example
#   include profile_jsm
class profile_jsm (
  String  $db_name,
  String  $db_user,
  String  $db_password,
  String  $jira_home,
  String  $backup_dir,
  Integer $backups_max_qty,
) {
  include lvm
  include profile_website

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
    backup_enable  => true,
    backup_options => {
      dir         => "${backup_dir}/postgres",
      db_user     => 'postgres_backup_user',
      db_password => $db_password,
      time        => [$cron_params[hour], $cron_params[minute]],
      manage_user => true,
      rotate      => $backups_max_qty,
    },
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

  ### Jira Backups
  $jira_backup = '/root/cron_scripts/jira-backup.sh'
  file { $jira_backup :
    ensure  => file,
    mode    => '0700',
    owner   => 'root',
    group   => '0',
    content => epp("profile_jsm/${jira_backup}.epp", {
        jira_home  => $jira_home,
        backup_dir => "${backup_dir}/jirahome",
        rotate     => $backups_max_qty,
      }
    ),
  }

  cron { 'jira home backup':
    command => $jira_backup,
    *       => $cron_params,
  }
}
