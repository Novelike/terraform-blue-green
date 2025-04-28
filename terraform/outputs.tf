output "blue_ip" {
  description = "Blue 서버 플로팅 IP"
  value       = openstack_networking_floatingip_v2.fip["blue"].address
}

output "green_ip" {
  description = "Green 서버 플로팅 IP"
  value       = openstack_networking_floatingip_v2.fip["green"].address
}

output "lb_vip" {
  description = "LoadBalancer VIP"
  value       = openstack_lb_loadbalancer_v2.lb.vip_address
}

