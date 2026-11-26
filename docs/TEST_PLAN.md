# Verification plan

The original manually configured lab was validated in November 2026. **The reconstructed files in this repository have not been verified on a fresh deployment.**

1. `terraform fmt -check` and `terraform validate` locally; inspect `terraform plan` before applying.
2. After first EC2 boot and `sudo bash lab/install-lab.sh`, check `systemctl status ospf-lab ospf-internet`.
3. `sudo vtysh -N r1 -c 'show ip ospf neighbor'` — two FULL adjacencies once converged.
4. `sudo vtysh -N r1 -c 'show ip route ospf'` — remote LAN B and `0.0.0.0/0` present.
5. `sudo ip netns exec pc1 ping -c 4 192.168.20.10` — expected reachability.
6. `sudo ip netns exec pc1 dig @8.8.8.8 example.com A +short` — DNS answer.
7. `sudo bash lab/demo-failover.sh` — route through R3 during failure, direct R2 link after restoration.
8. Reboot; rerun 2–6 to check namespace, FRR and NAT persistence.

`2-Way` can be transitional during Ethernet DR/BDR election. Do not assume an adjacency is faulty until it has had time to establish. Debug with `journalctl -u ospf-lab -u ospf-internet` and `/var/log/cloud-init-output.log`.

Avoid publishing `terraform.tfstate`, generated plans, account data or credentials.
