# Terraform + OSPF + NAT on AWS

**Infrastructure as Code · Dynamic routing · High availability · Linux NAT · Cloud networking**

> **Repository status — reconstructed from a previously validated lab.** The AWS Terraform files derive from the actual original starter project. The OSPF router configurations, shell scripts and service units in `lab/` were recreated from the configuration steps used in November 2026; the original EC2 instances were subsequently deleted, so this particular repository version **has not been end-to-end tested on a fresh AWS deployment**. Treat it as a reproducible candidate requiring validation, not as a verified machine image/export.

## Project summary

Terraform provisions the AWS network (VPC, subnet, Internet Gateway, route table, IAM instance profile, Security Group, Ubuntu EC2). On one EC2 instance, five Linux network namespaces (`pc1`, `r1`, `r2`, `r3`, `pc2`) form a virtual router triangle using FRRouting OSPF Area 0. The routers learn remote LAN routes; after the R1–R2 link fails, the R1–R3–R2 alternate path becomes active. R2 advertises the Internet default route into OSPF; Linux NAT on the EC2 host translates lab-client traffic toward the AWS Internet Gateway. Systemd restores the virtual topology and Internet uplink after reboots.

The historically tested lab demonstrated OSPF adjacency formation, PC1↔PC2 connectivity, successful link failover/return, PC1/PC2 Internet access, Google Public DNS lookups, and reboot persistence.

## Architecture

See [network diagram and addressing](docs/ARCHITECTURE.md). This is **one** EC2 instance, not a 3-EC2 router cluster, and does **not** use a billed AWS NAT Gateway.

## Repository structure

```text
main.tf / variables.tf / versions.tf / outputs.tf  Terraform AWS foundation
bootstrap.sh                                  EC2 cloud-init base packages
lab/frr/{r1,r2,r3}/frr.conf                  Reconstructed OSPF pathspaces
lab/setup-topology.sh                        Linux namespaces + veths + IPs
lab/configure-frr.sh                          FRR pathspace preparation
lab/start-lab.sh                              FRR startup and topology restore
lab/start-internet.sh                         R2 uplink, host routes, NAT
lab/systemd/                                 Boot automation units
lab/install-lab.sh                            Manual one-time install on EC2
lab/verify.sh / lab/demo-failover.sh           Verification and demo
```

## Deploy (proposed / fresh deployment not verified)

**Prerequisites:** Terraform 1.6+, AWS CLI with a browser/SSO identity allowed to provision EC2, VPC, IAM; `git` on Windows; a budget for EC2/EBS and public IPv4 charges. No long-term AWS credentials need to be placed in source files.

```powershell
$env:AWS_PROFILE = 'terraform-lab'   # adapt to your existing login
terraform init
terraform fmt
terraform validate
terraform plan
terraform apply
terraform output
```

Open **EC2 → Instances → Connect → Session Manager**. Wait for cloud-init and verify the base packages. To install the reconstructed virtual lab, fetch this *public* repository from inside EC2:

```bash
sudo cloud-init status --wait
sudo apt-get install -y git
git clone https://github.com/HammouchiLouay/terraform-aws-ospf-nat-lab.git
cd terraform-aws-ospf-nat-lab
sudo bash lab/install-lab.sh
sudo bash lab/verify.sh
```

**Note:** This is currently a **two-stage deployment**: Terraform provisions AWS; the `lab/` scripts and systemd install the Linux network. It is not yet zero-touch provisioning of the entire OSPF/NAT topology by Terraform. You must validate the reconstructed code in a new isolated EC2 before claiming turnkey reproduction.

## Demo and checks

```bash
sudo vtysh -N r1 -c 'show ip ospf neighbor'
sudo vtysh -N r1 -c 'show ip route ospf'
sudo ip netns exec pc1 ping -c 4 192.168.20.10
sudo ip netns exec pc1 dig @8.8.8.8 google.com A +short
sudo bash lab/demo-failover.sh
```

A full [test plan](docs/TEST_PLAN.md) includes post-reboot checks and return-path troubleshooting.

## Security and cost

- No inbound SG rules; Session Manager with an IAM instance role is the administration path.
- Avoid uploading `.terraform/`, state files, saved plans, `.tfvars` with secrets or AWS authentication caches.
- This configuration allows broad egress for initial installation and testing; tighten it for production.
- Host NAT rules match two lab LANs and the R2 uplink only. AWS public IPv4 translation is distinct from the Linux NAT stage.
- `terraform destroy` cleans up Terraform-tracked AWS resources; inspect the plan first. EBS and public IPv4 can incur costs before teardown.

## Technical concepts demonstrated

Terraform's HCL describes **desired cloud infrastructure**, while OSPF is a dynamic routing protocol that calculates best Layer-3 paths. Linux namespaces simulate router/network isolation; FRRouting supplies OSPF routing daemons and CLI. IP masquerade provides connection-tracked SNAT/PAT. Systemd orchestrates boot-time recovery.

This is a different project from the separate **AWS Adaptive SDN Security Lab** using CloudFormation, OS-Ken, OpenFlow 1.3 and Open vSwitch.

## Documentation

- [Terraform AWS provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [FRRouting setup / pathspaces](https://docs.frrouting.org/en/latest/setup.html)
- [AWS Systems Manager Session Manager](https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager.html)
