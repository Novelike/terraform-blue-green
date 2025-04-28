output "public_ip" {
  description = "생성된 VM의 퍼블릭 IP"
  value       = openstack_networking_floatingip_v2.public_ip.address
}

