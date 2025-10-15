#
#
#
define profile_jsm::hba (
  String  $hba_desc,
  String  $hba_type,
  String  $hba_db,
  String  $hba_user,
  String  $hba_addr,
  String  $hba_auth,
) {
  postgresql::server::pg_hba_rule { 'Postgresql access':
    description => $hba_desc,
    type        => $hba_type,
    database    => $hba_db,
    user        => $hba_user,
    address     => $hba_addr,
    auth_method => $hba_auth,
  }
}
