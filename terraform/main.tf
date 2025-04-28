terraform {
  required_providers {
    openstack = {
      source  = "terraform-provider-openstack/openstack"
      version = ">= 1.49.0"
    }
  }
}

provider "openstack" {
  auth_url    = "https://iam.kakaocloud.com/identity/v3"
  region      = var.region
  user_name   = var.username
  password    = var.password
  tenant_name = var.tenant_name
  domain_name = "kc-kdt-sfacspace2025"
}

# 1) Ubuntu 이미지 조회
data "openstack_images_image_v2" "ubuntu" {
  name        = var.image_name
  most_recent = true
}

# 2) External/Public 네트워크 조회
data "openstack_networking_network_v2" "floating_network" {
  external = true
}

# 3) 보안 그룹 생성
resource "openstack_networking_secgroup_v2" "web" {
  name        = "${var.dev_name}-web-sg"
  description = "Security group for web servers"
}

# 4) SSH/HTTP 보안 규칙
resource "openstack_networking_secgroup_rule_v2" "web_ssh" {
  security_group_id = openstack_networking_secgroup_v2.web.id
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 22
  port_range_max    = 22
  remote_ip_prefix  = "0.0.0.0/0"
}
resource "openstack_networking_secgroup_rule_v2" "web_http" {
  security_group_id = openstack_networking_secgroup_v2.web.id
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 80
  port_range_max    = 80
  remote_ip_prefix  = "0.0.0.0/0"
}

# 5) 웹 서버 인스턴스 (count=1 or 0)
resource "openstack_compute_instance_v2" "web" {
  count        = var.create_instance ? 1 : 0
  name         = "${var.dev_name}-web-server"
  image_id     = var.image_id != "" ? var.image_id : data.openstack_images_image_v2.ubuntu.id
  flavor_name  = var.flavor_name
  key_pair     = var.key_name
  availability_zone = var.availability_zone
  security_groups  = [openstack_networking_secgroup_v2.web.name]

  network {
    name = var.network_name
  }

  block_device {
    uuid                  = var.image_id != "" ? var.image_id : data.openstack_images_image_v2.ubuntu.id
    source_type           = "image"
    destination_type      = "volume"
    volume_size           = var.root_volume_size
    delete_on_termination = true
  }

  # 6) 퍼블릭 IP 자동 할당
  lifecycle {
    ignore_changes = [network]
  }
  provisioner "local-exec" {
    when    = "create"
    on_failure = "continue"

    command = <<EOF
       # 생성된 인스턴스에 플로팅 IP 붙이기 (CLI 필요)
       openstack server add floating ip ${openstack_compute_instance_v2.web[0].id} \
         $(openstack floating ip create --network $(terraform output -raw floating_network_id) \
         -f value -c floating_ip_address)
     EOF
  }
}

# 7) 추가 데이터 볼륨
resource "openstack_blockstorage_volume_v3" "data" {
  count = var.create_data_volume ? 1 : 0
  name        = "${var.dev_name}-data-volume"
  size        = var.data_volume_size
}

resource "openstack_compute_volume_attach_v2" "data_attach" {
  count       = var.create_instance && var.create_data_volume ? 1 : 0
  instance_id = openstack_compute_instance_v2.web[0].id
  volume_id   = openstack_blockstorage_volume_v3.data[0].id
}

# 8) Object Storage 컨테이너 (S3 버킷)
resource "openstack_objectstorage_container_v1" "storage" {
  count = var.create_s3_bucket ? 1 : 0
  name  = "${var.dev_name}-storage-${var.s3_bucket_suffix}"
}

