output "floating_network_id" {
  description = "External 네트워크 ID (CLI 로 플로팅 IP 생성할 때)"
  value       = data.openstack_networking_network_v2.floating_network.id
}
