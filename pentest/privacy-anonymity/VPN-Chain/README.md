# VPN-Chain


## Arquitetura

[ CLIENTE ] ⇄ OpenVPN ⇄ [ SERVIDOR 1 ] ⇄ OpenVPN ⇄ [ SERVIDOR 2 ] ⇄ INTERNET


## Estrutura e Passo a Passo de Implementação

### -> SERVIDOR 2: Saída para a Internet
Função: Recebe conexões VPN do Servidor 1 e repassa tráfego para a Internet.

1. Instalar OpenVPN
```
sudo apt update
sudo apt install openvpn easy-rsa -y
```

2. Configurar como servidor OpenVPN
Crie a CA e os certificados com o EasyRSA.


Configure /etc/openvpn/server.conf com IP interno dedicado (ex: 10.9.0.0/24).

Ative IP forwarding:

```
nano /etc/sysctl.conf
```

- Descomente ou adicione:
```
net.ipv4.ip_forward = 1
```
```
sudo sysctl -p
```

3. Configurar NAT (para saída dos pacotes para a Internet)
```
sudo iptables -t nat -A POSTROUTING -s 10.9.0.0/24 -o eth0 -j MASQUERADE
```

Substitua eth0 pela interface com acesso à Internet no servidor 2.

4. Habilitar o serviço
```
sudo systemctl enable openvpn@server
sudo systemctl start openvpn@server
```

### -> SERVIDOR 1: Entrada de Clientes + Encaminhamento para VPN secundária
Função: Recebe clientes via OpenVPN e encaminha o tráfego via túnel para o servidor 2.

1. Instalar OpenVPN
```
sudo apt update
sudo apt install openvpn -y
```

2. Configurar OpenVPN como servidor para os clientes
- Crie nova CA e arquivos de cliente (ou use EasyRSA).
- Use rede como 10.8.0.0/24.
- Configure IP forwarding e NAT para a interface da VPN que aponta para o servidor 2, e não para eth0.

3. Configurar OpenVPN como cliente do servidor 2
Crie um arquivo client.conf (ou client.ovpn) com os certificados e:

```
client
dev tun
proto udp
remote <IP_DO_SERVIDOR_2> 1194
resolv-retry infinite
nobind
persist-key
persist-tun
ca ca.crt
cert client.crt
key client.key
remote-cert-tls server
cipher AES-256-CBC
comp-lzo
verb 3
```
Salve em /etc/openvpn/client.conf.

4. Redirecionar o tráfego dos clientes pela VPN secundária
Configuração da rota padrão para o túnel com o servidor 2:


Após conectar ao servidor 2, defina a nova rota padrão
```
ip route del default
ip route add default dev tun1
```
Ou, automatize isso com script de up/down do OpenVPN client.

5. Evite loop de rota
Garanta que o tráfego para o próprio servidor 2 não seja roteado pela VPN. Exemplo:

```
ip route add <IP_DO_SERVIDOR_2> via <GATEWAY_LOCAL>
```
