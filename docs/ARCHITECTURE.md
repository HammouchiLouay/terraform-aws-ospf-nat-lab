# Network architecture and addressing

One AWS VPC (`10.70.0.0/16`), public subnet (`10.70.10.0/24`) and Ubuntu EC2 host. Within the EC2 instance, Linux namespaces act as independent PCs and routers.

```text
PC1 (192.168.10.10) --- R1 (192.168.10.1)
                            |  \
                 10.0.12/30 |   \ 10.0.13/30
                            |    \
                            R2 --- R3
                            |
                        LAN B (192.168.20.0/24)
                            |
                         PC2 (.10)

R2's 172.31.250.2 --- host ospf-uplink 172.31.250.1
                                  |
                         host NAT/MASQUERADE
                                  |
                        AWS EC2 private IPv4
                                  |
                        AWS Internet Gateway
                                  |
                          Google DNS 8.8.8.8
```

**Router-to-router:** R1 r12 10.0.12.1/30 ↔ R2 r21 10.0.12.2/30; R1 r13 10.0.13.1/30 ↔ R3 r31 10.0.13.2/30; R2 r23 10.0.23.1/30 ↔ R3 r32 10.0.23.2/30.

**LANs:** PC1 eth0 192.168.10.10/24 gateway R1 lan0 192.168.10.1; R2 lan0 192.168.20.1 gateway for PC2 eth0 192.168.20.10/24.

**OSPF:** Area 0 on all router interconnects, passive LAN interfaces. R1–R2 is lower-cost preferred path. R2 originates default route when its host-facing default route exists. On direct link failure, expected path: PC1 → R1 → R3 → R2 → PC2.

**Internet:** Linux source NAT on the EC2 host; AWS Internet Gateway is already provided by Terraform. This project does **not** provision an AWS managed NAT Gateway. The virtual namespaces are not additional EC2 instances.
