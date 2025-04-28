// terraform/outputs.tf

output "public_ip" {
  description = "생성된 VM에 할당된 퍼블릭(플로팅) IP 주소"
  value       = openstack_networking_floatingip_v2.public_ip.address
}

