terraform {
  required_version = ">= 1.0"
  required_providers {
    oxide = {
      source  = "oxidecomputer/oxide"
      version = "0.5.0"
    }
  }
}

provider "oxide" {}

data "oxide_project" "test" {
  name = var.project_name
}

resource "oxide_ssh_key" "test" {
  name        = "test-key"
  description = "SSH key for test provisioning"
  public_key  = var.public_ssh_key
}

resource "oxide_vpc" "test" {
  name        = var.vpc_name
  dns_name    = var.vpc_dns_name
  description = var.vpc_description
  project_id  = data.oxide_project.test.id
}

resource "oxide_vpc_subnet" "default" {
  vpc_id      = oxide_vpc.test.id
  name        = "testsubnet"
  description = "Default subnet for testing"
  ipv4_block  = var.subnet_cidr
}

resource "oxide_disk" "nodes" {
  for_each = { for i in range(var.instance_count) : i => "test-node-${i + 1}" }

  name            = each.value
  project_id      = data.oxide_project.test.id
  description     = "Disk for ${each.value}"
  size            = var.disk_size
  source_image_id = var.ubuntu_image_id
}

resource "oxide_instance" "nodes" {
  for_each = oxide_disk.nodes

  name             = each.value.name
  project_id       = data.oxide_project.test.id
  boot_disk_id     = each.value.id
  description      = "Test node ${each.value.name}"
  memory           = var.memory
  ncpus            = var.ncpus
  disk_attachments = [each.value.id]
  ssh_public_keys  = [oxide_ssh_key.test.id]
  start_on_create  = true
  host_name        = each.value.name

  external_ips = [{
    type = "ephemeral"
  }]

  network_interfaces = [{
    name        = "nic-${each.value.name}"
    description = "Primary NIC"
    vpc_id      = oxide_vpc.test.id
    subnet_id   = oxide_vpc_subnet.default.id
  }]

  user_data = base64encode(<<-EOF
#!/bin/bash
echo "ubuntu ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/ubuntu
chmod 0440 /etc/sudoers.d/ubuntu
EOF
  )
}

data "oxide_instance_external_ips" "nodes" {
  for_each    = oxide_instance.nodes
  instance_id = each.value.id
}

locals {
  sorted_instance_keys = sort(keys(oxide_instance.nodes))

  node_ips = [
    for k in local.sorted_instance_keys :
    data.oxide_instance_external_ips.nodes[k].external_ips[0].ip
  ]

  internal_node_ips = [
    for k in local.sorted_instance_keys :
    tolist(oxide_instance.nodes[k].network_interfaces)[0].ip_address
  ]

  internal_ip = local.internal_node_ips[0]
  external_ip = local.node_ips[0]
}
