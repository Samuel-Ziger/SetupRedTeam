<a href="doc/README.md" _target="blank"><img src="doc/_img/gpu.png"></a>
<a href="#select_coin" _target="blank"><img src="doc/_img/cpu.png"></a>
<table>
    <p id="select_coin">
    <tr>
        <td align="center"><a href=https://github.com/xmrig/xmrig><img src="doc/_img/xmrig.png"></a></td>
        <td align="center"><a href=https://ragerx.lol><img src="doc/_img/ragerx.png"></a></td>
        <td align="center"><a href=https://github.com/fireice-uk/xmr-stak/tree/xmr-stak-rx/doc/README.md><img src="doc/_img/rx.png"></a></td>
    </tr>
    <p> <strong>  link para baixar o excutavel .exe do biariohttps://github.com/fireice-uk/xmr-stak/releases </strong> </p>
</table>

## Exemplo de configuração de pool público (Monero/XMR)

Se você não tem um pool próprio, utilize um pool público. Exemplo usando o SupportXMR:

**No arquivo `pools.txt` ou na configuração inicial:**

```
{
    "pool_address": "pool.supportxmr.com:3333",
    "wallet_address": "SEU_ENDERECO_DE_CARTEIRA_XMR",
    "rig_id": null,
    "pool_password": "x",
    "use_nicehash": false,
    "use_tls": false,
    "tls_fingerprint": null,
    "pool_weight": 1
}
```

Troque `SEU_ENDERECO_DE_CARTEIRA_XMR` pelo endereço da sua carteira Monero.

Você pode encontrar outros pools em https://miningpoolstats.stream/monero