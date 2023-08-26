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
# @example
#   include profile_jsm
class profile_jsm (
  String $db_name,
  String $db_user,
  String $db_password,
) {
  include ::lvm
  include ::postgresql::server

  # This seems to be the only way to interact with postgresql::globals
  # but install fails regardless
  # class { 'postgresql::globals':
  #   manage_dnf_module =>  true,
  #   manage_package_repo =>  true,
  #   version =>  '15',
  # }
  # class { 'postgresql::server':
  # }

  postgresql::server::database { $db_name :
    comment  => 'Jira Service Management',
    encoding => 'UTF-8',
    locale   => 'en_US.UTF-8',
  }

  postgresql::server::role { $db_user :
    password_hash => $db_password,
    createdb      => true,
    db            => $db_name,
  }

}
