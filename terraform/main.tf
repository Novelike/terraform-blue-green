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

# 1) 보안 그룹 및 룰
resource "openstack_networking_secgroup_v2" "web_sg" {
  name        = "${var.dev_name}-sg"
  description = "Allow SSH and HTTP"
}

resource "openstack_networking_secgroup_rule_v2" "ssh" {
  security_group_id = openstack_networking_secgroup_v2.web_sg.id
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 22
  port_range_max    = 22
  remote_ip_prefix  = "0.0.0.0/0"
}

resource "openstack_networking_secgroup_rule_v2" "http" {
  security_group_id = openstack_networking_secgroup_v2.web_sg.id
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 8000
  port_range_max    = 8000
  remote_ip_prefix  = "0.0.0.0/0"
}

# 2) Ubuntu 이미지 조회
data "openstack_images_image_v2" "ubuntu" {
  id = "6f8f7e1c-b801-46c6-940c-603ffc05247a"
}

# 3) Blue/Green VM 생성 (볼륨백 부팅)
locals { envs = ["blue", "green"] }

resource "openstack_compute_instance_v2" "web" {
  for_each          = toset(local.envs)
  name              = "${var.dev_name}-${each.key}"
  image_id          = var.image_id != "" ? var.image_id : data.openstack_images_image_v2.ubuntu.id
  flavor_name       = var.flavor_name
  key_pair          = var.key_name
  availability_zone = var.availability_zone
  security_groups   = [openstack_networking_secgroup_v2.web_sg.name]

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

  user_data = templatefile("${path.module}/cloud-init.tpl", {
    env = each.key
  })

  metadata = {
    env = each.key
  }
}

# 4) Floating IP 생성
resource "openstack_networking_floatingip_v2" "fip" {
  for_each = toset(local.envs)
  pool     = var.floating_ip_pool
}

# 5) Floating IP → 포트 연결
resource "openstack_networking_floatingip_associate_v2" "assoc" {
  for_each    = openstack_compute_instance_v2.web
  floating_ip = openstack_networking_floatingip_v2.fip[each.key].address
  port_id     = each.value.network[0].port
}

# 6) Load Balancer 구성
resource "openstack_lb_loadbalancer_v2" "lb" {
  name              = "${var.dev_name}-lb"
  vip_subnet_id     = var.subnet_id
  availability_zone = var.availability_zone
}

resource "openstack_lb_listener_v2" "listener" {
  name            = "${var.dev_name}-listener"
  loadbalancer_id = openstack_lb_loadbalancer_v2.lb.id
  protocol        = "HTTP"
  protocol_port   = 80
}

resource "openstack_lb_pool_v2" "pool" {
  name        = "${var.dev_name}-pool"
  listener_id = openstack_lb_listener_v2.listener.id
  protocol    = "HTTP"
  lb_method   = "ROUND_ROBIN"
}

resource "openstack_lb_monitor_v2" "hc" {
  pool_id        = openstack_lb_pool_v2.pool.id
  type           = "HTTP"
  delay          = 5
  timeout        = 3
  max_retries    = 3
  http_method    = "GET"
  url_path       = "/hello"
  expected_codes = "200"
}

resource "openstack_lb_member_v2" "member" {
  for_each      = openstack_compute_instance_v2.web
  pool_id       = openstack_lb_pool_v2.pool.id
  address       = each.value.access_ip_v4
  protocol_port = 8000
  subnet_id     = var.subnet_id
}

