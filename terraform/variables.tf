  variable "username" {
    description = "카카오 클라우드 사용자 이름"
    type        = string
  }

  variable "password" {
    description = "카카오 클라우드 비밀번호"
    type        = string
    sensitive   = true
  }

  variable "tenant_name" {
    description = "카카오 클라우드 프로젝트 이름"
    type        = string
  }

  variable "region" {
    description = "리소스를 생성할 리전"
    type        = string
    default     = "kr-central-2"
  }

  variable "project_name" {
    description = "프로젝트 이름 (리소스 이름 접두어로 사용)"
    type        = string
    default     = "kc-sfacspace"
  }

  # 인스턴스 관련 변수
  variable "create_instance" {
    description = "인스턴스 생성 여부"
    type        = bool
    default     = false
  }

  variable "image_name" {
    description = "인스턴스의 이미지 이름"
    type        = string
    default     = "Ubuntu 24.04"
  }

  variable "image_id" {
    description = "인스턴스의 이미지 ID"
    type        = string
    default     = "6f8f7e1c-b801-46c6-940c-603ffc05247a"
  }

  variable "flavor_name" {
    description = "인스턴스 타입(flavor)"
    type        = string
    default     = "t1i.small"
  }

  variable "key_name" {
    description = "SSH 접속을 위한 키 페어 이름"
    type        = string
    default     = "test-keypair-kjh"
  }

  variable "root_volume_size" {
    description = "루트 볼륨 크기(GB)"
    type        = number
    default     = 20
  }

  variable "availability_zone" {
    description = "인스턴스 및 LoadBalancer 생성 시 사용할 AZ (예: kr-standard-a)"
    type        = string
    default     = "kr-central-2-a"
  }

  # 추가 볼륨 관련 변수
  variable "create_data_volume" {
    description = "추가 데이터 볼륨 생성 여부"
    type        = bool
    default     = false
  }

  variable "data_volume_size" {
    description = "데이터 볼륨 크기(GB)"
    type        = number
    default     = 50
  }

  # 오브젝트 스토리지 관련 변수
  variable "create_s3_bucket" {
    description = "오브젝트 스토리지 컨테이너 생성 여부"
    type        = bool
    default     = false
  }

  variable "s3_bucket_suffix" {
    description = "오브젝트 스토리지 컨테이너 이름 접미사 (globally unique 해야 함)"
    type        = string
    default     = "unique-suffix"
  }

  variable "network_id" {
    description = "이미 존재하는 VPC 네트워크 ID (sfacspace-default)"
    type        = string
    default     = "7c90b71b-e11a-48dc-83a0-e2bf7394bfb4"
  }

  variable "subnet_id" {
    description = "서브넷 id"
    type        = string
    default     = "75ec8f1b-f756-45ec-b84d-6124b2bd2f2b"
  }

  variable "dev_name" {
    description = "개발자 이름 (리소스 이름 접두어로 사용)"
    type        = string
    default     = "kjh"
  }

