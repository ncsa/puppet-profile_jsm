# @summary Set up the firewall for the server
#
# @param firewall_hash
#   The parameter is a hash of hashes.
#   Each contained hash should start with 2 entries: "NAME' and 'PORT'.
#
# @example
#   include profile_jsm::firewall
class profile_jsm::firewall (
  Hash $firewall_hash,
) {
  $firewall_hash.each | $tag, $sub_hash | {
    profile_jsm::add_firewall_entries($sub_hash)
  }
}
