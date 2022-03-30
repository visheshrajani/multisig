from brownie import network, accounts, config

LOCAL = ["development","ganache-local"]
FORK = ["mainnet-fork"]

def get_account(id=None):
    if id:
        return accounts[id]
    if network.show_active() in LOCAL or network.show_active() in FORK:
        return accounts[0]
    else:
        return accounts.add(config["wallets"]["from_key"])