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

# 1) 보안 그룹 (SSH/HTTP)
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
  port_range_min    = 80
  port_range_max    = 80
  remote_ip_prefix  = "0.0.0.0/0"
}

# 2) VM 인스턴스 (volume-backed)
resource "openstack_compute_instance_v2" "web" {
  name              = "${var.dev_name}-web"
  image_id          = var.image_id
  flavor_name       = var.flavor_name
  key_pair          = var.key_name
  availability_zone = var.availability_zone

  # ID 기준으로 SG 지정 (이름 중복 방지)
  security_group_ids = [
    openstack_networking_secgroup_v2.web_sg.id
  ]

  network {
    name      = var.network_name
    subnet_id = var.subnet_id
  }

  block_device {
    uuid                  = var.image_id
    source_type           = "image"
    destination_type      = "volume"
    volume_size           = var.root_volume_size
    delete_on_termination = true
  }

  user_data = <<-EOF
    #cloud-config
    runcmd:
      - apt-get update && apt-get install -y git python3 python3-venv
      - mkdir -p /opt/app && cd /opt/app
      - git clone https://github.com/fastapi/full-stack-fastapi-template.git .
      - python3 -m venv venv && . venv/bin/activate
      - pip install -r requirements.txt
      - echo "$(date)" > /opt/deploy_timestamp.txt
      - sed -i '/include_router/docs_router/i\\
@app.get("/hello")\\
async def hello():\\
    return {"deployed": open("/opt/deploy_timestamp.txt").read().strip()}' backend/app/main.py
      - cd backend
      - nohup uvicorn app.main:app --host 0.0.0.0 --port 8000 &
  EOF
}

# 3) Public IP 생성
resource "openstack_networking_floatingip_v2" "public_ip" {
  pool = var.external_network_id
}

# 4) 생성된 Public IP를 VM 포트에 연결
resource "openstack_networking_floatingip_associate_v2" "assoc" {
  floating_ip = openstack_networking_floatingip_v2.public_ip.address
  port_id     = openstack_compute_instance_v2.web.network[0].port
}

