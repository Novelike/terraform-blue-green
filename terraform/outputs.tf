output "blue_ip" {
  description = "Blue 서버 IP"
  value       = openstack_compute_instance_v2.web["blue"].access_ip_v4
}

output "green_ip" {
  description = "Green 서버 IP"
  value       = openstack_compute_instance_v2.web["green"].access_ip_v4
}

output "lb_vip" {
  description = "LoadBalancer VIP"
  value       = openstack_lb_loadbalancer_v2.lb.vip_address
}

