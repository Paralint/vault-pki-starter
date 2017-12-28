# vault-pki-starter
A small project to get you started running your own PKI with Vault (on Consul storage backend)


```bash
nohup consul agent --server --data-dir ./data --config-file ./consul-config.json -ui --bind $CONSUL_IP 2>&1 > data/consul.$(date --rfc-3339=date).log &
```
