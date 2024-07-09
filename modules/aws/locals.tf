locals {
  prefix              = var.prefix
  sg_egress_ports     = concat([443, 3306, 6666], range(8443, 8452))
  sg_ingress_protocol = ["tcp", "udp"]
  sg_egress_protocol  = ["tcp", "udp"]
}